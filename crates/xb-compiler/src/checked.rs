use thiserror::Error;
use xb_frontend::TypeSuffix;
pub use xb_frontend::{ArithmeticOp, BooleanOp, ComparisonOp, LogicalOp, Param, PrintSep, UnaryOp};

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
            Some(TypeSuffix::Integer | TypeSuffix::Giant) | None => Self::Integer,
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
    #[error("comparison operand type mismatch: {left:?} vs {right:?}")]
    ComparisonTypeMismatch { left: ValueType, right: ValueType },
    #[error("unknown function {name}")]
    UnknownFunction { name: String },
    #[error("function {name} expects {expected} args, got {actual}")]
    FunctionArgCount {
        name: String,
        expected: usize,
        actual: usize,
    },
    #[error("function {name} arg {index} type mismatch: expected {expected:?}, got {actual:?}")]
    FunctionArgType {
        name: String,
        index: usize,
        expected: ValueType,
        actual: ValueType,
    },
    #[error("return outside function")]
    ReturnOutsideFunction,
    #[error("return type mismatch: expected {expected:?}, got {actual:?}")]
    ReturnTypeMismatch {
        expected: ValueType,
        actual: ValueType,
    },
    #[error("arithmetic on string operand")]
    ArithmeticStringOperand,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedProgram {
    pub items: Vec<CheckedItem>,
    pub data_values: Vec<xb_frontend::DataValue>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CheckedItem {
    Version(String),
    ProgramName(String),
    Print {
        items: Vec<CheckedExpr>,
        separators: Vec<PrintSep>,
    },
    Dim {
        symbol: CheckedSymbol,
        size: Option<CheckedExpr>,
    },
    Assignment {
        target: CheckedSymbol,
        value: CheckedExpr,
    },
    ArrayAssignment {
        target: CheckedSymbol,
        index: CheckedExpr,
        value: CheckedExpr,
    },
    MidAssign {
        target: CheckedExpr,
        start: CheckedExpr,
        length: Option<CheckedExpr>,
        value: CheckedExpr,
    },
    BuiltinAssign {
        name: String,
        args: Vec<CheckedExpr>,
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
    While {
        condition: CheckedExpr,
        body: Vec<CheckedItem>,
    },
    DoLoop {
        pre_condition: Option<(CheckedExpr, bool)>,
        post_condition: Option<(CheckedExpr, bool)>,
        body: Vec<CheckedItem>,
    },
    For {
        var: CheckedSymbol,
        start: CheckedExpr,
        end: CheckedExpr,
        step: Option<CheckedExpr>,
        body: Vec<CheckedItem>,
    },
    Return {
        value: Option<CheckedExpr>,
    },
    Call {
        name: String,
        args: Vec<CheckedExpr>,
    },
    ExitLoop,
    ExitSelect,
    Swap {
        left: CheckedSymbol,
        right: CheckedSymbol,
    },
    Function {
        name: String,
        params: Vec<CheckedParam>,
        return_type: ValueType,
        body: Vec<CheckedItem>,
    },
    Nop,
    SelectCase {
        selector: CheckedExpr,
        cases: Vec<CheckedCaseClause>,
        default: Option<Vec<CheckedItem>>,
    },
    Compound(Vec<CheckedItem>),
    Read(Vec<CheckedSymbol>),
    Stop,
    Restore(Option<String>),
    Gosub(String),
    Label(String),
    Goto(String),
    GosubReturn,
    GosubExpr(CheckedExpr),
    GotoExpr(CheckedExpr),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedCaseClause {
    pub conditions: Vec<CheckedExpr>,
    pub body: Vec<CheckedItem>,
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
    Constant {
        name: String,
        value: String,
    },
    SharedVariable(CheckedSymbol),
    Symbol(CheckedSymbol),
    Comparison {
        op: ComparisonOp,
        left: Box<CheckedExpr>,
        right: Box<CheckedExpr>,
    },
    Arithmetic {
        op: ArithmeticOp,
        left: Box<CheckedExpr>,
        right: Box<CheckedExpr>,
    },
    Unary {
        op: xb_frontend::UnaryOp,
        operand: Box<CheckedExpr>,
    },
    Not(Box<CheckedExpr>),
    Boolean {
        op: BooleanOp,
        left: Box<CheckedExpr>,
        right: Box<CheckedExpr>,
    },
    Logical {
        op: LogicalOp,
        left: Box<CheckedExpr>,
        right: Box<CheckedExpr>,
    },
    FunctionCall {
        name: String,
        args: Vec<CheckedExpr>,
    },
    ArrayAccess {
        symbol: CheckedSymbol,
        index: Box<CheckedExpr>,
    },
    ArrayRef {
        symbol: CheckedSymbol,
    },
    ArrayUBound {
        symbol: CheckedSymbol,
    },
    SizeOf {
        symbol: CheckedSymbol,
    },
    SizeOfType {
        value_type: ValueType,
    },
    LabelAddress(String),
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

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedParam {
    pub name: String,
    pub value_type: ValueType,
}

impl CheckedParam {
    pub(crate) fn from_ast(p: &Param) -> Self {
        Self {
            name: p.name.clone(),
            value_type: ValueType::from_suffix(p.suffix),
        }
    }
}
