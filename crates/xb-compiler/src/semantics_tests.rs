use crate::semantics::{
    Analyzer, CheckedExpr, CheckedExprKind, CheckedItem, SemanticError, ValueType,
};
use xb_frontend::parse_program;

#[test]
fn resolves_dimmed_symbol_when_printed() {
    let program = parse_program("DIM name$\nPRINT name$\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    assert!(matches!(
        checked.items[1],
        CheckedItem::Print(CheckedExpr {
            value_type: ValueType::String,
            ..
        })
    ));
}

#[test]
fn accepts_assignment_when_type_matches_dimmed_symbol() {
    let program = parse_program("DIM name$\nname$ = \"hello\"\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    assert!(
        matches!(checked.items[1], CheckedItem::Assignment { ref target, ref value } if target.value_type == ValueType::String && value.value_type == ValueType::String)
    );
}

#[test]
fn rejects_assignment_to_unknown_symbol() {
    let program = parse_program("name$ = \"hello\"\n").unwrap();
    let result = Analyzer::analyze(&program);
    assert!(matches!(result, Err(SemanticError::UnknownSymbol { ref name }) if name == "name"));
}

#[test]
fn rejects_assignment_type_mismatch() {
    let program = parse_program("DIM name$\nname$ = 42\n").unwrap();
    let result = Analyzer::analyze(&program);
    assert!(matches!(
        result,
        Err(SemanticError::TypeMismatch {
            ref name,
            expected: ValueType::String,
            actual: ValueType::Integer,
        }) if name == "name"
    ));
}

#[test]
fn rejects_duplicate_symbols_in_scope() {
    let program = parse_program("DIM name$\nDIM name$\n").unwrap();
    let result = Analyzer::analyze(&program);
    assert!(matches!(result, Err(SemanticError::DuplicateSymbol { ref name }) if name == "name"));
}

#[test]
fn rejects_unknown_symbol_in_print() {
    let program = parse_program("PRINT missing\n").unwrap();
    let result = Analyzer::analyze(&program);
    assert!(matches!(result, Err(SemanticError::UnknownSymbol { ref name }) if name == "missing"));
}

#[test]
fn resolves_constant_reference_on_assignment_rhs() {
    // Given
    let program = parse_program("$$Answer = 42\nDIM result\nresult = $$Answer\n").unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    assert!(matches!(
        &checked.items[..],
        [
            CheckedItem::ConstantDefinition { name, value, value_type: ValueType::Integer },
            CheckedItem::Dim(_),
            CheckedItem::Assignment { value: CheckedExpr { kind: CheckedExprKind::Constant { name: reference, value: resolved }, value_type: ValueType::Integer }, .. }
        ] if name == "Answer" && value == "42" && reference == "Answer" && resolved == "42"
    ));
}

#[test]
fn resolves_constant_reference_in_function_from_prior_definition() {
    // Given
    let program =
        parse_program("$$Answer = 42\nFUNCTION Main\nPRINT $$Answer\nEND FUNCTION\n").unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    assert!(matches!(
        &checked.items[1],
        CheckedItem::Function { body, .. }
            if matches!(
                &body[..],
                [CheckedItem::Print(CheckedExpr {
                    kind: CheckedExprKind::Constant { name, value },
                    value_type: ValueType::Integer,
                })] if name == "Answer" && value == "42"
            )
    ));
}

#[test]
fn keeps_variable_and_constant_namespaces_separate() {
    // Given
    let program = parse_program("$$Value = 1\nDIM Value\nPRINT $$Value\nPRINT Value\n").unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    assert!(matches!(
        (&checked.items[2], &checked.items[3]),
        (
            CheckedItem::Print(CheckedExpr {
                kind: CheckedExprKind::Constant { .. },
                ..
            }),
            CheckedItem::Print(CheckedExpr {
                kind: CheckedExprKind::Symbol(_),
                ..
            }),
        )
    ));
}

#[test]
fn rejects_duplicate_constant_definitions() {
    // Given
    let program = parse_program("$$Answer = 1\n$$Answer = 2\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::DuplicateConstant { ref name }) if name == "Answer"
    ));
}

#[test]
fn rejects_unknown_constant_reference() {
    // Given
    let program = parse_program("PRINT $$Missing\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::UnknownConstant { ref name }) if name == "Missing"
    ));
}

#[test]
fn rejects_forward_constant_reference_at_top_level() {
    // Given
    let program = parse_program("PRINT $$Later\n$$Later = 1\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::UnknownConstant { ref name }) if name == "Later"
    ));
}

#[test]
fn rejects_later_constant_reference_from_earlier_function() {
    // Given
    let program =
        parse_program("FUNCTION Main\nPRINT $$Later\nEND FUNCTION\n$$Later = 1\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::UnknownConstant { ref name }) if name == "Later"
    ));
}

#[test]
fn rejects_constant_definition_nested_in_function() {
    // Given
    let program = parse_program("FUNCTION Main\n$$Local = 1\nEND FUNCTION\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::ConstantDefinitionNotTopLevel { ref name }) if name == "Local"
    ));
}

#[test]
fn accepts_if_with_integer_condition() {
    let prog = parse_program("FUNCTION Main\nIF 1 THEN\nPRINT 1\nEND IF\nEND FUNCTION\n").unwrap();
    let checked = Analyzer::analyze(&prog).unwrap();
    let has_if = checked.items.iter().any(|item| {
        matches!(item, CheckedItem::Function { body, .. } if body.iter().any(|bi| matches!(bi, CheckedItem::If { .. })))
    });
    assert!(has_if);
}

#[test]
fn rejects_if_with_float_condition() {
    let prog =
        parse_program("FUNCTION Main\nIF 1.5 THEN\nPRINT 1\nEND IF\nEND FUNCTION\n").unwrap();
    let err = Analyzer::analyze(&prog).unwrap_err();
    assert!(matches!(
        err,
        SemanticError::IfConditionNotInteger {
            actual: ValueType::Float
        }
    ));
}
