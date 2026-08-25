use crate::eval::eval;
pub use crate::slot::{
    DataEntry, ExecutionState, ProgramMetadata, RuntimeError, RuntimeValue, TypedSlot,
};
use xb_compiler::{IrExprKind, IrItem, IrProgram, ValueType};
#[derive(Debug, Clone, Copy, Default)]
pub struct Interpreter;

impl Interpreter {
    pub const fn new() -> Self {
        Self
    }

    pub fn execute(
        &self,
        program: &IrProgram,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState::default();
        crate::data_segment::init_data_segment(program, &mut state);
        exec_items(
            program,
            &program.items,
            &program.items,
            0,
            &mut state,
            output,
        )?;
        Ok(state)
    }

    pub fn execute_main(
        &self,
        program: &IrProgram,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState::default();
        crate::data_segment::init_data_segment(program, &mut state);
        exec_items(
            program,
            &program.items,
            &program.items,
            0,
            &mut state,
            output,
        )?;
        if let Some(main) = program.entry_or_first_callable("Main") {
            exec_items(program, main, main, 0, &mut state, output)?;
        }
        Ok(state)
    }
    pub fn execute_main_with_input(
        &self,
        program: &IrProgram,
        input: Vec<Vec<u8>>,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState {
            input,
            ..Default::default()
        };
        crate::data_segment::init_data_segment(program, &mut state);
        exec_items(
            program,
            &program.items,
            &program.items,
            0,
            &mut state,
            output,
        )?;
        if let Some(main) = program.entry_or_first_callable("Main") {
            exec_items(program, main, main, 0, &mut state, output)?;
        }
        Ok(state)
    }
}

pub(crate) enum Flow {
    Continue,
    Break,
    Return(Option<RuntimeValue>),
    Goto(String),
    GosubReturn,
}

/// Truthiness of a control-flow condition (`IF`/`WHILE`/`DO`). Integer and Giant
/// are tested against zero on their *full* value (narrowing a Giant to i32 first
/// would wrongly zero a multiple of 2^32), matching the C backends' `if (cond)`.
/// Returns `None` for non-numeric values, preserving the prior skip behavior.
fn cond_bool(v: &RuntimeValue) -> Option<bool> {
    match v {
        RuntimeValue::Integer(n) => Some(*n != 0),
        RuntimeValue::Giant(g) => Some(*g != 0),
        _ => None,
    }
}

