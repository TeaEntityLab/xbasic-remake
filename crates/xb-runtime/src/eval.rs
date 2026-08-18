use crate::helpers::{parse_float, parse_integer, read_slot};
use crate::interpreter::{exec_items, ExecutionState, Flow, RuntimeError, RuntimeValue};
use xb_compiler::{BooleanOp, IrExpr, IrExprKind, IrItem, IrProgram, LogicalOp, ValueType};


/// 1-based index of the top-level `IrItem::Function` named `target` (0 if absent);
/// the stable runtime value of `&Func` and a `FUNCADDR` slot.
pub(crate) fn function_id(program: &IrProgram, target: &str) -> i32 {
    let mut id = 0;
    for item in &program.items {
        if let IrItem::Function { name, .. } = item {
            id += 1;
            if name == target {
                return id;
            }
        }
    }
    0
}
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
        IrExprKind::StringLiteral(v) => RuntimeValue::from_string(v.clone()),
        IrExprKind::IntegerLiteral(v) => RuntimeValue::Integer(parse_integer(v)?),
        IrExprKind::FloatLiteral(v) => RuntimeValue::Float(parse_float(v)?),
        IrExprKind::Constant { value, .. } => RuntimeValue::Integer(parse_integer(value)?),
        // `@x` reads as the current value of the referenced lvalue; the
        // write-back on return is performed by the call site (call.rs).
        IrExprKind::ByRef(inner) => eval(program, inner, state)?,
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
                    _ => {
                        return Err(RuntimeError::TypeMismatch {
                            expected: ValueType::Integer,
                            actual: v.value_type(),
                        })
                    }
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
        IrExprKind::ArrayAccess {
            symbol,
            index,
            extra_indices,
        } => {
            let mut idxs: Vec<usize> = Vec::with_capacity(1 + extra_indices.len());
            for e in std::iter::once(index.as_ref()).chain(extra_indices.iter()) {
                match eval(program, e, state)? {
                    RuntimeValue::Integer(n) => idxs.push(n as usize),
                    other => {
                        return Err(RuntimeError::TypeMismatch {
                            expected: ValueType::Integer,
                            actual: other.value_type(),
                        })
                    }
                }
            }
            let value = match state.slots.get(&symbol.name) {
                Some(slot) => {
                    let off = slot.array_offset(&idxs).ok_or_else(|| {
                        RuntimeError::ArrayIndexOutOfRange {
                            index: idxs.first().copied().unwrap_or(0) as i32,
                        }
                    })?;
                    slot.array_get(off)?
                }
                // Undeclared array element reads as the type default (auto-declared).
                None => RuntimeValue::default_for(symbol.value_type),
            };
            return Ok(value);
        }
        IrExprKind::ArrayUBound { symbol } => {
            let slot = state
                .slots
                .get(&symbol.name)
                .or_else(|| state.shared.get(&symbol.name));
            let upper = match slot {
                Some(s) if s.array.is_some() => s.array.as_ref().map_or(0, |a| a.len()) as i32 - 1,
                // UBOUND(string$) is the last byte offset = LEN(string$) - 1.
                Some(s) => match &s.value {
                    RuntimeValue::String(st) => st.len() as i32 - 1,
                    _ => -1,
                },
                // Undeclared/empty -> -1 so `FOR i = 0 TO UBOUND(a[])` skips.
                None => -1,
            };
            return Ok(RuntimeValue::Integer(upper));
        }
        IrExprKind::FuncAddr(name) => RuntimeValue::Integer(function_id(program, name)),
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
    // Coerce the result to the expression's declared type (XBasic implicit
    // coercion) rather than erroring on a runtime type difference.
    Ok(crate::helpers::coerce_value(value, expr.value_type))
}

pub(crate) fn exec_for(
    program: &IrProgram,
    item: &IrItem,
    func_body: &[IrItem],
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
        // Auto-declare the loop variable if it was never DIM'd (legacy XBasic).
        let slot = state
            .slots
            .entry(var.name.clone())
            .or_insert_with(|| crate::slot::TypedSlot::new(var.value_type));
        slot.value = RuntimeValue::Integer(i);
        match exec_items(program, body, func_body, 0, state, output)? {
            Flow::Return(r) => return Ok(Flow::Return(r)),
            Flow::Break => break,
            Flow::Goto(label) => return Ok(Flow::Goto(label)),
            Flow::GosubReturn => return Ok(Flow::GosubReturn),
            Flow::Continue => {}
        }
        i += si;
    }
    Ok(Flow::Continue)
}
