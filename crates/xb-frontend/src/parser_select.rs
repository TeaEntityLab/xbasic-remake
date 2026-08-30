use std::sync::atomic::{AtomicUsize, Ordering};

use crate::ast::{
    BooleanOp, CaseClause, ComparisonOp, Expression, FunctionDecl, PrintSep, Statement,
};
use crate::parser::Parser;
use crate::token::{Keyword, TokenKind};

static SELECT_TRUE_COUNTER: AtomicUsize = AtomicUsize::new(0);

impl Parser {
    pub(crate) fn select_case_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Select)?;
        self.expect_keyword(Keyword::Case)?;
        // SELECT CASE [ALL] [TRUE | FALSE | <expr>]
        let all = matches!(self.peek_kind(), TokenKind::Identifier { name, .. } if name.eq_ignore_ascii_case("ALL"));
        if all {
            self.index += 1;
        }
        let truthy: Option<bool> = match self.peek_kind() {
            TokenKind::Identifier { name, .. } if name.eq_ignore_ascii_case("TRUE") => {
                self.index += 1;
                Some(true)
            }
            TokenKind::Identifier { name, .. } if name.eq_ignore_ascii_case("FALSE") => {
                self.index += 1;
                Some(false)
            }
            _ => None,
        };
        let selector = if truthy.is_some()
            || matches!(
                self.peek_kind(),
                TokenKind::Newline | TokenKind::Eof | TokenKind::Symbol(':')
            ) {
            Expression::IntegerLiteral("1".to_string())
        } else {
            self.expression()?
        };
        let mut cases = Vec::new();
        let mut default = None;
        self.skip_newlines();
        // Legacy XBasic allows statements before the first CASE; they run
        // unconditionally. Collect them and emit before the SELECT.
        let mut preamble = Vec::new();
        while !self.at_eof() && !self.starts_case() && !self.starts_end_select() {
            preamble.push(self.statement()?);
            self.skip_newlines();
        }
        while !self.at_eof() && !self.starts_end_select() {
            self.expect_keyword(Keyword::Case)?;
            if self.peek_keyword() == Some(Keyword::Else) {
                self.index += 1;
                let mut body = Vec::new();
                // CASE ELSE may have statement on same line or on next lines
                if !self.at_line_end() {
                    body.push(self.statement()?);
                } else {
                    self.expect_line_end()?;
                    self.skip_newlines();
                    while !self.at_eof() && !self.starts_end_select() {
                        body.push(self.statement()?);
                        self.skip_newlines();
                    }
                }
                default = Some(body);
            } else {
                let mut conditions = Vec::new();
                loop {
                    conditions.push(self.expression()?);
                    if self.peek_kind() == &TokenKind::Symbol(',') {
                        self.index += 1;
                    } else {
                        break;
                    }
                }
                if matches!(self.peek_kind(), TokenKind::Symbol(':')) {
                    self.index += 1;
                    let mut body = Vec::new();
                    if !self.at_line_end() {
                        body.push(self.statement()?);
                    }
                    self.skip_newlines();
                    while !self.at_eof() && !self.starts_case() && !self.starts_end_select() {
                        body.push(self.statement()?);
                        self.skip_newlines();
                    }
                    cases.push(CaseClause { conditions, body });
                    continue;
                }
                let mut body = Vec::new();
                self.expect_line_end()?;
                self.skip_newlines();
                while !self.at_eof() && !self.starts_case() && !self.starts_end_select() {
                    body.push(self.statement()?);
                    self.skip_newlines();
                }
                cases.push(CaseClause { conditions, body });
            }
        }
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::Select)?;
        self.expect_line_end()?;
        let stmt = if truthy.is_none() && !all {
            // Plain `SELECT CASE <expr>`: keep the value/first-match SelectCase —
            // exactly what the text-IR goldens and cgen.x consume, unchanged.
            Statement::SelectCase {
                selector,
                cases,
                default,
            }
        } else {
            // `SELECT CASE [ALL] TRUE|FALSE|<expr>` desugars to IF so the runtime
            // matches by truthiness (TRUE/FALSE) or runs every match (ALL), reusing
            // IF's non-zero test. No golden-bearing source uses these forms.
            Self::desugar_select_true(&selector, truthy, all, cases, default)
        };
        if preamble.is_empty() {
            Ok(stmt)
        } else {
            preamble.push(stmt);
            Ok(Statement::Compound(preamble))
        }
    }

    /// Build the boolean test for one CASE's conditions under a desugared
    /// `SELECT CASE [ALL] TRUE|FALSE|<expr>` (conditions are OR-ed).
    fn case_test(selector: &Expression, truthy: Option<bool>, conds: &[Expression]) -> Expression {
        let mut iter = conds.iter().cloned();
        let first = Self::cond_test(selector, truthy, iter.next().expect("CASE has a condition"));
        iter.fold(first, |acc, c| Expression::Boolean {
            op: BooleanOp::Or,
            left: Box::new(acc),
            right: Box::new(Self::cond_test(selector, truthy, c)),
        })
    }

    fn cond_test(selector: &Expression, truthy: Option<bool>, cond: Expression) -> Expression {
        match truthy {
            // TRUE: the case matches when `cond` is truthy (IF tests non-zero).
            Some(true) => cond,
            // FALSE: the case matches when `cond` is falsy.
            Some(false) => Expression::Not(Box::new(cond)),
            // ALL <expr>: value equality against the selector.
            None => Expression::Comparison {
                op: ComparisonOp::Equal,
                left: Box::new(selector.clone()),
                right: Box::new(cond),
            },
        }
    }

    fn desugar_select_true(
        selector: &Expression,
        truthy: Option<bool>,
        all: bool,
        cases: Vec<CaseClause>,
        default: Option<Vec<Statement>>,
    ) -> Statement {
        // Generate a unique label for EXIT SELECT within the desugared IF chain.
        // Without this, EXIT SELECT becomes exit_select in the IR with no enclosing
        // select_case, so the C emitter uses select id 0 — a label in a different
        // function (undeclared label cc error in xit/xcol).
        let id = SELECT_TRUE_COUNTER.fetch_add(1, Ordering::Relaxed);
        let exit_label = format!("_exit_sel_true_{id}");

        // Replace EXIT SELECT in case bodies with GOTO <exit_label>.
        fn replace_exit_select(stmts: &mut [Statement], label: &str) {
            for s in stmts.iter_mut() {
                match s {
                    Statement::ExitSelect => {
                        *s = Statement::Goto(Expression::Identifier {
                            name: label.to_string(),
                            suffix: None,
                        });
                    }
                    Statement::If {
                        then_body,
                        else_body,
                        ..
                    } => {
                        replace_exit_select(then_body, label);
                        if let Some(eb) = else_body {
                            replace_exit_select(eb, label);
                        }
                    }
                    Statement::Compound(body) => replace_exit_select(body, label),
                    Statement::For { body, .. } => replace_exit_select(body, label),
                    Statement::While { body, .. } => replace_exit_select(body, label),
                    Statement::DoLoop { body, .. } => replace_exit_select(body, label),
                    Statement::SelectCase { cases, default, .. } => {
                        for c in cases.iter_mut() {
                            replace_exit_select(&mut c.body, label);
                        }
                        if let Some(d) = default {
                            replace_exit_select(d, label);
                        }
                    }
                    _ => {}
                }
            }
        }

        if all {
            // Every matching case runs; ALL mode has no CASE ELSE.
            let mut out: Vec<Statement> = Vec::with_capacity(cases.len() + 1);
            for mut c in cases {
                replace_exit_select(&mut c.body, &exit_label);
                out.push(Statement::If {
                    condition: Self::case_test(selector, truthy, &c.conditions),
                    then_body: c.body,
                    else_body: None,
                });
            }
            out.push(Statement::Label(exit_label));
            Statement::Compound(out)
        } else {
            // First-match: nested IF/ELSE chain, innermost else = CASE ELSE.
            let mut else_body: Option<Vec<Statement>> = default.map(|mut d| {
                replace_exit_select(&mut d, &exit_label);
                d
            });
            for mut c in cases.into_iter().rev() {
                replace_exit_select(&mut c.body, &exit_label);
                let condition = Self::case_test(selector, truthy, &c.conditions);
                else_body = Some(vec![Statement::If {
                    condition,
                    then_body: c.body,
                    else_body: else_body.take(),
                }]);
            }
            let mut out = else_body.unwrap_or_default();
            out.push(Statement::Label(exit_label));
            Statement::Compound(out)
        }
    }
    pub(crate) fn starts_end_select(&self) -> bool {
        self.peek_keyword() == Some(Keyword::End)
            && self.peek_next_kind() == Some(&TokenKind::Keyword(Keyword::Select))
    }
    pub(crate) fn starts_case(&self) -> bool {
        self.peek_keyword() == Some(Keyword::Case)
    }
    pub(crate) fn program_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Program)?;
        let name = self.expect_string()?;
        self.expect_line_end()?;
        Ok(Statement::Program(name))
    }
    pub(crate) fn end_program_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::Program)?;
        self.expect_line_end()?;
        Ok(Statement::EndProgram)
    }
    pub(crate) fn import_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Import)?;
        let name = self.expect_string()?;
        self.expect_line_end()?;
        Ok(Statement::Import(name))
    }
    pub(crate) fn declare_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Declare)?;
        while matches!(
            self.peek_keyword(),
            Some(Keyword::External)
                | Some(Keyword::Internal)
                | Some(Keyword::CFunction)
                | Some(Keyword::Function)
        ) {
            self.index += 1;
        }
        // Skip optional type qualifier (XLONG, STRING, UBYTE, etc.) before function name
        if matches!(self.peek_kind(), TokenKind::Identifier { .. }) {
            let save = self.index;
            self.index += 1;
            // If next is another identifier or keyword, the first was a type qualifier
            if matches!(self.peek_kind(), TokenKind::Identifier { .. })
                || matches!(self.peek_kind(), TokenKind::Keyword(_))
            {
                // type qualifier was consumed, continue
            } else {
                // The first identifier IS the function name, restore
                self.index = save;
            }
        }
        let (name, _) = self.expect_name_or_keyword()?;
        let mut args = Vec::new();
        if self.peek_kind() == &TokenKind::Symbol('(') {
            self.index += 1;
            if self.peek_kind() != &TokenKind::Symbol(')') {
                loop {
                    // Skip optional type qualifier (XLONG, STRING, UBYTE, etc.) before @
                    if matches!(self.peek_kind(), TokenKind::Identifier { .. }) {
                        let save = self.index;
                        self.index += 1;
                        if !matches!(self.peek_kind(), TokenKind::Identifier { .. })
                            && !matches!(self.peek_kind(), TokenKind::Keyword(_))
                            && !matches!(self.peek_kind(), TokenKind::Symbol('@'))
                        {
                            self.index = save;
                        }
                    }
                    // Allow @ prefix
                    if matches!(self.peek_kind(), TokenKind::Symbol('@')) {
                        self.index += 1;
                    }
                    let (arg_name, _) = self.expect_name_or_keyword()?;
                    args.push(arg_name);
                    // Skip optional array brackets
                    if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                        self.index += 1;
                        if !matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                            let _ = self.expression();
                        }
                        self.expect_symbol(']')?;
                    }
                    if self.peek_kind() == &TokenKind::Symbol(',') {
                        self.index += 1;
                    } else {
                        break;
                    }
                }
            }
            self.expect_symbol(')')?;
        }
        self.expect_line_end()?;
        Ok(Statement::Declare { name, args })
    }

    pub(crate) fn sub_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Sub)?;
        let (name, suffix) = self.expect_name_or_keyword()?;
        let params = if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.parse_params()?
        } else {
            Vec::new()
        };
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_end_sub() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::Sub)?;
        // Skip optional sub name or $$TRUE/$$FALSE after END SUB
        if matches!(self.peek_kind(), TokenKind::Identifier { .. })
            || matches!(self.peek_kind(), TokenKind::SystemVariable { .. })
            || matches!(self.peek_kind(), TokenKind::SystemConstant(_))
        {
            self.index += 1;
        }
        self.expect_line_end()?;
        Ok(Statement::Function(FunctionDecl::new(
            name, suffix, params, body,
        )))
    }

    pub(crate) fn exit_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Exit)?;
        if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Function))
            || matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Sub))
        {
            self.index += 1;
            // Optional return value: `EXIT FUNCTION (expr)`.
            if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                let _ = self.parse_args()?;
            }
            self.expect_line_end()?;
            Ok(Statement::ExitFunction)
        } else if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::For))
            || matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Do))
            || matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Loop))
        {
            self.index += 1;
            // Skip optional loop depth number: EXIT FOR 2
            if matches!(self.peek_kind(), TokenKind::IntegerLiteral(_)) {
                self.index += 1;
            }
            self.expect_line_end()?;
            Ok(Statement::ExitLoop)
        } else if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Select)) {
            self.index += 1;
            // Skip optional depth number: EXIT SELECT 2
            if matches!(self.peek_kind(), TokenKind::IntegerLiteral(_)) {
                self.index += 1;
            }
            self.expect_line_end()?;
            Ok(Statement::ExitSelect)
        } else if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::If)) {
            // EXIT IF [depth]: leave the enclosing IF block(s). No dedicated node
            // exists; parse-consume as a no-op (only used in non-executed library
            // internals) so the surrounding structure still parses.
            self.index += 1;
            if matches!(self.peek_kind(), TokenKind::IntegerLiteral(_)) {
                self.index += 1;
            }
            self.expect_line_end()?;
            Ok(Statement::Compound(vec![]))
        } else if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            // EXIT(code) — treat as exit function with code
            let args = self.parse_args()?;
            self.expect_line_end()?;
            Ok(Statement::Call {
                name: "exit".to_string(),
                args,
            })
        } else if self.at_line_end() {
            // Bare EXIT — treat as exit function
            self.expect_line_end()?;
            Ok(Statement::ExitFunction)
        } else {
            self.expect_keyword(Keyword::While)?;
            self.expect_line_end()?;
            Ok(Statement::ExitLoop)
        }
    }
    pub(crate) fn is_end_program(&self) -> bool {
        self.peek_keyword() == Some(Keyword::End)
            && self.peek_next_kind() == Some(&TokenKind::Keyword(Keyword::Program))
    }

    #[allow(dead_code)]
    pub(crate) fn is_end_if(&self) -> bool {
        self.peek_keyword() == Some(Keyword::End)
            && self.peek_next_kind() == Some(&TokenKind::Keyword(Keyword::If))
    }
    pub(crate) fn export_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Export)?;
        // EXPORT is typically standalone or followed by names on the same line.
        // Just skip to end of line.
        while !self.at_line_end() && !self.at_eof() {
            self.index += 1;
        }
        self.expect_line_end()?;
        Ok(Statement::EndProgram)
    }

    fn starts_end_export(&self) -> bool {
        self.peek_keyword() == Some(Keyword::End)
            && self.peek_next_kind() == Some(&TokenKind::Keyword(Keyword::Export))
    }

    pub(crate) fn is_end_export(&self) -> bool {
        self.starts_end_export()
    }

    pub(crate) fn end_export_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::Export)?;
        self.expect_line_end()?;
        Ok(Statement::EndProgram)
    }

    pub(crate) fn return_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Return)?;
        let value = if self.at_line_end() {
            None
        } else if matches!(self.peek_kind(), TokenKind::Symbol('('))
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol(')')))
        {
            // RETURN () — empty parens, treat as no return value
            self.index += 2;
            None
        } else {
            Some(self.expression()?)
        };
        self.expect_line_end()?;
        Ok(Statement::Return { value })
    }
}

