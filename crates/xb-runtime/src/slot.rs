use std::collections::BTreeMap;

use thiserror::Error;
use xb_compiler::{EntryLookupError, ValueType};

#[derive(Debug, Clone, PartialEq)]
pub enum RuntimeValue {
    Integer(i32),
    Float(f64),
    String(Vec<u8>),
}

#[derive(Debug, Clone, PartialEq)]
pub enum DataEntry {
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
            ValueType::String => Self::String(Vec::new()),
        }
    }

    pub(crate) fn render(&self) -> String {
        match self {
            Self::Integer(value) => value.to_string(),
            Self::Float(value) => value.to_string(),
            Self::String(value) => String::from_utf8_lossy(value).into_owned(),
        }
    }

    /// Build a string value from UTF-8 text.
    pub(crate) fn from_str(s: &str) -> Self {
        Self::String(s.as_bytes().to_vec())
    }

    /// Build a string value from an owned `String` without copying bytes.
    pub(crate) fn from_string(s: String) -> Self {
        Self::String(s.into_bytes())
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct TypedSlot {
    pub(crate) value_type: ValueType,
    pub(crate) value: RuntimeValue,
    pub(crate) array: Option<Vec<RuntimeValue>>,
    /// Row-major per-dimension lengths (the shape). `[len]` for 1-D; empty only
    /// for scalars / not-yet-shaped arrays.
    pub(crate) dims: Vec<usize>,
}

impl TypedSlot {
    pub(crate) fn new(value_type: ValueType) -> Self {
        Self {
            value_type,
            value: RuntimeValue::default_for(value_type),
            array: None,
            dims: Vec::new(),
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
    pub(crate) fn new_array_nd(value_type: ValueType, dims: Vec<usize>) -> Self {
        let flat = if dims.is_empty() { 0 } else { dims.iter().product() };
        Self {
            value_type,
            value: RuntimeValue::default_for(value_type),
            array: Some(vec![RuntimeValue::default_for(value_type); flat]),
            dims,
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
    /// Reshape to `dims` (row-major), resizing the flat store to the product of the
    /// dimensions (preserving the common prefix).
    pub(crate) fn array_reshape(&mut self, dims: Vec<usize>) {
        let flat = if dims.is_empty() { 0 } else { dims.iter().product() };
        let fill = RuntimeValue::default_for(self.value_type);
        match &mut self.array {
            Some(arr) => arr.resize(flat, fill),
            None => self.array = Some(vec![fill; flat]),
        }
        self.dims = dims;
    }
    /// Row-major flat offset for `indices` given this slot's shape. Falls back to
    /// the first index when no shape is recorded (1-D). `None` if any subscript is
    /// out of its dimension or the flat offset exceeds the backing store.
    pub(crate) fn array_offset(&self, indices: &[usize]) -> Option<usize> {
        let arr = self.array.as_ref()?;
        if self.dims.is_empty() {
            return indices.first().copied().filter(|&i| i < arr.len());
        }
        let mut off = 0usize;
        for (k, &d) in self.dims.iter().enumerate() {
            let i = indices.get(k).copied().unwrap_or(0);
            if i >= d {
                return None;
            }
            off = off * d + i;
        }
        (off < arr.len()).then_some(off)
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ProgramMetadata {
    pub(crate) version: Option<String>,
    pub(crate) program_name: Option<String>,
}

impl ProgramMetadata {
    pub fn version(&self) -> Option<&str> {
        self.version.as_deref()
    }
}

#[derive(Debug, Default)]
pub struct ExecutionState {
    pub(crate) metadata: ProgramMetadata,
    pub(crate) slots: BTreeMap<String, TypedSlot>,
    pub(crate) shared: BTreeMap<String, TypedSlot>,
    pub(crate) input: Vec<String>,
    pub(crate) input_pos: usize,
    pub(crate) data_segment: Vec<DataEntry>,
    pub(crate) data_pos: usize,
    pub(crate) error_code: i32,
    pub(crate) files: Vec<Option<std::fs::File>>,
    pub(crate) label_addresses: std::collections::HashMap<String, usize>,
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
impl PartialEq for ExecutionState {
    fn eq(&self, other: &Self) -> bool {
        self.metadata == other.metadata
            && self.slots == other.slots
            && self.shared == other.shared
            && self.input == other.input
            && self.input_pos == other.input_pos
            && self.data_segment == other.data_segment
            && self.data_pos == other.data_pos
            && self.error_code == other.error_code
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
    #[error("program quit with code {code}")]
    Quit { code: i32 },
}
