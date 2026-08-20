use xb_compiler::{ArithmeticOp, ValueType};

use crate::interpreter::{RuntimeError, RuntimeValue};

pub(crate) fn arith(
    op: ArithmeticOp,
    l: &RuntimeValue,
    r: &RuntimeValue,
) -> Result<RuntimeValue, RuntimeError> {
    match (l, r) {
        (RuntimeValue::String(a), RuntimeValue::String(b)) => {
            if op != ArithmeticOp::Add {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: ValueType::String,
                });
            }
            let mut v = a.clone();
            v.extend_from_slice(b);
            Ok(RuntimeValue::String(v))
        }
        (RuntimeValue::Integer(a), RuntimeValue::Integer(b)) => {
            let v = match op {
                ArithmeticOp::Add => a.wrapping_add(*b),
                ArithmeticOp::Sub => a.wrapping_sub(*b),
                ArithmeticOp::Mul => a.wrapping_mul(*b),
                ArithmeticOp::Div => {
                    if *b == 0 {
                        return Err(RuntimeError::DivisionByZero);
                    }
                    a.wrapping_div(*b)
                }
                ArithmeticOp::IntegerDiv => {
                    if *b == 0 {
                        return Err(RuntimeError::DivisionByZero);
                    }
                    a.wrapping_div(*b)
                }
                ArithmeticOp::Mod => {
                    if *b == 0 {
                        return Err(RuntimeError::DivisionByZero);
                    }
                    a.wrapping_rem(*b)
                }
                ArithmeticOp::Shl => a.wrapping_shl(*b as u32),
                ArithmeticOp::Shr => a.wrapping_shr(*b as u32),
                ArithmeticOp::Pow => {
                    if *b < 0 {
                        return Err(RuntimeError::TypeMismatch {
                            expected: ValueType::Integer,
                            actual: ValueType::Float,
                        });
                    }
                    (*a).wrapping_pow(*b as u32)
                }
            };
            Ok(RuntimeValue::Integer(v))
        }
        (RuntimeValue::Float(a), RuntimeValue::Float(b)) => Ok(RuntimeValue::Float(match op {
            ArithmeticOp::Add => a + b,
            ArithmeticOp::Sub => a - b,
            ArithmeticOp::Mul => a * b,
            ArithmeticOp::Div => {
                if *b == 0.0 {
                    return Err(RuntimeError::DivisionByZero);
                }
                a / b
            }
            ArithmeticOp::IntegerDiv => (a / b).trunc(),
            ArithmeticOp::Mod => a % b,
            ArithmeticOp::Shl => (*a as i32).wrapping_shl(*b as i32 as u32) as f64,
            ArithmeticOp::Shr => (*a as i32).wrapping_shr(*b as i32 as u32) as f64,
            ArithmeticOp::Pow => a.powf(*b),
        })),
        (RuntimeValue::Float(a), RuntimeValue::Integer(b)) => Ok(RuntimeValue::Float(match op {
            ArithmeticOp::Add => a + *b as f64,
            ArithmeticOp::Sub => a - *b as f64,
            ArithmeticOp::Mul => a * *b as f64,
            ArithmeticOp::Div => {
                if *b == 0 {
                    return Err(RuntimeError::DivisionByZero);
                }
                a / *b as f64
            }
            ArithmeticOp::IntegerDiv => (a / *b as f64).trunc(),
            ArithmeticOp::Shl => (*a as i32).wrapping_shl(*b as u32) as f64,
            ArithmeticOp::Shr => (*a as i32).wrapping_shr(*b as u32) as f64,
            ArithmeticOp::Mod => a % *b as f64,
            ArithmeticOp::Pow => a.powf(*b as f64),
        })),
        (RuntimeValue::Integer(a), RuntimeValue::Float(b)) => Ok(RuntimeValue::Float(match op {
            ArithmeticOp::Add => *a as f64 + b,
            ArithmeticOp::Sub => *a as f64 - b,
            ArithmeticOp::Mul => *a as f64 * b,
            ArithmeticOp::Div => {
                if *b == 0.0 {
                    return Err(RuntimeError::DivisionByZero);
                }
                *a as f64 / b
            }
            ArithmeticOp::IntegerDiv => (*a as f64 / b).trunc(),
            ArithmeticOp::Mod => *a as f64 % b,
            ArithmeticOp::Shl => a.wrapping_shl(*b as i32 as u32) as f64,
            ArithmeticOp::Shr => a.wrapping_shr(*b as i32 as u32) as f64,
            ArithmeticOp::Pow => (*a as f64).powf(*b),
        })),
        // GIANT (i64) arithmetic. Mixed Giant/Integer promotes to i64; mixed
        // Giant/Float promotes to f64 (recurse with the Giant widened).
        (RuntimeValue::Giant(a), RuntimeValue::Giant(b)) => {
            Ok(RuntimeValue::Giant(giant_op(op, *a, *b)?))
        }
        (RuntimeValue::Giant(a), RuntimeValue::Integer(b)) => {
            Ok(RuntimeValue::Giant(giant_op(op, *a, *b as i64)?))
        }
        (RuntimeValue::Integer(a), RuntimeValue::Giant(b)) => {
            Ok(RuntimeValue::Giant(giant_op(op, *a as i64, *b)?))
        }
        (RuntimeValue::Giant(a), RuntimeValue::Float(_)) => {
            arith(op, &RuntimeValue::Float(*a as f64), r)
        }
        (RuntimeValue::Float(_), RuntimeValue::Giant(b)) => {
            arith(op, l, &RuntimeValue::Float(*b as f64))
        }
        _ => Err(RuntimeError::TypeMismatch {
            expected: ValueType::Integer,
            actual: l.value_type(),
        }),
    }
}

/// GIANT (i64) arithmetic, mirroring the INTEGER arm but 64-bit wide (no i32
/// truncation) — matches the C backend's `int64_t` GIANT ops.
fn giant_op(op: ArithmeticOp, a: i64, b: i64) -> Result<i64, RuntimeError> {
    Ok(match op {
        ArithmeticOp::Add => a.wrapping_add(b),
        ArithmeticOp::Sub => a.wrapping_sub(b),
        ArithmeticOp::Mul => a.wrapping_mul(b),
        ArithmeticOp::Div | ArithmeticOp::IntegerDiv => {
            if b == 0 {
                return Err(RuntimeError::DivisionByZero);
            }
            a.wrapping_div(b)
        }
        ArithmeticOp::Mod => {
            if b == 0 {
                return Err(RuntimeError::DivisionByZero);
            }
            a.wrapping_rem(b)
        }
        ArithmeticOp::Shl => a.wrapping_shl(b as u32),
        ArithmeticOp::Shr => a.wrapping_shr(b as u32),
        ArithmeticOp::Pow => {
            if b < 0 {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Giant,
                    actual: ValueType::Float,
                });
            }
            a.wrapping_pow(b as u32)
        }
    })
}
