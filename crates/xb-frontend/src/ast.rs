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

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Expression {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    Identifier {
        name: String,
        suffix: Option<TypeSuffix>,
    },
}
