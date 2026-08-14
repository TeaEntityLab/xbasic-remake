use std::collections::BTreeMap;

use xb_compiler::{IrSymbol, ValueType};

use crate::interpreter::{RuntimeError, RuntimeValue, TypedSlot};

pub(crate) fn read_slot(
    slots: &BTreeMap<String, TypedSlot>,
    symbol: &IrSymbol,
) -> Result<RuntimeValue, RuntimeError> {
    let slot = slots
        .get(&symbol.name)
        .ok_or_else(|| RuntimeError::UnknownSlot {
            name: symbol.name.clone(),
        })?;
    require_type(symbol.value_type, slot.value_type)?;
    Ok(slot.value.clone())
}

pub(crate) fn parse_integer(literal: &str) -> Result<i32, RuntimeError> {
    let parsed = if let Some(hex) = literal
        .strip_prefix("0x")
        .or_else(|| literal.strip_prefix("0X"))
    {
        i32::from_str_radix(hex, 16)
    } else {
        literal.parse::<i32>()
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

pub(crate) fn require_type(expected: ValueType, actual: ValueType) -> Result<(), RuntimeError> {
    if expected == actual {
        Ok(())
    } else {
        Err(RuntimeError::TypeMismatch { expected, actual })
    }
}
