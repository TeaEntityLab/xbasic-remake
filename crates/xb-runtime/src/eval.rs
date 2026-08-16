use crate::helpers::{parse_float, parse_integer, read_slot, require_type};
use crate::interpreter::{exec_items, ExecutionState, Flow, RuntimeError, RuntimeValue};
use xb_compiler::{BooleanOp, IrExpr, IrExprKind, IrItem, IrProgram, LogicalOp, ValueType};

pub(crate) fn eval(
    program: &IrProgram,
    expr: &IrExpr,
    state: &mut ExecutionState,
) -> Result<RuntimeValue, RuntimeError> {
    eval_expr(program, expr, state)
}

pub(crate) fn eval_expr(
    program: &IrProgram,
    expr: &IrExpr,
    state: &mut ExecutionState,
) -> Result<RuntimeValue, RuntimeError> {
    let value = match &expr.kind {
        IrExprKind::StringLiteral(v) => RuntimeValue::String(v.clone()),
        IrExprKind::IntegerLiteral(v) => RuntimeValue::Integer(parse_integer(v)?),
        IrExprKind::FloatLiteral(v) => RuntimeValue::Float(parse_float(v)?),
        IrExprKind::Constant { value, .. } => RuntimeValue::Integer(parse_integer(value)?),
        IrExprKind::Comparison { op, left, right } => {
            let l = eval(program, left, state)?;
            let r = eval(program, right, state)?;
            RuntimeValue::Integer(crate::compare::compare(*op, &l, &r)?)
        }
        IrExprKind::Arithmetic { op, left, right } => {
            let l = eval(program, left, state)?;
            let r = eval(program, right, state)?;
            crate::arith::arith(*op, &l, &r)?
        }
        IrExprKind::Not(inner) => {
            let v = eval(program, inner, state)?;
            let RuntimeValue::Integer(n) = v else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: v.value_type(),
                });
            };
            RuntimeValue::Integer(!n)
        }
        IrExprKind::Unary { op, operand } => {
            let v = eval(program, operand, state)?;
            match op {
                xb_compiler::UnaryOp::Neg => match v {
                    RuntimeValue::Integer(n) => RuntimeValue::Integer(-n),
                    RuntimeValue::Float(f) => RuntimeValue::Float(-f),
                    _ => return Err(RuntimeError::TypeMismatch {
                        expected: ValueType::Integer,
                        actual: v.value_type(),
                    }),
                },
                xb_compiler::UnaryOp::Pos => v,
            }
        }
        IrExprKind::Boolean { op, left, right } => {
            let l = eval(program, left, state)?;
            let r = eval(program, right, state)?;
            let (RuntimeValue::Integer(a), RuntimeValue::Integer(b)) = (l, r) else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: ValueType::String,
                });
            };
            RuntimeValue::Integer(match op {
                BooleanOp::And => a & b,
                BooleanOp::Or => a | b,
                BooleanOp::Xor => a ^ b,
            })
        }
        IrExprKind::Logical { op, left, right } => {
            let l = eval(program, left, state)?;
            let r = eval(program, right, state)?;
            let (RuntimeValue::Integer(a), RuntimeValue::Integer(b)) = (l, r) else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: ValueType::String,
                });
            };
            let ta = a != 0;
            let tb = b != 0;
            RuntimeValue::Integer(match op {
                LogicalOp::And => {
                    if ta && tb {
                        -1
                    } else {
                        0
                    }
                }
                LogicalOp::Or => {
                    if ta || tb {
                        -1
                    } else {
                        0
                    }
                }
                LogicalOp::Xor => {
                    if ta != tb {
                        -1
                    } else {
                        0
                    }
                }
            })
        }
        IrExprKind::SharedVariable(s) => read_slot(&state.shared, s)?,
        IrExprKind::Symbol(s) => read_slot(&state.slots, s)?,
        IrExprKind::FunctionCall { name, args } => {
            let mut out = Vec::new();
            return crate::call::call_function(program, name, args, state, &mut out);
        }
        IrExprKind::ArrayAccess { symbol, index } => {
            let idx = eval(program, index, state)?;
            let i = match idx {
                RuntimeValue::Integer(n) => n as usize,
                _ => {
                    return Err(RuntimeError::TypeMismatch {
                        expected: ValueType::Integer,
                        actual: idx.value_type(),
                    })
                }
            };
            let slot = state
                .slots
                .get(&symbol.name)
                .ok_or_else(|| RuntimeError::UnknownSlot {
                    name: symbol.name.clone(),
                })?;
            return slot.array_get(i);
        }
        IrExprKind::ArrayUBound { symbol } => {
            let slot = state
                .slots
                .get(&symbol.name)
                .or_else(|| state.shared.get(&symbol.name))
                .ok_or_else(|| RuntimeError::UnknownSlot {
                    name: symbol.name.clone(),
                })?;
            let len = slot.array.as_ref().map(|a| a.len()).unwrap_or(0);
            return Ok(RuntimeValue::Integer(if len > 0 { (len - 1) as i32 } else { 0 }));
        }
        IrExprKind::SizeOf { symbol } => {
            let slot = state
                .slots
                .get(&symbol.name)
                .or_else(|| state.shared.get(&symbol.name))
                .ok_or_else(|| RuntimeError::UnknownSlot {
                    name: symbol.name.clone(),
                })?;
            if let Some(arr) = &slot.array {
                let elem_size = match symbol.value_type {
                    ValueType::Integer => 4,
                    ValueType::Float => 8,
                    ValueType::String => 8,
                };
                return Ok(RuntimeValue::Integer((arr.len() * elem_size) as i32));
            }
            let size = match slot.value_type() {
                ValueType::Integer => 4,
                ValueType::Float => 8,
                ValueType::String => 8,
            };
            return Ok(RuntimeValue::Integer(size));
        }
        IrExprKind::SizeOfType { value_type } => {
            let size = match value_type {
                ValueType::Integer => 4,
                ValueType::Float => 8,
                ValueType::String => 8,
            };
            return Ok(RuntimeValue::Integer(size));
        }
        IrExprKind::LabelAddress(name) => {
            // Return the index of the label in the current items list
            let idx = state.label_addresses.get(name).copied().unwrap_or(0);
            return Ok(RuntimeValue::Integer(idx as i32));
        }
    };
    require_type(expr.value_type, value.value_type())?;
    Ok(value)
}

