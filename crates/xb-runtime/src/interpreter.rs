use std::collections::{btree_map::Entry, BTreeMap};

use thiserror::Error;
use xb_compiler::{EntryLookupError, IrExpr, IrExprKind, IrItem, IrProgram, IrSymbol, ValueType};

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
    value_type: ValueType,
    value: RuntimeValue,
}

impl TypedSlot {
    fn new(value_type: ValueType) -> Self {
        Self {
            value_type,
            value: RuntimeValue::default_for(value_type),
        }
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
    metadata: ProgramMetadata,
    slots: BTreeMap<String, TypedSlot>,
    shared: BTreeMap<String, TypedSlot>,
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
        execute_items(&program.items, &mut state, output)?;
        Ok(state)
    }

    pub fn execute_main(
        &self,
        program: &IrProgram,
        output: &mut Vec<String>,
    ) -> Result<ExecutionState, RuntimeError> {
        let mut state = ExecutionState::default();
        execute_items(&program.items, &mut state, output)?;
        execute_items(program.entry("Main")?, &mut state, output)?;
        Ok(state)
    }
}

fn execute_items(
    items: &[IrItem],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<(), RuntimeError> {
    for item in items {
        match item {
            IrItem::Version(version) => state.metadata.version = Some(version.clone()),
            IrItem::Print(expr) => output.push(evaluate(expr, state)?.render()),
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
                let v = evaluate(value, state)?;
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
                let value = evaluate(value, state)?;
                require_type(target.value_type, value.value_type())?;
                let slot = state
                    .shared
                    .entry(target.name.clone())
                    .or_insert_with(|| TypedSlot::new(target.value_type));
                require_type(slot.value_type, target.value_type)?;
                slot.value = value;
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                let cond = evaluate(condition, state)?;
                if let RuntimeValue::Integer(v) = cond {
                    if v != 0 {
                        execute_items(then_body, state, output)?;
                    } else if let Some(else_body) = else_body {
                        execute_items(else_body, state, output)?;
                    }
                }
            }
            IrItem::Function { name: _, body: _ } => {}
        }
    }
    Ok(())
}

fn evaluate(expr: &IrExpr, state: &ExecutionState) -> Result<RuntimeValue, RuntimeError> {
    let value = match &expr.kind {
        IrExprKind::StringLiteral(value) => RuntimeValue::String(value.clone()),
        IrExprKind::IntegerLiteral(value) => RuntimeValue::Integer(parse_integer(value)?),
        IrExprKind::FloatLiteral(value) => RuntimeValue::Float(parse_float(value)?),
        IrExprKind::Constant { value, .. } => RuntimeValue::Integer(parse_integer(value)?),
        IrExprKind::Comparison { op, left, right } => {
            let l = evaluate(left, state)?;
            let r = evaluate(right, state)?;
            RuntimeValue::Integer(crate::compare::compare(*op, &l, &r)?)
        }
        IrExprKind::SharedVariable(symbol) => read_slot(&state.shared, symbol)?,
        IrExprKind::Symbol(symbol) => read_slot(&state.slots, symbol)?,
    };
    require_type(expr.value_type, value.value_type())?;
    Ok(value)
}

fn read_slot(
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

fn parse_integer(literal: &str) -> Result<i32, RuntimeError> {
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

fn parse_float(literal: &str) -> Result<f64, RuntimeError> {
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

fn require_type(expected: ValueType, actual: ValueType) -> Result<(), RuntimeError> {
    if expected == actual {
        Ok(())
    } else {
        Err(RuntimeError::TypeMismatch { expected, actual })
    }
}
