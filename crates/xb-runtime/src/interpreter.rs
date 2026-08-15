use crate::eval::eval;
use crate::helpers::require_type;
pub use crate::slot::{
    DataEntry, ExecutionState, ProgramMetadata, RuntimeError, RuntimeValue, TypedSlot,
};
use xb_compiler::{IrItem, IrProgram, ValueType};
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
}

pub(crate) fn exec_items(
    program: &IrProgram,
    items: &[IrItem],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<Flow, RuntimeError> {
    for item in items {
        match item {
            IrItem::Version(v) => state.metadata.version = Some(v.clone()),
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
                let idx = eval(program, index, state)?;
                let v = eval(program, value, state)?;
                let i = match idx {
                    RuntimeValue::Integer(i) => i as usize,
                    _ => {
                        return Err(RuntimeError::TypeMismatch {
                            expected: ValueType::Integer,
                            actual: idx.value_type(),
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
                            Flow::Continue => {}
                        }
                    } else if let Some(eb) = else_body {
                        match exec_items(program, eb, state, output)? {
                            Flow::Return(r) => return Ok(Flow::Return(r)),
                            Flow::Break => return Ok(Flow::Break),
                            Flow::Continue => {}
                        }
                    }
                }
            }
            IrItem::While { condition, body } => loop {
                let cond = eval(program, condition, state)?;
                if let RuntimeValue::Integer(v) = cond {
                    if v == 0 {
                        break;
                    }
                }
                match exec_items(program, body, state, output)? {
                    Flow::Return(r) => return Ok(Flow::Return(r)),
                    Flow::Break => break,
                    Flow::Continue => {}
                }
            },
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => loop {
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
            },
            IrItem::For { .. } => match crate::eval::exec_for(program, item, state, output)? {
                Flow::Return(r) => return Ok(Flow::Return(r)),
                Flow::Break => {}
                Flow::Continue => {}
            },
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
            }
            IrItem::Call { name, args } => drop(crate::call::call_function(
                program, name, args, state, output,
            )?),
            IrItem::Return { value } => {
                return crate::exec_helpers::exec_return(program, value, state)
            }
            IrItem::Compound(items) => {
                let flow = exec_items(program, items, state, output)?;
                if !matches!(flow, Flow::Continue) {
                    return Ok(flow);
                }
            }
            IrItem::Read(symbols) => crate::data_segment::exec_read(symbols, state)?,
            IrItem::Restore(_) => crate::data_segment::exec_restore(state),
            IrItem::Stop => return Ok(Flow::Return(None)),
        }
    }
    Ok(Flow::Continue)
}
