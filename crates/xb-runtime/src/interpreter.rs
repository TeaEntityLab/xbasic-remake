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
        if let Some(main) = program.entry_or_first("Main") {
            exec_items(program, main, main, 0, &mut state, output)?;
        }
        Ok(state)
    }
    pub fn execute_main_with_input(
        &self,
        program: &IrProgram,
        input: Vec<String>,
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
        if let Some(main) = program.entry_or_first("Main") {
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
                is_array,
                redim,
            } => {
                // Inclusive upper bound: DIM a[n] -> indices 0..=n (len n+1).
                // An empty array `DIM a[]` (is_array, no size) has len 0.
                let len = match size {
                    Some(sz) => match eval(program, sz, state)? {
                        RuntimeValue::Integer(i) => (i.max(0) as usize).wrapping_add(1),
                        n => {
                            return Err(RuntimeError::TypeMismatch {
                                expected: ValueType::Integer,
                                actual: n.value_type(),
                            })
                        }
                    },
                    None => 0,
                };
                if *is_array {
                    if *redim {
                        // REDIM resizes preserving existing contents (grow:
                        // default-fill the new tail; shrink: truncate). REDIM of
                        // an undeclared name creates it (legacy XBasic).
                        state
                            .slots
                            .entry(symbol.name.clone())
                            .or_insert_with(|| TypedSlot::new_array(symbol.value_type, 0))
                            .array_resize(len);
                    } else {
                        state.slots.insert(
                            symbol.name.clone(),
                            TypedSlot::new_array(symbol.value_type, len),
                        );
                    }
                } else {
                    state
                        .slots
                        .insert(symbol.name.clone(), TypedSlot::new(symbol.value_type));
                }
            }
            IrItem::Assignment { target, value } => {
                let v = eval(program, value, state)?;
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
                value,
            } => {
                let idx_val = eval(program, index, state)?;
                let v =
                    crate::helpers::coerce_value(eval(program, value, state)?, target.value_type);
                let i = match idx_val {
                    RuntimeValue::Integer(i) => i as usize,
                    _ => {
                        return Err(RuntimeError::TypeMismatch {
                            expected: ValueType::Integer,
                            actual: idx_val.value_type(),
                        })
                    }
                };
                let slot =
                    state
                        .slots
                        .get_mut(&target.name)
                        .ok_or_else(|| RuntimeError::UnknownSlot {
                            name: target.name.clone(),
                        })?;
                slot.array_set(i, v)?;
            }
            IrItem::MidAssign {
                target,
                start,
                length,
                value,
            } => {
                // Target must be a symbol (string variable)
                let target_name = match &target.kind {
                    IrExprKind::Symbol(s) => &s.name,
                    _ => {
                        return Err(RuntimeError::UnknownSlot {
                            name: "mid_assign target".into(),
                        });
                    }
                };
                let start_val = eval(program, start, state)?;
                let len_val = if let Some(len_expr) = length {
                    Some(eval(program, len_expr, state)?)
                } else {
                    None
                };
                let src_val = eval(program, value, state)?;
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
                    state
                        .slots
                        .get_mut(target_name)
                        .ok_or_else(|| RuntimeError::UnknownSlot {
                            name: target_name.clone(),
                        })?;
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
                let _ = eval(program, value, state)?;
                let _ = name;
                let _ = args;
            }
            IrItem::SharedAssignment { target, value } => {
                crate::interpreter_select::exec_shared(target, value, program, state)?;
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                let cond = eval(program, condition, state)?;
                if let RuntimeValue::Integer(v) = cond {
                    if v != 0 {
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
                    let cond = eval(program, condition, state)?;
                    if let RuntimeValue::Integer(v) = cond {
                        if v == 0 {
                            break;
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
                        let v = eval(program, cond, state)?;
                        if let RuntimeValue::Integer(n) = v {
                            if (*is_while && n == 0) || (!*is_while && n != 0) {
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
                        let v = eval(program, cond, state)?;
                        if let RuntimeValue::Integer(n) = v {
                            if (*is_while && n == 0) || (!*is_while && n != 0) {
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
                return crate::exec_helpers::exec_return(program, value, state)
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
                let val = eval(program, expr, state)?;
                let RuntimeValue::Integer(addr) = val else {
                    return Err(RuntimeError::TypeMismatch {
                        expected: ValueType::Integer,
                        actual: val.value_type(),
                    });
                };
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
            IrItem::GotoExpr(expr) => {
                let val = eval(program, expr, state)?;
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
