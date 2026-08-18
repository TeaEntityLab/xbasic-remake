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
    use inkwell::values::{
        BasicMetadataValueEnum, BasicValueEnum, FloatValue, FunctionValue, IntValue, PointerValue,
    };
    use inkwell::{AddressSpace, OptimizationLevel};
    use inkwell::basic_block::BasicBlock;
    use inkwell::types::{BasicMetadataTypeEnum, BasicTypeEnum, FloatType, IntType, PointerType};
    use inkwell::{FloatPredicate, IntPredicate};
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
            emit.declare_functions(&program.items);
            emit.emit_items(&program.items)?;
            if let Some(body) = entry_body(&program) {
                emit.emit_items(body)?;
            }
            emit.ret_default()?;
            emit.emit_function_bodies(&program.items)?;
            emit.object()
        }
    }

    /// LLVM code generator emitting a single `main`.
    struct Emit<'ctx> {
        ctx: &'ctx Context,
        module: Module<'ctx>,
        builder: Builder<'ctx>,
        i32t: IntType<'ctx>,
        f64t: FloatType<'ctx>,
        ptr: PointerType<'ctx>,
        printf: FunctionValue<'ctx>,
        fmt_s: PointerValue<'ctx>,
        fmt_d: PointerValue<'ctx>,
        nl: PointerValue<'ctx>,
        fmt_g: PointerValue<'ctx>,
        /// User-defined functions (name → LLVM fn), excluding the flattened entry.
        funcs: HashMap<String, FunctionValue<'ctx>>,
        /// Function currently being emitted (for `append_basic_block`).
        cur_fn: FunctionValue<'ctx>,
        /// Return type of the function currently being emitted.
        cur_ret: ValueType,
        vars: HashMap<String, (PointerValue<'ctx>, ValueType)>,
        i64t: IntType<'ctx>,
        calloc: FunctionValue<'ctx>,
        strlen: FunctionValue<'ctx>,
        strcmp: FunctionValue<'ctx>,
        memcpy: FunctionValue<'ctx>,
        /// Array vars: name → (alloca holding the heap buffer ptr, element type). 1D only (v0).
        arrays: HashMap<String, (PointerValue<'ctx>, ValueType)>,
    }

    impl<'ctx> Emit<'ctx> {
        fn err(e: inkwell::builder::BuilderError) -> CompileError {
            CompileError::Llvm(e.to_string())
        }

        fn new(ctx: &'ctx Context) -> Result<Self, CompileError> {
            let module = ctx.create_module("xb");
            let builder = ctx.create_builder();
            let i32t = ctx.i32_type();
            let f64t = ctx.f64_type();
            let ptr = ctx.ptr_type(AddressSpace::default());
            let i64t = ctx.i64_type();
            let calloc =
                module.add_function("calloc", ptr.fn_type(&[i64t.into(), i64t.into()], false), None);
            let strlen = module.add_function("strlen", i64t.fn_type(&[ptr.into()], false), None);
            let strcmp =
                module.add_function("strcmp", i32t.fn_type(&[ptr.into(), ptr.into()], false), None);
            let memcpy = module.add_function(
                "memcpy",
                ptr.fn_type(&[ptr.into(), ptr.into(), i64t.into()], false),
                None,
            );
            let printf = module.add_function("printf", i32t.fn_type(&[ptr.into()], true), None);
            let main = module.add_function("main", i32t.fn_type(&[], false), None);
            builder.position_at_end(ctx.append_basic_block(main, "entry"));
            let g = |b: &Builder<'ctx>, s: &str, n: &str| -> Result<PointerValue<'ctx>, CompileError> {
                Ok(b.build_global_string_ptr(s, n).map_err(Self::err)?.as_pointer_value())
            };
            let fmt_s = g(&builder, "%s", "fmts")?;
            let fmt_d = g(&builder, "%d", "fmtd")?;
            let nl = g(&builder, "\n", "nl")?;
            let fmt_g = g(&builder, "%g", "fmtg")?;
            Ok(Self {
                ctx,
                module,
                builder,
                i32t,
                ptr,
                printf,
                fmt_s,
                fmt_d,
                nl,
                f64t,
                fmt_g,
                i64t,
                calloc,
                strlen,
                strcmp,
                memcpy,
                arrays: HashMap::new(),
                vars: HashMap::new(),
                funcs: HashMap::new(),
                cur_fn: main,
                cur_ret: ValueType::Integer,
            })
        }

        /// Emit the module to a host-target object (assumes returns already built).
        fn object(self) -> Result<ObjectFile, CompileError> {
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
        fn llvm_type(&self, vt: ValueType) -> BasicTypeEnum<'ctx> {
            match vt {
                ValueType::String => self.ptr.into(),
                ValueType::Float => self.f64t.into(),
                _ => self.i32t.into(),
            }
        }

        /// GEP to element `name[index]` (1D). `None` if `name` is not a known array.
        fn array_elem_ptr(
            &self,
            name: &str,
            index: &IrExpr,
        ) -> Result<Option<(PointerValue<'ctx>, ValueType)>, CompileError> {
            let Some(&(holder, elem)) = self.arrays.get(name) else {
                return Ok(None);
            };
            let bufptr = self
                .builder
                .build_load(self.ptr, holder, "buf")
                .map_err(Self::err)?
                .into_pointer_value();
            let idx = self.eval_int(index)?;
            let ety = self.llvm_type(elem);
            let ep = unsafe {
                self.builder
                    .build_in_bounds_gep(ety, bufptr, &[idx], "elem")
                    .map_err(Self::err)?
            };
            Ok(Some((ep, elem)))
        }

        /// Build a return for the current function's type if the block is still open.
        fn ret_default(&self) -> Result<(), CompileError> {
            if self
                .builder
                .get_insert_block()
                .and_then(|b| b.get_terminator())
                .is_some()
            {
                return Ok(());
            }
            let rv: BasicValueEnum = match self.cur_ret {
                ValueType::String => self.ptr.const_null().into(),
                ValueType::Float => self.f64t.const_zero().into(),
                _ => self.i32t.const_zero().into(),
            };
            self.builder.build_return(Some(&rv)).map_err(Self::err)?;
            Ok(())
        }

        /// Evaluate call arguments; `None` if any argument is untranslatable.
        fn eval_args(
            &self,
            args: &[IrExpr],
        ) -> Result<Option<Vec<BasicMetadataValueEnum<'ctx>>>, CompileError> {
            let mut argv = Vec::with_capacity(args.len());
            for a in args {
                match self.eval_value(a)? {
                    Some(v) => argv.push(v.into()),
                    None => return Ok(None),
                }
            }
            Ok(Some(argv))
        }

        /// Declare each non-entry user function (the entry is flattened into `main`).
        fn declare_functions(&mut self, items: &[IrItem]) {
            let entry = entry_name(items);
            for item in items {
                if let IrItem::Function { name, params, return_type, .. } = item {
                    if entry.as_deref() == Some(name.as_str()) {
                        continue;
                    }
                    let pts: Vec<BasicMetadataTypeEnum> = params
                        .iter()
                        .map(|p| self.llvm_type(p.value_type).into())
                        .collect();
                    let fty = match return_type {
                        ValueType::String => self.ptr.fn_type(&pts, false),
                        ValueType::Float => self.f64t.fn_type(&pts, false),
                        _ => self.i32t.fn_type(&pts, false),
                    };
                    let f = self.module.add_function(name, fty, None);
                    self.funcs.insert(name.clone(), f);
                }
            }
        }

        /// Emit each non-entry user function body in its own variable scope.
        fn emit_function_bodies(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            let entry = entry_name(items);
            for item in items {
                if let IrItem::Function { name, params, return_type, body } = item {
                    if entry.as_deref() == Some(name.as_str()) {
                        continue;
                    }
                    let f = self.funcs[name];
                    let saved_vars = std::mem::take(&mut self.vars);
                    let (saved_fn, saved_ret) = (self.cur_fn, self.cur_ret);
                    self.cur_fn = f;
                    self.cur_ret = *return_type;
                    let bb = self.ctx.append_basic_block(f, "entry");
                    self.builder.position_at_end(bb);
                    for (i, p) in params.iter().enumerate() {
                        let slot = self.get_or_alloca(&p.name, p.value_type)?;
                        if let Some(arg) = f.get_nth_param(i as u32) {
                            self.builder.build_store(slot, arg).map_err(Self::err)?;
                        }
                    }
                    self.emit_items(body)?;
                    self.ret_default()?;
                    self.vars = saved_vars;
                    self.cur_fn = saved_fn;
                    self.cur_ret = saved_ret;
                }
            }
            Ok(())
        }

        fn get_or_alloca(
            &mut self,
            name: &str,
            vt: ValueType,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            if let Some((s, _)) = self.vars.get(name) {
                return Ok(*s);
            }
            let ty: BasicTypeEnum = match vt {
                ValueType::String => self.ptr.into(),
                ValueType::Float => self.f64t.into(),
                _ => self.i32t.into(),
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
                    let init: BasicValueEnum = match symbol.value_type {
                        ValueType::String => self
                            .builder
                            .build_global_string_ptr("", "e")
                            .map_err(Self::err)?
                            .as_pointer_value()
                            .into(),
                        ValueType::Float => self.f64t.const_zero().into(),
                        _ => self.i32t.const_zero().into(),
                    };
                    self.builder.build_store(slot, init).map_err(Self::err)?;
                }
                IrItem::Dim { symbol, size, is_array: true, .. } => {
                    let elem = symbol.value_type;
                    let esz: u64 = match elem {
                        ValueType::Float | ValueType::String => 8,
                        _ => 4,
                    };
                    // DIM a[n] → indices 0..=n (n+1 slots); default 1 slot when unsized.
                    let count = match size {
                        Some(e) => {
                            let n = self.eval_int(e)?;
                            let n64 = self
                                .builder
                                .build_int_z_extend(n, self.i64t, "n64")
                                .map_err(Self::err)?;
                            self.builder
                                .build_int_add(n64, self.i64t.const_int(1, false), "cnt")
                                .map_err(Self::err)?
                        }
                        None => self.i64t.const_int(1, false),
                    };
                    let buf = self
                        .builder
                        .build_call(
                            self.calloc,
                            &[count.into(), self.i64t.const_int(esz, false).into()],
                            "arr",
                        )
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                        .into_pointer_value();
                    let holder = match self.arrays.get(&symbol.name) {
                        Some(&(h, _)) => h,
                        None => {
                            let h = self
                                .builder
                                .build_alloca(self.ptr, &symbol.name)
                                .map_err(Self::err)?;
                            self.arrays.insert(symbol.name.clone(), (h, elem));
                            h
                        }
                    };
                    self.builder.build_store(holder, buf).map_err(Self::err)?;
                }
                IrItem::Assignment { target, value } => {
                    if let Some(v) = self.eval_value(value)? {
                        let slot = self.get_or_alloca(&target.name, target.value_type)?;
                        self.builder.build_store(slot, v).map_err(Self::err)?;
                    }
                }
                IrItem::ArrayAssignment { target, index, value, .. } => {
                    if let (Some(v), Some((ep, _))) =
                        (self.eval_value(value)?, self.array_elem_ptr(&target.name, index)?)
                    {
                        self.builder.build_store(ep, v).map_err(Self::err)?;
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
                            Some(BasicValueEnum::FloatValue(fv)) => {
                                self.builder
                                    .build_call(self.printf, &[self.fmt_g.into(), fv.into()], "")
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
                    let then_bb = self.ctx.append_basic_block(self.cur_fn, "then");
                    let else_bb = self.ctx.append_basic_block(self.cur_fn, "else");
                    let merge = self.ctx.append_basic_block(self.cur_fn, "endif");
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
                    let header = self.ctx.append_basic_block(self.cur_fn, "while.head");
                    let body_bb = self.ctx.append_basic_block(self.cur_fn, "while.body");
                    let exit = self.ctx.append_basic_block(self.cur_fn, "while.exit");
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
                    let header = self.ctx.append_basic_block(self.cur_fn, "for.head");
                    let body_bb = self.ctx.append_basic_block(self.cur_fn, "for.body");
                    let exit = self.ctx.append_basic_block(self.cur_fn, "for.exit");
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
                IrItem::Return { value } => {
                    if self
                        .builder
                        .get_insert_block()
                        .and_then(|b| b.get_terminator())
                        .is_none()
                    {
                        let rv: BasicValueEnum = match (value, self.cur_ret) {
                            (Some(e), ValueType::String) => self
                                .eval_value(e)?
                                .unwrap_or_else(|| self.ptr.const_null().into()),
                            (Some(e), ValueType::Float) => self.eval_float(e)?.into(),
                            (Some(e), _) => self.eval_int(e)?.into(),
                            (None, ValueType::String) => self.ptr.const_null().into(),
                            (None, ValueType::Float) => self.f64t.const_zero().into(),
                            (None, _) => self.i32t.const_zero().into(),
                        };
                        self.builder.build_return(Some(&rv)).map_err(Self::err)?;
                    }
                }
                IrItem::Call { name, args } => {
                    if let Some(&f) = self.funcs.get(name) {
                        if let Some(argv) = self.eval_args(args)? {
                            self.builder.build_call(f, &argv, "call").map_err(Self::err)?;
                        }
                    }
                }
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

        /// Evaluate an expression to `f64`, promoting integers (0.0 otherwise).
        fn eval_float(&self, expr: &IrExpr) -> Result<FloatValue<'ctx>, CompileError> {
            Ok(match self.eval_value(expr)? {
                Some(BasicValueEnum::FloatValue(f)) => f,
                Some(BasicValueEnum::IntValue(i)) => self
                    .builder
                    .build_signed_int_to_float(i, self.f64t, "i2f")
                    .map_err(Self::err)?,
                _ => self.f64t.const_zero(),
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
                IrExprKind::FloatLiteral(v) => {
                    Some(self.f64t.const_float(v.parse::<f64>().unwrap_or(0.0)).into())
                }
                IrExprKind::Symbol(sym) => match self.vars.get(&sym.name) {
                    Some((slot, ValueType::String)) => {
                        Some(self.builder.build_load(self.ptr, *slot, "ld").map_err(Self::err)?)
                    }
                    Some((slot, ValueType::Float)) => {
                        Some(self.builder.build_load(self.f64t, *slot, "ld").map_err(Self::err)?)
                    }
                    Some((slot, _)) => {
                        Some(self.builder.build_load(self.i32t, *slot, "ld").map_err(Self::err)?)
                    }
                    None => None,
                },
                IrExprKind::Arithmetic { op, left, right } => {
                    if expr.value_type == ValueType::Float
                        || left.value_type == ValueType::Float
                        || right.value_type == ValueType::Float
                    {
                        let a = self.eval_float(left)?;
                        let b = self.eval_float(right)?;
                        let v = match op {
                            ArithmeticOp::Add => self.builder.build_float_add(a, b, "fadd"),
                            ArithmeticOp::Sub => self.builder.build_float_sub(a, b, "fsub"),
                            ArithmeticOp::Mul => self.builder.build_float_mul(a, b, "fmul"),
                            ArithmeticOp::Div => self.builder.build_float_div(a, b, "fdiv"),
                            _ => return Ok(None),
                        };
                        Some(v.map_err(Self::err)?.into())
                    } else {
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
                }
                IrExprKind::Comparison { op, left, right } => {
                    let c = if left.value_type == ValueType::String
                        || right.value_type == ValueType::String
                    {
                        let (
                            Some(BasicValueEnum::PointerValue(a)),
                            Some(BasicValueEnum::PointerValue(b)),
                        ) = (self.eval_value(left)?, self.eval_value(right)?)
                        else {
                            return Ok(None);
                        };
                        let r = self
                            .builder
                            .build_call(self.strcmp, &[a.into(), b.into()], "strcmp")
                            .map_err(Self::err)?
                            .try_as_basic_value()
                            .basic()
                            .ok_or_else(|| CompileError::Llvm("strcmp returned void".into()))?
                            .into_int_value();
                        let pred = match op {
                            ComparisonOp::Equal => IntPredicate::EQ,
                            ComparisonOp::NotEqual => IntPredicate::NE,
                            ComparisonOp::Less => IntPredicate::SLT,
                            ComparisonOp::Greater => IntPredicate::SGT,
                            ComparisonOp::LessEqual => IntPredicate::SLE,
                            ComparisonOp::GreaterEqual => IntPredicate::SGE,
                        };
                        self.builder
                            .build_int_compare(pred, r, self.i32t.const_zero(), "scmp")
                            .map_err(Self::err)?
                    } else if left.value_type == ValueType::Float
                        || right.value_type == ValueType::Float
                    {
                        let a = self.eval_float(left)?;
                        let b = self.eval_float(right)?;
                        let pred = match op {
                            ComparisonOp::Equal => FloatPredicate::OEQ,
                            ComparisonOp::NotEqual => FloatPredicate::ONE,
                            ComparisonOp::Less => FloatPredicate::OLT,
                            ComparisonOp::Greater => FloatPredicate::OGT,
                            ComparisonOp::LessEqual => FloatPredicate::OLE,
                            ComparisonOp::GreaterEqual => FloatPredicate::OGE,
                        };
                        self.builder.build_float_compare(pred, a, b, "fcmp").map_err(Self::err)?
                    } else {
                        let a = self.eval_int(left)?;
                        let b = self.eval_int(right)?;
                        let pred = match op {
                            ComparisonOp::Equal => IntPredicate::EQ,
                            ComparisonOp::NotEqual => IntPredicate::NE,
                            ComparisonOp::Less => IntPredicate::SLT,
                            ComparisonOp::Greater => IntPredicate::SGT,
                            ComparisonOp::LessEqual => IntPredicate::SLE,
                            ComparisonOp::GreaterEqual => IntPredicate::SGE,
                        };
                        self.builder.build_int_compare(pred, a, b, "cmp").map_err(Self::err)?
                    };
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
                IrExprKind::FunctionCall { name, args } => {
                    if let Some(v) = self.eval_builtin(name, args)? {
                        return Ok(Some(v));
                    }
                    let Some(&f) = self.funcs.get(name) else {
                        return Ok(None); // unsupported builtin or unknown function (deferred)
                    };
                    let Some(argv) = self.eval_args(args)? else {
                        return Ok(None);
                    };
                    self.builder
                        .build_call(f, &argv, "call")
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                }
                IrExprKind::ArrayAccess { symbol, index, .. } => {
                    match self.array_elem_ptr(&symbol.name, index)? {
                        Some((ep, elem)) => Some(
                            self.builder
                                .build_load(self.llvm_type(elem), ep, "ai")
                                .map_err(Self::err)?,
                        ),
                        None => None,
                    }
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

        /// `strlen(s)` as i64.
        fn str_len(&self, s: PointerValue<'ctx>) -> Result<IntValue<'ctx>, CompileError> {
            Ok(self
                .builder
                .build_call(self.strlen, &[s.into()], "len")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("strlen returned void".into()))?
                .into_int_value())
        }

        /// Unsigned min (matches `usize::min`).
        fn umin(&self, a: IntValue<'ctx>, b: IntValue<'ctx>) -> Result<IntValue<'ctx>, CompileError> {
            let lt = self
                .builder
                .build_int_compare(IntPredicate::ULT, a, b, "ult")
                .map_err(Self::err)?;
            Ok(self.builder.build_select(lt, a, b, "umin").map_err(Self::err)?.into_int_value())
        }

        /// Unsigned saturating subtract (matches `usize::saturating_sub`).
        fn usub_sat(&self, x: IntValue<'ctx>, y: IntValue<'ctx>) -> Result<IntValue<'ctx>, CompileError> {
            let ge = self
                .builder
                .build_int_compare(IntPredicate::UGE, x, y, "uge")
                .map_err(Self::err)?;
            let d = self.builder.build_int_sub(x, y, "sub").map_err(Self::err)?;
            Ok(self
                .builder
                .build_select(ge, d, self.i64t.const_zero(), "usub")
                .map_err(Self::err)?
                .into_int_value())
        }

        /// Allocate a fresh null-terminated string = `len` bytes copied from `src + off`.
        fn str_copy(
            &self,
            src: PointerValue<'ctx>,
            off: IntValue<'ctx>,
            len: IntValue<'ctx>,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            let cap = self
                .builder
                .build_int_add(len, self.i64t.const_int(1, false), "cap")
                .map_err(Self::err)?;
            let buf = self
                .builder
                .build_call(
                    self.calloc,
                    &[cap.into(), self.i64t.const_int(1, false).into()],
                    "sbuf",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                .into_pointer_value();
            let srcoff = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), src, &[off], "srcoff")
                    .map_err(Self::err)?
            };
            self.builder
                .build_call(self.memcpy, &[buf.into(), srcoff.into(), len.into()], "cp")
                .map_err(Self::err)?;
            Ok(buf)
        }

        /// Translate a supported builtin call; `None` if unsupported (deferred).
        fn eval_builtin(
            &self,
            name: &str,
            args: &[IrExpr],
        ) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            match (name, args.len()) {
                ("ABS", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::IntValue(iv)) => {
                        let neg = self.builder.build_int_neg(iv, "neg").map_err(Self::err)?;
                        let isneg = self
                            .builder
                            .build_int_compare(IntPredicate::SLT, iv, self.i32t.const_zero(), "isneg")
                            .map_err(Self::err)?;
                        Ok(Some(self.builder.build_select(isneg, neg, iv, "abs").map_err(Self::err)?))
                    }
                    Some(BasicValueEnum::FloatValue(fv)) => {
                        let neg = self.builder.build_float_neg(fv, "fneg").map_err(Self::err)?;
                        let isneg = self
                            .builder
                            .build_float_compare(
                                FloatPredicate::OLT,
                                fv,
                                self.f64t.const_zero(),
                                "fisneg",
                            )
                            .map_err(Self::err)?;
                        Ok(Some(self.builder.build_select(isneg, neg, fv, "fabs").map_err(Self::err)?))
                    }
                    _ => Ok(None),
                },
                ("LEN", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(pv)) => {
                        let call = self
                            .builder
                            .build_call(self.strlen, &[pv.into()], "len")
                            .map_err(Self::err)?;
                        let Some(n64) = call.try_as_basic_value().basic() else {
                            return Ok(None);
                        };
                        let n32 = self
                            .builder
                            .build_int_truncate(n64.into_int_value(), self.i32t, "len32")
                            .map_err(Self::err)?;
                        Ok(Some(n32.into()))
                    }
                    _ => Ok(None),
                },
                ("CHR$", 1) => {
                    let n = self.eval_int(&args[0])?;
                    let ch = self
                        .builder
                        .build_int_truncate(n, self.ctx.i8_type(), "ch")
                        .map_err(Self::err)?;
                    // calloc(2,1) -> [0,0]; store the char at [0], leaving a null terminator.
                    let buf = self
                        .builder
                        .build_call(
                            self.calloc,
                            &[
                                self.i64t.const_int(2, false).into(),
                                self.i64t.const_int(1, false).into(),
                            ],
                            "chrbuf",
                        )
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                        .into_pointer_value();
                    self.builder.build_store(buf, ch).map_err(Self::err)?;
                    Ok(Some(buf.into()))
                }
                ("LEFT$", 2) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let n = self.eval_int(&args[1])?;
                    let n64 = self.builder.build_int_s_extend(n, self.i64t, "n64").map_err(Self::err)?;
                    let len = self.str_len(s)?;
                    let cl = self.umin(n64, len)?;
                    Ok(Some(self.str_copy(s, self.i64t.const_zero(), cl)?.into()))
                }
                ("RIGHT$", 2) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let n = self.eval_int(&args[1])?;
                    let n64 = self.builder.build_int_s_extend(n, self.i64t, "n64").map_err(Self::err)?;
                    let len = self.str_len(s)?;
                    let start = self.usub_sat(len, n64)?;
                    let cl = self.builder.build_int_sub(len, start, "cl").map_err(Self::err)?;
                    Ok(Some(self.str_copy(s, start, cl)?.into()))
                }
                ("MID$", 2) | ("MID$", 3) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let start = self.eval_int(&args[1])?;
                    let s64 =
                        self.builder.build_int_s_extend(start, self.i64t, "s64").map_err(Self::err)?;
                    let len = self.str_len(s)?;
                    let a = self.usub_sat(s64, self.i64t.const_int(1, false))?;
                    let start_idx = self.umin(a, len)?;
                    let end_idx = if args.len() == 3 {
                        let l = self.eval_int(&args[2])?;
                        let l64 =
                            self.builder.build_int_s_extend(l, self.i64t, "l64").map_err(Self::err)?;
                        let sum =
                            self.builder.build_int_add(start_idx, l64, "sum").map_err(Self::err)?;
                        self.umin(sum, len)?
                    } else {
                        len
                    };
                    let cl = self.builder.build_int_sub(end_idx, start_idx, "cl").map_err(Self::err)?;
                    Ok(Some(self.str_copy(s, start_idx, cl)?.into()))
                }
                _ => Ok(None),
            }
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

    /// Name of the XBasic entry function (`Main`, else the first function).
    fn entry_name(items: &[IrItem]) -> Option<String> {
        let mut first = None;
        for item in items {
            if let IrItem::Function { name, .. } = item {
                if name == "Main" {
                    return Some("Main".to_string());
                }
                if first.is_none() {
                    first = Some(name.clone());
                }
            }
        }
        first
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

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_float_arithmetic() {
        use std::io::Write;
        use std::process::Command;
        // Double var + float division: 10.0 / 4.0 = 2.5 (printed via %g).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\nDIM x#\nx# = 10.0 / 4.0\nPRINT x#\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_flt.o");
        let exep = dir.join("xb_llvm_flt.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "2.5\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_user_function_call() {
        use std::io::Write;
        use std::process::Command;
        // Main calls Square(5); the user function returns x*x = 25.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             FUNCTION Main\n\
             DIM n\n\
             n = Square(5)\n\
             PRINT n\n\
             END FUNCTION\n\
             FUNCTION Square (x)\n\
             RETURN x * x\n\
             END FUNCTION\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_fn.o");
        let exep = dir.join("xb_llvm_fn.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "25\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_array_indexing() {
        use std::io::Write;
        use std::process::Command;
        // 1D heap array: a[2] = a[0] + a[1] = 30.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM a[3]\n\
             a[0] = 10\n\
             a[1] = 20\n\
             a[2] = a[0] + a[1]\n\
             PRINT a[2]\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_arr.o");
        let exep = dir.join("xb_llvm_arr.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "30\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_builtins_abs_len() {
        use std::io::Write;
        use std::process::Command;
        // LEN("hello") = 5; ABS(0 - 7) = 7.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM s$\n\
             s$ = \"hello\"\n\
             PRINT LEN(s$)\n\
             PRINT ABS(0 - 7)\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_bi.o");
        let exep = dir.join("xb_llvm_bi.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "5\n7\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_string_comparison() {
        use std::io::Write;
        use std::process::Command;
        // strcmp-backed IF on strings: n$ = "yes" -> "match".
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM n$\n\
             n$ = \"yes\"\n\
             IF n$ = \"yes\" THEN\n\
             PRINT \"match\"\n\
             ELSE\n\
             PRINT \"no\"\n\
             END IF\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_scmp.o");
        let exep = dir.join("xb_llvm_scmp.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "match\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_chr_builtin() {
        use std::io::Write;
        use std::process::Command;
        // CHR$(65) -> "A".
        let unit = FrontendUnit::parse("VERSION \"1\"\nPRINT CHR$(65)\n").unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_chr.o");
        let exep = dir.join("xb_llvm_chr.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "A\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_substring_builtins() {
        use std::io::Write;
        use std::process::Command;
        // LEFT$/RIGHT$/MID$ mirror the interpreter: "hello"/"world"/"world".
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM s$\n\
             s$ = \"hello world\"\n\
             PRINT LEFT$(s$, 5)\n\
             PRINT RIGHT$(s$, 5)\n\
             PRINT MID$(s$, 7, 5)\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_substr.o");
        let exep = dir.join("xb_llvm_substr.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "hello\nworld\nworld\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }
}
