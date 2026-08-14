use std::collections::{btree_map::Entry, BTreeMap};

use crate::helpers::require_type;
use thiserror::Error;
use xb_compiler::{EntryLookupError, IrExpr, IrItem, IrProgram, ValueType};

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

    fn default_for(value_type: ValueType) -> Self {
        match value_type {
            ValueType::Integer => Self::Integer(0),
            ValueType::Float => Self::Float(0.0),
            ValueType::String => Self::String(String::new()),
        }
    }

    fn render(&self) -> String {
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
}

impl TypedSlot {
    pub(crate) fn new(value_type: ValueType) -> Self {
        Self {
            value_type,
            value: RuntimeValue::default_for(value_type),
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
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ProgramMetadata {
    version: Option<String>,
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
}

#[derive(Debug, Clone, Copy, Default)]
pub struct Interpreter;

impl Interpreter {
    pub const fn new() -> Self {
        Self
    }

    pub fn execute(
        &self,
        program: &IrProgram,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState::default();
        exec_items(program, &program.items, &mut state, output)?;
        Ok(state)
    }

    pub fn execute_main(
        &self,
        program: &IrProgram,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState::default();
        exec_items(program, &program.items, &mut state, output)?;
        exec_items(program, program.entry("Main")?, &mut state, output)?;
        Ok(state)
    }
}

pub(crate) enum Flow {
    Continue,
    Return(Option<RuntimeValue>),
}

pub(crate) fn exec_items(
    program: &IrProgram,
    items: &[IrItem],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<Flow, RuntimeError> {
    for item in items {
        match item {
            IrItem::Version(v) => state.metadata.version = Some(v.clone()),
            IrItem::Print(expr) => output.push(eval(program, expr, state)?.render()),
            IrItem::ConstantDefinition { .. } => {}
            IrItem::Dim { symbol } => match state.slots.entry(symbol.name.clone()) {
                Entry::Vacant(e) => drop(e.insert(TypedSlot::new(symbol.value_type))),
                Entry::Occupied(_) => {
                    return Err(RuntimeError::DuplicateSlot {
                        name: symbol.name.clone(),
                    })
                }
            },
            IrItem::Assignment { target, value } => {
                let v = eval(program, value, state)?;
                require_type(target.value_type, v.value_type())?;
                let slot =
                    state
                        .slots
                        .get_mut(&target.name)
                        .ok_or_else(|| RuntimeError::UnknownSlot {
                            name: target.name.clone(),
                        })?;
                require_type(slot.value_type, target.value_type)?;
                slot.value = v;
            }
            IrItem::SharedAssignment { target, value } => {
                let v = eval(program, value, state)?;
                require_type(target.value_type, v.value_type())?;
                let slot = state
                    .shared
                    .entry(target.name.clone())
                    .or_insert_with(|| TypedSlot::new(target.value_type));
                require_type(slot.value_type, target.value_type)?;
                slot.value = v;
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                let cond = eval(program, condition, state)?;
                if let RuntimeValue::Integer(v) = cond {
                    if v != 0 {
                        match exec_items(program, then_body, state, output)? {
                            Flow::Return(r) => return Ok(Flow::Return(r)),
                            Flow::Continue => {}
                        }
                    } else if let Some(eb) = else_body {
                        match exec_items(program, eb, state, output)? {
                            Flow::Return(r) => return Ok(Flow::Return(r)),
                            Flow::Continue => {}
                        }
                    }
                }
            }
            IrItem::While { condition, body } => loop {
                let cond = eval(program, condition, state)?;
                if let RuntimeValue::Integer(v) = cond {
                    if v == 0 {
                        break;
                    }
                }
                match exec_items(program, body, state, output)? {
                    Flow::Return(r) => return Ok(Flow::Return(r)),
                    Flow::Continue => {}
                }
            },
            IrItem::Function { .. } => {}
            IrItem::Return { value } => {
                let v = match value {
                    Some(e) => Some(eval(program, e, state)?),
                    None => None,
                };
                return Ok(Flow::Return(v));
            }
        }
    }
    Ok(Flow::Continue)
}

pub(crate) fn eval(
    program: &IrProgram,
    expr: &IrExpr,
    state: &ExecutionState,
) -> Result<RuntimeValue, RuntimeError> {
    crate::eval::eval_expr(program, expr, state)
}
