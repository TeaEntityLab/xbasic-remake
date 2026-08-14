use crate::ast::{Expression, FunctionDecl, Program, Statement};
use crate::lexer::{lex, LexError};
use crate::token::{Keyword, Token, TokenKind, TypeSuffix};
use thiserror::Error;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum ParseError {
    #[error(transparent)]
    Lex(#[from] LexError),
    #[error("expected {expected} at {line}:{column}")]
    Expected {
        expected: &'static str,
        line: usize,
        column: usize,
    },
}

pub fn parse_program(source: &str) -> Result<Program, ParseError> {
    Parser::new(lex(source)?).parse_program()
}

pub struct Parser {
    pub(crate) tokens: Vec<Token>,
    pub(crate) index: usize,
}

impl Parser {
    pub const fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, index: 0 }
    }

    pub fn parse_program(mut self) -> Result<Program, ParseError> {
        let mut statements = Vec::new();
        self.skip_newlines();
        while !self.at_eof() {
            statements.push(self.statement()?);
            self.skip_newlines();
        }
        Ok(Program::new(statements))
    }

    pub(crate) fn statement(&mut self) -> Result<Statement, ParseError> {
        if self.starts_constant_definition() {
            return self.constant_definition_stmt();
        }
        if self.starts_shared_assignment() {
            return self.shared_assignment_stmt();
        }
        match self.peek_keyword() {
            Some(Keyword::Version) => self.version_stmt(),
            Some(Keyword::Print) => self.print_stmt(),
            Some(Keyword::Dim) => self.dim_stmt(),
            Some(Keyword::If) => self.if_stmt(),
            Some(Keyword::While) => self.while_stmt(),
            Some(Keyword::Function) => self.function_stmt(),
            Some(Keyword::Return) => self.return_stmt(),
            _ if self.starts_assignment() => self.assignment_stmt(),
            _ => Err(self.expected("statement")),
        }
    }

    fn constant_definition_stmt(&mut self) -> Result<Statement, ParseError> {
        let TokenKind::SystemConstant(name) = self.peek_kind().clone() else {
            return Err(self.expected("system constant"));
        };
        self.index += 1;
        self.expect_symbol('=')?;
        let TokenKind::IntegerLiteral(value) = self.peek_kind().clone() else {
            return Err(self.expected("integer literal"));
        };
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::ConstantDefinition { name, value })
    }

    fn shared_assignment_stmt(&mut self) -> Result<Statement, ParseError> {
        let TokenKind::SystemVariable { name, suffix } = self.peek_kind().clone() else {
            return Err(self.expected("system variable"));
        };
        self.index += 1;
        self.expect_symbol('=')?;
        let value = self.expression()?;
        self.expect_line_end()?;
        Ok(Statement::SharedAssignment {
            name,
            suffix,
            value,
        })
    }

    fn version_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Version)?;
        let version = self.expect_string()?;
        self.expect_line_end()?;
        Ok(Statement::Version(version))
    }

    fn print_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Print)?;
        let expr = self.expression()?;
        self.expect_line_end()?;
        Ok(Statement::Print(expr))
    }

    fn dim_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Dim)?;
        let (name, suffix) = self.expect_identifier()?;
        self.expect_line_end()?;
        Ok(Statement::Dim { name, suffix })
    }

    fn assignment_stmt(&mut self) -> Result<Statement, ParseError> {
        let (target, suffix) = self.expect_identifier()?;
        self.expect_symbol('=')?;
        let value = self.expression()?;
        self.expect_line_end()?;
        Ok(Statement::Assignment {
            target,
            suffix,
            value,
        })
    }

    fn function_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Function)?;
        let (name, suffix) = self.expect_identifier()?;
        let params = if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.parse_params()?
        } else {
            Vec::new()
        };
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_end_function() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::Function)?;
        self.expect_line_end()?;
        Ok(Statement::Function(FunctionDecl::new(
            name, suffix, params, body,
        )))
    }
    fn if_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::If)?;
        let condition = self.expression()?;
        self.expect_keyword(Keyword::Then)?;
        self.expect_line_end()?;
        let mut then_body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_else() && !self.starts_end_if() {
            then_body.push(self.statement()?);
            self.skip_newlines();
        }
        let else_body = if self.starts_else() {
            self.expect_keyword(Keyword::Else)?;
            self.expect_line_end()?;
            let mut body = Vec::new();
            self.skip_newlines();
            while !self.at_eof() && !self.starts_end_if() {
                body.push(self.statement()?);
                self.skip_newlines();
            }
            Some(body)
        } else {
            None
        };
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::If)?;
        self.expect_line_end()?;
        Ok(Statement::If {
            condition,
            then_body,
            else_body,
        })
    }

    pub(crate) fn expression(&mut self) -> Result<Expression, ParseError> {
        let left = self.additive()?;
        if let Some(op) = self.comparison_op() {
            let right = self.additive()?;
            Ok(Expression::Comparison {
                op,
                left: Box::new(left),
                right: Box::new(right),
            })
        } else {
            Ok(left)
        }
    }

    fn additive(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.multiplicative()?;
        while let Some(op) = self.add_op() {
            let right = self.multiplicative()?;
            left = Expression::Arithmetic {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn multiplicative(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.primary()?;
        while let Some(op) = self.mul_op() {
            let right = self.primary()?;
            left = Expression::Arithmetic {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn primary(&mut self) -> Result<Expression, ParseError> {
        let kind = self.peek_kind().clone();
        match kind {
            TokenKind::StringLiteral(value) => {
                self.index += 1;
                Ok(Expression::StringLiteral(value))
            }
            TokenKind::IntegerLiteral(value) => {
                self.index += 1;
                Ok(Expression::IntegerLiteral(value))
            }
            TokenKind::FloatLiteral(value) => {
                self.index += 1;
                Ok(Expression::FloatLiteral(value))
            }
            TokenKind::SystemConstant(name) => {
                self.index += 1;
                Ok(Expression::SystemConstant { name })
            }
            TokenKind::SystemVariable { name, suffix } => {
                self.index += 1;
                Ok(Expression::SystemVariable { name, suffix })
            }
            TokenKind::Identifier { name, suffix } => {
                self.index += 1;
                if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                    let args = self.parse_args()?;
                    let full = match suffix {
                        Some(TypeSuffix::String) => format!("{name}$"),
                        Some(TypeSuffix::Single) => format!("{name}!"),
                        Some(TypeSuffix::Double) => format!("{name}#"),
                        Some(TypeSuffix::Integer) => format!("{name}%"),
                        None => name,
                    };
                    Ok(Expression::FunctionCall { name: full, args })
                } else {
                    Ok(Expression::Identifier { name, suffix })
                }
            }
            _ => Err(self.expected("expression")),
        }
    }
}
