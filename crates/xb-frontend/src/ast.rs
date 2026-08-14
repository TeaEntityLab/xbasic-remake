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
    Print(Expression),
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
    For {
        var: String,
        start: Expression,
        end: Expression,
        body: Vec<Statement>,
    },
    Return {
        value: Option<Expression>,
    },
    Call {
        name: String,
        args: Vec<Expression>,
    },
    Function(FunctionDecl),
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
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BooleanOp {
    And,
    Or,
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
    Arithmetic {
        op: ArithmeticOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    FunctionCall {
        name: String,
        args: Vec<Expression>,
    },
    ArrayAccess {
        name: String,
        index: Box<Expression>,
    },
}