impl Parser {
    pub(crate) fn shared_static_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        let is_shared = matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Shared));
        self.index += 1; // consume SHARED/STATIC keyword
                         // Skip optional /path/ prefix: SHARED /yyy/ retAddr[999]
        if matches!(self.peek_kind(), TokenKind::Symbol('/')) {
            self.index += 1;
            while !self.at_line_end() && !matches!(self.peek_kind(), TokenKind::Symbol('/')) {
                self.index += 1;
            }
            if matches!(self.peek_kind(), TokenKind::Symbol('/')) {
                self.index += 1;
            }
        }
        // A composite TYPE qualifier (`SHARED TYPE var[…]`) is captured so the
        // variable is registered composite and (for a sized array) its member
        // arrays are created in the shared store; a non-composite qualifier is
        // skipped as before.
        let mut composite_type: Option<String> = None;
        if let TokenKind::Identifier { name: tn, .. } = self.peek_kind().clone() {
            if self.composite_types.contains(&tn)
                && matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Identifier { .. }) | Some(TokenKind::SharedName(_))
                )
            {
                composite_type = Some(tn);
                self.index += 1;
            }
        }
        if composite_type.is_none() && matches!(self.peek_kind(), TokenKind::Identifier { .. }) {
            let saved = self.index;
            self.index += 1;
            if !matches!(self.peek_kind(), TokenKind::Identifier { .. })
                && !matches!(self.peek_kind(), TokenKind::SharedName(_))
                && !matches!(self.peek_kind(), TokenKind::SystemVariable { .. })
            {
                self.index = saved;
            }
        }
        let (name, suffix) = match self.peek_kind().clone() {
            TokenKind::SharedName(n) => {
                self.index += 1;
                (n, None)
            }
            TokenKind::SystemVariable { name, suffix } => {
                self.index += 1;
                (name, suffix)
            }
            _ => self.expect_name_or_keyword()?,
        };
        let (size, is_array, extra_dims) = self.parse_array_size()?;
        // Collect comma-separated additional variables: `SHARED a, b, c`
        // Each gets its own Dim with shared=true. Only the first may carry
        // a composite type qualifier; the rest are plain shared scalars/arrays.
        let mut dims: Vec<Statement> = Vec::new();
        if let Some(type_name) = composite_type {
            let decl = Statement::CompositeDecl {
                type_name,
                var: name.clone(),
                shared: is_shared,
                is_array,
            };
            dims.push(decl);
            if is_array && size.is_some() {
                dims.push(Statement::Dim {
                    name,
                    suffix,
                    size,
                    extra_dims,
                    is_array: true,
                    redim: false,
                    shared: is_shared,
                });
            }
        } else {
            dims.push(Statement::Dim {
                name,
                suffix,
                size,
                extra_dims,
                is_array,
                redim: false,
                shared: is_shared,
            });
        }
        // Parse additional comma-separated variables
        while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
            self.index += 1; // consume comma
            let (n2, s2) = match self.peek_kind().clone() {
                TokenKind::SharedName(n) => {
                    self.index += 1;
                    (n, None)
                }
                TokenKind::SystemVariable { name, suffix } => {
                    self.index += 1;
                    (name, suffix)
                }
                _ => self.expect_name_or_keyword()?,
            };
            let (sz2, ia2, ed2) = self.parse_array_size()?;
            dims.push(Statement::Dim {
                name: n2,
                suffix: s2,
                size: sz2,
                extra_dims: ed2,
                is_array: ia2,
                redim: false,
                shared: is_shared,
            });
        }
        self.skip_to_line_end();
        if dims.len() == 1 {
            return Ok(dims.pop().unwrap());
        }
        Ok(Statement::Compound(dims))
    }

    pub(crate) fn redim_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.index += 1;
        let (name, suffix) = Self::shared_name_suffix(self.expect_name_or_keyword()?);
        let (size, is_array, extra_dims) = self.parse_array_size()?;
        self.expect_line_end()?;
        Ok(Statement::Dim {
            name,
            suffix,
            size,
            extra_dims,
            is_array,
            redim: true,
            shared: false,
        })
    }
}

