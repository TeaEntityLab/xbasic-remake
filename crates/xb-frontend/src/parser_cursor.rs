use crate::ast::{ArithmeticOp, ComparisonOp, Expression, Param, Statement};
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
            TokenKind::Newline => {
                self.index += 1;
                Ok(())
            }
            TokenKind::Eof => Ok(()),
            _ => Err(self.expected("end of line")),
        }
    }

    pub(crate) fn skip_newlines(&mut self) {
        while matches!(self.peek_kind(), TokenKind::Newline) {
            self.index += 1;
        }
    }

    pub(crate) fn at_line_end(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Newline | TokenKind::Eof)
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
    pub(crate) fn starts_end_if(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::End))
            && matches!(self.peek_next_kind(), Some(TokenKind::Keyword(Keyword::If)))
    }
    pub(crate) fn starts_wend(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Wend))
    }
    pub(crate) fn starts_else(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Else))
    }
    pub(crate) fn starts_assignment(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
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

impl Parser {
    pub(crate) fn comparison_op(&mut self) -> Option<ComparisonOp> {
        let op = match self.peek_kind() {
            TokenKind::Symbol('=') => Some(ComparisonOp::Equal),
            TokenKind::NotEqual => Some(ComparisonOp::NotEqual),
            TokenKind::Symbol('<') => Some(ComparisonOp::Less),
            TokenKind::Symbol('>') => Some(ComparisonOp::Greater),
            TokenKind::LessEqual => Some(ComparisonOp::LessEqual),
            TokenKind::GreaterEqual => Some(ComparisonOp::GreaterEqual),
            _ => None,
        };
        if op.is_some() {
            self.index += 1;
        }
        op
    }

    pub(crate) fn add_op(&mut self) -> Option<ArithmeticOp> {
        let op = match self.peek_kind() {
            TokenKind::Symbol('+') => Some(ArithmeticOp::Add),
            TokenKind::Symbol('-') => Some(ArithmeticOp::Sub),
            _ => None,
        };
        if op.is_some() {
            self.index += 1;
        }
        op
    }

    pub(crate) fn mul_op(&mut self) -> Option<ArithmeticOp> {
        let op = match self.peek_kind() {
            TokenKind::Symbol('*') => Some(ArithmeticOp::Mul),
            TokenKind::Symbol('/') => Some(ArithmeticOp::Div),
            _ => None,
        };
        if op.is_some() {
            self.index += 1;
        }
        op
    }
}
