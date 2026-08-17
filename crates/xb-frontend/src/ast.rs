use crate::token::TypeSuffix;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Program {
    pub statements: Vec<Statement>,
}

impl Program {
    pub fn new(statements: Vec<Statement>) -> Self {
        Self { statements }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Statement {
    Version(String),
    Print {
        items: Vec<Expression>,
        separators: Vec<PrintSep>,
    },
    Dim {
        name: String,
        suffix: Option<TypeSuffix>,
        size: Option<Expression>,
    },
    Assignment {
        target: String,
        suffix: Option<TypeSuffix>,
        value: Expression,
    },
    ArrayAssignment {
        target: String,
        index: Expression,
        value: Expression,
    },
    MidAssign {
        target: Expression,
        start: Expression,
        length: Option<Expression>,
        value: Expression,
    },
    BuiltinAssign {
        name: String,
        args: Vec<Expression>,
        value: Expression,
    },
    ConstantDefinition {
        name: String,
        value: String,
    },
    SharedAssignment {
        name: String,
        suffix: Option<TypeSuffix>,
        value: Expression,
    },
    If {
        condition: Expression,
        then_body: Vec<Statement>,
        else_body: Option<Vec<Statement>>,
    },
    While {
        condition: Expression,
        body: Vec<Statement>,
    },
    DoLoop {
        pre_condition: Option<(Expression, bool)>,
        post_condition: Option<(Expression, bool)>,
        body: Vec<Statement>,
    },
    For {
        var: String,
        start: Expression,
        end: Expression,
        step: Option<Expression>,
        body: Vec<Statement>,
    },
    Return {
        value: Option<Expression>,
    },
    ExitFunction,
    Call {
        name: String,
        args: Vec<Expression>,
    },
    ExitLoop,
    ExitSelect,
    Inc {
        target: String,
        suffix: Option<TypeSuffix>,
    },
    Dec {
        target: String,
        suffix: Option<TypeSuffix>,
    },
    Swap {
        left: String,
        left_suffix: Option<TypeSuffix>,
        right: String,
        right_suffix: Option<TypeSuffix>,
    },
    Function(FunctionDecl),
    Import(String),
    Declare {
        name: String,
        args: Vec<String>,
    },
    Program(String),
    EndProgram,
    SelectCase {
        selector: Expression,
        cases: Vec<CaseClause>,
        default: Option<Vec<Statement>>,
    },
    Goto(Expression),
    Gosub(Expression),
    Label(String),
    Data(Vec<DataValue>),
    Read(Vec<(String, Option<TypeSuffix>)>),
    Stop,
    Restore(Option<String>),
    Compound(Vec<Statement>),
    TypeDecl {
        name: String,
        members: Vec<TypeMember>,
    },
    CompositeDecl {
        type_name: String,
        var: String,
        shared: bool,
        is_array: bool,
    },
}

/// One member of a composite TYPE declaration (e.g. `GIANT .a`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TypeMember {
    pub name: String,
    pub byte_size: usize,
    pub is_float: bool,
    pub is_string: bool,
    /// Raw member type keyword (e.g. `SINGLE`, or a composite type name like
    /// `BICOORD`). Used by the analyzer to recurse into nested composite members.
    pub type_name: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CaseClause {
    pub conditions: Vec<Expression>,
    pub body: Vec<Statement>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DataValue {
    Integer(String),
    Float(String),
    String(String),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrintSep {
    Semicolon,
    Comma,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Param {
    pub name: String,
    pub suffix: Option<TypeSuffix>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FunctionDecl {
    pub name: String,
    pub suffix: Option<TypeSuffix>,
    pub params: Vec<Param>,
    pub body: Vec<Statement>,
}

impl FunctionDecl {
    pub fn new(
        name: String,
        suffix: Option<TypeSuffix>,
        params: Vec<Param>,
        body: Vec<Statement>,
    ) -> Self {
        Self {
            name,
            suffix,
            params,
            body,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComparisonOp {
    Equal,
    NotEqual,
    Less,
    Greater,
    LessEqual,
    GreaterEqual,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ArithmeticOp {
    Add,
    Sub,
    Mul,
    Div,
    IntegerDiv,
    Mod,
    Shl,
    Shr,
    Pow,
}

impl ArithmeticOp {
    pub fn is_integer_op(self) -> bool {
        matches!(self, Self::IntegerDiv | Self::Mod | Self::Shl | Self::Shr)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UnaryOp {
    Neg,
    Pos,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BooleanOp {
    And,
    Or,
    Xor,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LogicalOp {
    And,
    Or,
    Xor,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Expression {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    SystemConstant {
        name: String,
    },
    SystemVariable {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    Identifier {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    ByRefIdentifier {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    Comparison {
        op: ComparisonOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Not(Box<Expression>),
    Boolean {
        op: BooleanOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Logical {
        op: LogicalOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Arithmetic {
        op: ArithmeticOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Unary {
        op: UnaryOp,
        operand: Box<Expression>,
    },
    FunctionCall {
        name: String,
        args: Vec<Expression>,
    },
    ArrayAccess {
        name: String,
        index: Box<Expression>,
    },
    ArrayRef {
        name: String,
    },
}
