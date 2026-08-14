use crate::{parse_program, Expression, ParseError, Statement, TypeSuffix};

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
fn parses_assignment_statement_when_target_is_identifier() {
    let program = parse_program("name$ = \"hello\"\n").unwrap();
    assert!(matches!(
        program.statements[0],
        Statement::Assignment {
            ref target,
            suffix: Some(TypeSuffix::String),
            value: crate::Expression::StringLiteral(_),
        } if target == "name"
    ));
}

#[test]
fn rejects_trailing_tokens_after_assignment() {
    let result = parse_program("name$ = \"hello\" garbage\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "end of line",
            ..
        })
    ));
}

#[test]
fn rejects_assignment_without_value() {
    let result = parse_program("name$ =\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "expression",
            ..
        })
    ));
}

#[test]
fn rejects_bare_identifier_statement() {
    let result = parse_program("name$\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "statement",
            ..
        })
    ));
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

#[test]
fn parses_integer_constant_definitions_and_references() {
    let src = "$$XBSysLinux = 1\nFUNCTION Main\n$$Local = 0x2\nPRINT $$XBSysLinux\nEND FUNCTION\n";
    let program = parse_program(src).unwrap();

    assert!(matches!(
        program.statements[0],
        Statement::ConstantDefinition { ref name, ref value }
            if name == "XBSysLinux" && value == "1"
    ));
    assert!(matches!(
        program.statements[1],
        Statement::Function(ref function)
            if matches!(
                function.body.as_slice(),
                [
                    Statement::ConstantDefinition { name, value },
                    Statement::Print(Expression::SystemConstant { name: reference }),
                ] if name == "Local" && value == "0x2" && reference == "XBSysLinux"
            )
    ));
}

#[test]
fn rejects_constant_definition_when_value_is_not_integer_literal() {
    for src in [
        "$$Value = 1.5\n",
        "$$Value = \"text\"\n",
        "$$Value = $$Other\n",
    ] {
        let result = parse_program(src);
        assert!(matches!(
            result,
            Err(ParseError::Expected {
                expected: "integer literal",
                ..
            })
        ));
    }
}

#[test]
fn rejects_bare_system_constant_statement() {
    let result = parse_program("$$XBSysLinux\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "statement",
            ..
        })
    ));
}

#[test]
fn rejects_system_variable_expression() {
    let result = parse_program("PRINT ##XBSystem\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "expression",
            ..
        })
    ));
}