pub(crate) fn exec_items(
    program: &IrProgram,
    items: &[IrItem],
    func_body: &[IrItem],
    start: usize,
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<Flow, RuntimeError> {
    // Build label → index map
    let mut label_map: std::collections::HashMap<&str, usize> = std::collections::HashMap::new();
    for (i, item) in items.iter().enumerate() {
        if let IrItem::Label(name) = item {
            label_map.insert(name.as_str(), i);
            state.label_addresses.insert(name.clone(), i);
        }
    }

    let mut idx = start;
    while idx < items.len() {
        let item = &items[idx];
        match item {
            IrItem::Version(v) => state.metadata.version = Some(v.clone()),
            IrItem::ProgramName(v) => state.metadata.program_name = Some(v.clone()),
            IrItem::Print { items, separators } => {
                crate::interpreter_select::exec_print(items, separators, program, output, state)?
            }
            IrItem::ConstantDefinition { .. } => {}
            IrItem::Dim {
                symbol,
                size,
                extra_dims,
                is_array,
                redim,
                shared,
            } => {
                // A dynamic array (empty-bracket DIM, REDIM'd, or SHARED)
                // registers for write auto-vivification: a write past the
                // current storage grows it (contract matches the compiled
                // backends' dyn grow-guard). Fixed non-shared arrays don't.
                if *is_array && (*redim || size.is_none() || *shared) {
                    state.dyn_arrays.insert(symbol.name.clone());
                }
                if *is_array {
                    // Inclusive upper bounds: DIM a[d0, d1, …] -> shape
                    // [d0+1, d1+1, …]; empty `DIM a[]` -> empty shape (len 0).
                    let mut dims: Vec<usize> = Vec::new();
                    for e in size.iter().chain(extra_dims.iter()) {
                        match eval(program, e, state, output)? {
                            RuntimeValue::Integer(i) => {
                                dims.push((i.max(0) as usize).wrapping_add(1))
                            }
                            n => {
                                return Err(RuntimeError::TypeMismatch {
                                    expected: ValueType::Integer,
                                    actual: n.value_type(),
                                })
                            }
                        }
                    }
                    // `SHARED x[…]` arrays live in the module-shared store so they
                    // persist across function calls (threaded via ExecutionState);
                    // plain `DIM`/`REDIM` arrays are function-local.
                    let store = if *shared {
                        &mut state.shared
                    } else {
                        &mut state.slots
                    };
                    if *redim {
                        // REDIM reshapes preserving the common prefix; REDIM of an
                        // undeclared name creates it (legacy XBasic).
                        store
                            .entry(symbol.name.clone())
                            .or_insert_with(|| {
                                TypedSlot::new_array_nd(symbol.value_type, Vec::new())
                            })
                            .array_reshape(dims);
                    } else if *shared && dims.is_empty() {
                        // `SHARED x[]` references the shared array without resizing;
                        // create an empty one only if it does not exist yet.
                        store.entry(symbol.name.clone()).or_insert_with(|| {
                            TypedSlot::new_array_nd(symbol.value_type, Vec::new())
                        });
                    } else if *shared {
                        // `SHARED x[n]` sizes the shared array (create-or-resize,
                        // preserving existing data across re-declaration/order).
                        store
                            .entry(symbol.name.clone())
                            .or_insert_with(|| {
                                TypedSlot::new_array_nd(symbol.value_type, Vec::new())
                            })
                            .array_reshape(dims);
                    } else {
                        store.insert(
                            symbol.name.clone(),
                            TypedSlot::new_array_nd(symbol.value_type, dims),
                        );
                    }
                } else if *shared {
                    // Keyword-`SHARED` scalar: module-shared storage (classic
                    // BASIC); reads/writes go through SharedVariable /
                    // SharedAssignment which target `state.shared`.
                    state
                        .shared
                        .entry(symbol.name.clone())
                        .or_insert_with(|| TypedSlot::new(symbol.value_type));
                } else {
                    state
                        .slots
                        .insert(symbol.name.clone(), TypedSlot::new(symbol.value_type));
                }
            }
            IrItem::Assignment { target, value } => {
                let v = eval(program, value, state, output)?;
                // Coerce to the target type (XBasic implicit coercion).
                let v = crate::helpers::coerce_value(v, target.value_type);
                // Auto-declare the variable on first assignment (legacy XBasic
                // auto-declares locals; DIM is not required before assignment).
                let slot = state
                    .slots
                    .entry(target.name.clone())
                    .or_insert_with(|| TypedSlot::new(target.value_type));
                slot.value = v;
            }
            IrItem::ArrayAssignment {
                target,
                index,
                extra_indices,
                value,
            } => {
                let mut idxs: Vec<usize> = Vec::with_capacity(1 + extra_indices.len());
                for e in std::iter::once(index).chain(extra_indices.iter()) {
                    match eval(program, e, state, output)? {
                        RuntimeValue::Integer(i) => idxs.push(i as usize),
                        n => {
                            return Err(RuntimeError::TypeMismatch {
                                expected: ValueType::Integer,
                                actual: n.value_type(),
                            })
                        }
                    }
                }
                let v = crate::helpers::coerce_value(
                    eval(program, value, state, output)?,
                    target.value_type,
                );
                // Auto-vivify the slot if it doesn't exist in either local or
                // shared scope (matches the C backend's hoist-all-used-symbols
                // behavior; reads already auto-vivify via read_slot/ArrayAccess).
                // If the slot has no array (undimmed), discard the write —
                // matching the C backend's undimmed-array fold (write → discard).
                // Dynamic arrays (dyn_arrays set) GROW instead: a write past the
                // current storage resizes to index+1 (preserving the prefix),
                // matching the compiled backends' dyn grow-guard. 1-D only.
                let grow = state.dyn_arrays.contains(&target.name) && idxs.len() == 1;
                if let Some(slot) = state.slots.get_mut(&target.name) {
                    if let Some(off) = slot.array_offset(&idxs) {
                        slot.array_set(off, v)?;
                    } else if grow {
                        slot.array_reshape(vec![idxs[0] + 1]);
                        slot.array_set(idxs[0], v)?;
                    }
                } else if let Some(slot) = state.shared.get_mut(&target.name) {
                    if let Some(off) = slot.array_offset(&idxs) {
                        slot.array_set(off, v)?;
                    } else if grow {
                        slot.array_reshape(vec![idxs[0] + 1]);
                        slot.array_set(idxs[0], v)?;
                    }
                } else {
                    let mut slot = TypedSlot::new(target.value_type);
                    if let Some(off) = slot.array_offset(&idxs) {
                        slot.array_set(off, v)?;
                    }
                    state.slots.insert(target.name.clone(), slot);
                }
            }
            IrItem::MidAssign {
                target,
                start,
                length,
                value,
            } => {
                // Target: a local symbol, or a keyword-`SHARED` scalar
                // (SharedVariable) whose bytes live in `state.shared`.
                let (target_name, target_shared) = match &target.kind {
                    IrExprKind::Symbol(s) => (&s.name, false),
                    IrExprKind::SharedVariable(s) => (&s.name, true),
                    _ => {
                        return Err(RuntimeError::UnknownSlot {
                            name: "mid_assign target".into(),
                        });
                    }
                };
                let start_val = eval(program, start, state, output)?;
                let len_val = if let Some(len_expr) = length {
                    Some(eval(program, len_expr, state, output)?)
                } else {
                    None
                };
                let src_val = eval(program, value, state, output)?;
                let RuntimeValue::Integer(start_i) = start_val else {
                    return Err(RuntimeError::TypeMismatch {
                        expected: ValueType::Integer,
                        actual: start_val.value_type(),
                    });
                };
                let RuntimeValue::String(ref src) = src_val else {
                    return Err(RuntimeError::TypeMismatch {
                        expected: ValueType::String,
                        actual: src_val.value_type(),
                    });
                };
                let copy_len = match &len_val {
                    Some(RuntimeValue::Integer(n)) => *n as usize,
                    _ => src.len(),
                };
                let slot =
                    if target_shared {
                        state.shared.get_mut(target_name).ok_or_else(|| {
                            RuntimeError::UnknownSlot {
                                name: target_name.clone(),
                            }
                        })?
                    } else {
                        state.slots.get_mut(target_name).ok_or_else(|| {
                            RuntimeError::UnknownSlot {
                                name: target_name.clone(),
                            }
                        })?
                    };
                if let RuntimeValue::String(ref mut dst) = slot.value {
                    let si = (start_i as usize).saturating_sub(1);
                    let copy = copy_len.min(src.len()).min(dst.len().saturating_sub(si));
                    // Byte copy: XBasic strings are raw bytes (no char boundaries).
                    if copy > 0 {
                        dst[si..si + copy].copy_from_slice(&src[..copy]);
                    }
                }
            }
            IrItem::BuiltinAssign { name, args, value } => {
                // *AT assignment: in interpreter, this is a no-op (no real memory)
                // Just evaluate the value to check for errors
                let _ = eval(program, value, state, output)?;
                let _ = name;
                let _ = args;
            }
            IrItem::SharedAssignment { target, value } => {
                crate::interpreter_select::exec_shared(target, value, program, state, output)?;
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                let cond = eval(program, condition, state, output)?;
                if let Some(is_true) = cond_bool(&cond) {
                    if is_true {
                        match exec_items(program, then_body, func_body, 0, state, output)? {
                            Flow::Return(r) => return Ok(Flow::Return(r)),
                            Flow::Break => return Ok(Flow::Break),
                            Flow::GosubReturn => return Ok(Flow::GosubReturn),
                            Flow::Goto(label) => {
                                if let Some(&pos) = label_map.get(label.as_str()) {
                                    idx = pos;
                                    continue;
                                }
                                return Ok(Flow::Goto(label));
                            }
                            Flow::Continue => {}
                        }
                    } else if let Some(eb) = else_body {
                        match exec_items(program, eb, func_body, 0, state, output)? {
                            Flow::Return(r) => return Ok(Flow::Return(r)),
                            Flow::Break => return Ok(Flow::Break),
                            Flow::GosubReturn => return Ok(Flow::GosubReturn),
                            Flow::Goto(label) => {
                                if let Some(&pos) = label_map.get(label.as_str()) {
                                    idx = pos;
                                    continue;
                                }
                                return Ok(Flow::Goto(label));
                            }
                            Flow::Continue => {}
                        }
                    }
                }
            }
            IrItem::While { condition, body } => {
                let mut pending_flow: Option<Flow> = None;
                loop {
                    let cond = eval(program, condition, state, output)?;
                    if cond_bool(&cond) == Some(false) {
                        break;
                    }
                    match exec_items(program, body, func_body, 0, state, output)? {
                        Flow::Return(r) => return Ok(Flow::Return(r)),
                        Flow::Break => break,
                        Flow::GosubReturn => return Ok(Flow::GosubReturn),
                        Flow::Goto(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                idx = pos;
                                continue;
                            }
                            pending_flow = Some(Flow::Goto(label));
                            break;
                        }
                        Flow::Continue => {}
                    }
                }
                if let Some(f) = pending_flow {
                    return Ok(f);
                }
            }
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => {
                let mut pending_flow: Option<Flow> = None;
                loop {
                    if let Some((cond, is_while)) = pre_condition {
                        let v = eval(program, cond, state, output)?;
                        if let Some(t) = cond_bool(&v) {
                            if (*is_while && !t) || (!*is_while && t) {
                                break;
                            }
                        }
                    }
                    match exec_items(program, body, func_body, 0, state, output)? {
                        Flow::Return(r) => return Ok(Flow::Return(r)),
                        Flow::Break => break,
                        Flow::GosubReturn => return Ok(Flow::GosubReturn),
                        Flow::Goto(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                idx = pos;
                                continue;
                            }
                            pending_flow = Some(Flow::Goto(label));
                            break;
                        }
                        Flow::Continue => {}
                    }
                    if let Some((cond, is_while)) = post_condition {
                        let v = eval(program, cond, state, output)?;
                        if let Some(t) = cond_bool(&v) {
                            if (*is_while && !t) || (!*is_while && t) {
                                break;
                            }
                        }
                    }
                }
                if let Some(f) = pending_flow {
                    return Ok(f);
                }
            }
            IrItem::For { .. } => {
                match crate::eval::exec_for(program, item, func_body, state, output)? {
                    Flow::Return(r) => return Ok(Flow::Return(r)),
                    Flow::Break => {}
                    Flow::GosubReturn => return Ok(Flow::GosubReturn),
                    Flow::Goto(label) => {
                        if let Some(&pos) = label_map.get(label.as_str()) {
                            idx = pos;
                            continue;
                        }
                        return Ok(Flow::Goto(label));
                    }
                    Flow::Continue => {}
                }
            }
            IrItem::ExitLoop => return Ok(Flow::Break),
            IrItem::ExitSelect => return Ok(Flow::Break),
            IrItem::Swap { left, right } => {
                crate::interpreter_select::exec_swap(left, right, state)?
            }
            IrItem::Function { .. } => {}
            IrItem::Nop => {}
            IrItem::SelectCase {
                selector,
                cases,
                default,
            } => {
                let flow = crate::interpreter_select::exec_select_case(
                    program,
                    selector,
                    cases,
                    default.as_deref(),
                    func_body,
                    state,
                    output,
                )?;
                match flow {
                    Flow::Return(_) | Flow::GosubReturn => return Ok(flow),
                    Flow::Goto(label) => {
                        if let Some(&pos) = label_map.get(label.as_str()) {
                            idx = pos;
                            continue;
                        }
                        return Ok(Flow::Goto(label));
                    }
                    Flow::Break | Flow::Continue => {}
                }
            }
            IrItem::Call { name, args } => drop(crate::call::call_function(
                program, name, args, state, output,
            )?),
            IrItem::Return { value } => {
                return crate::exec_helpers::exec_return(program, value, state, output)
            }
            IrItem::Compound(inner) => {
                let flow = exec_items(program, inner, func_body, 0, state, output)?;
                if !matches!(flow, Flow::Continue) {
                    return Ok(flow);
                }
            }
            IrItem::Read(symbols) => crate::data_segment::exec_read(symbols, state)?,
            IrItem::Restore(_) => crate::data_segment::exec_restore(state),
            IrItem::Stop => return Ok(Flow::Return(None)),
            IrItem::Label(_) => {}
            IrItem::Goto(name) => {
                if let Some(&pos) = label_map.get(name.as_str()) {
                    idx = pos;
                    continue;
                }
                // Label not in this scope; propagate up
                return Ok(Flow::Goto(name.clone()));
            }
            IrItem::Gosub(name) => {
                if let Some(target) = find_label_index(func_body, name) {
                    match exec_items(program, func_body, func_body, target, state, output)? {
                        Flow::Return(r) => return Ok(Flow::Return(r)),
                        Flow::Goto(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                idx = pos;
                                continue;
                            }
                            return Ok(Flow::Goto(label));
                        }
                        // GosubReturn / Continue / Break: subroutine finished, resume here.
                        _ => {}
                    }
                }
                // Unknown label: tolerated as a no-op (matches stubbed-call behavior).
            }
            IrItem::GosubReturn => {
                // Return from the current subroutine to its caller, or from the
                // function when reached at the top level (empty call chain).
                return Ok(Flow::GosubReturn);
            }
            IrItem::GosubExpr(expr) => {
                let val = eval(program, expr, state, output)?;
                let RuntimeValue::Integer(addr) = val else {
                    return Err(RuntimeError::TypeMismatch {
                        expected: ValueType::Integer,
                        actual: val.value_type(),
                    });
                };
                // Address 0 = no subroutine registered (undimmed Sub[] or
                // unregistered message). Skip — matches the C backend where
                // XgrProcessMessages is a stub that never dispatches.
                if addr == 0 {
                    // no-op
                } else {
                    match exec_items(program, func_body, func_body, addr as usize, state, output)? {
                        Flow::Return(r) => return Ok(Flow::Return(r)),
                        Flow::Goto(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                idx = pos;
                                continue;
                            }
                            return Ok(Flow::Goto(label));
                        }
                        _ => {}
                    }
                }
            }
            IrItem::GotoExpr(expr) => {
                let val = eval(program, expr, state, output)?;
                let RuntimeValue::Integer(addr) = val else {
                    return Err(RuntimeError::TypeMismatch {
                        expected: ValueType::Integer,
                        actual: val.value_type(),
                    });
                };
                let target = addr as usize;
                // Executing the function body directly: jump within it.
                if std::ptr::eq(items, func_body) {
                    idx = target;
                    continue;
                }
                // Nested body: resolve the target label and unwind to it.
                if let Some(name) = label_name_at(func_body, target) {
                    if let Some(&pos) = label_map.get(name) {
                        idx = pos;
                        continue;
                    }
                    return Ok(Flow::Goto(name.to_owned()));
                }
                // Computed target is not a label reachable from a nested body.
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: ValueType::Integer,
                });
            }
        }
        idx += 1;
    }
    Ok(Flow::Continue)
}

/// Position of `label name:` within a function body, or `None` if absent.
fn find_label_index(func_body: &[IrItem], name: &str) -> Option<usize> {
    func_body
        .iter()
        .position(|it| matches!(it, IrItem::Label(l) if l == name))
}

/// Name of the label at `idx` in a function body, if that item is a label.
fn label_name_at(func_body: &[IrItem], idx: usize) -> Option<&str> {
    match func_body.get(idx) {
        Some(IrItem::Label(l)) => Some(l.as_str()),
        _ => None,
    }
}
