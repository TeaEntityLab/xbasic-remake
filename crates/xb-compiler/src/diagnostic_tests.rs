use xb_frontend::{LexError, ParseError};

use crate::{CompileError, SemanticError, ValueType};

fn unterminated_string() -> CompileError {
    CompileError::Parse(ParseError::Lex(LexError::UnterminatedString {
        line: 1,
        column: 1,
    }))
}

fn unexpected_char() -> CompileError {
    CompileError::Parse(ParseError::Lex(LexError::UnexpectedChar {
        ch: '@',
        line: 1,
        column: 1,
    }))
}

fn expected() -> CompileError {
    CompileError::Parse(ParseError::Expected {
        expected: "PRINT",
        line: 1,
        column: 1,
    })
}

fn duplicate_symbol() -> CompileError {
    CompileError::Semantic(SemanticError::DuplicateSymbol { name: "x".into() })
}

fn unknown_symbol() -> CompileError {
    CompileError::Semantic(SemanticError::UnknownSymbol { name: "x".into() })
}

fn type_mismatch() -> CompileError {
    CompileError::Semantic(SemanticError::TypeMismatch {
        name: "x".into(),
        expected: ValueType::Integer,
        actual: ValueType::String,
    })
}

fn duplicate_constant() -> CompileError {
    CompileError::Semantic(SemanticError::DuplicateConstant {
        name: "Answer".into(),
    })
}

fn unknown_constant() -> CompileError {
    CompileError::Semantic(SemanticError::UnknownConstant {
        name: "Answer".into(),
    })
}

fn constant_definition_not_top_level() -> CompileError {
    CompileError::Semantic(SemanticError::ConstantDefinitionNotTopLevel {
        name: "Answer".into(),
    })
}

fn unknown_shared_variable() -> CompileError {
    CompileError::Semantic(SemanticError::UnknownSharedVariable {
        name: "XBSystem".into(),
    })
}

fn shared_assignment_not_in_function() -> CompileError {
    CompileError::Semantic(SemanticError::SharedAssignmentNotInFunction {
        name: "XBSystem".into(),
    })
}

fn if_condition_not_integer() -> CompileError {
    CompileError::Semantic(SemanticError::IfConditionNotInteger {
        actual: ValueType::Float,
    })
}

fn comparison_type_mismatch() -> CompileError {
    CompileError::Semantic(SemanticError::ComparisonTypeMismatch {
        left: ValueType::Integer,
        right: ValueType::Float,
    })
}

fn unknown_function() -> CompileError {
    CompileError::Semantic(SemanticError::UnknownFunction { name: "f".into() })
}

fn function_arg_count() -> CompileError {
    CompileError::Semantic(SemanticError::FunctionArgCount {
        name: "f".into(),
        expected: 1,
        actual: 0,
    })
}

fn function_arg_type() -> CompileError {
    CompileError::Semantic(SemanticError::FunctionArgType {
        name: "f".into(),
        index: 0,
        expected: ValueType::Integer,
        actual: ValueType::Float,
    })
}

fn return_outside_function() -> CompileError {
    CompileError::Semantic(SemanticError::ReturnOutsideFunction)
}

fn return_type_mismatch() -> CompileError {
    CompileError::Semantic(SemanticError::ReturnTypeMismatch {
        expected: ValueType::Integer,
        actual: ValueType::Float,
    })
}

fn arithmetic_string_operand() -> CompileError {
    CompileError::Semantic(SemanticError::ArithmeticStringOperand)
}

