pub(crate) fn is_identifier_start(ch: char) -> bool {
    ch == '_' || ch.is_ascii_alphabetic()
}

pub(crate) fn is_identifier_part(ch: char) -> bool {
    is_identifier_start(ch) || ch.is_ascii_digit()
}

pub(crate) fn is_hex_digit(ch: char) -> bool {
    ch.is_ascii_hexdigit()
}

pub(crate) fn is_symbol(ch: char) -> bool {
    matches!(
        ch,
        '(' | ')' | '[' | ']' | ',' | '+' | '-' | '*' | '/' | '=' | '@' | '.' | '\\'
    )
}
