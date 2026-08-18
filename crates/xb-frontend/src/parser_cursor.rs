use crate::ast::{Expression, Param, Statement, UnaryOp};
use crate::parser::{ParseError, Parser};
use crate::parser_expr::is_statement_keyword;
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

    /// Like expect_identifier but also accepts keywords as names (XBasic
    /// allows keywords like Print as SUB/function/label names).
    pub(crate) fn expect_name_or_keyword(
        &mut self,
    ) -> Result<(String, Option<TypeSuffix>), ParseError> {
        match self.peek_kind().clone() {
            TokenKind::Identifier { name, suffix } => {
                self.index += 1;
                Ok((name, suffix))
            }
            TokenKind::Keyword(kw) => {
                self.index += 1;
                Ok((format!("{kw:?}"), None))
            }
            TokenKind::SystemVariable { name, suffix } => {
                self.index += 1;
                Ok((name, suffix))
            }
            TokenKind::SharedName(name) => {
                self.index += 1;
                Ok((name, None))
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
    pub(crate) fn expect_token_kind(&mut self, kind: TokenKind) -> Result<(), ParseError> {
        if *self.peek_kind() == kind {
            self.index += 1;
            Ok(())
        } else {
            Err(self.expected("token"))
        }
    }
    pub(crate) fn expect_line_end(&mut self) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Newline => {
                self.index += 1;
                Ok(())
            }
            TokenKind::Symbol(':') if !self.in_single_line_if => {
                self.index += 1;
                Ok(())
            }
            // Accept identifier/system var as implicit line separator only when
            // it starts a new statement (followed by =, [, or .)
            TokenKind::Identifier { .. }
            | TokenKind::SystemConstant(_)
            | TokenKind::SystemVariable { .. }
                if matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Symbol('='))
                        | Some(TokenKind::Symbol('['))
                        | Some(TokenKind::Symbol('.'))
                ) =>
            {
                Ok(())
            }
            TokenKind::Eof => Ok(()),
            TokenKind::Symbol(':') if self.in_single_line_if => Ok(()),
            TokenKind::Keyword(Keyword::Else) | TokenKind::Keyword(Keyword::ElseIf)
                if self.in_single_line_if =>
            {
                Ok(())
            }
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
        match self.peek_kind() {
            TokenKind::Newline | TokenKind::Eof => true,
            TokenKind::Symbol(':') if !self.in_single_line_if => true,
            TokenKind::Keyword(Keyword::Else) | TokenKind::Keyword(Keyword::ElseIf)
                if self.in_single_line_if =>
            {
                true
            }
            _ => false,
        }
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

    /// Parse an optional array dimension. Returns `(size, is_array)` where
    /// `is_array` is `true` whenever brackets/parens were present — including the
    /// empty form `a[]` (which yields `(None, true)`), distinct from a bare scalar
    /// `a` which yields `(None, false)`.
    pub(crate) fn parse_array_size(&mut self) -> Result<(Option<Expression>, bool), ParseError> {
        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.index += 1;
            let e = self.expression()?;
            self.expect_symbol(')')?;
            Ok((Some(e), true))
        } else if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            if matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                self.index += 1;
                return Ok((None, true));
            }
            let e = self.expression()?;
            // Skip additional dimensions (comma-separated) — use first only
            while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
                let _ = self.expression();
            }
            self.expect_symbol(']')?;
            Ok((Some(e), true))
        } else {
            Ok((None, false))
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
        (matches!(self.peek_kind(), TokenKind::Keyword(Keyword::End))
            && matches!(self.peek_next_kind(), Some(TokenKind::Keyword(Keyword::If))))
            || matches!(self.peek_kind(), TokenKind::Identifier { ref name, .. } if name.eq_ignore_ascii_case("ENDIF"))
    }
    pub(crate) fn expect_end_if(&mut self) -> Result<(), ParseError> {
        if matches!(self.peek_kind(), TokenKind::Identifier { ref name, .. } if name.eq_ignore_ascii_case("ENDIF"))
        {
            self.index += 1;
        } else {
            self.expect_keyword(Keyword::End)?;
            self.expect_keyword(Keyword::If)?;
        }
        Ok(())
    }
    pub(crate) fn starts_wend(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Wend))
    }
    pub(crate) fn starts_loop(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Loop))
    }
    pub(crate) fn starts_next(&self) -> bool {
        // `NEXT` ends a FOR body, but `next` is also a legal variable name; when it
        // is followed by `=`, `[`, `.`, or `(` it is a variable use, not a terminator.
        matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Next))
            && !matches!(
                self.peek_next_kind(),
                Some(TokenKind::Symbol('='))
                    | Some(TokenKind::Symbol('['))
                    | Some(TokenKind::Symbol('.'))
                    | Some(TokenKind::Symbol('('))
            )
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
        (matches!(self.peek_kind(), TokenKind::Identifier { .. })
            || matches!(self.peek_kind(), TokenKind::SharedName(_)))
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
    }
    pub(crate) fn starts_call(&self) -> bool {
        let is_name = matches!(self.peek_kind(), TokenKind::Identifier { .. })
            || matches!(self.peek_kind(), TokenKind::Keyword(kw) if !is_statement_keyword(*kw))
            || matches!(self.peek_kind(), TokenKind::SharedName(_));
        is_name
            && (matches!(self.peek_next_kind(), Some(TokenKind::Symbol('(')))
                || matches!(self.peek_next_kind(), Some(TokenKind::Symbol('['))))
    }
    pub(crate) fn starts_attach(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { ref name, .. } if name.eq_ignore_ascii_case("ATTACH"))
    }
    pub(crate) fn starts_label(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol(':')))
    }
    pub(crate) fn starts_constant_definition(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::SystemConstant(_))
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
    }
    pub(crate) fn starts_typed_dim(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && (matches!(self.peek_next_kind(), Some(TokenKind::Identifier { .. }))
                || matches!(self.peek_next_kind(), Some(TokenKind::Keyword(_)))
                || matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::SystemVariable { .. })
                )
                || matches!(self.peek_next_kind(), Some(TokenKind::SharedName(_))))
    }
    pub(crate) fn starts_dot_access(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('.')))
    }
    pub(crate) fn starts_shared_name_assignment(&self) -> bool {
        matches!(self.peek_kind(), TokenKind::SharedName(_))
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
                // Varargs `...` (e.g. `EXTERNAL CFUNCTION printf (addr, ...)`).
                // Lexed as consecutive `.` symbols; terminal, so stop after it.
                if matches!(self.peek_kind(), TokenKind::Symbol('.'))
                    && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('.')))
                {
                    while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                        self.index += 1;
                    }
                    break;
                }
                // Handle grouped params: (r1, r1$, r1[], r1$[])
                if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                    self.index += 1;
                    while !matches!(self.peek_kind(), TokenKind::Symbol(')')) && !self.at_eof() {
                        self.index += 1;
                    }
                    self.expect_symbol(')')?;
                    if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                        self.index += 1;
                    } else {
                        break;
                    }
                    continue;
                }
                let mut by_ref = false;
                if matches!(self.peek_kind(), TokenKind::Symbol('@')) {
                    by_ref = true;
                    self.index += 1;
                }
                // Optional type qualifier (ANY, STRING, INTEGER, FUNCADDR, or a
                // composite TYPE name). The param name may be an identifier or a
                // keyword (e.g. 'data').
                let mut type_name: Option<String> = None;
                if matches!(self.peek_kind(), TokenKind::Identifier { .. })
                    || matches!(self.peek_kind(), TokenKind::Keyword(Keyword::FuncAddr))
                {
                    let candidate = if let TokenKind::Identifier { name, .. } = self.peek_kind() {
                        Some(name.clone())
                    } else {
                        None
                    };
                    let save = self.index;
                    self.index += 1;
                    if !matches!(self.peek_kind(), TokenKind::Identifier { .. })
                        && !matches!(self.peek_kind(), TokenKind::Keyword(_))
                        && !matches!(self.peek_kind(), TokenKind::Symbol('@'))
                    {
                        self.index = save; // Not a type qualifier, restore
                    } else if let Some(c) = candidate {
                        // Confirmed type qualifier; record composite TYPE names so
                        // the analyzer can flatten the param into member slots.
                        if self.composite_types.contains(&c) {
                            type_name = Some(c);
                        }
                    }
                }
                if matches!(self.peek_kind(), TokenKind::Symbol('@')) {
                    by_ref = true;
                    self.index += 1;
                }
                let (name, suffix) = self.expect_name_or_keyword()?;
                // Skip optional array brackets
                if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                    self.index += 1;
                    if !matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                        let _ = self.expression();
                    }
                    self.expect_symbol(']')?;
                }
                params.push(Param {
                    name,
                    suffix,
                    type_name,
                    by_ref,
                });
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
        let value = self.expression()?;
        // Allow next $ constant on same line without separator
        if !matches!(self.peek_kind(), TokenKind::SystemConstant(_)) {
            self.expect_line_end()?;
        }
        // Extract string representation from the expression for ConstantDefinition
        let value_str = match &value {
            Expression::IntegerLiteral(s) => s.clone(),
            Expression::FloatLiteral(s) => s.clone(),
            Expression::StringLiteral(s) => s.clone(),
            Expression::Unary {
                op: UnaryOp::Neg,
                operand,
            } => {
                if let Expression::IntegerLiteral(s) = operand.as_ref() {
                    format!("-{s}")
                } else {
                    "0".to_string()
                }
            }
            _ => "0".to_string(),
        };
        Ok(Statement::ConstantDefinition {
            name,
            value: value_str,
        })
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

    pub(crate) fn shared_name_assignment_stmt(&mut self) -> Result<Statement, ParseError> {
        let TokenKind::SharedName(name) = self.peek_kind().clone() else {
            return Err(self.expected("shared name"));
        };
        self.index += 1;
        self.expect_symbol('=')?;
        let value = self.expression()?;
        self.expect_line_end()?;
        Ok(Statement::SharedAssignment {
            name,
            suffix: None,
            value,
        })
    }
}
