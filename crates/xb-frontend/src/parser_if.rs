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
        // THEN is optional in IFZ/IFT/IFF — skip extra THENs (legacy: IFZ x THEN THEN stmt)
        while matches!(self.peek_keyword(), Some(Keyword::Then)) {
            self.index += 1;
        }
        if self.at_line_end() {
            let stmt = self.parse_if_chain_with_cond(condition)?;
            self.expect_end_if()?;
            self.expect_line_end()?;
            Ok(stmt)
        } else {
            // Single-line IFZ/IFT/IFF: THEN <stmt> [ELSE <stmt>]
            self.in_single_line_if = true;
            let body_start = self.index;
            let mut then_body = vec![self.statement()?];
            while matches!(self.peek_kind(), TokenKind::Symbol(':')) {
                self.index += 1;
                then_body.push(self.statement()?);
            }
            let consumed_newline = self.tokens[body_start..self.index]
                .iter()
                .any(|t| matches!(t.kind, TokenKind::Newline));
            let else_body = if !consumed_newline && matches!(self.peek_keyword(), Some(Keyword::Else)) {
                self.index += 1;
                let mut body = vec![self.statement()?];
                while matches!(self.peek_kind(), TokenKind::Symbol(':')) {
                    self.index += 1;
                    body.push(self.statement()?);
                }
                Some(body)
            } else {
                None
            };
            self.in_single_line_if = false;
            Ok(Statement::If {
                condition,
                then_body,
                else_body,
            })
        }
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
        let expr = self.label_expr()?;
        self.expect_line_end()?;
        Ok(Statement::Gosub(expr))
    }

    pub(crate) fn break_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::ExitLoop)
    }

    pub(crate) fn goto_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        let expr = self.label_expr()?;
        self.expect_line_end()?;
        Ok(Statement::Goto(expr))
    }

    pub(crate) fn stop_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        self.expect_line_end()?;
        Ok(Statement::Stop)
    }
    pub(crate) fn label_stmt(&mut self) -> Result<Statement, ParseError> {
        let (name, _) = self.expect_name_or_keyword()?;
        self.index += 1; // skip colon
        // A label may be followed by a statement on the same line: `lbl: stmt`.
        // Only consume the line end when the label stands alone.
        if self.at_line_end() {
            self.expect_line_end()?;
        }
        Ok(Statement::Label(name))
    }
}

impl Parser {
    /// Parse a label expression for GOSUB/GOTO — accepts keywords as label names.
    fn label_expr(&mut self) -> Result<Expression, ParseError> {
        if matches!(self.peek_kind(), TokenKind::Symbol('@')) {
            self.index += 1;
            // @ prefix with complex expression: @d86[i].action
            return self.expression();
        }
        let kind = self.peek_kind().clone();
        match kind {
            TokenKind::Identifier { name, suffix } => {
                self.index += 1;
                Ok(Expression::Identifier { name, suffix })
            }
            TokenKind::Keyword(kw) => {
                self.index += 1;
                let name = format!("{kw:?}");
                Ok(Expression::Identifier { name, suffix: None })
            }
            _ => self.expression(),
        }
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
        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            // Skip file expression and closing ]
            while !matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                if matches!(self.peek_kind(), TokenKind::Eof | TokenKind::Newline) {
                    break;
                }
                self.index += 1;
            }
            if matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                self.index += 1;
            }
            // Skip comma after [file]
            if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
            }
        }
        loop {
            let (name, suffix) = self.expect_name_or_keyword()?;
            // Skip optional array brackets
            if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                self.index += 1;
                if !matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                    let _ = self.expression();
                }
                self.expect_symbol(']')?;
            }
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
        // Skip optional date/comment after version string
        while !self.at_line_end() && !self.at_eof() {
            self.index += 1;
        }
        self.expect_line_end()?;
        Ok(Statement::Version(version))
    }
}
