use crate::ast::{CaseClause, FunctionDecl, PrintSep, Statement};
use crate::parser::Parser;
use crate::token::{Keyword, TokenKind};

impl Parser {
    pub(crate) fn select_case_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Select)?;
        self.expect_keyword(Keyword::Case)?;
        let selector = self.expression()?;
        self.expect_line_end()?;
        let mut cases = Vec::new();
        let mut default = None;
        self.skip_newlines();
        while !self.at_eof() && !self.starts_end_select() {
            self.expect_keyword(Keyword::Case)?;
            if self.peek_keyword() == Some(Keyword::Else) {
                self.index += 1;
                self.expect_line_end()?;
                let mut body = Vec::new();
                self.skip_newlines();
                while !self.at_eof() && !self.starts_end_select() {
                    body.push(self.statement()?);
                    self.skip_newlines();
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
                self.expect_line_end()?;
                let mut body = Vec::new();
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
        Ok(Statement::SelectCase {
            selector,
            cases,
            default,
        })
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
        let (name, _) = self.expect_identifier()?;
        let mut args = Vec::new();
        if self.peek_kind() == &TokenKind::Symbol('(') {
            self.index += 1;
            if self.peek_kind() != &TokenKind::Symbol(')') {
                loop {
                    let (arg_name, _) = self.expect_identifier()?;
                    args.push(arg_name);
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
        let (name, suffix) = self.expect_identifier()?;
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
            self.expect_line_end()?;
            Ok(Statement::Return { value: None })
        } else if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::For))
            || matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Do))
            || matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Loop))
        {
            self.index += 1;
            self.expect_line_end()?;
            Ok(Statement::ExitLoop)
        } else if matches!(self.peek_kind(), TokenKind::Keyword(Keyword::Select)) {
            self.index += 1;
            self.expect_line_end()?;
            Ok(Statement::ExitSelect)
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

    pub(crate) fn export_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.expect_keyword(Keyword::Export)?;
        if self.at_line_end() {
            self.expect_line_end()?;
            self.skip_newlines();
            while !self.at_eof() && !self.starts_end_export() {
                self.statement()?;
                self.skip_newlines();
            }
            self.expect_keyword(Keyword::End)?;
            self.expect_keyword(Keyword::Export)?;
            self.expect_line_end()?;
        } else {
            while !self.at_line_end() && !self.at_eof() {
                self.index += 1;
            }
            self.expect_line_end()?;
        }
        Ok(Statement::Program(String::new()))
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
        } else {
            Some(self.expression()?)
        };
        self.expect_line_end()?;
        Ok(Statement::Return { value })
    }
}

impl Parser {
    pub(crate) fn shared_static_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.index += 1;
        if matches!(self.peek_kind(), TokenKind::Identifier { .. }) {
            let saved = self.index;
            self.index += 1;
            if !matches!(self.peek_kind(), TokenKind::Identifier { .. }) {
                self.index = saved;
            }
        }
        let (name, suffix) = self.expect_identifier()?;
        let size = self.parse_array_size()?;
        self.skip_to_line_end();
        Ok(Statement::Dim { name, suffix, size })
    }

    pub(crate) fn redim_stmt(&mut self) -> Result<Statement, crate::ParseError> {
        self.index += 1;
        let (name, suffix) = self.expect_identifier()?;
        let size = self.parse_array_size()?;
        self.expect_line_end()?;
        Ok(Statement::Dim { name, suffix, size })
    }
}

pub(crate) fn parse_print(parser: &mut Parser) -> Result<Statement, crate::ParseError> {
    parser.expect_keyword(Keyword::Print)?;
    let mut items = vec![parser.expression()?];
    let mut separators = Vec::new();
    while matches!(
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
        if parser.at_line_end() {
            break;
        }
        items.push(parser.expression()?);
    }
    parser.expect_line_end()?;
    Ok(Statement::Print { items, separators })
}
