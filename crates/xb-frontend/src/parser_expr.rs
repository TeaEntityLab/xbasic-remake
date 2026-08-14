use crate::ast::{BooleanOp, Expression};
use crate::parser::{ParseError, Parser};
use crate::token::{Keyword, TokenKind};

impl Parser {
    pub(crate) fn expression(&mut self) -> Result<Expression, ParseError> {
        self.or_expr()
    }

    fn or_expr(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.and_expr()?;
        while matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Or)) {
            self.index += 1;
            let right = self.and_expr()?;
            left = Expression::Boolean {
                op: BooleanOp::Or,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn and_expr(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.not_expr()?;
        while matches!(self.peek_kind(), TokenKind::Keyword(Keyword::And)) {
            self.index += 1;
            let right = self.not_expr()?;
            left = Expression::Boolean {
                op: BooleanOp::And,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn not_expr(&mut self) -> Result<Expression, ParseError> {
        if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Not)) {
            self.index += 1;
            let inner = self.not_expr()?;
            return Ok(Expression::Not(Box::new(inner)));
        }
        self.comparison_expr()
    }

    fn comparison_expr(&mut self) -> Result<Expression, ParseError> {
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
}
