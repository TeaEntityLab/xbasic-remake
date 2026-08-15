use crate::ast::{ArithmeticOp, BooleanOp, ComparisonOp, Expression};
use crate::parser::{ParseError, Parser};
use crate::token::{full_name, Keyword, TokenKind, TypeSuffix};

impl Parser {
    pub(crate) fn expression(&mut self) -> Result<Expression, ParseError> {
        self.or_expr()
    }

    fn or_expr(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.and_expr()?;
        while matches!(
            self.peek_kind(),
            TokenKind::Keyword(Keyword::Or) | TokenKind::Keyword(Keyword::Xor)
        ) {
            let is_xor = matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Xor));
            self.index += 1;
            let right = self.and_expr()?;
            left = Expression::Boolean {
                op: if is_xor {
                    BooleanOp::Xor
                } else {
                    BooleanOp::Or
                },
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
        let mut left = self.power_expr()?;
        while let Some(op) = self.mul_op() {
            let right = self.power_expr()?;
            left = Expression::Arithmetic {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn power_expr(&mut self) -> Result<Expression, ParseError> {
        let base = self.primary()?;
        if self.pow_op().is_some() {
            let exp = self.power_expr()?;
            return Ok(Expression::Arithmetic {
                op: ArithmeticOp::Pow,
                left: Box::new(base),
                right: Box::new(exp),
            });
        }
        Ok(base)
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
            TokenKind::Symbol('\\') => Some(ArithmeticOp::IntegerDiv),
            TokenKind::Keyword(Keyword::Mod) => Some(ArithmeticOp::Mod),
            _ => None,
        };
        if op.is_some() {
            self.index += 1;
        }
        op
    }

    fn pow_op(&mut self) -> Option<()> {
        if matches!(self.peek_kind(), TokenKind::Power) {
            self.index += 1;
            return Some(());
        }
        None
    }

    pub(crate) fn primary(&mut self) -> Result<Expression, ParseError> {
        let kind = self.peek_kind().clone();
        match kind {
            TokenKind::Symbol('@') => {
                self.index += 1;
                self.primary()
            }
            TokenKind::StringLiteral(v) => {
                self.index += 1;
                Ok(Expression::StringLiteral(v))
            }
            TokenKind::IntegerLiteral(v) => {
                self.index += 1;
                Ok(Expression::IntegerLiteral(v))
            }
            TokenKind::FloatLiteral(v) => {
                self.index += 1;
                Ok(Expression::FloatLiteral(v))
            }
            TokenKind::SystemConstant(name) => {
                self.index += 1;
                Ok(Expression::SystemConstant { name })
            }
            TokenKind::SystemVariable { name, suffix } => {
                self.index += 1;
                Ok(Expression::SystemVariable { name, suffix })
            }
            TokenKind::Identifier { name, suffix } => self.identifier_expr(name, suffix),
            TokenKind::Symbol('(') => {
                self.index += 1;
                let expr = self.expression()?;
                self.expect_symbol(')')?;
                Ok(expr)
            }
            _ => Err(self.expected("expression")),
        }
    }
    fn identifier_expr(
        &mut self,
        name: String,
        suffix: Option<TypeSuffix>,
    ) -> Result<Expression, ParseError> {
        self.index += 1;
        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            let args = self.parse_args()?;
            let full = full_name(name, suffix);
            Ok(Expression::FunctionCall { name: full, args })
        } else if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            let index = self.expression()?;
            self.expect_symbol(']')?;
            let full = full_name(name, suffix);
            Ok(Expression::ArrayAccess {
                name: full,
                index: Box::new(index),
            })
        } else {
            Ok(Expression::Identifier { name, suffix })
        }
    }
}
