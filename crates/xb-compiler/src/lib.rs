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
    use crate::checked::{ArithmeticOp, BooleanOp, ComparisonOp, LogicalOp};
    use crate::ir::{IrExpr, IrExprKind, IrItem, IrProgram};
    use crate::ValueType;
    use inkwell::context::Context;
    use inkwell::targets::{
        CodeModel, FileType, InitializationConfig, RelocMode, Target, TargetMachine,
    };
    use inkwell::builder::Builder;
    use inkwell::module::Module;
    use inkwell::values::{BasicValueEnum, FunctionValue, IntValue, PointerValue};
    use inkwell::{AddressSpace, OptimizationLevel};
    use inkwell::basic_block::BasicBlock;
    use inkwell::types::{BasicTypeEnum, IntType, PointerType};
    use inkwell::IntPredicate;
    use std::collections::HashMap;

    #[derive(Debug, Clone, Copy, Default)]
    pub struct LlvmBackend;

    impl Codegen for LlvmBackend {
        /// Emit a real native object. Translates the executed integer+string subset —
        /// scalar `DIM`/assignment, integer arithmetic/comparisons/boolean/logical,
        /// `IF`/`WHILE`/`FOR` control flow, and `PRINT` — into a `main` driving `printf`,
        /// then writes a host-target object via `TargetMachine`. Functions, floats,
        /// arrays, and string comparison are not yet translated (docs/17); the C backend
        /// remains the full AOT path.
        fn compile(&self, unit: &FrontendUnit) -> Result<ObjectFile, CompileError> {
            let program = unit.lower_ir()?;
            Target::initialize_native(&InitializationConfig::default())
                .map_err(CompileError::Llvm)?;
            let ctx = Context::create();
            let mut emit = Emit::new(&ctx)?;
            emit.emit_items(&program.items)?;
            if let Some(body) = entry_body(&program) {
                emit.emit_items(body)?;
            }
            emit.finish()
        }
    }

    /// LLVM code generator emitting a single `main`.
    struct Emit<'ctx> {
        ctx: &'ctx Context,
        module: Module<'ctx>,
        builder: Builder<'ctx>,
        i32t: IntType<'ctx>,
        ptr: PointerType<'ctx>,
        printf: FunctionValue<'ctx>,
        main: FunctionValue<'ctx>,
        fmt_s: PointerValue<'ctx>,
        fmt_d: PointerValue<'ctx>,
        nl: PointerValue<'ctx>,
        vars: HashMap<String, (PointerValue<'ctx>, ValueType)>,
    }

    impl<'ctx> Emit<'ctx> {
        fn err(e: inkwell::builder::BuilderError) -> CompileError {
            CompileError::Llvm(e.to_string())
        }

        fn new(ctx: &'ctx Context) -> Result<Self, CompileError> {
            let module = ctx.create_module("xb");
            let builder = ctx.create_builder();
            let i32t = ctx.i32_type();
            let ptr = ctx.ptr_type(AddressSpace::default());
            let printf = module.add_function("printf", i32t.fn_type(&[ptr.into()], true), None);
            let main = module.add_function("main", i32t.fn_type(&[], false), None);
            builder.position_at_end(ctx.append_basic_block(main, "entry"));
            let g = |b: &Builder<'ctx>, s: &str, n: &str| -> Result<PointerValue<'ctx>, CompileError> {
                Ok(b.build_global_string_ptr(s, n).map_err(Self::err)?.as_pointer_value())
            };
            let fmt_s = g(&builder, "%s", "fmts")?;
            let fmt_d = g(&builder, "%d", "fmtd")?;
            let nl = g(&builder, "\n", "nl")?;
            Ok(Self {
                ctx,
                module,
                builder,
                i32t,
                ptr,
                printf,
                main,
                fmt_s,
                fmt_d,
                nl,
                vars: HashMap::new(),
            })
        }

        fn finish(self) -> Result<ObjectFile, CompileError> {
            self.builder
                .build_return(Some(&self.i32t.const_int(0, false)))
                .map_err(Self::err)?;
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
                .write_to_memory_buffer(&self.module, FileType::Object)
                .map_err(|e| CompileError::Llvm(e.to_string()))?;
            Ok(ObjectFile::from_bytes(buf.as_slice().to_vec()))
        }

        fn get_or_alloca(
            &mut self,
            name: &str,
            vt: ValueType,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            if let Some((s, _)) = self.vars.get(name) {
                return Ok(*s);
            }
            let ty: BasicTypeEnum = if vt == ValueType::String {
                self.ptr.into()
            } else {
                self.i32t.into()
            };
            let s = self.builder.build_alloca(ty, name).map_err(Self::err)?;
            self.vars.insert(name.to_string(), (s, vt));
            Ok(s)
        }

        /// Branch to `bb` unless the current block is already terminated.
        fn branch_to(&self, bb: BasicBlock<'ctx>) -> Result<(), CompileError> {
            let open = self
                .builder
                .get_insert_block()
                .and_then(|b| b.get_terminator())
                .is_none();
            if open {
                self.builder.build_unconditional_branch(bb).map_err(Self::err)?;
            }
            Ok(())
        }

        fn emit_items(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            for item in items {
                self.emit_item(item)?;
            }
            Ok(())
        }

        fn emit_item(&mut self, item: &IrItem) -> Result<(), CompileError> {
            match item {
                IrItem::Dim { symbol, is_array: false, .. } => {
                    let slot = self.get_or_alloca(&symbol.name, symbol.value_type)?;
                    let init: BasicValueEnum = if symbol.value_type == ValueType::String {
                        self.builder
                            .build_global_string_ptr("", "e")
                            .map_err(Self::err)?
                            .as_pointer_value()
                            .into()
                    } else {
                        self.i32t.const_zero().into()
                    };
                    self.builder.build_store(slot, init).map_err(Self::err)?;
                }
                IrItem::Assignment { target, value } => {
                    if let Some(v) = self.eval_value(value)? {
                        let slot = self.get_or_alloca(&target.name, target.value_type)?;
                        self.builder.build_store(slot, v).map_err(Self::err)?;
                    }
                }
                IrItem::Print { items, .. } => {
                    for e in items {
                        match self.eval_value(e)? {
                            Some(BasicValueEnum::IntValue(iv)) => {
                                self.builder
                                    .build_call(self.printf, &[self.fmt_d.into(), iv.into()], "")
                                    .map_err(Self::err)?;
                            }
                            Some(BasicValueEnum::PointerValue(pv)) => {
                                self.builder
                                    .build_call(self.printf, &[self.fmt_s.into(), pv.into()], "")
                                    .map_err(Self::err)?;
                            }
                            _ => {}
                        }
                    }
                    self.builder
                        .build_call(self.printf, &[self.nl.into()], "")
                        .map_err(Self::err)?;
                }
                IrItem::If { condition, then_body, else_body } => {
                    let cond = self.eval_bool(condition)?;
                    let then_bb = self.ctx.append_basic_block(self.main, "then");
                    let else_bb = self.ctx.append_basic_block(self.main, "else");
                    let merge = self.ctx.append_basic_block(self.main, "endif");
                    self.builder
                        .build_conditional_branch(cond, then_bb, else_bb)
                        .map_err(Self::err)?;
                    self.builder.position_at_end(then_bb);
                    self.emit_items(then_body)?;
                    self.branch_to(merge)?;
                    self.builder.position_at_end(else_bb);
                    if let Some(eb) = else_body {
                        self.emit_items(eb)?;
                    }
                    self.branch_to(merge)?;
                    self.builder.position_at_end(merge);
                }
                IrItem::While { condition, body } => {
                    let header = self.ctx.append_basic_block(self.main, "while.head");
                    let body_bb = self.ctx.append_basic_block(self.main, "while.body");
                    let exit = self.ctx.append_basic_block(self.main, "while.exit");
                    self.branch_to(header)?;
                    self.builder.position_at_end(header);
                    let cond = self.eval_bool(condition)?;
                    self.builder
                        .build_conditional_branch(cond, body_bb, exit)
                        .map_err(Self::err)?;
                    self.builder.position_at_end(body_bb);
                    self.emit_items(body)?;
                    self.branch_to(header)?;
                    self.builder.position_at_end(exit);
                }
                IrItem::For { var, start, end, step, body } => {
                    let slot = self.get_or_alloca(&var.name, ValueType::Integer)?;
                    let start_v = self.eval_int(start)?;
                    self.builder.build_store(slot, start_v).map_err(Self::err)?;
                    let end_v = self.eval_int(end)?;
                    let step_v = match step {
                        Some(s) => self.eval_int(s)?,
                        None => self.i32t.const_int(1, true),
                    };
                    let header = self.ctx.append_basic_block(self.main, "for.head");
                    let body_bb = self.ctx.append_basic_block(self.main, "for.body");
                    let exit = self.ctx.append_basic_block(self.main, "for.exit");
                    self.branch_to(header)?;
                    self.builder.position_at_end(header);
                    let cur = self
                        .builder
                        .build_load(self.i32t, slot, "for.cur")
                        .map_err(Self::err)?
                        .into_int_value();
                    let zero = self.i32t.const_zero();
                    let up = self
                        .builder
                        .build_int_compare(IntPredicate::SGE, step_v, zero, "for.up")
                        .map_err(Self::err)?;
                    let le = self
                        .builder
                        .build_int_compare(IntPredicate::SLE, cur, end_v, "for.le")
                        .map_err(Self::err)?;
                    let ge = self
                        .builder
                        .build_int_compare(IntPredicate::SGE, cur, end_v, "for.ge")
                        .map_err(Self::err)?;
                    let cond = self
                        .builder
                        .build_select(up, le, ge, "for.cond")
                        .map_err(Self::err)?
                        .into_int_value();
                    self.builder
                        .build_conditional_branch(cond, body_bb, exit)
                        .map_err(Self::err)?;
                    self.builder.position_at_end(body_bb);
                    self.emit_items(body)?;
                    let cur2 = self
                        .builder
                        .build_load(self.i32t, slot, "for.cur2")
                        .map_err(Self::err)?
                        .into_int_value();
                    let next = self
                        .builder
                        .build_int_add(cur2, step_v, "for.next")
                        .map_err(Self::err)?;
                    self.builder.build_store(slot, next).map_err(Self::err)?;
                    self.branch_to(header)?;
                    self.builder.position_at_end(exit);
                }
                IrItem::Compound(items) => self.emit_items(items)?,
                _ => {}
            }
            Ok(())
        }

        /// Evaluate a condition to `i1` (nonzero = true) for a branch.
        fn eval_bool(&self, expr: &IrExpr) -> Result<IntValue<'ctx>, CompileError> {
            let v = self.eval_int(expr)?;
            self.builder
                .build_int_compare(IntPredicate::NE, v, self.i32t.const_zero(), "cond")
                .map_err(Self::err)
        }

        /// Evaluate an expression to `i32` (0 when not an integer value).
        fn eval_int(&self, expr: &IrExpr) -> Result<IntValue<'ctx>, CompileError> {
            Ok(match self.eval_value(expr)? {
                Some(BasicValueEnum::IntValue(v)) => v,
                _ => self.i32t.const_zero(),
            })
        }

        /// Evaluate to an LLVM value: `ptr` (char*) for strings, `i32` for integers.
        /// `None` for constructs this v0 does not translate.
        fn eval_value(&self, expr: &IrExpr) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            Ok(match &expr.kind {
                IrExprKind::StringLiteral(s) => Some(
                    self.builder
                        .build_global_string_ptr(s, "s")
                        .map_err(Self::err)?
                        .as_pointer_value()
                        .into(),
                ),
                IrExprKind::IntegerLiteral(v) => {
                    let n = if let Some(h) = v.strip_prefix("0x").or_else(|| v.strip_prefix("0X")) {
                        i64::from_str_radix(h, 16).unwrap_or(0)
                    } else {
                        v.parse::<i64>().unwrap_or(0)
                    };
                    Some(self.i32t.const_int(n as u64, true).into())
                }
                IrExprKind::Symbol(sym) => match self.vars.get(&sym.name) {
                    Some((slot, ValueType::String)) => {
                        Some(self.builder.build_load(self.ptr, *slot, "ld").map_err(Self::err)?)
                    }
                    Some((slot, _)) => {
                        Some(self.builder.build_load(self.i32t, *slot, "ld").map_err(Self::err)?)
                    }
                    None => None,
                },
                IrExprKind::Arithmetic { op, left, right } => {
                    let a = self.eval_int(left)?;
                    let b = self.eval_int(right)?;
                    let v = match op {
                        ArithmeticOp::Add => self.builder.build_int_add(a, b, "add"),
                        ArithmeticOp::Sub => self.builder.build_int_sub(a, b, "sub"),
                        ArithmeticOp::Mul => self.builder.build_int_mul(a, b, "mul"),
                        ArithmeticOp::Div => self.builder.build_int_signed_div(a, b, "div"),
                        _ => return Ok(None),
                    };
                    Some(v.map_err(Self::err)?.into())
                }
                IrExprKind::Comparison { op, left, right } => {
                    let (Some(BasicValueEnum::IntValue(a)), Some(BasicValueEnum::IntValue(b))) =
                        (self.eval_value(left)?, self.eval_value(right)?)
                    else {
                        return Ok(None);
                    };
                    let pred = match op {
                        ComparisonOp::Equal => IntPredicate::EQ,
                        ComparisonOp::NotEqual => IntPredicate::NE,
                        ComparisonOp::Less => IntPredicate::SLT,
                        ComparisonOp::Greater => IntPredicate::SGT,
                        ComparisonOp::LessEqual => IntPredicate::SLE,
                        ComparisonOp::GreaterEqual => IntPredicate::SGE,
                    };
                    let c = self.builder.build_int_compare(pred, a, b, "cmp").map_err(Self::err)?;
                    // XBasic truth is -1: sign-extend i1 (1 -> -1, 0 -> 0).
                    Some(
                        self.builder
                            .build_int_s_extend(c, self.i32t, "cmpext")
                            .map_err(Self::err)?
                            .into(),
                    )
                }
                IrExprKind::Not(inner) => {
                    let v = self.eval_int(inner)?;
                    Some(self.builder.build_not(v, "not").map_err(Self::err)?.into())
                }
                IrExprKind::Boolean { op, left, right } => {
                    let a = self.eval_int(left)?;
                    let b = self.eval_int(right)?;
                    let v = match op {
                        BooleanOp::And => self.builder.build_and(a, b, "and"),
                        BooleanOp::Or => self.builder.build_or(a, b, "or"),
                        BooleanOp::Xor => self.builder.build_xor(a, b, "xor"),
                    };
                    Some(v.map_err(Self::err)?.into())
                }
                IrExprKind::Logical { op, left, right } => {
                    let a = self.eval_int(left)?;
                    let b = self.eval_int(right)?;
                    let zero = self.i32t.const_zero();
                    let la = self.builder.build_int_compare(IntPredicate::NE, a, zero, "la").map_err(Self::err)?;
                    let rb = self.builder.build_int_compare(IntPredicate::NE, b, zero, "lb").map_err(Self::err)?;
                    let r = match op {
                        LogicalOp::And => self.builder.build_and(la, rb, "land"),
                        LogicalOp::Or => self.builder.build_or(la, rb, "lor"),
                        LogicalOp::Xor => self.builder.build_xor(la, rb, "lxor"),
                    };
                    Some(
                        self.builder
                            .build_int_s_extend(r.map_err(Self::err)?, self.i32t, "lext")
                            .map_err(Self::err)?
                            .into(),
                    )
                }
                _ => None,
            })
        }
    }

    /// The entry function body (`Main`, else the first function), if any. Top-level
    /// items are emitted directly; `Function` items are skipped by `emit_item`.
    fn entry_body(program: &IrProgram) -> Option<&[IrItem]> {
        let mut entry: Option<&[IrItem]> = None;
        for item in &program.items {
            if let IrItem::Function { name, body, .. } = item {
                if name == "Main" {
                    return Some(body.as_slice());
                }
                if entry.is_none() {
                    entry = Some(body.as_slice());
                }
            }
        }
        entry
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

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_integer_arithmetic() {
        use std::io::Write;
        use std::process::Command;
        // Integer var + arithmetic + PRINT: 2*3 + 1 = 7.
        let unit = FrontendUnit::parse(
            "VERSION \"6.5.0\"\nDIM n\nn = 2 * 3 + 1\nPRINT n\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_int.o");
        let exep = dir.join("xb_llvm_int.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "7\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_control_flow() {
        use std::io::Write;
        use std::process::Command;
        // FOR sums 1..3 = 6; the IF selects the `> 5` branch. Exercises For, If,
        // integer comparison, and arithmetic through the LLVM backend.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM n\n\
             n = 0\n\
             FOR i = 1 TO 3\n\
             n = n + i\n\
             NEXT i\n\
             PRINT n\n\
             IF n > 5 THEN\n\
             PRINT \"big\"\n\
             ELSE\n\
             PRINT \"small\"\n\
             END IF\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_cf.o");
        let exep = dir.join("xb_llvm_cf.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "6\nbig\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }
}
