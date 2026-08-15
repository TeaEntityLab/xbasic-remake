use crate::ast::{FunctionDecl, Program, Statement};
use crate::lexer::{lex, LexError};
use crate::token::{full_name, Keyword, Token, TokenKind};
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
            Some(Keyword::For) => self.for_stmt(),
            Some(Keyword::While) => self.while_stmt(),
            Some(Keyword::Do) => self.do_stmt(),
            Some(Keyword::Function) => self.function_stmt(),
            Some(Keyword::Exit) => self.exit_stmt(),
            Some(Keyword::Return) => self.return_stmt(),
            _ if self.starts_assignment() => self.assignment_stmt(),
            _ if self.starts_call() => self.call_stmt(),
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
        let size = if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.index += 1;
            let e = self.expression()?;
            self.expect_symbol(')')?;
            Some(e)
        } else {
            None
        };
        self.expect_line_end()?;
        Ok(Statement::Dim { name, suffix, size })
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

    fn call_stmt(&mut self) -> Result<Statement, ParseError> {
        let (name, suffix) = self.expect_identifier()?;
        let args = self.parse_args()?;
        if matches!(self.peek_kind(), TokenKind::Symbol('=')) && args.len() == 1 {
            self.index += 1;
            let value = self.expression()?;
            self.expect_line_end()?;
            let full = full_name(name, suffix);
            return Ok(Statement::ArrayAssignment {
                target: full,
                index: args.into_iter().next().unwrap(),
                value,
            });
        }
        self.expect_line_end()?;
        let full = full_name(name, suffix);
        Ok(Statement::Call { name: full, args })
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
        let stmt = self.parse_if_chain()?;
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::If)?;
        self.expect_line_end()?;
        Ok(stmt)
    }
    fn exit_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Exit)?;
        if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::For)) {
            self.index += 1;
        } else {
            self.expect_keyword(Keyword::While)?;
        }
        self.expect_line_end()?;
        Ok(Statement::ExitLoop)
    }
    pub(crate) fn return_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Return)?;
        let value = if self.at_line_end() {
            None
        } else {
            Some(self.expression()?)
        };
        self.expect_line_end()?;
        Ok(Statement::Return { value })
    }
    pub(crate) fn while_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::While)?;
        let condition = self.expression()?;
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_wend() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::Wend)?;
        self.expect_line_end()?;
        Ok(Statement::While { condition, body })
    }
}
