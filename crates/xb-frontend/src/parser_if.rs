use crate::ast::Statement;
use crate::parser::{ParseError, Parser};
use crate::token::Keyword;

impl Parser {
    pub(crate) fn parse_if_chain(&mut self) -> Result<Statement, ParseError> {
        let condition = self.expression()?;
        self.expect_keyword(Keyword::Then)?;
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
}
