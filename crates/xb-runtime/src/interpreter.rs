use crate::helpers::require_type;
pub use crate::slot::{ExecutionState, ProgramMetadata, RuntimeError, RuntimeValue, TypedSlot};
use xb_compiler::{IrExpr, IrItem, IrProgram, ValueType};
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
        exec_items(program, &program.items, &mut state, output)?;
        Ok(state)
    }

    pub fn execute_main(
        &self,
        program: &IrProgram,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState::default();
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
        let mut state = ExecutionState::default();
        state.input = input;
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
            IrItem::Print(expr) => output.push(eval(program, expr, state)?.render()),
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
                let v = eval(program, value, state)?;
                require_type(target.value_type, v.value_type())?;
                let slot = state
                    .shared
                    .entry(target.name.clone())
                    .or_insert_with(|| TypedSlot::new(target.value_type));
                require_type(slot.value_type, target.value_type)?;
                slot.value = v;
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
            IrItem::For {
                var,
                start,
                end,
                body,
            } => match crate::eval::exec_for(program, var, start, end, body, state, output)? {
                Flow::Return(r) => return Ok(Flow::Return(r)),
                Flow::Break => {}
                Flow::Continue => {}
            },
            IrItem::ExitLoop => return Ok(Flow::Break),
            IrItem::Function { .. } => {}
            IrItem::Call { name, args } => {
                let _ = crate::call::call_function(program, name, args, state, output)?;
            }
            IrItem::Return { value } => {
                let v = match value {
                    Some(e) => Some(eval(program, e, state)?),
                    None => None,
                };
                return Ok(Flow::Return(v));
            }
        }
    }
    Ok(Flow::Continue)
}

pub(crate) fn eval(
    program: &IrProgram,
    expr: &IrExpr,
    state: &mut ExecutionState,
) -> Result<RuntimeValue, RuntimeError> {
    crate::eval::eval_expr(program, expr, state)
}
