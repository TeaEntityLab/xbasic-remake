use crate::ast::{Expression, Param, Statement};
use crate::parser::{ParseError, Parser};
use crate::token::{Keyword, SourcePos, TokenKind, TypeSuffix};

impl Parser {
    pub(crate) fn expect_identifier(&mut self) -> Result<(String, Option<TypeSuffix>), ParseError> {
        match self.peek_kind().clone() {
            TokenKind::Identifier { name, suffix } => {
                self.index += 1;
                Ok((name, suffix))
            }
            _ => Err(self.expected("identifier")),
        }
    }

    pub(crate) fn expect_string(&mut self) -> Result<String, ParseError> {
        match self.peek_kind().clone() {
            TokenKind::StringLiteral(value) => {
                self.index += 1;
                Ok(value)
            }
            _ => Err(self.expected("string literal")),
        }
    }

    pub(crate) fn expect_keyword(&mut self, keyword: Keyword) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Keyword(found) if *found == keyword => {
                self.index += 1;
                Ok(())
            }
            _ => Err(self.expected("keyword")),
        }
    }

    pub(crate) fn expect_symbol(&mut self, symbol: char) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Symbol(found) if *found == symbol => {
                self.index += 1;
                Ok(())
            }
            _ => Err(self.expected("symbol")),
        }
    }

    pub(crate) fn expect_line_end(&mut self) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Newline | TokenKind::Symbol(':') => {
                self.index += 1;
                Ok(())
            }
            TokenKind::Eof => Ok(()),
            _ => Err(self.expected("end of line")),
        }
    }

    pub(crate) fn skip_newlines(&mut self) {
        while matches!(
            self.peek_kind(),
            TokenKind::Newline | TokenKind::Symbol(':')
        ) {
            self.index += 1;
        }
    }

    pub(crate) fn at_line_end(&self) -> bool {
        matches!(
            self.peek_kind(),
            TokenKind::Newline | TokenKind::Eof | TokenKind::Symbol(':')
        )
    }

    pub(crate) fn peek_keyword(&self) -> Option<Keyword> {
        match self.peek_kind() {
            TokenKind::Keyword(keyword) => Some(*keyword),
            _ => None,
        }
    }

    pub(crate) fn peek_kind(&self) -> &TokenKind {
        self.tokens
            .get(self.index)
            .map_or(&TokenKind::Eof, |token| &token.kind)
    }

    pub(crate) fn peek_next_kind(&self) -> Option<&TokenKind> {
        self.tokens.get(self.index + 1).map(|token| &token.kind)
    }

    pub(crate) fn at_eof(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Eof)
    }

    pub(crate) fn parse_array_size(&mut self) -> Result<Option<Expression>, ParseError> {
        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.index += 1;
            let e = self.expression()?;
            self.expect_symbol(')')?;
            Ok(Some(e))
        } else if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            let e = self.expression()?;
            self.expect_symbol(']')?;
            Ok(Some(e))
        } else {
            Ok(None)
        }
    }

    pub(crate) fn skip_to_line_end(&mut self) {
        while !self.at_line_end() {
            self.index += 1;
        }
    }

    pub(crate) fn expected(&self, expected: &'static str) -> ParseError {
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

    pub(crate) fn starts_end_function(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::End))
            && matches!(
                self.peek_next_kind(),
                Some(TokenKind::Keyword(Keyword::Function))
            )
    }

    pub(crate) fn starts_end_sub(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::End))
            && matches!(
                self.peek_next_kind(),
                Some(TokenKind::Keyword(Keyword::Sub))
            )
    }
    pub(crate) fn starts_end_if(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::End))
            && matches!(self.peek_next_kind(), Some(TokenKind::Keyword(Keyword::If)))
    }
    pub(crate) fn starts_wend(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Wend))
    }
    pub(crate) fn starts_loop(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Loop))
    }
    pub(crate) fn starts_next(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Next))
    }
    pub(crate) fn starts_else(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Else))
    }
    pub(crate) fn starts_elseif(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::ElseIf))
    }
    pub(crate) fn starts_if_boundary(&self) -> bool {
        self.starts_else() || self.starts_elseif() || self.starts_end_if()
    }
    pub(crate) fn starts_assignment(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
    }
    pub(crate) fn starts_call(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && (matches!(self.peek_next_kind(), Some(TokenKind::Symbol('(')))
                || matches!(self.peek_next_kind(), Some(TokenKind::Symbol('['))))
    }
    pub(crate) fn starts_label(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol(':')))
    }
    pub(crate) fn starts_constant_definition(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::SystemConstant(_))
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
    }
    pub(crate) fn starts_shared_assignment(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::SystemVariable { .. })
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
    }

    pub(crate) fn parse_params(&mut self) -> Result<Vec<Param>, ParseError> {
        self.expect_symbol('(')?;
        let mut params = Vec::new();
        if !matches!(self.peek_kind(), TokenKind::Symbol(')')) {
            loop {
                let (name, suffix) = self.expect_identifier()?;
                params.push(Param { name, suffix });
                if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                    self.index += 1;
                } else {
                    break;
                }
            }
        }
        self.expect_symbol(')')?;
        Ok(params)
    }
    pub(crate) fn parse_args(&mut self) -> Result<Vec<Expression>, ParseError> {
        self.expect_symbol('(')?;
        let mut args = Vec::new();
        if !matches!(self.peek_kind(), TokenKind::Symbol(')')) {
            loop {
                args.push(self.expression()?);
                if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                    self.index += 1;
                } else {
                    break;
                }
            }
        }
        self.expect_symbol(')')?;
        Ok(args)
    }

    pub(crate) fn constant_definition_stmt(&mut self) -> Result<Statement, ParseError> {
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

    pub(crate) fn const_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        let (name, _) = self.expect_identifier()?;
        self.expect_symbol('=')?;
        let TokenKind::IntegerLiteral(value) = self.peek_kind().clone() else {
            return Err(self.expected("integer literal"));
        };
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::ConstantDefinition { name, value })
    }

    pub(crate) fn shared_assignment_stmt(&mut self) -> Result<Statement, ParseError> {
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
}
