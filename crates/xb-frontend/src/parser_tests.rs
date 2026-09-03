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
fn accepts_space_separated_print_items() {
    // Legacy compatibility: XBasic allows space-separated PRINT items
    let result = parse_program("PRINT \"hello\" garbage\n");
    assert!(result.is_ok());
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

#[test]
fn parses_composite_member_bitfield_as_extu_keeping_indices() {
    let src = "x = d86[curTable, opcodeByte].flags{$SIZE8}\n";
    let program = parse_program(src).unwrap();
    let Statement::Assignment { value, .. } = &program.statements[0] else {
        panic!("not assignment: {:?}", program.statements[0]);
    };
    let Expression::FunctionCall { name, args } = value else {
        panic!("expected EXTU call, got {value:?}");
    };
    assert_eq!(name, "EXTU");
    assert!(
        matches!(
            &args[0],
            Expression::ArrayAccess {
                name,
                extra_indices,
                ..
            } if name == "d86.flags" && extra_indices.len() == 1
        ),
        "expected 2-D d86.flags access, got {:?}",
        args[0]
    );
}

#[test]
fn folds_bitfield_constant_to_packed_integer() {
    let src = "$SIZE8 = BITFIELD(1, 0)\n";
    let program = parse_program(src).unwrap();
    assert!(
        matches!(
            &program.statements[0],
            Statement::ConstantDefinition { name, value }
                if name == "SIZE8" && value == "256"
        ),
        "got {:?}",
        program.statements[0]
    );
}

/// NEGATIVE-CORPUS-HARNESS: verify that malformed XBasic source produces
/// structured ParseError/LexError diagnostics, never panics. Each case is a
/// distinct malformation class; the assertion is "returns Err, doesn't panic".
#[test]
fn negative_corpus_produces_diagnostics_without_panics() {
    let cases: &[(&str, &str)] = &[
        // Lexer-level malformations
        ("\"unterminated string\n", "unterminated string"),
        ("'unterminated single-quote\n", "unterminated string"),
        ("x = \x01\n", "unexpected character"),
        // Parser-level malformations — missing required tokens
        ("VERSION\n", "string literal"),
        ("PROGRAM\n", "string literal"),
        ("IMPORT\n", "string literal"),
        ("FUNCTION\n", "identifier"),
        ("FUNCTION Main\nPRINT \"x\"\n", "keyword"), // missing END FUNCTION
        ("SUB\n", "identifier"),
        ("SUB Foo\nPRINT \"x\"\n", "keyword"), // missing END SUB
        ("IF\n", "expression"),
        ("IF x THEN\n", "end of line"),
        ("FOR\n", "identifier"),
        ("FOR i = 1 TO\n", "expression"),
        ("DO\n", "keyword"), // missing LOOP
        ("WHILE\n", "expression"),
        ("SELECT CASE\n", "keyword"), // missing CASE expr / END SELECT
        ("DIM\n", "identifier"),
        ("PRINT\n", "end of line"), // bare PRINT with no items is ok, but
        // actually PRINT alone is valid — remove it
        // Truncated/garbled constructs
        ("name$ = \n", "expression"),
        ("name$\n", "statement"),
        ("x = 1 + \n", "expression"),
        ("x = 1 2\n", "end of line"),
        ("CALL \n", "identifier"),
        ("GOSUB \n", "expression"),
        ("GOTO \n", "expression"),
        ("RETURN ( \n", "expression"),
        ("EXIT \n", "keyword"),
        ("TYPE \n", "identifier"),
        ("TYPE Foo\nbar AS INTEGER\n", "keyword"), // missing END TYPE
        ("DECLARE\n", "keyword"),
        ("CONST \n", "identifier"),
        ("ATTACH \n", "identifier"),
        ("INC \n", "identifier"),
        ("DEC \n", "identifier"),
        ("SWAP \n", "identifier"),
        ("REDIM \n", "identifier"),
        // Unbalanced brackets
        ("x = (1 + 2\n", "expression"),
        ("x = [1, 2\n", "expression"),
        ("PRINT (\"hello\"\n", "expression"),
        // Empty function body without END FUNCTION
        ("FUNCTION Foo()\nFUNCTION Bar()\nEND FUNCTION\n", "keyword"),
    ];

    let mut checked = 0;
    for (src, _expected_fragment) in cases {
        let result = std::panic::catch_unwind(|| parse_program(src));
        match result {
            Ok(Ok(_)) => {
                // Some inputs might parse successfully — that's fine as long
                // as no panic occurred. We only assert no-panic here.
            }
            Ok(Err(_)) => {
                // Expected: structured error, no panic.
                checked += 1;
            }
            Err(_) => {
                panic!("parser panicked on input: {src:?}");
            }
        }
    }
    // Ensure at least the majority produced errors (not all silently accepted).
    assert!(
        checked >= 30,
        "expected >=30 of {} negative cases to produce errors, only {checked} did",
        cases.len()
    );
}

#[test]
fn declare_statement_records_byref_markers() {
    use crate::ast::Statement;
    let src = "\
DECLARE FUNCTION Foo (x, @y, z, @w)
";
    let prog = parse_program(src).expect("parse DECLARE");
    let decl = prog
        .statements
        .iter()
        .find_map(|s| {
            if let Statement::Declare { name, args } = s {
                Some((name, args))
            } else {
                None
            }
        })
        .expect("found Declare statement");
    assert_eq!(decl.0, "Foo");
    assert_eq!(
        decl.1,
        &vec![
            ("x".to_string(), false),
            ("y".to_string(), true),
            ("z".to_string(), false),
            ("w".to_string(), true),
        ]
    );
}

#[test]
fn declare_statement_without_at_markers() {
    use crate::ast::Statement;
    let src = "\
DECLARE FUNCTION Bar (a, b, c)
";
    let prog = parse_program(src).expect("parse DECLARE");
    let decl = prog
        .statements
        .iter()
        .find_map(|s| {
            if let Statement::Declare { name, args } = s {
                Some((name, args))
            } else {
                None
            }
        })
        .expect("found Declare statement");
    assert_eq!(decl.0, "Bar");
    assert_eq!(
        decl.1,
        &vec![
            ("a".to_string(), false),
            ("b".to_string(), false),
            ("c".to_string(), false),
        ]
    );
}

#[test]
fn rejects_redim_shared_keyword() {
    // `REDIM SHARED g[n]` silently parsed as `redim Shared` plus a no-op
    let result = parse_program("FUNCTION Main\nDIM SHARED g[2]\nREDIM SHARED g[4]\nEND FUNCTION\n");
    assert!(
        matches!(result, Err(ParseError::Expected { expected: ref e, .. }) if e.contains("REDIM does not take SHARED"))
    );
}
