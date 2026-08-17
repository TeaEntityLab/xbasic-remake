use crate::ast::Statement;
use crate::parser::{ParseError, Parser};
use crate::token::{Keyword, TokenKind};

impl Parser {
    pub(crate) fn do_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Do)?;
        // DO NEXT means "continue to next iteration" — treat as ExitLoop
        if matches!(self.peek_keyword(), Some(Keyword::Next)) {
            self.index += 1;
            // DO NEXT <n> — exit n loops, consume the number
            if matches!(self.peek_kind(), TokenKind::IntegerLiteral(_)) {
                self.index += 1;
            }
            self.expect_line_end()?;
            return Ok(Statement::ExitLoop);
        }
        // DO FOR means "continue to next iteration of FOR loop" — treat as ExitLoop
        if matches!(self.peek_keyword(), Some(Keyword::For)) {
            self.index += 1;
            self.expect_line_end()?;
            return Ok(Statement::ExitLoop);
        }
        // DO DO means "do nothing" — treat as no-op
        if matches!(self.peek_keyword(), Some(Keyword::Do)) {
            self.index += 1;
            self.expect_line_end()?;
            return Ok(Statement::Compound(vec![]));
        }
        let pre_condition = match self.peek_keyword() {
            Some(Keyword::While) => {
                self.index += 1;
                let cond = self.expression()?;
                Some((cond, true))
            }
            Some(Keyword::Until) => {
                self.index += 1;
                let cond = self.expression()?;
                Some((cond, false))
            }
            _ => None,
        };
        // DO LOOP — empty loop with no body
        if matches!(self.peek_keyword(), Some(Keyword::Loop)) {
            self.index += 1;
            self.expect_line_end()?;
            return Ok(Statement::DoLoop {
                pre_condition: None,
                post_condition: None,
                body: Vec::new(),
            });
        }
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_loop() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::Loop)?;
        let post_condition = match self.peek_keyword() {
            Some(Keyword::While) => {
                self.index += 1;
                let cond = self.expression()?;
                Some((cond, true))
            }
            Some(Keyword::Until) => {
                self.index += 1;
                let cond = self.expression()?;
                Some((cond, false))
            }
            _ => None,
        };
        self.expect_line_end()?;
        Ok(Statement::DoLoop {
            pre_condition,
            post_condition,
            body,
        })
    }

    pub(crate) fn for_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::For)?;
        let (var, _) = self.expect_name_or_keyword()?;
        self.expect_symbol('=')?;
        let start = self.expression()?;
        self.expect_keyword(Keyword::To)?;
        let end = self.expression()?;
        let step = if matches!(self.peek_keyword(), Some(Keyword::Step)) {
            self.index += 1;
            Some(self.expression()?)
        } else {
            None
        };
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_next() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::Next)?;
        if !self.at_line_end()
            && !self.at_eof()
            && matches!(
                self.peek_kind(),
                TokenKind::Identifier { .. } | TokenKind::Keyword(_)
            )
        {
            self.index += 1;
        }
        self.expect_line_end()?;
        Ok(Statement::For {
            var,
            start,
            end,
            step,
            body,
        })
    }
}