pub(crate) fn exec_for(
    program: &IrProgram,
    item: &IrItem,
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<Flow, RuntimeError> {
    let IrItem::For {
        var,
        start,
        end,
        step,
        body,
    } = item
    else {
        return Err(RuntimeError::TypeMismatch {
            expected: ValueType::Integer,
            actual: ValueType::Integer,
        });
    };
    let s = eval(program, start, state)?;
    let e = eval(program, end, state)?;
    let st = match step {
        Some(se) => eval(program, se, state)?,
        None => RuntimeValue::Integer(1),
    };
    let (RuntimeValue::Integer(mut i), RuntimeValue::Integer(ei), RuntimeValue::Integer(si)) =
        (s, e, st)
    else {
        return Err(RuntimeError::TypeMismatch {
            expected: ValueType::Integer,
            actual: ValueType::Float,
        });
    };
    if si == 0 {
        return Err(RuntimeError::TypeMismatch {
            expected: ValueType::Integer,
            actual: ValueType::Integer,
        });
    }
    while if si > 0 { i <= ei } else { i >= ei } {
        let slot = state
            .slots
            .get_mut(&var.name)
            .ok_or_else(|| RuntimeError::UnknownSlot {
                name: var.name.clone(),
            })?;
        slot.value = RuntimeValue::Integer(i);
        match exec_items(program, body, state, output)? {
            Flow::Return(r) => return Ok(Flow::Return(r)),
            Flow::Break => break,
            Flow::Goto(label) => return Ok(Flow::Goto(label)),
            Flow::Gosub(label) => return Ok(Flow::Gosub(label)),
            Flow::GosubReturn => return Ok(Flow::GosubReturn),
            Flow::Continue => {}
        }
        i += si;
    }
    Ok(Flow::Continue)
}