pub(crate) fn parse_print(parser: &mut Parser) -> Result<Statement, crate::ParseError> {
    parser.expect_keyword(Keyword::Print)?;
    if parser.at_line_end() {
        parser.expect_line_end()?;
        return Ok(Statement::Print {
            items: vec![],
            separators: vec![],
        });
    }
    // Skip optional file handle: PRINT [outfile], ...
    if matches!(parser.peek_kind(), TokenKind::Symbol('[')) {
        parser.index += 1;
        let _ = parser.expression();
        if matches!(parser.peek_kind(), TokenKind::Symbol(']')) {
            parser.index += 1;
        }
        // Skip optional comma after file handle
        if matches!(parser.peek_kind(), TokenKind::Symbol(',')) {
            parser.index += 1;
        }
    }
    if parser.at_line_end() {
        parser.expect_line_end()?;
        return Ok(Statement::Print {
            items: vec![],
            separators: vec![],
        });
    }
    let mut items = vec![parse_print_item(parser)?];
    let mut separators = Vec::new();
    loop {
        if matches!(
            parser.peek_kind(),
            TokenKind::Symbol(';') | TokenKind::Symbol(',')
        ) {
            let is_comma = matches!(parser.peek_kind(), TokenKind::Symbol(','));
            parser.index += 1;
            separators.push(if is_comma {
                PrintSep::Comma
            } else {
                PrintSep::Semicolon
            });
            // Handle consecutive separators (;;) — push empty items
            if matches!(parser.peek_kind(), TokenKind::Symbol(';'))
                || matches!(parser.peek_kind(), TokenKind::Symbol(','))
            {
                items.push(Expression::StringLiteral(String::new()));
                continue;
            }
            if parser.at_line_end() {
                break;
            }
            items.push(parse_print_item(parser)?);
        } else if !(parser.at_line_end()
            || parser.in_single_line_if && matches!(parser.peek_kind(), TokenKind::Symbol(':')))
        {
            // Space-separated item: implicit semicolon
            separators.push(PrintSep::Semicolon);
            items.push(parse_print_item(parser)?);
        } else {
            break;
        }
    }
    parser.expect_line_end()?;
    Ok(Statement::Print { items, separators })
}

