use crate::semantics::{
    Analyzer, CheckedExpr, CheckedExprKind, CheckedItem, SemanticError, ValueType,
};
use xb_frontend::parse_program;

#[test]
fn resolves_dimmed_symbol_when_printed() {
    let program = parse_program("DIM name$\nPRINT name$\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    assert!(matches!(
        &checked.items[1],
        CheckedItem::Print { items, .. } if matches!(items.as_slice(), [CheckedExpr { value_type: ValueType::String, .. }])
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
fn auto_declares_unknown_symbol_on_assignment() {
    let program = parse_program("name$ = \"hello\"\n").unwrap();
    let result = Analyzer::analyze(&program);
    // XBasic auto-declares variables on first use; string suffix makes it a string
    assert!(result.is_ok());
}

#[test]
fn accepts_assignment_type_coercion() {
    // Legacy compatibility: XBasic allows implicit type coercion
    let program = parse_program("DIM name$\nname$ = 42\n").unwrap();
    let result = Analyzer::analyze(&program);
    assert!(result.is_ok());
}

#[test]
fn allows_duplicate_symbols_in_scope() {
    // Legacy compatibility: XBasic allows re-declaration of variables
    let program = parse_program("DIM name$\nDIM name$\n").unwrap();
    let result = Analyzer::analyze(&program);
    assert!(result.is_ok());
}
#[test]
fn auto_declares_unknown_symbol_in_print() {
    let program = parse_program("PRINT missing\n").unwrap();
    let result = Analyzer::analyze(&program);
    // XBasic auto-declares variables on first use as integers
    assert!(result.is_ok());
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
            CheckedItem::Dim { .. },
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
    let body = match &checked.items[1] {
        CheckedItem::Function { body, .. } => body,
        _ => panic!("expected function"),
    };
    assert!(matches!(
        &body[0],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::Constant { name, value }, value_type: ValueType::Integer } if name == "Answer" && value == "42")
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
        &checked.items[2],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::Constant { .. }, .. })
    ));
    assert!(matches!(
        &checked.items[3],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::Symbol(_), .. })
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
fn auto_declares_unknown_constant_reference() {
    // Given
    let program = parse_program("PRINT $$Missing\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then: XBasic auto-declares unknown constants as 0
    assert!(result.is_ok());
}

#[test]
fn auto_declares_forward_constant_reference_at_top_level() {
    // Given
    let program = parse_program("PRINT $$Later\n$$Later = 1\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then: forward reference auto-declares as 0, then gets redefined
    assert!(result.is_ok());
}

#[test]
fn auto_declares_later_constant_reference_from_earlier_function() {
    // Given
    let program =
        parse_program("FUNCTION Main\nPRINT $$Later\nEND FUNCTION\n$$Later = 1\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then: forward reference auto-declares as 0
    assert!(result.is_ok());
}

#[test]
fn accepts_constant_definition_nested_in_function() {
    let program = parse_program("FUNCTION Main\n$$Local = 1\nEND FUNCTION\n").unwrap();
    let result = Analyzer::analyze(&program);
    assert!(result.is_ok());
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
fn accepts_if_with_float_condition() {
    let prog =
        parse_program("FUNCTION Main\nIF 1.5 THEN\nPRINT 1\nEND IF\nEND FUNCTION\n").unwrap();
    // XBasic allows any type in boolean context
    assert!(Analyzer::analyze(&prog).is_ok());
}
