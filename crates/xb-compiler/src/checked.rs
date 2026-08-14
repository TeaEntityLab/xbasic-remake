use thiserror::Error;
use xb_frontend::TypeSuffix;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ValueType {
    Integer,
    Float,
    String,
}

impl ValueType {
    pub const fn from_suffix(suffix: Option<TypeSuffix>) -> Self {
        match suffix {
            Some(TypeSuffix::String) => Self::String,
            Some(TypeSuffix::Single | TypeSuffix::Double) => Self::Float,
            Some(TypeSuffix::Integer) | None => Self::Integer,
        }
    }
}

#[derive(Debug, Error, PartialEq, Eq)]
pub enum SemanticError {
    #[error("duplicate symbol {name}")]
    DuplicateSymbol { name: String },
    #[error("unknown symbol {name}")]
    UnknownSymbol { name: String },
    #[error("type mismatch for {name}: expected {expected:?}, got {actual:?}")]
    TypeMismatch {
        name: String,
        expected: ValueType,
        actual: ValueType,
    },
    #[error("duplicate constant {name}")]
    DuplicateConstant { name: String },
    #[error("unknown constant {name}")]
    UnknownConstant { name: String },
    #[error("constant definition {name} is not at top level")]
    ConstantDefinitionNotTopLevel { name: String },
    #[error("unknown shared variable {name}")]
    UnknownSharedVariable { name: String },
    #[error("shared assignment {name} is not inside a function")]
    SharedAssignmentNotInFunction { name: String },
    #[error("if condition must be integer, got {actual:?}")]
    IfConditionNotInteger { actual: ValueType },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedProgram {
    pub items: Vec<CheckedItem>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CheckedItem {
    Version(String),
    Print(CheckedExpr),
    Dim(CheckedSymbol),
    Assignment {
        target: CheckedSymbol,
        value: CheckedExpr,
    },
    ConstantDefinition {
        name: String,
        value: String,
        value_type: ValueType,
    },
    SharedAssignment {
        target: CheckedSymbol,
        value: CheckedExpr,
    },
    If {
        condition: CheckedExpr,
        then_body: Vec<CheckedItem>,
        else_body: Option<Vec<CheckedItem>>,
    },
    Function {
        name: String,
        body: Vec<CheckedItem>,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedExpr {
    pub kind: CheckedExprKind,
    pub value_type: ValueType,
}

impl CheckedExpr {
    pub(crate) const fn new(kind: CheckedExprKind, value_type: ValueType) -> Self {
        Self { kind, value_type }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CheckedExprKind {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    Constant { name: String, value: String },
    SharedVariable(CheckedSymbol),
    Symbol(CheckedSymbol),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedSymbol {
    pub name: String,
    pub value_type: ValueType,
}

impl CheckedSymbol {
    pub(crate) const fn new(name: String, value_type: ValueType) -> Self {
        Self { name, value_type }
    }
}
