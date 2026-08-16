use crate::{Analyzer, CheckedExpr, CheckedExprKind, CheckedItem, SemanticError, ValueType};
use xb_frontend::parse_program;

#[test]
fn declares_shared_variable_on_first_assignment_and_resolves_reference() {
    // Given
    let program =
        parse_program("FUNCTION Main\n##XBSystem = 1\nPRINT ##XBSystem\nEND FUNCTION\n").unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    let body = match &checked.items[0] {
        CheckedItem::Function { body, .. } => body,
        _ => panic!("expected function"),
    };
    assert!(matches!(
        &body[0],
        CheckedItem::SharedAssignment { target, value: CheckedExpr { value_type: ValueType::Integer, .. } }
            if target.name == "XBSystem"
    ));
    assert!(matches!(
        &body[1],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::SharedVariable(reference), value_type: ValueType::Integer } if reference.name == "XBSystem")
    ));
}

#[test]
fn keeps_shared_constant_and_variable_namespaces_separate() {
    // Given
    let source = "$$Value = 1\nDIM Value\nFUNCTION Init\n##Value = 2\nEND FUNCTION\nPRINT $$Value\nPRINT Value\nPRINT ##Value\n";
    let program = parse_program(source).unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    assert!(matches!(
        &checked.items[3],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::Constant { .. }, .. })
    ));
    assert!(matches!(
        &checked.items[4],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::Symbol(_), .. })
    ));
    assert!(matches!(
        &checked.items[5],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::SharedVariable(_), .. })
    ));
}

#[test]
fn rejects_reference_to_unassigned_shared_variable() {
    // Given
    let program = parse_program("PRINT ##Missing\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::UnknownSharedVariable { ref name }) if name == "Missing"
    ));
}

#[test]
fn accepts_shared_assignment_inside_function_body() {
    // Given
    let source = "$$XBSysLinux = 1\nFUNCTION Main\n##XBSystem = $$XBSysLinux\nEND FUNCTION\n";
    let program = parse_program(source).unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    assert!(matches!(
        &checked.items[1],
        CheckedItem::Function { body, .. } if matches!(
            &body[..],
            [CheckedItem::SharedAssignment { target, value: CheckedExpr { kind: CheckedExprKind::Constant { .. }, .. } }]
                if target.name == "XBSystem"
        )
    ));
}

#[test]
fn accepts_top_level_shared_assignment() {
    // Given
    let program = parse_program("##XBSystem = 1\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(result.is_ok());
}

#[test]
fn resolves_shared_variable_assigned_inside_an_earlier_function() {
    // Given
    let program =
        parse_program("FUNCTION Init\n##XBSystem = 1\nEND FUNCTION\nPRINT ##XBSystem\n").unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    assert!(matches!(
        &checked.items[1],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::SharedVariable(reference), .. } if reference.name == "XBSystem")
    ));
}

#[test]
fn rejects_shared_assignment_that_conflicts_with_the_declared_type() {
    // Given
    let program =
        parse_program("FUNCTION Main\n##XBDir$ = \"/usr/xb\"\n##XBDir$ = 1\nEND FUNCTION\n")
            .unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::TypeMismatch {
            ref name,
            expected: ValueType::String,
            actual: ValueType::Integer,
        }) if name == "XBDir"
    ));
}

#[test]
fn rejects_shared_reference_whose_suffix_conflicts_with_the_declared_type() {
    // Given
    let program =
        parse_program("FUNCTION Init\n##XBSystem = 1\nEND FUNCTION\nPRINT ##XBSystem$\n").unwrap();

    // When
    let result = Analyzer::analyze(&program);

    // Then
    assert!(matches!(
        result,
        Err(SemanticError::TypeMismatch {
            ref name,
            expected: ValueType::String,
            actual: ValueType::Integer,
        }) if name == "XBSystem"
    ));
}

#[test]
fn preserves_string_shared_variable_type_from_suffix() {
    // Given
    let program =
        parse_program("FUNCTION Init\n##XBDir$ = \"/usr/xb\"\nEND FUNCTION\nPRINT ##XBDir$\n")
            .unwrap();

    // When
    let checked = Analyzer::analyze(&program).unwrap();

    // Then
    assert!(matches!(
        &checked.items[1],
        CheckedItem::Print { items, .. }
            if items.len() == 1 && matches!(&items[0], CheckedExpr { kind: CheckedExprKind::SharedVariable(reference), value_type: ValueType::String } if reference.name == "XBDir")
    ));
}
