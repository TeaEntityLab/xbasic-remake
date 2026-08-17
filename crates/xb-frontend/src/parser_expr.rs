use crate::ast::{ArithmeticOp, BooleanOp, ComparisonOp, Expression};
use crate::parser::{ParseError, Parser};
use crate::token::{full_name, Keyword, TokenKind, TypeSuffix};

impl Parser {
    pub(crate) fn expression(&mut self) -> Result<Expression, ParseError> {
        self.logical_or_expr()
    }

    pub(crate) fn or_expr(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.and_expr()?;
        while matches!(
            self.peek_kind(),
            TokenKind::Keyword(Keyword::Or) | TokenKind::Keyword(Keyword::Xor)
                | TokenKind::Symbol('|') | TokenKind::Symbol('^')
        ) {
            let is_xor = matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Xor) | TokenKind::Symbol('^'));
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
        while matches!(self.peek_kind(), TokenKind::Keyword(Keyword::And) | TokenKind::Symbol('&')) {
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
        if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Not)) || matches!(self.peek_kind(), TokenKind::Symbol('!')) {
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
        let base = self.shift_expr()?;
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

    fn shift_expr(&mut self) -> Result<Expression, ParseError> {
        let mut left = self.unary_expr()?;
        while let Some(op) = self.shift_op() {
            let right = self.unary_expr()?;
            left = Expression::Arithmetic {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }
    fn unary_expr(&mut self) -> Result<Expression, ParseError> {
        if matches!(self.peek_kind(), TokenKind::Symbol('-')) {
            self.index += 1;
            let operand = self.unary_expr()?;
            return Ok(Expression::Unary {
                op: crate::ast::UnaryOp::Neg,
                operand: Box::new(operand),
            });
        }
        if matches!(self.peek_kind(), TokenKind::Symbol('+')) {
            self.index += 1;
            let operand = self.unary_expr()?;
            return Ok(Expression::Unary {
                op: crate::ast::UnaryOp::Pos,
                operand: Box::new(operand),
            });
        }
        self.primary()
    }
}

impl Parser {
    fn shift_op(&mut self) -> Option<ArithmeticOp> {
        let op = match self.peek_kind() {
            TokenKind::Shl => Some(ArithmeticOp::Shl),
            TokenKind::Shr => Some(ArithmeticOp::Shr),
            _ => None,
        };
        if op.is_some() {
            self.index += 1;
        }
        op
    }
}

impl Parser {
    pub(crate) fn comparison_op(&mut self) -> Option<ComparisonOp> {
        let op = match self.peek_kind() {
            TokenKind::Symbol('=') | TokenKind::Equal => Some(ComparisonOp::Equal),
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
                // @ prefix means pass-by-reference; produce ByRefIdentifier
                match self.peek_kind().clone() {
                    TokenKind::Identifier { name, suffix } => {
                        self.index += 1;
                        // Skip optional array brackets
                        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                            self.index += 1;
                            if !matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                                let _ = self.expression();
                            }
                            self.expect_symbol(']')?;
                        }
                        // Handle @func() call
                        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                            let args = self.parse_args()?;
                            let full = full_name(name, suffix);
                            return Ok(Expression::FunctionCall { name: full, args });
                        }
                        Ok(Expression::ByRefIdentifier { name, suffix })
                    }
                    TokenKind::SharedName(name) => {
                        self.index += 1;
                        // Skip optional array brackets
                        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                            self.index += 1;
                            if !matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                                let _ = self.expression();
                            }
                            self.expect_symbol(']')?;
                        }
                        Ok(Expression::ByRefIdentifier { name, suffix: None })
                    }
                    TokenKind::Keyword(kw) if !is_statement_keyword(kw) => {
                        self.index += 1;
                        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                            self.index += 1;
                            if !matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                                let _ = self.expression();
                            }
                            self.expect_symbol(']')?;
                        }
                        Ok(Expression::ByRefIdentifier { name: format!("{kw:?}"), suffix: None })
                    }
                    _ => self.primary(),
                }
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
                let full = full_name(name.clone(), suffix.clone());
                if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                    self.index += 1;
                    if matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                        self.index += 1;
                        return Ok(Expression::ArrayRef { name: full });
                    }
                    let index = self.expression()?;
                    while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                        self.index += 1;
                        let _ = self.expression();
                    }
                    self.expect_symbol(']')?;
                    return Ok(Expression::ArrayAccess { name: full, index: Box::new(index) });
                }
                if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                    let args = self.parse_args()?;
                    return Ok(Expression::FunctionCall { name: full, args });
                }
                // Preserve original name and suffix for shared variable lookup
                Ok(Expression::SystemVariable { name, suffix })
            }
            TokenKind::Symbol('&') | TokenKind::LogicalAnd => {
                self.index += 1;
                // Support && (double address-of): consume second & if present
                if matches!(self.peek_kind(), TokenKind::Symbol('&') | TokenKind::LogicalAnd) {
                    self.index += 1;
                }
                self.primary()
            }
            TokenKind::Symbol('~') => {
                self.index += 1;
                let operand = self.primary()?;
                Ok(Expression::Not(Box::new(operand)))
            }
            TokenKind::SharedName(name) => self.identifier_expr(name, None),
            TokenKind::Identifier { name, suffix } => self.identifier_expr(name, suffix),
            TokenKind::Keyword(kw) if !is_statement_keyword(kw) || matches!(kw, Keyword::Function | Keyword::Next | Keyword::Select | Keyword::Const | Keyword::Break | Keyword::End | Keyword::Case | Keyword::Step | Keyword::To | Keyword::Until | Keyword::Wend | Keyword::Loop | Keyword::Else | Keyword::ElseIf | Keyword::Then | Keyword::Do) => self.identifier_expr(format!("{kw:?}"), None),
            TokenKind::Symbol('(') => {
                self.index += 1;
                let expr = self.expression()?;
                // Allow missing ) when a comment consumed it (e.g., ''' inside parens)
                if matches!(self.peek_kind(), TokenKind::Symbol(')')) {
                    self.index += 1;
                }
                // Handle bitfield {{...}} after parenthesized expression
                if matches!(self.peek_kind(), TokenKind::LBrace2) {
                    self.index += 1;
                    let mut args = vec![self.expression()?];
                    while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                        self.index += 1;
                        args.push(self.expression()?);
                    }
                    self.expect_token_kind(TokenKind::RBrace2)?;
                    // Wrap: treat as function call on the expression
                    if let Expression::FunctionCall { name, .. } = &expr {
                        return Ok(Expression::FunctionCall { name: name.clone(), args });
                    }
                    return Ok(expr);
                }
                Ok(expr)
            }
            TokenKind::Symbol('[') => {
                // [expr] — address/pointer expression in function args
                self.index += 1;
                let expr = self.expression()?;
                self.expect_symbol(']')?;
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
        if matches!(self.peek_kind(), TokenKind::LBrace2) {
            // {{...}} bitfield access
            self.index += 1;
            let full = full_name(name, suffix);
            let mut args = vec![self.expression()?];
            while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
                args.push(self.expression()?);
            }
            self.expect_token_kind(TokenKind::RBrace2)?;
            return Ok(Expression::FunctionCall { name: full, args });
        }
        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            let full = full_name(name, suffix);
            let args = self.parse_args()?;
            // Handle bitfield after function call: ABS(offset){8, 0}
            // { is mapped to ( by lexer, so we see ( after )
            // Only treat as bitfield if on same line as closing )
            if matches!(self.peek_kind(), TokenKind::LBrace2) {
                self.index += 1;
                let mut bf_args = vec![self.expression()?];
                while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                    self.index += 1;
                    bf_args.push(self.expression()?);
                }
                self.expect_token_kind(TokenKind::RBrace2)?;
                return Ok(Expression::FunctionCall { name: full, args: bf_args });
            }
            // Handle bitfield {8, 0} after function call: ABS(offset){8, 0}
            // { is mapped to ( by lexer, so we see ( after )
            // Only treat as bitfield if on same line as closing )
            if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                let prev_pos = self.tokens.get(self.index.saturating_sub(1)).map(|t| t.pos);
                let curr_pos = self.tokens.get(self.index).map(|t| t.pos);
                let same_line = matches!((prev_pos, curr_pos), (Some(p), Some(c)) if p.line == c.line);
                if same_line {
                    let bf_args = self.parse_args()?;
                    return Ok(Expression::FunctionCall { name: full, args: bf_args });
                }
            }
            Ok(Expression::FunctionCall { name: full, args })
        } else if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            if matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                self.index += 1;
                let full = full_name(name, suffix);
                Ok(Expression::ArrayRef { name: full })
            } else {
                let index = self.expression()?;
                // Skip additional comma-separated dimensions (multi-dim arrays)
                while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                    self.index += 1;
                    let _ = self.expression();
                }
                self.expect_symbol(']')?;
                let full = full_name(name, suffix);
                // Handle dot member access after array: arr[i].member
                if matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                    self.index += 1;
                    if let TokenKind::Identifier { name: member, .. } = self.peek_kind().clone() {
                        self.index += 1;
                        let combined = format!("{full}.{member}");
                        // Handle call/bitfield after dot: d86[i].flags{$SIZE8} → d86[i].flags($SIZE8)
                        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                            let args = self.parse_args()?;
                            return Ok(Expression::FunctionCall { name: combined, args });
                        }
                        // Handle array access after dot member: arr[i].member[j]
                        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                            self.index += 1;
                            let inner = self.expression()?;
                            while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                                self.index += 1;
                                let _ = self.expression();
                            }
                            self.expect_symbol(']')?;
                            return Ok(Expression::ArrayAccess { name: combined, index: Box::new(inner) });
                        }
                        return Ok(Expression::Identifier { name: combined, suffix: None });
                    } else if let TokenKind::Keyword(kw) = self.peek_kind().clone() {
                        self.index += 1;
                        let combined = format!("{full}.{kw:?}");
                        return Ok(Expression::Identifier { name: combined, suffix: None });
                    }
                }
                if matches!(self.peek_kind(), TokenKind::LBrace2) {
                    // {{...}} bitfield after array access
                    self.index += 1;
                    let mut args = vec![self.expression()?];
                    while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                        self.index += 1;
                        args.push(self.expression()?);
                    }
                    self.expect_token_kind(TokenKind::RBrace2)?;
                    return Ok(Expression::FunctionCall { name: full, args });
                }
                if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                    // Single { } index or function call after array
                    let args = self.parse_args()?;
                    return Ok(Expression::FunctionCall { name: full, args });
                }
                Ok(Expression::ArrayAccess {
                    name: full,
                    index: Box::new(index),
                })
            }
        } else {
            // Handle dot member access: identifier.member → treat as "identifier.member"
            if matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                self.index += 1;
                if let TokenKind::Identifier { name: member, suffix: mem_suffix } = self.peek_kind().clone() {
                    self.index += 1;
                    let combined = format!("{name}.{member}");
                    // Handle call after dot-access: nnotebook.flags{2,3} → nnotebook.flags(2,3)
                    if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                        let args = self.parse_args()?;
                        return Ok(Expression::FunctionCall { name: combined, args });
                    }
                    // Handle further dot access
                    if matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                        let mut full = combined;
                        while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                            self.index += 1;
                            if let TokenKind::Identifier { name: m2, .. } = self.peek_kind().clone() {
                                self.index += 1;
                                full = format!("{full}.{m2}");
                            } else { break; }
                        }
                        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                            let args = self.parse_args()?;
                            return Ok(Expression::FunctionCall { name: full, args });
                        }
                        return Ok(Expression::Identifier { name: full, suffix: mem_suffix });
                    }
                    // Handle array access after dot: host.alias[0]
                    if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                        self.index += 1;
                        if matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                            self.index += 1;
                            return Ok(Expression::ArrayRef { name: combined });
                        }
                        let index = self.expression()?;
                        while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                            self.index += 1;
                            let _ = self.expression();
                        }
                        self.expect_symbol(']')?;
                        return Ok(Expression::ArrayAccess {
                            name: combined,
                            index: Box::new(index),
                        });
                    }
                    return Ok(Expression::Identifier { name: combined, suffix: mem_suffix });
                } else if let TokenKind::Keyword(kw) = self.peek_kind().clone() {
                    // Handle keyword as member name: eevent.type
                    self.index += 1;
                    let combined = format!("{name}.{kw:?}");
                    return Ok(Expression::Identifier { name: combined, suffix: None });
                }
            }
            Ok(Expression::Identifier { name, suffix })
        }
    }
}

pub(crate) fn is_statement_keyword(kw: Keyword) -> bool {
    matches!(
        kw,
            | Keyword::Dim
            | Keyword::If
            | Keyword::Ifz
            | Keyword::Ift
            | Keyword::Iff
            | Keyword::For
            | Keyword::While
            | Keyword::Function
            | Keyword::External
            | Keyword::Internal
            | Keyword::CFunction
            | Keyword::Do
            | Keyword::Select
            | Keyword::Program
            | Keyword::Import
            | Keyword::Declare
            | Keyword::End
            | Keyword::Static
            | Keyword::Shared
            | Keyword::Then
            | Keyword::Else
            | Keyword::ElseIf
            | Keyword::Case
            | Keyword::To
            | Keyword::Step
            | Keyword::Until
            | Keyword::Wend
            | Keyword::Loop
            | Keyword::Export
    )
}
