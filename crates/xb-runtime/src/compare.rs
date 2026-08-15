use xb_compiler::{ComparisonOp, ValueType};

use crate::interpreter::{RuntimeError, RuntimeValue};

pub fn compare(op: ComparisonOp, l: &RuntimeValue, r: &RuntimeValue) -> Result<i32, RuntimeError> {
    let ord = match (l, r) {
        (RuntimeValue::Integer(a), RuntimeValue::Integer(b)) => a.cmp(b),
        (RuntimeValue::Float(a), RuntimeValue::Float(b)) => {
            a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)
        }
        (RuntimeValue::String(a), RuntimeValue::String(b)) => a.cmp(b),
        _ => {
            return Err(RuntimeError::TypeMismatch {
                expected: ValueType::Integer,
                actual: ValueType::String,
            })
        }
    };
    let result = match op {
        ComparisonOp::Equal => ord.is_eq(),
        ComparisonOp::NotEqual => !ord.is_eq(),
        ComparisonOp::Less => ord.is_lt(),
        ComparisonOp::Greater => ord.is_gt(),
        ComparisonOp::LessEqual => !ord.is_gt(),
        ComparisonOp::GreaterEqual => !ord.is_lt(),
    };
    Ok(if result { -1 } else { 0 })
}
