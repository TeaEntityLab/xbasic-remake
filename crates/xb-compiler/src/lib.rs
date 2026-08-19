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
    use crate::checked::{ArithmeticOp, BooleanOp, ComparisonOp, LogicalOp, PrintSep};
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
            emit.emit_body(&program.items)?;
            if let Some(body) = entry_body(&program) {
                emit.emit_body(body)?;
            }
            emit.ret_default()?;
            emit.emit_function_bodies(&program.items)?;
            emit.object()
        }
    }

    /// State-machine context for a body containing labels/`GOSUB`/`GOTO`: a `pc`-dispatch
    /// loop (`switch` over one block per top-level item) plus a `GOSUB` return-index stack.
    /// `pc` = top-level item index (so computed `GOSUB`/`GOTO` by index work directly).
    struct SmCtx<'ctx> {
        dispatch: BasicBlock<'ctx>,
        pc: PointerValue<'ctx>,
        retstack: PointerValue<'ctx>,
        retsp: PointerValue<'ctx>,
        labels: HashMap<String, u64>,
        /// Resume pc pushed by a `GOSUB` in the current top-level item (= item index + 1).
        resume: u64,
        /// Number of top-level items (out-of-range pc → dispatch default → exit).
        count: u64,
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
        fmt_d: PointerValue<'ctx>,
        nl: PointerValue<'ctx>,
        tab: PointerValue<'ctx>,
        fmt_g: PointerValue<'ctx>,
        fmt_hex: PointerValue<'ctx>,
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
        memcpy: FunctionValue<'ctx>,
        snprintf: FunctionValue<'ctx>,
        memset: FunctionValue<'ctx>,
        putchar: FunctionValue<'ctx>,
        memcmp: FunctionValue<'ctx>,
        /// Array vars: name → (alloca holding the heap buffer ptr, element type,
        /// per-dimension count allocas as i64 — row-major shape). 1 dim entry = 1D.
        arrays: HashMap<String, (PointerValue<'ctx>, ValueType, Vec<PointerValue<'ctx>>)>,
        /// Set while emitting a label-bearing body; routes jumps to the dispatch block.
        sm: Option<SmCtx<'ctx>>,
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
            let memcpy = module.add_function(
                "memcpy",
                ptr.fn_type(&[ptr.into(), ptr.into(), i64t.into()], false),
                None,
            );
            let snprintf = module.add_function(
                "snprintf",
                i32t.fn_type(&[ptr.into(), i64t.into(), ptr.into()], true),
                None,
            );
            let memset = module.add_function(
                "memset",
                ptr.fn_type(&[ptr.into(), i32t.into(), i64t.into()], false),
                None,
            );
            let putchar = module.add_function("putchar", i32t.fn_type(&[i32t.into()], false), None);
            let memcmp = module.add_function(
                "memcmp",
                i32t.fn_type(&[ptr.into(), ptr.into(), i64t.into()], false),
                None,
            );
            let printf = module.add_function("printf", i32t.fn_type(&[ptr.into()], true), None);
            let main = module.add_function("main", i32t.fn_type(&[], false), None);
            builder.position_at_end(ctx.append_basic_block(main, "entry"));
            let g = |b: &Builder<'ctx>, s: &str, n: &str| -> Result<PointerValue<'ctx>, CompileError> {
                Ok(b.build_global_string_ptr(s, n).map_err(Self::err)?.as_pointer_value())
            };
            let fmt_d = g(&builder, "%d", "fmtd")?;
            let nl = g(&builder, "\n", "nl")?;
            let tab = g(&builder, "\t", "tab")?;
            let fmt_g = g(&builder, "%g", "fmtg")?;
            let fmt_hex = g(&builder, "%X", "fmthex")?;
            Ok(Self {
                ctx,
                module,
                builder,
                i32t,
                ptr,
                printf,
                fmt_d,
                nl,
                tab,
                f64t,
                fmt_g,
                fmt_hex,
                i64t,
                calloc,
                strlen,
                memcpy,
                snprintf,
                memset,
                putchar,
                memcmp,
                arrays: HashMap::new(),
                sm: None,
                vars: HashMap::new(),
                funcs: HashMap::new(),
                cur_fn: main,
                cur_ret: ValueType::Integer,
            })
        }

        /// Emit the module to a host-target object (assumes returns already built).
        fn object(self) -> Result<ObjectFile, CompileError> {
            // Reject invalid IR with a readable error instead of crashing LLVM codegen.
            if let Err(msg) = self.module.verify() {
                return Err(CompileError::Llvm(format!("invalid IR: {}", msg)));
            }
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

        /// GEP to element `name[index, extra_indices...]` via row-major Horner offset
        /// (mirrors `TypedSlot::array_offset`). `None` if `name` is not a known array.
        fn array_elem_ptr(
            &self,
            name: &str,
            index: &IrExpr,
            extra_indices: &[IrExpr],
        ) -> Result<Option<(PointerValue<'ctx>, ValueType)>, CompileError> {
            let Some((holder, elem, dims)) = self.arrays.get(name).cloned() else {
                return Ok(None);
            };
            let bufptr = self
                .builder
                .build_load(self.ptr, holder, "buf")
                .map_err(Self::err)?
                .into_pointer_value();
            // Evaluate every provided subscript (side effects match the interpreter),
            // sign-extended to i64.
            let mut idxs: Vec<IntValue<'ctx>> = Vec::new();
            for e in std::iter::once(index).chain(extra_indices.iter()) {
                let ik = self.eval_int(e)?;
                idxs.push(self.builder.build_int_s_extend(ik, self.i64t, "ik").map_err(Self::err)?);
            }
            // off = 0; for each recorded dim k: off = off*count_k + idx_k (missing idx -> 0).
            let mut off = self.i64t.const_zero();
            for (k, cslot) in dims.iter().enumerate() {
                let ck = self
                    .builder
                    .build_load(self.i64t, *cslot, "ck")
                    .map_err(Self::err)?
                    .into_int_value();
                let ik = idxs.get(k).copied().unwrap_or_else(|| self.i64t.const_zero());
                let m = self.builder.build_int_mul(off, ck, "offm").map_err(Self::err)?;
                off = self.builder.build_int_add(m, ik, "offa").map_err(Self::err)?;
            }
            let ety = self.llvm_type(elem);
            let ep = unsafe {
                self.builder
                    .build_in_bounds_gep(ety, bufptr, &[off], "elem")
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
            f: FunctionValue<'ctx>,
            args: &[IrExpr],
        ) -> Result<Option<Vec<BasicMetadataValueEnum<'ctx>>>, CompileError> {
            // Coerce each argument to the callee's declared parameter type and reconcile
            // arity (pad missing with zeros, drop extras) so the call is valid IR even when
            // the source passes mismatched types/counts.
            let ptypes = f.get_type().get_param_types();
            let mut argv = Vec::with_capacity(ptypes.len());
            for (i, target) in ptypes.iter().enumerate() {
                let v = if i < args.len() {
                    match self.eval_value(&args[i])? {
                        Some(v) => self.coerce_to(v, *target)?,
                        None => return Ok(None),
                    }
                } else {
                    self.zero_of(*target)
                };
                argv.push(v.into());
            }
            Ok(Some(argv))
        }

        /// Zero/default value of a parameter type (for padding missing arguments).
        fn zero_of(&self, target: BasicMetadataTypeEnum<'ctx>) -> BasicValueEnum<'ctx> {
            match target {
                BasicMetadataTypeEnum::FloatType(_) => self.f64t.const_zero().into(),
                BasicMetadataTypeEnum::PointerType(_) => self.ptr.const_null().into(),
                _ => self.i32t.const_zero().into(),
            }
        }

        /// Coerce a value to a parameter type (int↔float promotion; else pass-through or
        /// zero on an incompatible kind), so calls always match the callee signature.
        fn coerce_to(
            &self,
            v: BasicValueEnum<'ctx>,
            target: BasicMetadataTypeEnum<'ctx>,
        ) -> Result<BasicValueEnum<'ctx>, CompileError> {
            Ok(match target {
                BasicMetadataTypeEnum::IntType(_) => match v {
                    BasicValueEnum::IntValue(iv) => iv.into(),
                    BasicValueEnum::FloatValue(fv) => self
                        .builder
                        .build_float_to_signed_int(fv, self.i32t, "f2i")
                        .map_err(Self::err)?
                        .into(),
                    _ => self.i32t.const_zero().into(),
                },
                BasicMetadataTypeEnum::FloatType(_) => match v {
                    BasicValueEnum::FloatValue(fv) => fv.into(),
                    BasicValueEnum::IntValue(iv) => self
                        .builder
                        .build_signed_int_to_float(iv, self.f64t, "i2f")
                        .map_err(Self::err)?
                        .into(),
                    _ => self.f64t.const_zero().into(),
                },
                BasicMetadataTypeEnum::PointerType(_) => match v {
                    BasicValueEnum::PointerValue(pv) => pv.into(),
                    _ => self.ptr.const_null().into(),
                },
                _ => v,
            })
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
                    let saved_arrays = std::mem::take(&mut self.arrays);
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
                    self.emit_body(body)?;
                    self.ret_default()?;
                    self.vars = saved_vars;
                    self.arrays = saved_arrays;
                    self.cur_fn = saved_fn;
                    self.cur_ret = saved_ret;
                }
            }
            Ok(())
        }

        /// Allocate in the function's entry block, which dominates every block — required
        /// for variables/arrays whose uses span state-machine dispatch blocks.
        fn entry_alloca(
            &self,
            ty: BasicTypeEnum<'ctx>,
            name: &str,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            let entry = self
                .cur_fn
                .get_first_basic_block()
                .ok_or_else(|| CompileError::Llvm("function has no entry block".into()))?;
            let b = self.ctx.create_builder();
            match entry.get_first_instruction() {
                Some(inst) => b.position_before(&inst),
                None => b.position_at_end(entry),
            }
            b.build_alloca(ty, name).map_err(Self::err)
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
            let s = self.entry_alloca(ty, name)?;
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
                // A jump (SM GOTO/GOSUB/RETURN) or function return terminates the block;
                // the remaining items are unreachable — stop so we never build past a
                // terminator (invalid IR).
                if self.builder.get_insert_block().and_then(|b| b.get_terminator()).is_some() {
                    break;
                }
            }
            Ok(())
        }

        /// Emit a body: a `pc`-dispatch state machine for label-bearing bodies whose
        /// GOSUBs are all top-level (resume pc is then correct); otherwise the
        /// straight-line path. Nested GOSUB can't get a correct top-level resume pc, so
        /// such bodies fall back to linear emission (jumps lower to no-ops, matching the
        /// backend's "unsupported → no-op" convention — divergence is caught by the
        /// differential, never silently claimed correct) rather than the SM.
        fn emit_body(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            if body_has_labels(items) && !has_nested_gosub(items) {
                self.emit_body_sm(items)
            } else {
                self.emit_items(items)
            }
        }

        /// State-machine emission for a label-bearing body: one block per top-level item,
        /// dispatched by a `pc` switch; GOSUB/GOTO/RETURN set `pc` and re-dispatch
        /// (mirrors the interpreter's index-based `exec_items`). Leaves the builder at the
        /// exit block so the caller can build the function return.
        fn emit_body_sm(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            let n = items.len() as u64;
            let mut labels: HashMap<String, u64> = HashMap::new();
            for (i, it) in items.iter().enumerate() {
                if let IrItem::Label(name) = it {
                    labels.insert(name.clone(), i as u64);
                }
            }
            let pc = self.builder.build_alloca(self.i32t, "pc").map_err(Self::err)?;
            self.builder.build_store(pc, self.i32t.const_zero()).map_err(Self::err)?;
            let retstack = self
                .builder
                .build_array_alloca(self.i32t, self.i32t.const_int(256, false), "retstack")
                .map_err(Self::err)?;
            let retsp = self.builder.build_alloca(self.i32t, "retsp").map_err(Self::err)?;
            self.builder.build_store(retsp, self.i32t.const_zero()).map_err(Self::err)?;
            let dispatch = self.ctx.append_basic_block(self.cur_fn, "sm.dispatch");
            let exit = self.ctx.append_basic_block(self.cur_fn, "sm.exit");
            let blocks: Vec<BasicBlock<'ctx>> = (0..items.len())
                .map(|i| self.ctx.append_basic_block(self.cur_fn, &format!("sm.pc{i}")))
                .collect();
            let saved = self.sm.take();
            self.sm = Some(SmCtx { dispatch, pc, retstack, retsp, labels, resume: 0, count: n });
            self.builder.build_unconditional_branch(dispatch).map_err(Self::err)?;
            self.builder.position_at_end(dispatch);
            let pcv = self.builder.build_load(self.i32t, pc, "pcv").map_err(Self::err)?.into_int_value();
            let cases: Vec<(IntValue<'ctx>, BasicBlock<'ctx>)> = blocks
                .iter()
                .enumerate()
                .map(|(i, b)| (self.i32t.const_int(i as u64, false), *b))
                .collect();
            self.builder.build_switch(pcv, exit, &cases).map_err(Self::err)?;
            for (i, it) in items.iter().enumerate() {
                self.builder.position_at_end(blocks[i]);
                if let Some(ctx) = self.sm.as_mut() {
                    ctx.resume = i as u64 + 1;
                }
                self.emit_item(it)?;
                let open = self
                    .builder
                    .get_insert_block()
                    .and_then(|b| b.get_terminator())
                    .is_none();
                if open {
                    self.builder
                        .build_store(pc, self.i32t.const_int(i as u64 + 1, false))
                        .map_err(Self::err)?;
                    self.builder.build_unconditional_branch(dispatch).map_err(Self::err)?;
                }
            }
            self.builder.position_at_end(exit);
            self.sm = saved;
            Ok(())
        }

        fn emit_item(&mut self, item: &IrItem) -> Result<(), CompileError> {
            match item {
                IrItem::Dim { symbol, is_array: false, .. } => {
                    let slot = self.get_or_alloca(&symbol.name, symbol.value_type)?;
                    let init: BasicValueEnum = match symbol.value_type {
                        ValueType::String => self.str_const(b"")?.into(),
                        ValueType::Float => self.f64t.const_zero().into(),
                        _ => self.i32t.const_zero().into(),
                    };
                    self.builder.build_store(slot, init).map_err(Self::err)?;
                }
                IrItem::Dim { symbol, size, extra_dims, is_array: true, .. } => {
                    let elem = symbol.value_type;
                    let esz: u64 = match elem {
                        ValueType::Float | ValueType::String => 8,
                        _ => 4,
                    };
                    // Per-dimension counts n_k = max(0, size_k) + 1 (inclusive upper
                    // bound), mirroring the interpreter; total = product of counts.
                    let mut counts: Vec<IntValue<'ctx>> = Vec::new();
                    for e in size.iter().chain(extra_dims.iter()) {
                        let raw = self.eval_int(e)?;
                        let pos = self
                            .builder
                            .build_int_compare(IntPredicate::SGT, raw, self.i32t.const_zero(), "pos")
                            .map_err(Self::err)?;
                        let nn = self
                            .builder
                            .build_select(pos, raw, self.i32t.const_zero(), "max0")
                            .map_err(Self::err)?
                            .into_int_value();
                        let nn64 =
                            self.builder.build_int_s_extend(nn, self.i64t, "nn64").map_err(Self::err)?;
                        let cnt = self
                            .builder
                            .build_int_add(nn64, self.i64t.const_int(1, false), "cnt")
                            .map_err(Self::err)?;
                        counts.push(cnt);
                    }
                    // Total = product of counts; empty (unsized `DIM a[]`) → 0 elements,
                    // matching the interpreter (a later REDIM sets the real shape).
                    let mut total = if counts.is_empty() {
                        self.i64t.const_zero()
                    } else {
                        self.i64t.const_int(1, false)
                    };
                    for c in &counts {
                        total = self.builder.build_int_mul(total, *c, "tot").map_err(Self::err)?;
                    }
                    let buf = self
                        .builder
                        .build_call(
                            self.calloc,
                            &[total.into(), self.i64t.const_int(esz, false).into()],
                            "arr",
                        )
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                        .into_pointer_value();
                    // Persist the shape: one i64 alloca per dim holding the count.
                    let mut shape: Vec<PointerValue<'ctx>> = Vec::with_capacity(counts.len());
                    for (k, c) in counts.iter().enumerate() {
                        let s = self.entry_alloca(self.i64t.into(), &format!("{}_d{k}", symbol.name))?;
                        self.builder.build_store(s, *c).map_err(Self::err)?;
                        shape.push(s);
                    }
                    let existing = self.arrays.get(&symbol.name).map(|(h, _, _)| *h);
                    let holder = match existing {
                        Some(h) => h,
                        None => {
                            self.entry_alloca(self.ptr.into(), &symbol.name)?
                        }
                    };
                    self.builder.build_store(holder, buf).map_err(Self::err)?;
                    self.arrays.insert(symbol.name.clone(), (holder, elem, shape));
                }
                IrItem::Assignment { target, value } => {
                    if let Some(v) = self.eval_value(value)? {
                        let slot = self.get_or_alloca(&target.name, target.value_type)?;
                        self.builder.build_store(slot, v).map_err(Self::err)?;
                    }
                }
                IrItem::ArrayAssignment { target, index, extra_indices, value } => {
                    if let (Some(v), Some((ep, _))) = (
                        self.eval_value(value)?,
                        self.array_elem_ptr(&target.name, index, extra_indices)?,
                    ) {
                        self.builder.build_store(ep, v).map_err(Self::err)?;
                    }
                }
                IrItem::Print { items, separators } => {
                    for (i, e) in items.iter().enumerate() {
                        // Comma separator = a tab (matches exec_print); semicolon = nothing.
                        if i > 0 {
                            if let Some(PrintSep::Comma) = separators.get(i - 1) {
                                self.builder
                                    .build_call(self.printf, &[self.tab.into()], "")
                                    .map_err(Self::err)?;
                            }
                        }
                        match self.eval_value(e)? {
                            Some(BasicValueEnum::IntValue(iv)) => {
                                self.builder
                                    .build_call(self.printf, &[self.fmt_d.into(), iv.into()], "")
                                    .map_err(Self::err)?;
                            }
                            Some(BasicValueEnum::PointerValue(pv)) => self.str_print(pv)?,
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
                    // Emit the increment + back-edge only if the body fell through; a
                    // RETURN/GOTO in the body terminates the block (the back-edge would be
                    // unreachable, and appending past a terminator is invalid IR).
                    if self.builder.get_insert_block().and_then(|b| b.get_terminator()).is_none() {
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
                    }
                    self.builder.position_at_end(exit);
                }
                IrItem::Compound(items) => self.emit_items(items)?,
                IrItem::SelectCase { selector, cases, default } => {
                    // Equality chain matching exec_select_case (first matching CASE wins).
                    if let Some(sel) = self.eval_value(selector)? {
                        let done = self.ctx.append_basic_block(self.cur_fn, "select.done");
                        for case in cases {
                            for cond in &case.conditions {
                                let Some(cv) = self.eval_value(cond)? else { continue };
                                let eq = self.values_equal(sel, cv)?;
                                let body_bb = self.ctx.append_basic_block(self.cur_fn, "case.body");
                                let next_bb = self.ctx.append_basic_block(self.cur_fn, "case.next");
                                self.builder
                                    .build_conditional_branch(eq, body_bb, next_bb)
                                    .map_err(Self::err)?;
                                self.builder.position_at_end(body_bb);
                                self.emit_items(&case.body)?;
                                self.branch_to(done)?;
                                self.builder.position_at_end(next_bb);
                            }
                        }
                        if let Some(def) = default {
                            self.emit_items(def)?;
                        }
                        self.branch_to(done)?;
                        self.builder.position_at_end(done);
                    }
                }
                IrItem::Return { value } => {
                    if self
                        .builder
                        .get_insert_block()
                        .and_then(|b| b.get_terminator())
                        .is_none()
                    {
                        let rv: BasicValueEnum = match (value, self.cur_ret) {
                            (Some(e), ValueType::String) => match self.eval_value(e)? {
                                Some(v) => v,
                                None => self.str_const(b"")?.into(),
                            },
                            (Some(e), ValueType::Float) => self.eval_float(e)?.into(),
                            (Some(e), _) => self.eval_int(e)?.into(),
                            (None, ValueType::String) => self.str_const(b"")?.into(),
                            (None, ValueType::Float) => self.f64t.const_zero().into(),
                            (None, _) => self.i32t.const_zero().into(),
                        };
                        self.builder.build_return(Some(&rv)).map_err(Self::err)?;
                    }
                }
                IrItem::Call { name, args } => {
                    if let Some(&f) = self.funcs.get(name) {
                        if let Some(argv) = self.eval_args(f, args)? {
                            self.builder.build_call(f, &argv, "call").map_err(Self::err)?;
                        }
                    }
                }
                // Label/GOSUB/GOTO items: no-ops unless emitting a state-machine body,
                // where they manipulate `pc` and branch to the dispatch block.
                IrItem::Label(_) => {}
                IrItem::Goto(name) => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc, count) = (ctx.dispatch, ctx.pc, ctx.count);
                        let target = ctx.labels.get(name).copied().unwrap_or(count);
                        self.builder
                            .build_store(pc, self.i32t.const_int(target, false))
                            .map_err(Self::err)?;
                        self.builder.build_unconditional_branch(dispatch).map_err(Self::err)?;
                    }
                }
                IrItem::GotoExpr(expr) => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc) = (ctx.dispatch, ctx.pc);
                        let target = self.eval_int(expr)?;
                        self.builder.build_store(pc, target).map_err(Self::err)?;
                        self.builder.build_unconditional_branch(dispatch).map_err(Self::err)?;
                    }
                }
                IrItem::Gosub(name) => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc, retstack, retsp, resume, count) =
                            (ctx.dispatch, ctx.pc, ctx.retstack, ctx.retsp, ctx.resume, ctx.count);
                        let target = ctx.labels.get(name).copied().unwrap_or(count);
                        self.sm_push(retstack, retsp, resume)?;
                        self.builder
                            .build_store(pc, self.i32t.const_int(target, false))
                            .map_err(Self::err)?;
                        self.builder.build_unconditional_branch(dispatch).map_err(Self::err)?;
                    }
                }
                IrItem::GosubExpr(expr) => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc, retstack, retsp, resume) =
                            (ctx.dispatch, ctx.pc, ctx.retstack, ctx.retsp, ctx.resume);
                        let target = self.eval_int(expr)?;
                        self.sm_push(retstack, retsp, resume)?;
                        self.builder.build_store(pc, target).map_err(Self::err)?;
                        self.builder.build_unconditional_branch(dispatch).map_err(Self::err)?;
                    }
                }
                IrItem::GosubReturn => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc, retstack, retsp, count) =
                            (ctx.dispatch, ctx.pc, ctx.retstack, ctx.retsp, ctx.count);
                        // Pop the return-index stack (branchless): empty → exit (pc = count).
                        let sp = self
                            .builder
                            .build_load(self.i32t, retsp, "sp")
                            .map_err(Self::err)?
                            .into_int_value();
                        let ne = self
                            .builder
                            .build_int_compare(IntPredicate::UGT, sp, self.i32t.const_zero(), "ne")
                            .map_err(Self::err)?;
                        let spm1 = self
                            .builder
                            .build_int_sub(sp, self.i32t.const_int(1, false), "spm1")
                            .map_err(Self::err)?;
                        let newsp =
                            self.builder.build_select(ne, spm1, sp, "nsp").map_err(Self::err)?.into_int_value();
                        self.builder.build_store(retsp, newsp).map_err(Self::err)?;
                        let slot = unsafe {
                            self.builder
                                .build_in_bounds_gep(self.i32t, retstack, &[newsp], "rslot")
                                .map_err(Self::err)?
                        };
                        let idx = self.builder.build_load(self.i32t, slot, "ridx").map_err(Self::err)?.into_int_value();
                        let target = self
                            .builder
                            .build_select(ne, idx, self.i32t.const_int(count, false), "rpc")
                            .map_err(Self::err)?
                            .into_int_value();
                        self.builder.build_store(pc, target).map_err(Self::err)?;
                        self.builder.build_unconditional_branch(dispatch).map_err(Self::err)?;
                    }
                }
                _ => {}
            }
            Ok(())
        }

        /// Push a return index onto the state-machine GOSUB stack.
        fn sm_push(
            &self,
            retstack: PointerValue<'ctx>,
            retsp: PointerValue<'ctx>,
            v: u64,
        ) -> Result<(), CompileError> {
            let sp = self.builder.build_load(self.i32t, retsp, "psp").map_err(Self::err)?.into_int_value();
            let slot = unsafe {
                self.builder
                    .build_in_bounds_gep(self.i32t, retstack, &[sp], "pslot")
                    .map_err(Self::err)?
            };
            self.builder
                .build_store(slot, self.i32t.const_int(v, false))
                .map_err(Self::err)?;
            let sp1 = self.builder.build_int_add(sp, self.i32t.const_int(1, false), "psp1").map_err(Self::err)?;
            self.builder.build_store(retsp, sp1).map_err(Self::err)?;
            Ok(())
        }

        /// Evaluate a condition to `i1` (nonzero = true) for a branch.
        fn eval_bool(&self, expr: &IrExpr) -> Result<IntValue<'ctx>, CompileError> {
            let v = self.eval_int(expr)?;
            self.builder
                .build_int_compare(IntPredicate::NE, v, self.i32t.const_zero(), "cond")
                .map_err(Self::err)
        }

        /// i1: XBasic equality of two evaluated values (int/float direct, string via `str_cmp`).
        fn values_equal(
            &self,
            a: BasicValueEnum<'ctx>,
            b: BasicValueEnum<'ctx>,
        ) -> Result<IntValue<'ctx>, CompileError> {
            match (a, b) {
                (BasicValueEnum::IntValue(x), BasicValueEnum::IntValue(y)) => {
                    self.builder.build_int_compare(IntPredicate::EQ, x, y, "seq").map_err(Self::err)
                }
                (BasicValueEnum::FloatValue(x), BasicValueEnum::FloatValue(y)) => self
                    .builder
                    .build_float_compare(FloatPredicate::OEQ, x, y, "sfeq")
                    .map_err(Self::err),
                (BasicValueEnum::PointerValue(x), BasicValueEnum::PointerValue(y)) => {
                    let r = self.str_cmp(x, y)?;
                    self.builder
                        .build_int_compare(IntPredicate::EQ, r, self.i32t.const_zero(), "seq0")
                        .map_err(Self::err)
                }
                _ => Ok(self.ctx.bool_type().const_zero()),
            }
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
                IrExprKind::StringLiteral(s) => Some(self.str_const(s.as_bytes())?.into()),
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
                    if matches!(op, ArithmeticOp::Add)
                        && (expr.value_type == ValueType::String
                            || left.value_type == ValueType::String
                            || right.value_type == ValueType::String)
                    {
                        let (
                            Some(BasicValueEnum::PointerValue(a)),
                            Some(BasicValueEnum::PointerValue(b)),
                        ) = (self.eval_value(left)?, self.eval_value(right)?)
                        else {
                            return Ok(None);
                        };
                        let la = self.str_len(a)?;
                        let lb = self.str_len(b)?;
                        let total = self.builder.build_int_add(la, lb, "cclen").map_err(Self::err)?;
                        let buf = self.str_new(total)?;
                        self.builder
                            .build_call(self.memcpy, &[buf.into(), a.into(), la.into()], "cp1")
                            .map_err(Self::err)?;
                        let off = unsafe {
                            self.builder
                                .build_in_bounds_gep(self.ctx.i8_type(), buf, &[la], "ccoff")
                                .map_err(Self::err)?
                        };
                        self.builder
                            .build_call(self.memcpy, &[off.into(), b.into(), lb.into()], "cp2")
                            .map_err(Self::err)?;
                        return Ok(Some(buf.into()));
                    }
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
                            ArithmeticOp::IntegerDiv => {
                                self.builder.build_int_signed_div(a, b, "idiv")
                            }
                            ArithmeticOp::Mod => self.builder.build_int_signed_rem(a, b, "mod"),
                            ArithmeticOp::Shl => {
                                let m = self
                                    .builder
                                    .build_and(b, self.i32t.const_int(31, false), "shlm")
                                    .map_err(Self::err)?;
                                self.builder.build_left_shift(a, m, "shl")
                            }
                            ArithmeticOp::Shr => {
                                let m = self
                                    .builder
                                    .build_and(b, self.i32t.const_int(31, false), "shrm")
                                    .map_err(Self::err)?;
                                self.builder.build_right_shift(a, m, true, "shr")
                            }
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
                        let r = self.str_cmp(a, b)?;
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
                    let Some(argv) = self.eval_args(f, args)? else {
                        return Ok(None);
                    };
                    self.builder
                        .build_call(f, &argv, "call")
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                }
                IrExprKind::ArrayAccess { symbol, index, extra_indices } => {
                    match self.array_elem_ptr(&symbol.name, index, extra_indices)? {
                        Some((ep, elem)) => Some(
                            self.builder
                                .build_load(self.llvm_type(elem), ep, "ai")
                                .map_err(Self::err)?,
                        ),
                        None => None,
                    }
                }
                IrExprKind::ArrayUBound { symbol } => {
                    // Array: flat length − 1; string var: LEN − 1; else −1 (matches
                    // eval.rs ArrayUBound so `FOR i = 0 TO UBOUND(a)` iterates identically).
                    if let Some((_, _, dims)) = self.arrays.get(&symbol.name).cloned() {
                        let mut total = if dims.is_empty() {
                            self.i64t.const_zero()
                        } else {
                            self.i64t.const_int(1, false)
                        };
                        for cslot in &dims {
                            let c = self
                                .builder
                                .build_load(self.i64t, *cslot, "c")
                                .map_err(Self::err)?
                                .into_int_value();
                            total = self.builder.build_int_mul(total, c, "t").map_err(Self::err)?;
                        }
                        let m1 = self
                            .builder
                            .build_int_sub(total, self.i64t.const_int(1, false), "ub")
                            .map_err(Self::err)?;
                        Some(self.builder.build_int_truncate(m1, self.i32t, "ub32").map_err(Self::err)?.into())
                    } else if let Some((slot, ValueType::String)) =
                        self.vars.get(&symbol.name).copied()
                    {
                        let sptr = self
                            .builder
                            .build_load(self.ptr, slot, "s")
                            .map_err(Self::err)?
                            .into_pointer_value();
                        let len = self.str_len(sptr)?;
                        let m1 = self
                            .builder
                            .build_int_sub(len, self.i64t.const_int(1, false), "ub")
                            .map_err(Self::err)?;
                        Some(self.builder.build_int_truncate(m1, self.i32t, "ub32").map_err(Self::err)?.into())
                    } else {
                        Some(self.i32t.const_int((-1i32) as u64, true).into())
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

        /// Length of a byte-string, from the i64 prefix at `s - 8`.
        fn str_len(&self, s: PointerValue<'ctx>) -> Result<IntValue<'ctx>, CompileError> {
            let neg1 = self.i64t.const_int((-1i64) as u64, true);
            let lenp = unsafe {
                self.builder
                    .build_in_bounds_gep(self.i64t, s, &[neg1], "lenp")
                    .map_err(Self::err)?
            };
            Ok(self.builder.build_load(self.i64t, lenp, "slen").map_err(Self::err)?.into_int_value())
        }

        /// `strcmp`-like i32 (<0/0/>0) for byte-strings: unsigned byte-lexicographic with a
        /// length tiebreak, matching Rust `Vec<u8>`/`str` ordering (shorter prefix is less).
        fn str_cmp(&self, a: PointerValue<'ctx>, b: PointerValue<'ctx>) -> Result<IntValue<'ctx>, CompileError> {
            let la = self.str_len(a)?;
            let lb = self.str_len(b)?;
            let m = self.umin(la, lb)?;
            let r = self
                .builder
                .build_call(self.memcmp, &[a.into(), b.into(), m.into()], "mcmp")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("memcmp returned void".into()))?
                .into_int_value();
            let llt = self.builder.build_int_compare(IntPredicate::ULT, la, lb, "llt").map_err(Self::err)?;
            let lgt = self.builder.build_int_compare(IntPredicate::UGT, la, lb, "lgt").map_err(Self::err)?;
            let neg1 = self.i32t.const_int((-1i64) as u64, true);
            let one = self.i32t.const_int(1, false);
            let hi = self.builder.build_select(lgt, one, self.i32t.const_zero(), "lhi").map_err(Self::err)?.into_int_value();
            let dif = self.builder.build_select(llt, neg1, hi, "ldif").map_err(Self::err)?.into_int_value();
            let rnz = self.builder.build_int_compare(IntPredicate::NE, r, self.i32t.const_zero(), "rnz").map_err(Self::err)?;
            Ok(self.builder.build_select(rnz, r, dif, "scmpsel").map_err(Self::err)?.into_int_value())
        }

        /// Allocate a zeroed byte-string of `len` bytes; returns the data pointer, with the
        /// i64 length in the 8-byte prefix and a trailing NUL (for C interop).
        fn str_new(&self, len: IntValue<'ctx>) -> Result<PointerValue<'ctx>, CompileError> {
            let total = self
                .builder
                .build_int_add(len, self.i64t.const_int(9, false), "stot")
                .map_err(Self::err)?;
            let base = self
                .builder
                .build_call(
                    self.calloc,
                    &[total.into(), self.i64t.const_int(1, false).into()],
                    "sbase",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                .into_pointer_value();
            self.builder.build_store(base, len).map_err(Self::err)?;
            let data = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), base, &[self.i64t.const_int(8, false)], "sdata")
                    .map_err(Self::err)?
            };
            Ok(data)
        }

        /// A global length-prefixed byte-string constant; returns its data pointer.
        fn str_const(&self, bytes: &[u8]) -> Result<PointerValue<'ctx>, CompileError> {
            let i8t = self.ctx.i8_type();
            let mut raw: Vec<u8> = (bytes.len() as u64).to_le_bytes().to_vec();
            raw.extend_from_slice(bytes);
            raw.push(0);
            let vals: Vec<_> = raw.iter().map(|b| i8t.const_int(*b as u64, false)).collect();
            let arr = i8t.const_array(&vals);
            let g = self.module.add_global(arr.get_type(), None, "bsc");
            g.set_initializer(&arr);
            g.set_constant(true);
            let data = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, g.as_pointer_value(), &[self.i64t.const_int(8, false)], "scd")
                    .map_err(Self::err)?
            };
            Ok(data)
        }

        /// Byte-string copy of a NUL-terminated C string (its length via libc `strlen`).
        /// Safe only for C strings with no embedded NUL (e.g. `snprintf` numeric output).
        fn str_from_cstr(&self, c: PointerValue<'ctx>) -> Result<PointerValue<'ctx>, CompileError> {
            let clen = self
                .builder
                .build_call(self.strlen, &[c.into()], "clen")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("strlen returned void".into()))?
                .into_int_value();
            self.str_copy(c, self.i64t.const_zero(), clen)
        }

        /// `snprintf(fmt, iv)` into a scratch buffer, returned as a byte-string.
        fn str_from_int(&self, fmt: PointerValue<'ctx>, iv: IntValue<'ctx>) -> Result<PointerValue<'ctx>, CompileError> {
            let tmp = self
                .builder
                .build_call(
                    self.calloc,
                    &[self.i64t.const_int(24, false).into(), self.i64t.const_int(1, false).into()],
                    "numbuf",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                .into_pointer_value();
            self.builder
                .build_call(
                    self.snprintf,
                    &[tmp.into(), self.i64t.const_int(24, false).into(), fmt.into(), iv.into()],
                    "num",
                )
                .map_err(Self::err)?;
            self.str_from_cstr(tmp)
        }

        /// Write a byte-string to stdout via a `putchar` loop over its length (handles
        /// embedded NULs; shares libc's stdout buffer with `printf` so ordering is kept).
        fn str_print(&self, s: PointerValue<'ctx>) -> Result<(), CompileError> {
            let len = self.str_len(s)?;
            let idx = self.builder.build_alloca(self.i64t, "pi").map_err(Self::err)?;
            self.builder.build_store(idx, self.i64t.const_zero()).map_err(Self::err)?;
            let head = self.ctx.append_basic_block(self.cur_fn, "sp.head");
            let body = self.ctx.append_basic_block(self.cur_fn, "sp.body");
            let exit = self.ctx.append_basic_block(self.cur_fn, "sp.exit");
            self.builder.build_unconditional_branch(head).map_err(Self::err)?;
            self.builder.position_at_end(head);
            let iv = self.builder.build_load(self.i64t, idx, "pv").map_err(Self::err)?.into_int_value();
            let cont = self
                .builder
                .build_int_compare(IntPredicate::ULT, iv, len, "plt")
                .map_err(Self::err)?;
            self.builder.build_conditional_branch(cont, body, exit).map_err(Self::err)?;
            self.builder.position_at_end(body);
            let ep = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), s, &[iv], "pep")
                    .map_err(Self::err)?
            };
            let c = self.builder.build_load(self.ctx.i8_type(), ep, "pc").map_err(Self::err)?.into_int_value();
            let ci = self.builder.build_int_z_extend(c, self.i32t, "pci").map_err(Self::err)?;
            self.builder.build_call(self.putchar, &[ci.into()], "pch").map_err(Self::err)?;
            let next = self.builder.build_int_add(iv, self.i64t.const_int(1, false), "pn").map_err(Self::err)?;
            self.builder.build_store(idx, next).map_err(Self::err)?;
            self.builder.build_unconditional_branch(head).map_err(Self::err)?;
            self.builder.position_at_end(exit);
            Ok(())
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

        /// Allocate a byte-string = `len` bytes copied from `src + off`.
        fn str_copy(
            &self,
            src: PointerValue<'ctx>,
            off: IntValue<'ctx>,
            len: IntValue<'ctx>,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            let buf = self.str_new(len)?;
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

        /// `SPACE$(n)`: a byte-string of `n` spaces.
        fn str_space(&self, n: IntValue<'ctx>) -> Result<PointerValue<'ctx>, CompileError> {
            let n64 = self.builder.build_int_s_extend(n, self.i64t, "n64").map_err(Self::err)?;
            let buf = self.str_new(n64)?;
            self.builder
                .build_call(
                    self.memset,
                    &[buf.into(), self.i32t.const_int(b' ' as u64, false).into(), n64.into()],
                    "ms",
                )
                .map_err(Self::err)?;
            Ok(buf)
        }

        /// i1: is `c` (i8) ASCII whitespace — space/tab/LF/CR/FF (matches `is_ascii_whitespace`).
        fn is_ws(&self, c: IntValue<'ctx>) -> Result<IntValue<'ctx>, CompileError> {
            let i8t = self.ctx.i8_type();
            let mut acc: Option<IntValue<'ctx>> = None;
            for w in [32u64, 9, 10, 13, 12] {
                let eq = self
                    .builder
                    .build_int_compare(IntPredicate::EQ, c, i8t.const_int(w, false), "weq")
                    .map_err(Self::err)?;
                acc = Some(match acc {
                    None => eq,
                    Some(a) => self.builder.build_or(a, eq, "wor").map_err(Self::err)?,
                });
            }
            Ok(acc.unwrap())
        }

        /// `UCASE$`/`LCASE$`: ASCII case fold each byte in a fresh copy.
        fn str_case(&self, s: PointerValue<'ctx>, upper: bool) -> Result<PointerValue<'ctx>, CompileError> {
            let len = self.str_len(s)?;
            let buf = self.str_copy(s, self.i64t.const_zero(), len)?;
            let i8t = self.ctx.i8_type();
            let idx = self.builder.build_alloca(self.i64t, "ci").map_err(Self::err)?;
            self.builder.build_store(idx, self.i64t.const_zero()).map_err(Self::err)?;
            let head = self.ctx.append_basic_block(self.cur_fn, "case.head");
            let body = self.ctx.append_basic_block(self.cur_fn, "case.body");
            let exit = self.ctx.append_basic_block(self.cur_fn, "case.exit");
            self.builder.build_unconditional_branch(head).map_err(Self::err)?;
            self.builder.position_at_end(head);
            let iv = self.builder.build_load(self.i64t, idx, "i").map_err(Self::err)?.into_int_value();
            let cont = self.builder.build_int_compare(IntPredicate::ULT, iv, len, "lt").map_err(Self::err)?;
            self.builder.build_conditional_branch(cont, body, exit).map_err(Self::err)?;
            self.builder.position_at_end(body);
            let ep = unsafe {
                self.builder.build_in_bounds_gep(i8t, buf, &[iv], "cp").map_err(Self::err)?
            };
            let c = self.builder.build_load(i8t, ep, "c").map_err(Self::err)?.into_int_value();
            let (lo, hi, delta) = if upper { (b'a', b'z', -32i64) } else { (b'A', b'Z', 32i64) };
            let ge = self
                .builder
                .build_int_compare(IntPredicate::UGE, c, i8t.const_int(lo as u64, false), "ge")
                .map_err(Self::err)?;
            let le = self
                .builder
                .build_int_compare(IntPredicate::ULE, c, i8t.const_int(hi as u64, false), "le")
                .map_err(Self::err)?;
            let inr = self.builder.build_and(ge, le, "inr").map_err(Self::err)?;
            let sh = self
                .builder
                .build_int_add(c, i8t.const_int(delta as u64, true), "sh")
                .map_err(Self::err)?;
            let nc = self.builder.build_select(inr, sh, c, "nc").map_err(Self::err)?.into_int_value();
            self.builder.build_store(ep, nc).map_err(Self::err)?;
            let next = self.builder.build_int_add(iv, self.i64t.const_int(1, false), "inc").map_err(Self::err)?;
            self.builder.build_store(idx, next).map_err(Self::err)?;
            self.builder.build_unconditional_branch(head).map_err(Self::err)?;
            self.builder.position_at_end(exit);
            Ok(buf)
        }

        /// `TRIM$`/`LTRIM$`/`RTRIM$`: strip ASCII whitespace (matches `byte_trim`).
        fn str_trim(&self, s: PointerValue<'ctx>, left: bool, right: bool) -> Result<PointerValue<'ctx>, CompileError> {
            let len = self.str_len(s)?;
            let i8t = self.ctx.i8_type();
            let a = self.builder.build_alloca(self.i64t, "ta").map_err(Self::err)?;
            self.builder.build_store(a, self.i64t.const_zero()).map_err(Self::err)?;
            let b = self.builder.build_alloca(self.i64t, "tb").map_err(Self::err)?;
            self.builder.build_store(b, len).map_err(Self::err)?;
            if left {
                let head = self.ctx.append_basic_block(self.cur_fn, "lt.head");
                let chk = self.ctx.append_basic_block(self.cur_fn, "lt.chk");
                let adv = self.ctx.append_basic_block(self.cur_fn, "lt.adv");
                let done = self.ctx.append_basic_block(self.cur_fn, "lt.done");
                self.builder.build_unconditional_branch(head).map_err(Self::err)?;
                self.builder.position_at_end(head);
                let av = self.builder.build_load(self.i64t, a, "av").map_err(Self::err)?.into_int_value();
                let c1 = self.builder.build_int_compare(IntPredicate::ULT, av, len, "c1").map_err(Self::err)?;
                self.builder.build_conditional_branch(c1, chk, done).map_err(Self::err)?;
                self.builder.position_at_end(chk);
                let ea = unsafe { self.builder.build_in_bounds_gep(i8t, s, &[av], "ea").map_err(Self::err)? };
                let ca = self.builder.build_load(i8t, ea, "ca").map_err(Self::err)?.into_int_value();
                let w = self.is_ws(ca)?;
                self.builder.build_conditional_branch(w, adv, done).map_err(Self::err)?;
                self.builder.position_at_end(adv);
                let ap1 = self.builder.build_int_add(av, self.i64t.const_int(1, false), "ap1").map_err(Self::err)?;
                self.builder.build_store(a, ap1).map_err(Self::err)?;
                self.builder.build_unconditional_branch(head).map_err(Self::err)?;
                self.builder.position_at_end(done);
            }
            if right {
                let head = self.ctx.append_basic_block(self.cur_fn, "rt.head");
                let chk = self.ctx.append_basic_block(self.cur_fn, "rt.chk");
                let adv = self.ctx.append_basic_block(self.cur_fn, "rt.adv");
                let done = self.ctx.append_basic_block(self.cur_fn, "rt.done");
                self.builder.build_unconditional_branch(head).map_err(Self::err)?;
                self.builder.position_at_end(head);
                let bv = self.builder.build_load(self.i64t, b, "bv").map_err(Self::err)?.into_int_value();
                let av = self.builder.build_load(self.i64t, a, "av2").map_err(Self::err)?.into_int_value();
                let c2 = self.builder.build_int_compare(IntPredicate::UGT, bv, av, "c2").map_err(Self::err)?;
                self.builder.build_conditional_branch(c2, chk, done).map_err(Self::err)?;
                self.builder.position_at_end(chk);
                let bm1 = self.builder.build_int_sub(bv, self.i64t.const_int(1, false), "bm1").map_err(Self::err)?;
                let eb = unsafe { self.builder.build_in_bounds_gep(i8t, s, &[bm1], "eb").map_err(Self::err)? };
                let cb = self.builder.build_load(i8t, eb, "cb").map_err(Self::err)?.into_int_value();
                let w = self.is_ws(cb)?;
                self.builder.build_conditional_branch(w, adv, done).map_err(Self::err)?;
                self.builder.position_at_end(adv);
                self.builder.build_store(b, bm1).map_err(Self::err)?;
                self.builder.build_unconditional_branch(head).map_err(Self::err)?;
                self.builder.position_at_end(done);
            }
            let av = self.builder.build_load(self.i64t, a, "fa").map_err(Self::err)?.into_int_value();
            let bv = self.builder.build_load(self.i64t, b, "fb").map_err(Self::err)?.into_int_value();
            let cl = self.builder.build_int_sub(bv, av, "cl").map_err(Self::err)?;
            self.str_copy(s, av, cl)
        }

        /// Get-or-declare a libc `double NAME(double)` and call it on `arg` (evaluated as f64).
        fn call_libm1(&self, cname: &str, arg: &IrExpr) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let f = self.module.get_function(cname).unwrap_or_else(|| {
                self.module.add_function(cname, self.f64t.fn_type(&[self.f64t.into()], false), None)
            });
            let a = self.eval_float(arg)?;
            self.builder
                .build_call(f, &[a.into()], "m1")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm(format!("{cname} returned void")))
        }

        /// Get-or-declare a libc `double NAME(double, double)`.
        fn libm2(&self, cname: &str) -> FunctionValue<'ctx> {
            self.module.get_function(cname).unwrap_or_else(|| {
                self.module
                    .add_function(cname, self.f64t.fn_type(&[self.f64t.into(), self.f64t.into()], false), None)
            })
        }

        /// `double NAME(double, double)` applied to two f64 args.
        fn call_libm2(&self, cname: &str, a: FloatValue<'ctx>, b: FloatValue<'ctx>) -> Result<BasicValueEnum<'ctx>, CompileError> {
            self.builder
                .build_call(self.libm2(cname), &[a.into(), b.into()], "m2")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm(format!("{cname} returned void")))
        }

        /// `1.0 / NAME(arg)` — reciprocal trig/hyperbolic (COT/SEC/CSC/COTH/SECH/CSCH).
        fn call_recip(&self, cname: &str, arg: &IrExpr) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let v = self.call_libm1(cname, arg)?.into_float_value();
            Ok(self
                .builder
                .build_float_div(self.f64t.const_float(1.0), v, "recip")
                .map_err(Self::err)?
                .into())
        }

        /// `double NAME(double)` applied to an already-evaluated f64 (for composed forms).
        fn callm1v(&self, cname: &str, v: FloatValue<'ctx>) -> Result<FloatValue<'ctx>, CompileError> {
            let f = self.module.get_function(cname).unwrap_or_else(|| {
                self.module.add_function(cname, self.f64t.fn_type(&[self.f64t.into()], false), None)
            });
            Ok(self
                .builder
                .build_call(f, &[v.into()], "m1v")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm(format!("{cname} returned void")))?
                .into_float_value())
        }

        /// `NAME(1.0 / arg)` — inverse reciprocal (ACSC/ACOTH/ASECH/ACSCH).
        fn call_inv_recip(&self, cname: &str, arg: &IrExpr) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let v = self.eval_float(arg)?;
            let inv = self.builder.build_float_div(self.f64t.const_float(1.0), v, "invr").map_err(Self::err)?;
            Ok(self.callm1v(cname, inv)?.into())
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
                ("SQRT", 1) => Ok(Some(self.call_libm1("sqrt", &args[0])?)),
                ("SIN", 1) => Ok(Some(self.call_libm1("sin", &args[0])?)),
                ("COS", 1) => Ok(Some(self.call_libm1("cos", &args[0])?)),
                ("TAN", 1) => Ok(Some(self.call_libm1("tan", &args[0])?)),
                ("EXP", 1) => Ok(Some(self.call_libm1("exp", &args[0])?)),
                ("LOG", 1) => Ok(Some(self.call_libm1("log", &args[0])?)),
                ("LOG10", 1) => Ok(Some(self.call_libm1("log10", &args[0])?)),
                ("ACOS", 1) => Ok(Some(self.call_libm1("acos", &args[0])?)),
                ("ASIN", 1) => Ok(Some(self.call_libm1("asin", &args[0])?)),
                ("ATAN", 1) | ("ATN", 1) => Ok(Some(self.call_libm1("atan", &args[0])?)),
                ("SINH", 1) => Ok(Some(self.call_libm1("sinh", &args[0])?)),
                ("COSH", 1) => Ok(Some(self.call_libm1("cosh", &args[0])?)),
                ("TANH", 1) => Ok(Some(self.call_libm1("tanh", &args[0])?)),
                ("ASINH", 1) => Ok(Some(self.call_libm1("asinh", &args[0])?)),
                ("ACOSH", 1) => Ok(Some(self.call_libm1("acosh", &args[0])?)),
                ("ATANH", 1) => Ok(Some(self.call_libm1("atanh", &args[0])?)),
                ("CEIL", 1) => Ok(Some(self.call_libm1("ceil", &args[0])?)),
                ("FLOOR", 1) => Ok(Some(self.call_libm1("floor", &args[0])?)),
                ("ROUND", 1) => Ok(Some(self.call_libm1("round", &args[0])?)),
                ("COT", 1) => self.call_recip("tan", &args[0]).map(Some),
                ("SEC", 1) => self.call_recip("cos", &args[0]).map(Some),
                ("CSC", 1) => self.call_recip("sin", &args[0]).map(Some),
                ("COTH", 1) => self.call_recip("tanh", &args[0]).map(Some),
                ("SECH", 1) => self.call_recip("cosh", &args[0]).map(Some),
                ("CSCH", 1) => self.call_recip("sinh", &args[0]).map(Some),
                ("ACSC", 1) => self.call_inv_recip("asin", &args[0]).map(Some),
                ("ACOTH", 1) => self.call_inv_recip("atanh", &args[0]).map(Some),
                ("ASECH", 1) => self.call_inv_recip("acosh", &args[0]).map(Some),
                ("ACSCH", 1) => self.call_inv_recip("asinh", &args[0]).map(Some),
                ("ATAN2", 2) => {
                    let a = self.eval_float(&args[0])?;
                    let b = self.eval_float(&args[1])?;
                    Ok(Some(self.call_libm2("atan2", a, b)?))
                }
                ("POWER", 2) => {
                    let a = self.eval_float(&args[0])?;
                    let b = self.eval_float(&args[1])?;
                    Ok(Some(self.call_libm2("pow", a, b)?))
                }
                ("EXP10", 1) => {
                    let v = self.eval_float(&args[0])?;
                    Ok(Some(self.call_libm2("pow", self.f64t.const_float(10.0), v)?))
                }
                ("EXP2", 1) => {
                    let v = self.eval_float(&args[0])?;
                    Ok(Some(self.call_libm2("pow", self.f64t.const_float(2.0), v)?))
                }
                ("ASEC", 1) => {
                    // M_PI_2 - asin(1/v)
                    let v = self.eval_float(&args[0])?;
                    let inv = self.builder.build_float_div(self.f64t.const_float(1.0), v, "invr").map_err(Self::err)?;
                    let a = self.callm1v("asin", inv)?;
                    Ok(Some(self.builder.build_float_sub(self.f64t.const_float(std::f64::consts::FRAC_PI_2), a, "asec").map_err(Self::err)?.into()))
                }
                ("ACOT", 1) => {
                    // v > 1 ? atan(1/v) : M_PI_2 - atan(v)
                    let v = self.eval_float(&args[0])?;
                    let inv = self.builder.build_float_div(self.f64t.const_float(1.0), v, "invr").map_err(Self::err)?;
                    let hi = self.callm1v("atan", inv)?;
                    let av = self.callm1v("atan", v)?;
                    let lo = self.builder.build_float_sub(self.f64t.const_float(std::f64::consts::FRAC_PI_2), av, "acotlo").map_err(Self::err)?;
                    let gt1 = self.builder.build_float_compare(FloatPredicate::OGT, v, self.f64t.const_float(1.0), "gt1").map_err(Self::err)?;
                    Ok(Some(self.builder.build_select(gt1, hi, lo, "acot").map_err(Self::err)?))
                }
                ("STRING$", 1) => {
                    let iv = self.eval_int(&args[0])?;
                    Ok(Some(self.str_from_int(self.fmt_d, iv)?.into()))
                }
                ("CSIZE", 1) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let n = self
                        .builder
                        .build_call(self.strlen, &[s.into()], "csz")
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("strlen returned void".into()))?
                        .into_int_value();
                    Ok(Some(self.builder.build_int_truncate(n, self.i32t, "csz32").map_err(Self::err)?.into()))
                }
                ("INSTR", 2) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let Some(BasicValueEnum::PointerValue(sub)) = self.eval_value(&args[1])? else {
                        return Ok(None);
                    };
                    let strstr = self.module.get_function("strstr").unwrap_or_else(|| {
                        self.module.add_function("strstr", self.ptr.fn_type(&[self.ptr.into(), self.ptr.into()], false), None)
                    });
                    let p = self
                        .builder
                        .build_call(strstr, &[s.into(), sub.into()], "iss")
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("strstr returned void".into()))?
                        .into_pointer_value();
                    let pnull = self.builder.build_is_null(p, "pnull").map_err(Self::err)?;
                    let pi = self.builder.build_ptr_to_int(p, self.i64t, "pi").map_err(Self::err)?;
                    let si = self.builder.build_ptr_to_int(s, self.i64t, "si").map_err(Self::err)?;
                    let diff = self.builder.build_int_sub(pi, si, "diff").map_err(Self::err)?;
                    let diff32 = self.builder.build_int_truncate(diff, self.i32t, "diff32").map_err(Self::err)?;
                    let pos = self.builder.build_int_add(diff32, self.i32t.const_int(1, false), "pos").map_err(Self::err)?;
                    Ok(Some(self.builder.build_select(pnull, self.i32t.const_zero(), pos, "instr").map_err(Self::err)?))
                }
                ("LEN", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(pv)) => {
                        let n32 = self
                            .builder
                            .build_int_truncate(self.str_len(pv)?, self.i32t, "len32")
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
                    // A 1-byte byte-string; storing the char keeps CHR$(0) as a real NUL byte.
                    let buf = self.str_new(self.i64t.const_int(1, false))?;
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
                ("STR$", 1) => match self.eval_value(&args[0])? {
                    // Integer STR$ = Rust i32::to_string == snprintf("%d"). Float STR$ is
                    // deferred (Rust float fmt != printf; would be silently wrong).
                    Some(BasicValueEnum::IntValue(iv)) => Ok(Some(self.str_from_int(self.fmt_d, iv)?.into())),
                    _ => Ok(None),
                },
                ("SPACE$", 1) => {
                    let n = self.eval_int(&args[0])?;
                    Ok(Some(self.str_space(n)?.into()))
                }
                ("ASC", 1) => match self.eval_value(&args[0])? {
                    // First byte as int; empty string's null terminator reads as 0.
                    Some(BasicValueEnum::PointerValue(s)) => {
                        let byte = self
                            .builder
                            .build_load(self.ctx.i8_type(), s, "ascb")
                            .map_err(Self::err)?
                            .into_int_value();
                        Ok(Some(
                            self.builder.build_int_z_extend(byte, self.i32t, "asc").map_err(Self::err)?.into(),
                        ))
                    }
                    _ => Ok(None),
                },
                ("SGN", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::IntValue(n)) => {
                        let z = self.i32t.const_zero();
                        let pos = self.builder.build_int_compare(IntPredicate::SGT, n, z, "sgp").map_err(Self::err)?;
                        let neg = self.builder.build_int_compare(IntPredicate::SLT, n, z, "sgn").map_err(Self::err)?;
                        let pi = self.builder.build_int_z_extend(pos, self.i32t, "sgpi").map_err(Self::err)?;
                        let ni = self.builder.build_int_z_extend(neg, self.i32t, "sgni").map_err(Self::err)?;
                        Ok(Some(self.builder.build_int_sub(pi, ni, "sgn").map_err(Self::err)?.into()))
                    }
                    _ => Ok(None),
                },
                ("INT", 1) | ("FIX", 1) => match self.eval_value(&args[0])? {
                    // Float → i32 truncation toward zero (matches `*n as i32`).
                    Some(BasicValueEnum::FloatValue(f)) => Ok(Some(
                        self.builder.build_float_to_signed_int(f, self.i32t, "int").map_err(Self::err)?.into(),
                    )),
                    _ => Ok(None),
                },
                ("MAX", 2) | ("MIN", 2) => {
                    match (self.eval_value(&args[0])?, self.eval_value(&args[1])?) {
                        (Some(BasicValueEnum::IntValue(a)), Some(BasicValueEnum::IntValue(b))) => {
                            let pred = if name == "MAX" { IntPredicate::SGT } else { IntPredicate::SLT };
                            let c = self.builder.build_int_compare(pred, a, b, "mmc").map_err(Self::err)?;
                            Ok(Some(self.builder.build_select(c, a, b, "mm").map_err(Self::err)?))
                        }
                        _ => Ok(None),
                    }
                }
                ("HEX$", 1) => match self.eval_value(&args[0])? {
                    // snprintf("%X") == Rust `{:X}` on i32 (both hex of the 32-bit pattern).
                    Some(BasicValueEnum::IntValue(iv)) => Ok(Some(self.str_from_int(self.fmt_hex, iv)?.into())),
                    _ => Ok(None),
                },
                ("UCASE$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => Ok(Some(self.str_case(s, true)?.into())),
                    _ => Ok(None),
                },
                ("LCASE$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => Ok(Some(self.str_case(s, false)?.into())),
                    _ => Ok(None),
                },
                ("TRIM$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => Ok(Some(self.str_trim(s, true, true)?.into())),
                    _ => Ok(None),
                },
                ("LTRIM$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => Ok(Some(self.str_trim(s, true, false)?.into())),
                    _ => Ok(None),
                },
                ("RTRIM$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => Ok(Some(self.str_trim(s, false, true)?.into())),
                    _ => Ok(None),
                },
                _ => Ok(None),
            }
        }
    }

    /// True if a body has top-level labels/GOSUB/GOTO (needs state-machine emission).
    fn body_has_labels(items: &[IrItem]) -> bool {
        items.iter().any(|it| {
            matches!(
                it,
                IrItem::Label(_)
                    | IrItem::Goto(_)
                    | IrItem::Gosub(_)
                    | IrItem::GosubReturn
                    | IrItem::GosubExpr(_)
                    | IrItem::GotoExpr(_)
            )
        })
    }

    /// True if a `GOSUB`/computed-`GOSUB` appears *nested* inside a control-flow block.
    /// The state machine resumes at the next top-level pc, which is only correct for a
    /// top-level GOSUB — a nested one (e.g. inside a loop) would resume wrong, so such
    /// bodies are rejected (→ the C backend) rather than emitted with wrong output.
    fn has_nested_gosub(items: &[IrItem]) -> bool {
        items.iter().any(item_nested_gosub)
    }

    fn body_contains_gosub(items: &[IrItem]) -> bool {
        items
            .iter()
            .any(|it| matches!(it, IrItem::Gosub(_) | IrItem::GosubExpr(_)) || item_nested_gosub(it))
    }

    /// True if `it` is a control-flow construct whose body contains a GOSUB.
    fn item_nested_gosub(it: &IrItem) -> bool {
        match it {
            IrItem::If { then_body, else_body, .. } => {
                body_contains_gosub(then_body)
                    || else_body.as_ref().is_some_and(|b| body_contains_gosub(b))
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } => body_contains_gosub(body),
            IrItem::SelectCase { cases, default, .. } => {
                cases.iter().any(|c| body_contains_gosub(&c.body))
                    || default.as_ref().is_some_and(|b| body_contains_gosub(b))
            }
            IrItem::Compound(items) => body_contains_gosub(items),
            _ => false,
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

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_string_build() {
        use std::io::Write;
        use std::process::Command;
        // Concatenation + STR$ mirror the interpreter: "n=42"/"abc"/"-5".
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM s$\n\
             s$ = \"n=\" + STR$(42)\n\
             PRINT s$\n\
             PRINT \"a\" + \"b\" + \"c\"\n\
             PRINT STR$(0 - 5)\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_sbuild.o");
        let exep = dir.join("xb_llvm_sbuild.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "n=42\nabc\n-5\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_multidim_array() {
        use std::io::Write;
        use std::process::Command;
        // Row-major 2D array (DIM m[2,3]) mirrors the interpreter: 5/9/7.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM m[2, 3]\n\
             m[0, 0] = 5\n\
             m[1, 2] = 9\n\
             m[2, 3] = 7\n\
             PRINT m[0, 0]\n\
             PRINT m[1, 2]\n\
             PRINT m[2, 3]\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_nd.o");
        let exep = dir.join("xb_llvm_nd.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "5\n9\n7\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_ubound() {
        use std::io::Write;
        use std::process::Command;
        // UBOUND(a) = flat length − 1 = 4; loop fills a[i]=i*i so a[4]=16.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM a[4]\n\
             FOR i = 0 TO UBOUND(a)\n\
             a[i] = i * i\n\
             NEXT i\n\
             PRINT a[UBOUND(a)]\n\
             PRINT UBOUND(a)\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_ub.o");
        let exep = dir.join("xb_llvm_ub.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "16\n4\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_string_transform_builtins() {
        use std::io::Write;
        use std::process::Command;
        // TRIM$/LTRIM$/RTRIM$/UCASE$/LCASE$/SPACE$ mirror the interpreter (byte_trim =
        // ASCII whitespace; ASCII case fold; n spaces).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM s$\n\
             s$ = \"  Hi There  \"\n\
             PRINT \"[\" + TRIM$(s$) + \"]\"\n\
             PRINT \"[\" + LTRIM$(s$) + \"]\"\n\
             PRINT \"[\" + RTRIM$(s$) + \"]\"\n\
             PRINT UCASE$(\"hello\")\n\
             PRINT LCASE$(\"WORLD\")\n\
             PRINT \"[\" + SPACE$(3) + \"]\"\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_sx.o");
        let exep = dir.join("xb_llvm_sx.bin");
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
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "[Hi There]\n[Hi There  ]\n[  Hi There]\nHELLO\nworld\n[   ]\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_print_separators() {
        use std::io::Write;
        use std::process::Command;
        // Comma separator = tab, semicolon = nothing (matches exec_print).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT \"a\", \"b\", \"c\"\n\
             PRINT 1, 2\n\
             PRINT \"x\"; \"y\"\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_psep.o");
        let exep = dir.join("xb_llvm_psep.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "a\tb\tc\n1\t2\nxy\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_select_case() {
        use std::io::Write;
        use std::process::Command;
        // Multi-condition CASE + CASE ELSE, nested inside a FOR loop.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM x\n\
             x = 2\n\
             SELECT CASE x\n\
             CASE 1\n\
             PRINT \"one\"\n\
             CASE 2, 3\n\
             PRINT \"two-or-three\"\n\
             CASE ELSE\n\
             PRINT \"other\"\n\
             END SELECT\n\
             FOR i = 1 TO 4\n\
             SELECT CASE i\n\
             CASE 4\n\
             PRINT \"four\"\n\
             CASE ELSE\n\
             PRINT i\n\
             END SELECT\n\
             NEXT i\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_sel.o");
        let exep = dir.join("xb_llvm_sel.bin");
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
        assert_eq!(String::from_utf8_lossy(&run.stdout), "two-or-three\n1\n2\n3\nfour\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_gosub_goto() {
        use std::io::Write;
        use std::process::Command;
        // Top-level GOSUB/RETURN (called twice) + GOTO over the subroutine.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM x\n\
             x = 0\n\
             GOSUB addone\n\
             GOSUB addone\n\
             PRINT x\n\
             GOTO done\n\
             addone:\n\
             x = x + 10\n\
             RETURN\n\
             done:\n\
             PRINT \"end\"\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_gs.o");
        let exep = dir.join("xb_llvm_gs.bin");
        std::fs::File::create(&objp).unwrap().write_all(obj.as_bytes()).unwrap();
        let link = Command::new("cc").arg(&objp).arg("-o").arg(&exep).output().unwrap();
        assert!(link.status.success(), "link: {}", String::from_utf8_lossy(&link.stderr));
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "20\nend\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_nested_gosub_falls_back_to_linear() {
        // A GOSUB nested inside a loop can't get a correct top-level resume pc, so the
        // body uses linear emission (jumps no-op'd) instead of the state machine. It must
        // still compile cleanly (no panic / codegen error) — divergence is caught by the
        // differential, never a silent claim of correctness.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM i\n\
             FOR i = 1 TO 3\n\
             IF i = 2 THEN GOSUB s\n\
             NEXT i\n\
             GOTO fin\n\
             s:\n\
             PRINT i\n\
             RETURN\n\
             fin:\n\
             PRINT \"x\"\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_numeric_builtins() {
        use std::io::Write;
        use std::process::Command;
        // ASC/SGN/INT/MAX/MIN/HEX$ mirror the interpreter.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT ASC(\"A\")\n\
             PRINT SGN(0 - 5)\n\
             PRINT INT(3.7)\n\
             PRINT MAX(4, 9)\n\
             PRINT MIN(4, 9)\n\
             PRINT HEX$(255)\n\
             PRINT HEX$(0 - 1)\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_nb.o");
        let exep = dir.join("xb_llvm_nb.bin");
        std::fs::File::create(&objp).unwrap().write_all(obj.as_bytes()).unwrap();
        let link = Command::new("cc").arg(&objp).arg("-o").arg(&exep).output().unwrap();
        assert!(link.status.success(), "link: {}", String::from_utf8_lossy(&link.stderr));
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "65\n-1\n3\n9\n4\nFF\nFFFFFFFF\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_integer_ops() {
        use std::io::Write;
        use std::process::Command;
        // MOD (signed rem), \\ (IntegerDiv), << (Shl), >> (Shr) mirror the interpreter.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT 17 MOD 5\n\
             PRINT 17 \\ 5\n\
             PRINT 1 << 4\n\
             PRINT 100 >> 2\n\
             PRINT 0 - 17 MOD 5\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_iop.o");
        let exep = dir.join("xb_llvm_iop.bin");
        std::fs::File::create(&objp).unwrap().write_all(obj.as_bytes()).unwrap();
        let link = Command::new("cc").arg(&objp).arg("-o").arg(&exep).output().unwrap();
        assert!(link.status.success(), "link: {}", String::from_utf8_lossy(&link.stderr));
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "2\n3\n16\n25\n-2\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_embedded_nul_strings() {
        use std::io::Write;
        use std::process::Command;
        // Byte-string representation: CHR$(0)/embedded NULs survive concat, LEN, and PRINT
        // byte-for-byte (a C null-terminated backend would truncate at the first NUL).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM s$\n\
             s$ = \"AB\" + CHR$(0) + \"CD\"\n\
             PRINT LEN(s$)\n\
             PRINT s$\n\
             PRINT LEN(CHR$(0))\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_nul.o");
        let exep = dir.join("xb_llvm_nul.bin");
        std::fs::File::create(&objp).unwrap().write_all(obj.as_bytes()).unwrap();
        let link = Command::new("cc").arg(&objp).arg("-o").arg(&exep).output().unwrap();
        assert!(link.status.success(), "link: {}", String::from_utf8_lossy(&link.stderr));
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(run.stdout, b"5\nAB\x00CD\n1\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_math_and_string_builtins() {
        use std::io::Write;
        use std::process::Command;
        // libc-backed math (SQRT/POWER via sqrt/pow) + string builtins (INSTR/STRING$/CSIZE)
        // mirror the interpreter; INT() keeps the float results deterministic to print.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT SQRT(144.0)\n\
             PRINT INT(SQRT(50.0))\n\
             PRINT POWER(3.0, 4.0)\n\
             PRINT INSTR(\"mississippi\", \"ssi\")\n\
             PRINT STRING$(123)\n\
             PRINT CSIZE(\"test\")\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        assert!(!obj.as_bytes().is_empty());
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_mb.o");
        let exep = dir.join("xb_llvm_mb.bin");
        std::fs::File::create(&objp).unwrap().write_all(obj.as_bytes()).unwrap();
        let link = Command::new("cc").arg(&objp).arg("-o").arg(&exep).output().unwrap();
        assert!(link.status.success(), "link: {}", String::from_utf8_lossy(&link.stderr));
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "12\n7\n81\n3\n123\n4\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }
}
