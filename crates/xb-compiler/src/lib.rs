mod builtin;
mod c_emit;
mod c_emit_bitops;
mod c_emit_data;
mod c_emit_expr;
mod c_emit_goto;
mod c_emit_helpers;
mod c_emit_hoist;
mod c_emit_logical;
mod c_emit_select;
mod c_emit_stmt;
mod c_emit_str2;
mod c_emit_xin;
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
pub mod is_builtin;
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
pub use builtin::builtin_param_types;
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
    use inkwell::basic_block::BasicBlock;
    use inkwell::builder::Builder;
    use inkwell::context::Context;
    use inkwell::module::Module;
    use inkwell::targets::{
        CodeModel, FileType, InitializationConfig, RelocMode, Target, TargetMachine,
    };
    use inkwell::types::{BasicMetadataTypeEnum, BasicTypeEnum, FloatType, IntType, PointerType};
    use inkwell::values::{
        BasicMetadataValueEnum, BasicValueEnum, FloatValue, FunctionValue, IntValue, PointerValue,
    };
    use inkwell::{AddressSpace, OptimizationLevel};
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
            emit.byref_params = collect_byref_params(&program.items);
            emit.byref_array_params = collect_byref_array_params(&program.items);
            emit.func_ids = {
                let mut m = HashMap::new();
                let mut id = 0;
                for item in &program.items {
                    if let IrItem::Function { name, .. } = item {
                        id += 1;
                        m.entry(name.clone()).or_insert(id);
                    }
                }
                m
            };
            emit.declare_functions(&program.items);
            emit.declare_shared(&program.items);
            {
                // CGEN-AUTOVIVIFY parity: dynamic array names (empty-bracket DIM
                // or REDIM'd) — 1-D writes past the count auto-vivify.
                fn scan_dyn_names(items: &[IrItem], out: &mut std::collections::HashSet<String>) {
                    for it in items {
                        match it {
                            IrItem::Dim {
                                symbol,
                                size,
                                is_array: true,
                                redim,
                                ..
                            } => {
                                if *redim || size.is_none() {
                                    out.insert(symbol.name.clone());
                                }
                            }
                            IrItem::If {
                                then_body,
                                else_body,
                                ..
                            } => {
                                scan_dyn_names(then_body, out);
                                if let Some(eb) = else_body {
                                    scan_dyn_names(eb, out);
                                }
                            }
                            IrItem::Function { body, .. } => scan_dyn_names(body, out),
                            IrItem::While { body, .. }
                            | IrItem::For { body, .. }
                            | IrItem::DoLoop { body, .. }
                            | IrItem::Compound(body) => scan_dyn_names(body, out),
                            IrItem::SelectCase { cases, default, .. } => {
                                for c in cases {
                                    scan_dyn_names(&c.body, out);
                                }
                                if let Some(d) = default {
                                    scan_dyn_names(d, out);
                                }
                            }
                            _ => {}
                        }
                    }
                }
                scan_dyn_names(&program.items, &mut emit.dyn_arrays);
            }
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
    /// Sentinel pc that falls through the dispatch switch to the exit block (a RETURN
    /// with an empty stack, or a jump to an unknown label).
    const SM_EXIT_PC: u64 = 0x7FFF_FFFF;

    /// `pc` = top-level item index (so computed `GOSUB`/`GOTO` by index work directly);
    /// values `count+1..` are per-GOSUB *landing* pcs (resume points) so a GOSUB nested in
    /// an `IF`/`FOR`/… resumes exactly after itself, not at the enclosing top-level item.
    struct SmCtx<'ctx> {
        dispatch: BasicBlock<'ctx>,
        pc: PointerValue<'ctx>,
        retstack: PointerValue<'ctx>,
        retsp: PointerValue<'ctx>,
        labels: HashMap<String, u64>,
        /// Number of top-level items; also the base pc for landing blocks.
        count: u64,
        /// Per-GOSUB resume landings: `(pc, block)` with `pc = count + 1 + index`.
        landings: Vec<(u64, BasicBlock<'ctx>)>,
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
        /// Function name → 1-based program-order index, for `&func()` (`FuncAddr`). Mirrors the
        /// interpreter's `function_id`; unknown names resolve to 0.
        func_ids: HashMap<String, i32>,
        /// Function currently being emitted (for `append_basic_block`).
        cur_fn: FunctionValue<'ctx>,
        /// Return type of the function currently being emitted.
        cur_ret: ValueType,
        vars: HashMap<String, (PointerValue<'ctx>, ValueType)>,
        /// Module-shared scalar variables (`SHARED`), as LLVM globals keyed by name so
        /// they persist across function calls — mirrors the interpreter's `state.shared`
        /// and the C backend's `xb_shared_<name>` file-scope globals.
        shared: HashMap<String, (PointerValue<'ctx>, ValueType)>,
        /// LLVM-SHARED-ARR: program-wide shared array storage declared by
        /// `declare_shared` — name -> (holder global, elem type, dim-count globals).
        shared_arrays: HashMap<String, (PointerValue<'ctx>, ValueType, Vec<PointerValue<'ctx>>)>,
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
        /// Per-function parameter positions passed by-ref as `@scalar` at every call site
        /// (never by-value): lowered as pointer params sharing the caller's slot. Array `@`
        /// (which needs the array-descriptor ABI) is excluded.
        byref_params: HashMap<String, std::collections::HashSet<usize>>,
        /// Per-function parameter positions passed as `@array[]` (by-ref of a 1-D array)
        /// at every call site: lowered as a pointer to a `{data, dims}` descriptor the
        /// callee reads (read-only sharing; REDIM write-back is not yet modeled).
        byref_array_params: HashMap<String, std::collections::HashSet<usize>>,
        /// File runtime: an `xb_file_open_mode(name, mode) -> FILE*` helper normalizes
        /// documented OPEN base/share/NONBLOCK modes, then the existing `FILE*` table keeps
        /// CLOSE/LOF/record I/O ABI-stable.
        file_open_mode: FunctionValue<'ctx>,
        fclose: FunctionValue<'ctx>,
        fseek: FunctionValue<'ctx>,
        ftell: FunctionValue<'ctx>,
        /// Record data path: `fwrite`/`fread` (`__WRITE_RECORD`/`__READ_RECORD`) + `fflush`.
        fwrite: FunctionValue<'ctx>,
        fread: FunctionValue<'ctx>,
        fflush: FunctionValue<'ctx>,
        /// RT-KERNEL32 stdio: `xb_getstdhandle` / `xb_write_file` / `xb_read_file`
        /// (mirrors the generated-C runtimes; handles 0=stdin 1=stdout 2=stderr).
        getstdhandle: FunctionValue<'ctx>,
        write_file: FunctionValue<'ctx>,
        read_file: FunctionValue<'ctx>,
        /// Runtime helper `xb_file_eof(handle) -> i32` (EOF or invalid/closed handle → 1).
        file_eof: FunctionValue<'ctx>,
        /// Global `[FILE_SLOTS x ptr]` of open `FILE*` (index = handle − 3).
        file_table: PointerValue<'ctx>,
        /// CGEN-AUTOVIVIFY parity: `xb_dyn_resize(holder, cnt, newcnt, esz, is_str)`
        /// reallocs a dynamic array preserving content and fills the grown tail.
        dyn_resize: FunctionValue<'ctx>,
        /// Dynamic array names (empty-bracket DIM or REDIM'd): 1-D writes past the
        /// count auto-vivify via `dyn_resize`.
        dyn_arrays: std::collections::HashSet<String>,
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
            let realloc_f = module.add_function(
                "realloc",
                ptr.fn_type(&[ptr.into(), i64t.into()], false),
                None,
            );
            let calloc = module.add_function(
                "calloc",
                ptr.fn_type(&[i64t.into(), i64t.into()], false),
                None,
            );
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
            // File runtime: normalize OPEN modes in one helper, returning FILE* so the
            // existing fclose/fseek/ftell/fread/fwrite handle table remains unchanged.
            #[cfg(not(unix))]
            let fopen =
                module.add_function("fopen", ptr.fn_type(&[ptr.into(), ptr.into()], false), None);
            #[cfg(unix)]
            let open_fd =
                module.add_function("open", i32t.fn_type(&[ptr.into(), i32t.into()], true), None);
            #[cfg(not(unix))]
            let open_fd = fopen; // non-unix helper bodies don't run (see below)
            #[cfg(unix)]
            let fdopen = module.add_function(
                "fdopen",
                ptr.fn_type(&[i32t.into(), ptr.into()], false),
                None,
            );
            #[cfg(unix)]
            let close_fd = module.add_function("close", i32t.fn_type(&[i32t.into()], false), None);
            let file_open_mode = module.add_function(
                "xb_file_open_mode",
                i32t.fn_type(&[ptr.into(), i32t.into()], false),
                None,
            );
            let fclose = module.add_function("fclose", i32t.fn_type(&[ptr.into()], false), None);
            let fseek = module.add_function(
                "fseek",
                i32t.fn_type(&[ptr.into(), i64t.into(), i32t.into()], false),
                None,
            );
            let ftell = module.add_function("ftell", i64t.fn_type(&[ptr.into()], false), None);
            let fwrite = module.add_function(
                "fwrite",
                i64t.fn_type(&[ptr.into(), i64t.into(), i64t.into(), ptr.into()], false),
                None,
            );
            let fread = module.add_function(
                "fread",
                i64t.fn_type(&[ptr.into(), i64t.into(), i64t.into(), ptr.into()], false),
                None,
            );
            let fflush = module.add_function("fflush", i32t.fn_type(&[ptr.into()], false), None);
            let feof = module.add_function("feof", i32t.fn_type(&[ptr.into()], false), None);
            // RT-KERNEL32 stdio helpers — same contract as the generated-C runtimes:
            // handles 0=stdin 1=stdout 2=stderr; WriteFile writes min(bytes, LEN) and
            // stores the count; ReadFile replaces the buffer with exactly the bytes
            // read and stores the count.
            let getstdhandle =
                module.add_function("xb_getstdhandle", i32t.fn_type(&[i32t.into()], false), None);
            // CGEN-AUTOVIVIFY parity: dynamic-array resize helper (realloc +
            // tail fill; empty byte-strings for String elements, zeros else).
            let dyn_resize = module.add_function(
                "xb_dyn_resize",
                ctx.void_type().fn_type(
                    &[
                        ptr.into(),
                        ptr.into(),
                        i64t.into(),
                        i64t.into(),
                        ctx.bool_type().into(),
                    ],
                    false,
                ),
                None,
            );

            let write_file = module.add_function(
                "xb_write_file",
                i32t.fn_type(
                    &[i32t.into(), ptr.into(), i32t.into(), ptr.into(), ptr.into()],
                    false,
                ),
                None,
            );
            let read_file = module.add_function(
                "xb_read_file",
                i32t.fn_type(
                    &[i32t.into(), ptr.into(), i32t.into(), ptr.into(), ptr.into()],
                    false,
                ),
                None,
            );
            let file_arr_ty = ptr.array_type(256);
            let file_table_g = module.add_global(file_arr_ty, None, "xb_files");
            file_table_g.set_initializer(&file_arr_ty.const_zero());
            let file_table = file_table_g.as_pointer_value();
            let file_count_g = module.add_global(i32t, None, "xb_file_n");
            file_count_g.set_initializer(&i32t.const_zero());
            let file_count = file_count_g.as_pointer_value();
            let main = module.add_function("main", i32t.fn_type(&[], false), None);
            let main_entry = ctx.append_basic_block(main, "entry");
            builder.position_at_end(main_entry);
            let g =
                |b: &Builder<'ctx>, s: &str, n: &str| -> Result<PointerValue<'ctx>, CompileError> {
                    Ok(b.build_global_string_ptr(s, n)
                        .map_err(Self::err)?
                        .as_pointer_value())
                };
            let fmt_d = g(&builder, "%d", "fmtd")?;
            let nl = g(&builder, "\n", "nl")?;
            let tab = g(&builder, "\t", "tab")?;
            let fmt_g = g(&builder, "%g", "fmtg")?;
            // `xb_file_open_mode`: strip only NONBLOCK (0x800), exact-match documented bases,
            // and fall back to read-only existing-file semantics for unsupported values.
            // The helper also owns handle registration, so failed opens never consume a handle.
            {
                let entry = ctx.append_basic_block(file_open_mode, "entry");
                let finish = ctx.append_basic_block(file_open_mode, "finish");
                let success = ctx.append_basic_block(file_open_mode, "success");
                let failure = ctx.append_basic_block(file_open_mode, "failure");
                builder.position_at_end(entry);
                let name = file_open_mode
                    .get_nth_param(0)
                    .unwrap()
                    .into_pointer_value();
                let mode = file_open_mode.get_nth_param(1).unwrap().into_int_value();
                let fp_slot = builder.build_alloca(ptr, "ofp").map_err(Self::err)?;
                builder
                    .build_store(fp_slot, ptr.const_null())
                    .map_err(Self::err)?;
                let nonblock = builder
                    .build_int_compare(
                        IntPredicate::NE,
                        builder
                            .build_and(mode, i32t.const_int(0x0800, false), "onb")
                            .map_err(Self::err)?,
                        i32t.const_zero(),
                        "hasnb",
                    )
                    .map_err(Self::err)?;
                let base = builder
                    .build_and(mode, i32t.const_int((!0x0800u32) as u64, false), "obase")
                    .map_err(Self::err)?;
                let eq = |m: u64, n: &str| -> Result<IntValue<'ctx>, CompileError> {
                    builder
                        .build_int_compare(IntPredicate::EQ, base, i32t.const_int(m, false), n)
                        .map_err(Self::err)
                };
                let rd = builder
                    .build_or(eq(0, "ord")?, eq(0x10, "ordshare")?, "isrd")
                    .map_err(Self::err)?;
                let wr_trunc = builder
                    .build_or(eq(1, "owr")?, eq(3, "owrnew")?, "owrtr")
                    .map_err(Self::err)?;
                let rw_preserve = builder
                    .build_or(eq(2, "orw")?, eq(0x30, "orwshare")?, "orwp")
                    .map_err(Self::err)?;
                let rw_trunc = eq(4, "orwnew")?;
                let wr_preserve = eq(0x20, "owrshare")?;
                let valid_a = builder
                    .build_or(rd, wr_trunc, "ovalida")
                    .map_err(Self::err)?;
                let valid_b = builder
                    .build_or(rw_preserve, rw_trunc, "ovalidb")
                    .map_err(Self::err)?;
                let valid = builder
                    .build_or(
                        builder
                            .build_or(valid_a, valid_b, "ovalidab")
                            .map_err(Self::err)?,
                        wr_preserve,
                        "ovalid",
                    )
                    .map_err(Self::err)?;
                let read_only = builder
                    .build_or(
                        rd,
                        builder.build_not(valid, "oinvalid").map_err(Self::err)?,
                        "oreadonly",
                    )
                    .map_err(Self::err)?;
                let rdwr = builder
                    .build_or(rw_preserve, rw_trunc, "ordwr")
                    .map_err(Self::err)?;
                let trunc = builder
                    .build_or(wr_trunc, rw_trunc, "otrunc")
                    .map_err(Self::err)?;
                let preserve_writable = builder
                    .build_or(rw_preserve, wr_preserve, "opreserve")
                    .map_err(Self::err)?;
                let create = builder
                    .build_or(trunc, preserve_writable, "ocreate")
                    .map_err(Self::err)?;
                #[cfg(unix)]
                {
                    let mut flags = builder
                        .build_select(
                            rdwr,
                            i32t.const_int(libc::O_RDWR as u64, true),
                            i32t.const_int(libc::O_WRONLY as u64, true),
                            "ofacc",
                        )
                        .map_err(Self::err)?
                        .into_int_value();
                    flags = builder
                        .build_select(
                            read_only,
                            i32t.const_int(libc::O_RDONLY as u64, true),
                            flags,
                            "ofrd",
                        )
                        .map_err(Self::err)?
                        .into_int_value();
                    flags = builder
                        .build_select(
                            create,
                            builder
                                .build_or(flags, i32t.const_int(libc::O_CREAT as u64, true), "ofcr")
                                .map_err(Self::err)?,
                            flags,
                            "ofscreate",
                        )
                        .map_err(Self::err)?
                        .into_int_value();
                    flags = builder
                        .build_select(
                            trunc,
                            builder
                                .build_or(flags, i32t.const_int(libc::O_TRUNC as u64, true), "oftr")
                                .map_err(Self::err)?,
                            flags,
                            "ofstrunc",
                        )
                        .map_err(Self::err)?
                        .into_int_value();
                    flags = builder
                        .build_select(
                            nonblock,
                            builder
                                .build_or(
                                    flags,
                                    i32t.const_int(libc::O_NONBLOCK as u64, true),
                                    "ofnb",
                                )
                                .map_err(Self::err)?,
                            flags,
                            "ofsnb",
                        )
                        .map_err(Self::err)?
                        .into_int_value();
                    let fd = builder
                        .build_call(
                            open_fd,
                            &[
                                name.into(),
                                flags.into(),
                                i32t.const_int(0o666, false).into(),
                            ],
                            "openfd",
                        )
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("open returned void".into()))?
                        .into_int_value();
                    let fd_ok = builder
                        .build_int_compare(IntPredicate::SGE, fd, i32t.const_zero(), "fdok")
                        .map_err(Self::err)?;
                    let wrap = ctx.append_basic_block(file_open_mode, "wrap");
                    builder
                        .build_conditional_branch(fd_ok, wrap, finish)
                        .map_err(Self::err)?;
                    builder.position_at_end(wrap);
                    let rw_mode = builder
                        .build_select(
                            rdwr,
                            g(&builder, "r+b", "omrw")?,
                            g(&builder, "wb", "omwr")?,
                            "omsel",
                        )
                        .map_err(Self::err)?
                        .into_pointer_value();
                    let mode_ptr = builder
                        .build_select(read_only, g(&builder, "rb", "omrd")?, rw_mode, "omode")
                        .map_err(Self::err)?
                        .into_pointer_value();
                    let fp = builder
                        .build_call(fdopen, &[fd.into(), mode_ptr.into()], "fdopen")
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("fdopen returned void".into()))?
                        .into_pointer_value();
                    let fp_null = builder.build_is_null(fp, "fpnull").map_err(Self::err)?;
                    let wrap_failed = ctx.append_basic_block(file_open_mode, "wrap_failed");
                    let wrap_ok = ctx.append_basic_block(file_open_mode, "wrap_ok");
                    builder
                        .build_conditional_branch(fp_null, wrap_failed, wrap_ok)
                        .map_err(Self::err)?;
                    builder.position_at_end(wrap_failed);
                    builder
                        .build_call(close_fd, &[fd.into()], "closefd")
                        .map_err(Self::err)?;
                    builder
                        .build_unconditional_branch(finish)
                        .map_err(Self::err)?;
                    builder.position_at_end(wrap_ok);
                    builder.build_store(fp_slot, fp).map_err(Self::err)?;
                    builder
                        .build_unconditional_branch(finish)
                        .map_err(Self::err)?;
                }
                #[cfg(not(unix))]
                {
                    let _ = nonblock;
                    let direct = builder
                        .build_select(
                            read_only,
                            g(&builder, "rb", "omrd")?,
                            builder
                                .build_select(
                                    trunc,
                                    g(&builder, "w+b", "omtr")?,
                                    g(&builder, "r+b", "ompr")?,
                                    "omode1",
                                )
                                .map_err(Self::err)?,
                            "omode2",
                        )
                        .map_err(Self::err)?
                        .into_pointer_value();
                    let first = builder
                        .build_call(fopen, &[name.into(), direct.into()], "fopen")
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("fopen returned void".into()))?
                        .into_pointer_value();
                    let missing = builder
                        .build_is_null(first, "fmissing")
                        .map_err(Self::err)?;
                    let retry = builder
                        .build_and(preserve_writable, missing, "fretry")
                        .map_err(Self::err)?;
                    let retry_bb = ctx.append_basic_block(file_open_mode, "retry");
                    let keep_bb = ctx.append_basic_block(file_open_mode, "keep");
                    builder
                        .build_conditional_branch(retry, retry_bb, keep_bb)
                        .map_err(Self::err)?;
                    builder.position_at_end(retry_bb);
                    let second = builder
                        .build_call(
                            fopen,
                            &[name.into(), g(&builder, "w+b", "omcreate")?.into()],
                            "fcreate",
                        )
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("fopen returned void".into()))?
                        .into_pointer_value();
                    builder.build_store(fp_slot, second).map_err(Self::err)?;
                    builder
                        .build_unconditional_branch(finish)
                        .map_err(Self::err)?;
                    builder.position_at_end(keep_bb);
                    builder.build_store(fp_slot, first).map_err(Self::err)?;
                    builder
                        .build_unconditional_branch(finish)
                        .map_err(Self::err)?;
                }
                builder.position_at_end(finish);
                let fp = builder
                    .build_load(ptr, fp_slot, "ofinal")
                    .map_err(Self::err)?
                    .into_pointer_value();
                // Table exhaustion returns -1 without consuming a handle, matching
                // failed-open semantics and the generated-C backends.
                let table_full = builder
                    .build_int_compare(
                        IntPredicate::SGE,
                        builder
                            .build_load(i32t, file_count, "fcount")
                            .map_err(Self::err)?
                            .into_int_value(),
                        i32t.const_int(256u64, false),
                        "tblfull",
                    )
                    .map_err(Self::err)?;
                let full = ctx.append_basic_block(file_open_mode, "tblfull");
                let open_ok = ctx.append_basic_block(file_open_mode, "openok");
                builder
                    .build_conditional_branch(table_full, full, open_ok)
                    .map_err(Self::err)?;
                builder.position_at_end(full);
                builder
                    .build_return(Some(&i32t.const_int((-1i64) as u64, true)))
                    .map_err(Self::err)?;
                builder.position_at_end(open_ok);
                let is_null = builder.build_is_null(fp, "ofnull").map_err(Self::err)?;
                builder
                    .build_conditional_branch(is_null, failure, success)
                    .map_err(Self::err)?;
                builder.position_at_end(failure);
                builder
                    .build_return(Some(&i32t.const_int((-1i64) as u64, true)))
                    .map_err(Self::err)?;
                builder.position_at_end(success);
                let idx = builder
                    .build_load(i32t, file_count, "fidx")
                    .map_err(Self::err)?
                    .into_int_value();
                let slot = unsafe {
                    builder
                        .build_in_bounds_gep(
                            file_arr_ty,
                            file_table,
                            &[i32t.const_zero(), idx],
                            "fslot",
                        )
                        .map_err(Self::err)?
                };
                builder.build_store(slot, fp).map_err(Self::err)?;
                let idx1 = builder
                    .build_int_add(idx, i32t.const_int(1, false), "fidx1")
                    .map_err(Self::err)?;
                builder.build_store(file_count, idx1).map_err(Self::err)?;
                let handle = builder
                    .build_int_add(idx, i32t.const_int(3, false), "fh")
                    .map_err(Self::err)?;
                builder.build_return(Some(&handle)).map_err(Self::err)?;
            }
            let fmt_hex = g(&builder, "%X", "fmthex")?;
            // Runtime helper `xb_file_eof(handle) -> i32`: 1 when the file is at EOF or the
            // handle is invalid/closed, else 0. A dedicated function so its null/range-guard
            // branches never split an expression (EOF is used in `DO…LOOP UNTIL` conditions).
            let file_eof =
                module.add_function("xb_file_eof", i32t.fn_type(&[i32t.into()], false), None);
            {
                let entry = ctx.append_basic_block(file_eof, "entry");
                let chk = ctx.append_basic_block(file_eof, "chk");
                let call_feof = ctx.append_basic_block(file_eof, "do");
                let iseof = ctx.append_basic_block(file_eof, "iseof");
                builder.position_at_end(entry);
                let h = file_eof.get_nth_param(0).unwrap().into_int_value();
                let idx = builder
                    .build_int_sub(h, i32t.const_int(3, false), "eidx")
                    .map_err(Self::err)?;
                let cnt = builder
                    .build_load(i32t, file_count, "ecnt")
                    .map_err(Self::err)?
                    .into_int_value();
                let ge0 = builder
                    .build_int_compare(IntPredicate::SGE, idx, i32t.const_zero(), "ege0")
                    .map_err(Self::err)?;
                let ltc = builder
                    .build_int_compare(IntPredicate::SLT, idx, cnt, "eltc")
                    .map_err(Self::err)?;
                let valid = builder.build_and(ge0, ltc, "evalid").map_err(Self::err)?;
                builder
                    .build_conditional_branch(valid, chk, iseof)
                    .map_err(Self::err)?;
                builder.position_at_end(chk);
                let slot = unsafe {
                    builder
                        .build_in_bounds_gep(
                            file_arr_ty,
                            file_table,
                            &[i32t.const_zero(), idx],
                            "eslot",
                        )
                        .map_err(Self::err)?
                };
                let fp = builder
                    .build_load(ptr, slot, "efp")
                    .map_err(Self::err)?
                    .into_pointer_value();
                let isnull = builder.build_is_null(fp, "enull").map_err(Self::err)?;
                builder
                    .build_conditional_branch(isnull, iseof, call_feof)
                    .map_err(Self::err)?;
                builder.position_at_end(call_feof);
                let e = builder
                    .build_call(feof, &[fp.into()], "feof")
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("feof returned void".into()))?
                    .into_int_value();
                let ne = builder
                    .build_int_compare(IntPredicate::NE, e, i32t.const_zero(), "ene")
                    .map_err(Self::err)?;
                let r = builder
                    .build_select(ne, i32t.const_int(1, false), i32t.const_zero(), "eres")
                    .map_err(Self::err)?
                    .into_int_value();
                builder.build_return(Some(&r)).map_err(Self::err)?;
                builder.position_at_end(iseof);
                builder
                    .build_return(Some(&i32t.const_int(1, false)))
                    .map_err(Self::err)?;
            }
            // RT-KERNEL32 stdio helpers — the same contract as the generated-C
            // runtimes (c_runtime.rs emit_kernel32_runtime). `xb_getstdhandle`:
            // -10/-11/-12 -> 0/1/2, else -1. `xb_write_file(h, buf, bytes, &written, _)`:
            // write `bytes` to stdout, store the count, return 1 on full write.
            // `xb_read_file(h, &buf, bytes, &read, _)`: read up to `bytes` from stdin,
            // replace *buf with a fresh byte-string of exactly the bytes read, store
            // the count, return 1 when anything was read. Uses the FILE* streams so
            // output ordering with printf/putchar holds.
            {
                let entry = ctx.append_basic_block(getstdhandle, "entry");
                builder.position_at_end(entry);
                let dev = getstdhandle.get_nth_param(0).unwrap().into_int_value();
                let m = |v: i64, n: &str| -> Result<IntValue<'ctx>, CompileError> {
                    builder
                        .build_int_compare(IntPredicate::EQ, dev, i32t.const_int(v as u64, true), n)
                        .map_err(Self::err)
                };
                let din = m(-10, "din")?;
                let dout = m(-11, "dout")?;
                let derr = m(-12, "derr")?;
                let r0 = builder
                    .build_select(
                        din,
                        i32t.const_zero(),
                        i32t.const_int((-1i64) as u64, true),
                        "rin",
                    )
                    .map_err(Self::err)?
                    .into_int_value();
                let r1 = builder
                    .build_select(dout, i32t.const_int(1, false), r0, "rout")
                    .map_err(Self::err)?
                    .into_int_value();
                let r2 = builder
                    .build_select(derr, i32t.const_int(2, false), r1, "rerr")
                    .map_err(Self::err)?
                    .into_int_value();
                builder.build_return(Some(&r2)).map_err(Self::err)?;
            }
            {
                // `xb_dyn_resize(holder, cnt, newcnt, esz, is_str)`: realloc the
                // dynamic array to `newcnt` elements preserving content; fill the
                // grown tail with fresh empty byte-strings (String) or zeros.
                let entry = ctx.append_basic_block(dyn_resize, "entry");
                builder.position_at_end(entry);
                let holder = dyn_resize.get_nth_param(0).unwrap().into_pointer_value();
                let cnt = dyn_resize.get_nth_param(1).unwrap().into_pointer_value();
                let newcnt = dyn_resize.get_nth_param(2).unwrap().into_int_value();
                let esz = dyn_resize.get_nth_param(3).unwrap().into_int_value();
                let is_str = dyn_resize.get_nth_param(4).unwrap().into_int_value();
                let oldcnt = builder
                    .build_load(i64t, cnt, "oldcnt")
                    .map_err(Self::err)?
                    .into_int_value();
                let oldbuf = builder
                    .build_load(ptr, holder, "oldbuf")
                    .map_err(Self::err)?
                    .into_pointer_value();
                let bytes = builder
                    .build_int_mul(newcnt, esz, "bytes")
                    .map_err(Self::err)?;
                let newbuf = builder
                    .build_call(realloc_f, &[oldbuf.into(), bytes.into()], "newbuf")
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("realloc returned void".into()))?
                    .into_pointer_value();
                builder.build_store(holder, newbuf).map_err(Self::err)?;
                builder.build_store(cnt, newcnt).map_err(Self::err)?;
                let more = builder
                    .build_int_compare(IntPredicate::SLT, oldcnt, newcnt, "more")
                    .map_err(Self::err)?;
                let fill = ctx.append_basic_block(dyn_resize, "fill");
                let done = ctx.append_basic_block(dyn_resize, "done");
                builder
                    .build_conditional_branch(more, fill, done)
                    .map_err(Self::err)?;
                builder.position_at_end(fill);
                let cur = builder
                    .build_phi(i64t, "cur")
                    .map_err(Self::err)?;
                let is_str_b = builder
                    .build_int_compare(
                        IntPredicate::NE,
                        is_str,
                        ctx.bool_type().const_zero(),
                        "s",
                    )
                    .map_err(Self::err)?;
                let curb = builder
                    .build_int_mul(
                        cur.as_basic_value().into_int_value(),
                        esz,
                        "curb",
                    )
                    .map_err(Self::err)?;
                let ep = unsafe {
                    builder
                        .build_in_bounds_gep(ctx.i8_type(), newbuf, &[curb], "ep")
                        .map_err(Self::err)?
                };
                let sblk = ctx.append_basic_block(dyn_resize, "sfill");
                let zblk = ctx.append_basic_block(dyn_resize, "zfill");
                let fnext = ctx.append_basic_block(dyn_resize, "fnext");
                builder
                    .build_conditional_branch(is_str_b, sblk, zblk)
                    .map_err(Self::err)?;
                builder.position_at_end(sblk);
                let sp = builder
                    .build_call(
                        calloc,
                        &[
                            i64t.const_int(9, false).into(),
                            i64t.const_int(1, false).into(),
                        ],
                        "s",
                    )
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                    .into_pointer_value();
                builder.build_store(ep, sp).map_err(Self::err)?;
                builder.build_unconditional_branch(fnext).map_err(Self::err)?;
                builder.position_at_end(zblk);
                builder
                    .build_call(
                        memset,
                        &[
                            ep.into(),
                            i32t.const_zero().into(),
                            esz.into(),
                        ],
                        "z",
                    )
                    .map_err(Self::err)?;
                builder.build_unconditional_branch(fnext).map_err(Self::err)?;
                builder.position_at_end(fnext);
                let inext = builder
                    .build_int_add(
                        cur.as_basic_value().into_int_value(),
                        i64t.const_int(1, false),
                        "inext",
                    )
                    .map_err(Self::err)?;
                let more2 = builder
                    .build_int_compare(IntPredicate::SLT, inext, newcnt, "more2")
                    .map_err(Self::err)?;
                builder
                    .build_conditional_branch(more2, fill, done)
                    .map_err(Self::err)?;
                let oldcnt_enum: BasicValueEnum = oldcnt.into();
                let inext_enum: BasicValueEnum = inext.into();
                cur.add_incoming(&[(&oldcnt_enum, entry), (&inext_enum, fnext)]);
                builder.position_at_end(done);
                builder.build_return(None).map_err(Self::err)?;
            }
            {
                let entry = ctx.append_basic_block(write_file, "entry");
                builder.position_at_end(entry);
                let h = write_file.get_nth_param(0).unwrap().into_int_value();
                let buf = write_file.get_nth_param(1).unwrap().into_pointer_value();
                let bytes = write_file.get_nth_param(2).unwrap().into_int_value();
                let written = write_file.get_nth_param(3).unwrap().into_pointer_value();
                // `written` is already the caller's i32 slot address (a plain symbol
                // lowers to its alloca) — no extra deref.
                let wslot = written;
                builder
                    .build_store(wslot, i32t.const_zero())
                    .map_err(Self::err)?;
                let is_out = builder
                    .build_int_compare(IntPredicate::EQ, h, i32t.const_int(1, false), "wisout")
                    .map_err(Self::err)?;
                let bpos = builder
                    .build_int_compare(IntPredicate::SGT, bytes, i32t.const_zero(), "wbpos")
                    .map_err(Self::err)?;
                let go = builder.build_and(is_out, bpos, "wgo").map_err(Self::err)?;
                let body = ctx.append_basic_block(write_file, "wbody");
                let done = ctx.append_basic_block(write_file, "wdone");
                builder
                    .build_conditional_branch(go, body, done)
                    .map_err(Self::err)?;
                builder.position_at_end(done);
                builder
                    .build_return(Some(&i32t.const_zero()))
                    .map_err(Self::err)?;
                builder.position_at_end(body);
                // Portable stdio: open(2)+fdopen on /dev/stdout — avoids
                // platform-specific `stdout` symbol shapes (ELF data symbol vs
                // Mach-O macro) and reuses the OPEN runtime declarations.
                let outpath = builder
                    .build_global_string_ptr("/dev/stdout", "wdev")
                    .map_err(Self::err)?
                    .as_pointer_value();
                let wfd = builder
                    .build_call(
                        open_fd,
                        &[outpath.into(), i32t.const_int(1, false).into()],
                        "wofd",
                    )
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("open returned void".into()))?
                    .into_int_value();
                let wmode = builder
                    .build_global_string_ptr("w", "wmode")
                    .map_err(Self::err)?
                    .as_pointer_value();
                let outfp = builder
                    .build_call(fdopen, &[wfd.into(), wmode.into()], "woutfp")
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("fdopen returned void".into()))?
                    .into_pointer_value();
                let b64 = builder
                    .build_int_s_extend(bytes, i64t, "wb64")
                    .map_err(Self::err)?;
                let one = i64t.const_int(1, false);
                let n = builder
                    .build_call(
                        fwrite,
                        &[buf.into(), one.into(), b64.into(), outfp.into()],
                        "wn",
                    )
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("fwrite returned void".into()))?
                    .into_int_value();
                builder
                    .build_call(fflush, &[outfp.into()], "wflush")
                    .map_err(Self::err)?;
                let n32 = builder
                    .build_int_truncate(n, i32t, "wn32")
                    .map_err(Self::err)?;
                builder.build_store(wslot, n32).map_err(Self::err)?;
                let full = builder
                    .build_int_compare(IntPredicate::EQ, n32, bytes, "wfull")
                    .map_err(Self::err)?;
                let res = builder
                    .build_select(full, i32t.const_int(1, false), i32t.const_zero(), "wres")
                    .map_err(Self::err)?
                    .into_int_value();
                builder.build_return(Some(&res)).map_err(Self::err)?;
            }
            {
                let entry = ctx.append_basic_block(read_file, "entry");
                builder.position_at_end(entry);
                let h = read_file.get_nth_param(0).unwrap().into_int_value();
                let bufpp = read_file.get_nth_param(1).unwrap().into_pointer_value();
                let bytes = read_file.get_nth_param(2).unwrap().into_int_value();
                let readp = read_file.get_nth_param(3).unwrap().into_pointer_value();
                // Same: `readp` is already the caller's i32 slot address.
                let rslot = readp;
                builder
                    .build_store(rslot, i32t.const_zero())
                    .map_err(Self::err)?;
                let is_in = builder
                    .build_int_compare(IntPredicate::EQ, h, i32t.const_zero(), "risin")
                    .map_err(Self::err)?;
                let bpos = builder
                    .build_int_compare(IntPredicate::SGT, bytes, i32t.const_zero(), "rbpos")
                    .map_err(Self::err)?;
                let go = builder.build_and(is_in, bpos, "rgo").map_err(Self::err)?;
                let body = ctx.append_basic_block(read_file, "rbody");
                let done = ctx.append_basic_block(read_file, "rdone");
                builder
                    .build_conditional_branch(go, body, done)
                    .map_err(Self::err)?;
                builder.position_at_end(done);
                builder
                    .build_return(Some(&i32t.const_zero()))
                    .map_err(Self::err)?;
                builder.position_at_end(body);
                let inpath = builder
                    .build_global_string_ptr("/dev/stdin", "rdev")
                    .map_err(Self::err)?
                    .as_pointer_value();
                let rfd = builder
                    .build_call(open_fd, &[inpath.into(), i32t.const_zero().into()], "rofd")
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("open returned void".into()))?
                    .into_int_value();
                let rmode = builder
                    .build_global_string_ptr("r", "rmode")
                    .map_err(Self::err)?
                    .as_pointer_value();
                let infp = builder
                    .build_call(fdopen, &[rfd.into(), rmode.into()], "rinfp")
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("fdopen returned void".into()))?
                    .into_pointer_value();
                let b64 = builder
                    .build_int_s_extend(bytes, i64t, "rb64")
                    .map_err(Self::err)?;
                let one = i64t.const_int(1, false);
                let tmp = builder
                    .build_call(calloc, &[b64.into(), one.into()], "rtmp")
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                    .into_pointer_value();
                let n = builder
                    .build_call(
                        fread,
                        &[tmp.into(), one.into(), b64.into(), infp.into()],
                        "rn",
                    )
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("fread returned void".into()))?
                    .into_int_value();
                // Fresh byte-string of exactly `n` bytes: 8-byte length prefix at
                // base[0..8], data at base+8 (same layout as str_new, inlined —
                // Emit::new has no `self`).
                let total = builder
                    .build_int_add(n, i64t.const_int(9, false), "rtot")
                    .map_err(Self::err)?;
                let base = builder
                    .build_call(calloc, &[total.into(), one.into()], "rbase")
                    .map_err(Self::err)?
                    .try_as_basic_value()
                    .basic()
                    .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                    .into_pointer_value();
                let nslot = builder.build_alloca(i64t, "rnslot").map_err(Self::err)?;
                builder.build_store(nslot, n).map_err(Self::err)?;
                builder
                    .build_call(
                        memcpy,
                        &[base.into(), nslot.into(), i64t.const_int(8, false).into()],
                        "rlenw",
                    )
                    .map_err(Self::err)?;
                let data = unsafe {
                    builder
                        .build_in_bounds_gep(
                            ctx.i8_type(),
                            base,
                            &[i64t.const_int(8, false)],
                            "rdata",
                        )
                        .map_err(Self::err)?
                };
                let has = builder
                    .build_int_compare(IntPredicate::UGT, n, i64t.const_zero(), "rhas")
                    .map_err(Self::err)?;
                let cp = ctx.append_basic_block(read_file, "rcp");
                let nocp = ctx.append_basic_block(read_file, "rnocp");
                builder
                    .build_conditional_branch(has, cp, nocp)
                    .map_err(Self::err)?;
                builder.position_at_end(cp);
                builder
                    .build_call(memcpy, &[data.into(), tmp.into(), n.into()], "rmc")
                    .map_err(Self::err)?;
                builder
                    .build_unconditional_branch(nocp)
                    .map_err(Self::err)?;
                builder.position_at_end(nocp);
                // *buf = dst: `bufpp` is already the caller's char* slot address
                // (char**) — store the new pointer directly.
                builder.build_store(bufpp, data).map_err(Self::err)?;
                let n32 = builder
                    .build_int_truncate(n, i32t, "rn32")
                    .map_err(Self::err)?;
                builder.build_store(rslot, n32).map_err(Self::err)?;
                let any = builder
                    .build_int_compare(IntPredicate::UGT, n32, i32t.const_zero(), "rany")
                    .map_err(Self::err)?;
                let res = builder
                    .build_select(any, i32t.const_int(1, false), i32t.const_zero(), "rres")
                    .map_err(Self::err)?
                    .into_int_value();
                builder.build_return(Some(&res)).map_err(Self::err)?;
            }
            builder.position_at_end(main_entry);
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
                byref_params: HashMap::new(),
                byref_array_params: HashMap::new(),
                file_open_mode,
                fclose,
                fseek,
                ftell,
                fwrite,
                fread,
                fflush,
                getstdhandle,
                write_file,
                read_file,
                file_eof,
                file_table,
                dyn_resize,
                dyn_arrays: std::collections::HashSet::new(),
                vars: HashMap::new(),
                shared: HashMap::new(),
                shared_arrays: HashMap::new(),
                funcs: HashMap::new(),
                func_ids: HashMap::new(),
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

        /// Runtime array descriptor `{ ptr data, [4 x i64] dims }` for passing a 1-D array
        /// by reference: the caller stores the buffer pointer + dim counts, the callee GEPs
        /// the fields and reads through them (read-only sharing).
        fn arr_desc_ty(&self) -> inkwell::types::StructType<'ctx> {
            self.ctx
                .struct_type(&[self.ptr.into(), self.i64t.array_type(4).into()], false)
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
                idxs.push(
                    self.builder
                        .build_int_s_extend(ik, self.i64t, "ik")
                        .map_err(Self::err)?,
                );
            }
            // off = 0; for each recorded dim k: off = off*count_k + idx_k (missing idx -> 0).
            let mut off = self.i64t.const_zero();
            for (k, cslot) in dims.iter().enumerate() {
                let ck = self
                    .builder
                    .build_load(self.i64t, *cslot, "ck")
                    .map_err(Self::err)?
                    .into_int_value();
                let ik = idxs
                    .get(k)
                    .copied()
                    .unwrap_or_else(|| self.i64t.const_zero());
                let m = self
                    .builder
                    .build_int_mul(off, ck, "offm")
                    .map_err(Self::err)?;
                off = self
                    .builder
                    .build_int_add(m, ik, "offa")
                    .map_err(Self::err)?;
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
                if let IrItem::Function {
                    name,
                    params,
                    return_type,
                    ..
                } = item
                {
                    if entry.as_deref() == Some(name.as_str()) {
                        continue;
                    }
                    let refset = self.byref_params.get(name);
                    let aref = self.byref_array_params.get(name);
                    let pts: Vec<BasicMetadataTypeEnum> = params
                        .iter()
                        .enumerate()
                        .map(|(i, p)| {
                            if refset.is_some_and(|r| r.contains(&i))
                                || aref.is_some_and(|r| r.contains(&i))
                            {
                                self.ptr.into()
                            } else {
                                self.llvm_type(p.value_type).into()
                            }
                        })
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

        /// Create an LLVM global for every `SHARED` scalar (each `SharedAssignment`
        /// target, in any function), so `SharedAssignment` stores and `SharedVariable`
        /// reads resolve to a module-persistent slot — matching the interpreter's
        /// `state.shared` and the C backend's `xb_shared_<name>` globals. A shared
        /// variable never assigned has no global and reads its type default (as in the
        /// interpreter), so collecting assignment targets is sufficient.
        fn declare_shared(&mut self, items: &[IrItem]) {
            let mut names: std::collections::BTreeMap<String, ValueType> =
                std::collections::BTreeMap::new();
            collect_shared(items, &mut names);
            // LLVM-SHARED-ARR: shared array DIMs get program-global storage
            // (buffer holder + per-dim count slots) so every function shares
            // one backing store. First DIM site wins; later sites reuse it.
            {
                fn scan_shared_arr_dims<'a>(
                    items: &'a [IrItem],
                    out: &mut Vec<(&'a str, ValueType, usize)>,
                ) {
                    for it in items {
                        match it {
                            IrItem::Dim {
                                symbol,
                                shared: true,
                                is_array: true,
                                extra_dims,
                                ..
                            } => {
                                out.push((
                                    symbol.name.as_str(),
                                    symbol.value_type,
                                    1 + extra_dims.len(),
                                ));
                            }
                            IrItem::If {
                                then_body,
                                else_body,
                                ..
                            } => {
                                scan_shared_arr_dims(then_body, out);
                                if let Some(eb) = else_body {
                                    scan_shared_arr_dims(eb, out);
                                }
                            }
                            IrItem::While { body, .. }
                            | IrItem::For { body, .. }
                            | IrItem::DoLoop { body, .. }
                            | IrItem::Compound(body) => scan_shared_arr_dims(body, out),
                            IrItem::SelectCase { cases, default, .. } => {
                                for c in cases {
                                    scan_shared_arr_dims(&c.body, out);
                                }
                                if let Some(d) = default {
                                    scan_shared_arr_dims(d, out);
                                }
                            }
                            _ => {}
                        }
                    }
                }
                let mut arrs: Vec<(&str, ValueType, usize)> = Vec::new();
                scan_shared_arr_dims(items, &mut arrs);
                for (name, vt, ndims) in arrs {
                    if self.shared_arrays.contains_key(name) {
                        continue;
                    }
                    let holder = self
                        .module
                        .add_global(self.ptr, None, &format!("xb_sarr_{name}"));
                    holder.set_initializer(&self.ptr.const_null());
                    let mut shape = Vec::with_capacity(ndims);
                    for k in 0..ndims {
                        let g = self.module.add_global(
                            self.i64t,
                            None,
                            &format!("xb_sarr_{name}_d{k}"),
                        );
                        g.set_initializer(&self.i64t.const_zero());
                        shape.push(g.as_pointer_value());
                    }
                    self.shared_arrays
                        .insert(name.to_string(), (holder.as_pointer_value(), vt, shape));
                }
            }
            for (name, vt) in names {
                let g =
                    self.module
                        .add_global(self.llvm_type(vt), None, &format!("xb_shared_{name}"));
                let init: BasicValueEnum = match vt {
                    ValueType::String => self.ptr.const_null().into(),
                    ValueType::Float => self.f64t.const_zero().into(),
                    ValueType::Giant => self.i64t.const_zero().into(),
                    ValueType::Integer => self.i32t.const_zero().into(),
                };
                g.set_initializer(&init);
                self.shared.insert(name, (g.as_pointer_value(), vt));
            }
        }

        /// Emit each non-entry user function body in its own variable scope.
        fn emit_function_bodies(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            let entry = entry_name(items);
            for item in items {
                if let IrItem::Function {
                    name,
                    params,
                    return_type,
                    body,
                } = item
                {
                    if entry.as_deref() == Some(name.as_str()) {
                        continue;
                    }
                    let f = self.funcs[name];
                    let saved_vars = std::mem::take(&mut self.vars);
                    let saved_arrays = std::mem::take(&mut self.arrays);
                    // Shared arrays are program-global: every function sees the
                    // same holder/shape slots regardless of DIM execution order.
                    for (n, (h, vt, sh)) in self.shared_arrays.clone() {
                        self.arrays.insert(n, (h, vt, sh));
                    }
                    let (saved_fn, saved_ret) = (self.cur_fn, self.cur_ret);
                    self.cur_fn = f;
                    self.cur_ret = *return_type;
                    let bb = self.ctx.append_basic_block(f, "entry");
                    self.builder.position_at_end(bb);
                    let refset = self.byref_params.get(name).cloned();
                    let aref = self.byref_array_params.get(name).cloned();
                    for (i, p) in params.iter().enumerate() {
                        let arg = f.get_nth_param(i as u32);
                        if aref.as_ref().is_some_and(|r| r.contains(&i)) {
                            // @array param: the arg is a `{data, dims}` descriptor pointer.
                            // GEP its fields as the array's holder + dim-0 slot so array ops
                            // read the shared buffer/count (1-D read-only sharing).
                            if let Some(a) = arg {
                                let dty = self.arr_desc_ty();
                                let desc = a.into_pointer_value();
                                let holder = self
                                    .builder
                                    .build_struct_gep(dty, desc, 0, "phdata")
                                    .map_err(|_| {
                                        CompileError::Llvm("param desc data gep".into())
                                    })?;
                                let dims0 = self
                                    .builder
                                    .build_struct_gep(dty, desc, 1, "phdims")
                                    .map_err(|_| {
                                    CompileError::Llvm("param desc dims gep".into())
                                })?;
                                self.arrays
                                    .insert(p.name.clone(), (holder, p.value_type, vec![dims0]));
                            }
                        } else if refset.as_ref().is_some_and(|r| r.contains(&i)) {
                            // By-ref scalar param: the LLVM arg is a pointer to the caller's
                            // slot; use it directly so reads/writes share it.
                            if let Some(a) = arg {
                                self.vars
                                    .insert(p.name.clone(), (a.into_pointer_value(), p.value_type));
                            }
                        } else {
                            let slot = self.get_or_alloca(&p.name, p.value_type)?;
                            if let Some(a) = arg {
                                self.builder.build_store(slot, a).map_err(Self::err)?;
                            }
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
                self.builder
                    .build_unconditional_branch(bb)
                    .map_err(Self::err)?;
            }
            Ok(())
        }

        fn emit_items(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            for item in items {
                self.emit_item(item)?;
                // A jump (SM GOTO/GOSUB/RETURN) or function return terminates the block;
                // the remaining items are unreachable — stop so we never build past a
                // terminator (invalid IR).
                if self
                    .builder
                    .get_insert_block()
                    .and_then(|b| b.get_terminator())
                    .is_some()
                {
                    break;
                }
            }
            Ok(())
        }

        /// Emit a body: a `pc`-dispatch state machine for label-bearing bodies (`GOSUB`/
        /// `GOTO`/labels), else the straight-line path. GOSUBs — including ones nested in
        /// `IF`/`FOR`/… — resume via per-site landing blocks (see `SmCtx`).
        fn emit_body(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            self.prealloc_arrays(items)?;
            self.prealloc_scalars(items)?;
            if body_has_labels(items) {
                self.emit_body_sm(items)
            } else {
                self.emit_items(items)
            }
        }

        /// Pre-create a zero-initialized alloca for every scalar assigned in this body, so a
        /// read emitted before its assignment (auto-vivified counters, `INC` after a first
        /// read, forward references inside loops) loads the stored value rather than a frozen
        /// undefined-variable constant (see `collect_assigned_scalars`). Params, by-ref args,
        /// and arrays are already registered in `self.vars`/`self.arrays` before the body is
        /// emitted, so `get_or_alloca` returns those untouched and this never shadows them.
        fn prealloc_scalars(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            let mut assigned = std::collections::BTreeMap::new();
            collect_assigned_scalars(items, &mut assigned);
            for (name, vt) in assigned {
                if self.vars.contains_key(&name) || self.arrays.contains_key(&name) {
                    continue;
                }
                let slot = self.get_or_alloca(&name, vt)?;
                let default: BasicValueEnum = match vt {
                    ValueType::String => self.str_const(b"")?.into(),
                    ValueType::Float => self.f64t.const_zero().into(),
                    _ => self.i32t.const_zero().into(),
                };
                self.builder.build_store(slot, default).map_err(Self::err)?;
            }
            Ok(())
        }

        /// Pre-register every array `DIM`'d in this body — an entry-block holder (null) plus
        /// one zero-initialized i64 count slot per dimension — so a `UBOUND`/element access
        /// emitted before the `DIM` in emission order (e.g. after a GOSUB to a subroutine that
        /// DIMs the array) reads the same slots the DIM later writes, instead of the
        /// unknown-array default (−1). The `DIM` arm reuses these slots when the dimensionality
        /// matches. Arrays already registered (by-ref array params) are left untouched.
        fn prealloc_arrays(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            let mut dims = std::collections::BTreeMap::new();
            collect_dim_arrays(items, &mut dims);
            for (name, (elem, ndims)) in dims {
                if self.arrays.contains_key(&name) {
                    continue;
                }
                let holder = self.entry_alloca(self.ptr.into(), &name)?;
                self.builder
                    .build_store(holder, self.ptr.const_null())
                    .map_err(Self::err)?;
                let mut shape = Vec::with_capacity(ndims);
                for k in 0..ndims {
                    let s = self.entry_alloca(self.i64t.into(), &format!("{name}_d{k}"))?;
                    self.builder
                        .build_store(s, self.i64t.const_zero())
                        .map_err(Self::err)?;
                    shape.push(s);
                }
                self.arrays.insert(name, (holder, elem, shape));
            }
            Ok(())
        }

        /// State-machine emission for a label-bearing body: one block per top-level item,
        /// dispatched by a `pc` switch; GOSUB/GOTO/RETURN set `pc` and re-dispatch (mirrors
        /// the interpreter's index-based `exec_items`). A GOSUB pushes a fresh *landing* pc
        /// and resumes there, so a GOSUB nested in an `IF`/`FOR`/… returns to exactly after
        /// itself. The dispatch switch is built after emission, once every landing pc is
        /// known. Leaves the builder at the exit block so the caller can build the return.
        fn emit_body_sm(&mut self, items: &[IrItem]) -> Result<(), CompileError> {
            let n = items.len() as u64;
            let mut labels: HashMap<String, u64> = HashMap::new();
            for (i, it) in items.iter().enumerate() {
                if let IrItem::Label(name) = it {
                    labels.insert(name.clone(), i as u64);
                }
            }
            let pc = self
                .builder
                .build_alloca(self.i32t, "pc")
                .map_err(Self::err)?;
            self.builder
                .build_store(pc, self.i32t.const_zero())
                .map_err(Self::err)?;
            let retstack = self
                .builder
                .build_array_alloca(self.i32t, self.i32t.const_int(256, false), "retstack")
                .map_err(Self::err)?;
            let retsp = self
                .builder
                .build_alloca(self.i32t, "retsp")
                .map_err(Self::err)?;
            self.builder
                .build_store(retsp, self.i32t.const_zero())
                .map_err(Self::err)?;
            let dispatch = self.ctx.append_basic_block(self.cur_fn, "sm.dispatch");
            let exit = self.ctx.append_basic_block(self.cur_fn, "sm.exit");
            let blocks: Vec<BasicBlock<'ctx>> = (0..items.len())
                .map(|i| {
                    self.ctx
                        .append_basic_block(self.cur_fn, &format!("sm.pc{i}"))
                })
                .collect();
            let saved = self.sm.take();
            self.sm = Some(SmCtx {
                dispatch,
                pc,
                retstack,
                retsp,
                labels,
                count: n,
                landings: Vec::new(),
            });
            self.builder
                .build_unconditional_branch(dispatch)
                .map_err(Self::err)?;
            // Emit each top-level item; nested GOSUBs append landing blocks to `sm.landings`
            // and leave the builder on their landing so emission continues past them.
            for (i, it) in items.iter().enumerate() {
                self.builder.position_at_end(blocks[i]);
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
                    self.builder
                        .build_unconditional_branch(dispatch)
                        .map_err(Self::err)?;
                }
            }
            // Build the dispatch switch now that every landing pc is known: a case per
            // top-level block (`0..n`) plus one per GOSUB landing (`count..`). An unknown pc
            // (e.g. `SM_EXIT_PC` from an empty RETURN) falls through to `exit`.
            self.builder.position_at_end(dispatch);
            let pcv = self
                .builder
                .build_load(self.i32t, pc, "pcv")
                .map_err(Self::err)?
                .into_int_value();
            let landings = self.sm.as_ref().unwrap().landings.clone();
            let mut cases: Vec<(IntValue<'ctx>, BasicBlock<'ctx>)> = blocks
                .iter()
                .enumerate()
                .map(|(i, b)| (self.i32t.const_int(i as u64, false), *b))
                .collect();
            for (lpc, lb) in landings {
                cases.push((self.i32t.const_int(lpc, false), lb));
            }
            self.builder
                .build_switch(pcv, exit, &cases)
                .map_err(Self::err)?;
            self.builder.position_at_end(exit);
            self.sm = saved;
            Ok(())
        }

        fn emit_item(&mut self, item: &IrItem) -> Result<(), CompileError> {
            match item {
                IrItem::Dim {
                    symbol,
                    is_array: false,
                    shared: false,
                    ..
                } => {
                    let slot = self.get_or_alloca(&symbol.name, symbol.value_type)?;
                    let init: BasicValueEnum = match symbol.value_type {
                        ValueType::String => self.str_const(b"")?.into(),
                        ValueType::Float => self.f64t.const_zero().into(),
                        _ => self.i32t.const_zero().into(),
                    };
                    self.builder.build_store(slot, init).map_err(Self::err)?;
                }
                IrItem::Dim {
                    symbol,
                    size,
                    extra_dims,
                    is_array: true,
                    shared: true,
                    ..
                } => {
                    // LLVM-SHARED-ARR: store the buffer + per-dim counts into the
                    // program-global slots declared by declare_shared so every
                    // function shares one backing store.
                    let elem = symbol.value_type;
                    let Some((holder, _, shape)) = self.shared_arrays.get(&symbol.name).cloned()
                    else {
                        return Err(CompileError::Llvm(format!(
                            "shared array {} missing global declaration",
                            symbol.name
                        )));
                    };
                    let esz: u64 = match elem {
                        ValueType::Float | ValueType::String => 8,
                        _ => 4,
                    };
                    let mut total = self.i64t.const_int(1, false);
                    for e in size.iter().chain(extra_dims.iter()) {
                        let raw = self.eval_int(e)?;
                        let pos = self
                            .builder
                            .build_int_compare(
                                IntPredicate::SGT,
                                raw,
                                self.i32t.const_zero(),
                                "pos",
                            )
                            .map_err(Self::err)?;
                        let nn = self
                            .builder
                            .build_select(pos, raw, self.i32t.const_zero(), "max0")
                            .map_err(Self::err)?
                            .into_int_value();
                        let nn64 = self
                            .builder
                            .build_int_s_extend(nn, self.i64t, "nn64")
                            .map_err(Self::err)?;
                        let cnt = self
                            .builder
                            .build_int_add(nn64, self.i64t.const_int(1, false), "cnt")
                            .map_err(Self::err)?;
                        total = self
                            .builder
                            .build_int_mul(total, cnt, "tot")
                            .map_err(Self::err)?;
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
                    self.builder.build_store(holder, buf).map_err(Self::err)?;
                    // Store per-dim counts into the global shape slots.
                    for (k, e) in size.iter().chain(extra_dims.iter()).enumerate() {
                        let raw = self.eval_int(e)?;
                        let pos = self
                            .builder
                            .build_int_compare(
                                IntPredicate::SGT,
                                raw,
                                self.i32t.const_zero(),
                                "pos",
                            )
                            .map_err(Self::err)?;
                        let nn = self
                            .builder
                            .build_select(pos, raw, self.i32t.const_zero(), "max0")
                            .map_err(Self::err)?
                            .into_int_value();
                        let nn64 = self
                            .builder
                            .build_int_s_extend(nn, self.i64t, "nn64")
                            .map_err(Self::err)?;
                        let cnt = self
                            .builder
                            .build_int_add(nn64, self.i64t.const_int(1, false), "cnt")
                            .map_err(Self::err)?;
                        if let Some(s) = shape.get(k) {
                            self.builder.build_store(*s, cnt).map_err(Self::err)?;
                        }
                    }
                    self.shared_arrays
                        .insert(symbol.name.clone(), (holder, elem, shape.clone()));
                    self.arrays
                        .insert(symbol.name.clone(), (holder, elem, shape));
                }
                IrItem::Dim {
                    symbol,
                    size,
                    extra_dims,
                    is_array: true,
                    redim,
                    ..
                } => {
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
                            .build_int_compare(
                                IntPredicate::SGT,
                                raw,
                                self.i32t.const_zero(),
                                "pos",
                            )
                            .map_err(Self::err)?;
                        let nn = self
                            .builder
                            .build_select(pos, raw, self.i32t.const_zero(), "max0")
                            .map_err(Self::err)?
                            .into_int_value();
                        let nn64 = self
                            .builder
                            .build_int_s_extend(nn, self.i64t, "nn64")
                            .map_err(Self::err)?;
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
                        total = self
                            .builder
                            .build_int_mul(total, *c, "tot")
                            .map_err(Self::err)?;
                    }
                    // Dynamic arrays (empty-bracket DIM or REDIM'd): the count
                    // slots must exist BEFORE the buffer op — auto-vivify writes
                    // and content-preserving REDIM resize through them.
                    let is_dyn = self.dyn_arrays.contains(&symbol.name);
                    let existing = self.arrays.get(&symbol.name).cloned();
                    let shape: Vec<PointerValue<'ctx>> = if is_dyn {
                        match &existing {
                            Some((_, _, sh)) if sh.len() == counts.len() => {
                                for (s, c) in sh.iter().zip(counts.iter()) {
                                    self.builder.build_store(*s, *c).map_err(Self::err)?;
                                }
                                sh.clone()
                            }
                            _ => {
                                let mut sh = Vec::with_capacity(counts.len().max(1));
                                for (k, c) in counts.iter().enumerate() {
                                    let s = self.entry_alloca(
                                        self.i64t.into(),
                                        &format!("{}_d{k}", symbol.name),
                                    )?;
                                    self.builder.build_store(s, *c).map_err(Self::err)?;
                                    sh.push(s);
                                }
                                if sh.is_empty() {
                                    // `DIM a$[]`: one count slot at 0 (UBOUND -1)
                                    // so auto-vivify writes have a counter.
                                    let s = self.entry_alloca(
                                        self.i64t.into(),
                                        &format!("{}_d0", symbol.name),
                                    )?;
                                    self.builder
                                        .build_store(s, self.i64t.const_zero())
                                        .map_err(Self::err)?;
                                    sh.push(s);
                                }
                                sh
                            }
                        }
                    } else {
                        match &existing {
                            Some((_, _, sh)) if sh.len() == counts.len() => {
                                for (s, c) in sh.iter().zip(counts.iter()) {
                                    self.builder.build_store(*s, *c).map_err(Self::err)?;
                                }
                                sh.clone()
                            }
                            _ => {
                                let mut sh = Vec::with_capacity(counts.len());
                                for (k, c) in counts.iter().enumerate() {
                                    let s = self.entry_alloca(
                                        self.i64t.into(),
                                        &format!("{}_d{k}", symbol.name),
                                    )?;
                                    self.builder.build_store(s, *c).map_err(Self::err)?;
                                    sh.push(s);
                                }
                                sh
                            }
                        }
                    };
                    let holder = match &existing {
                        Some((h, _, _)) => *h,
                        None => self.entry_alloca(self.ptr.into(), &symbol.name)?,
                    };
                    let is_str_b = self
                        .ctx
                        .bool_type()
                        .const_int(u64::from(elem == ValueType::String), false);
                    let buf = if is_dyn && *redim {
                        // Content-preserving REDIM: realloc + fill the grown tail.
                        // The helper stores the new buffer into `holder` itself.
                        self.builder
                            .build_call(
                                self.dyn_resize,
                                &[
                                    holder.into(),
                                    shape[0].into(),
                                    total.into(),
                                    self.i64t.const_int(esz, false).into(),
                                    is_str_b.into(),
                                ],
                                "redim",
                            )
                            .map_err(Self::err)?;
                        self.builder
                            .build_load(self.ptr, holder, "redbuf")
                            .map_err(Self::err)?
                            .into_pointer_value()
                    } else {
                        if is_dyn {
                            // Fresh dynamic holder: NULL so realloc(NULL,·) in the
                            // grow helper behaves as malloc.
                            if existing.is_none() {
                                self.builder
                                    .build_store(holder, self.ptr.const_null())
                                    .map_err(Self::err)?;
                            }
                        }
                        self.builder
                            .build_call(
                                self.calloc,
                                &[total.into(), self.i64t.const_int(esz, false).into()],
                                "arr",
                            )
                            .map_err(Self::err)?
                            .try_as_basic_value()
                            .basic()
                            .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                            .into_pointer_value()
                    };
                    self.builder.build_store(holder, buf).map_err(Self::err)?;
                    self.arrays
                        .insert(symbol.name.clone(), (holder, elem, shape));
                }
                IrItem::Assignment { target, value } => {
                    if let Some(v) = self.eval_value(value)? {
                        let slot = self.get_or_alloca(&target.name, target.value_type)?;
                        let v = self.coerce_to(v, self.llvm_type(target.value_type).into())?;
                        self.builder.build_store(slot, v).map_err(Self::err)?;
                    }
                }
                IrItem::SharedAssignment { target, value } => {
                    // Store to the module-shared global (mirrors the interpreter's
                    // exec_shared and the C backend's `xb_shared_<name> = …`); declared
                    // up front by declare_shared. Previously fell through `_ => {}`, so a
                    // shared write was silently dropped.
                    if let (Some(v), Some((slot, vt))) = (
                        self.eval_value(value)?,
                        self.shared.get(&target.name).copied(),
                    ) {
                        let v = self.coerce_to(v, self.llvm_type(vt).into())?;
                        self.builder.build_store(slot, v).map_err(Self::err)?;
                    }
                }
                IrItem::ArrayAssignment {
                    target,
                    index,
                    extra_indices,
                    value,
                } => {
                    let v = self.eval_value(value)?;
                    // CGEN-AUTOVIVIFY parity: a 1-D write past a dynamic array's
                    // count grows the storage (preserving content) before the store.
                    if extra_indices.is_empty() && self.dyn_arrays.contains(&target.name) {
                        if let Some((holder, elem, dims)) = self.arrays.get(&target.name).cloned()
                        {
                            if let Some(cnt) = dims.first().copied() {
                                let raw = self.eval_int(index)?;
                                let idx64 = self
                                    .builder
                                    .build_int_s_extend(raw, self.i64t, "avidx")
                                    .map_err(Self::err)?;
                                // The count slot holds ELEMENT COUNT (ubound+1):
                                // a write at index i needs count >= i+1, and
                                // must NEVER shrink existing storage.
                                let idx1 = self
                                    .builder
                                    .build_int_add(
                                        idx64,
                                        self.i64t.const_int(1, false),
                                        "avidx1",
                                    )
                                    .map_err(Self::err)?;
                                let cur = self
                                    .builder
                                    .build_load(self.i64t, cnt, "avcur")
                                    .map_err(Self::err)?
                                    .into_int_value();
                                let bigger = self
                                    .builder
                                    .build_int_compare(
                                        IntPredicate::SGT,
                                        cur,
                                        idx1,
                                        "avbigger",
                                    )
                                    .map_err(Self::err)?;
                                let want = self
                                    .builder
                                    .build_select(
                                        bigger,
                                        cur,
                                        idx1,
                                        "avwant",
                                    )
                                    .map_err(Self::err)?;
                                let esz: u64 = match elem {
                                    ValueType::Float | ValueType::String => 8,
                                    _ => 4,
                                };
                                self.builder
                                    .build_call(
                                        self.dyn_resize,
                                        &[
                                            holder.into(),
                                            cnt.into(),
                                            want.into(),
                                            self.i64t
                                                .const_int(esz, false)
                                                .into(),
                                            self.ctx
                                                .bool_type()
                                                .const_int(
                                                    u64::from(elem == ValueType::String),
                                                    false,
                                                )
                                                .into(),
                                        ],
                                        "avgrow",
                                    )
                                    .map_err(Self::err)?;
                            }
                        }
                    }
                    if let (Some(v), Some((ep, elem))) = (
                        v,
                        self.array_elem_ptr(&target.name, index, extra_indices)?,
                    ) {
                        let v = self.coerce_to(v, self.llvm_type(elem).into())?;
                        self.builder.build_store(ep, v).map_err(Self::err)?;
                    }
                }
                IrItem::MidAssign {
                    target,
                    start,
                    length,
                    value,
                } => {
                    self.mid_assign(target, start, length, value)?;
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
                IrItem::If {
                    condition,
                    then_body,
                    else_body,
                } => {
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
                IrItem::DoLoop {
                    pre_condition,
                    post_condition,
                    body,
                } => {
                    // `loop { [pre-check→exit]; body; [post-check→exit] }` — mirrors the
                    // interpreter. A `WHILE` guard continues while its condition is nonzero; an
                    // `UNTIL` guard continues while it is zero (`is_while` is compile-time).
                    let header = self.ctx.append_basic_block(self.cur_fn, "do.head");
                    let body_bb = self.ctx.append_basic_block(self.cur_fn, "do.body");
                    let exit = self.ctx.append_basic_block(self.cur_fn, "do.exit");
                    self.branch_to(header)?;
                    self.builder.position_at_end(header);
                    match pre_condition {
                        Some((cond, is_while)) => {
                            let c = self.eval_bool(cond)?;
                            let keep = if *is_while {
                                c
                            } else {
                                self.builder.build_not(c, "do.pre.not").map_err(Self::err)?
                            };
                            self.builder
                                .build_conditional_branch(keep, body_bb, exit)
                                .map_err(Self::err)?;
                        }
                        None => self.branch_to(body_bb)?,
                    }
                    self.builder.position_at_end(body_bb);
                    self.emit_items(body)?;
                    // Post-condition / back-edge, only if the body did not already terminate
                    // the block (e.g. an unconditional RETURN inside the loop).
                    let open = self
                        .builder
                        .get_insert_block()
                        .and_then(|b| b.get_terminator())
                        .is_none();
                    if open {
                        match post_condition {
                            Some((cond, is_while)) => {
                                let c = self.eval_bool(cond)?;
                                let keep = if *is_while {
                                    c
                                } else {
                                    self.builder
                                        .build_not(c, "do.post.not")
                                        .map_err(Self::err)?
                                };
                                self.builder
                                    .build_conditional_branch(keep, header, exit)
                                    .map_err(Self::err)?;
                            }
                            None => {
                                self.builder
                                    .build_unconditional_branch(header)
                                    .map_err(Self::err)?;
                            }
                        }
                    }
                    self.builder.position_at_end(exit);
                }
                IrItem::For {
                    var,
                    start,
                    end,
                    step,
                    body,
                } => {
                    let slot = self.get_or_alloca(&var.name, ValueType::Integer)?;
                    let start_v = self.eval_int(start)?;
                    self.builder.build_store(slot, start_v).map_err(Self::err)?;
                    // Hoist the loop bound and step into entry allocas and re-load them each
                    // pass. In a state machine a nested GOSUB's landing re-enters the loop via
                    // the global dispatch, bypassing this setup block, so a once-computed SSA
                    // bound/step would fail to dominate the header/increment. Memory always
                    // dominates (entry allocas), so the loop stays correct across GOSUBs.
                    let end_slot = self.entry_alloca(self.i32t.into(), "for.end")?;
                    let end_v = self.eval_int(end)?;
                    self.builder
                        .build_store(end_slot, end_v)
                        .map_err(Self::err)?;
                    let step_slot = self.entry_alloca(self.i32t.into(), "for.step")?;
                    let step_v = match step {
                        Some(s) => self.eval_int(s)?,
                        None => self.i32t.const_int(1, true),
                    };
                    self.builder
                        .build_store(step_slot, step_v)
                        .map_err(Self::err)?;
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
                    let end_l = self
                        .builder
                        .build_load(self.i32t, end_slot, "for.endl")
                        .map_err(Self::err)?
                        .into_int_value();
                    let step_l = self
                        .builder
                        .build_load(self.i32t, step_slot, "for.stepl")
                        .map_err(Self::err)?
                        .into_int_value();
                    let zero = self.i32t.const_zero();
                    let up = self
                        .builder
                        .build_int_compare(IntPredicate::SGE, step_l, zero, "for.up")
                        .map_err(Self::err)?;
                    let le = self
                        .builder
                        .build_int_compare(IntPredicate::SLE, cur, end_l, "for.le")
                        .map_err(Self::err)?;
                    let ge = self
                        .builder
                        .build_int_compare(IntPredicate::SGE, cur, end_l, "for.ge")
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
                    if self
                        .builder
                        .get_insert_block()
                        .and_then(|b| b.get_terminator())
                        .is_none()
                    {
                        let cur2 = self
                            .builder
                            .build_load(self.i32t, slot, "for.cur2")
                            .map_err(Self::err)?
                            .into_int_value();
                        let step2 = self
                            .builder
                            .build_load(self.i32t, step_slot, "for.step2")
                            .map_err(Self::err)?
                            .into_int_value();
                        let next = self
                            .builder
                            .build_int_add(cur2, step2, "for.next")
                            .map_err(Self::err)?;
                        self.builder.build_store(slot, next).map_err(Self::err)?;
                        self.branch_to(header)?;
                    }
                    self.builder.position_at_end(exit);
                }
                IrItem::Compound(items) => self.emit_items(items)?,
                IrItem::SelectCase {
                    selector,
                    cases,
                    default,
                } => {
                    // Equality chain matching exec_select_case (first matching CASE wins).
                    if let Some(sel) = self.eval_value(selector)? {
                        let done = self.ctx.append_basic_block(self.cur_fn, "select.done");
                        for case in cases {
                            for cond in &case.conditions {
                                let Some(cv) = self.eval_value(cond)? else {
                                    continue;
                                };
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
                    eprintln!("TRACE arm reached {}", name);
                    if let Some(&f) = self.funcs.get(name) {
                        if let Some(argv) = self.eval_args(f, args)? {
                            self.builder
                                .build_call(f, &argv, "call")
                                .map_err(Self::err)?;
                        }
                    } else if matches!(
                        name.as_str(),
                        "__WRITE_RECORD" | "__READ_RECORD" | "WriteFile" | "ReadFile"
                    ) {
                        // Side-effecting file builtins used as statements (`WRITE`/`READ [n], arr[]`
                        // lower to these). Other statement builtins are pure or unimplemented, so
                        // are correctly ignored here; CLOSE is intentionally a no-op (the file
                        // runtime flushes on write, matching the interpreter's no-op `CLOSE(-1)`).
                        let _ = self.eval_builtin(name, args)?;
                    }
                }
                // Label/GOSUB/GOTO items: no-ops outside a state-machine body; inside one
                // they set `pc` and branch to the dispatch (GOSUB via a resume landing).
                IrItem::Label(_) => {}
                IrItem::Goto(name) => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc) = (ctx.dispatch, ctx.pc);
                        let target = ctx.labels.get(name).copied().unwrap_or(SM_EXIT_PC);
                        self.builder
                            .build_store(pc, self.i32t.const_int(target, false))
                            .map_err(Self::err)?;
                        self.builder
                            .build_unconditional_branch(dispatch)
                            .map_err(Self::err)?;
                    }
                }
                IrItem::GotoExpr(expr) => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc) = (ctx.dispatch, ctx.pc);
                        let target = self.eval_int(expr)?;
                        self.builder.build_store(pc, target).map_err(Self::err)?;
                        self.builder
                            .build_unconditional_branch(dispatch)
                            .map_err(Self::err)?;
                    }
                }
                IrItem::Gosub(name) => {
                    if self.sm.is_some() {
                        let target = self
                            .sm
                            .as_ref()
                            .unwrap()
                            .labels
                            .get(name)
                            .copied()
                            .unwrap_or(SM_EXIT_PC);
                        let tv = self.i32t.const_int(target, false);
                        self.sm_gosub(tv)?;
                    }
                }
                IrItem::GosubExpr(expr) => {
                    if self.sm.is_some() {
                        let tv = self.eval_int(expr)?;
                        self.sm_gosub(tv)?;
                    }
                }
                IrItem::GosubReturn => {
                    if let Some(ctx) = &self.sm {
                        let (dispatch, pc, retstack, retsp) =
                            (ctx.dispatch, ctx.pc, ctx.retstack, ctx.retsp);
                        // Pop the return-index stack (branchless): empty → exit (SM_EXIT_PC).
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
                        let newsp = self
                            .builder
                            .build_select(ne, spm1, sp, "nsp")
                            .map_err(Self::err)?
                            .into_int_value();
                        self.builder.build_store(retsp, newsp).map_err(Self::err)?;
                        let slot = unsafe {
                            self.builder
                                .build_in_bounds_gep(self.i32t, retstack, &[newsp], "rslot")
                                .map_err(Self::err)?
                        };
                        let idx = self
                            .builder
                            .build_load(self.i32t, slot, "ridx")
                            .map_err(Self::err)?
                            .into_int_value();
                        let target = self
                            .builder
                            .build_select(ne, idx, self.i32t.const_int(SM_EXIT_PC, false), "rpc")
                            .map_err(Self::err)?
                            .into_int_value();
                        self.builder.build_store(pc, target).map_err(Self::err)?;
                        self.builder
                            .build_unconditional_branch(dispatch)
                            .map_err(Self::err)?;
                    } else {
                        // Outside a state machine (a bare `RETURN` — GosubReturn — reached
                        // with no GOSUB in flight, e.g. nested in an `IF` so the body was not
                        // routed to the SM) this halts the function: return its default value,
                        // matching the interpreter's empty-GOSUB-stack GosubReturn = halt.
                        self.ret_default()?;
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
            let sp = self
                .builder
                .build_load(self.i32t, retsp, "psp")
                .map_err(Self::err)?
                .into_int_value();
            let slot = unsafe {
                self.builder
                    .build_in_bounds_gep(self.i32t, retstack, &[sp], "pslot")
                    .map_err(Self::err)?
            };
            self.builder
                .build_store(slot, self.i32t.const_int(v, false))
                .map_err(Self::err)?;
            let sp1 = self
                .builder
                .build_int_add(sp, self.i32t.const_int(1, false), "psp1")
                .map_err(Self::err)?;
            self.builder.build_store(retsp, sp1).map_err(Self::err)?;
            Ok(())
        }

        /// Allocate a fresh GOSUB return landing: an empty block registered in the dispatch
        /// switch at pc `count + 1 + index` (pc `count` is the fall-off-end → exit). The
        /// caller pushes this pc and resumes emission on the returned block, so code after
        /// the GOSUB (even nested) runs on RETURN.
        fn sm_new_landing(&mut self) -> Result<(u64, BasicBlock<'ctx>), CompileError> {
            let land = self.ctx.append_basic_block(self.cur_fn, "sm.land");
            let ctx = self
                .sm
                .as_mut()
                .expect("landing requires an active state machine");
            let lpc = ctx.count + 1 + ctx.landings.len() as u64;
            ctx.landings.push((lpc, land));
            Ok((lpc, land))
        }

        /// Emit a GOSUB to `target` pc: push a fresh landing, jump through the dispatch, then
        /// resume emission on the landing block (so code after the GOSUB runs on RETURN).
        fn sm_gosub(&mut self, target: IntValue<'ctx>) -> Result<(), CompileError> {
            let (land_pc, land) = self.sm_new_landing()?;
            let (dispatch, pc, retstack, retsp) = {
                let c = self.sm.as_ref().unwrap();
                (c.dispatch, c.pc, c.retstack, c.retsp)
            };
            self.sm_push(retstack, retsp, land_pc)?;
            self.builder.build_store(pc, target).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(dispatch)
                .map_err(Self::err)?;
            self.builder.position_at_end(land);
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
                (BasicValueEnum::IntValue(x), BasicValueEnum::IntValue(y)) => self
                    .builder
                    .build_int_compare(IntPredicate::EQ, x, y, "seq")
                    .map_err(Self::err),
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
                IrExprKind::ByRef(inner) => {
                    // `@scalar`: pass a pointer to the caller's variable slot. `@array[]`:
                    // materialize a `{data, dims}` descriptor and pass its pointer (read-only
                    // 1-D). Anything else → None (call skipped, as before).
                    if let IrExprKind::Symbol(sym) = &inner.kind {
                        if let Some((holder, _elem, dims)) = self.arrays.get(&sym.name).cloned() {
                            let dty = self.arr_desc_ty();
                            let desc = self.entry_alloca(dty.into(), "adesc")?;
                            let bufptr = self
                                .builder
                                .build_load(self.ptr, holder, "abuf")
                                .map_err(Self::err)?;
                            let dptr = self
                                .builder
                                .build_struct_gep(dty, desc, 0, "addata")
                                .map_err(|_| CompileError::Llvm("desc data gep".into()))?;
                            self.builder.build_store(dptr, bufptr).map_err(Self::err)?;
                            let dimsp = self
                                .builder
                                .build_struct_gep(dty, desc, 1, "addims")
                                .map_err(|_| CompileError::Llvm("desc dims gep".into()))?;
                            for (k, cslot) in dims.iter().enumerate().take(4) {
                                let cnt = self
                                    .builder
                                    .build_load(self.i64t, *cslot, "acnt")
                                    .map_err(Self::err)?;
                                let ep = unsafe {
                                    self.builder
                                        .build_in_bounds_gep(
                                            self.i64t,
                                            dimsp,
                                            &[self.i64t.const_int(k as u64, false)],
                                            "adimk",
                                        )
                                        .map_err(Self::err)?
                                };
                                self.builder.build_store(ep, cnt).map_err(Self::err)?;
                            }
                            Some(desc.into())
                        } else {
                            self.vars.get(&sym.name).map(|(slot, _)| (*slot).into())
                        }
                    } else {
                        None
                    }
                }
                IrExprKind::IntegerLiteral(v) => Some(
                    self.i32t
                        .const_int(parse_int_literal(v) as u64, true)
                        .into(),
                ),
                IrExprKind::Constant { value, .. } => match expr.value_type {
                    // System / user `$$` constant: the IR carries its resolved value. Match the
                    // interpreter (`parse_integer`) for integers; support float/string too.
                    ValueType::Float => Some(
                        self.f64t
                            .const_float(value.parse::<f64>().unwrap_or(0.0))
                            .into(),
                    ),
                    ValueType::String => Some(self.str_const(value.as_bytes())?.into()),
                    _ => Some(
                        self.i32t
                            .const_int(parse_int_literal(value) as u64, true)
                            .into(),
                    ),
                },
                IrExprKind::FloatLiteral(v) => Some(
                    self.f64t
                        .const_float(v.parse::<f64>().unwrap_or(0.0))
                        .into(),
                ),
                IrExprKind::FuncAddr(name) => {
                    // `&func()`: the interpreter uses a synthetic id (the function's 1-based
                    // program-order index), not a real address; mirror it so `&f` compares and
                    // prints identically (unknown → 0).
                    let id = self.func_ids.get(name).copied().unwrap_or(0);
                    Some(self.i32t.const_int(id as u64, true).into())
                }
                IrExprKind::Unary { op, operand } => match self.eval_value(operand)? {
                    // Unary negation / plus (e.g. `-1` lowers to `Neg(1)`); mirrors the
                    // interpreter. `Pos` is identity. A non-numeric operand yields nothing.
                    Some(BasicValueEnum::IntValue(iv)) => Some(match op {
                        xb_frontend::UnaryOp::Neg => self
                            .builder
                            .build_int_neg(iv, "uneg")
                            .map_err(Self::err)?
                            .into(),
                        xb_frontend::UnaryOp::Pos => iv.into(),
                    }),
                    Some(BasicValueEnum::FloatValue(fv)) => Some(match op {
                        xb_frontend::UnaryOp::Neg => self
                            .builder
                            .build_float_neg(fv, "ufneg")
                            .map_err(Self::err)?
                            .into(),
                        xb_frontend::UnaryOp::Pos => fv.into(),
                    }),
                    _ => None,
                },
                IrExprKind::Symbol(sym) => match self.vars.get(&sym.name) {
                    Some((slot, ValueType::String)) => Some(
                        self.builder
                            .build_load(self.ptr, *slot, "ld")
                            .map_err(Self::err)?,
                    ),
                    Some((slot, ValueType::Float)) => Some(
                        self.builder
                            .build_load(self.f64t, *slot, "ld")
                            .map_err(Self::err)?,
                    ),
                    Some((slot, _)) => Some(
                        self.builder
                            .build_load(self.i32t, *slot, "ld")
                            .map_err(Self::err)?,
                    ),
                    // Undefined variable: XBasic auto-vivifies to the type default (0 /
                    // 0.0 / "") on read; the interpreter does the same, so the backend
                    // must too rather than skip (which would drop the value from PRINT).
                    None => Some(match sym.value_type {
                        ValueType::String => self.str_const(b"")?.into(),
                        ValueType::Float => self.f64t.const_zero().into(),
                        _ => self.i32t.const_zero().into(),
                    }),
                },
                IrExprKind::SharedVariable(sym) => match self.shared.get(&sym.name) {
                    Some((slot, ValueType::String)) => Some(
                        self.builder
                            .build_load(self.ptr, *slot, "shld")
                            .map_err(Self::err)?,
                    ),
                    Some((slot, ValueType::Float)) => Some(
                        self.builder
                            .build_load(self.f64t, *slot, "shld")
                            .map_err(Self::err)?,
                    ),
                    Some((slot, _)) => Some(
                        self.builder
                            .build_load(self.i32t, *slot, "shld")
                            .map_err(Self::err)?,
                    ),
                    // A shared read before any shared write auto-vivifies to the type
                    // default, matching the interpreter (previously fell through to `_ =>
                    // None`, dropping the value from PRINT).
                    None => Some(match sym.value_type {
                        ValueType::String => self.str_const(b"")?.into(),
                        ValueType::Float => self.f64t.const_zero().into(),
                        _ => self.i32t.const_zero().into(),
                    }),
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
                        let total = self
                            .builder
                            .build_int_add(la, lb, "cclen")
                            .map_err(Self::err)?;
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
                    let ls = left.value_type == ValueType::String;
                    let rs = right.value_type == ValueType::String;
                    let c = if ls && rs {
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
                    } else if ls || rs {
                        // string vs number: compare the string's byte length to the number, so
                        // `s$ == 0` (`IFZ s$`) tests emptiness — mirrors the interpreter.
                        let (sexpr, nexpr, str_left) = if ls {
                            (left, right, true)
                        } else {
                            (right, left, false)
                        };
                        let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(sexpr)? else {
                            return Ok(None);
                        };
                        let slen = self
                            .builder
                            .build_int_truncate(self.str_len(s)?, self.i32t, "slen32")
                            .map_err(Self::err)?;
                        let n = self.eval_int(nexpr)?;
                        let (a, b) = if str_left { (slen, n) } else { (n, slen) };
                        let pred = match op {
                            ComparisonOp::Equal => IntPredicate::EQ,
                            ComparisonOp::NotEqual => IntPredicate::NE,
                            ComparisonOp::Less => IntPredicate::SLT,
                            ComparisonOp::Greater => IntPredicate::SGT,
                            ComparisonOp::LessEqual => IntPredicate::SLE,
                            ComparisonOp::GreaterEqual => IntPredicate::SGE,
                        };
                        self.builder
                            .build_int_compare(pred, a, b, "slcmp")
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
                        self.builder
                            .build_float_compare(pred, a, b, "fcmp")
                            .map_err(Self::err)?
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
                        self.builder
                            .build_int_compare(pred, a, b, "cmp")
                            .map_err(Self::err)?
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
                        // Unknown callee. Mirror the interpreter's `call_function`
                        // stub (call.rs): a non-builtin, non-user function yields the
                        // zero-default (`""` for a `$`-suffixed name, else `0`), while a
                        // *deferred* builtin (interp-implemented, not yet in the backend)
                        // is skipped so we never emit a wrong constant for it.
                        if crate::is_builtin::is_builtin(name) {
                            return Ok(None); // deferred builtin
                        }
                        return Ok(Some(if name.ends_with('$') {
                            self.str_const(b"")?.into()
                        } else {
                            self.i32t.const_zero().into()
                        }));
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
                IrExprKind::ArrayAccess {
                    symbol,
                    index,
                    extra_indices,
                } => match self.array_elem_ptr(&symbol.name, index, extra_indices)? {
                    Some((ep, elem)) => Some(
                        self.builder
                            .build_load(self.llvm_type(elem), ep, "ai")
                            .map_err(Self::err)?,
                    ),
                    None => None,
                },
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
                            total = self
                                .builder
                                .build_int_mul(total, c, "t")
                                .map_err(Self::err)?;
                        }
                        let m1 = self
                            .builder
                            .build_int_sub(total, self.i64t.const_int(1, false), "ub")
                            .map_err(Self::err)?;
                        Some(
                            self.builder
                                .build_int_truncate(m1, self.i32t, "ub32")
                                .map_err(Self::err)?
                                .into(),
                        )
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
                        Some(
                            self.builder
                                .build_int_truncate(m1, self.i32t, "ub32")
                                .map_err(Self::err)?
                                .into(),
                        )
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
                    let la = self
                        .builder
                        .build_int_compare(IntPredicate::NE, a, zero, "la")
                        .map_err(Self::err)?;
                    let rb = self
                        .builder
                        .build_int_compare(IntPredicate::NE, b, zero, "lb")
                        .map_err(Self::err)?;
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
            Ok(self
                .builder
                .build_load(self.i64t, lenp, "slen")
                .map_err(Self::err)?
                .into_int_value())
        }

        /// `strcmp`-like i32 (<0/0/>0) for byte-strings: unsigned byte-lexicographic with a
        /// length tiebreak, matching Rust `Vec<u8>`/`str` ordering (shorter prefix is less).
        fn str_cmp(
            &self,
            a: PointerValue<'ctx>,
            b: PointerValue<'ctx>,
        ) -> Result<IntValue<'ctx>, CompileError> {
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
            let llt = self
                .builder
                .build_int_compare(IntPredicate::ULT, la, lb, "llt")
                .map_err(Self::err)?;
            let lgt = self
                .builder
                .build_int_compare(IntPredicate::UGT, la, lb, "lgt")
                .map_err(Self::err)?;
            let neg1 = self.i32t.const_int((-1i64) as u64, true);
            let one = self.i32t.const_int(1, false);
            let hi = self
                .builder
                .build_select(lgt, one, self.i32t.const_zero(), "lhi")
                .map_err(Self::err)?
                .into_int_value();
            let dif = self
                .builder
                .build_select(llt, neg1, hi, "ldif")
                .map_err(Self::err)?
                .into_int_value();
            let rnz = self
                .builder
                .build_int_compare(IntPredicate::NE, r, self.i32t.const_zero(), "rnz")
                .map_err(Self::err)?;
            Ok(self
                .builder
                .build_select(rnz, r, dif, "scmpsel")
                .map_err(Self::err)?
                .into_int_value())
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
                    .build_in_bounds_gep(
                        self.ctx.i8_type(),
                        base,
                        &[self.i64t.const_int(8, false)],
                        "sdata",
                    )
                    .map_err(Self::err)?
            };
            Ok(data)
        }

        /// A private C format-string global (for `snprintf`); returns its data pointer.
        fn fmt_g(&self, s: &str) -> Result<PointerValue<'ctx>, CompileError> {
            Ok(self
                .builder
                .build_global_string_ptr(s, "fmt")
                .map_err(Self::err)?
                .as_pointer_value())
        }

        /// `LJUST$`/`RJUST$`/`CJUST$`: place `s` in a space-padded field (mode 0=left, 1=right,
        /// 2=center). Left/right keep an over-long `s` whole (out length `max(len,w)`); center
        /// produces exactly `w`, truncating an over-long `s` to its first `w` bytes. Branchless
        /// (zero-length memsets are no-ops); `memcpy` preserves embedded NULs.
        fn str_justify(
            &self,
            s_arg: &IrExpr,
            w_arg: &IrExpr,
            mode: u8,
        ) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(s_arg)? else {
                return Ok(None);
            };
            let w = self.eval_int(w_arg)?;
            let w64 = self
                .builder
                .build_int_s_extend(w, self.i64t, "w64")
                .map_err(Self::err)?;
            let slen = self.str_len(s)?;
            // Center (mode 2) produces exactly width `w`, truncating an over-long `s` to its
            // first `w` bytes (matches the interpreter's `s[..width]`); left/right keep the full
            // string when it is already >= `w` (no truncation), so out length is `max(len, w)`.
            let sgtw = self
                .builder
                .build_int_compare(IntPredicate::SGT, slen, w64, "sgtw")
                .map_err(Self::err)?;
            let (copylen, outlen) = if mode == 2 {
                (self.umin(slen, w64)?, w64)
            } else {
                (
                    slen,
                    self.builder
                        .build_select(sgtw, slen, w64, "outlen")
                        .map_err(Self::err)?
                        .into_int_value(),
                )
            };
            let r = self.str_new(outlen)?;
            let pad = self
                .builder
                .build_int_sub(outlen, copylen, "pad")
                .map_err(Self::err)?;
            let leftpad = match mode {
                1 => pad,
                2 => self
                    .builder
                    .build_int_signed_div(pad, self.i64t.const_int(2, false), "lp")
                    .map_err(Self::err)?,
                _ => self.i64t.const_zero(),
            };
            let space = self.i32t.const_int(b' ' as u64, false);
            self.builder
                .build_call(
                    self.memset,
                    &[r.into(), space.into(), leftpad.into()],
                    "ms1",
                )
                .map_err(Self::err)?;
            let dst = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), r, &[leftpad], "jdst")
                    .map_err(Self::err)?
            };
            self.builder
                .build_call(self.memcpy, &[dst.into(), s.into(), copylen.into()], "jmc")
                .map_err(Self::err)?;
            let ls = self
                .builder
                .build_int_add(leftpad, copylen, "ls")
                .map_err(Self::err)?;
            let rightpad = self
                .builder
                .build_int_sub(outlen, ls, "rp")
                .map_err(Self::err)?;
            let rstart = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), r, &[ls], "jrs")
                    .map_err(Self::err)?
            };
            self.builder
                .build_call(
                    self.memset,
                    &[rstart.into(), space.into(), rightpad.into()],
                    "ms2",
                )
                .map_err(Self::err)?;
            Ok(Some(r.into()))
        }

        /// A global length-prefixed byte-string constant; returns its data pointer.
        fn str_const(&self, bytes: &[u8]) -> Result<PointerValue<'ctx>, CompileError> {
            let i8t = self.ctx.i8_type();
            let mut raw: Vec<u8> = (bytes.len() as u64).to_le_bytes().to_vec();
            raw.extend_from_slice(bytes);
            raw.push(0);
            let vals: Vec<_> = raw
                .iter()
                .map(|b| i8t.const_int(*b as u64, false))
                .collect();
            let arr = i8t.const_array(&vals);
            let g = self.module.add_global(arr.get_type(), None, "bsc");
            g.set_initializer(&arr);
            g.set_constant(true);
            let data = unsafe {
                self.builder
                    .build_in_bounds_gep(
                        i8t,
                        g.as_pointer_value(),
                        &[self.i64t.const_int(8, false)],
                        "scd",
                    )
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
        fn str_from_int(
            &self,
            fmt: PointerValue<'ctx>,
            iv: IntValue<'ctx>,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            let tmp = self
                .builder
                .build_call(
                    self.calloc,
                    &[
                        self.i64t.const_int(24, false).into(),
                        self.i64t.const_int(1, false).into(),
                    ],
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
                    &[
                        tmp.into(),
                        self.i64t.const_int(24, false).into(),
                        fmt.into(),
                        iv.into(),
                    ],
                    "num",
                )
                .map_err(Self::err)?;
            self.str_from_cstr(tmp)
        }

        /// `snprintf(fmt, width, iv)` into a `width + 16` scratch buffer, returned as a
        /// byte-string. For width-padded radix formats (`0x%0*X`, `%0*o`, …) where `*`
        /// consumes the runtime width — mirrors the interpreter's 2-arg HEXX$/HEX$/OCT$.
        fn str_from_int_width(
            &self,
            fmt: PointerValue<'ctx>,
            width: IntValue<'ctx>,
            iv: IntValue<'ctx>,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            let w64 = self
                .builder
                .build_int_s_extend(width, self.i64t, "w64")
                .map_err(Self::err)?;
            let size = self
                .builder
                .build_int_add(w64, self.i64t.const_int(16, false), "hxsz")
                .map_err(Self::err)?;
            let tmp = self
                .builder
                .build_call(
                    self.calloc,
                    &[size.into(), self.i64t.const_int(1, false).into()],
                    "hxbuf",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                .into_pointer_value();
            self.builder
                .build_call(
                    self.snprintf,
                    &[tmp.into(), size.into(), fmt.into(), width.into(), iv.into()],
                    "hxnum",
                )
                .map_err(Self::err)?;
            self.str_from_cstr(tmp)
        }

        /// Write a byte-string to stdout via a `putchar` loop over its length (handles
        /// embedded NULs; shares libc's stdout buffer with `printf` so ordering is kept).
        fn str_print(&self, s: PointerValue<'ctx>) -> Result<(), CompileError> {
            // A null string pointer (an unassigned string slot / array element, which the
            // interpreter treats as "") prints as empty — guard before reading the length
            // prefix at `s - 8`, which would fault on null.
            let isnull = self.builder.build_is_null(s, "spnull").map_err(Self::err)?;
            let go = self.ctx.append_basic_block(self.cur_fn, "sp.go");
            let head = self.ctx.append_basic_block(self.cur_fn, "sp.head");
            let body = self.ctx.append_basic_block(self.cur_fn, "sp.body");
            let exit = self.ctx.append_basic_block(self.cur_fn, "sp.exit");
            self.builder
                .build_conditional_branch(isnull, exit, go)
                .map_err(Self::err)?;
            self.builder.position_at_end(go);
            let len = self.str_len(s)?;
            let idx = self
                .builder
                .build_alloca(self.i64t, "pi")
                .map_err(Self::err)?;
            self.builder
                .build_store(idx, self.i64t.const_zero())
                .map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(head)
                .map_err(Self::err)?;
            self.builder.position_at_end(head);
            let iv = self
                .builder
                .build_load(self.i64t, idx, "pv")
                .map_err(Self::err)?
                .into_int_value();
            let cont = self
                .builder
                .build_int_compare(IntPredicate::ULT, iv, len, "plt")
                .map_err(Self::err)?;
            self.builder
                .build_conditional_branch(cont, body, exit)
                .map_err(Self::err)?;
            self.builder.position_at_end(body);
            let ep = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), s, &[iv], "pep")
                    .map_err(Self::err)?
            };
            let c = self
                .builder
                .build_load(self.ctx.i8_type(), ep, "pc")
                .map_err(Self::err)?
                .into_int_value();
            let ci = self
                .builder
                .build_int_z_extend(c, self.i32t, "pci")
                .map_err(Self::err)?;
            self.builder
                .build_call(self.putchar, &[ci.into()], "pch")
                .map_err(Self::err)?;
            let next = self
                .builder
                .build_int_add(iv, self.i64t.const_int(1, false), "pn")
                .map_err(Self::err)?;
            self.builder.build_store(idx, next).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(head)
                .map_err(Self::err)?;
            self.builder.position_at_end(exit);
            Ok(())
        }

        /// Unsigned min (matches `usize::min`).
        fn umin(
            &self,
            a: IntValue<'ctx>,
            b: IntValue<'ctx>,
        ) -> Result<IntValue<'ctx>, CompileError> {
            let lt = self
                .builder
                .build_int_compare(IntPredicate::ULT, a, b, "ult")
                .map_err(Self::err)?;
            Ok(self
                .builder
                .build_select(lt, a, b, "umin")
                .map_err(Self::err)?
                .into_int_value())
        }

        /// Unsigned saturating subtract (matches `usize::saturating_sub`).
        fn usub_sat(
            &self,
            x: IntValue<'ctx>,
            y: IntValue<'ctx>,
        ) -> Result<IntValue<'ctx>, CompileError> {
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

        /// `MID$(target, start[, len]) = value`: overwrite bytes of the string variable
        /// `target`, starting at 1-based `start`, with up to `len` bytes of `value` (all of
        /// `value` when `len` is absent). Byte copy — embedded NULs preserved, string length
        /// unchanged. Clamped so it never reads/writes past either string; a no-op when
        /// `start` exceeds `len(target)`. Uses `usize`-style unsigned min / saturating-sub, so
        /// it matches the interpreter's `MidAssign` byte-for-byte.
        ///
        /// Copy-on-write: the target's slot is rewritten to a fresh heap buffer holding the
        /// mutated copy, rather than mutating in place. This gives value semantics (matching
        /// the interpreter, which clones on assignment) and — crucially — never writes through
        /// a read-only string-literal global (`s$ = "ABC"; s${2} = …`) or an aliased buffer.
        fn mid_assign(
            &self,
            target: &IrExpr,
            start: &IrExpr,
            length: &Option<IrExpr>,
            value: &IrExpr,
        ) -> Result<(), CompileError> {
            let IrExprKind::Symbol(sym) = &target.kind else {
                return Ok(());
            };
            let Some((slot, ValueType::String)) = self.vars.get(&sym.name).copied() else {
                return Ok(());
            };
            let Some(BasicValueEnum::PointerValue(src)) = self.eval_value(value)? else {
                return Ok(());
            };
            let old = self
                .builder
                .build_load(self.ptr, slot, "mold")
                .map_err(Self::err)?
                .into_pointer_value();
            let dlen = self.str_len(old)?;
            // Fresh writable buffer = a byte-for-byte copy of the current target.
            let dst = self.str_new(dlen)?;
            self.builder
                .build_call(self.memcpy, &[dst.into(), old.into(), dlen.into()], "mcopy")
                .map_err(Self::err)?;
            let start64 = self
                .builder
                .build_int_s_extend(self.eval_int(start)?, self.i64t, "mstart")
                .map_err(Self::err)?;
            let si = self.usub_sat(start64, self.i64t.const_int(1, false))?;
            let slen = self.str_len(src)?;
            let copy_req = match length {
                Some(len_expr) => self
                    .builder
                    .build_int_s_extend(self.eval_int(len_expr)?, self.i64t, "mlen")
                    .map_err(Self::err)?,
                None => slen,
            };
            let copy = self.umin(copy_req, slen)?;
            let avail = self.usub_sat(dlen, si)?;
            let copy = self.umin(copy, avail)?;
            // Clamp the destination offset into the buffer (data..data+len, the last being the
            // trailing NUL) so the GEP stays in bounds even when `copy` is zero.
            let si_g = self.umin(si, dlen)?;
            let dstoff = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), dst, &[si_g], "mdst")
                    .map_err(Self::err)?
            };
            self.builder
                .build_call(
                    self.memcpy,
                    &[dstoff.into(), src.into(), copy.into()],
                    "mmc",
                )
                .map_err(Self::err)?;
            self.builder.build_store(slot, dst).map_err(Self::err)?;
            Ok(())
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
            let n64 = self
                .builder
                .build_int_s_extend(n, self.i64t, "n64")
                .map_err(Self::err)?;
            let buf = self.str_new(n64)?;
            self.builder
                .build_call(
                    self.memset,
                    &[
                        buf.into(),
                        self.i32t.const_int(b' ' as u64, false).into(),
                        n64.into(),
                    ],
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
        fn str_case(
            &self,
            s: PointerValue<'ctx>,
            upper: bool,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            let len = self.str_len(s)?;
            let buf = self.str_copy(s, self.i64t.const_zero(), len)?;
            let i8t = self.ctx.i8_type();
            let idx = self
                .builder
                .build_alloca(self.i64t, "ci")
                .map_err(Self::err)?;
            self.builder
                .build_store(idx, self.i64t.const_zero())
                .map_err(Self::err)?;
            let head = self.ctx.append_basic_block(self.cur_fn, "case.head");
            let body = self.ctx.append_basic_block(self.cur_fn, "case.body");
            let exit = self.ctx.append_basic_block(self.cur_fn, "case.exit");
            self.builder
                .build_unconditional_branch(head)
                .map_err(Self::err)?;
            self.builder.position_at_end(head);
            let iv = self
                .builder
                .build_load(self.i64t, idx, "i")
                .map_err(Self::err)?
                .into_int_value();
            let cont = self
                .builder
                .build_int_compare(IntPredicate::ULT, iv, len, "lt")
                .map_err(Self::err)?;
            self.builder
                .build_conditional_branch(cont, body, exit)
                .map_err(Self::err)?;
            self.builder.position_at_end(body);
            let ep = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, buf, &[iv], "cp")
                    .map_err(Self::err)?
            };
            let c = self
                .builder
                .build_load(i8t, ep, "c")
                .map_err(Self::err)?
                .into_int_value();
            let (lo, hi, delta) = if upper {
                (b'a', b'z', -32i64)
            } else {
                (b'A', b'Z', 32i64)
            };
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
            let nc = self
                .builder
                .build_select(inr, sh, c, "nc")
                .map_err(Self::err)?
                .into_int_value();
            self.builder.build_store(ep, nc).map_err(Self::err)?;
            let next = self
                .builder
                .build_int_add(iv, self.i64t.const_int(1, false), "inc")
                .map_err(Self::err)?;
            self.builder.build_store(idx, next).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(head)
                .map_err(Self::err)?;
            self.builder.position_at_end(exit);
            Ok(buf)
        }

        /// `TRIM$`/`LTRIM$`/`RTRIM$`: strip ASCII whitespace (matches `byte_trim`).
        fn str_trim(
            &self,
            s: PointerValue<'ctx>,
            left: bool,
            right: bool,
        ) -> Result<PointerValue<'ctx>, CompileError> {
            let len = self.str_len(s)?;
            let i8t = self.ctx.i8_type();
            let a = self
                .builder
                .build_alloca(self.i64t, "ta")
                .map_err(Self::err)?;
            self.builder
                .build_store(a, self.i64t.const_zero())
                .map_err(Self::err)?;
            let b = self
                .builder
                .build_alloca(self.i64t, "tb")
                .map_err(Self::err)?;
            self.builder.build_store(b, len).map_err(Self::err)?;
            if left {
                let head = self.ctx.append_basic_block(self.cur_fn, "lt.head");
                let chk = self.ctx.append_basic_block(self.cur_fn, "lt.chk");
                let adv = self.ctx.append_basic_block(self.cur_fn, "lt.adv");
                let done = self.ctx.append_basic_block(self.cur_fn, "lt.done");
                self.builder
                    .build_unconditional_branch(head)
                    .map_err(Self::err)?;
                self.builder.position_at_end(head);
                let av = self
                    .builder
                    .build_load(self.i64t, a, "av")
                    .map_err(Self::err)?
                    .into_int_value();
                let c1 = self
                    .builder
                    .build_int_compare(IntPredicate::ULT, av, len, "c1")
                    .map_err(Self::err)?;
                self.builder
                    .build_conditional_branch(c1, chk, done)
                    .map_err(Self::err)?;
                self.builder.position_at_end(chk);
                let ea = unsafe {
                    self.builder
                        .build_in_bounds_gep(i8t, s, &[av], "ea")
                        .map_err(Self::err)?
                };
                let ca = self
                    .builder
                    .build_load(i8t, ea, "ca")
                    .map_err(Self::err)?
                    .into_int_value();
                let w = self.is_ws(ca)?;
                self.builder
                    .build_conditional_branch(w, adv, done)
                    .map_err(Self::err)?;
                self.builder.position_at_end(adv);
                let ap1 = self
                    .builder
                    .build_int_add(av, self.i64t.const_int(1, false), "ap1")
                    .map_err(Self::err)?;
                self.builder.build_store(a, ap1).map_err(Self::err)?;
                self.builder
                    .build_unconditional_branch(head)
                    .map_err(Self::err)?;
                self.builder.position_at_end(done);
            }
            if right {
                let head = self.ctx.append_basic_block(self.cur_fn, "rt.head");
                let chk = self.ctx.append_basic_block(self.cur_fn, "rt.chk");
                let adv = self.ctx.append_basic_block(self.cur_fn, "rt.adv");
                let done = self.ctx.append_basic_block(self.cur_fn, "rt.done");
                self.builder
                    .build_unconditional_branch(head)
                    .map_err(Self::err)?;
                self.builder.position_at_end(head);
                let bv = self
                    .builder
                    .build_load(self.i64t, b, "bv")
                    .map_err(Self::err)?
                    .into_int_value();
                let av = self
                    .builder
                    .build_load(self.i64t, a, "av2")
                    .map_err(Self::err)?
                    .into_int_value();
                let c2 = self
                    .builder
                    .build_int_compare(IntPredicate::UGT, bv, av, "c2")
                    .map_err(Self::err)?;
                self.builder
                    .build_conditional_branch(c2, chk, done)
                    .map_err(Self::err)?;
                self.builder.position_at_end(chk);
                let bm1 = self
                    .builder
                    .build_int_sub(bv, self.i64t.const_int(1, false), "bm1")
                    .map_err(Self::err)?;
                let eb = unsafe {
                    self.builder
                        .build_in_bounds_gep(i8t, s, &[bm1], "eb")
                        .map_err(Self::err)?
                };
                let cb = self
                    .builder
                    .build_load(i8t, eb, "cb")
                    .map_err(Self::err)?
                    .into_int_value();
                let w = self.is_ws(cb)?;
                self.builder
                    .build_conditional_branch(w, adv, done)
                    .map_err(Self::err)?;
                self.builder.position_at_end(adv);
                self.builder.build_store(b, bm1).map_err(Self::err)?;
                self.builder
                    .build_unconditional_branch(head)
                    .map_err(Self::err)?;
                self.builder.position_at_end(done);
            }
            let av = self
                .builder
                .build_load(self.i64t, a, "fa")
                .map_err(Self::err)?
                .into_int_value();
            let bv = self
                .builder
                .build_load(self.i64t, b, "fb")
                .map_err(Self::err)?
                .into_int_value();
            let cl = self
                .builder
                .build_int_sub(bv, av, "cl")
                .map_err(Self::err)?;
            self.str_copy(s, av, cl)
        }

        /// Get-or-declare a libc `double NAME(double)` and call it on `arg` (evaluated as f64).
        fn call_libm1(
            &self,
            cname: &str,
            arg: &IrExpr,
        ) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let f = self.module.get_function(cname).unwrap_or_else(|| {
                self.module
                    .add_function(cname, self.f64t.fn_type(&[self.f64t.into()], false), None)
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
                self.module.add_function(
                    cname,
                    self.f64t
                        .fn_type(&[self.f64t.into(), self.f64t.into()], false),
                    None,
                )
            })
        }

        /// `double NAME(double, double)` applied to two f64 args.
        fn call_libm2(
            &self,
            cname: &str,
            a: FloatValue<'ctx>,
            b: FloatValue<'ctx>,
        ) -> Result<BasicValueEnum<'ctx>, CompileError> {
            self.builder
                .build_call(self.libm2(cname), &[a.into(), b.into()], "m2")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm(format!("{cname} returned void")))
        }

        /// `1.0 / NAME(arg)` — reciprocal trig/hyperbolic (COT/SEC/CSC/COTH/SECH/CSCH).
        fn call_recip(
            &self,
            cname: &str,
            arg: &IrExpr,
        ) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let v = self.call_libm1(cname, arg)?.into_float_value();
            Ok(self
                .builder
                .build_float_div(self.f64t.const_float(1.0), v, "recip")
                .map_err(Self::err)?
                .into())
        }

        /// `double NAME(double)` applied to an already-evaluated f64 (for composed forms).
        fn callm1v(
            &self,
            cname: &str,
            v: FloatValue<'ctx>,
        ) -> Result<FloatValue<'ctx>, CompileError> {
            let f = self.module.get_function(cname).unwrap_or_else(|| {
                self.module
                    .add_function(cname, self.f64t.fn_type(&[self.f64t.into()], false), None)
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
        fn call_inv_recip(
            &self,
            cname: &str,
            arg: &IrExpr,
        ) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let v = self.eval_float(arg)?;
            let inv = self
                .builder
                .build_float_div(self.f64t.const_float(1.0), v, "invr")
                .map_err(Self::err)?;
            Ok(self.callm1v(cname, inv)?.into())
        }
        /// Append byte `c` to `work[*pos]`, advancing `*pos` only when `cond` — the byte is
        /// always stored but overwritten by the next append when `cond` is false (branchless).
        fn fmt_push_cond(
            &self,
            work: PointerValue<'ctx>,
            pos: PointerValue<'ctx>,
            c: IntValue<'ctx>,
            cond: IntValue<'ctx>,
        ) -> Result<(), CompileError> {
            let p = self
                .builder
                .build_load(self.i64t, pos, "fp")
                .map_err(Self::err)?
                .into_int_value();
            let ep = unsafe {
                self.builder
                    .build_in_bounds_gep(self.ctx.i8_type(), work, &[p], "fep")
                    .map_err(Self::err)?
            };
            self.builder.build_store(ep, c).map_err(Self::err)?;
            let adv = self
                .builder
                .build_int_z_extend(cond, self.i64t, "fadv")
                .map_err(Self::err)?;
            let np = self
                .builder
                .build_int_add(p, adv, "fnp")
                .map_err(Self::err)?;
            self.builder.build_store(pos, np).map_err(Self::err)?;
            Ok(())
        }

        /// A libc `char* NAME(...)` external (get-or-declare); shape via `two_ptr`/`ptr_i32`.
        fn libc_ptr_fn(&self, name: &str, second_is_int: bool) -> FunctionValue<'ctx> {
            self.module.get_function(name).unwrap_or_else(|| {
                let arg2 = if second_is_int {
                    self.i32t.into()
                } else {
                    self.ptr.into()
                };
                self.module.add_function(
                    name,
                    self.ptr.fn_type(&[self.ptr.into(), arg2], false),
                    None,
                )
            })
        }

        /// `FORMAT$(fmt, value)` — dispatch on the value type (string align vs numeric).
        fn eval_format(
            &self,
            fmt_arg: &IrExpr,
            val_arg: &IrExpr,
        ) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            let Some(BasicValueEnum::PointerValue(fmt)) = self.eval_value(fmt_arg)? else {
                return Ok(None);
            };
            match self.eval_value(val_arg)? {
                Some(BasicValueEnum::PointerValue(sval)) => self.format_string(fmt, sval).map(Some),
                Some(BasicValueEnum::IntValue(iv)) => {
                    let d = self
                        .builder
                        .build_signed_int_to_float(iv, self.f64t, "fi2f")
                        .map_err(Self::err)?;
                    self.format_num(fmt, d).map(Some)
                }
                Some(BasicValueEnum::FloatValue(fv)) => self.format_num(fmt, fv).map(Some),
                _ => Ok(None),
            }
        }

        /// String `FORMAT$`: `&` (and any non-align pattern) copies whole; `<`/`>`/`|` place the
        /// string left/right/center in a width counted from the leading pattern chars, truncating
        /// an over-long string to that width (mirrors `xb_format` is_str path).
        fn format_string(
            &self,
            fmt: PointerValue<'ctx>,
            sval: PointerValue<'ctx>,
        ) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let i8t = self.ctx.i8_type();
            let slen = self.str_len(sval)?;
            let c0 = self
                .builder
                .build_load(i8t, fmt, "c0")
                .map_err(Self::err)?
                .into_int_value();
            let lt = self
                .builder
                .build_int_compare(
                    IntPredicate::EQ,
                    c0,
                    i8t.const_int(b'<' as u64, false),
                    "islt",
                )
                .map_err(Self::err)?;
            let gt = self
                .builder
                .build_int_compare(
                    IntPredicate::EQ,
                    c0,
                    i8t.const_int(b'>' as u64, false),
                    "isgt",
                )
                .map_err(Self::err)?;
            let bar = self
                .builder
                .build_int_compare(
                    IntPredicate::EQ,
                    c0,
                    i8t.const_int(b'|' as u64, false),
                    "isbar",
                )
                .map_err(Self::err)?;
            let o1 = self.builder.build_or(lt, gt, "o1").map_err(Self::err)?;
            let isalign = self
                .builder
                .build_or(o1, bar, "isalign")
                .map_err(Self::err)?;
            let result = self
                .builder
                .build_alloca(self.ptr, "fsres")
                .map_err(Self::err)?;
            let align_bb = self.ctx.append_basic_block(self.cur_fn, "fs.align");
            let dup_bb = self.ctx.append_basic_block(self.cur_fn, "fs.dup");
            let done_bb = self.ctx.append_basic_block(self.cur_fn, "fs.done");
            self.builder
                .build_conditional_branch(isalign, align_bb, dup_bb)
                .map_err(Self::err)?;
            self.builder.position_at_end(dup_bb);
            let dup = self.str_copy(sval, self.i64t.const_zero(), slen)?;
            self.builder.build_store(result, dup).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(done_bb)
                .map_err(Self::err)?;
            self.builder.position_at_end(align_bb);
            let widx = self
                .builder
                .build_alloca(self.i64t, "fw")
                .map_err(Self::err)?;
            self.builder
                .build_store(widx, self.i64t.const_zero())
                .map_err(Self::err)?;
            let wcount = self
                .builder
                .build_alloca(self.i64t, "fwc")
                .map_err(Self::err)?;
            self.builder
                .build_store(wcount, self.i64t.const_zero())
                .map_err(Self::err)?;
            let wh = self.ctx.append_basic_block(self.cur_fn, "fw.head");
            let wb = self.ctx.append_basic_block(self.cur_fn, "fw.body");
            let we = self.ctx.append_basic_block(self.cur_fn, "fw.exit");
            self.builder
                .build_unconditional_branch(wh)
                .map_err(Self::err)?;
            self.builder.position_at_end(wh);
            let wi = self
                .builder
                .build_load(self.i64t, widx, "wi")
                .map_err(Self::err)?
                .into_int_value();
            let wcp = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, fmt, &[wi], "wcp")
                    .map_err(Self::err)?
            };
            let wc = self
                .builder
                .build_load(i8t, wcp, "wc")
                .map_err(Self::err)?
                .into_int_value();
            let wnul = self
                .builder
                .build_int_compare(IntPredicate::EQ, wc, i8t.const_int(0, false), "wnul")
                .map_err(Self::err)?;
            self.builder
                .build_conditional_branch(wnul, we, wb)
                .map_err(Self::err)?;
            self.builder.position_at_end(wb);
            let weq = self
                .builder
                .build_int_compare(IntPredicate::EQ, wc, c0, "weq")
                .map_err(Self::err)?;
            let wcv = self
                .builder
                .build_load(self.i64t, wcount, "wcv")
                .map_err(Self::err)?
                .into_int_value();
            let wce = self
                .builder
                .build_int_z_extend(weq, self.i64t, "wce")
                .map_err(Self::err)?;
            self.builder
                .build_store(
                    wcount,
                    self.builder
                        .build_int_add(wcv, wce, "wcn")
                        .map_err(Self::err)?,
                )
                .map_err(Self::err)?;
            self.builder
                .build_store(
                    widx,
                    self.builder
                        .build_int_add(wi, self.i64t.const_int(1, false), "wnext")
                        .map_err(Self::err)?,
                )
                .map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(wh)
                .map_err(Self::err)?;
            self.builder.position_at_end(we);
            let w = self
                .builder
                .build_load(self.i64t, wcount, "w")
                .map_err(Self::err)?
                .into_int_value();
            let copylen = self.umin(slen, w)?;
            let r = self.str_new(w)?;
            let pad = self
                .builder
                .build_int_sub(w, copylen, "fspad")
                .map_err(Self::err)?;
            let half = self
                .builder
                .build_int_signed_div(pad, self.i64t.const_int(2, false), "fshalf")
                .map_err(Self::err)?;
            let bz = self
                .builder
                .build_select(bar, half, self.i64t.const_zero(), "fsbz")
                .map_err(Self::err)?
                .into_int_value();
            let leftpad = self
                .builder
                .build_select(gt, pad, bz, "fslp")
                .map_err(Self::err)?
                .into_int_value();
            // '>' truncation copies the LAST `w` bytes (src offset slen-copylen); '<'/'|' copy the first.
            let gtoff = self
                .builder
                .build_int_sub(slen, copylen, "gtoff")
                .map_err(Self::err)?;
            let src_off = self
                .builder
                .build_select(gt, gtoff, self.i64t.const_zero(), "srcoff")
                .map_err(Self::err)?
                .into_int_value();
            let src = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, sval, &[src_off], "fssrc")
                    .map_err(Self::err)?
            };
            let space = self.i32t.const_int(b' ' as u64, false);
            self.builder
                .build_call(
                    self.memset,
                    &[r.into(), space.into(), leftpad.into()],
                    "fsms1",
                )
                .map_err(Self::err)?;
            let dst = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, r, &[leftpad], "fsdst")
                    .map_err(Self::err)?
            };
            self.builder
                .build_call(
                    self.memcpy,
                    &[dst.into(), src.into(), copylen.into()],
                    "fsmc",
                )
                .map_err(Self::err)?;
            let ls = self
                .builder
                .build_int_add(leftpad, copylen, "fsls")
                .map_err(Self::err)?;
            let rp = self
                .builder
                .build_int_sub(w, ls, "fsrp")
                .map_err(Self::err)?;
            let rstart = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, r, &[ls], "fsrs")
                    .map_err(Self::err)?
            };
            self.builder
                .build_call(
                    self.memset,
                    &[rstart.into(), space.into(), rp.into()],
                    "fsms2",
                )
                .map_err(Self::err)?;
            self.builder.build_store(result, r).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(done_bb)
                .map_err(Self::err)?;
            self.builder.position_at_end(done_bb);
            Ok(self
                .builder
                .build_load(self.ptr, result, "fsr")
                .map_err(Self::err)?)
        }
        /// Numeric `FORMAT$`: parse `#`/`.`/`,`/`$`/`*`/`0`/`+`/`-`/`(`/`_` pattern flags, then
        /// build sign/dollar/fill-pad/commas/int/decimals/trailing exactly as `xb_format`.
        fn format_num(
            &self,
            fmt: PointerValue<'ctx>,
            val: FloatValue<'ctx>,
        ) -> Result<BasicValueEnum<'ctx>, CompileError> {
            let i8t = self.ctx.i8_type();
            let z32 = self.i32t.const_zero();
            let ch = |b: u8| i8t.const_int(b as u64, false);
            let flag = |n: &str| -> Result<PointerValue<'ctx>, CompileError> {
                let a = self.builder.build_alloca(self.i32t, n).map_err(Self::err)?;
                self.builder.build_store(a, z32).map_err(Self::err)?;
                Ok(a)
            };
            let (int_digits, frac_digits, has_decimal, has_commas) = (
                flag("int_d")?,
                flag("frac_d")?,
                flag("has_dec")?,
                flag("has_com")?,
            );
            let (dollar, star_fill, zero_fill) = (flag("dollar")?, flag("star")?, flag("zero")?);
            let (leading_plus, trailing_plus, trailing_minus, paren_neg) =
                (flag("lp")?, flag("tp")?, flag("tm")?, flag("pn")?);
            let orr = |a: PointerValue<'ctx>, cond: IntValue<'ctx>| -> Result<(), CompileError> {
                let f = self
                    .builder
                    .build_load(self.i32t, a, "f")
                    .map_err(Self::err)?
                    .into_int_value();
                let e = self
                    .builder
                    .build_int_z_extend(cond, self.i32t, "e")
                    .map_err(Self::err)?;
                let nf = self.builder.build_or(f, e, "nf").map_err(Self::err)?;
                self.builder.build_store(a, nf).map_err(Self::err)?;
                Ok(())
            };
            let addc = |a: PointerValue<'ctx>, cond: IntValue<'ctx>| -> Result<(), CompileError> {
                let f = self
                    .builder
                    .build_load(self.i32t, a, "f")
                    .map_err(Self::err)?
                    .into_int_value();
                let e = self
                    .builder
                    .build_int_z_extend(cond, self.i32t, "e")
                    .map_err(Self::err)?;
                let nf = self.builder.build_int_add(f, e, "nf").map_err(Self::err)?;
                self.builder.build_store(a, nf).map_err(Self::err)?;
                Ok(())
            };
            let eqc = |c: IntValue<'ctx>, b: u8| {
                self.builder
                    .build_int_compare(IntPredicate::EQ, c, ch(b), "eqc")
                    .map_err(Self::err)
            };
            // parse loop
            let ial = self
                .builder
                .build_alloca(self.i64t, "ial")
                .map_err(Self::err)?;
            self.builder
                .build_store(ial, self.i64t.const_zero())
                .map_err(Self::err)?;
            let ph = self.ctx.append_basic_block(self.cur_fn, "fn.ph");
            let pb = self.ctx.append_basic_block(self.cur_fn, "fn.pb");
            let pe = self.ctx.append_basic_block(self.cur_fn, "fn.pe");
            self.builder
                .build_unconditional_branch(ph)
                .map_err(Self::err)?;
            self.builder.position_at_end(ph);
            let i = self
                .builder
                .build_load(self.i64t, ial, "i")
                .map_err(Self::err)?
                .into_int_value();
            let cp = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, fmt, &[i], "cp")
                    .map_err(Self::err)?
            };
            let c = self
                .builder
                .build_load(i8t, cp, "c")
                .map_err(Self::err)?
                .into_int_value();
            let isnul = self
                .builder
                .build_int_compare(IntPredicate::EQ, c, ch(0), "isnul")
                .map_err(Self::err)?;
            self.builder
                .build_conditional_branch(isnul, pe, pb)
                .map_err(Self::err)?;
            self.builder.position_at_end(pb);
            let hash = eqc(c, b'#')?;
            let hd = self
                .builder
                .build_load(self.i32t, has_decimal, "hd")
                .map_err(Self::err)?
                .into_int_value();
            let hd_nz = self
                .builder
                .build_int_compare(IntPredicate::NE, hd, z32, "hdnz")
                .map_err(Self::err)?;
            let not_hd = self.builder.build_not(hd_nz, "nhd").map_err(Self::err)?;
            addc(
                frac_digits,
                self.builder
                    .build_and(hash, hd_nz, "if")
                    .map_err(Self::err)?,
            )?;
            addc(
                int_digits,
                self.builder
                    .build_and(hash, not_hd, "ii")
                    .map_err(Self::err)?,
            )?;
            orr(has_decimal, eqc(c, b'.')?)?;
            orr(has_commas, eqc(c, b',')?)?;
            orr(dollar, eqc(c, b'$')?)?;
            orr(star_fill, eqc(c, b'*')?)?;
            orr(zero_fill, eqc(c, b'0')?)?;
            let plus = eqc(c, b'+')?;
            let idv = self
                .builder
                .build_load(self.i32t, int_digits, "idv")
                .map_err(Self::err)?
                .into_int_value();
            let id_pos = self
                .builder
                .build_int_compare(IntPredicate::SGT, idv, z32, "idpos")
                .map_err(Self::err)?;
            let not_idpos = self
                .builder
                .build_not(id_pos, "nidpos")
                .map_err(Self::err)?;
            orr(
                trailing_plus,
                self.builder
                    .build_and(plus, id_pos, "tpc")
                    .map_err(Self::err)?,
            )?;
            orr(
                leading_plus,
                self.builder
                    .build_and(plus, not_idpos, "lpc")
                    .map_err(Self::err)?,
            )?;
            orr(
                trailing_minus,
                self.builder
                    .build_and(eqc(c, b'-')?, id_pos, "tmc")
                    .map_err(Self::err)?,
            )?;
            orr(paren_neg, eqc(c, b'(')?)?;
            let us = eqc(c, b'_')?;
            let skip = self
                .builder
                .build_int_z_extend(us, self.i64t, "skip")
                .map_err(Self::err)?;
            let i1 = self
                .builder
                .build_int_add(i, self.i64t.const_int(1, false), "i1")
                .map_err(Self::err)?;
            let i2 = self
                .builder
                .build_int_add(i1, skip, "i2")
                .map_err(Self::err)?;
            self.builder.build_store(ial, i2).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(ph)
                .map_err(Self::err)?;
            self.builder.position_at_end(pe);
            // simple case: no digits and no fill -> "%g"
            let ld = |a: PointerValue<'ctx>, n: &str| {
                self.builder
                    .build_load(self.i32t, a, n)
                    .map_err(Self::err)
                    .map(|v| v.into_int_value())
            };
            let nz = |v: IntValue<'ctx>, n: &str| {
                self.builder
                    .build_int_compare(IntPredicate::NE, v, z32, n)
                    .map_err(Self::err)
            };
            let idv = ld(int_digits, "id")?;
            let fdv = ld(frac_digits, "fd")?;
            let sfv = ld(star_fill, "sf")?;
            let zfv = ld(zero_fill, "zf")?;
            let noid = self
                .builder
                .build_int_compare(IntPredicate::EQ, idv, z32, "noid")
                .map_err(Self::err)?;
            let nofd = self
                .builder
                .build_int_compare(IntPredicate::EQ, fdv, z32, "nofd")
                .map_err(Self::err)?;
            let nosf = self
                .builder
                .build_int_compare(IntPredicate::EQ, sfv, z32, "nosf")
                .map_err(Self::err)?;
            let nozf = self
                .builder
                .build_int_compare(IntPredicate::EQ, zfv, z32, "nozf")
                .map_err(Self::err)?;
            let s1 = self
                .builder
                .build_and(noid, nofd, "s1")
                .map_err(Self::err)?;
            let s2 = self
                .builder
                .build_and(nosf, nozf, "s2")
                .map_err(Self::err)?;
            let simple = self
                .builder
                .build_and(s1, s2, "simple")
                .map_err(Self::err)?;
            let result = self
                .builder
                .build_alloca(self.ptr, "fnres")
                .map_err(Self::err)?;
            let sbb = self.ctx.append_basic_block(self.cur_fn, "fn.simple");
            let bbb = self.ctx.append_basic_block(self.cur_fn, "fn.build");
            let dbb = self.ctx.append_basic_block(self.cur_fn, "fn.done");
            self.builder
                .build_conditional_branch(simple, sbb, bbb)
                .map_err(Self::err)?;
            self.builder.position_at_end(sbb);
            let nb0 = self
                .builder
                .build_alloca(i8t.array_type(64), "nb0")
                .map_err(Self::err)?;
            self.builder
                .build_call(
                    self.snprintf,
                    &[
                        nb0.into(),
                        self.i64t.const_int(64, false).into(),
                        self.fmt_g("%g")?.into(),
                        val.into(),
                    ],
                    "sg",
                )
                .map_err(Self::err)?;
            let sr = self.str_from_cstr(nb0)?;
            self.builder.build_store(result, sr).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(dbb)
                .map_err(Self::err)?;
            // build
            self.builder.position_at_end(bbb);
            let tru = self.ctx.bool_type().const_int(1, false);
            let neg = self
                .builder
                .build_float_compare(FloatPredicate::OLT, val, self.f64t.const_zero(), "neg")
                .map_err(Self::err)?;
            let nv = self.builder.build_float_neg(val, "nv").map_err(Self::err)?;
            let absv = self
                .builder
                .build_select(neg, nv, val, "absv")
                .map_err(Self::err)?
                .into_float_value();
            let work = self
                .builder
                .build_alloca(i8t.array_type(256), "work")
                .map_err(Self::err)?;
            let pos = self
                .builder
                .build_alloca(self.i64t, "pos")
                .map_err(Self::err)?;
            self.builder
                .build_store(pos, self.i64t.const_zero())
                .map_err(Self::err)?;
            let pn_nz = nz(ld(paren_neg, "pn")?, "pnnz")?;
            let lp_nz = nz(ld(leading_plus, "lp")?, "lpnz")?;
            let tp_nz = nz(ld(trailing_plus, "tp")?, "tpnz")?;
            let tm_nz = nz(ld(trailing_minus, "tm")?, "tmnz")?;
            let dol_nz = nz(ld(dollar, "dl")?, "dlnz")?;
            let com_nz = nz(ld(has_commas, "hc")?, "hcnz")?;
            let sf_nz = nz(ld(star_fill, "sf2")?, "sfnz")?;
            let zf_nz = nz(ld(zero_fill, "zf2")?, "zfnz")?;
            let dec_nz = nz(ld(has_decimal, "hdc")?, "hdcnz")?;
            let open_paren = self
                .builder
                .build_and(pn_nz, neg, "openp")
                .map_err(Self::err)?;
            let not_open = self
                .builder
                .build_not(open_paren, "nopen")
                .map_err(Self::err)?;
            self.fmt_push_cond(work, pos, ch(b'('), open_paren)?;
            let lead = self
                .builder
                .build_and(lp_nz, not_open, "lead")
                .map_err(Self::err)?;
            let lead_char = self
                .builder
                .build_select(neg, ch(b'-'), ch(b'+'), "leadc")
                .map_err(Self::err)?
                .into_int_value();
            self.fmt_push_cond(work, pos, lead_char, lead)?;
            let not_lp = self.builder.build_not(lp_nz, "nlp").map_err(Self::err)?;
            let not_tp = self.builder.build_not(tp_nz, "ntp").map_err(Self::err)?;
            let not_tm = self.builder.build_not(tm_nz, "ntm").map_err(Self::err)?;
            let b1 = self
                .builder
                .build_and(neg, not_open, "b1")
                .map_err(Self::err)?;
            let b2 = self
                .builder
                .build_and(not_lp, not_tp, "b2")
                .map_err(Self::err)?;
            let b3 = self
                .builder
                .build_and(b2, not_tm, "b3")
                .map_err(Self::err)?;
            let bare = self.builder.build_and(b1, b3, "bare").map_err(Self::err)?;
            self.fmt_push_cond(work, pos, ch(b'-'), bare)?;
            self.fmt_push_cond(work, pos, ch(b'$'), dol_nz)?;
            // numbuf via %.*f or %g
            let nb = self
                .builder
                .build_alloca(i8t.array_type(64), "nb")
                .map_err(Self::err)?;
            let fd2 = ld(frac_digits, "fd2")?;
            let fd_pos = self
                .builder
                .build_int_compare(IntPredicate::SGT, fd2, z32, "fdpos")
                .map_err(Self::err)?;
            let usedec = self
                .builder
                .build_and(dec_nz, fd_pos, "usedec")
                .map_err(Self::err)?;
            let nbf = self.ctx.append_basic_block(self.cur_fn, "fn.nbf");
            let nbg = self.ctx.append_basic_block(self.cur_fn, "fn.nbg");
            let nbd = self.ctx.append_basic_block(self.cur_fn, "fn.nbd");
            self.builder
                .build_conditional_branch(usedec, nbf, nbg)
                .map_err(Self::err)?;
            self.builder.position_at_end(nbf);
            self.builder
                .build_call(
                    self.snprintf,
                    &[
                        nb.into(),
                        self.i64t.const_int(64, false).into(),
                        self.fmt_g("%.*f")?.into(),
                        fd2.into(),
                        absv.into(),
                    ],
                    "nbf",
                )
                .map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(nbd)
                .map_err(Self::err)?;
            self.builder.position_at_end(nbg);
            self.builder
                .build_call(
                    self.snprintf,
                    &[
                        nb.into(),
                        self.i64t.const_int(64, false).into(),
                        self.fmt_g("%g")?.into(),
                        absv.into(),
                    ],
                    "nbg",
                )
                .map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(nbd)
                .map_err(Self::err)?;
            self.builder.position_at_end(nbd);
            let strchr = self.libc_ptr_fn("strchr", true);
            let dot = self
                .builder
                .build_call(
                    strchr,
                    &[nb.into(), self.i32t.const_int(b'.' as u64, false).into()],
                    "dot",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("strchr void".into()))?
                .into_pointer_value();
            let has_dot = self
                .builder
                .build_not(
                    self.builder
                        .build_is_null(dot, "dotnull")
                        .map_err(Self::err)?,
                    "hasdot",
                )
                .map_err(Self::err)?;
            let nblen = self
                .builder
                .build_call(self.strlen, &[nb.into()], "nblen")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("strlen void".into()))?
                .into_int_value();
            let dot_i = self
                .builder
                .build_ptr_to_int(dot, self.i64t, "doti")
                .map_err(Self::err)?;
            let nb_i = self
                .builder
                .build_ptr_to_int(nb, self.i64t, "nbi")
                .map_err(Self::err)?;
            let dot_off = self
                .builder
                .build_int_sub(dot_i, nb_i, "dotoff")
                .map_err(Self::err)?;
            let oil = self
                .builder
                .build_select(has_dot, dot_off, nblen, "oil")
                .map_err(Self::err)?
                .into_int_value();
            let fill = {
                let z = self
                    .builder
                    .build_select(zf_nz, ch(b'0'), ch(b' '), "fz")
                    .map_err(Self::err)?
                    .into_int_value();
                self.builder
                    .build_select(sf_nz, ch(b'*'), z, "fill")
                    .map_err(Self::err)?
                    .into_int_value()
            };
            let oil_m1 = self
                .builder
                .build_int_sub(oil, self.i64t.const_int(1, false), "oilm1")
                .map_err(Self::err)?;
            let commas_if = self
                .builder
                .build_int_signed_div(oil_m1, self.i64t.const_int(3, false), "comif")
                .map_err(Self::err)?;
            let commas = self
                .builder
                .build_select(com_nz, commas_if, self.i64t.const_zero(), "commas")
                .map_err(Self::err)?
                .into_int_value();
            let idl = self
                .builder
                .build_int_s_extend(ld(int_digits, "id2")?, self.i64t, "idl")
                .map_err(Self::err)?;
            let oic = self
                .builder
                .build_int_add(oil, commas, "oic")
                .map_err(Self::err)?;
            let padgt = self
                .builder
                .build_int_compare(IntPredicate::SGT, idl, oic, "padgt")
                .map_err(Self::err)?;
            let paddiff = self
                .builder
                .build_int_sub(idl, oic, "paddiff")
                .map_err(Self::err)?;
            let pad = self
                .builder
                .build_select(padgt, paddiff, self.i64t.const_zero(), "pad")
                .map_err(Self::err)?
                .into_int_value();
            // pad loop
            let pj = self
                .builder
                .build_alloca(self.i64t, "pj")
                .map_err(Self::err)?;
            self.builder
                .build_store(pj, self.i64t.const_zero())
                .map_err(Self::err)?;
            let pph = self.ctx.append_basic_block(self.cur_fn, "fn.pph");
            let ppb = self.ctx.append_basic_block(self.cur_fn, "fn.ppb");
            let ppe = self.ctx.append_basic_block(self.cur_fn, "fn.ppe");
            self.builder
                .build_unconditional_branch(pph)
                .map_err(Self::err)?;
            self.builder.position_at_end(pph);
            let jv = self
                .builder
                .build_load(self.i64t, pj, "jv")
                .map_err(Self::err)?
                .into_int_value();
            let jlt = self
                .builder
                .build_int_compare(IntPredicate::SLT, jv, pad, "jlt")
                .map_err(Self::err)?;
            self.builder
                .build_conditional_branch(jlt, ppb, ppe)
                .map_err(Self::err)?;
            self.builder.position_at_end(ppb);
            self.fmt_push_cond(work, pos, fill, tru)?;
            self.builder
                .build_store(
                    pj,
                    self.builder
                        .build_int_add(jv, self.i64t.const_int(1, false), "jn")
                        .map_err(Self::err)?,
                )
                .map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(pph)
                .map_err(Self::err)?;
            self.builder.position_at_end(ppe);
            // int digits with commas
            let ci = self
                .builder
                .build_alloca(self.i64t, "ci")
                .map_err(Self::err)?;
            self.builder
                .build_store(ci, self.i64t.const_zero())
                .map_err(Self::err)?;
            let cih = self.ctx.append_basic_block(self.cur_fn, "fn.cih");
            let cib = self.ctx.append_basic_block(self.cur_fn, "fn.cib");
            let cie = self.ctx.append_basic_block(self.cur_fn, "fn.cie");
            self.builder
                .build_unconditional_branch(cih)
                .map_err(Self::err)?;
            self.builder.position_at_end(cih);
            let civ = self
                .builder
                .build_load(self.i64t, ci, "civ")
                .map_err(Self::err)?
                .into_int_value();
            let cilt = self
                .builder
                .build_int_compare(IntPredicate::SLT, civ, oil, "cilt")
                .map_err(Self::err)?;
            self.builder
                .build_conditional_branch(cilt, cib, cie)
                .map_err(Self::err)?;
            self.builder.position_at_end(cib);
            let i_gt0 = self
                .builder
                .build_int_compare(IntPredicate::SGT, civ, self.i64t.const_zero(), "igt0")
                .map_err(Self::err)?;
            let oil_ci = self
                .builder
                .build_int_sub(oil, civ, "oilci")
                .map_err(Self::err)?;
            let rem = self
                .builder
                .build_int_signed_rem(oil_ci, self.i64t.const_int(3, false), "rem")
                .map_err(Self::err)?;
            let rem0 = self
                .builder
                .build_int_compare(IntPredicate::EQ, rem, self.i64t.const_zero(), "rem0")
                .map_err(Self::err)?;
            let ch1 = self
                .builder
                .build_and(com_nz, i_gt0, "ch1")
                .map_err(Self::err)?;
            let comma_here = self
                .builder
                .build_and(ch1, rem0, "commah")
                .map_err(Self::err)?;
            self.fmt_push_cond(work, pos, ch(b','), comma_here)?;
            let ncp = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, nb, &[civ], "ncp")
                    .map_err(Self::err)?
            };
            let nc = self
                .builder
                .build_load(i8t, ncp, "nc")
                .map_err(Self::err)?
                .into_int_value();
            self.fmt_push_cond(work, pos, nc, tru)?;
            self.builder
                .build_store(
                    ci,
                    self.builder
                        .build_int_add(civ, self.i64t.const_int(1, false), "cin")
                        .map_err(Self::err)?,
                )
                .map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(cih)
                .map_err(Self::err)?;
            self.builder.position_at_end(cie);
            // decimals
            self.fmt_push_cond(work, pos, ch(b'.'), has_dot)?;
            let dotp1 = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, dot, &[self.i64t.const_int(1, false)], "dotp1")
                    .map_err(Self::err)?
            };
            let safe = self
                .builder
                .build_select(has_dot, dotp1, nb, "safe")
                .map_err(Self::err)?
                .into_pointer_value();
            let flen_raw = self
                .builder
                .build_call(self.strlen, &[safe.into()], "flenr")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("strlen void".into()))?
                .into_int_value();
            let flen = self
                .builder
                .build_select(has_dot, flen_raw, self.i64t.const_zero(), "flen")
                .map_err(Self::err)?
                .into_int_value();
            let pv = self
                .builder
                .build_load(self.i64t, pos, "pvd")
                .map_err(Self::err)?
                .into_int_value();
            let wdst = unsafe {
                self.builder
                    .build_in_bounds_gep(i8t, work, &[pv], "wdst")
                    .map_err(Self::err)?
            };
            self.builder
                .build_call(self.memcpy, &[wdst.into(), safe.into(), flen.into()], "dmc")
                .map_err(Self::err)?;
            self.builder
                .build_store(
                    pos,
                    self.builder
                        .build_int_add(pv, flen, "posd")
                        .map_err(Self::err)?,
                )
                .map_err(Self::err)?;
            // trailing
            self.fmt_push_cond(work, pos, ch(b')'), open_paren)?;
            let t_plus = self
                .builder
                .build_and(tp_nz, not_open, "tplus")
                .map_err(Self::err)?;
            let t_plus_char = self
                .builder
                .build_select(neg, ch(b'-'), ch(b'+'), "tpc2")
                .map_err(Self::err)?
                .into_int_value();
            self.fmt_push_cond(work, pos, t_plus_char, t_plus)?;
            let tmm1 = self
                .builder
                .build_and(tm_nz, neg, "tmm1")
                .map_err(Self::err)?;
            let tmm2 = self
                .builder
                .build_and(not_open, not_tp, "tmm2")
                .map_err(Self::err)?;
            let t_minus = self
                .builder
                .build_and(tmm1, tmm2, "tminus")
                .map_err(Self::err)?;
            self.fmt_push_cond(work, pos, ch(b'-'), t_minus)?;
            let finalpos = self
                .builder
                .build_load(self.i64t, pos, "finalpos")
                .map_err(Self::err)?
                .into_int_value();
            let br = self.str_copy(work, self.i64t.const_zero(), finalpos)?;
            self.builder.build_store(result, br).map_err(Self::err)?;
            self.builder
                .build_unconditional_branch(dbb)
                .map_err(Self::err)?;
            self.builder.position_at_end(dbb);
            Ok(self
                .builder
                .build_load(self.ptr, result, "fnr")
                .map_err(Self::err)?)
        }
        /// `OPEN(name$, mode)`: normalized documented modes (0..4, share bases
        /// 0x10/0x20/0x30, optional 0x800 NONBLOCK) are handled by the runtime
        /// helper. It returns an XBasic handle or -1 and does not consume a handle
        /// on failure, matching the interpreter and generated-C backends.
        fn file_open(&self, args: &[IrExpr]) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            let Some(BasicValueEnum::PointerValue(name)) = self.eval_value(&args[0])? else {
                return Ok(None);
            };
            let mode = self.eval_int(&args[1])?;
            let handle = self
                .builder
                .build_call(self.file_open_mode, &[name.into(), mode.into()], "xbopen")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("xb_file_open_mode returned void".into()))?;
            Ok(Some(handle))
        }

        /// Address of a variable's storage slot for a positional out-param: a plain
        /// `Symbol` or `ByRef(Symbol)` yields the caller's alloca (the legacy `&x`
        /// prefix parses as a plain symbol). Returns `None` for anything else.
        fn symbol_slot_addr(
            &self,
            expr: &IrExpr,
        ) -> Result<Option<PointerValue<'ctx>>, CompileError> {
            let sym = match &expr.kind {
                IrExprKind::Symbol(s) => Some(s),
                IrExprKind::ByRef(inner) => match &inner.kind {
                    IrExprKind::Symbol(s) => Some(s),
                    _ => None,
                },
                _ => None,
            };
            Ok(sym.and_then(|s| self.vars.get(&s.name).map(|(slot, _)| *slot)))
        }

        /// `FILE*` slot pointer for handle `h` (table index `h − 3`).
        fn file_slot(&self, h: IntValue<'ctx>) -> Result<PointerValue<'ctx>, CompileError> {
            let idx = self
                .builder
                .build_int_sub(h, self.i32t.const_int(3, false), "fsidx")
                .map_err(Self::err)?;
            unsafe {
                self.builder
                    .build_in_bounds_gep(
                        self.ptr.array_type(256),
                        self.file_table,
                        &[self.i32t.const_zero(), idx],
                        "fs",
                    )
                    .map_err(Self::err)
            }
        }

        /// `CLOSE(handle)`: `fclose` the file and clear its table slot; returns 0. Assumes a
        /// valid handle from a prior `OPEN` (the corpus guards `OPEN >= 3` before use).
        fn file_close(
            &self,
            args: &[IrExpr],
        ) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            let h = self.eval_int(&args[0])?;
            let slot = self.file_slot(h)?;
            let fp = self
                .builder
                .build_load(self.ptr, slot, "cfp")
                .map_err(Self::err)?
                .into_pointer_value();
            self.builder
                .build_call(self.fclose, &[fp.into()], "fclose")
                .map_err(Self::err)?;
            self.builder
                .build_store(slot, self.ptr.const_null())
                .map_err(Self::err)?;
            Ok(Some(self.i32t.const_zero().into()))
        }

        /// `LOF(handle)`: length of the open file in bytes (seek to end, `ftell`, restore).
        fn file_lof(&self, args: &[IrExpr]) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            let h = self.eval_int(&args[0])?;
            let slot = self.file_slot(h)?;
            let fp = self
                .builder
                .build_load(self.ptr, slot, "lfp")
                .map_err(Self::err)?
                .into_pointer_value();
            let pos = self
                .builder
                .build_call(self.ftell, &[fp.into()], "ftpos")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("ftell returned void".into()))?
                .into_int_value();
            // SEEK_END = 2
            self.builder
                .build_call(
                    self.fseek,
                    &[
                        fp.into(),
                        self.i64t.const_zero().into(),
                        self.i32t.const_int(2, false).into(),
                    ],
                    "seekend",
                )
                .map_err(Self::err)?;
            let size = self
                .builder
                .build_call(self.ftell, &[fp.into()], "ftend")
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("ftell returned void".into()))?
                .into_int_value();
            // Restore position (SEEK_SET = 0).
            self.builder
                .build_call(
                    self.fseek,
                    &[fp.into(), pos.into(), self.i32t.const_zero().into()],
                    "seekpos",
                )
                .map_err(Self::err)?;
            let size32 = self
                .builder
                .build_int_truncate(size, self.i32t, "lof")
                .map_err(Self::err)?;
            Ok(Some(size32.into()))
        }

        /// `__WRITE_RECORD(handle, count)` (lowered `WRITE [n], arr[]`): append `count` zero
        /// bytes to the file and `fflush` so a later re-`OPEN` for reading sees them. Mirrors
        /// the interpreter, which writes `count` zeros (only the byte count is significant —
        /// the record data itself is not serialized). Returns `count`. Assumes a valid handle
        /// (the corpus guards `handle > 2`).
        fn file_write(
            &self,
            args: &[IrExpr],
        ) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            let h = self.eval_int(&args[0])?;
            let count = self.eval_int(&args[1])?;
            let slot = self.file_slot(h)?;
            let fp = self
                .builder
                .build_load(self.ptr, slot, "wfp")
                .map_err(Self::err)?
                .into_pointer_value();
            let count64 = self
                .builder
                .build_int_s_extend(count, self.i64t, "wcnt")
                .map_err(Self::err)?;
            let buf = self
                .builder
                .build_call(
                    self.calloc,
                    &[count64.into(), self.i64t.const_int(1, false).into()],
                    "wbuf",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                .into_pointer_value();
            self.builder
                .build_call(
                    self.fwrite,
                    &[
                        buf.into(),
                        self.i64t.const_int(1, false).into(),
                        count64.into(),
                        fp.into(),
                    ],
                    "fwrite",
                )
                .map_err(Self::err)?;
            self.builder
                .build_call(self.fflush, &[fp.into()], "fflush")
                .map_err(Self::err)?;
            Ok(Some(count.into()))
        }

        /// `__READ_RECORD(handle, count)` (lowered `READ [n], arr[]`): read up to `count` bytes
        /// into a scratch buffer (the record data is discarded, matching the interpreter — only
        /// the file position advances) and return the number of bytes read. Assumes a valid
        /// handle.
        fn file_read(&self, args: &[IrExpr]) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            let h = self.eval_int(&args[0])?;
            let count = self.eval_int(&args[1])?;
            let slot = self.file_slot(h)?;
            let fp = self
                .builder
                .build_load(self.ptr, slot, "rfp")
                .map_err(Self::err)?
                .into_pointer_value();
            let count64 = self
                .builder
                .build_int_s_extend(count, self.i64t, "rcnt")
                .map_err(Self::err)?;
            let buf = self
                .builder
                .build_call(
                    self.calloc,
                    &[count64.into(), self.i64t.const_int(1, false).into()],
                    "rbuf",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("calloc returned void".into()))?
                .into_pointer_value();
            let got = self
                .builder
                .build_call(
                    self.fread,
                    &[
                        buf.into(),
                        self.i64t.const_int(1, false).into(),
                        count64.into(),
                        fp.into(),
                    ],
                    "fread",
                )
                .map_err(Self::err)?
                .try_as_basic_value()
                .basic()
                .ok_or_else(|| CompileError::Llvm("fread returned void".into()))?
                .into_int_value();
            let got32 = self
                .builder
                .build_int_truncate(got, self.i32t, "rgot")
                .map_err(Self::err)?;
            Ok(Some(got32.into()))
        }

        /// Translate a supported builtin call; `None` if unsupported (deferred).
        fn eval_builtin(
            &self,
            name: &str,
            args: &[IrExpr],
        ) -> Result<Option<BasicValueEnum<'ctx>>, CompileError> {
            match (name, args.len()) {
                ("FORMAT$", 2) => self.eval_format(&args[0], &args[1]),
                ("OPEN", 2) => self.file_open(args),
                ("CLOSE", 1) => self.file_close(args),
                ("LOF", 1) => self.file_lof(args),
                ("__WRITE_RECORD", 2) => self.file_write(args),
                ("__READ_RECORD", 2) => self.file_read(args),
                ("GetStdHandle", 1) => {
                    let dev = self.eval_int(&args[0])?;
                    Ok(Some(
                        self.builder
                            .build_call(self.getstdhandle, &[dev.into()], "gsh")
                            .map_err(Self::err)?
                            .try_as_basic_value()
                            .basic()
                            .ok_or_else(|| {
                                CompileError::Llvm("xb_getstdhandle returned void".into())
                            })?,
                    ))
                }
                ("WriteFile", 5) => {
                    eprintln!("TRACE eval_builtin WriteFile");
                    let h = self.eval_int(&args[0])?;
                    let Some(BasicValueEnum::PointerValue(buf)) = self.eval_value(&args[1])? else {
                        return Ok(None);
                    };
                    let bytes = self.eval_int(&args[2])?;
                    // `sent` is a plain symbol: take its slot ADDRESS (the out-param
                    // is positional), not the loaded value.
                    let Some(written) = self.symbol_slot_addr(&args[3])? else {
                        return Ok(None);
                    };
                    let nul = self.ptr.const_null();
                    Ok(Some(
                        self.builder
                            .build_call(
                                self.write_file,
                                &[
                                    h.into(),
                                    buf.into(),
                                    bytes.into(),
                                    written.into(),
                                    nul.into(),
                                ],
                                "wf",
                            )
                            .map_err(Self::err)?
                            .try_as_basic_value()
                            .basic()
                            .ok_or_else(|| {
                                CompileError::Llvm("xb_write_file returned void".into())
                            })?,
                    ))
                }
                ("ReadFile", 5) => {
                    // RT-KERNEL32: the buffer is replaced through its char** slot
                    // address; the count out-param takes the caller's i32 slot address.
                    let h = self.eval_int(&args[0])?;
                    // `&buf$` parses as a plain symbol (legacy noise prefix), so take
                    // the caller's char* slot ADDRESS positionally — same rule as the
                    // C runtimes' emit_byref_addr.
                    let Some(bufpp) = self.symbol_slot_addr(&args[1])? else {
                        return Ok(None);
                    };
                    let bytes = self.eval_int(&args[2])?;
                    let Some(read) = self.symbol_slot_addr(&args[3])? else {
                        return Ok(None);
                    };
                    let nul = self.ptr.const_null();
                    Ok(Some(
                        self.builder
                            .build_call(
                                self.read_file,
                                &[
                                    h.into(),
                                    bufpp.into(),
                                    bytes.into(),
                                    read.into(),
                                    nul.into(),
                                ],
                                "rf",
                            )
                            .map_err(Self::err)?
                            .try_as_basic_value()
                            .basic()
                            .ok_or_else(|| {
                                CompileError::Llvm("xb_read_file returned void".into())
                            })?,
                    ))
                }
                ("EOF", 1) => {
                    let h = self.eval_int(&args[0])?;
                    Ok(Some(
                        self.builder
                            .build_call(self.file_eof, &[h.into()], "eof")
                            .map_err(Self::err)?
                            .try_as_basic_value()
                            .basic()
                            .ok_or_else(|| {
                                CompileError::Llvm("xb_file_eof returned void".into())
                            })?,
                    ))
                }
                ("ABS", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::IntValue(iv)) => {
                        let neg = self.builder.build_int_neg(iv, "neg").map_err(Self::err)?;
                        let isneg = self
                            .builder
                            .build_int_compare(
                                IntPredicate::SLT,
                                iv,
                                self.i32t.const_zero(),
                                "isneg",
                            )
                            .map_err(Self::err)?;
                        Ok(Some(
                            self.builder
                                .build_select(isneg, neg, iv, "abs")
                                .map_err(Self::err)?,
                        ))
                    }
                    Some(BasicValueEnum::FloatValue(fv)) => {
                        let neg = self
                            .builder
                            .build_float_neg(fv, "fneg")
                            .map_err(Self::err)?;
                        let isneg = self
                            .builder
                            .build_float_compare(
                                FloatPredicate::OLT,
                                fv,
                                self.f64t.const_zero(),
                                "fisneg",
                            )
                            .map_err(Self::err)?;
                        Ok(Some(
                            self.builder
                                .build_select(isneg, neg, fv, "fabs")
                                .map_err(Self::err)?,
                        ))
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
                    Ok(Some(self.call_libm2(
                        "pow",
                        self.f64t.const_float(10.0),
                        v,
                    )?))
                }
                ("EXP2", 1) => {
                    let v = self.eval_float(&args[0])?;
                    Ok(Some(self.call_libm2(
                        "pow",
                        self.f64t.const_float(2.0),
                        v,
                    )?))
                }
                ("ASEC", 1) => {
                    // M_PI_2 - asin(1/v)
                    let v = self.eval_float(&args[0])?;
                    let inv = self
                        .builder
                        .build_float_div(self.f64t.const_float(1.0), v, "invr")
                        .map_err(Self::err)?;
                    let a = self.callm1v("asin", inv)?;
                    Ok(Some(
                        self.builder
                            .build_float_sub(
                                self.f64t.const_float(std::f64::consts::FRAC_PI_2),
                                a,
                                "asec",
                            )
                            .map_err(Self::err)?
                            .into(),
                    ))
                }
                ("ACOT", 1) => {
                    // v > 1 ? atan(1/v) : M_PI_2 - atan(v)
                    let v = self.eval_float(&args[0])?;
                    let inv = self
                        .builder
                        .build_float_div(self.f64t.const_float(1.0), v, "invr")
                        .map_err(Self::err)?;
                    let hi = self.callm1v("atan", inv)?;
                    let av = self.callm1v("atan", v)?;
                    let lo = self
                        .builder
                        .build_float_sub(
                            self.f64t.const_float(std::f64::consts::FRAC_PI_2),
                            av,
                            "acotlo",
                        )
                        .map_err(Self::err)?;
                    let gt1 = self
                        .builder
                        .build_float_compare(
                            FloatPredicate::OGT,
                            v,
                            self.f64t.const_float(1.0),
                            "gt1",
                        )
                        .map_err(Self::err)?;
                    Ok(Some(
                        self.builder
                            .build_select(gt1, hi, lo, "acot")
                            .map_err(Self::err)?,
                    ))
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
                    Ok(Some(
                        self.builder
                            .build_int_truncate(n, self.i32t, "csz32")
                            .map_err(Self::err)?
                            .into(),
                    ))
                }
                ("INSTR", 2) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let Some(BasicValueEnum::PointerValue(sub)) = self.eval_value(&args[1])? else {
                        return Ok(None);
                    };
                    let strstr = self.module.get_function("strstr").unwrap_or_else(|| {
                        self.module.add_function(
                            "strstr",
                            self.ptr.fn_type(&[self.ptr.into(), self.ptr.into()], false),
                            None,
                        )
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
                    let pi = self
                        .builder
                        .build_ptr_to_int(p, self.i64t, "pi")
                        .map_err(Self::err)?;
                    let si = self
                        .builder
                        .build_ptr_to_int(s, self.i64t, "si")
                        .map_err(Self::err)?;
                    let diff = self
                        .builder
                        .build_int_sub(pi, si, "diff")
                        .map_err(Self::err)?;
                    let diff32 = self
                        .builder
                        .build_int_truncate(diff, self.i32t, "diff32")
                        .map_err(Self::err)?;
                    let pos = self
                        .builder
                        .build_int_add(diff32, self.i32t.const_int(1, false), "pos")
                        .map_err(Self::err)?;
                    Ok(Some(
                        self.builder
                            .build_select(pnull, self.i32t.const_zero(), pos, "instr")
                            .map_err(Self::err)?,
                    ))
                }
                ("OCT$", 1) => {
                    let iv = self.eval_int(&args[0])?;
                    Ok(Some(self.str_from_int(self.fmt_g("%o")?, iv)?.into()))
                }
                ("BIN$", 1) | ("BIN$", 2) | ("BINB$", 1) | ("BINB$", 2) => {
                    // Minimal binary of the u32 bit pattern (matches Rust `{:b}`: negatives -> 32
                    // bits, 0 -> "0"), optionally zero-padded to a width, `0b` prefix for BINB$.
                    let n = self.eval_int(&args[0])?;
                    let ctlz = self
                        .module
                        .get_function("llvm.ctlz.i32")
                        .unwrap_or_else(|| {
                            self.module.add_function(
                                "llvm.ctlz.i32",
                                self.i32t.fn_type(
                                    &[self.i32t.into(), self.ctx.bool_type().into()],
                                    false,
                                ),
                                None,
                            )
                        });
                    let clz = self
                        .builder
                        .build_call(
                            ctlz,
                            &[n.into(), self.ctx.bool_type().const_zero().into()],
                            "clz",
                        )
                        .map_err(Self::err)?
                        .try_as_basic_value()
                        .basic()
                        .ok_or_else(|| CompileError::Llvm("ctlz void".into()))?
                        .into_int_value();
                    let nb = self
                        .builder
                        .build_int_sub(self.i32t.const_int(32, false), clz, "nb")
                        .map_err(Self::err)?;
                    let iszero = self
                        .builder
                        .build_int_compare(IntPredicate::EQ, n, self.i32t.const_zero(), "binz")
                        .map_err(Self::err)?;
                    let nbits = self
                        .builder
                        .build_select(iszero, self.i32t.const_int(1, false), nb, "nbits")
                        .map_err(Self::err)?
                        .into_int_value();
                    let zeropad = if args.len() == 2 {
                        let w = self.eval_int(&args[1])?;
                        let padgt = self
                            .builder
                            .build_int_compare(IntPredicate::SGT, w, nbits, "binpadgt")
                            .map_err(Self::err)?;
                        let diff = self
                            .builder
                            .build_int_sub(w, nbits, "bindiff")
                            .map_err(Self::err)?;
                        self.builder
                            .build_select(padgt, diff, self.i32t.const_zero(), "binzp")
                            .map_err(Self::err)?
                            .into_int_value()
                    } else {
                        self.i32t.const_zero()
                    };
                    let is_binb = name == "BINB$";
                    let prefix = if is_binb { 2u64 } else { 0 };
                    let i8t = self.ctx.i8_type();
                    let nbits64 = self
                        .builder
                        .build_int_z_extend(nbits, self.i64t, "nbits64")
                        .map_err(Self::err)?;
                    let zp64 = self
                        .builder
                        .build_int_z_extend(zeropad, self.i64t, "zp64")
                        .map_err(Self::err)?;
                    let digits = self
                        .builder
                        .build_int_add(nbits64, zp64, "bindig")
                        .map_err(Self::err)?;
                    let total = self
                        .builder
                        .build_int_add(digits, self.i64t.const_int(prefix, false), "bintot")
                        .map_err(Self::err)?;
                    let r = self.str_new(total)?;
                    if is_binb {
                        self.builder
                            .build_store(r, i8t.const_int(b'0' as u64, false))
                            .map_err(Self::err)?;
                        let r1 = unsafe {
                            self.builder
                                .build_in_bounds_gep(
                                    i8t,
                                    r,
                                    &[self.i64t.const_int(1, false)],
                                    "br1",
                                )
                                .map_err(Self::err)?
                        };
                        self.builder
                            .build_store(r1, i8t.const_int(b'b' as u64, false))
                            .map_err(Self::err)?;
                    }
                    let zpstart = unsafe {
                        self.builder
                            .build_in_bounds_gep(
                                i8t,
                                r,
                                &[self.i64t.const_int(prefix, false)],
                                "zps",
                            )
                            .map_err(Self::err)?
                    };
                    self.builder
                        .build_call(
                            self.memset,
                            &[
                                zpstart.into(),
                                self.i32t.const_int(b'0' as u64, false).into(),
                                zp64.into(),
                            ],
                            "binms",
                        )
                        .map_err(Self::err)?;
                    let base = self
                        .builder
                        .build_int_add(self.i64t.const_int(prefix, false), zp64, "binbase")
                        .map_err(Self::err)?;
                    let bidx = self
                        .builder
                        .build_alloca(self.i64t, "bidx")
                        .map_err(Self::err)?;
                    self.builder
                        .build_store(bidx, self.i64t.const_zero())
                        .map_err(Self::err)?;
                    let bh = self.ctx.append_basic_block(self.cur_fn, "bin.h");
                    let bb = self.ctx.append_basic_block(self.cur_fn, "bin.b");
                    let be = self.ctx.append_basic_block(self.cur_fn, "bin.e");
                    self.builder
                        .build_unconditional_branch(bh)
                        .map_err(Self::err)?;
                    self.builder.position_at_end(bh);
                    let bi = self
                        .builder
                        .build_load(self.i64t, bidx, "bi")
                        .map_err(Self::err)?
                        .into_int_value();
                    let bcont = self
                        .builder
                        .build_int_compare(IntPredicate::ULT, bi, nbits64, "bcont")
                        .map_err(Self::err)?;
                    self.builder
                        .build_conditional_branch(bcont, bb, be)
                        .map_err(Self::err)?;
                    self.builder.position_at_end(bb);
                    let bi32 = self
                        .builder
                        .build_int_truncate(bi, self.i32t, "bi32")
                        .map_err(Self::err)?;
                    let nbm1 = self
                        .builder
                        .build_int_sub(nbits, self.i32t.const_int(1, false), "nbm1")
                        .map_err(Self::err)?;
                    let sh = self
                        .builder
                        .build_int_sub(nbm1, bi32, "binsh")
                        .map_err(Self::err)?;
                    let shifted = self
                        .builder
                        .build_right_shift(n, sh, false, "binshf")
                        .map_err(Self::err)?;
                    let bit = self
                        .builder
                        .build_and(shifted, self.i32t.const_int(1, false), "binbit")
                        .map_err(Self::err)?;
                    let bc32 = self
                        .builder
                        .build_int_add(bit, self.i32t.const_int(b'0' as u64, false), "binbc")
                        .map_err(Self::err)?;
                    let bc = self
                        .builder
                        .build_int_truncate(bc32, i8t, "binbc8")
                        .map_err(Self::err)?;
                    let bpos = self
                        .builder
                        .build_int_add(base, bi, "binpos")
                        .map_err(Self::err)?;
                    let bep = unsafe {
                        self.builder
                            .build_in_bounds_gep(i8t, r, &[bpos], "binep")
                            .map_err(Self::err)?
                    };
                    self.builder.build_store(bep, bc).map_err(Self::err)?;
                    self.builder
                        .build_store(
                            bidx,
                            self.builder
                                .build_int_add(bi, self.i64t.const_int(1, false), "binn")
                                .map_err(Self::err)?,
                        )
                        .map_err(Self::err)?;
                    self.builder
                        .build_unconditional_branch(bh)
                        .map_err(Self::err)?;
                    self.builder.position_at_end(be);
                    Ok(Some(r.into()))
                }
                ("SIGNED$", 1) => {
                    let iv = self.eval_int(&args[0])?;
                    Ok(Some(self.str_from_int(self.fmt_g("%+d")?, iv)?.into()))
                }
                ("NULL$", 1) => {
                    let n = self.eval_int(&args[0])?;
                    let n64 = self
                        .builder
                        .build_int_s_extend(n, self.i64t, "n64")
                        .map_err(Self::err)?;
                    let neg = self
                        .builder
                        .build_int_compare(IntPredicate::SLT, n64, self.i64t.const_zero(), "nn")
                        .map_err(Self::err)?;
                    let clamped = self
                        .builder
                        .build_select(neg, self.i64t.const_zero(), n64, "nclamp")
                        .map_err(Self::err)?
                        .into_int_value();
                    Ok(Some(self.str_new(clamped)?.into()))
                }
                ("LJUST$", 2) => self.str_justify(&args[0], &args[1], 0),
                ("RJUST$", 2) => self.str_justify(&args[0], &args[1], 1),
                ("CJUST$", 2) => self.str_justify(&args[0], &args[1], 2),
                ("LCLIP$", 2) => {
                    // drop the first `n` bytes
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let n = self.eval_int(&args[1])?;
                    let n64 = self
                        .builder
                        .build_int_s_extend(n, self.i64t, "n64")
                        .map_err(Self::err)?;
                    let slen = self.str_len(s)?;
                    let off = self.umin(n64, slen)?;
                    let outlen = self
                        .builder
                        .build_int_sub(slen, off, "lcl")
                        .map_err(Self::err)?;
                    Ok(Some(self.str_copy(s, off, outlen)?.into()))
                }
                ("RCLIP$", 2) => {
                    // drop the last `n` bytes
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let n = self.eval_int(&args[1])?;
                    let n64 = self
                        .builder
                        .build_int_s_extend(n, self.i64t, "n64")
                        .map_err(Self::err)?;
                    let slen = self.str_len(s)?;
                    let keep = self.usub_sat(slen, n64)?;
                    Ok(Some(self.str_copy(s, self.i64t.const_zero(), keep)?.into()))
                }
                ("HEXX$", 1) => {
                    let iv = self.eval_int(&args[0])?;
                    Ok(Some(self.str_from_int(self.fmt_g("0x%X")?, iv)?.into()))
                }
                ("OCTO$", 1) => {
                    let iv = self.eval_int(&args[0])?;
                    Ok(Some(self.str_from_int(self.fmt_g("0o%o")?, iv)?.into()))
                }
                ("HEXX$", 2) => {
                    let iv = self.eval_int(&args[0])?;
                    let w = self.eval_int(&args[1])?;
                    Ok(Some(
                        self.str_from_int_width(self.fmt_g("0x%0*X")?, w, iv)?
                            .into(),
                    ))
                }
                ("HEX$", 2) => {
                    let iv = self.eval_int(&args[0])?;
                    let w = self.eval_int(&args[1])?;
                    Ok(Some(
                        self.str_from_int_width(self.fmt_g("%0*X")?, w, iv)?.into(),
                    ))
                }
                ("OCTO$", 2) => {
                    let iv = self.eval_int(&args[0])?;
                    let w = self.eval_int(&args[1])?;
                    Ok(Some(
                        self.str_from_int_width(self.fmt_g("0o%0*o")?, w, iv)?
                            .into(),
                    ))
                }
                ("OCT$", 2) => {
                    let iv = self.eval_int(&args[0])?;
                    let w = self.eval_int(&args[1])?;
                    Ok(Some(
                        self.str_from_int_width(self.fmt_g("%0*o")?, w, iv)?.into(),
                    ))
                }
                ("ROTATEL", 2) | ("ROTATER", 2) => {
                    // n %= 32; ROTATEL = (v<<n)|(v>>((32-n)%32)); ROTATER swaps the shifts.
                    let v = self.eval_int(&args[0])?;
                    let n = self.eval_int(&args[1])?;
                    let c32 = self.i32t.const_int(32, false);
                    let n = self
                        .builder
                        .build_int_unsigned_rem(n, c32, "rn")
                        .map_err(Self::err)?;
                    let comp = self
                        .builder
                        .build_int_sub(c32, n, "rcomp")
                        .map_err(Self::err)?;
                    let comp = self
                        .builder
                        .build_int_unsigned_rem(comp, c32, "rcompm")
                        .map_err(Self::err)?;
                    let shl = self
                        .builder
                        .build_left_shift(v, n, "rshl")
                        .map_err(Self::err)?;
                    let shr = self
                        .builder
                        .build_right_shift(v, comp, false, "rshr")
                        .map_err(Self::err)?;
                    let (a, b) = if name == "ROTATEL" {
                        // (v<<n) | (v>>(32-n))
                        (shl, shr)
                    } else {
                        // (v>>n) | (v<<(32-n))
                        let shr2 = self
                            .builder
                            .build_right_shift(v, n, false, "rshr2")
                            .map_err(Self::err)?;
                        let shl2 = self
                            .builder
                            .build_left_shift(v, comp, "rshl2")
                            .map_err(Self::err)?;
                        (shr2, shl2)
                    };
                    Ok(Some(
                        self.builder
                            .build_or(a, b, "rot")
                            .map_err(Self::err)?
                            .into(),
                    ))
                }
                ("DHIGH", 1) => {
                    let d = self.eval_float(&args[0])?;
                    let bits = self
                        .builder
                        .build_bit_cast(d, self.i64t, "dbits")
                        .map_err(Self::err)?
                        .into_int_value();
                    let hi = self
                        .builder
                        .build_right_shift(bits, self.i64t.const_int(32, false), false, "dhi")
                        .map_err(Self::err)?;
                    Ok(Some(
                        self.builder
                            .build_int_truncate(hi, self.i32t, "dhi32")
                            .map_err(Self::err)?
                            .into(),
                    ))
                }
                ("DLOW", 1) => {
                    let d = self.eval_float(&args[0])?;
                    let bits = self
                        .builder
                        .build_bit_cast(d, self.i64t, "dbits")
                        .map_err(Self::err)?
                        .into_int_value();
                    Ok(Some(
                        self.builder
                            .build_int_truncate(bits, self.i32t, "dlo")
                            .map_err(Self::err)?
                            .into(),
                    ))
                }
                ("DMAKE", 2) => {
                    let hi = self.eval_int(&args[0])?;
                    let lo = self.eval_int(&args[1])?;
                    let hi64 = self
                        .builder
                        .build_int_z_extend(hi, self.i64t, "hi64")
                        .map_err(Self::err)?;
                    let lo64 = self
                        .builder
                        .build_int_z_extend(lo, self.i64t, "lo64")
                        .map_err(Self::err)?;
                    let hishift = self
                        .builder
                        .build_left_shift(hi64, self.i64t.const_int(32, false), "hishift")
                        .map_err(Self::err)?;
                    let bits = self
                        .builder
                        .build_or(hishift, lo64, "dmbits")
                        .map_err(Self::err)?;
                    Ok(Some(
                        self.builder
                            .build_bit_cast(bits, self.f64t, "dmake")
                            .map_err(Self::err)?,
                    ))
                }
                ("SMAKE", 1) => {
                    let n = self.eval_int(&args[0])?;
                    let f = self
                        .builder
                        .build_bit_cast(n, self.ctx.f32_type(), "smf")
                        .map_err(Self::err)?
                        .into_float_value();
                    Ok(Some(
                        self.builder
                            .build_float_ext(f, self.f64t, "smake")
                            .map_err(Self::err)?
                            .into(),
                    ))
                }
                ("XMAKE", 1) => {
                    let d = self.eval_float(&args[0])?;
                    let f = self
                        .builder
                        .build_float_trunc(d, self.ctx.f32_type(), "xmf")
                        .map_err(Self::err)?;
                    Ok(Some(
                        self.builder
                            .build_bit_cast(f, self.i32t, "xmake")
                            .map_err(Self::err)?,
                    ))
                }
                ("GMAKE", 2) => Ok(Some(self.eval_int(&args[1])?.into())),
                ("GHIGH", 1) => {
                    let v = self.eval_int(&args[0])?;
                    Ok(Some(
                        self.builder
                            .build_right_shift(v, self.i32t.const_int(31, false), true, "ghigh")
                            .map_err(Self::err)?
                            .into(),
                    ))
                }
                ("GLOW", 1) => Ok(Some(self.eval_int(&args[0])?.into())),
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
                ("CHR$", 1) | ("CHR$", 2) => {
                    let n = self.eval_int(&args[0])?;
                    let chi = self
                        .builder
                        .build_int_truncate(n, self.ctx.i8_type(), "ch")
                        .map_err(Self::err)?;
                    // 2-arg CHR$(c, count) = `count` copies; 1-arg = a single byte (CHR$(0) = a real NUL).
                    if args.len() == 2 {
                        let cnt = self.eval_int(&args[1])?;
                        let cnt64 = self
                            .builder
                            .build_int_s_extend(cnt, self.i64t, "cnt64")
                            .map_err(Self::err)?;
                        let neg = self
                            .builder
                            .build_int_compare(
                                IntPredicate::SLT,
                                cnt64,
                                self.i64t.const_zero(),
                                "cneg",
                            )
                            .map_err(Self::err)?;
                        let clamped = self
                            .builder
                            .build_select(neg, self.i64t.const_zero(), cnt64, "cclamp")
                            .map_err(Self::err)?
                            .into_int_value();
                        let buf = self.str_new(clamped)?;
                        let ci = self
                            .builder
                            .build_int_z_extend(chi, self.i32t, "chi32")
                            .map_err(Self::err)?;
                        self.builder
                            .build_call(
                                self.memset,
                                &[buf.into(), ci.into(), clamped.into()],
                                "chrms",
                            )
                            .map_err(Self::err)?;
                        Ok(Some(buf.into()))
                    } else {
                        let buf = self.str_new(self.i64t.const_int(1, false))?;
                        self.builder.build_store(buf, chi).map_err(Self::err)?;
                        Ok(Some(buf.into()))
                    }
                }
                ("LEFT$", 2) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let n = self.eval_int(&args[1])?;
                    let n64 = self
                        .builder
                        .build_int_s_extend(n, self.i64t, "n64")
                        .map_err(Self::err)?;
                    let len = self.str_len(s)?;
                    let cl = self.umin(n64, len)?;
                    Ok(Some(self.str_copy(s, self.i64t.const_zero(), cl)?.into()))
                }
                ("RIGHT$", 2) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let n = self.eval_int(&args[1])?;
                    let n64 = self
                        .builder
                        .build_int_s_extend(n, self.i64t, "n64")
                        .map_err(Self::err)?;
                    let len = self.str_len(s)?;
                    let start = self.usub_sat(len, n64)?;
                    let cl = self
                        .builder
                        .build_int_sub(len, start, "cl")
                        .map_err(Self::err)?;
                    Ok(Some(self.str_copy(s, start, cl)?.into()))
                }
                ("MID$", 2) | ("MID$", 3) => {
                    let Some(BasicValueEnum::PointerValue(s)) = self.eval_value(&args[0])? else {
                        return Ok(None);
                    };
                    let start = self.eval_int(&args[1])?;
                    let s64 = self
                        .builder
                        .build_int_s_extend(start, self.i64t, "s64")
                        .map_err(Self::err)?;
                    let len = self.str_len(s)?;
                    let a = self.usub_sat(s64, self.i64t.const_int(1, false))?;
                    let start_idx = self.umin(a, len)?;
                    let end_idx = if args.len() == 3 {
                        let l = self.eval_int(&args[2])?;
                        let l64 = self
                            .builder
                            .build_int_s_extend(l, self.i64t, "l64")
                            .map_err(Self::err)?;
                        let sum = self
                            .builder
                            .build_int_add(start_idx, l64, "sum")
                            .map_err(Self::err)?;
                        self.umin(sum, len)?
                    } else {
                        len
                    };
                    let cl = self
                        .builder
                        .build_int_sub(end_idx, start_idx, "cl")
                        .map_err(Self::err)?;
                    Ok(Some(self.str_copy(s, start_idx, cl)?.into()))
                }
                ("STR$", 1) => match self.eval_value(&args[0])? {
                    // Integer STR$ = Rust i32::to_string == snprintf("%d"). Float STR$ is
                    // deferred (Rust float fmt != printf; would be silently wrong).
                    Some(BasicValueEnum::IntValue(iv)) => {
                        Ok(Some(self.str_from_int(self.fmt_d, iv)?.into()))
                    }
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
                            self.builder
                                .build_int_z_extend(byte, self.i32t, "asc")
                                .map_err(Self::err)?
                                .into(),
                        ))
                    }
                    _ => Ok(None),
                },
                ("SGN", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::IntValue(n)) => {
                        let z = self.i32t.const_zero();
                        let pos = self
                            .builder
                            .build_int_compare(IntPredicate::SGT, n, z, "sgp")
                            .map_err(Self::err)?;
                        let neg = self
                            .builder
                            .build_int_compare(IntPredicate::SLT, n, z, "sgn")
                            .map_err(Self::err)?;
                        let pi = self
                            .builder
                            .build_int_z_extend(pos, self.i32t, "sgpi")
                            .map_err(Self::err)?;
                        let ni = self
                            .builder
                            .build_int_z_extend(neg, self.i32t, "sgni")
                            .map_err(Self::err)?;
                        Ok(Some(
                            self.builder
                                .build_int_sub(pi, ni, "sgn")
                                .map_err(Self::err)?
                                .into(),
                        ))
                    }
                    _ => Ok(None),
                },
                ("INT", 1) | ("FIX", 1) => match self.eval_value(&args[0])? {
                    // Float → i32 truncation toward zero (matches `*n as i32`).
                    Some(BasicValueEnum::FloatValue(f)) => Ok(Some(
                        self.builder
                            .build_float_to_signed_int(f, self.i32t, "int")
                            .map_err(Self::err)?
                            .into(),
                    )),
                    _ => Ok(None),
                },
                ("MAX", 2) | ("MIN", 2) => {
                    match (self.eval_value(&args[0])?, self.eval_value(&args[1])?) {
                        (Some(BasicValueEnum::IntValue(a)), Some(BasicValueEnum::IntValue(b))) => {
                            let pred = if name == "MAX" {
                                IntPredicate::SGT
                            } else {
                                IntPredicate::SLT
                            };
                            let c = self
                                .builder
                                .build_int_compare(pred, a, b, "mmc")
                                .map_err(Self::err)?;
                            Ok(Some(
                                self.builder
                                    .build_select(c, a, b, "mm")
                                    .map_err(Self::err)?,
                            ))
                        }
                        _ => Ok(None),
                    }
                }
                ("HEX$", 1) => match self.eval_value(&args[0])? {
                    // snprintf("%X") == Rust `{:X}` on i32 (both hex of the 32-bit pattern).
                    Some(BasicValueEnum::IntValue(iv)) => {
                        Ok(Some(self.str_from_int(self.fmt_hex, iv)?.into()))
                    }
                    _ => Ok(None),
                },
                ("UCASE$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => {
                        Ok(Some(self.str_case(s, true)?.into()))
                    }
                    _ => Ok(None),
                },
                ("LCASE$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => {
                        Ok(Some(self.str_case(s, false)?.into()))
                    }
                    _ => Ok(None),
                },
                ("TRIM$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => {
                        Ok(Some(self.str_trim(s, true, true)?.into()))
                    }
                    _ => Ok(None),
                },
                ("LTRIM$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => {
                        Ok(Some(self.str_trim(s, true, false)?.into()))
                    }
                    _ => Ok(None),
                },
                ("RTRIM$", 1) => match self.eval_value(&args[0])? {
                    Some(BasicValueEnum::PointerValue(s)) => {
                        Ok(Some(self.str_trim(s, false, true)?.into()))
                    }
                    _ => Ok(None),
                },
                _ => Ok(None),
            }
        }
    }

    /// Parse an XBasic integer literal / constant value string to `i32`, mirroring the
    /// interpreter's `parse_integer`: `0x`/`0b`/`0o` radix prefixes plus decimal, reinterpreting
    /// unsigned 32/64-bit bit patterns as `i32` (e.g. `0xEDB88320`); unparsable → 0.
    fn parse_int_literal(v: &str) -> i32 {
        let radixed = |d: &str, r: u32| -> i32 {
            i32::from_str_radix(d, r)
                .or_else(|_| u32::from_str_radix(d, r).map(|u| u as i32))
                .or_else(|_| u64::from_str_radix(d, r).map(|u| u as i32))
                .unwrap_or(0)
        };
        if let Some(h) = v.strip_prefix("0x").or_else(|| v.strip_prefix("0X")) {
            radixed(h, 16)
        } else if let Some(b) = v.strip_prefix("0b").or_else(|| v.strip_prefix("0B")) {
            radixed(b, 2)
        } else if let Some(o) = v.strip_prefix("0o").or_else(|| v.strip_prefix("0O")) {
            radixed(o, 8)
        } else {
            v.parse::<i32>()
                .or_else(|_| v.parse::<u32>().map(|u| u as i32))
                .or_else(|_| v.parse::<u64>().map(|u| u as i32))
                .or_else(|_| v.parse::<i64>().map(|i| i as i32))
                .unwrap_or(0)
        }
    }

    /// Names DIM'd as arrays anywhere in the program — used to tell an `@array` pass (which
    /// needs the deferred array-descriptor ABI) from an `@scalar` pass.
    fn collect_array_names(items: &[IrItem], out: &mut std::collections::HashSet<String>) {
        for it in items {
            match it {
                IrItem::Dim {
                    symbol,
                    is_array: true,
                    ..
                } => {
                    out.insert(symbol.name.clone());
                }
                IrItem::Function { body, .. }
                | IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. } => collect_array_names(body, out),
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    collect_array_names(then_body, out);
                    if let Some(b) = else_body {
                        collect_array_names(b, out);
                    }
                }
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        collect_array_names(&c.body, out);
                    }
                    if let Some(b) = default {
                        collect_array_names(b, out);
                    }
                }
                IrItem::Compound(items) => collect_array_names(items, out),
                _ => {}
            }
        }
    }

    /// Every `SHARED` scalar (name → type) assigned anywhere in the program, recursing
    /// all bodies *including* nested `Function` items — `SHARED` variables span
    /// functions. Deterministic order (`BTreeMap`).
    fn collect_shared(items: &[IrItem], out: &mut std::collections::BTreeMap<String, ValueType>) {
        for it in items {
            match it {
                IrItem::SharedAssignment { target, .. } => {
                    out.entry(target.name.clone()).or_insert(target.value_type);
                }
                IrItem::Function { body, .. }
                | IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. } => collect_shared(body, out),
                IrItem::Dim {
                    symbol,
                    is_array: false,
                    shared: true,
                    ..
                } => {
                    out.entry(symbol.name.clone()).or_insert(symbol.value_type);
                }
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    collect_shared(then_body, out);
                    if let Some(b) = else_body {
                        collect_shared(b, out);
                    }
                }
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        collect_shared(&c.body, out);
                    }
                    if let Some(b) = default {
                        collect_shared(b, out);
                    }
                }
                IrItem::Compound(items) => collect_shared(items, out),
                _ => {}
            }
        }
    }

    /// Names (with type) assigned via a plain scalar `Assignment` anywhere in one function
    /// body (recursing into control-flow bodies, but NOT into nested `Function` items — each
    /// body is pre-allocated at its own `emit_body`). Used to pre-create zero-initialized
    /// allocas so a read emitted *before* the assignment in emission order — e.g. an
    /// auto-vivified counter read in `s${i+o}` then `INC o`'d later in the same loop — loads
    /// the stored value instead of a frozen undefined-variable constant. Deterministic order
    /// (`BTreeMap`). Arrays are `ArrayAssignment`/`Dim`, never collected here.
    fn collect_assigned_scalars(
        items: &[IrItem],
        out: &mut std::collections::BTreeMap<String, ValueType>,
    ) {
        for it in items {
            match it {
                IrItem::Assignment { target, .. } => {
                    out.entry(target.name.clone()).or_insert(target.value_type);
                }
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. } => collect_assigned_scalars(body, out),
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    collect_assigned_scalars(then_body, out);
                    if let Some(b) = else_body {
                        collect_assigned_scalars(b, out);
                    }
                }
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        collect_assigned_scalars(&c.body, out);
                    }
                    if let Some(b) = default {
                        collect_assigned_scalars(b, out);
                    }
                }
                IrItem::Compound(items) => collect_assigned_scalars(items, out),
                _ => {}
            }
        }
    }

    /// Arrays `DIM`'d anywhere in one function body (recursing into control-flow bodies, but
    /// NOT nested `Function` items) with their element type and maximum dimensionality. Used
    /// to pre-register array shape slots so a `UBOUND`/access emitted *before* the `DIM` in
    /// emission order — e.g. after a `GOSUB` to a subroutine that `DIM`s the array — reads the
    /// same runtime-updated slots instead of the unknown-array default (−1). Deterministic
    /// order (`BTreeMap`).
    fn collect_dim_arrays(
        items: &[IrItem],
        out: &mut std::collections::BTreeMap<String, (ValueType, usize)>,
    ) {
        for it in items {
            match it {
                IrItem::Dim {
                    symbol,
                    size,
                    extra_dims,
                    is_array: true,
                    ..
                } => {
                    // An empty-bracket array DIM (`DIM a$[]`) is still rank-1:
                    // prealloc must create one 0-init count slot so auto-vivify
                    // writes and UBOUND have a counter (a 0-dim shape would
                    // fold every access to offset 0).
                    let ndims = (size.iter().count() + extra_dims.len()).max(1);
                    out.entry(symbol.name.clone())
                        .and_modify(|e| {
                            if ndims > e.1 {
                                e.1 = ndims;
                            }
                        })
                        .or_insert((symbol.value_type, ndims));
                }
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. } => collect_dim_arrays(body, out),
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    collect_dim_arrays(then_body, out);
                    if let Some(b) = else_body {
                        collect_dim_arrays(b, out);
                    }
                }
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        collect_dim_arrays(&c.body, out);
                    }
                    if let Some(b) = default {
                        collect_dim_arrays(b, out);
                    }
                }
                IrItem::Compound(items) => collect_dim_arrays(items, out),
                _ => {}
            }
        }
    }

    /// Visit every call (`Call` item and `FunctionCall` expr) with its callee name and args.
    fn walk_calls(items: &[IrItem], cb: &mut dyn FnMut(&str, &[IrExpr])) {
        for it in items {
            match it {
                IrItem::Call { name, args } => {
                    cb(name, args);
                    for a in args {
                        walk_expr_calls(a, cb);
                    }
                }
                IrItem::Assignment { value, .. } => walk_expr_calls(value, cb),
                IrItem::ArrayAssignment {
                    index,
                    extra_indices,
                    value,
                    ..
                } => {
                    walk_expr_calls(index, cb);
                    for e in extra_indices {
                        walk_expr_calls(e, cb);
                    }
                    walk_expr_calls(value, cb);
                }
                IrItem::Print { items, .. } => {
                    for e in items {
                        walk_expr_calls(e, cb);
                    }
                }
                IrItem::If {
                    condition,
                    then_body,
                    else_body,
                } => {
                    walk_expr_calls(condition, cb);
                    walk_calls(then_body, cb);
                    if let Some(b) = else_body {
                        walk_calls(b, cb);
                    }
                }
                IrItem::While { condition, body } => {
                    walk_expr_calls(condition, cb);
                    walk_calls(body, cb);
                }
                IrItem::DoLoop {
                    pre_condition,
                    post_condition,
                    body,
                } => {
                    if let Some((c, _)) = pre_condition {
                        walk_expr_calls(c, cb);
                    }
                    if let Some((c, _)) = post_condition {
                        walk_expr_calls(c, cb);
                    }
                    walk_calls(body, cb);
                }
                IrItem::For {
                    start,
                    end,
                    step,
                    body,
                    ..
                } => {
                    walk_expr_calls(start, cb);
                    walk_expr_calls(end, cb);
                    if let Some(s) = step {
                        walk_expr_calls(s, cb);
                    }
                    walk_calls(body, cb);
                }
                IrItem::SelectCase {
                    selector,
                    cases,
                    default,
                } => {
                    walk_expr_calls(selector, cb);
                    for c in cases {
                        for cond in &c.conditions {
                            walk_expr_calls(cond, cb);
                        }
                        walk_calls(&c.body, cb);
                    }
                    if let Some(b) = default {
                        walk_calls(b, cb);
                    }
                }
                IrItem::Function { body, .. } => walk_calls(body, cb),
                IrItem::Compound(inner) => walk_calls(inner, cb),
                IrItem::Return { value: Some(v) } => walk_expr_calls(v, cb),
                IrItem::GosubExpr(e) | IrItem::GotoExpr(e) => walk_expr_calls(e, cb),
                _ => {}
            }
        }
    }

    fn walk_expr_calls(e: &IrExpr, cb: &mut dyn FnMut(&str, &[IrExpr])) {
        match &e.kind {
            IrExprKind::FunctionCall { name, args } => {
                cb(name, args);
                for a in args {
                    walk_expr_calls(a, cb);
                }
            }
            IrExprKind::ByRef(inner)
            | IrExprKind::Not(inner)
            | IrExprKind::Unary { operand: inner, .. } => walk_expr_calls(inner, cb),
            IrExprKind::Comparison { left, right, .. }
            | IrExprKind::Arithmetic { left, right, .. }
            | IrExprKind::Boolean { left, right, .. }
            | IrExprKind::Logical { left, right, .. } => {
                walk_expr_calls(left, cb);
                walk_expr_calls(right, cb);
            }
            IrExprKind::ArrayAccess {
                index,
                extra_indices,
                ..
            } => {
                walk_expr_calls(index, cb);
                for e in extra_indices {
                    walk_expr_calls(e, cb);
                }
            }
            _ => {}
        }
    }

    /// `@scalar` by-ref parameter positions per function: a position passed `ByRef` of a
    /// non-array symbol at ≥1 call site and never any other way (so lowering it as a shared
    /// pointer is always safe). Array `@` is excluded — it needs the array-descriptor ABI.
    fn collect_byref_params(items: &[IrItem]) -> HashMap<String, std::collections::HashSet<usize>> {
        use std::collections::HashSet;
        let mut arrays: HashSet<String> = HashSet::new();
        collect_array_names(items, &mut arrays);
        let mut byref: HashMap<String, HashSet<usize>> = HashMap::new();
        let mut other: HashMap<String, HashSet<usize>> = HashMap::new();
        {
            let mut on_call = |name: &str, args: &[IrExpr]| {
                for (i, a) in args.iter().enumerate() {
                    let scalar_ref = match &a.kind {
                        IrExprKind::ByRef(inner) => {
                            matches!(&inner.kind, IrExprKind::Symbol(s) if !arrays.contains(&s.name))
                        }
                        _ => false,
                    };
                    if scalar_ref {
                        byref.entry(name.to_string()).or_default().insert(i);
                    } else {
                        other.entry(name.to_string()).or_default().insert(i);
                    }
                }
            };
            walk_calls(items, &mut on_call);
        }
        let mut result: HashMap<String, HashSet<usize>> = HashMap::new();
        for (name, positions) in byref {
            let excluded = other.get(&name);
            let refset: HashSet<usize> = positions
                .into_iter()
                .filter(|p| excluded.is_none_or(|e| !e.contains(p)))
                .collect();
            if !refset.is_empty() {
                result.insert(name, refset);
            }
        }
        result
    }

    /// `@array[]` by-ref parameter positions per function: a position passed `ByRef` of an
    /// array-named symbol at ≥1 call site and never any other way (safe to lower as a shared
    /// descriptor). 1-D read-only sharing; string-array `$`-name mismatch and REDIM
    /// write-back are the deferred parts of the full effort (docs/17).
    fn collect_byref_array_params(
        items: &[IrItem],
    ) -> HashMap<String, std::collections::HashSet<usize>> {
        use std::collections::HashSet;
        let mut arrays: HashSet<String> = HashSet::new();
        collect_array_names(items, &mut arrays);
        let mut aref: HashMap<String, HashSet<usize>> = HashMap::new();
        let mut other: HashMap<String, HashSet<usize>> = HashMap::new();
        {
            let mut on_call = |name: &str, args: &[IrExpr]| {
                for (i, a) in args.iter().enumerate() {
                    let arr_ref = match &a.kind {
                        IrExprKind::ByRef(inner) => {
                            matches!(&inner.kind, IrExprKind::Symbol(s) if arrays.contains(&s.name))
                        }
                        _ => false,
                    };
                    if arr_ref {
                        aref.entry(name.to_string()).or_default().insert(i);
                    } else {
                        other.entry(name.to_string()).or_default().insert(i);
                    }
                }
            };
            walk_calls(items, &mut on_call);
        }
        let mut result: HashMap<String, HashSet<usize>> = HashMap::new();
        for (name, positions) in aref {
            let excluded = other.get(&name);
            let refset: HashSet<usize> = positions
                .into_iter()
                .filter(|p| excluded.is_none_or(|e| !e.contains(p)))
                .collect();
            if !refset.is_empty() {
                result.insert(name, refset);
            }
        }
        result
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
        let unit =
            FrontendUnit::parse("VERSION \"6.5.0\"\nDIM name$\nname$ = \"hello\"\nPRINT name$\n")
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
        let unit =
            FrontendUnit::parse("VERSION \"6.5.0\"\nDIM n\nn = 2 * 3 + 1\nPRINT n\n").unwrap();
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
        let unit =
            FrontendUnit::parse("VERSION \"1\"\nDIM x#\nx# = 10.0 / 4.0\nPRINT x#\n").unwrap();
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
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "hello\nworld\nworld\n"
        );
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
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "two-or-three\n1\n2\n3\nfour\n"
        );
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "20\nend\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_nested_gosub_in_loop() {
        use std::io::Write;
        use std::process::Command;
        // A GOSUB nested inside a FOR resumes exactly after itself via a per-site landing
        // block: the loop runs to completion and the subroutine is entered only for i = 2,
        // so the output is "2\nx\n" (not an infinite loop or a skipped remainder).
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
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_ng.o");
        let exep = dir.join("xb_llvm_ng.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "2\nx\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "12\n7\n81\n3\n123\n4\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_justify_and_radix_builtins() {
        use std::io::Write;
        use std::process::Command;
        // LJUST$/RJUST$ keep over-long input; CJUST$ truncates to width; LCLIP$/RCLIP$ drop
        // n bytes; OCT$/SIGNED$/NULL$ — all byte-exact vs the interpreter.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT LJUST$(\"hi\", 6)\n\
             PRINT RJUST$(\"hi\", 6)\n\
             PRINT CJUST$(\"hi\", 6)\n\
             PRINT LJUST$(\"toolong\", 4)\n\
             PRINT CJUST$(\"toolongstring\", 4)\n\
             PRINT LCLIP$(\"hello\", 2)\n\
             PRINT RCLIP$(\"hello\", 2)\n\
             PRINT OCT$(64)\n\
             PRINT SIGNED$(5)\n\
             PRINT LEN(NULL$(3))\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_jb.o");
        let exep = dir.join("xb_llvm_jb.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "hi    \n    hi\n  hi  \ntoolong\ntool\nllo\nhel\n100\n+5\n3\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_format_builtin() {
        use std::io::Write;
        use std::process::Command;
        // FORMAT$ string align (< > | &, with >-truncation taking the last w) + numeric
        // (#-digits, decimals, commas, $, *-fill, leading sign) mirror the interpreter.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT \"<\"; FORMAT$(\"<<<<<<\", \"hi\"); \">\"\n\
             PRINT \"<\"; FORMAT$(\">>>>>>\", \"hi\"); \">\"\n\
             PRINT \"<\"; FORMAT$(\"||||||\", \"hi\"); \">\"\n\
             PRINT \"<\"; FORMAT$(\">>>>\", \"toolongstring\"); \">\"\n\
             PRINT FORMAT$(\"######.##\", 1234.5)\n\
             PRINT FORMAT$(\"$#,###.##\", 1234567.89)\n\
             PRINT FORMAT$(\"*#####\", 42)\n\
             PRINT FORMAT$(\"#####\", 0 - 5)\n\
             PRINT FORMAT$(\"&\", \"amp\")\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_fmt.o");
        let exep = dir.join("xb_llvm_fmt.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "<hi    >\n<    hi>\n<  hi  >\n<ring>\n  1234.50\n$1,234,567.89\n***42\n-    5\namp\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_bin_and_radix_literals() {
        use std::io::Write;
        use std::process::Command;
        // BIN$/BINB$ (minimal binary of the u32 pattern, negatives -> 32 bits, width pad) and
        // 0x/0b/0o integer literals (unsigned pattern reinterpreted as i32) mirror the interpreter.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT BIN$(5)\n\
             PRINT BIN$(0 - 1)\n\
             PRINT BIN$(5, 8)\n\
             PRINT BINB$(6, 4)\n\
             PRINT 0xFF\n\
             PRINT 0b101\n\
             PRINT 0o17\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_bin.o");
        let exep = dir.join("xb_llvm_bin.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "101\n11111111111111111111111111111111\n00000101\n0b0110\n255\n5\n15\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_width_radix_builtins() {
        use std::io::Write;
        use std::process::Command;
        // 2-arg HEXX$/HEX$/OCTO$/OCT$ zero-pad the digits to the given width (prefix kept),
        // mirroring the interpreter — regression guard for asystem.x's HEXX$(endian$$, 16).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             PRINT HEXX$(0, 16)\n\
             PRINT HEXX$(255, 4)\n\
             PRINT HEX$(255, 4)\n\
             PRINT OCTO$(8, 4)\n\
             PRINT OCT$(8, 4)\n\
             PRINT HEXX$(0 - 1, 8)\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_wr.o");
        let exep = dir.join("xb_llvm_wr.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "0x0000000000000000\n0x00FF\n00FF\n0o0010\n0010\n0xFFFFFFFF\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_scalar_byref_params() {
        use std::io::Write;
        use std::process::Command;
        // An `@scalar` argument shares the caller's variable slot with a pointer param, so
        // the callee's writes are visible on return (matches the interpreter's copy-out).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             DECLARE FUNCTION Bump (@n)\n\
             DECLARE FUNCTION SetHi (@s$)\n\
             FUNCTION Entry ()\n\
             x = 5\n\
             Bump (@x)\n\
             PRINT x\n\
             a$ = \"lo\"\n\
             SetHi (@a$)\n\
             PRINT \"[\"; a$; \"]\"\n\
             END FUNCTION\n\
             FUNCTION Bump (@n)\n\
             n = n + 1\n\
             END FUNCTION\n\
             FUNCTION SetHi (@s$)\n\
             s$ = \"hi\"\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_br.o");
        let exep = dir.join("xb_llvm_br.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "6\n[hi]\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_array_byref_param() {
        use std::io::Write;
        use std::process::Command;
        // `@array[]` passes a 1-D array by reference via a `{data, dims}` descriptor: the
        // callee reads the caller's buffer and dim-0 count (UBOUND + element access). This
        // is the LLVM backend's *correct* behavior; the interpreter is value-degenerate for
        // `@array` value-reads (unblocks aarray_ISNODE, whose output is ISNODE-driven).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             DECLARE FUNCTION Dump (a[])\n\
             FUNCTION Entry ()\n\
             DIM a[2]\n\
             a[0] = 10\n\
             a[1] = 20\n\
             a[2] = 30\n\
             Dump (@a[])\n\
             END FUNCTION\n\
             FUNCTION Dump (a[])\n\
             FOR i = 0 TO UBOUND(a[])\n\
             PRINT a[i]\n\
             NEXT i\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_arrbr.o");
        let exep = dir.join("xb_llvm_arrbr.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "10\n20\n30\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_stubs_unknown_calls_like_interpreter() {
        use std::io::Write;
        use std::process::Command;
        // A call to a non-builtin, non-user function is a stub: the interpreter
        // (call.rs) returns 0 / "" by `$`-suffix, coerced to the target type. The
        // backend must match (previously it left the target unchanged).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             x = 9\n\
             x = UndefinedFunc (5)\n\
             PRINT x\n\
             s$ = \"keep\"\n\
             s$ = UndefinedStr$ (2)\n\
             PRINT \"[\"; s$; \"]\"\n\
             DIM f#\n\
             f# = UndefFloat (1)\n\
             PRINT f#\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_stub.o");
        let exep = dir.join("xb_llvm_stub.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "0\n[]\n0\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_shares_variables_across_functions() {
        use std::io::Write;
        use std::process::Command;
        // `##name` is a module-shared scalar: a write in one function is visible in
        // another. The backend must lower SharedAssignment/SharedVariable to an LLVM
        // global (both previously fell through to a no-op / None, dropping the shared
        // state), matching the interpreter and the C backend.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             FUNCTION SetIt ()\n\
             ##counter = 42\n\
             ##name$ = \"hello\"\n\
             END FUNCTION\n\
             FUNCTION Main\n\
             SetIt ()\n\
             PRINT ##counter\n\
             PRINT ##name$\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_shared.o");
        let exep = dir.join("xb_llvm_shared.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "42\nhello\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_shared_scalar_keyword() {
        use std::io::Write;
        use std::process::Command;
        // Keyword `SHARED y` scalars share module-level storage (classic
        // BASIC): Main's write is visible in a callee that also declares
        // `SHARED counter`, matching the interpreter and the C backends.
        // Previously the shared flag was discarded for scalars, so the callee
        // mutated its own fresh local (printed 5, not 17).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             FUNCTION Show ()\n\
             SHARED counter\n\
             counter = counter + 5\n\
             RETURN counter\n\
             END FUNCTION\n\
             FUNCTION Main\n\
             SHARED counter\n\
             counter = 12\n\
             PRINT Show ()\n\
             PRINT counter\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_shsc.o");
        let exep = dir.join("xb_llvm_shsc.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "17\n17\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_shared_array_keyword() {
        use std::io::Write;
        use std::process::Command;
        // `DIM SHARED arr[n]` (and the 2-D form) share program-global storage:
        // a callee's writes are visible in Main without passing the array,
        // matching the interpreter, Rust CEmitter, and cgen.x. Previously the
        // LLVM backend allocated shared arrays per-function (0/0 divergence).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DIM SHARED arr[3]\n\
             FUNCTION Fill ()\n\
             arr[0] = 7\n\
             arr[2] = 9\n\
             END FUNCTION\n\
             FUNCTION Main\n\
             Fill ()\n\
             PRINT arr[0]\n\
             PRINT arr[2]\n\
             END FUNCTION\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_sharr.o");
        let exep = dir.join("xb_llvm_sharr.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "7\n9\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_dyn_array_autovivify() {
        use std::io::Write;
        use std::process::Command;
        // Writes past a dynamic array's ubound auto-vivify: storage grows to
        // index+1 (preserving the prefix), matching interp/Rust-C/cgen.x.
        // Previously LLVM SIGSEGV'd on the NULL-buffer write.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             FUNCTION Main\n\
             DIM a$[]\n\
             a$[0] = \"x\"\n\
             a$[2] = \"z\"\n\
             REDIM a$[UBOUND(a$[]) + 3]\n\
             PRINT a$[0]\n\
             PRINT a$[2]\n\
             PRINT UBOUND(a$[])\n\
             END FUNCTION\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_autoviv.o");
        let exep = dir.join("xb_llvm_autoviv.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert!(
            run.status.success(),
            "run rc={:?}: {}",
            run.status.code(),
            String::from_utf8_lossy(&run.stderr)
        );
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "x\nz\n5\n",
            "auto-vivify + content-preserving REDIM output"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_defaults_undefined_variable_reads() {
        use std::io::Write;
        use std::process::Command;
        // A never-assigned variable auto-vivifies to its type default on read (0 /
        // ""), exactly as the interpreter does — the backend must not drop it from
        // PRINT. Regression guard for e.g. `afile.x` (`error = ERROR(0)` skipped).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             PRINT \"[\"; nevref; \"][\"; nevref$; \"]\"\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_uv.o");
        let exep = dir.join("xb_llvm_uv.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "[0][]\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_mid_assign() {
        use std::io::Write;
        use std::process::Command;
        // `s${n} = v` overwrites a byte of the string in place (1-based start `n+1`, byte
        // copy). Copy-on-write means it is safe even on a string-literal-assigned variable
        // (a read-only global): `"ABC"` with byte 3 set to 88 ('X') → "ABX". Regression guard
        // for `acharmap` (`test${i}=i`).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             s$ = \"ABC\"\n\
             s${2} = 88\n\
             PRINT s$\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_mid.o");
        let exep = dir.join("xb_llvm_mid.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "ABX\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_prealloc_autovivified_counter() {
        use std::io::Write;
        use std::process::Command;
        // A counter never explicitly initialized (`o`), incremented inside a loop, must
        // observe its own increments: `INC o`'s `o + 1` read is emitted once, before the
        // store, so without a pre-created zero-initialized alloca the read is a frozen `0`
        // constant and `o` stays 1. With the prealloc it counts 1,2,3. Regression guard for
        // `acharmap` (`o` typo'd, never initialized; read in `test${i+o}` before `INC o`).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             FOR i = 0 TO 2\n\
             INC o\n\
             NEXT i\n\
             PRINT o\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_prealloc.o");
        let exep = dir.join("xb_llvm_prealloc.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "3\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_evaluates_system_constants() {
        use std::io::Write;
        use std::process::Command;
        // A `$$` constant used in an expression carries its resolved value in the IR
        // (`IrExprKind::Constant`); the backend must evaluate it, not drop it. `$$WR`=1,
        // `$$RD`=0, `$$TRUE`=-1 (xst.dec). Regression guard for `astring` (OPEN mode args).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             PRINT $$WR; \" \"; $$RD; \" \"; $$TRUE\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_const.o");
        let exep = dir.join("xb_llvm_const.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "1 0 -1\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_file_open_close_lof() {
        use std::io::Write;
        use std::process::Command;
        // Real file runtime: OPEN returns a handle (table index + 3, monotonic like the
        // interpreter's `files.len() + 3`), CLOSE frees it, LOF reads the size (0 for the
        // freshly created empty file). Prints "3 4 0". Regression guard for `astring`.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             f1 = OPEN (\"xb_lock_ftest.dat\", $$WR)\n\
             CLOSE (f1)\n\
             f2 = OPEN (\"xb_lock_ftest.dat\", $$RD)\n\
             n = LOF (f2)\n\
             CLOSE (f2)\n\
             PRINT f1; \" \"; f2; \" \"; n\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_file.o");
        let exep = dir.join("xb_llvm_file.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        // Run in a temp cwd so the data file lands there, then clean it up.
        let run = Command::new(&exep).current_dir(&dir).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "3 4 0\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
        let _ = std::fs::remove_file(dir.join("xb_lock_ftest.dat"));
    }

    #[cfg(feature = "llvm")]
    fn run_llvm_source_in(source: &str, dir: &std::path::Path, stem: &str) -> std::process::Output {
        use std::io::Write;
        let unit = FrontendUnit::parse(source).expect("parse LLVM test source");
        let obj = llvm_backend::LlvmBackend
            .compile(&unit)
            .expect("compile LLVM test source");
        let objp = dir.join(format!("{stem}.o"));
        let exep = dir.join(format!("{stem}.bin"));
        std::fs::File::create(&objp)
            .unwrap()
            .write_all(obj.as_bytes())
            .unwrap();
        let link = std::process::Command::new("cc")
            .arg(&objp)
            .arg("-o")
            .arg(&exep)
            .output()
            .unwrap();
        assert!(
            link.status.success(),
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = std::process::Command::new(&exep)
            .current_dir(dir)
            .output()
            .unwrap();
        let _ = std::fs::remove_file(objp);
        let _ = std::fs::remove_file(exep);
        run
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_open_mode_matrix() {
        let root = std::env::temp_dir().join(format!("xb_llvm_open_modes_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&root);
        std::fs::create_dir_all(&root).unwrap();
        let p = |name: &str| root.join(name);
        for name in [
            "rd", "wr", "rw", "wrnew", "rwnew", "rdshare", "wrshare", "rwshare", "nbwr", "nbrw",
            "invalid",
        ] {
            std::fs::write(p(name), b"abc").unwrap();
        }
        let q = |path: &std::path::Path| path.to_string_lossy().replace('\\', "\\\\");
        let source = format!(
            "VERSION \"1\"\nFUNCTION Main\n\
             f = OPEN(\"{}\", 0) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 1) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 2) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 3) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 4) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x10) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x20) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x30) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x801) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x802) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x123) : PRINT LOF(f) : CLOSE(f)\n\
             PRINT OPEN(\"{}\", 0)\n\
             PRINT OPEN(\"{}\", 0x10)\n\
             f = OPEN(\"{}\", 0x20) : PRINT f : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x30) : PRINT f : CLOSE(f)\n\
             END FUNCTION\n",
            q(&p("rd")),
            q(&p("wr")),
            q(&p("rw")),
            q(&p("wrnew")),
            q(&p("rwnew")),
            q(&p("rdshare")),
            q(&p("wrshare")),
            q(&p("rwshare")),
            q(&p("nbwr")),
            q(&p("nbrw")),
            q(&p("invalid")),
            q(&p("missing_rd")),
            q(&p("missing_rdshare")),
            q(&p("create_wrshare")),
            q(&p("create_rwshare")),
        );
        let run = run_llvm_source_in(&source, &root, "open_modes");
        assert!(
            run.status.success(),
            "run: {}",
            String::from_utf8_lossy(&run.stderr)
        );
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "3\n0\n3\n0\n0\n3\n3\n3\n0\n3\n3\n-1\n-1\n14\n15\n"
        );
        assert!(!p("missing_rd").exists());
        assert!(!p("missing_rdshare").exists());
        assert!(p("create_wrshare").exists());
        assert!(p("create_rwshare").exists());
        let _ = std::fs::remove_dir_all(root);
    }

    #[cfg(all(feature = "llvm", unix))]
    #[test]
    fn llvm_backend_open_nonblock_fifo_returns() {
        use std::ffi::CString;
        use std::os::unix::ffi::OsStrExt;
        use std::time::{Duration, Instant};
        let root = std::env::temp_dir().join(format!("xb_llvm_fifo_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&root);
        std::fs::create_dir_all(&root).unwrap();
        let fifo = root.join("input.fifo");
        let c_fifo = CString::new(fifo.as_os_str().as_bytes()).unwrap();
        assert_eq!(unsafe { libc::mkfifo(c_fifo.as_ptr(), 0o600) }, 0);
        let path = fifo.to_string_lossy().replace('\\', "\\\\");
        let source = format!("VERSION \"1\"\nFUNCTION Main\nf = OPEN(\"{path}\", 0x800)\nPRINT f\nCLOSE(f)\nEND FUNCTION\n");
        // Compile/link separately so the parent can enforce a hard runtime deadline.
        let unit = FrontendUnit::parse(&source).unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let objp = root.join("fifo.o");
        let exep = root.join("fifo.bin");
        std::fs::write(&objp, obj.as_bytes()).unwrap();
        let link = std::process::Command::new("cc")
            .arg(&objp)
            .arg("-o")
            .arg(&exep)
            .output()
            .unwrap();
        assert!(
            link.status.success(),
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let mut child = std::process::Command::new(&exep)
            .current_dir(&root)
            .stdout(std::process::Stdio::piped())
            .spawn()
            .unwrap();
        let deadline = Instant::now() + Duration::from_secs(3);
        loop {
            if child.try_wait().unwrap().is_some() {
                break;
            }
            if Instant::now() >= deadline {
                let _ = child.kill();
                let _ = child.wait();
                panic!("LLVM OPEN blocked on FIFO despite NONBLOCK");
            }
            std::thread::sleep(Duration::from_millis(20));
        }
        let out = child.wait_with_output().unwrap();
        assert_eq!(String::from_utf8_lossy(&out.stdout), "3\n");
        let _ = std::fs::remove_dir_all(root);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_file_table_exhaustion_returns_negative_one() {
        use std::io::Write;
        use std::process::Command;
        // The FILE* table holds 256 slots; handles start at 3, so open #254 is the
        // last one that fits. Exhaustion must return -1 WITHOUT consuming a slot
        // (matching failed-open semantics) instead of writing out of bounds.
        let root = std::env::temp_dir().join(format!("xb_llvm_tbl_{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&root);
        std::fs::create_dir_all(&root).unwrap();
        let path = root.join("t.dat").to_string_lossy().replace('\\', "\\\\");
        let src = format!("VERSION \"1\"\nFUNCTION Main\nDIM i\nDIM h\nFOR i = 1 TO 254\nh = OPEN(\"{path}\", 0x20)\nIF h < 0 THEN PRINT \"early\"\nNEXT i\nPRINT OPEN(\"{path}\", 0x20)\nPRINT OPEN(\"{path}\", 0x20)\nPRINT OPEN(\"{path}\", 0x20)\nEND FUNCTION\n");
        let unit = FrontendUnit::parse(&src).unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let objp = root.join("tbl.o");
        let exep = root.join("tbl.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).current_dir(&root).output().unwrap();
        assert!(
            run.status.success(),
            "run: {}",
            String::from_utf8_lossy(&run.stderr)
        );
        // 254 loop opens + 2 more exactly fill the 256-slot table (handles 3..258);
        // the 257th open must return -1 instead of writing past the table.
        assert_eq!(String::from_utf8_lossy(&run.stdout), "257\n258\n-1\n");
        let _ = std::fs::remove_dir_all(root);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_record_write_sets_file_size() {
        use std::io::Write;
        use std::process::Command;
        // WRITE [n], arr[] (a composite array) lowers to __WRITE_RECORD(n, byte_count); the
        // backend writes byte_count bytes and fflushes, so a later re-OPEN reads that size via
        // LOF. Mirrors the interpreter, which writes zeros (only the byte count is
        // significant). REC = one 4-byte INT; r[3] = 4 elements = 16 bytes. Guard for `arecord`.
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             TYPE REC\n\
             INT .x\n\
             END TYPE\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             REC r[]\n\
             DIM r[3]\n\
             f = OPEN (\"xb_rec_lock.dat\", $$WR)\n\
             IF (f > 2) THEN WRITE [f], r[]\n\
             CLOSE (f)\n\
             g = OPEN (\"xb_rec_lock.dat\", $$RD)\n\
             IF (g > 2) THEN n = LOF (g)\n\
             CLOSE (g)\n\
             PRINT n\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_rec.o");
        let exep = dir.join("xb_llvm_rec.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).current_dir(&dir).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "16\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
        let _ = std::fs::remove_file(dir.join("xb_rec_lock.dat"));
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_compiles_do_loop_forms() {
        use std::io::Write;
        use std::process::Command;
        // All three DO/LOOP shapes. The body-first post-condition forms (LOOP UNTIL / LOOP
        // WHILE) were previously unhandled in emit_item — the loop body never ran (0
        // iterations). n counts to 3 (UNTIL n>=3), m to 8 (WHILE m<8), k to 2 (pre WHILE k<2).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             n = 0\n\
             DO\n\
             INC n\n\
             LOOP UNTIL (n >= 3)\n\
             PRINT n\n\
             m = 5\n\
             DO\n\
             INC m\n\
             LOOP WHILE (m < 8)\n\
             PRINT m\n\
             k = 0\n\
             DO WHILE (k < 2)\n\
             INC k\n\
             LOOP\n\
             PRINT k\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_doloop.o");
        let exep = dir.join("xb_llvm_doloop.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "3\n8\n2\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_eof_on_invalid_handle_terminates_loop() {
        use std::io::Write;
        use std::process::Command;
        // EOF must return 1 (true) for an invalid/closed handle so `DO … LOOP UNTIL EOF`
        // terminates instead of spinning forever (OPEN of a missing file → -1; the loop body
        // runs once, then EOF(-1)=1 exits). Prints "1". Regression guard for `acrc32` (which
        // OPENs a stdin-supplied filename that is empty when no input is piped).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             f = OPEN (\"xb_eof_nonexist.dat\", $$RD)\n\
             n = 0\n\
             DO\n\
             INC n\n\
             LOOP UNTIL EOF(f)\n\
             PRINT n\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_eof.o");
        let exep = dir.join("xb_llvm_eof.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).current_dir(&dir).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "1\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_funcaddr_is_program_order_id() {
        use std::io::Write;
        use std::process::Command;
        // &func() yields the interpreter's synthetic id — the function's 1-based program-order
        // index — not a real address, so `&f` compares/prints identically across backends.
        // Entry=1, Foo=2, Bar=3 → prints "2 3". Regression guard for `atimer` (`&Timer()`).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             DECLARE FUNCTION Foo ()\n\
             DECLARE FUNCTION Bar ()\n\
             FUNCTION Entry ()\n\
             PRINT &Foo(); \" \"; &Bar()\n\
             END FUNCTION\n\
             FUNCTION Foo ()\n\
             END FUNCTION\n\
             FUNCTION Bar ()\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_funcaddr.o");
        let exep = dir.join("xb_llvm_funcaddr.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "2 3\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_forward_dimd_array_ubound_and_null_elems() {
        use std::io::Write;
        use std::process::Command;
        // An array DIM'd in a GOSUB subroutine is used (UBOUND + element read) in code
        // emitted before the DIM. Pre-registration makes UBOUND read the runtime shape (3,
        // not the unknown-array -1 that skips the loop); unassigned string elements read as ""
        // (null-safe PRINT), matching the interpreter. Guard for `asortie`. Output:
        // "ubound=3\nx\ny\n\n\n".
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             GOSUB Init\n\
             PRINT \"ubound=\"; UBOUND(arr$[])\n\
             FOR i = 0 TO UBOUND(arr$[])\n\
             PRINT arr$[i]\n\
             NEXT i\n\
             RETURN\n\
             Init:\n\
             DIM arr$[3]\n\
             arr$[0] = \"x\"\n\
             arr$[1] = \"y\"\n\
             RETURN\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_fwdim.o");
        let exep = dir.join("xb_llvm_fwdim.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "ubound=3\nx\ny\n\n\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_unary_negation() {
        use std::io::Write;
        use std::process::Command;
        // `-1` lowers to Unary{Neg, 1}; if unhandled, eval_value returns None and the whole
        // assignment is silently dropped (the variable keeps its prior value). x=14 then x=-1
        // must print -1. Regression guard for `atask` (`count = -1`).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             x = 14\n\
             x = -1\n\
             PRINT x\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_uneg.o");
        let exep = dir.join("xb_llvm_uneg.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "-1\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_bare_return_halts_function() {
        use std::io::Write;
        use std::process::Command;
        // A bare `RETURN` (no value) lowers to GosubReturn; with no GOSUB in flight it halts
        // the function, matching the interpreter's empty-stack GosubReturn = halt. Here it is
        // nested in an `IF` (so the body is not routed to the state machine), which previously
        // made it a silent no-op that fell through. Prints only "before". Guard for `atask`
        // (`IFZ assigned THEN RETURN` before its message loop).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             PRINT \"before\"\n\
             n = 0\n\
             IFZ n THEN RETURN\n\
             PRINT \"after\"\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_bareret.o");
        let exep = dir.join("xb_llvm_bareret.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "before\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }

    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_string_vs_number_comparison() {
        use std::io::Write;
        use std::process::Command;
        // A string compared to a number uses its length, so `IFZ s$` (lowered to `s$ == 0`)
        // tests emptiness — matching the interpreter. Empty string → prints "s-empty";
        // non-empty "hello" → the second IFZ is false. Prints "s-empty\ndone". Regression
        // guard for `qbtoxb` (`IFZ qfile$`).
        let unit = FrontendUnit::parse(
            "VERSION \"1\"\n\
             DECLARE FUNCTION Entry ()\n\
             FUNCTION Entry ()\n\
             s$ = \"\"\n\
             IFZ s$ THEN PRINT \"s-empty\"\n\
             t$ = \"hello\"\n\
             IFZ t$ THEN PRINT \"t-empty\"\n\
             PRINT \"done\"\n\
             END FUNCTION\n\
             END PROGRAM\n",
        )
        .unwrap();
        let obj = llvm_backend::LlvmBackend.compile(&unit).unwrap();
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_ifzs.o");
        let exep = dir.join("xb_llvm_ifzs.bin");
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
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let run = Command::new(&exep).output().unwrap();
        assert_eq!(String::from_utf8_lossy(&run.stdout), "s-empty\ndone\n");
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }
    #[cfg(feature = "llvm")]
    #[test]
    fn llvm_backend_kernel32_stdio() {
        use std::io::Write as _;
        use std::process::Command;
        // RT-KERNEL32 through the LLVM backend: GetStdHandle/WriteFile/ReadFile
        // with the same golden as the interp/Rust-C/cgen three-way test.
        let src = "PROGRAM \"k32l\"\n\
                   VERSION \"0.1\"\n\
                   FUNCTION Main ()\n\
                   h = 1\n\
                   out$ = \"hello-k32\" + CHR$ (10)\n\
                   n = LEN (out$)\n\
                   sent = 0\n\
                   WriteFile (h, &out$, n, &sent, 0)\n\
                   PRINT sent\n\
                   ##hin = GetStdHandle (-10)\n\
                   buf$ = CHR$ (0, 32)\n\
                   got = 0\n\
                   ReadFile (##hin, &buf$, 32, &got, 0)\n\
                   PRINT got\n\
                   PRINT LEFT$ (buf$, got)\n\
                   bad = GetStdHandle (7)\n\
                   PRINT bad\n\
                   END FUNCTION\n\
                   END PROGRAM\n";
        let unit = FrontendUnit::parse(src).expect("parse kernel32 LLVM program");
        let obj = llvm_backend::LlvmBackend
            .compile(&unit)
            .expect("compile kernel32 LLVM program");
        let dir = std::env::temp_dir();
        let objp = dir.join("xb_llvm_k32.o");
        let exep = dir.join("xb_llvm_k32.bin");
        std::fs::write(&objp, obj.as_bytes()).unwrap();
        let link = Command::new("cc")
            .arg(&objp)
            .arg("-o")
            .arg(&exep)
            .output()
            .unwrap();
        assert!(
            link.status.success(),
            "link: {}",
            String::from_utf8_lossy(&link.stderr)
        );
        let mut child = Command::new(&exep)
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .spawn()
            .unwrap();
        child
            .stdin
            .as_mut()
            .unwrap()
            .write_all(b"POSTDATA-123")
            .unwrap();
        let run = child.wait_with_output().unwrap();
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            "hello-k32\n10\n12\nPOSTDATA-123\n-1\n"
        );
        let _ = std::fs::remove_file(&objp);
        let _ = std::fs::remove_file(&exep);
    }
}
