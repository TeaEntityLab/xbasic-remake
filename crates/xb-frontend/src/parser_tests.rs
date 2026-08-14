use crate::{parse_program, ParseError, Statement, TypeSuffix};

#[test]
fn parses_bootstrap_subset_when_program_has_function_body() {
    let src = "VERSION \"6.5.0\"\nDIM name$\nFUNCTION Main\nPRINT \"hello\"\nEND FUNCTION\n";
    let program = parse_program(src).unwrap();
    assert_eq!(program.statements.len(), 3);
    assert!(matches!(program.statements[0], Statement::Version(_)));
    assert!(matches!(
        program.statements[1],
        Statement::Dim {
            suffix: Some(TypeSuffix::String),
            ..
        }
    ));
    assert!(matches!(program.statements[2], Statement::Function(_)));
}

#[test]
fn rejects_trailing_tokens_after_print_expression() {
    let result = parse_program("PRINT \"hello\" garbage\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "end of line",
            ..
        })
    ));
}

#[test]
fn rejects_version_without_string_literal() {
    let result = parse_program("VERSION\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "string literal",
            ..
        })
    ));
}

#[test]
fn rejects_function_missing_end_function() {
    let result = parse_program("FUNCTION Main\nPRINT \"x\"\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "keyword",
            ..
        })
    ));
}

#[test]
fn rejects_trailing_tokens_after_dim() {
    let result = parse_program("DIM name$ extra\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "end of line",
            ..
        })
    ));
}

#[test]
fn rejects_print_without_expression() {
    let result = parse_program("PRINT\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "expression",
            ..
        })
    ));
}

#[test]
fn rejects_trailing_tokens_after_function_header() {
    let result = parse_program("FUNCTION Main garbage\nEND FUNCTION\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "end of line",
            ..
        })
    ));
}

#[test]
fn rejects_trailing_tokens_after_end_function() {
    let result = parse_program("FUNCTION Main\nEND FUNCTION garbage\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "end of line",
            ..
        })
    ));
}
