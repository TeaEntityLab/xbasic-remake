use xb_compiler::{ComparisonOp, ValueType};

use crate::interpreter::{RuntimeError, RuntimeValue};

pub fn compare(op: ComparisonOp, l: &RuntimeValue, r: &RuntimeValue) -> Result<i32, RuntimeError> {
    let ord = match (l, r) {
        (RuntimeValue::Integer(a), RuntimeValue::Integer(b)) => a.cmp(b),
        (RuntimeValue::Float(a), RuntimeValue::Float(b)) => {
            a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)
        }
        (RuntimeValue::String(a), RuntimeValue::String(b)) => a.cmp(b),
        // Mixed numeric operands promote the integer to float (e.g. `a! = 0`).
        (RuntimeValue::Float(a), RuntimeValue::Integer(b)) => a
            .partial_cmp(&(*b as f64))
            .unwrap_or(std::cmp::Ordering::Equal),
        (RuntimeValue::Integer(a), RuntimeValue::Float(b)) => (*a as f64)
            .partial_cmp(b)
            .unwrap_or(std::cmp::Ordering::Equal),
        // A string compared against a number uses its byte length, so `IFZ s$` (lowered to
        // `s$ == 0`) tests emptiness and `IFNZ s$` tests non-empty. Non-numeric operands
        // otherwise mismatch.
        (RuntimeValue::String(a), RuntimeValue::Integer(b)) => (a.len() as i64).cmp(&(*b as i64)),
        (RuntimeValue::Integer(a), RuntimeValue::String(b)) => (*a as i64).cmp(&(b.len() as i64)),
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
