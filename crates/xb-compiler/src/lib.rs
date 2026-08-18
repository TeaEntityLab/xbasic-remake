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
    #[error("LLVM codegen error: {0}")]
    Llvm(String),
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
    use crate::ir::{IrExprKind, IrItem, IrProgram};
    use crate::ValueType;
    use inkwell::context::Context;
    use inkwell::targets::{
        CodeModel, FileType, InitializationConfig, RelocMode, Target, TargetMachine,
    };
    use inkwell::values::PointerValue;
    use inkwell::{AddressSpace, OptimizationLevel};
    use std::collections::HashMap;

    #[derive(Debug, Clone, Copy, Default)]
    pub struct LlvmBackend;

    impl Codegen for LlvmBackend {
        /// Emit a real native object. v0 translates the executed string subset
        /// (`DIM s$` / `s$ = "…"` / `s$ = other$` / `PRINT "…"|s$`) into a `main`
        /// that drives `puts`, then writes a host-target object via `TargetMachine`.
        /// Non-string / control-flow items are not yet translated (tracked in docs/17).
        fn compile(&self, unit: &FrontendUnit) -> Result<ObjectFile, CompileError> {
            let program = unit.lower_ir()?;
            Target::initialize_native(&InitializationConfig::default())
                .map_err(CompileError::Llvm)?;
            let ctx = Context::create();
            let module = ctx.create_module("xb");
            let builder = ctx.create_builder();
            let err = |e: inkwell::builder::BuilderError| CompileError::Llvm(e.to_string());
            let i32t = ctx.i32_type();
            let ptr = ctx.ptr_type(AddressSpace::default());
            let puts = module.add_function("puts", i32t.fn_type(&[ptr.into()], false), None);
            let main = module.add_function("main", i32t.fn_type(&[], false), None);
            builder.position_at_end(ctx.append_basic_block(main, "entry"));
            let mut vars: HashMap<String, PointerValue> = HashMap::new();
            for item in executable_items(&program) {
                match item {
                    IrItem::Dim { symbol, .. } if symbol.value_type == ValueType::String => {
                        let slot = builder.build_alloca(ptr, &symbol.name).map_err(err)?;
                        let empty = builder.build_global_string_ptr("", "e").map_err(err)?;
                        builder.build_store(slot, empty.as_pointer_value()).map_err(err)?;
                        vars.insert(symbol.name.clone(), slot);
                    }
                    IrItem::Assignment { target, value }
                        if target.value_type == ValueType::String =>
                    {
                        let v = match &value.kind {
                            IrExprKind::StringLiteral(s) => builder
                                .build_global_string_ptr(s, "s")
                                .map_err(err)?
                                .as_pointer_value(),
                            IrExprKind::Symbol(sym) => match vars.get(&sym.name) {
                                Some(slot) => builder
                                    .build_load(ptr, *slot, "ld")
                                    .map_err(err)?
                                    .into_pointer_value(),
                                None => continue,
                            },
                            _ => continue,
                        };
                        let slot = match vars.get(&target.name) {
                            Some(s) => *s,
                            None => {
                                let s = builder.build_alloca(ptr, &target.name).map_err(err)?;
                                vars.insert(target.name.clone(), s);
                                s
                            }
                        };
                        builder.build_store(slot, v).map_err(err)?;
                    }
                    IrItem::Print { items, .. } => {
                        for e in items {
                            let p: Option<PointerValue> = match &e.kind {
                                IrExprKind::StringLiteral(s) => Some(
                                    builder
                                        .build_global_string_ptr(s, "s")
                                        .map_err(err)?
                                        .as_pointer_value(),
                                ),
                                IrExprKind::Symbol(sym) => match vars.get(&sym.name) {
                                    Some(slot) => Some(
                                        builder
                                            .build_load(ptr, *slot, "ld")
                                            .map_err(err)?
                                            .into_pointer_value(),
                                    ),
                                    None => None,
                                },
                                _ => None,
                            };
                            if let Some(p) = p {
                                builder.build_call(puts, &[p.into()], "").map_err(err)?;
                            }
                        }
                    }
                    _ => {}
                }
            }
            builder
                .build_return(Some(&i32t.const_int(0, false)))
                .map_err(err)?;

            let triple = TargetMachine::get_default_triple();
            let target =
                Target::from_triple(&triple).map_err(|e| CompileError::Llvm(e.to_string()))?;
            let tm = target
                .create_target_machine(
                    &triple,
                    &TargetMachine::get_host_cpu_name().to_string(),
                    &TargetMachine::get_host_cpu_features().to_string(),
                    OptimizationLevel::Default,
                    RelocMode::PIC,
                    CodeModel::Default,
                )
                .ok_or_else(|| CompileError::Llvm("could not create target machine".into()))?;
            let buf = tm
                .write_to_memory_buffer(&module, FileType::Object)
                .map_err(|e| CompileError::Llvm(e.to_string()))?;
            Ok(ObjectFile::from_bytes(buf.as_slice().to_vec()))
        }
    }

    /// The items `execute_main` would run: top-level items, then the entry
    /// function (`Main`, else the first function) body.
    fn executable_items(program: &IrProgram) -> Vec<&IrItem> {
        let mut out: Vec<&IrItem> = program
            .items
            .iter()
            .filter(|i| !matches!(i, IrItem::Function { .. }))
            .collect();
        let mut entry: Option<&Vec<IrItem>> = None;
        for item in &program.items {
            if let IrItem::Function { name, body, .. } = item {
                if name == "Main" {
                    entry = Some(body);
                    break;
                }
                if entry.is_none() {
                    entry = Some(body);
                }
            }
        }
        if let Some(body) = entry {
            out.extend(body.iter());
        }
        out
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

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_emits_runnable_object() {
        use std::io::Write;
        use std::process::Command;
        // Bootstrap hello fixture pattern: DIM / assign / PRINT a string variable.
        let unit = FrontendUnit::parse(
            "VERSION \"6.5.0\"\nDIM name$\nname$ = \"hello\"\nPRINT name$\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty(), "object file must not be empty");
        // Real-emission proof: link the object with cc and run the executable.
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_hello.o");
        let exep = dir.join("xb_llvm_hello.bin");
        std::fs::File::create(&objp)
            .unwrap()
            .write_all(obj.as_bytes())
            .unwrap();
        let link = Command::new("cc")
            .arg(&objp)
            .arg("-o")
            .arg(&exep)
            .output()
            .unwrap();
        assert!(
            link.status.success(),
            "link failed: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "hello\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }
}
