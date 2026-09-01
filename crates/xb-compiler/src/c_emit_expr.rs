use crate::c_emit_helpers::{
    arith_op, boolean_op, cmp_op, emit_c_function_name, emit_c_string, emit_type_conversion,
    is_type_conversion,
};
use crate::checked::ArithmeticOp;
use crate::ir::{IrExpr, IrExprKind, IrSymbol};
use crate::ValueType;
#[allow(clippy::if_same_then_else)]
pub(crate) fn emit_expr(expr: &IrExpr, out: &mut String) {
    match &expr.kind {
        IrExprKind::StringLiteral(v) => {
            if v.contains('\0') {
                // Embedded NUL: xb_str goes through strlen and would truncate;
                // xb_str_n (usage-gated helper) carries the byte length.
                out.push_str("xb_str_n(\"");
                emit_c_string(v, out);
                out.push_str(&format!("\", {})", v.len()));
            } else {
                out.push_str("xb_str(\"");
                emit_c_string(v, out);
                out.push_str("\")");
            }
        }
        IrExprKind::IntegerLiteral(v) => {
            // XBasic decimal literals like 08, 09 are invalid C octal constants.
            // Strip leading zeros (preserving "0" itself and 0x hex prefixes).
            if v.starts_with("0o") || v.starts_with("0O") {
                // XBasic octal literal `0o666` → C octal `0666`.
                let digits = &v[2..];
                out.push('0');
                out.push_str(digits);
            } else if v.starts_with("0x")
                || v.starts_with("0X")
                || v.starts_with("0b")
                || v.starts_with("0B")
            {
                // A hex/binary literal (0xEDB88320, 0xFFFFFFFF) is an i32 bit
                // pattern (XBasic INTEGER is i32) but in C it is `unsigned int`
                // (positive). Cast to int32_t for the signed i32 value the
                // interpreter uses (0xFFFFFFFF -> -1), so later shifts/prints stay
                // i32-faithful even though storage is intptr_t (CGEN-SHIFT).
                let wrap = expr.value_type == ValueType::Integer;
                if wrap {
                    out.push_str("(int32_t)(");
                }
                out.push_str(v);
                if wrap {
                    out.push(')');
                }
            } else if let Some(stripped) = v.strip_prefix('-') {
                out.push('-');
                let s = stripped.trim_start_matches('0');
                out.push_str(if s.is_empty() { "0" } else { s });
            } else {
                let s = v.trim_start_matches('0');
                out.push_str(if s.is_empty() { "0" } else { s });
            }
        }
        IrExprKind::FloatLiteral(v) => {
            let lower = v.to_ascii_lowercase();
            if lower == "nan" || lower == "-nan" {
                out.push_str(v.strip_prefix('-').map_or("NAN", |_| "-NAN"));
            } else if lower == "inf"
                || lower == "-inf"
                || lower == "infinity"
                || lower == "-infinity"
            {
                out.push_str(if v.starts_with('-') {
                    "-INFINITY"
                } else {
                    "INFINITY"
                });
            } else {
                out.push_str(v);
            }
        }
        IrExprKind::Constant { name, value } => {
            if name.ends_with('$') {
                // String constant: emit the global variable reference.
                // The global is initialized via __attribute__((constructor)).
                out.push_str(&format!("xb_const_{name}"));
            } else {
                let lower = value.to_ascii_lowercase();
                if lower == "nan" || lower == "-nan" {
                    out.push_str(value.strip_prefix('-').map_or("NAN", |_| "-NAN"));
                } else if lower == "inf"
                    || lower == "-inf"
                    || lower == "infinity"
                    || lower == "-infinity"
                {
                    out.push_str(if value.starts_with('-') {
                        "-INFINITY"
                    } else {
                        "INFINITY"
                    });
                } else {
                    out.push_str(value);
                }
            }
        }
        IrExprKind::SharedVariable(s) => {
            out.push_str("xb_shared_");
            out.push_str(&sanitize_c_ident(&s.name));
        }
        IrExprKind::Symbol(s) => {
            emit_symbol_ref(s, out);
        }
        // C by-ref write-back is not modeled; emit the inner value. Adding `&`
        // unconditionally is wrong — a by-ref arg to a *scalar* param needs the
        // value, only a by-ref arg to an *array/pointer* param needs the address;
        // the correct choice needs the callee's param kind (see docs/17
        // CGEN-BYREF-ARG). No corpus or demo uses by-ref, so this arm is inert
        // there and only affects XBSourceLib (7 core libs, float-array by-ref).
        IrExprKind::ByRef(inner) => emit_expr(inner, out),
        IrExprKind::Comparison { op, left, right } => {
            let ls = left.value_type == ValueType::String;
            let rs = right.value_type == ValueType::String;
            if ls && rs {
                out.push_str("(-(xb_scmp(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push_str(") ");
                out.push_str(cmp_op(*op));
                out.push_str(" 0))");
            } else if ls || rs {
                // Mixed string/numeric (e.g. `IFZ s$` lowers to `s$ == 0`): the
                // interpreter compares the string's byte length to the number
                // (compare.rs), so emit a length-vs-number test — never xb_scmp,
                // whose xb_len(0) reads a bogus length header and crashes.
                out.push_str("-(");
                if ls {
                    out.push_str("(intptr_t)xb_len(");
                    emit_expr(left, out);
                    out.push(')');
                } else {
                    emit_expr(left, out);
                }
                out.push(' ');
                out.push_str(cmp_op(*op));
                out.push(' ');
                if rs {
                    out.push_str("(intptr_t)xb_len(");
                    emit_expr(right, out);
                    out.push(')');
                } else {
                    emit_expr(right, out);
                }
                out.push(')');
            } else {
                out.push_str("-(");
                emit_expr(left, out);
                out.push(' ');
                out.push_str(cmp_op(*op));
                out.push(' ');
                emit_expr(right, out);
                out.push(')');
            }
        }
        IrExprKind::Arithmetic { op, left, right } => {
            if op == &ArithmeticOp::Add
                && (left.value_type == ValueType::String || right.value_type == ValueType::String)
            {
                out.push_str("xb_concat(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push(')');
            } else if op == &ArithmeticOp::Pow {
                out.push_str("pow(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push(')');
            } else if op == &ArithmeticOp::IntegerDiv
                && (left.value_type == ValueType::Float || right.value_type == ValueType::Float)
            {
                out.push_str("(double)(int)(");
                emit_expr(left, out);
                out.push_str(" / ");
                emit_expr(right, out);
                out.push(')');
            } else if matches!(
                op,
                ArithmeticOp::Mod | ArithmeticOp::Shl | ArithmeticOp::Shr
            ) && (left.value_type == ValueType::Float
                || right.value_type == ValueType::Float)
            {
                // Integer-only C operators (% << >>) with a Float operand:
                // XBasic's variant type system allows MOD/shift on float-stored
                // values (truncating to int at runtime). Cast both operands to
                // intptr_t so the C operator is valid.
                let mask = expr.value_type == ValueType::Integer;
                if mask {
                    out.push_str("(int32_t)");
                }
                out.push('(');
                if left.value_type == ValueType::Float {
                    out.push_str("(intptr_t)(");
                    emit_expr(left, out);
                    out.push(')');
                } else {
                    emit_expr(left, out);
                }
                out.push(' ');
                out.push_str(arith_op(*op));
                out.push(' ');
                if right.value_type == ValueType::Float {
                    out.push_str("(intptr_t)(");
                    emit_expr(right, out);
                    out.push(')');
                } else {
                    emit_expr(right, out);
                }
                out.push(')');
            } else {
                // Integer arithmetic wraps at 32 bits (XBasic INTEGER is i32;
                // interp `wrapping_*`). Values are stored as `intptr_t` (i64) so
                // that address-valued integers - computed GOSUB/GOTO label
                // pointers - are NOT truncated (see CGEN-SHIFT). Compute in i64,
                // then truncate the *result* to i32: `(int32_t)(a OP b)`. This is
                // defined (i64 op can't overflow for i32 operands; the cast is a
                // 2's-complement narrowing) and needs no `-fwrapv`. Byte-neutral
                // for in-range values (the cast is identity).
                let mask = expr.value_type == ValueType::Integer;
                if mask {
                    out.push_str("(int32_t)");
                }
                out.push('(');
                emit_expr(left, out);
                out.push(' ');
                out.push_str(arith_op(*op));
                out.push(' ');
                emit_expr(right, out);
                out.push(')');
            }
        }
        IrExprKind::Not(inner) => {
            if expr.value_type == ValueType::Integer {
                out.push_str("(int32_t)");
            }
            if inner.value_type == ValueType::String {
                // NOT on a string = truthiness complement (desugared
                // `SELECT CASE FALSE / CASE rows, text$[]` in xui's TextMessage).
                // The interpreter's bit_operand errors on String, so there is no
                // numeric-parity to preserve; `!ptr` matches how a bare string
                // Symbol condition is emitted (`if (xb_str_x)`).
                out.push_str("(-(!(");
                emit_expr(inner, out);
                out.push_str(")))");
            } else {
                out.push_str("(~");
                emit_expr(inner, out);
                out.push(')');
            }
        }
        IrExprKind::Unary { op, operand } => {
            // Unary POS is identity in the interpreter (`Pos => v`, any type). On a
            // String operand it must pass through unchanged — `+` on a `char*` is
            // an invalid C unary expression (`+log$` in xrun.x). Numeric POS/Neg
            // keep the (int32_t)-masked form (CGEN-SHIFT), byte-neutral.
            if matches!(op, xb_frontend::UnaryOp::Pos) && operand.value_type == ValueType::String {
                emit_expr(operand, out);
            } else {
                if expr.value_type == ValueType::Integer {
                    out.push_str("(int32_t)");
                }
                out.push('(');
                match op {
                    xb_frontend::UnaryOp::Neg => out.push('-'),
                    xb_frontend::UnaryOp::Pos => out.push('+'),
                }
                emit_expr(operand, out);
                out.push(')');
            }
        }
        IrExprKind::Boolean { op, left, right } => {
            // Bitwise AND/OR/XOR on i32 values; mask the result to i32 so high
            // bits from the i64 storage don't leak into a later shift (CGEN-SHIFT).
            if expr.value_type == ValueType::Integer {
                out.push_str("(int32_t)");
            }
            out.push_str("((");
            emit_expr(left, out);
            out.push_str(") ");
            out.push_str(boolean_op(*op));
            out.push_str(" (");
            emit_expr(right, out);
            out.push_str("))");
        }
        IrExprKind::Logical { .. } => crate::c_emit_logical::emit_logical(expr, out),
        IrExprKind::FunctionCall { name, args } => {
            // RR-07: If a function is user-defined, prefer the compiled legacy
            // body over native helper shadows. This enables behavior-port testing.
            let is_user_defined = crate::c_emit::is_defined_func(name);
            if name == "CHR$" {
                if args.len() == 1 {
                    out.push_str("xb_chr");
                    out.push('(');
                    emit_expr(&args[0], out);
                    out.push_str(", 1)");
                } else {
                    out.push_str("xb_chr");
                    out.push('(');
                    for (i, arg) in args.iter().enumerate() {
                        if i > 0 {
                            out.push_str(", ");
                        }
                        emit_expr(arg, out);
                    }
                    out.push(')');
                }
            } else if name == "ASC" {
                // The interpreter's ASC reads only `args[0]` (byte 0 of the
                // string) and ignores an optional 2nd position arg; `xb_asc` is
                // 1-arg. Emit just the string so `ASC(line$, 1)` (core libs
                // CreateHelp/xcol) compiles and matches the interpreter.
                out.push_str("xb_asc(");
                emit_expr(&args[0], out);
                out.push(')');
            } else if name == "INSTR" {
                if args.len() == 2 {
                    out.push_str("xb_instr2");
                } else {
                    out.push_str("xb_instr3");
                }
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if name == "RINSTR" {
                if args.len() == 2 {
                    out.push_str("xb_rinstr2");
                } else {
                    out.push_str("xb_rinstr3");
                }
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if name == "INSTRI" || name == "RINSTRI" {
                let base = if name == "INSTRI" {
                    "xb_instri"
                } else {
                    "xb_rinstri"
                };
                out.push_str(base);
                out.push_str(if args.len() == 2 { "2" } else { "3" });
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if name == "INCHR" || name == "RINCHR" || name == "INCHRI" || name == "RINCHRI" {
                let base = match name.as_str() {
                    "INCHR" => "xb_inchr",
                    "RINCHR" => "xb_rinchr",
                    "INCHRI" => "xb_inchri",
                    _ => "xb_rinchri",
                };
                if args.len() == 2 {
                    out.push_str(base);
                    out.push('2');
                } else {
                    out.push_str(base);
                }
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if name == "ABS" && expr.value_type == ValueType::Float {
                out.push_str("xb_fabs(");
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if is_type_conversion(name) {
                emit_type_conversion(name, &args[0], out, emit_expr);
            } else if name.eq_ignore_ascii_case("SUBADDR") || name.eq_ignore_ascii_case("SUBADDRESS") || name.eq_ignore_ascii_case("VARPTR") {
                out.push_str("((intptr_t)&");
                if let Some(arg) = args.first() {
                    emit_expr(arg, out);
                } else {
                    out.push('0');
                }
                out.push(')');
            } else if name == "HEXX$" {
                crate::c_emit_str2::emit_hexx(args, out, emit_expr);
            } else if crate::c_emit_str2::try_emit_int2str2(name, args, out, emit_expr) {
            } else if crate::c_emit_str2::try_emit_format(name, args, out, emit_expr) {
            } else if name == "RCLIP$" || name == "LCLIP$" {
                crate::c_emit_str2::emit_clip(name, args, out, emit_expr);
            } else if name == "STUFF$" {
                crate::c_emit_str2::emit_stuff(args, out, emit_expr);
            } else if name == "STR$" && !args.is_empty() && args[0].value_type == ValueType::Float {
                out.push_str("xb_str_float(");
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if !is_user_defined && name == "XstStringToNumber" && args.len() == 5 {
                // three args are `@`-out-params written through pointers.
                out.push_str("xb_xst_str_to_num(");
                emit_byref_value(&args[0], out);
                out.push_str(", ");
                emit_expr(&args[1], out);
                out.push_str(", ");
                emit_byref_addr(&args[2], out);
                out.push_str(", ");
                emit_byref_addr(&args[3], out);
                out.push_str(", ");
                emit_byref_addr(&args[4], out);
                out.push(')');
            } else if !is_user_defined && name == "XuiGetNextCallback" && args.len() >= 2 {
                // Headless: deliver one synthetic CloseWindow (sets @grid+@message$),
                // then FALSE — terminates the demo's message loop (mirrors interp).
                out.push_str("xb_gui_next_callback(");
                emit_byref_addr(&args[0], out);
                out.push_str(", ");
                emit_byref_addr(&args[1], out);
                out.push(')');
            } else if !is_user_defined && name == "GetStdHandle" && args.len() == 1 {
                // RT-KERNEL32: Win32-CGI stdio handles (-10 stdin, -11 stdout,
                // -12 stderr; else -1). Mirrors interp call.rs.
                out.push_str("xb_getstdhandle(");
                emit_expr(&args[0], out);
                out.push(')');
            } else if !is_user_defined && name == "WriteFile" && args.len() == 5 {
                // RT-KERNEL32 `WriteFile(h, &buf$, bytes, &written, _)`: the
                // legacy `&x` prefix lowers to a PLAIN symbol (no byref), so
                // the buffer passes as its char* value and the count out-param
                // takes its address positionally (mirrors interp call.rs).
                out.push_str("xb_write_file(");
                emit_expr(&args[0], out);
                out.push_str(", ");
                emit_byref_value(&args[1], out);
                out.push_str(", ");
                emit_expr(&args[2], out);
                out.push_str(", ");
                emit_byref_addr(&args[3], out);
                out.push_str(", 0)");
            } else if !is_user_defined && name == "ReadFile" && args.len() == 5 {
                // RT-KERNEL32 `ReadFile(h, &buf$, bytes, &read, _)`: the buffer
                // is replaced through its char** address (helper xb_allocs the
                // exact byte count read).
                out.push_str("xb_read_file(");
                emit_expr(&args[0], out);
                out.push_str(", ");
                emit_byref_addr(&args[1], out);
                out.push_str(", ");
                emit_expr(&args[2], out);
                out.push_str(", ");
                emit_byref_addr(&args[3], out);
                out.push_str(", 0)");
            } else if !is_user_defined && name == "XstQuickSort" && args.len() == 5 {
                emit_quicksort_call(args, out);
            } else if !is_user_defined && name == "XstCopyArray" && args.len() == 2 {
                emit_copyarray_call(args, out);
            } else if !is_user_defined && name == "XstBackStringToBinString$" && !args.is_empty() {
                // Pure string transform (mirrors interp xst::back_to_bin); the
                // `@back$` arg is passed by value (the string).
                out.push_str("xb_back_to_bin(");
                emit_byref_value(&args[0], out);
                out.push(')');
            } else if name == "EXTS"
                || name == "EXTU"
                || name == "CLR"
                || name == "SET"
                || name == "MAKE"
            {
                crate::c_emit_bitops::emit_bit_op_call(name, args, out);
            } else if name == "MID$" && args.len() == 2 {
                crate::c_emit_str2::emit_mid2(args, out, emit_expr);
            } else if crate::c_emit_stmt::is_at_write_builtin(name) {
                // *AT memory reads: the interpreter has no real memory and
                // returns 0 / 0.0 (builtin.rs) — a real *(T*)(addr) would
                // dereference the stub-0 address. Emit the zero-default; also
                // sidesteps the arg-count mismatch (1-arg UBYTEAT(addr) vs the
                // 2-arg xb_ubyteat helper).
                let (_, is_float) = crate::c_emit_stmt::at_write_ctype(name);
                out.push_str(if is_float { "0.0" } else { "0" });
            } else if name == "EOF" {
                // The interpreter ignores the handle arg entirely (EOF tests
                // piped-input exhaustion; call.rs) — the arg is not even
                // evaluated. xb_eof takes no parameter.
                out.push_str("xb_eof()");
            } else if name == "INLINE$" {
                // INLINE$ prints a literal prompt (interp call.rs pushes it to the
                // real output sink — see eval.rs threading output through
                // FunctionCall) then reads the next stdin line (or "" at EOF).
                // Non-literal prompts are not printed (interp only pushes a
                // StringLiteral arg); mirrors the statement position (c_emit_stmt).
                out.push_str("xb_inline(");
                match args.first().map(|a| &a.kind) {
                    Some(crate::ir::IrExprKind::StringLiteral(_)) => emit_expr(&args[0], out),
                    _ => out.push('0'),
                }
                out.push(')');
            } else if (name == "RIGHT$" || name == "LEFT$") && args.len() == 1 {
                // Missing count: the interpreter errors if this executes
                // (string_slice indexes args[1]); pad 0 so it compiles.
                emit_c_function_name(name, out);
                out.push('(');
                emit_expr(&args[0], out);
                out.push_str(", 0)");
            } else if !is_user_defined
                && name.starts_with("Xin")
                && crate::c_emit_xin::emit_xin_call(name, args, out)
            {
                // RT-XIN-SOCKETS: real BSD-socket lowering (C backend only;
                // interp keeps zero-stubs — no raw-address memory model).
            } else if crate::c_emit::is_unknown_call(name) {
                // Unknown callee (non-builtin, undefined): mirror the interpreter's
                // call_function stub (call.rs) and the LLVM backend (lib.rs) — yield
                // the zero-default ("" for a $-suffixed name, else 0). Args are
                // skipped, matching the backends, so undefined/external calls (GUI
                // Xgr*/Xui*, forward-referenced library functions) compile and match.
                if name.ends_with('$') {
                    out.push_str("xb_str(\"\")");
                } else {
                    out.push('0');
                }
            } else if !is_user_defined && crate::c_emit::is_builtin_without_helper(name) {
                // Recognized builtin with no emitter arm and no C helper (the name
                // maps to xb_user_*, e.g. a call-form UBOUND): the interpreter
                // errors only if this executes — yield the zero-default.
                if name.ends_with('$') {
                    out.push_str("xb_str(\"\")");
                } else {
                    out.push('0');
                }
            } else if is_user_defined {
                // builtin name mapping (e.g. xma's SINH → xb_user_SINH,
                // not the runtime's xb_sinh wrapper).
                // Composite return: extract .R when used in expression context.
                // (Assignment context is handled in c_emit_stmt.rs.)
                let comp_ret = if crate::c_emit::is_suppress_comp_r() {
                    None
                } else {
                    crate::c_emit::func_return_composite(name)
                };
                if comp_ret.is_some() {
                    out.push('(');
                }
                out.push_str("xb_user_");
                out.push_str(name);
                out.push('(');
                emit_call_args(name, args, out);
                out.push(')');
                if comp_ret.is_some() {
                    out.push_str(").R");
                }
            } else {
                emit_c_function_name(name, out);
                out.push('(');
                emit_call_args(name, args, out);
                out.push(')');
            }
        }
        IrExprKind::ArrayAccess {
            symbol,
            index,
            extra_indices,
        } => {
            if crate::c_emit::is_descriptor_param(&symbol.name) {
                // Descriptor by-ref array param: deref its data pointer `(*xb_var_x_dd)[i]` (docs/18).
                // Check before is_undimmed_array (ARCH-01) — a descriptor param may appear
                // undimmed in FN_UNDIMMED_ARRAYS but has caller-backed storage.
                crate::c_emit::emit_array_var_name(symbol, out);
                out.push('[');
                crate::c_emit::emit_array_subscript(&symbol.name, index, extra_indices, out);
                out.push(']');
            } else if crate::c_emit::is_undimmed_array(&symbol.name) {
                // Auto-vivified (never-`Dim`'d) array: the interpreter reads the
                // type default for any index (eval.rs missing-slot arm); emit it.
                emit_default(symbol.value_type, out);
            } else {
                crate::c_emit::emit_array_var_name(symbol, out);
                out.push('[');
                crate::c_emit::emit_array_subscript(&symbol.name, index, extra_indices, out);
                out.push(']');
            }
        }
        IrExprKind::ArrayUBound { symbol } => {
            if crate::c_emit::is_descriptor_param(&symbol.name) {
                // Descriptor by-ref array param: the length cell `*xb_ub_x` (docs/18).
                out.push_str("((int)*");
                out.push_str(&crate::c_emit::descriptor_ub_ident(&symbol.name));
                out.push(')');
            } else if crate::c_emit::is_undimmed_array(&symbol.name) {
                if symbol.value_type == ValueType::String {
                    // UBOUND(s$) of a scalar string is its last byte offset,
                    // LEN(s$) - 1 (interp eval.rs ArrayUBound string arm) —
                    // aback's `FOR i = 0 TO UBOUND(b$)` byte loop.
                    out.push_str("(xb_len(");
                    emit_var_name(symbol, out);
                    out.push_str(") - 1)");
                } else {
                    // UBOUND of an undeclared array is -1 (interp eval.rs), so
                    // `FOR i = 0 TO UBOUND(a[])` loops zero times.
                    out.push_str("(-1)");
                }
            } else if crate::c_emit::is_dyn_array(&symbol.name) {
                // Late/repeated DIM: the array is a hoisted pointer; sizeof would
                // be wrong. Read the tracked upper bound.
                out.push_str("((int)xb_ub_");
                out.push_str(&crate::c_emit::array_ident(&symbol.name));
                out.push(')');
            } else {
                out.push_str("(int)(sizeof(");
                crate::c_emit::emit_array_var_name(symbol, out);
                out.push_str(")/sizeof(");
                crate::c_emit::emit_array_var_name(symbol, out);
                out.push_str("[0])-1)");
            }
        }
        IrExprKind::SizeOf { symbol } => {
            // SIZE reports the *logical* XBasic element size (XLONG integer = 4;
            // GIANT/DOUBLE/STRING = 8), matching SizeOfType + the interpreter —
            // NOT the C storage size (every scalar is an 8-byte intptr_t/double/
            // char*). Emit element-count * logical size, so SIZE(x)=4 and
            // SIZE(int a[3])=16 as in the interpreter (arithmetic is 32-bit XLONG).
            let logical = match symbol.value_type {
                ValueType::Integer => 4,
                _ => 8,
            };
            if crate::c_emit::is_descriptor_param(&symbol.name) {
                out.push_str("(int)((*");
                out.push_str(&crate::c_emit::descriptor_ub_ident(&symbol.name));
                out.push_str(" + 1) * ");
                out.push_str(&logical.to_string());
                out.push(')');
            } else {
                out.push_str("(int)(sizeof(");
                crate::c_emit::emit_array_var_name(symbol, out);
                out.push_str(")/sizeof(intptr_t)) * ");
                out.push_str(&logical.to_string());
            }
        }
        IrExprKind::SizeOfType { value_type } => {
            let size = match value_type {
                ValueType::Integer => 4,
                ValueType::Giant => 8,
                ValueType::Float => 8,
                ValueType::String => 8,
            };
            out.push_str(&size.to_string());
        }
        IrExprKind::LabelAddress(name) => {
            if crate::c_emit::fn_has_label(name) {
                out.push_str("((intptr_t)&&xb_label_");
                out.push_str(name);
                out.push(')');
            } else {
                // Label absent from this function: the interpreter's
                // `label_addresses.get(name)` yields 0 (eval.rs); `&&xb_label_X`
                // would be an undeclared C label.
                out.push('0');
            }
        }
        IrExprKind::FuncAddr(name) => {
            if crate::c_emit::is_unknown_call(name) {
                // Unknown function address: interp/LLVM resolve &func of an unknown
                // name to 0; match so it compiles instead of referencing an
                // undeclared symbol.
                out.push('0');
            } else {
                // The interpreter's &Func value is a synthetic 1-based id in
                // program-item order (eval.rs function_id), not a machine
                // address — LLVM matches; emit the same id for byte parity.
                out.push_str(&crate::c_emit::func_addr_id(name).to_string());
            }
        }
    }
}

/// Emit a condition expression in boolean context. A string-typed condition
/// is wrapped with `xb_len(...) > 0` — in XBasic, `IF s$` is true when the
/// string is non-empty, but a C `char*` pointer is always truthy (non-NULL),
/// even for `xb_str("")`. Integer/float conditions pass through unchanged.
pub(crate) fn emit_condition(expr: &IrExpr, out: &mut String) {
    if expr.value_type == ValueType::String {
        out.push_str("(xb_len(");
        emit_expr(expr, out);
        out.push_str(") > 0)");
    } else {
        emit_expr(expr, out);
    }
}

fn emit_symbol_ref(s: &IrSymbol, out: &mut String) {
    if crate::c_emit::is_descriptor_param(&s.name) {
        // A bare descriptor-array-param name reads the slot's SCALAR field, which
        // for a by-ref array param is the type default (the array lives in
        // `slot.array`; `read_slot` returns `slot.value` = default) — so `IFZ a[]`
        // (lowered to `a == 0`) tests the empty scalar, and `addr = a` (memory-op,
        // stubbed consumer) reads 0. Emitting the default matches the interpreter
        // (helpers.rs `read_slot`); the data pointer is reached via `a[i]`/UBOUND
        // (docs/18).
        emit_default(s.value_type, out);
        return;
    }
    if crate::c_emit::is_array_param(&s.name) && s.value_type == crate::ValueType::String {
        // Plain by-ref string array param used as scalar (e.g., `IFZ qb$[]` where
        // `qb$` is `string[]` param). The scalar slot is the type default (empty
        // string), not the array data pointer. Emitting `xb_str("")` makes
        // `IFZ` correctly test empty (length 0) so the early RETURN is taken
        // for empty input, matching the interpreter.
        emit_default(s.value_type, out);
        return;
    }
    emit_var_name(s, out);
}

pub(crate) fn emit_var_name(symbol: &IrSymbol, out: &mut String) {
    match symbol.value_type {
        ValueType::String => {
            out.push_str("xb_str_");
        }
        _ => {
            out.push_str("xb_var_");
        }
    }
    // Composite member names contain dots and auto-declared type-suffixed names
    // carry `$`/`!`/`#` — C identifiers can't contain those. Replace `.` with
    // `_`, `$` with `_s`, `!` with `_f`, `#` with `_d` to avoid collisions
    // (the type is already encoded in the xb_str_/xb_var_ prefix).
    out.push_str(&sanitize_c_ident(&symbol.name));
}

/// Emit the *value* of a (possibly `@`-wrapped) argument — used for a by-ref
/// arg passed to a parameter that wants the value (e.g. XstStringToNumber's
/// string `@s$`).
pub(crate) fn emit_byref_value(expr: &IrExpr, out: &mut String) {
    match &expr.kind {
        IrExprKind::ByRef(inner) => emit_expr(inner, out),
        _ => emit_expr(expr, out),
    }
}

/// Emit the *address* of a (possibly `@`-wrapped) lvalue argument — used for a
/// by-ref builtin out-param (XstStringToNumber's `@afterOff`/`@rtype`/`@value$$`).
pub(crate) fn emit_byref_addr(expr: &IrExpr, out: &mut String) {
    let inner = match &expr.kind {
        IrExprKind::ByRef(b) => b.as_ref(),
        _ => expr,
    };
    match &inner.kind {
        IrExprKind::Symbol(s) => {
            out.push('&');
            emit_var_name(s, out);
        }
        IrExprKind::SharedVariable(s) => {
            out.push_str("&xb_shared_");
            out.push_str(&sanitize_c_ident(&s.name));
        }
        // Not an lvalue (shouldn't happen for an @out-param): pass null.
        _ => out.push('0'),
    }
}

/// Sanitize an XBasic name for use as a C identifier suffix (after a prefix
/// like `xb_ub_`). Mirrors the sanitization in `emit_var_name`.
pub(crate) fn sanitize_c_ident(name: &str) -> String {
    // The XBasic type suffixes `$ ! # @ & %` (and doubled `$$ @@ && %%`) are part
    // of a name — `value` (XLONG), `value@` (SBYTE), `value&&` (ULONG) are three
    // distinct variables — but none is a legal C identifier char. Map each to a
    // distinct `_x` (the type is already in the `xb_var_`/`xb_str_` prefix), so
    // the three become `value`, `value_a`, `value_l_l`.
    name.replace('.', "_")
        .replace('$', "_s")
        .replace('!', "_f")
        .replace('#', "_d")
        .replace('@', "_a")
        .replace('&', "_l")
        .replace('%', "_h")
}

/// Emit a call's argument list. For a user-defined callee whose arg count
/// mismatches its declared params, reconcile arity exactly like the interpreter
/// (`call.rs` `params.zip(args)`: extra args dropped unevaluated) and the LLVM
/// backend (`eval_args`: missing params padded with zero-defaults). A matching
/// count (every self-host/v0.1 program) emits byte-identically to the plain loop.
pub(crate) fn emit_call_args(name: &str, args: &[IrExpr], out: &mut String) {
    let params = crate::c_emit::defined_params(name);
    let (take, pad) = match &params {
        Some(p) if args.len() != p.len() => {
            (args.len().min(p.len()), &p[args.len().min(p.len())..])
        }
        _ => (args.len(), &[][..]),
    };
    let param_arrays = crate::c_emit::defined_param_arrays(name);
    let param_byref = crate::c_emit::defined_param_byref(name);
    let param_descriptor = crate::c_emit::defined_param_descriptor(name);
    for (i, arg) in args.iter().take(take).enumerate() {
        if i > 0 {
            out.push_str(", ");
        }
        // Descriptor-aware by-ref array passing (docs/18): the arg form is dictated
        // by the *callee's* param shape. A descriptor position takes `(data, ub)`;
        // a plain `T*` position receiving our descriptor local derefs `*x_d`.
        if let IrExprKind::ByRef(b) = &arg.kind {
            if let IrExprKind::Symbol(s) = &b.kind {
                let callee_desc = param_descriptor
                    .as_ref()
                    .is_some_and(|pd| pd.get(i).copied().unwrap_or(false));
                if callee_desc {
                    if crate::c_emit::is_descriptor_param(&s.name) {
                        crate::c_emit::emit_descriptor_data_ptr(s, out);
                        out.push_str(", ");
                        out.push_str(&crate::c_emit::descriptor_ub_ident(&s.name));
                    } else {
                        out.push('&');
                        crate::c_emit::emit_raw_array_name(s, out);
                        out.push_str(", &xb_ub_");
                        out.push_str(&crate::c_emit::array_ident(&s.name));
                    }
                    continue;
                }
                if crate::c_emit::is_descriptor_param(&s.name) {
                    out.push_str("(*");
                    crate::c_emit::emit_descriptor_data_ptr(s, out);
                    out.push(')');
                    continue;
                }
            }
        }
        // A by-ref arg to a *pointer* param (an array param, or a by-ref scalar
        // param `T* x_ref`) must be a pointer, not a value — a scalar float by-ref
        // to `double *` is otherwise a hard cc error. A pure dyn array is already a
        // pointer variable → pass it directly; everything else (scalar, static
        // array, dual-use scalar facet, string) takes address-of `&x`. Only fires
        // for by-ref args to known callees; the corpus has 0 by-ref → byte-identical.
        let to_ptr = param_arrays
            .as_ref()
            .is_some_and(|pa| pa.get(i).copied().unwrap_or(false))
            || param_byref
                .as_ref()
                .is_some_and(|pb| pb.get(i).copied().unwrap_or(false));
        if to_ptr {
            if let IrExprKind::ByRef(inner) = &arg.kind {
                match &inner.kind {
                    IrExprKind::Symbol(s) => {
                        let is_array_param = param_arrays
                            .as_ref()
                            .is_some_and(|pa| pa.get(i).copied().unwrap_or(false));
                        if is_array_param {
                            let caller_is_shared = crate::c_emit::is_shared_array(&s.name);
                            let caller_is_desc = crate::c_emit::is_descriptor_param(&s.name);
                            if caller_is_shared || caller_is_desc {
                                if caller_is_desc {
                                    out.push_str("(*");
                                    crate::c_emit::emit_descriptor_data_ptr(s, out);
                                    out.push(')');
                                } else if crate::c_emit::is_dyn_array(&s.name) {
                                    crate::c_emit::emit_raw_array_name(s, out);
                                } else {
                                    out.push('&');
                                    crate::c_emit::emit_raw_array_name(s, out);
                                }
                            } else if crate::c_emit::is_dyn_array(&s.name)
                                && !crate::c_emit::is_dual_use(&s.name)
                            {
                                emit_var_name(s, out);
                            } else {
                                out.push('&');
                                emit_var_name(s, out);
                            }
                        } else if crate::c_emit::is_dyn_array(&s.name)
                            && !crate::c_emit::is_dual_use(&s.name)
                        {
                            emit_var_name(s, out);
                        } else {
                            out.push('&');
                            emit_var_name(s, out);
                        }
                        continue;
                    }
                    // Byref of a keyword-`SHARED` scalar: address of the
                    // file-scope shared slot.
                    IrExprKind::SharedVariable(s) => {
                        out.push_str("&xb_shared_");
                        out.push_str(&sanitize_c_ident(&s.name));
                        continue;
                    }
                    _ => {}
                }
            }
        }
        emit_expr(arg, out);
    }
    for (i, vt) in pad.iter().enumerate() {
        if take + i > 0 {
            out.push_str(", ");
        }
        emit_default(*vt, out);
    }
}

/// The array symbol of a whole-array by-ref arg (`@a[]` → `ByRef(Symbol(a))`).
fn array_symbol(expr: &IrExpr) -> Option<&IrSymbol> {
    let inner = match &expr.kind {
        IrExprKind::ByRef(b) => b.as_ref(),
        _ => expr,
    };
    match &inner.kind {
        IrExprKind::Symbol(s) | IrExprKind::SharedVariable(s) => Some(s),
        IrExprKind::ArrayAccess { symbol, .. } | IrExprKind::ArrayUBound { symbol } => Some(symbol),
        _ => None,
    }
}

/// Emit the element count of an array arg (`*ub+1` descriptor, `ub+1` dyn, else
/// `sizeof/sizeof`).
fn emit_array_len(sym: &IrSymbol, out: &mut String) {
    if crate::c_emit::is_descriptor_param(&sym.name) {
        out.push_str("(*");
        out.push_str(&crate::c_emit::descriptor_ub_ident(&sym.name));
        out.push_str(" + 1)");
    } else if crate::c_emit::is_dyn_array(&sym.name) {
        out.push_str("(xb_ub_");
        out.push_str(&crate::c_emit::array_ident(&sym.name));
        out.push_str(" + 1)");
    } else {
        out.push_str("(intptr_t)(sizeof(");
        crate::c_emit::emit_array_var_name(sym, out);
        out.push_str(")/sizeof(");
        crate::c_emit::emit_array_var_name(sym, out);
        out.push_str("[0]))");
    }
}

/// Emit the `(data_addr, ub_addr)` descriptor pair for a resizable array arg — a
/// descriptor param forwards `xb_var_x_d, xb_ub_x`; a local dyn takes address-of.
fn emit_array_descriptor(sym: &IrSymbol, out: &mut String) {
    if crate::c_emit::is_descriptor_param(&sym.name) {
        crate::c_emit::emit_descriptor_data_ptr(sym, out);
        out.push_str(", ");
        out.push_str(&crate::c_emit::descriptor_ub_ident(&sym.name));
    } else {
        out.push('&');
        crate::c_emit::emit_raw_array_name(sym, out);
        out.push_str(", &xb_ub_");
        out.push_str(&crate::c_emit::array_ident(&sym.name));
    }
}

fn array_et(vt: ValueType) -> &'static str {
    match vt {
        ValueType::Float => "1",
        ValueType::String => "2",
        _ => "0",
    }
}

/// Emit `XstQuickSort(@a[], @n[], low, high, mode)` — sort `a[]` in place (8-byte
/// slot reorder) + resize/fill the index array `@n[]` via its descriptor.
pub(crate) fn emit_quicksort_call(args: &[IrExpr], out: &mut String) {
    let a = array_symbol(&args[0]);
    let n = array_symbol(&args[1]);
    out.push_str("xb_quicksort((void*)");
    match a {
        Some(s) => crate::c_emit::emit_array_var_name(s, out),
        None => out.push('0'),
    }
    out.push_str(", ");
    out.push_str(array_et(
        a.map(|s| s.value_type).unwrap_or(ValueType::Integer),
    ));
    out.push_str(", ");
    match a {
        Some(s) => emit_array_len(s, out),
        None => out.push('0'),
    }
    out.push_str(", (intptr_t**)");
    match n {
        Some(s) => {
            let mut d = String::new();
            emit_array_descriptor(s, &mut d);
            let (nd, nub) = d.split_once(", ").unwrap_or((d.as_str(), "0"));
            out.push_str(nd);
            out.push_str(", (intptr_t*)");
            out.push_str(nub);
        }
        None => out.push_str("0, (intptr_t*)0"),
    }
    out.push_str(", (intptr_t)(");
    emit_expr(&args[2], out);
    out.push_str("), (intptr_t)(");
    emit_expr(&args[3], out);
    out.push_str("), (intptr_t)(");
    emit_expr(&args[4], out);
    out.push_str("))");
}

/// Emit `XstCopyArray(@src[], @dst[])` — resize `@dst[]` to `@src[]`'s length and
/// copy every element (strings deep-copied by the runtime helper).
pub(crate) fn emit_copyarray_call(args: &[IrExpr], out: &mut String) {
    let src = array_symbol(&args[0]);
    let dst = array_symbol(&args[1]);
    out.push_str("xb_copyarray((void*)");
    match src {
        Some(s) => crate::c_emit::emit_array_var_name(s, out),
        None => out.push('0'),
    }
    out.push_str(", ");
    match src {
        Some(s) => emit_array_len(s, out),
        None => out.push('0'),
    }
    out.push_str(", ");
    out.push_str(array_et(
        src.map(|s| s.value_type).unwrap_or(ValueType::Integer),
    ));
    out.push_str(", (void**)");
    match dst {
        Some(s) => {
            let mut d = String::new();
            emit_array_descriptor(s, &mut d);
            let (dd, dub) = d.split_once(", ").unwrap_or((d.as_str(), "0"));
            out.push_str(dd);
            out.push_str(", (intptr_t*)");
            out.push_str(dub);
        }
        None => out.push_str("0, (intptr_t*)0"),
    }
    out.push(')');
}

pub(crate) fn emit_default(vt: ValueType, out: &mut String) {
    match vt {
        ValueType::Giant => out.push('0'),
        ValueType::Integer => out.push('0'),
        ValueType::Float => out.push_str("0.0"),
        ValueType::String => out.push_str("xb_str(\"\")"),
    }
}

/// Emits the return-variable declaration at the top of a C function body.
pub(crate) fn emit_return_var_decl(name: &str, return_type: ValueType, out: &mut String) {
    let ret_name = name.trim_end_matches('$');
    out.push_str("    ");
    out.push_str(crate::c_emit::c_type(return_type));
    out.push(' ');
    emit_var_name(
        &IrSymbol {
            name: ret_name.to_string(),
            value_type: return_type,
        },
        out,
    );
    out.push_str(" = ");
    emit_default(return_type, out);
    out.push_str(";\n");
}
