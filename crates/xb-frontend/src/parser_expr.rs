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
            TokenKind::Keyword(Keyword::Or)
                | TokenKind::Keyword(Keyword::Xor)
                | TokenKind::Symbol('|')
                | TokenKind::Symbol('^')
        ) {
            let is_xor = matches!(
                self.peek_kind(),
                TokenKind::Keyword(Keyword::Xor) | TokenKind::Symbol('^')
            );
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
        while matches!(
            self.peek_kind(),
            TokenKind::Keyword(Keyword::And) | TokenKind::Symbol('&')
        ) {
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
        if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Not))
            || matches!(self.peek_kind(), TokenKind::Symbol('!'))
        {
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
                        // Optional array brackets: `@a$[]` is a by-ref array. Bake
                        // the type suffix into the name (like `ArrayRef`) so the
                        // by-ref symbol matches the array's slot name (`a$`) used by
                        // DIM and element access; otherwise the `$` is dropped and
                        // the array can't be found or written back.
                        let mut is_array = false;
                        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                            is_array = true;
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
                        if is_array {
                            Ok(Expression::ByRefIdentifier {
                                name: full_name(name, suffix),
                                suffix,
                            })
                        } else {
                            Ok(Expression::ByRefIdentifier { name, suffix })
                        }
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
                        Ok(Expression::ByRefIdentifier {
                            name: format!("{kw:?}"),
                            suffix: None,
                        })
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
                    let sv_extra = self.collect_extra_indices()?;
                    self.expect_symbol(']')?;
                    // Trailing brace byte-access: `##ARGV$[i]{off}` (brace lexes as
                    // parens) — consume `(off)` so the element access parses.
                    if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                        let _ = self.parse_args()?;
                    }
                    return Ok(Expression::ArrayAccess {
                        name: full,
                        index: Box::new(index),
                        extra_indices: sv_extra,
                    });
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
                if matches!(
                    self.peek_kind(),
                    TokenKind::Symbol('&') | TokenKind::LogicalAnd
                ) {
                    self.index += 1;
                }
                // `&Func(...)` — address-of a function → a FUNCADDR value. The
                // parenthesised form (with or without args) distinguishes it from
                // taking the address of a variable (`&x`, handled by primary()).
                if let TokenKind::Identifier { name, suffix } = self.peek_kind().clone() {
                    if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('('))) {
                        let fname = full_name(name, suffix);
                        self.index += 2; // identifier + '('
                        let mut depth = 1;
                        while depth > 0 && !self.at_eof() {
                            match self.peek_kind() {
                                TokenKind::Symbol('(') => depth += 1,
                                TokenKind::Symbol(')') => depth -= 1,
                                _ => {}
                            }
                            self.index += 1;
                        }
                        return Ok(Expression::FuncAddr(fname));
                    }
                }
                self.primary()
            }
            TokenKind::Symbol('~') => {
                self.index += 1;
                let operand = self.primary()?;
                Ok(Expression::Not(Box::new(operand)))
            }
            TokenKind::Keyword(Keyword::Not) | TokenKind::Symbol('!') => {
                self.index += 1;
                let operand = self.primary()?;
                Ok(Expression::Not(Box::new(operand)))
            }
            TokenKind::SharedName(name) => self.identifier_expr(name, None),
            TokenKind::Identifier { name, suffix } => self.identifier_expr(name, suffix),
            TokenKind::Keyword(kw) => self.identifier_expr(format!("{kw:?}"), None),
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
                        return Ok(Expression::FunctionCall {
                            name: name.clone(),
                            args,
                        });
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

    /// Lower a brace-notation byte read `base{idx}` (the lexer maps `{` to `(`)
    /// to `ASC(MID$(base, idx + 1, 1))` — the 0-based byte offset becomes a
    /// 1-based MID$ start. Composed entirely of builtins every backend
    /// implements (interpreter, Rust CEmitter, cgen.x, LLVM), so no new
    /// IR/text-IR surface is created.
    fn byte_read_desugar(base: Expression, idx: Expression) -> Expression {
        let one = || Expression::IntegerLiteral("1".to_string());
        let start = Expression::Arithmetic {
            op: ArithmeticOp::Add,
            left: Box::new(idx),
            right: Box::new(one()),
        };
        let mid = Expression::FunctionCall {
            name: "MID$".to_string(),
            args: vec![base, start, one()],
        };
        Expression::FunctionCall {
            name: "ASC".to_string(),
            args: vec![mid],
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
                return Ok(Expression::FunctionCall {
                    name: full,
                    args: bf_args,
                });
            }
            // Handle bitfield {8, 0} after function call: ABS(offset){8, 0}
            // { is mapped to ( by lexer, so we see ( after )
            // Only treat as bitfield if on same line as closing )
            if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                let prev_pos = self.tokens.get(self.index.saturating_sub(1)).map(|t| t.pos);
                let curr_pos = self.tokens.get(self.index).map(|t| t.pos);
                let same_line =
                    matches!((prev_pos, curr_pos), (Some(p), Some(c)) if p.line == c.line);
                if same_line {
                    let bf_args = self.parse_args()?;
                    return Ok(Expression::FunctionCall {
                        name: full,
                        args: bf_args,
                    });
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
                let index_extra = self.collect_extra_indices()?;
                self.expect_symbol(']')?;
                let full = full_name(name, suffix);
                // Handle dot member access after array: arr[i].member
                if matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                    self.index += 1;
                    if let TokenKind::Identifier { name: member, .. } = self.peek_kind().clone() {
                        self.index += 1;
                        let mut combined = format!("{full}.{member}");
                        // Chained member access: arr[i].a.b.c
                        while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                            self.index += 1;
                            if let TokenKind::Identifier { name: m2, .. } = self.peek_kind().clone()
                            {
                                self.index += 1;
                                combined = format!("{combined}.{m2}");
                            } else if let TokenKind::Keyword(kw) = self.peek_kind().clone() {
                                self.index += 1;
                                combined = format!("{combined}.{kw:?}");
                            } else {
                                break;
                            }
                        }
                        // Handle call/bitfield after dot: d86[i].flags{$SIZE8} → d86[i].flags($SIZE8)
                        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                            let args = self.parse_args()?;
                            return Ok(Expression::FunctionCall {
                                name: combined,
                                args,
                            });
                        }
                        // Handle array access after dot member: arr[i].member[j]
                        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                            self.index += 1;
                            let inner = self.expression()?;
                            let inner_extra = self.collect_extra_indices()?;
                            self.expect_symbol(']')?;
                            return Ok(Expression::ArrayAccess {
                                name: combined,
                                index: Box::new(inner),
                                extra_indices: inner_extra,
                            });
                        }
                        return Ok(Expression::ArrayAccess {
                            name: combined,
                            index: Box::new(index),
                            extra_indices: index_extra.clone(),
                        });
                    } else if let TokenKind::Keyword(kw) = self.peek_kind().clone() {
                        self.index += 1;
                        let combined = format!("{full}.{kw:?}");
                        return Ok(Expression::ArrayAccess {
                            name: combined,
                            index: Box::new(index),
                            extra_indices: index_extra.clone(),
                        });
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
                    // `{expr}` after array access (brace-mapped paren) is a
                    // BYTE read on the element: text$[l]{n} →
                    // ASC(MID$(text$[l], n+1, 1)) at parse time. A REAL `(` is
                    // a call (legacy behavior).
                    let brace_call =
                        self.tokens.get(self.index).map_or(false, |t| t.from_brace);
                    let args = self.parse_args()?;
                    if brace_call && full.ends_with('$') {
                        let elem = Expression::ArrayAccess {
                            name: full,
                            index: Box::new(index),
                            extra_indices: index_extra,
                        };
                        let idx = args.into_iter().next().expect("brace arg");
                        return Ok(Self::byte_read_desugar(elem, idx));
                    }
                    return Ok(Expression::FunctionCall { name: full, args });
                }
                Ok(Expression::ArrayAccess {
                    name: full,
                    index: Box::new(index),
                    extra_indices: index_extra,
                })
            }
        } else {
            // Handle dot member access: identifier.member → treat as "identifier.member"
            if matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                self.index += 1;
                let (member, mem_suffix) = match self.peek_kind().clone() {
                    TokenKind::Identifier { name: m, suffix: s } => {
                        self.index += 1;
                        (m, s)
                    }
                    TokenKind::Keyword(kw) => {
                        self.index += 1;
                        (format!("{kw:?}"), None)
                    }
                    _ => return Ok(Expression::Identifier { name, suffix }),
                };
                let mut combined = format!("{name}.{member}");
                // Chained members: a.b.c ...
                while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                    self.index += 1;
                    match self.peek_kind().clone() {
                        TokenKind::Identifier { name: m2, .. } => {
                            self.index += 1;
                            combined = format!("{combined}.{m2}");
                        }
                        TokenKind::Keyword(kw) => {
                            self.index += 1;
                            combined = format!("{combined}.{kw:?}");
                        }
                        _ => break,
                    }
                }
                // Call: a.b(args)
                if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                    let args = self.parse_args()?;
                    return Ok(Expression::FunctionCall {
                        name: combined,
                        args,
                    });
                }
                // Array access: a.b[i]  (a.b[] is an array reference)
                if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                    self.index += 1;
                    if matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                        self.index += 1;
                        return Ok(Expression::ArrayRef { name: combined });
                    }
                    let index = self.expression()?;
                    let dm_extra = self.collect_extra_indices()?;
                    self.expect_symbol(']')?;
                    return Ok(Expression::ArrayAccess {
                        name: combined,
                        index: Box::new(index),
                        extra_indices: dm_extra,
                    });
                }
                return Ok(Expression::Identifier {
                    name: combined,
                    suffix: mem_suffix,
                });
            }
            Ok(Expression::Identifier { name, suffix })
        }
    }
}

pub(crate) fn is_statement_keyword(kw: Keyword) -> bool {
    matches!(kw, |Keyword::Dim| Keyword::If
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
        | Keyword::Export)
}
