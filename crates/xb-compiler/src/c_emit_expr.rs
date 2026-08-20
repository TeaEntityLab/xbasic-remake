use crate::c_emit_helpers::{
    arith_op, boolean_op, cmp_op, emit_c_function_name, emit_c_string, emit_type_conversion,
    is_type_conversion,
};
use crate::checked::ArithmeticOp;
use crate::ir::{IrExpr, IrExprKind, IrSymbol};
use crate::ValueType;

pub(crate) fn emit_expr(expr: &IrExpr, out: &mut String) {
    match &expr.kind {
        IrExprKind::StringLiteral(v) => {
            out.push_str("xb_str(\"");
            emit_c_string(v, out);
            out.push_str("\")");
        }
        IrExprKind::IntegerLiteral(v) => {
            // XBasic decimal literals like 08, 09 are invalid C octal constants.
            // Strip leading zeros (preserving "0" itself and 0x hex prefixes).
            if v.starts_with("0x") || v.starts_with("0X") || v.starts_with("0b") || v.starts_with("0B") {
                out.push_str(v);
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
            out.push_str(v);
        }
        IrExprKind::Constant { value, .. } => {
            out.push_str(value);
        }
        IrExprKind::SharedVariable(s) => {
            out.push_str("xb_shared_");
            out.push_str(&s.name.replace('.', "_").replace('$', "_s").replace('!', "_f").replace('#', "_d"));
        }
        IrExprKind::Symbol(s) => {
            emit_symbol_ref(s, out);
        }
        // C by-ref write-back is not modeled; emit the inner value. (No corpus or
        // self-host program uses `@`, so this arm is exercised only via the
        // interpreter path today — see docs/17 RT-NESTED-COMPOSITE.)
        IrExprKind::ByRef(inner) => emit_expr(inner, out),
        IrExprKind::Comparison { op, left, right } => {
            if left.value_type == ValueType::String || right.value_type == ValueType::String {
                out.push_str("(-(xb_scmp(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push_str(") ");
                out.push_str(cmp_op(*op));
                out.push_str(" 0))");
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
            } else {
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
            out.push_str("(~");
            emit_expr(inner, out);
            out.push(')');
        }
        IrExprKind::Unary { op, operand } => {
            out.push('(');
            match op {
                xb_frontend::UnaryOp::Neg => out.push('-'),
                xb_frontend::UnaryOp::Pos => out.push('+'),
            }
            emit_expr(operand, out);
            out.push(')');
        }
        IrExprKind::Boolean { op, left, right } => {
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
                    out.push_str("2");
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
            } else if name == "EXTS"
                || name == "EXTU"
                || name == "CLR"
                || name == "SET"
                || name == "MAKE"
            {
                crate::c_emit_bitops::emit_bit_op_call(name, args, out);
            } else if name == "MID$" && args.len() == 2 {
                crate::c_emit_str2::emit_mid2(args, out, emit_expr);
            } else if name == "EOF" {
                // The interpreter ignores the handle arg entirely (EOF tests
                // piped-input exhaustion; call.rs) — the arg is not even
                // evaluated. xb_eof takes no parameter.
                out.push_str("xb_eof()");
            } else if name == "INLINE$" {
                // Expression-position INLINE$ never prints its prompt: eval.rs
                // routes FunctionCall through call_function with a *discarded*
                // output sink, so the interp swallows it. Only the next stdin
                // line (or "" at EOF) is produced.
                out.push_str("xb_inline(0)");
            } else if (name == "RIGHT$" || name == "LEFT$") && args.len() == 1 {
                // Missing count: the interpreter errors if this executes
                // (string_slice indexes args[1]); pad 0 so it compiles.
                emit_c_function_name(name, out);
                out.push('(');
                emit_expr(&args[0], out);
                out.push_str(", 0)");
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
            } else if crate::c_emit::is_builtin_without_helper(name) {
                // Recognized builtin with no emitter arm and no C helper (the name
                // maps to xb_user_*, e.g. a call-form UBOUND): the interpreter
                // errors only if this executes — yield the zero-default.
                if name.ends_with('$') {
                    out.push_str("xb_str(\"\")");
                } else {
                    out.push('0');
                }
            } else {
                emit_c_function_name(name, out);
                out.push('(');
                emit_call_args(name, args, out);
                out.push(')');
            }
        }
        IrExprKind::ArrayAccess { symbol, index, .. } => {
            if crate::c_emit::is_undimmed_array(&symbol.name) {
                // Auto-vivified (never-`Dim`'d) array: the interpreter reads the
                // type default for any index (eval.rs missing-slot arm); emit it.
                emit_default(symbol.value_type, out);
            } else {
                emit_symbol_ref(symbol, out);
                out.push('[');
                emit_expr(index, out);
                out.push(']');
            }
        }
        IrExprKind::ArrayUBound { symbol } => {
            if crate::c_emit::is_undimmed_array(&symbol.name) {
                // UBOUND of an undeclared array is -1 (interp eval.rs), so
                // `FOR i = 0 TO UBOUND(a[])` loops zero times.
                out.push_str("(-1)");
            } else if crate::c_emit::is_dyn_array(&symbol.name) {
                // Late/repeated DIM: the array is a hoisted pointer; sizeof would
                // be wrong. Read the tracked upper bound.
                out.push_str("((int)xb_ub_");
                out.push_str(&symbol.name);
                out.push(')');
            } else {
                out.push_str("(int)(sizeof(");
                emit_var_name(symbol, out);
                out.push_str(")/sizeof(");
                emit_var_name(symbol, out);
                out.push_str("[0])-1)");
            }
        }
        IrExprKind::SizeOf { symbol } => {
            out.push_str("(int)sizeof(");
            emit_var_name(symbol, out);
            out.push(')');
        }
        IrExprKind::SizeOfType { value_type } => {
            let size = match value_type {
                ValueType::Integer => 4,
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
                out.push_str("((intptr_t)&");
                emit_c_function_name(name, out);
                out.push(')');
            }
        }
    }
}

fn emit_symbol_ref(s: &IrSymbol, out: &mut String) {
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
    let sanitized = symbol.name
        .replace('.', "_")
        .replace('$', "_s")
        .replace('!', "_f")
        .replace('#', "_d");
    out.push_str(&sanitized);
}

/// Emit a call's argument list. For a user-defined callee whose arg count
/// mismatches its declared params, reconcile arity exactly like the interpreter
/// (`call.rs` `params.zip(args)`: extra args dropped unevaluated) and the LLVM
/// backend (`eval_args`: missing params padded with zero-defaults). A matching
/// count (every self-host/v0.1 program) emits byte-identically to the plain loop.
pub(crate) fn emit_call_args(name: &str, args: &[IrExpr], out: &mut String) {
    let params = crate::c_emit::defined_params(name);
    let (take, pad) = match &params {
        Some(p) if args.len() != p.len() => (args.len().min(p.len()), &p[args.len().min(p.len())..]),
        _ => (args.len(), &[][..]),
    };
    for (i, arg) in args.iter().take(take).enumerate() {
        if i > 0 {
            out.push_str(", ");
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

pub(crate) fn emit_default(vt: ValueType, out: &mut String) {
    match vt {
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
