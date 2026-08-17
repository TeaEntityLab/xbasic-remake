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
    pub(crate) prev_char: Option<char>,
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
            prev_char: None,
            line: 1,
            column: 1,
        }
    }

    pub fn lex_all(mut self) -> Result<Vec<Token>, LexError> {
        let mut tokens = Vec::new();
        while let Some(ch) = self.lookahead {
            match ch {
                ' ' | '\t' | '\r' | '\0' => self.advance(),
                '\n' => tokens.push(self.newline()),
                '\'' => {
                    // `'''` (three consecutive quotes) is the XBasic char literal
                    // for a single-quote character (value 39). Resolve it here, before
                    // any comment/string disambiguation, so it is never mis-split into
                    // empty-string + comment (which would eat a following THEN and
                    // corrupt IF-block structure).
                    {
                        let mut rest = self.chars.clone();
                        if rest.next() == Some('\'') && rest.next() == Some('\'') {
                            let pos = self.pos();
                            self.advance();
                            self.advance();
                            self.advance();
                            tokens.push(Token::new(
                                TokenKind::IntegerLiteral("39".to_string()),
                                pos,
                            ));
                            continue;
                        }
                    }
                    // ' is a comment when preceded by whitespace, newline, or :
                    // Exception: after "= " it's a string delimiter (e.g., c = 'n')
                    // Otherwise it's a string delimiter (XBasic single-quote strings)
                    match self.prev_char {
                        Some(' ') | Some('\t') | Some('\n') | Some('\r') | Some(':') | None => {
                            if self.prev_char == Some(' ') {
                                let rest = self.chars.as_str();
                                let line_rest = rest.split_once('\n').map(|(l, _)| l).unwrap_or(rest);
                                // ''' is empty string '' + comment ' — parse '' then skip rest as comment
                                if line_rest.starts_with("''") {
                                    tokens.push(self.single_quote_string()?);
                                    self.skip_comment();
                                    continue;
                                }
                                if line_rest.contains('\'') && !line_rest.starts_with('\'') {
                                    let before_quote = line_rest.split_once('\'').map(|(b, _)| b).unwrap_or("");
                                    if !before_quote.is_empty()
                                        && !(before_quote.len() > 1
                                            && before_quote.chars().all(|c| c.is_whitespace()))
                                        && (before_quote.len() <= 3 || (!before_quote.contains(' ') && !before_quote.contains('(') && !before_quote.contains(')'))) {
                                        tokens.push(self.single_quote_string()?);
                                        continue;
                                    }
                                }
                            }
                            self.skip_comment()
                        }
                        _ => {
                            // After a closing ', check if this ' starts a comment or string
                            let rest = self.chars.as_str();
                            let line_rest = rest.split_once('\n').map(|(l, _)| l).unwrap_or(rest);
                            if (!line_rest[1..].contains('\'') && !line_rest.starts_with("')")) || line_rest.starts_with("' ") || line_rest.starts_with("'\t") {
                                self.skip_comment();
                            } else {
                                tokens.push(self.single_quote_string()?);
                            }
                        }
                    }
                }
                '"' => tokens.push(self.string_literal()?),
                '0'..='9' => tokens.push(self.number()),
                '.' if self.chars.clone().next().map(|c| c.is_ascii_digit()).unwrap_or(false) => {
                    tokens.push(self.number())
                }
                '#' => tokens.push(self.hash_prefixed()?),
                '$' => tokens.push(self.system_constant()?),
                c if is_identifier_start(c) => tokens.push(self.identifier()),
                ':' => tokens.push(self.colon_or_symbol()),
                '<' | '>' | '=' => tokens.push(self.comparison()),
                '!' => tokens.push(self.bang_or_symbol()),
                '&' | '|' | '^' | '~' => tokens.push(self.logical_or_symbol()),
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
        self.prev_char = self.lookahead;
        if self.lookahead == Some('\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }
        self.lookahead = self.chars.next();
    }

    /// Check if there's a matching single-quote on the current line (for
    /// distinguishing string delimiters from comments).
    #[allow(dead_code)]
    fn has_matching_quote_on_line(&self) -> bool {
        self.chars
            .as_str()
            .split_once('\n')
            .map(|(line, _)| line.contains('\''))
            .unwrap_or_else(|| self.chars.as_str().contains('\''))
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
        if ch == '*' && self.lookahead == Some('*') {
            self.advance();
            return Token::new(TokenKind::Power, pos);
        }
        // XBasic uses {} for array indexing — treat as ()
        // But {{ }} is a bitfield operator — keep as distinct tokens
        if ch == '{' && self.lookahead == Some('{') {
            self.advance();
            return Token::new(TokenKind::LBrace2, pos);
        }
        if ch == '}' && self.lookahead == Some('}') {
            self.advance();
            return Token::new(TokenKind::RBrace2, pos);
        }
        let ch = match ch {
            '{' => '(',
            '}' => ')',
            c => c,
        };
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
        assert!(tokens.iter().any(
            |t| matches!(t.kind, TokenKind::SystemVariable { ref name, suffix: None } if name == "XBSystem")
        ));
    }

    #[test]
    fn lexes_suffixed_system_variable_as_one_token() {
        // Given the historical `##XBDir$` string shared variable.
        let tokens = lex("##XBDir$\n").unwrap();

        // Then the suffix belongs to the shared name, not a following symbol.
        assert!(matches!(
            tokens[0].kind,
            TokenKind::SystemVariable {
                ref name,
                suffix: Some(TypeSuffix::String)
            } if name == "XBDir"
        ));
        assert_eq!(tokens[1].kind, TokenKind::Newline);
    }
}
