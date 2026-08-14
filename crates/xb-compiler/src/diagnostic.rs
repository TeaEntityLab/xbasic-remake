//! Stable diagnostic codes for every leaf of [`CompileError`].
//!
//! The corpus harness consumes [`SOURCE_DIAGNOSTIC_CODES`],
//! [`BACKEND_DIAGNOSTIC_CODES`], and [`CompileError::diagnostic_code`].

use xb_frontend::{LexError, ParseError};

use crate::{CompileError, SemanticError};

/// Stable codes for errors originating in the frontend (lexer, parser, semantics).
pub const SOURCE_DIAGNOSTIC_CODES: &[&str] = &[
    "XB-L001", "XB-L002", "XB-P001", "XB-S001", "XB-S002", "XB-S003", "XB-S004", "XB-S005",
    "XB-S006", "XB-S007", "XB-S008", "XB-S009", "XB-S010", "XB-S011", "XB-S012", "XB-S013",
    "XB-S014", "XB-S015", "XB-S016",
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
                SemanticError::SharedAssignmentNotInFunction { .. } => "XB-S008",
                SemanticError::IfConditionNotInteger { .. } => "XB-S009",
                SemanticError::ComparisonTypeMismatch { .. } => "XB-S010",
                SemanticError::UnknownFunction { .. } => "XB-S011",
                SemanticError::FunctionArgCount { .. } => "XB-S012",
                SemanticError::FunctionArgType { .. } => "XB-S013",
                SemanticError::ReturnOutsideFunction => "XB-S014",
                SemanticError::ReturnTypeMismatch { .. } => "XB-S015",
                SemanticError::ArithmeticStringOperand => "XB-S016",
            },
            CompileError::LlvmDisabled => "XB-B001",
        }
    }
}