/// Parse a print item — either a normal expression or an inline IF expression.
fn parse_print_item(parser: &mut Parser) -> Result<Expression, crate::ParseError> {
    if matches!(parser.peek_keyword(), Some(Keyword::If)) {
        parser.index += 1;
        let cond = parser.expression()?;
        // Skip optional THEN
        if matches!(parser.peek_keyword(), Some(Keyword::Then)) {
            parser.index += 1;
        }
        parser.in_single_line_if = true;
        // The then/else branches may contain PRINT statements (inline IF as print item)
        // Parse the branch as a print expression or regular expression
        let then_expr = parse_inline_if_branch(parser)?;
        let else_expr = if matches!(parser.peek_keyword(), Some(Keyword::Else)) {
            parser.index += 1;
            Some(parse_inline_if_branch(parser)?)
        } else {
            None
        };
        parser.in_single_line_if = false;
        let mut args = vec![cond, then_expr];
        if let Some(ee) = else_expr {
            args.push(ee);
        }
        return Ok(Expression::FunctionCall {
            name: "IF".to_string(),
            args,
        });
    }
    parser.expression()
}

/// Parse a branch of an inline IF inside a PRINT statement.
/// Handles PRINT statements by converting them to string expressions.
fn parse_inline_if_branch(parser: &mut Parser) -> Result<Expression, crate::ParseError> {
    if matches!(parser.peek_keyword(), Some(Keyword::Print)) {
        // Parse PRINT statement and extract items as a concatenated string
        let stmt = parser.print_stmt()?;
        if let Statement::Print { items, .. } = stmt {
            // Join items as a single expression (simplified: just take first item)
            if items.len() == 1 {
                return Ok(items.into_iter().next().unwrap());
            }
            // Multiple items: wrap in a function call
            return Ok(Expression::FunctionCall {
                name: "PRINT".to_string(),
                args: items,
            });
        }
        return Ok(Expression::StringLiteral(String::new()));
    }
    parser.expression()
}
