use crate::parser::{ParseError, Parser};
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

    pub(crate) fn expect_line_end(&mut self) -> Result<(), ParseError> {
        match self.peek_kind() {
            TokenKind::Newline => {
                self.index += 1;
                Ok(())
            }
            TokenKind::Eof => Ok(()),
            _ => Err(self.expected("end of line")),
        }
    }

    pub(crate) fn skip_newlines(&mut self) {
        while matches!(self.peek_kind(), TokenKind::Newline) {
            self.index += 1;
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
}
