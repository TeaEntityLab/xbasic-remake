use crate::eval::eval;
use crate::helpers::require_type;
pub use crate::slot::{
    DataEntry, ExecutionState, ProgramMetadata, RuntimeError, RuntimeValue, TypedSlot,
};
use xb_compiler::{IrExpr, IrExprKind, IrItem, IrProgram, ValueType};
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
        exec_items(program, &program.items, &mut state, output)?;
        Ok(state)
    }

    pub fn execute_main(
        &self,
        program: &IrProgram,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState::default();
        crate::data_segment::init_data_segment(program, &mut state);
        exec_items(program, &program.items, &mut state, output)?;
        exec_items(program, program.entry("Main")?, &mut state, output)?;
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
        exec_items(program, &program.items, &mut state, output)?;
        exec_items(program, program.entry("Main")?, &mut state, output)?;
        Ok(state)
    }
}

pub(crate) enum Flow {
    Continue,
    Break,
    Return(Option<RuntimeValue>),
    Goto(String),
    Gosub(String),
    GosubReturn,
}

pub(crate) fn exec_items(
    program: &IrProgram,
    items: &[IrItem],
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

    let mut idx = 0;
    while idx < items.len() {
        let item = &items[idx];
        match item {
            IrItem::Version(v) => state.metadata.version = Some(v.clone()),
            IrItem::ProgramName(v) => state.metadata.program_name = Some(v.clone()),
            IrItem::Print { items, separators } => {
                crate::interpreter_select::exec_print(items, separators, program, output, state)?
            }
            IrItem::ConstantDefinition { .. } => {}
            IrItem::Dim { symbol, size } => {
                if state.slots.contains_key(&symbol.name) {
                    return Err(RuntimeError::DuplicateSlot {
                        name: symbol.name.clone(),
                    });
                }
                match size {
                    Some(sz) => {
                        let n = eval(program, sz, state)?;
                        let len = match n {
                            RuntimeValue::Integer(i) => i as usize,
                            _ => {
                                return Err(RuntimeError::TypeMismatch {
                                    expected: ValueType::Integer,
                                    actual: n.value_type(),
                                })
                            }
                        };
                        state.slots.insert(
                            symbol.name.clone(),
                            TypedSlot::new_array(symbol.value_type, len),
                        );
                    }
                    None => {
                        state
                            .slots
                            .insert(symbol.name.clone(), TypedSlot::new(symbol.value_type));
                    }
                }
            }
            IrItem::Assignment { target, value } => {
                let v = eval(program, value, state)?;
                require_type(target.value_type, v.value_type())?;
                let slot =
                    state
                        .slots
                        .get_mut(&target.name)
                        .ok_or_else(|| RuntimeError::UnknownSlot {
                            name: target.name.clone(),
                        })?;
                require_type(slot.value_type, target.value_type)?;
                slot.value = v;
            }
            IrItem::ArrayAssignment {
                target,
                index,
                value,
            } => {
                let idx_val = eval(program, index, state)?;
                let v = eval(program, value, state)?;
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
                require_type(slot.value_type, target.value_type)?;
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
                    if copy > 0 {
                        dst.replace_range(si..si + copy, &src[..copy]);
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
                        match exec_items(program, then_body, state, output)? {
                            Flow::Return(r) => return Ok(Flow::Return(r)),
                            Flow::Break => return Ok(Flow::Break),
                            Flow::Goto(label) => {
                                if let Some(&pos) = label_map.get(label.as_str()) {
                                    idx = pos;
                                    continue;
                                }
                                return Ok(Flow::Goto(label));
                            }
                            Flow::Gosub(label) => {
                                if let Some(&pos) = label_map.get(label.as_str()) {
                                    state.gosub_stack.push(idx + 1);
                                    idx = pos;
                                    continue;
                                }
                                return Ok(Flow::Gosub(label));
                            }
                            Flow::GosubReturn => return Ok(Flow::GosubReturn),
                            Flow::Continue => {}
                        }
                    } else if let Some(eb) = else_body {
                        match exec_items(program, eb, state, output)? {
                            Flow::Return(r) => return Ok(Flow::Return(r)),
                            Flow::Break => return Ok(Flow::Break),
                            Flow::Goto(label) => {
                                if let Some(&pos) = label_map.get(label.as_str()) {
                                    idx = pos;
                                    continue;
                                }
                                return Ok(Flow::Goto(label));
                            }
                            Flow::Gosub(label) => {
                                if let Some(&pos) = label_map.get(label.as_str()) {
                                    state.gosub_stack.push(idx + 1);
                                    idx = pos;
                                    continue;
                                }
                                return Ok(Flow::Gosub(label));
                            }
                            Flow::GosubReturn => return Ok(Flow::GosubReturn),
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
                    match exec_items(program, body, state, output)? {
                        Flow::Return(r) => return Ok(Flow::Return(r)),
                        Flow::Break => break,
                        Flow::Goto(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                idx = pos;
                                continue;
                            }
                            pending_flow = Some(Flow::Goto(label));
                            break;
                        }
                        Flow::Gosub(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                state.gosub_stack.push(idx + 1);
                                idx = pos;
                                continue;
                            }
                            pending_flow = Some(Flow::Gosub(label));
                            break;
                        }
                        Flow::GosubReturn => return Ok(Flow::GosubReturn),
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
                    match exec_items(program, body, state, output)? {
                        Flow::Return(r) => return Ok(Flow::Return(r)),
                        Flow::Break => break,
                        Flow::Goto(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                idx = pos;
                                continue;
                            }
                            pending_flow = Some(Flow::Goto(label));
                            break;
                        }
                        Flow::Gosub(label) => {
                            if let Some(&pos) = label_map.get(label.as_str()) {
                                state.gosub_stack.push(idx + 1);
                                idx = pos;
                                continue;
                            }
                            pending_flow = Some(Flow::Gosub(label));
                            break;
                        }
                        Flow::GosubReturn => return Ok(Flow::GosubReturn),
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
                match crate::eval::exec_for(program, item, state, output)? {
                    Flow::Return(r) => return Ok(Flow::Return(r)),
                    Flow::Break => {}
                    Flow::Goto(label) => {
                        if let Some(&pos) = label_map.get(label.as_str()) {
                            idx = pos;
                            continue;
                        }
                        return Ok(Flow::Goto(label));
                    }
                    Flow::Gosub(label) => {
                        if let Some(&pos) = label_map.get(label.as_str()) {
                            state.gosub_stack.push(idx + 1);
                            idx = pos;
                            continue;
                        }
                        return Ok(Flow::Gosub(label));
                    }
                    Flow::GosubReturn => return Ok(Flow::GosubReturn),
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
                    state,
                    output,
                )?;
                if matches!(flow, Flow::Return(_)) {
                    return Ok(flow);
                }
                if let Flow::Goto(_) = flow {
                    return Ok(flow);
                }
                if let Flow::GosubReturn = flow {
                    return Ok(flow);
                }
            }
            IrItem::Call { name, args } => drop(crate::call::call_function(
                program, name, args, state, output,
            )?),
            IrItem::Return { value } => {
                return crate::exec_helpers::exec_return(program, value, state)
            }
            IrItem::Compound(inner) => {
                let flow = exec_items(program, inner, state, output)?;
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
                if let Some(&pos) = label_map.get(name.as_str()) {
                    state.gosub_stack.push(idx + 1);
                    idx = pos;
                    continue;
                }
                // Label not in this scope; propagate up (outer scope will push return addr)
                return Ok(Flow::Gosub(name.clone()));
            }
            IrItem::GosubReturn => {
                if let Some(ret_idx) = state.gosub_stack.pop() {
                    idx = ret_idx;
                    continue;
                }
                // Empty gosub stack: fall back to function return
                return Ok(Flow::Return(None));
            }
            IrItem::GosubExpr(expr) => {
                let val = eval(program, expr, state)?;
                if let RuntimeValue::Integer(addr) = val {
                    // Address is an index into label_map values
                    // For now, treat as direct label index
                    state.gosub_stack.push(idx + 1);
                    idx = addr as usize;
                    continue;
                }
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: val.value_type(),
                });
            }
            IrItem::GotoExpr(expr) => {
                let val = eval(program, expr, state)?;
                if let RuntimeValue::Integer(addr) = val {
                    idx = addr as usize;
                    continue;
                }
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: val.value_type(),
                });
            }
        }
        idx += 1;
    }
    Ok(Flow::Continue)
}