#[test]
fn simple_codes_map_correctly() {
    assert_eq!(unterminated_string().diagnostic_code(), "XB-L001");
    assert_eq!(unexpected_char().diagnostic_code(), "XB-L002");
    assert_eq!(expected().diagnostic_code(), "XB-P001");
    assert_eq!(duplicate_symbol().diagnostic_code(), "XB-S001");
    assert_eq!(unknown_symbol().diagnostic_code(), "XB-S002");
    assert_eq!(type_mismatch().diagnostic_code(), "XB-S003");
    assert_eq!(duplicate_constant().diagnostic_code(), "XB-S004");
    assert_eq!(unknown_constant().diagnostic_code(), "XB-S005");
    assert_eq!(
        constant_definition_not_top_level().diagnostic_code(),
        "XB-S006"
    );
    assert_eq!(unknown_shared_variable().diagnostic_code(), "XB-S007");
    assert_eq!(
        shared_assignment_not_in_function().diagnostic_code(),
        "XB-S008"
    );
    assert_eq!(if_condition_not_integer().diagnostic_code(), "XB-S009");
    assert_eq!(comparison_type_mismatch().diagnostic_code(), "XB-S010");
    assert_eq!(unknown_function().diagnostic_code(), "XB-S011");
    assert_eq!(function_arg_count().diagnostic_code(), "XB-S012");
    assert_eq!(function_arg_type().diagnostic_code(), "XB-S013");
    assert_eq!(return_outside_function().diagnostic_code(), "XB-S014");
    assert_eq!(return_type_mismatch().diagnostic_code(), "XB-S015");
    assert_eq!(arithmetic_string_operand().diagnostic_code(), "XB-S016");
    assert_eq!(CompileError::LlvmDisabled.diagnostic_code(), "XB-B001");
}

#[test]
fn parse_lex_wrapper_delegates_to_lex_code() {
    assert_eq!(unterminated_string().diagnostic_code(), "XB-L001");
    assert_eq!(unexpected_char().diagnostic_code(), "XB-L002");
}

#[test]
fn all_diagnostic_codes_are_unique() {
    let mut codes = vec![
        unterminated_string().diagnostic_code(),
        unexpected_char().diagnostic_code(),
        expected().diagnostic_code(),
        duplicate_symbol().diagnostic_code(),
        unknown_symbol().diagnostic_code(),
        type_mismatch().diagnostic_code(),
        duplicate_constant().diagnostic_code(),
        unknown_constant().diagnostic_code(),
        constant_definition_not_top_level().diagnostic_code(),
        unknown_shared_variable().diagnostic_code(),
        shared_assignment_not_in_function().diagnostic_code(),
        if_condition_not_integer().diagnostic_code(),
        comparison_type_mismatch().diagnostic_code(),
        unknown_function().diagnostic_code(),
        function_arg_count().diagnostic_code(),
        function_arg_type().diagnostic_code(),
        return_outside_function().diagnostic_code(),
        return_type_mismatch().diagnostic_code(),
        arithmetic_string_operand().diagnostic_code(),
        CompileError::LlvmDisabled.diagnostic_code(),
    ];
    codes.sort_unstable();
    codes.dedup();
    assert_eq!(codes.len(), 20);
}

#[test]
fn source_codes_are_unique_and_complete() {
    let mut codes = crate::SOURCE_DIAGNOSTIC_CODES.to_vec();
    codes.sort_unstable();
    codes.dedup();
    assert_eq!(codes.len(), 19);
    for code in codes {
        assert!(code.starts_with("XB-"));
    }
}

#[test]
fn every_leaf_code_is_member_of_source_list() {
    for code in [
        unterminated_string().diagnostic_code(),
        unexpected_char().diagnostic_code(),
        expected().diagnostic_code(),
        duplicate_symbol().diagnostic_code(),
        unknown_symbol().diagnostic_code(),
        type_mismatch().diagnostic_code(),
        duplicate_constant().diagnostic_code(),
        unknown_constant().diagnostic_code(),
        constant_definition_not_top_level().diagnostic_code(),
        unknown_shared_variable().diagnostic_code(),
        shared_assignment_not_in_function().diagnostic_code(),
        if_condition_not_integer().diagnostic_code(),
        comparison_type_mismatch().diagnostic_code(),
        unknown_function().diagnostic_code(),
        function_arg_count().diagnostic_code(),
        function_arg_type().diagnostic_code(),
        return_outside_function().diagnostic_code(),
        return_type_mismatch().diagnostic_code(),
    ] {
        assert!(
            crate::SOURCE_DIAGNOSTIC_CODES.contains(&code),
            "{code} missing from SOURCE_DIAGNOSTIC_CODES"
        );
    }
}

#[test]
fn backend_code_is_member_of_backend_list_only() {
    let code = CompileError::LlvmDisabled.diagnostic_code();
    assert!(crate::BACKEND_DIAGNOSTIC_CODES.contains(&code));
    assert!(!crate::SOURCE_DIAGNOSTIC_CODES.contains(&code));
}
