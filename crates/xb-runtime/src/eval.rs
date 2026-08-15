use crate::helpers::{parse_float, parse_integer, read_slot, require_type};
use crate::interpreter::{exec_items, ExecutionState, Flow, RuntimeError, RuntimeValue};
use xb_compiler::{BooleanOp, IrExpr, IrExprKind, IrItem, IrProgram, ValueType};

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
            Flow::Continue => {}
        }
        i += si;
    }
    Ok(Flow::Continue)
}
