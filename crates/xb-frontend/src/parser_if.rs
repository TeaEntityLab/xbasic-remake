use crate::ast::{ComparisonOp, DataValue, Expression, Statement};
use crate::parser::{ParseError, Parser};
use crate::token::{Keyword, TokenKind};

impl Parser {
    pub(crate) fn parse_if_chain(&mut self) -> Result<Statement, ParseError> {
        let condition = self.expression()?;
        self.expect_keyword(Keyword::Then)?;
        self.parse_if_chain_with_cond(condition)
    }

    pub(crate) fn parse_if_chain_with_cond(
        &mut self,
        condition: Expression,
    ) -> Result<Statement, ParseError> {
        self.expect_line_end()?;
        let mut then_body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_if_boundary() {
            then_body.push(self.statement()?);
            self.skip_newlines();
        }
        let else_body = if self.starts_elseif() {
            self.index += 1;
            Some(vec![self.parse_if_chain()?])
        } else if self.starts_else() {
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
        Ok(Statement::If {
            condition,
            then_body,
            else_body,
        })
    }

    fn if_cond_stmt(&mut self, is_zero: bool) -> Result<Statement, ParseError> {
        self.index += 1;
        let cond = self.expression()?;
        let zero = Expression::IntegerLiteral("0".to_string());
        let condition = if is_zero {
            Expression::Comparison {
                op: ComparisonOp::Equal,
                left: Box::new(cond),
                right: Box::new(zero),
            }
        } else {
            Expression::Comparison {
                op: ComparisonOp::NotEqual,
                left: Box::new(cond),
                right: Box::new(zero),
            }
        };
        self.expect_keyword(Keyword::Then)?;
        let stmt = self.parse_if_chain_with_cond(condition)?;
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::If)?;
        self.expect_line_end()?;
        Ok(stmt)
    }

    pub(crate) fn ifz_stmt(&mut self) -> Result<Statement, ParseError> {
        self.if_cond_stmt(true)
    }

    pub(crate) fn ift_stmt(&mut self) -> Result<Statement, ParseError> {
        self.if_cond_stmt(false)
    }

    pub(crate) fn iff_stmt(&mut self) -> Result<Statement, ParseError> {
        self.if_cond_stmt(true)
    }
    pub(crate) fn doevents_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::Program(String::new()))
    }
    pub(crate) fn randomize_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::Program(String::new()))
    }
}

impl Parser {
    pub(crate) fn gosub_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        let _ = self.expect_identifier()?;
        self.expect_line_end()?;
        Ok(Statement::Program(String::new()))
    }

    pub(crate) fn break_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::ExitLoop)
    }

    pub(crate) fn goto_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        let (name, _) = self.expect_identifier()?;
        self.expect_line_end()?;
        Ok(Statement::Goto(name))
    }

    pub(crate) fn stop_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::Stop)
    }

    pub(crate) fn label_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 2;
        Ok(Statement::Program(String::new()))
    }
}

impl Parser {
    pub(crate) fn data_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        let mut values = Vec::new();
        loop {
            let val = self.parse_data_value()?;
            values.push(val);
            if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
            } else {
                break;
            }
        }
        self.expect_line_end()?;
        Ok(Statement::Data(values))
    }
    fn parse_data_value(&mut self) -> Result<DataValue, ParseError> {
        match self.peek_kind().clone() {
            TokenKind::StringLiteral(s) => {
                self.index += 1;
                Ok(DataValue::String(s))
            }
            TokenKind::IntegerLiteral(s) => {
                self.index += 1;
                Ok(DataValue::Integer(s))
            }
            TokenKind::FloatLiteral(s) => {
                self.index += 1;
                Ok(DataValue::Float(s))
            }
            TokenKind::Symbol('-') => {
                self.index += 1;
                match self.peek_kind().clone() {
                    TokenKind::IntegerLiteral(n) => {
                        self.index += 1;
                        Ok(DataValue::Integer(format!("-{n}")))
                    }
                    TokenKind::FloatLiteral(f) => {
                        self.index += 1;
                        Ok(DataValue::Float(format!("-{f}")))
                    }
                    _ => Err(self.expected("number after -")),
                }
            }
            _ => Err(self.expected("data value")),
        }
    }
    pub(crate) fn read_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        let mut vars = Vec::new();
        loop {
            let (name, suffix) = self.expect_identifier()?;
            vars.push((name, suffix));
            if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
            } else {
                break;
            }
        }
        self.expect_line_end()?;
        Ok(Statement::Read(vars))
    }
    pub(crate) fn restore_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        if self.at_line_end() {
            self.expect_line_end()?;
            Ok(Statement::Restore(None))
        } else {
            let (name, _) = self.expect_identifier()?;
            self.expect_line_end()?;
            Ok(Statement::Restore(Some(name)))
        }
    }
}

impl Parser {
    pub(crate) fn version_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Version)?;
        let version = self.expect_string()?;
        self.expect_line_end()?;
        Ok(Statement::Version(version))
    }
}
