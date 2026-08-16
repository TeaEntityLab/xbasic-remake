use crate::{parse_program, ComparisonOp, Expression, ParseError, Statement, TypeSuffix};

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
fn rejects_malformed_statements() {
    for (src, expected) in [
        ("name$ = \"hello\" garbage\n", "end of line"),
        ("name$ =\n", "expression"),
        ("name$\n", "statement"),
    ] {
        assert!(
            matches!(parse_program(src), Err(ParseError::Expected { expected: e, .. }) if e == expected)
        );
    }
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
fn dim_multi_declaration_succeeds() {
    let result = parse_program("FUNCTION Main\nDIM a, b, c\nEND FUNCTION\n");
    assert!(result.is_ok());
}

#[test]
fn accepts_print_without_expression() {
    let result = parse_program("PRINT\n");
    assert!(result.is_ok());
    let prog = result.unwrap();
    assert_eq!(prog.statements.len(), 1);
    assert!(matches!(
        prog.statements[0],
        Statement::Print {
            ref items,
            ref separators,
        } if items.is_empty() && separators.is_empty()
    ));
}

#[test]
fn accepts_return_type_in_function_header() {
    let result = parse_program("FUNCTION DOUBLE Main()\nEND FUNCTION\n");
    assert!(result.is_ok());
}

#[test]
fn accepts_trailing_name_after_end_function() {
    let result = parse_program("FUNCTION Main\nEND FUNCTION Main\n");
    assert!(result.is_ok());
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
    let function = match &program.statements[1] {
        Statement::Function(f) => f,
        _ => panic!("expected function"),
    };
    assert!(matches!(
        function.body[0],
        Statement::ConstantDefinition { ref name, ref value }
            if name == "Local" && value == "0x2"
    ));
    assert!(matches!(
        &function.body[1],
        Statement::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], Expression::SystemConstant { name: ref reference } if reference == "XBSysLinux")
    ));
}

#[test]
fn accepts_constant_definition_with_any_value() {
    for src in [
        "$$Value = 1.5\n",
        "$$Value = \"text\"\n",
        "$$Value = $$Other\n",
        "$$Value = -1\n",
    ] {
        let result = parse_program(src);
        assert!(result.is_ok(), "failed to parse: {src}");
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
fn parses_shared_variable_assignment_and_reference() {
    // Given the historical xrun.x:79 form, assigned inside a function body.
    let src = "##XBSystem = $$XBSysLinux\nFUNCTION Main\n##XBSystem = 2\nPRINT ##XBSystem\nEND FUNCTION\n";

    // When
    let program = parse_program(src).unwrap();

    // Then
    assert!(matches!(
        program.statements[0],
        Statement::SharedAssignment {
            ref name,
            suffix: None,
            value: Expression::SystemConstant { name: ref source },
        } if name == "XBSystem" && source == "XBSysLinux"
    ));
    let function = match &program.statements[1] {
        Statement::Function(f) => f,
        _ => panic!("expected function"),
    };
    assert!(matches!(
        function.body[0],
        Statement::SharedAssignment { ref name, value: Expression::IntegerLiteral(ref value), .. }
            if name == "XBSystem" && value == "2"
    ));
    assert!(matches!(
        &function.body[1],
        Statement::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], Expression::SystemVariable { name: ref reference, suffix: None } if reference == "XBSystem")
    ));
}

#[test]
fn parses_suffixed_shared_variable_as_single_typed_name() {
    // Given the historical xutpde.x:62 string form.
    let program = parse_program("##XBDir$ = \"/usr/xb\"\n").unwrap();

    assert!(matches!(
        program.statements[0],
        Statement::SharedAssignment {
            ref name,
            suffix: Some(TypeSuffix::String),
            value: Expression::StringLiteral(_),
        } if name == "XBDir"
    ));
}

#[test]
fn rejects_bare_system_variable_statement() {
    let result = parse_program("##XBSystem\n");
    assert!(matches!(
        result,
        Err(ParseError::Expected {
            expected: "statement",
            ..
        })
    ));
}

#[test]
fn parses_if_then_end_if() {
    let prog = parse_program("IF 1 THEN\nPRINT 1\nEND IF\n").unwrap();
    let Statement::If { else_body, .. } = &prog.statements[0] else {
        panic!("not If")
    };
    assert!(else_body.is_none());
}

#[test]
fn parses_if_then_else_end_if() {
    let prog = parse_program("IF 1 THEN\nPRINT 1\nELSE\nPRINT 0\nEND IF\n").unwrap();
    assert!(
        matches!(&prog.statements[0], Statement::If { condition: Expression::IntegerLiteral(_), then_body, else_body: Some(_) } if then_body.len() == 1)
    );
}

#[test]
fn parses_comparison_expression() {
    let prog = parse_program("IF 1 = 1 THEN\nPRINT 1\nEND IF\n").unwrap();
    let Statement::If { condition, .. } = &prog.statements[0] else {
        panic!("not If")
    };
    assert!(matches!(
        condition,
        Expression::Comparison {
            op: ComparisonOp::Equal,
            ..
        }
    ));
}
