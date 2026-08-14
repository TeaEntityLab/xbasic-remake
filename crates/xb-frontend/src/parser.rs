use crate::ast::{Expression, FunctionDecl, Program, Statement};
use crate::lexer::{lex, LexError};
use crate::token::{Keyword, SourcePos, Token, TokenKind, TypeSuffix};
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
    tokens: Vec<Token>,
    index: usize,
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

    fn statement(&mut self) -> Result<Statement, ParseError> {
        match self.peek_keyword() {
            Some(Keyword::Version) => self.version_stmt(),
            Some(Keyword::Print) => self.print_stmt(),
            Some(Keyword::Dim) => self.dim_stmt(),
            Some(Keyword::Function) => self.function_stmt(),
            _ if self.starts_assignment() => self.assignment_stmt(),
            _ => Err(self.expected("statement")),
        }
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
        let (name, _) = self.expect_identifier()?;
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
        Ok(Statement::Function(FunctionDecl::new(name, body)))
    }

    fn expression(&mut self) -> Result<Expression, ParseError> {
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
            TokenKind::Identifier { name, suffix } => {
                self.index += 1;
                Ok(Expression::Identifier { name, suffix })
            }
            _ => Err(self.expected("expression")),
        }
    }

    fn expect_identifier(&mut self) -> Result<(String, Option<TypeSuffix>), ParseError> {
        match self.peek_kind().clone() {
            TokenKind::Identifier { name, suffix } => {
                self.index += 1;
                Ok((name, suffix))
            }
            _ => Err(self.expected("identifier")),
        }
    }

    fn expect_string(&mut self) -> Result<String, ParseError> {
        match self.peek_kind().clone() {
            TokenKind::StringLiteral(value) => {
                self.index += 1;
                Ok(value)
            }
            _ => Err(self.expected("string literal")),
        }
    }

    fn expect_keyword(&mut self, keyword: Keyword) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Keyword(found) if *found == keyword => {
                self.index += 1;
                Ok(())
            }
            _ => Err(self.expected("keyword")),
        }
    }

    fn starts_end_function(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::End))
            && matches!(
                self.peek_next_kind(),
                Some(TokenKind::Keyword(Keyword::Function))
            )
    }

    fn starts_assignment(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
    }

    fn expect_symbol(&mut self, symbol: char) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Symbol(found) if *found == symbol => {
                self.index += 1;
                Ok(())
            }
            _ => Err(self.expected("symbol")),
        }
    }

    fn expect_line_end(&mut self) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Newline => {
                self.index += 1;
                Ok(())
            }
            TokenKind::Eof => Ok(()),
            _ => Err(self.expected("end of line")),
        }
    }

    fn skip_newlines(&mut self) {
        while matches!(self.peek_kind(), TokenKind::Newline) {
            self.index += 1;
        }
    }

    fn peek_keyword(&self) -> Option<Keyword> {
        match self.peek_kind() {
            TokenKind::Keyword(keyword) => Some(*keyword),
            _ => None,
        }
    }

    fn peek_kind(&self) -> &TokenKind {
        self.tokens
            .get(self.index)
            .map_or(&TokenKind::Eof, |token| &token.kind)
    }

    fn peek_next_kind(&self) -> Option<&TokenKind> {
        self.tokens.get(self.index + 1).map(|token| &token.kind)
    }

    fn at_eof(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Eof)
    }

    fn expected(&self, expected: &'static str) -> ParseError {
        let pos = self.current_pos();
        ParseError::Expected {
            expected,
            line: pos.line,
            column: pos.column,
        }
    }

    fn current_pos(&self) -> SourcePos {
        self.tokens
            .get(self.index)
            .map_or(SourcePos::new(0, 0), |token| token.pos)
    }
}
