use crate::ast::{FunctionDecl, Program, Statement};
use crate::lexer::{lex, LexError};
use crate::token::{full_name, Keyword, Token, TokenKind};
use thiserror::Error;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum ParseError {
    #[error(transparent)]
    Lex(#[from] LexError),
    #[error("expected {expected} at {line}:{column}")]
    Expected {
        expected: &'static str,
        line: usize,
        column: usize,
    },
}

pub fn parse_program(source: &str) -> Result<Program, ParseError> {
    Parser::new(lex(source)?).parse_program()
}

pub struct Parser {
    pub(crate) tokens: Vec<Token>,
    pub(crate) index: usize,
}

impl Parser {
    pub const fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, index: 0 }
    }

    pub fn parse_program(mut self) -> Result<Program, ParseError> {
        let mut statements = Vec::new();
        self.skip_newlines();
        while !self.at_eof() {
            statements.push(self.statement()?);
            self.skip_newlines();
        }
        Ok(Program::new(statements))
    }

    pub(crate) fn statement(&mut self) -> Result<Statement, ParseError> {
        if self.starts_constant_definition() {
            return self.constant_definition_stmt();
        }
        if self.starts_shared_assignment() {
            return self.shared_assignment_stmt();
        }
        if self.starts_label() {
            return self.label_stmt();
        }
        match self.peek_keyword() {
            Some(Keyword::Version) => self.version_stmt(),
            Some(Keyword::Print) => self.print_stmt(),
            Some(Keyword::Dim) => self.dim_stmt(),
            Some(Keyword::If) => self.if_stmt(),
            Some(Keyword::Ifz) => self.ifz_stmt(),
            Some(Keyword::Ift) => self.ift_stmt(),
            Some(Keyword::Iff) => self.iff_stmt(),
            Some(Keyword::For) => self.for_stmt(),
            Some(Keyword::While) => self.while_stmt(),
            Some(Keyword::Function)
            | Some(Keyword::External)
            | Some(Keyword::Internal)
            | Some(Keyword::CFunction) => self.function_stmt(),
            Some(Keyword::Do) => self.do_stmt(),
            Some(Keyword::Select) => self.select_case_stmt(),
            Some(Keyword::Export) => self.export_stmt(),
            Some(Keyword::Sub) => self.sub_stmt(),
            Some(Keyword::Exit) => self.exit_stmt(),
            Some(Keyword::Return) => self.return_stmt(),
            Some(Keyword::Inc) => self.inc_dec_stmt(true),
            Some(Keyword::Dec) => self.inc_dec_stmt(false),
            Some(Keyword::Swap) => self.swap_stmt(),
            Some(Keyword::Program) => self.program_stmt(),
            Some(Keyword::Import) => self.import_stmt(),
            Some(Keyword::Declare) => self.declare_stmt(),
            Some(Keyword::End) if self.is_end_program() => self.end_program_stmt(),
            Some(Keyword::Static) | Some(Keyword::Shared) => self.shared_static_stmt(),
            Some(Keyword::Redim) => self.redim_stmt(),
            Some(Keyword::Gosub) => self.gosub_stmt(),
            Some(Keyword::DoEvents) => self.doevents_stmt(),
            Some(Keyword::Randomize) => self.randomize_stmt(),
            Some(Keyword::Break) => self.break_stmt(),
            Some(Keyword::Goto) => self.goto_stmt(),
            Some(Keyword::Const) => self.const_stmt(),
            Some(Keyword::Data) => self.data_stmt(),
            Some(Keyword::Read) => self.read_stmt(),
            Some(Keyword::Stop) => self.stop_stmt(),
            Some(Keyword::Restore) => self.restore_stmt(),
            Some(Keyword::Let) => {
                self.index += 1;
                self.assignment_stmt()
            }
            _ if self.starts_assignment() => self.assignment_stmt(),
            _ if self.starts_call() => self.call_stmt(),
            _ => Err(self.expected("statement")),
        }
    }

    fn print_stmt(&mut self) -> Result<Statement, ParseError> {
        crate::parser_select::parse_print(self)
    }

    fn dim_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Dim)?;
        let mut dims = Vec::new();
        loop {
            let (name, suffix) = self.expect_identifier()?;
            let size = self.parse_array_size()?;
            dims.push(Statement::Dim { name, suffix, size });
            if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
            } else {
                break;
            }
        }
        self.expect_line_end()?;
        if dims.len() == 1 {
            Ok(dims.pop().unwrap())
        } else {
            Ok(Statement::Compound(dims))
        }
    }

    fn assignment_stmt(&mut self) -> Result<Statement, ParseError> {
        let (target, suffix) = self.expect_identifier()?;
        self.expect_symbol('=')?;
        let value = self.expression()?;
        self.expect_line_end()?;
        Ok(Statement::Assignment {
            target,
            suffix,
            value,
        })
    }

    fn call_stmt(&mut self) -> Result<Statement, ParseError> {
        let (name, suffix) = self.expect_identifier()?;
        let is_bracket = matches!(self.peek_kind(), TokenKind::Symbol('['));
        let args = if is_bracket {
            self.index += 1;
            let mut args = vec![self.expression()?];
            self.expect_symbol(']')?;
            while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
                args.push(self.expression()?);
            }
            args
        } else {
            self.parse_args()?
        };
        if matches!(self.peek_kind(), TokenKind::Symbol('=')) && args.len() == 1 {
            self.index += 1;
            let value = self.expression()?;
            self.expect_line_end()?;
            let full = full_name(name, suffix);
            return Ok(Statement::ArrayAssignment {
                target: full,
                index: args.into_iter().next().unwrap(),
                value,
            });
        }
        self.expect_line_end()?;
        let full = full_name(name, suffix);
        Ok(Statement::Call { name: full, args })
    }
    fn function_stmt(&mut self) -> Result<Statement, ParseError> {
        while matches!(
            self.peek_keyword(),
            Some(Keyword::External) | Some(Keyword::Internal)
        ) {
            self.index += 1;
        }
        if matches!(self.peek_keyword(), Some(Keyword::CFunction)) {
            self.index += 1;
        } else {
            self.expect_keyword(Keyword::Function)?;
        }
        let (name, suffix) = self.expect_identifier()?;
        let params = if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.parse_params()?
        } else {
            Vec::new()
        };
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_end_function() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::End)?;
        self.expect_keyword(Keyword::Function)?;
        self.expect_line_end()?;
        Ok(Statement::Function(FunctionDecl::new(
            name, suffix, params, body,
        )))
    }
    fn if_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::If)?;
        let condition = self.expression()?;
        self.expect_keyword(Keyword::Then)?;
        if self.at_line_end() {
            let stmt = self.parse_if_chain_with_cond(condition)?;
            self.expect_keyword(Keyword::End)?;
            self.expect_keyword(Keyword::If)?;
            self.expect_line_end()?;
            Ok(stmt)
        } else {
            let then_body = vec![self.statement()?];
            Ok(Statement::If {
                condition,
                then_body,
                else_body: None,
            })
        }
    }
    fn inc_dec_stmt(&mut self, is_inc: bool) -> Result<Statement, ParseError> {
        self.index += 1;
        let (target, suffix) = self.expect_identifier()?;
        self.expect_line_end()?;
        if is_inc {
            Ok(Statement::Inc { target, suffix })
        } else {
            Ok(Statement::Dec { target, suffix })
        }
    }
    fn swap_stmt(&mut self) -> Result<Statement, ParseError> {
        self.index += 1;
        let (left, left_suffix) = self.expect_identifier()?;
        self.expect_symbol(',')?;
        let (right, right_suffix) = self.expect_identifier()?;
        self.expect_line_end()?;
        Ok(Statement::Swap {
            left,
            left_suffix,
            right,
            right_suffix,
        })
    }
    pub(crate) fn while_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::While)?;
        let condition = self.expression()?;
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_wend() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::Wend)?;
        self.expect_line_end()?;
        Ok(Statement::While { condition, body })
    }
}
