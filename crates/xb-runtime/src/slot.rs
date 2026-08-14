use std::collections::BTreeMap;

use thiserror::Error;
use xb_compiler::{EntryLookupError, ValueType};

#[derive(Debug, Clone, PartialEq)]
pub enum RuntimeValue {
    Integer(i32),
    Float(f64),
    String(String),
}

impl RuntimeValue {
    pub const fn value_type(&self) -> ValueType {
        match self {
            Self::Integer(_) => ValueType::Integer,
            Self::Float(_) => ValueType::Float,
            Self::String(_) => ValueType::String,
        }
    }

    pub(crate) fn default_for(value_type: ValueType) -> Self {
        match value_type {
            ValueType::Integer => Self::Integer(0),
            ValueType::Float => Self::Float(0.0),
            ValueType::String => Self::String(String::new()),
        }
    }

    pub(crate) fn render(&self) -> String {
        match self {
            Self::Integer(value) => value.to_string(),
            Self::Float(value) => value.to_string(),
            Self::String(value) => value.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct TypedSlot {
    pub(crate) value_type: ValueType,
    pub(crate) value: RuntimeValue,
    pub(crate) array: Option<Vec<RuntimeValue>>,
}

impl TypedSlot {
    pub(crate) fn new(value_type: ValueType) -> Self {
        Self {
            value_type,
            value: RuntimeValue::default_for(value_type),
            array: None,
        }
    }
    pub(crate) fn set(&mut self, v: RuntimeValue) {
        self.value = v;
    }
    pub const fn value_type(&self) -> ValueType {
        self.value_type
    }
    pub const fn value(&self) -> &RuntimeValue {
        &self.value
    }
    pub(crate) fn new_array(value_type: ValueType, size: usize) -> Self {
        Self {
            value_type,
            value: RuntimeValue::default_for(value_type),
            array: Some(vec![RuntimeValue::default_for(value_type); size]),
        }
    }
    pub(crate) fn array_get(&self, index: usize) -> Result<RuntimeValue, RuntimeError> {
        self.array
            .as_ref()
            .and_then(|a| a.get(index))
            .cloned()
            .ok_or(RuntimeError::ArrayIndexOutOfRange {
                index: index as i32,
            })
    }
    pub(crate) fn array_set(&mut self, index: usize, v: RuntimeValue) -> Result<(), RuntimeError> {
        let arr = self.array.as_mut().ok_or(RuntimeError::NotAnArray)?;
        let slot = arr
            .get_mut(index)
            .ok_or(RuntimeError::ArrayIndexOutOfRange {
                index: index as i32,
            })?;
        *slot = v;
        Ok(())
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ProgramMetadata {
    pub(crate) version: Option<String>,
}

impl ProgramMetadata {
    pub fn version(&self) -> Option<&str> {
        self.version.as_deref()
    }
}

#[derive(Debug, Clone, Default, PartialEq)]
pub struct ExecutionState {
    pub(crate) metadata: ProgramMetadata,
    pub(crate) slots: BTreeMap<String, TypedSlot>,
    pub(crate) shared: BTreeMap<String, TypedSlot>,
}

impl ExecutionState {
    pub const fn metadata(&self) -> &ProgramMetadata {
        &self.metadata
    }
    pub fn slot(&self, name: &str) -> Option<&TypedSlot> {
        self.slots.get(name)
    }
    pub fn shared_slot(&self, name: &str) -> Option<&TypedSlot> {
        self.shared.get(name)
    }
}

#[derive(Debug, Error, PartialEq, Eq)]
pub enum RuntimeError {
    #[error(transparent)]
    EntryLookup(#[from] EntryLookupError),
    #[error("duplicate runtime slot {name}")]
    DuplicateSlot { name: String },
    #[error("unknown runtime slot {name}")]
    UnknownSlot { name: String },
    #[error("runtime type mismatch: expected {expected:?}, got {actual:?}")]
    TypeMismatch {
        expected: ValueType,
        actual: ValueType,
    },
    #[error("invalid {value_type:?} literal {literal}")]
    InvalidLiteral {
        literal: String,
        value_type: ValueType,
    },
    #[error("unknown function {name}")]
    UnknownFunction { name: String },
    #[error("division by zero")]
    DivisionByZero,
    #[error("array index out of range: {index}")]
    ArrayIndexOutOfRange { index: i32 },
    #[error("not an array")]
    NotAnArray,
}
