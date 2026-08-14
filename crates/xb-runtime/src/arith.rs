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
            Ok(RuntimeValue::String(format!("{a}{b}")))
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
        })),
        _ => Err(RuntimeError::TypeMismatch {
            expected: ValueType::Integer,
            actual: l.value_type(),
        }),
    }
}
