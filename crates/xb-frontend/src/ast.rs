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
    },
    Assignment {
        target: String,
        suffix: Option<TypeSuffix>,
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
    Function(FunctionDecl),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FunctionDecl {
    pub name: String,
    pub body: Vec<Statement>,
}

impl FunctionDecl {
    pub fn new(name: String, body: Vec<Statement>) -> Self {
        Self { name, body }
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
}
