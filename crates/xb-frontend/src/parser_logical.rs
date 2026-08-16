use crate::ast::{Expression, LogicalOp};
use crate::parser::{ParseError, Parser};
use crate::token::TokenKind;

impl Parser {
    pub(crate) fn logical_or_expr(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.logical_and_expr()?;
        while matches!(
            self.peek_kind(),
            TokenKind::LogicalOr | TokenKind::LogicalXor
        ) {
            let is_xor = matches!(self.peek_kind(), TokenKind::LogicalXor);
            self.index += 1;
            let right = self.logical_and_expr()?;
            left = Expression::Logical {
                op: if is_xor {
                    LogicalOp::Xor
                } else {
                    LogicalOp::Or
                },
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    pub(crate) fn logical_and_expr(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.or_expr()?;
        while matches!(self.peek_kind(), TokenKind::LogicalAnd) {
            self.index += 1;
            let right = self.or_expr()?;
            left = Expression::Logical {
                op: LogicalOp::And,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }
}
