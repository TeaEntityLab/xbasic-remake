//! Stable diagnostic codes for every leaf of [`CompileError`].
//!
//! The corpus harness consumes [`SOURCE_DIAGNOSTIC_CODES`],
//! [`BACKEND_DIAGNOSTIC_CODES`], and [`CompileError::diagnostic_code`].

use xb_frontend::{LexError, ParseError};

use crate::{CompileError, SemanticError};

/// Stable codes for errors originating in the frontend (lexer, parser, semantics).
pub const SOURCE_DIAGNOSTIC_CODES: &[&str] = &[
    "XB-L001", "XB-L002", "XB-P001", "XB-S001", "XB-S002", "XB-S003", "XB-S004", "XB-S005",
    "XB-S006", "XB-S007", "XB-S008", "XB-S009",
];

/// Stable codes for errors originating in the backend (codegen).
pub const BACKEND_DIAGNOSTIC_CODES: &[&str] = &["XB-B001"];

impl CompileError {
    /// Returns the stable diagnostic code for this error leaf.
    pub const fn diagnostic_code(&self) -> &'static str {
        match self {
            CompileError::Parse(parse_error) => match parse_error {
                ParseError::Lex(lex_error) => match lex_error {
                    LexError::UnterminatedString { .. } => "XB-L001",
                    LexError::UnexpectedChar { .. } => "XB-L002",
                },
                ParseError::Expected { .. } => "XB-P001",
            },
            CompileError::Semantic(semantic_error) => match semantic_error {
                SemanticError::DuplicateSymbol { .. } => "XB-S001",
                SemanticError::UnknownSymbol { .. } => "XB-S002",
                SemanticError::TypeMismatch { .. } => "XB-S003",
                SemanticError::DuplicateConstant { .. } => "XB-S004",
                SemanticError::UnknownConstant { .. } => "XB-S005",
                SemanticError::ConstantDefinitionNotTopLevel { .. } => "XB-S006",
                SemanticError::UnknownSharedVariable { .. } => "XB-S007",
                SemanticError::IfConditionNotInteger { .. } => "XB-S009",
                SemanticError::SharedAssignmentNotInFunction { .. } => "XB-S008",
            },
            CompileError::LlvmDisabled => "XB-B001",
        }
    }
}

#[cfg(test)]
mod tests {
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
        CompileError::Semantic(SemanticError::DuplicateSymbol {
            name: "x".to_string(),
        })
    }

    fn unknown_symbol() -> CompileError {
        CompileError::Semantic(SemanticError::UnknownSymbol {
            name: "x".to_string(),
        })
    }

    fn type_mismatch() -> CompileError {
        CompileError::Semantic(SemanticError::TypeMismatch {
            name: "x".to_string(),
            expected: ValueType::Integer,
            actual: ValueType::String,
        })
    }

    fn duplicate_constant() -> CompileError {
        CompileError::Semantic(SemanticError::DuplicateConstant {
            name: "Answer".to_string(),
        })
    }

    fn unknown_constant() -> CompileError {
        CompileError::Semantic(SemanticError::UnknownConstant {
            name: "Answer".to_string(),
        })
    }

    fn constant_definition_not_top_level() -> CompileError {
        CompileError::Semantic(SemanticError::ConstantDefinitionNotTopLevel {
            name: "Answer".to_string(),
        })
    }

    fn unknown_shared_variable() -> CompileError {
        CompileError::Semantic(SemanticError::UnknownSharedVariable {
            name: "XBSystem".to_string(),
        })
    }

    fn shared_assignment_not_in_function() -> CompileError {
        CompileError::Semantic(SemanticError::SharedAssignmentNotInFunction {
            name: "XBSystem".to_string(),
        })
    }
    fn if_condition_not_integer() -> CompileError {
        CompileError::Semantic(SemanticError::IfConditionNotInteger {
            actual: ValueType::Float,
        })
    }

    #[test]
    fn unterminated_string_maps_to_xb_l001() {
        assert_eq!(unterminated_string().diagnostic_code(), "XB-L001");
    }

    #[test]
    fn unexpected_char_maps_to_xb_l002() {
        assert_eq!(unexpected_char().diagnostic_code(), "XB-L002");
    }

    #[test]
    fn expected_maps_to_xb_p001() {
        assert_eq!(expected().diagnostic_code(), "XB-P001");
    }

    #[test]
    fn duplicate_symbol_maps_to_xb_s001() {
        assert_eq!(duplicate_symbol().diagnostic_code(), "XB-S001");
    }

    #[test]
    fn unknown_symbol_maps_to_xb_s002() {
        assert_eq!(unknown_symbol().diagnostic_code(), "XB-S002");
    }

    #[test]
    fn type_mismatch_maps_to_xb_s003() {
        assert_eq!(type_mismatch().diagnostic_code(), "XB-S003");
    }

    #[test]
    fn duplicate_constant_maps_to_xb_s004() {
        assert_eq!(duplicate_constant().diagnostic_code(), "XB-S004");
    }

    #[test]
    fn unknown_constant_maps_to_xb_s005() {
        assert_eq!(unknown_constant().diagnostic_code(), "XB-S005");
    }

    #[test]
    fn nested_constant_definition_maps_to_xb_s006() {
        assert_eq!(
            constant_definition_not_top_level().diagnostic_code(),
            "XB-S006"
        );
    }

    #[test]
    fn unknown_shared_variable_maps_to_xb_s007() {
        assert_eq!(unknown_shared_variable().diagnostic_code(), "XB-S007");
    }

    #[test]
    fn top_level_shared_assignment_maps_to_xb_s008() {
        assert_eq!(
            shared_assignment_not_in_function().diagnostic_code(),
            "XB-S008"
        );
    }

    #[test]
    fn if_condition_not_integer_maps_to_xb_s009() {
        assert_eq!(if_condition_not_integer().diagnostic_code(), "XB-S009");
    }

    #[test]
    fn llvm_disabled_maps_to_xb_b001() {
        assert_eq!(CompileError::LlvmDisabled.diagnostic_code(), "XB-B001");
    }

    #[test]
    fn parse_lex_wrapper_delegates_to_lex_code() {
        // ParseError::Lex must delegate to the wrapped LexError's code.
        assert_eq!(unterminated_string().diagnostic_code(), "XB-L001");
        assert_eq!(unexpected_char().diagnostic_code(), "XB-L002");
    }

    #[test]
    fn compile_error_wrappers_delegate_to_inner_code() {
        // CompileError::Parse and CompileError::Semantic must delegate inward.
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
            CompileError::LlvmDisabled.diagnostic_code(),
        ];
        codes.sort_unstable();
        codes.dedup();
        assert_eq!(codes.len(), 13);
    }

    #[test]
    fn source_codes_are_unique_and_complete() {
        let mut codes = crate::SOURCE_DIAGNOSTIC_CODES.to_vec();
        codes.sort_unstable();
        codes.dedup();
        assert_eq!(codes.len(), 12);
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
}
