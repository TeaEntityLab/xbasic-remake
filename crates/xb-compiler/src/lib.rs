mod builtin;
mod c_emit;
mod c_emit_bitops;
mod c_emit_data;
mod c_emit_expr;
mod c_emit_helpers;
mod c_emit_logical;
mod c_emit_select;
mod c_emit_stmt;
mod c_emit_str2;
mod c_runtime;
mod c_runtime_bit;
mod c_runtime_math;
pub mod checked;
mod diagnostic;
#[cfg(test)]
mod diagnostic_tests;
mod entry_lookup;
pub mod ir;
mod ir_lower;
#[cfg(test)]
mod ir_tests;
pub mod semantics;
mod semantics_expr;
mod semantics_function;
mod semantics_if;
mod semantics_logical;
mod semantics_select;
#[cfg(test)]
mod semantics_shared_tests;
mod semantics_statement;
mod semantics_stmts;
mod semantics_suffix;
#[cfg(test)]
mod semantics_tests;
mod semantics_types;
pub mod text_ir;
mod text_ir_expr;
mod text_ir_ops;
pub mod text_ir_parser;
mod text_ir_parser_data;
mod text_ir_parser_expr;
mod text_ir_parser_helpers;
mod text_ir_parser_item;
mod text_ir_parser_select;
#[cfg(test)]
mod text_ir_parser_tests;
#[cfg(test)]
mod text_ir_tests;
pub use c_emit::CEmitter;
pub use checked::{
    ArithmeticOp, BooleanOp, CheckedExpr, CheckedExprKind, CheckedItem, CheckedParam,
    CheckedProgram, CheckedSymbol, ComparisonOp, LogicalOp, PrintSep, SemanticError, UnaryOp,
    ValueType,
};
pub use diagnostic::{BACKEND_DIAGNOSTIC_CODES, SOURCE_DIAGNOSTIC_CODES};
pub use entry_lookup::EntryLookupError;
pub use ir::{IrCaseClause, IrExpr, IrExprKind, IrItem, IrParam, IrProgram, IrSymbol};
pub use semantics::Analyzer;
pub use text_ir::TextIrEmitter;
pub use text_ir_parser::{TextIrParseError, TextIrParser};

use thiserror::Error;
use xb_frontend::{parse_program, ParseError, Program};

#[derive(Debug, Error)]
pub enum CompileError {
    #[error(transparent)]
    Parse(#[from] ParseError),
    #[error(transparent)]
    Semantic(#[from] SemanticError),
    #[error("LLVM backend is disabled; rebuild xb-compiler with the `llvm` feature")]
    LlvmDisabled,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrontendUnit {
    program: Program,
}

impl FrontendUnit {
    pub fn parse(source: &str) -> Result<Self, CompileError> {
        Ok(Self {
            program: parse_program(source)?,
        })
    }

    pub fn program(&self) -> &Program {
        &self.program
    }

    pub fn analyze(&self) -> Result<CheckedProgram, CompileError> {
        Ok(Analyzer::analyze(&self.program)?)
    }

    pub fn lower_ir(&self) -> Result<IrProgram, CompileError> {
        Ok(IrProgram::lower(&self.analyze()?))
    }

    pub fn analyze_strict(&self) -> Result<CheckedProgram, CompileError> {
        Ok(Analyzer::analyze_strict(&self.program)?)
    }

    pub fn lower_ir_strict(&self) -> Result<IrProgram, CompileError> {
        Ok(IrProgram::lower(&self.analyze_strict()?))
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ObjectFile {
    bytes: Vec<u8>,
}

impl ObjectFile {
    pub fn from_bytes(bytes: Vec<u8>) -> Self {
        Self { bytes }
    }

    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes
    }
}

pub trait Codegen {
    fn compile(&self, unit: &FrontendUnit) -> Result<ObjectFile, CompileError>;
}

#[derive(Debug, Clone, Copy, Default)]
pub struct DisabledLlvmBackend;

impl Codegen for DisabledLlvmBackend {
    fn compile(&self, _unit: &FrontendUnit) -> Result<ObjectFile, CompileError> {
        Err(CompileError::LlvmDisabled)
    }
}

#[cfg(feature = "llvm")]
pub mod llvm_backend {
    use super::{Codegen, CompileError, FrontendUnit, ObjectFile};

    #[derive(Debug, Clone, Copy, Default)]
    pub struct LlvmBackend;

    impl Codegen for LlvmBackend {
        fn compile(&self, unit: &FrontendUnit) -> Result<ObjectFile, CompileError> {
            let _item_count = unit.lower_ir()?.items.len();
            Ok(ObjectFile::from_bytes(Vec::new()))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_frontend_unit_when_source_has_statements() {
        let unit = FrontendUnit::parse("VERSION \"6.5.0\"\nPRINT \"hello\"\n").unwrap();
        assert_eq!(unit.program().statements.len(), 2);
    }

    #[test]
    fn lowers_frontend_unit_into_ir() {
        let unit = FrontendUnit::parse(
            "VERSION \"6.5.0\"\nFUNCTION Main\nPRINT \"hello\"\nEND FUNCTION\n",
        )
        .unwrap();
        let ir = unit.lower_ir().unwrap();
        assert_eq!(ir.items.len(), 2);
    }

    #[test]
    fn auto_declares_unknown_identifier_during_analysis() {
        let unit = FrontendUnit::parse("PRINT missing\n").unwrap();
        let result = unit.analyze();
        // XBasic auto-declares variables on first use as integers
        assert!(result.is_ok());
    }

    #[test]
    fn disabled_backend_reports_missing_feature() {
        let unit = FrontendUnit::parse("PRINT \"hello\"\n").unwrap();
        let result = DisabledLlvmBackend.compile(&unit);
        assert!(matches!(result, Err(CompileError::LlvmDisabled)));
    }
}
