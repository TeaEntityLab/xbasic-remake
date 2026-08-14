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
            _ => Err(self.expected("statement")),
        }
    }

    fn version_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Version)?;
        let version = self.expect_string()?;
        self.consume_line_tail();
        Ok(Statement::Version(version))
    }

    fn print_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Print)?;
        let expr = self.expression()?;
        self.consume_line_tail();
        Ok(Statement::Print(expr))
    }

    fn dim_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Dim)?;
        let (name, suffix) = self.expect_identifier()?;
        self.consume_line_tail();
        Ok(Statement::Dim { name, suffix })
    }

    fn function_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Function)?;
        let (name, _) = self.expect_identifier()?;
        self.consume_line_tail();
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_end_function() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::Function)?;
        self.consume_line_tail();
        Ok(Statement::Function(FunctionDecl::new(name, body)))
    }

    fn expression(&mut self) -> Result<Expression, ParseError> {
        match self.advance_kind() {
            TokenKind::StringLiteral(value) => Ok(Expression::StringLiteral(value)),
            TokenKind::IntegerLiteral(value) => Ok(Expression::IntegerLiteral(value)),
            TokenKind::FloatLiteral(value) => Ok(Expression::FloatLiteral(value)),
            TokenKind::Identifier { name, suffix } => Ok(Expression::Identifier { name, suffix }),
            _ => Err(self.expected("expression")),
        }
    }

    fn expect_identifier(&mut self) -> Result<(String, Option<TypeSuffix>), ParseError> {
        match self.advance_kind() {
            TokenKind::Identifier { name, suffix } => Ok((name, suffix)),
            _ => Err(self.expected("identifier")),
        }
    }

    fn expect_string(&mut self) -> Result<String, ParseError> {
        match self.advance_kind() {
            TokenKind::StringLiteral(value) => Ok(value),
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

    fn consume_line_tail(&mut self) {
        while !self.at_eof() {
            if matches!(self.peek_kind(), TokenKind::Newline) {
                self.index += 1;
                return;
            }
            self.index += 1;
        }
    }

    fn skip_newlines(&mut self) {
        while matches!(self.peek_kind(), TokenKind::Newline) {
            self.index += 1;
        }
    }

    fn advance_kind(&mut self) -> TokenKind {
        let kind = self.peek_kind().clone();
        if !matches!(kind, TokenKind::Eof) {
            self.index += 1;
        }
        kind
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_bootstrap_subset_when_program_has_function_body() {
        let src = "VERSION \"6.5.0\"\nDIM name$\nFUNCTION Main\nPRINT \"hello\"\nEND FUNCTION\n";
        let program = parse_program(src).unwrap();
        assert_eq!(program.statements.len(), 3);
        assert!(matches!(program.statements[0], Statement::Version(_)));
        assert!(matches!(
            program.statements[1],
            Statement::Dim {
                suffix: Some(TypeSuffix::String),
                ..
            }
        ));
        assert!(matches!(program.statements[2], Statement::Function(_)));
    }
}
