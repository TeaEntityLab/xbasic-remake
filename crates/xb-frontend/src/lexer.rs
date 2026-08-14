use crate::lexeme::{is_identifier_start, is_symbol};
use crate::token::{SourcePos, Token, TokenKind};
use thiserror::Error;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum LexError {
    #[error("unterminated string at {line}:{column}")]
    UnterminatedString { line: usize, column: usize },
    #[error("unexpected character {ch:?} at {line}:{column}")]
    UnexpectedChar {
        ch: char,
        line: usize,
        column: usize,
    },
}

pub fn lex(input: &str) -> Result<Vec<Token>, LexError> {
    Lexer::new(input).lex_all()
}

pub struct Lexer<'a> {
    pub(crate) chars: std::str::Chars<'a>,
    pub(crate) lookahead: Option<char>,
    line: usize,
    column: usize,
}

impl<'a> Lexer<'a> {
    pub fn new(input: &'a str) -> Self {
        let mut chars = input.chars();
        let lookahead = chars.next();
        Self {
            chars,
            lookahead,
            line: 1,
            column: 1,
        }
    }

    pub fn lex_all(mut self) -> Result<Vec<Token>, LexError> {
        let mut tokens = Vec::new();
        while let Some(ch) = self.lookahead {
            match ch {
                ' ' | '\t' | '\r' => self.advance(),
                '\n' => tokens.push(self.newline()),
                '\'' => self.skip_comment(),
                '"' => tokens.push(self.string_literal()?),
                '0'..='9' => tokens.push(self.number()),
                '#' => tokens.push(self.hash_prefixed()?),
                '$' => tokens.push(self.system_constant()?),
                c if is_identifier_start(c) => tokens.push(self.identifier()),
                ':' => tokens.push(self.colon_or_symbol()),
                '<' | '>' => tokens.push(self.comparison()),
                c if is_symbol(c) => tokens.push(self.symbol(c)),
                other => return Err(self.unexpected(other)),
            }
        }
        tokens.push(Token::new(TokenKind::Eof, self.pos()));
        Ok(tokens)
    }

    pub(crate) fn pos(&self) -> SourcePos {
        SourcePos::new(self.line, self.column)
    }

    pub(crate) fn advance(&mut self) {
        if self.lookahead == Some('\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }
        self.lookahead = self.chars.next();
    }

    pub(crate) fn take_while(&mut self, out: &mut String, pred: impl Fn(char) -> bool) {
        while let Some(ch) = self.lookahead {
            if !pred(ch) {
                break;
            }
            out.push(ch);
            self.advance();
        }
    }

    pub(crate) fn unexpected(&self, ch: char) -> LexError {
        let pos = self.pos();
        LexError::UnexpectedChar {
            ch,
            line: pos.line,
            column: pos.column,
        }
    }

    fn newline(&mut self) -> Token {
        let pos = self.pos();
        self.advance();
        Token::new(TokenKind::Newline, pos)
    }

    fn symbol(&mut self, ch: char) -> Token {
        let pos = self.pos();
        self.advance();
        Token::new(TokenKind::Symbol(ch), pos)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::token::{Keyword, TokenKind, TypeSuffix};

    #[test]
    fn lexes_fork_features_when_present() {
        let src = "PACKED Vec2\nDIM name$\nIF a :: b THEN\nmask = 0xFF\n$$XBSysLinux\n##XBSystem\n";
        let tokens = lex(src).unwrap();
        assert!(tokens
            .iter()
            .any(|t| t.kind == TokenKind::Keyword(Keyword::Packed)));
        assert!(tokens.iter().any(|t| matches!(t.kind, TokenKind::Identifier { ref name, suffix: Some(TypeSuffix::String) } if name == "name")));
        assert!(tokens.iter().any(|t| t.kind == TokenKind::ColonColon));
        assert!(tokens
            .iter()
            .any(|t| t.kind == TokenKind::IntegerLiteral("0xFF".to_string())));
        assert!(tokens
            .iter()
            .any(|t| t.kind == TokenKind::SystemConstant("XBSysLinux".to_string())));
        assert!(tokens
            .iter()
            .any(|t| t.kind == TokenKind::SystemVariable("XBSystem".to_string())));
    }
}
