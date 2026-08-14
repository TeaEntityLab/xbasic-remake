use crate::lexeme::{is_hex_digit, is_identifier_part};
use crate::lexer::{LexError, Lexer};
use crate::token::{Keyword, SourcePos, Token, TokenKind, TypeSuffix};

impl Lexer<'_> {
    pub(crate) fn skip_comment(&mut self) {
        while let Some(ch) = self.lookahead {
            if ch == '\n' {
                return;
            }
            self.advance();
        }
    }

    pub(crate) fn string_literal(&mut self) -> Result<Token, LexError> {
        let pos = self.pos();
        self.advance();
        let mut value = String::new();
        while let Some(ch) = self.lookahead {
            if ch == '"' {
                self.advance();
                return Ok(Token::new(TokenKind::StringLiteral(value), pos));
            }
            if ch == '\n' {
                break;
            }
            value.push(ch);
            self.advance();
        }
        Err(LexError::UnterminatedString {
            line: pos.line,
            column: pos.column,
        })
    }

    pub(crate) fn number(&mut self) -> Token {
        let pos = self.pos();
        let mut text = String::new();
        let mut is_float = false;
        if self.lookahead == Some('0') {
            text.push('0');
            self.advance();
            if let Some(prefix @ ('x' | 'X')) = self.lookahead {
                text.push(prefix);
                self.advance();
                self.take_while(&mut text, is_hex_digit);
                return Token::new(TokenKind::IntegerLiteral(text), pos);
            }
        }
        self.take_while(&mut text, |ch| ch.is_ascii_digit());
        if self.lookahead == Some('.') {
            is_float = true;
            text.push('.');
            self.advance();
            self.take_while(&mut text, |ch| ch.is_ascii_digit());
        }
        if matches!(self.lookahead, Some('e' | 'E')) {
            is_float = true;
            self.take_exponent(&mut text);
        }
        let kind = if is_float {
            TokenKind::FloatLiteral(text)
        } else {
            TokenKind::IntegerLiteral(text)
        };
        Token::new(kind, pos)
    }

    pub(crate) fn identifier(&mut self) -> Token {
        let pos = self.pos();
        let mut name = String::new();
        self.take_while(&mut name, is_identifier_part);
        let suffix = self.type_suffix();
        if suffix.is_none() {
            if let Some(keyword) = Keyword::parse(&name) {
                return Token::new(TokenKind::Keyword(keyword), pos);
            }
        }
        Token::new(TokenKind::Identifier { name, suffix }, pos)
    }

    pub(crate) fn hash_prefixed(&mut self) -> Result<Token, LexError> {
        let pos = self.pos();
        self.advance();
        if self.lookahead == Some('#') {
            self.advance();
            let name = self.name_after_prefix(pos)?;
            return Ok(Token::new(TokenKind::SystemVariable(name), pos));
        }
        let name = self.name_after_prefix(pos)?;
        Ok(Token::new(TokenKind::SharedName(name), pos))
    }

    pub(crate) fn system_constant(&mut self) -> Result<Token, LexError> {
        let pos = self.pos();
        self.advance();
        if self.lookahead == Some('$') {
            self.advance();
            let name = self.name_after_prefix(pos)?;
            return Ok(Token::new(TokenKind::SystemConstant(name), pos));
        }
        Ok(Token::new(TokenKind::Symbol('$'), pos))
    }

    pub(crate) fn colon_or_symbol(&mut self) -> Token {
        let pos = self.pos();
        self.advance();
        if self.lookahead == Some(':') {
            self.advance();
            return Token::new(TokenKind::ColonColon, pos);
        }
        Token::new(TokenKind::Symbol(':'), pos)
    }

    pub(crate) fn comparison(&mut self) -> Token {
        let pos = self.pos();
        let first = self.lookahead.unwrap_or('<');
        self.advance();
        let kind = match (first, self.lookahead) {
            ('<', Some('=')) => {
                self.advance();
                TokenKind::LessEqual
            }
            ('>', Some('=')) => {
                self.advance();
                TokenKind::GreaterEqual
            }
            ('<', Some('>')) => {
                self.advance();
                TokenKind::NotEqual
            }
            _ => TokenKind::Symbol(first),
        };
        Token::new(kind, pos)
    }

    fn take_exponent(&mut self, out: &mut String) {
        if let Some(ch) = self.lookahead {
            out.push(ch);
            self.advance();
        }
        if let Some(sign @ ('+' | '-')) = self.lookahead {
            out.push(sign);
            self.advance();
        }
        self.take_while(out, |ch| ch.is_ascii_digit());
    }

    fn type_suffix(&mut self) -> Option<TypeSuffix> {
        let suffix = match self.lookahead {
            Some('$') => TypeSuffix::String,
            Some('%') => TypeSuffix::Integer,
            Some('!') => TypeSuffix::Single,
            Some('#') => TypeSuffix::Double,
            _ => return None,
        };
        self.advance();
        Some(suffix)
    }

    fn name_after_prefix(&mut self, pos: SourcePos) -> Result<String, LexError> {
        let mut name = String::new();
        self.take_while(&mut name, is_identifier_part);
        if name.is_empty() {
            return Err(LexError::UnexpectedChar {
                ch: self.lookahead.unwrap_or('\0'),
                line: pos.line,
                column: pos.column,
            });
        }
        Ok(name)
    }
}
