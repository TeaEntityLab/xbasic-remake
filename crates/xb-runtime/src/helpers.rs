use std::collections::BTreeMap;

use xb_compiler::{IrSymbol, ValueType};

use crate::interpreter::{RuntimeError, RuntimeValue, TypedSlot};

pub(crate) fn read_slot(
    slots: &BTreeMap<String, TypedSlot>,
    symbol: &IrSymbol,
) -> Result<RuntimeValue, RuntimeError> {
    match slots.get(&symbol.name) {
        // Coerce the stored value to the expected type (XBasic implicit coercion).
        Some(slot) => Ok(coerce_value(slot.value.clone(), symbol.value_type)),
        // XBasic auto-declares locals on first use; an unassigned variable
        // reads as its type default (0, 0.0, or "").
        None => Ok(RuntimeValue::default_for(symbol.value_type)),
    }
}

/// Coerce a runtime value to the target type (XBasic implicit coercion:
/// numeric <-> numeric, and to/from string via render/parse).
pub(crate) fn coerce_value(value: RuntimeValue, target: ValueType) -> RuntimeValue {
    match (target, value) {
        (ValueType::Integer, RuntimeValue::Float(f)) => RuntimeValue::Integer(f as i32),
        (ValueType::Integer, RuntimeValue::String(s)) => RuntimeValue::Integer(
            s.trim()
                .parse::<i32>()
                .or_else(|_| s.trim().parse::<f64>().map(|f| f as i32))
                .unwrap_or(0),
        ),
        (ValueType::Float, RuntimeValue::Integer(i)) => RuntimeValue::Float(i as f64),
        (ValueType::Float, RuntimeValue::String(s)) => {
            RuntimeValue::Float(s.trim().parse::<f64>().unwrap_or(0.0))
        }
        (ValueType::String, v @ (RuntimeValue::Integer(_) | RuntimeValue::Float(_))) => {
            RuntimeValue::String(v.render())
        }
        // Already the target type (Integer/Float/String -> same).
        (_, v) => v,
    }
}

pub(crate) fn parse_integer(literal: &str) -> Result<i32, RuntimeError> {
    // XBasic unsigned 32-bit values (e.g. 0xEDB88320) exceed i32::MAX; reinterpret
    // the bit pattern as i32. Wider (GIANT) literals keep the low 32 bits.
    fn radixed(digits: &str, radix: u32) -> Result<i32, std::num::ParseIntError> {
        i32::from_str_radix(digits, radix)
            .or_else(|_| u32::from_str_radix(digits, radix).map(|u| u as i32))
            .or_else(|_| u64::from_str_radix(digits, radix).map(|u| u as i32))
    }
    let parsed = if let Some(h) = literal.strip_prefix("0x").or_else(|| literal.strip_prefix("0X")) {
        radixed(h, 16)
    } else if let Some(b) = literal.strip_prefix("0b").or_else(|| literal.strip_prefix("0B")) {
        radixed(b, 2)
    } else if let Some(o) = literal.strip_prefix("0o").or_else(|| literal.strip_prefix("0O")) {
        radixed(o, 8)
    } else {
        literal
            .parse::<i32>()
            .or_else(|_| literal.parse::<u32>().map(|u| u as i32))
            .or_else(|_| literal.parse::<u64>().map(|u| u as i32))
            .or_else(|_| literal.parse::<i64>().map(|i| i as i32))
    };
    parsed.map_err(|_| invalid_literal(literal, ValueType::Integer))
}

pub(crate) fn parse_float(literal: &str) -> Result<f64, RuntimeError> {
    let value = literal
        .parse::<f64>()
        .map_err(|_| invalid_literal(literal, ValueType::Float))?;
    if value.is_finite() {
        Ok(value)
    } else {
        Err(invalid_literal(literal, ValueType::Float))
    }
}

fn invalid_literal(literal: &str, value_type: ValueType) -> RuntimeError {
    RuntimeError::InvalidLiteral {
        literal: literal.to_string(),
        value_type,
    }
}
