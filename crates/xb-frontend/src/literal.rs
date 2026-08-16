use crate::lexeme::{is_hex_digit, is_identifier_part, is_identifier_start};
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
                // Check for doubled quote ("") — XBasic escape for literal "
                self.advance();
                if self.lookahead == Some('"') {
                    value.push('"');
                    self.advance();
                    continue;
                }
                return Ok(Token::new(TokenKind::StringLiteral(value), pos));
            }
            if ch == '\\' {
                // C-style escapes: \" → ", \\ → \, \n → newline, \t → tab, \r → CR
                self.advance();
                match self.lookahead {
                    Some('"') => value.push('"'),
                    Some('\\') => value.push('\\'),
                    Some('n') => value.push('\n'),
                    Some('t') => value.push('\t'),
                    Some('r') => value.push('\r'),
                    Some(other) => {
                        // Unknown escape: keep backslash + char literally
                        value.push('\\');
                        value.push(other);
                    }
                    None => {
                        value.push('\\');
                        break;
                    }
                }
                self.advance();
                continue;
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
            if let Some(prefix @ ('b' | 'B')) = self.lookahead {
                text.push(prefix);
                self.advance();
                self.take_while(&mut text, crate::lexeme::is_bin_digit);
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
            // Only treat as exponent if followed by digit or +/- and digit
            let next = self.chars.clone().next();
            let is_exp = match next {
                Some(c) if c.is_ascii_digit() => true,
                Some('+' | '-') => {
                    let mut peek = self.chars.clone();
                    peek.next(); // skip sign
                    peek.next().map(|c| c.is_ascii_digit()).unwrap_or(false)
                }
                _ => false,
            };
            if is_exp {
                is_float = true;
                self.take_exponent(&mut text);
            }
        }
        // Handle type suffix: # (Double), ! (Single), % (Integer)
        match self.lookahead {
            Some('#') => {
                self.advance();
                return Token::new(TokenKind::FloatLiteral(text), pos);
            }
            Some('!') => {
                self.advance();
                return Token::new(TokenKind::FloatLiteral(text), pos);
            }
            Some('%') => {
                self.advance();
                return Token::new(TokenKind::IntegerLiteral(text), pos);
            }
            _ => {}
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
        // Handle @@ suffix (XBasic absolute/external variable indicator)
        if self.lookahead == Some('@') {
            while self.lookahead == Some('@') {
                name.push('@');
                self.advance();
            }
        }
        let suffix = self.type_suffix();
        if suffix.is_none() && name.to_ascii_uppercase() == "REM" {
            self.skip_comment();
            if self.lookahead == Some('\n') {
                self.advance();
            }
            return Token::new(TokenKind::Newline, pos);
        }
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
            let suffix = self.type_suffix();
            return Ok(Token::new(TokenKind::SystemVariable { name, suffix }, pos));
        }
        let name = self.name_after_prefix(pos)?;
        Ok(Token::new(TokenKind::SharedName(name), pos))
    }

    pub(crate) fn system_constant(&mut self) -> Result<Token, LexError> {
        let pos = self.pos();
        self.advance();
        if self.lookahead == Some('$') {
            self.advance();
        }
        // If no identifier follows, treat as bare $ symbol
        if self.lookahead.map(|c| !is_identifier_start(c)).unwrap_or(true) {
            return Ok(Token::new(TokenKind::Symbol('$'), pos));
        }
        let name = self.name_after_prefix(pos)?;
        let suffix = self.type_suffix();
        if let Some(s) = suffix {
            return Ok(Token::new(
                TokenKind::SystemVariable {
                    name: format!("$${name}"),
                    suffix: Some(s),
                },
                pos,
            ));
        }
        Ok(Token::new(TokenKind::SystemConstant(name), pos))
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
            ('<', Some('<')) => {
                self.advance();
                TokenKind::Shl
            }
            ('>', Some('>')) => {
                self.advance();
                // Check for >>> (unsigned right shift)
                if self.lookahead == Some('>') {
                    self.advance();
                }
                TokenKind::Shr
            }
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
            ('=', Some('=')) => {
                self.advance();
                TokenKind::Equal
            }
            _ => TokenKind::Symbol(first),
        };
        Token::new(kind, pos)
    }

    pub(crate) fn bang_or_symbol(&mut self) -> Token {
        let pos = self.pos();
        self.advance();
        if self.lookahead == Some('=') {
            self.advance();
            Token::new(TokenKind::NotEqual, pos)
        } else {
            Token::new(TokenKind::Symbol('!'), pos)
        }
    }

    pub(crate) fn logical_or_symbol(&mut self) -> Token {
        let pos = self.pos();
        let first = self.lookahead.unwrap();
        self.advance();
        if self.lookahead == Some(first) {
            self.advance();
            Token::new(
                match first {
                    '&' => TokenKind::LogicalAnd,
                    '|' => TokenKind::LogicalOr,
                    '^' => TokenKind::LogicalXor,
                    _ => TokenKind::Symbol(first),
                },
                pos,
            )
        } else {
            Token::new(TokenKind::Symbol(first), pos)
        }
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

    pub(crate) fn single_quote_string(&mut self) -> Result<Token, LexError> {
        let pos = self.pos();
        self.advance(); // skip opening '
        let mut value = String::new();
        while let Some(ch) = self.lookahead {
            if ch == '\'' {
                self.advance(); // skip closing '
                // Single-quoted chars in XBasic are integer literals (ASCII codes)
                let int_val = if value.chars().count() == 1 {
                    value.chars().next().unwrap() as i64
                } else {
                    // Multi-char: pack like C (implementation-defined, use simple hash)
                    let mut result: i64 = 0;
                    for ch in value.chars() {
                        result = (result << 8) | (ch as i64 & 0xFF);
                    }
                    result
                };
                return Ok(Token::new(TokenKind::IntegerLiteral(int_val.to_string()), pos));
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
}
