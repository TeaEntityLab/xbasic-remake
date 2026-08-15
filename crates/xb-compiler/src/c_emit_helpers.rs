use crate::checked::{ArithmeticOp, BooleanOp, ComparisonOp, ValueType};
use crate::ir::IrExpr;

pub(crate) fn cmp_op(op: ComparisonOp) -> &'static str {
    match op {
        ComparisonOp::Equal => "==",
        ComparisonOp::NotEqual => "!=",
        ComparisonOp::Less => "<",
        ComparisonOp::Greater => ">",
        ComparisonOp::LessEqual => "<=",
        ComparisonOp::GreaterEqual => ">=",
    }
}

pub(crate) fn arith_op(op: ArithmeticOp) -> &'static str {
    match op {
        ArithmeticOp::Add => "+",
        ArithmeticOp::Sub => "-",
        ArithmeticOp::Mul => "*",
        ArithmeticOp::Div => "/",
        ArithmeticOp::IntegerDiv => "/",
        ArithmeticOp::Mod => "%",
        ArithmeticOp::Shl => "<<",
        ArithmeticOp::Shr => ">>",
        ArithmeticOp::Pow => "**",
    }
}

pub(crate) fn boolean_op(op: BooleanOp) -> &'static str {
    match op {
        BooleanOp::And => "&",
        BooleanOp::Or => "|",
        BooleanOp::Xor => "^",
    }
}

pub(crate) fn emit_c_string(s: &str, out: &mut String) {
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\t' => out.push_str("\\t"),
            '\r' => out.push_str("\\r"),
            '\0' => out.push_str("\\0"),
            c if (c as u32) < 0x20 => {
                out.push_str(&format!("\\x{:02x}", c as u32));
            }
            c => out.push(c),
        }
    }
}

pub(crate) fn emit_c_function_name(name: &str, out: &mut String) {
    match name {
        "LEN" => out.push_str("xb_len"),
        "ASC" => out.push_str("xb_asc"),
        "CHR$" => out.push_str("xb_chr"),
        "LEFT$" => out.push_str("xb_left"),
        "RIGHT$" => out.push_str("xb_right"),
        "MID$" => out.push_str("xb_mid"),
        "INSTR" => out.push_str("xb_instr"),
        "VAL" => out.push_str("xb_val"),
        "STR$" => out.push_str("xb_str_num"),
        "UCASE$" => out.push_str("xb_ucase"),
        "LCASE$" => out.push_str("xb_lcase"),
        "TRIM$" => out.push_str("xb_trim"),
        "LTRIM$" => out.push_str("xb_ltrim"),
        "RTRIM$" => out.push_str("xb_rtrim"),
        "SPACE$" => out.push_str("xb_space"),
        "ABS" => out.push_str("xb_abs"),
        "SGN" => out.push_str("xb_sgn"),
        "INT" => out.push_str("xb_int"),
        "FIX" => out.push_str("xb_fix"),
        "MAX" => out.push_str("xb_max"),
        "MIN" => out.push_str("xb_min"),
        "HEX$" => out.push_str("xb_hex"),
        "BIN$" => out.push_str("xb_bin"),
        "STRING$" | "STRING" => out.push_str("xb_string"),
        "SQRT" => out.push_str("xb_sqrt"),
        "SIN" => out.push_str("xb_sin"),
        "COS" => out.push_str("xb_cos"),
        "TAN" => out.push_str("xb_tan"),
        "EXP" => out.push_str("xb_exp"),
        "LOG" => out.push_str("xb_log"),
        "ACOS" => out.push_str("xb_acos"),
        "ASIN" => out.push_str("xb_asin"),
        "ATAN2" => out.push_str("xb_atan2"),
        "LOG10" => out.push_str("xb_log10"),
        "POWER" => out.push_str("xb_power"),
        "SINH" => out.push_str("xb_sinh"),
        "COSH" => out.push_str("xb_cosh"),
        "TANH" => out.push_str("xb_tanh"),
        "ASINH" => out.push_str("xb_asinh"),
        "ACOSH" => out.push_str("xb_acosh"),
        "ATANH" => out.push_str("xb_atanh"),
        "EXP10" => out.push_str("xb_exp10"),
        "EXP2" => out.push_str("xb_exp2"),
        "COT" => out.push_str("xb_cot"),
        "SEC" => out.push_str("xb_sec"),
        "CSC" => out.push_str("xb_csc"),
        "COTH" => out.push_str("xb_coth"),
        "SECH" => out.push_str("xb_sech"),
        "CSCH" => out.push_str("xb_csch"),
        "ACOT" => out.push_str("xb_acot"),
        "ASEC" => out.push_str("xb_asec"),
        "ACSC" => out.push_str("xb_acsc"),
        "ACOTH" => out.push_str("xb_acoth"),
        "ASECH" => out.push_str("xb_asech"),
        "ACSCH" => out.push_str("xb_acsch"),
        "RND" => out.push_str("xb_rnd"),
        "CEIL" => out.push_str("xb_ceil"),
        "FLOOR" => out.push_str("xb_floor"),
        "ROUND" => out.push_str("xb_round"),
        "TIMER" => out.push_str("xb_timer"),
        "TIME$" => out.push_str("xb_time"),
        "DATE$" => out.push_str("xb_date"),
        "INLINE$" => out.push_str("xb_inline"),
        "READLINE$" => out.push_str("xb_readline"),
        "HEXX$" => out.push_str("xb_hexx"),
        "RJUST$" => out.push_str("xb_rjust"),
        "LJUST$" => out.push_str("xb_ljust"),
        "INCHR" => out.push_str("xb_inchr"),
        "RINCHR" => out.push_str("xb_rinchr"),
        "STUFF$" => out.push_str("xb_stuff"),
        "EOF" => out.push_str("xb_eof"),
        "VERSION$" => out.push_str("xb_version"),
        "SIGNED$" => out.push_str("xb_signed"),
        "NULL$" => out.push_str("xb_null"),
        _ => {
            out.push_str("xb_user_");
            out.push_str(name);
        }
    }
}

/// Emits C code for HEXX$(value[, width]). 1-arg form passes width=0.
pub(crate) fn emit_hexx(args: &[IrExpr], out: &mut String, emit_fn: impl Fn(&IrExpr, &mut String)) {
    out.push_str("xb_hexx(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    if args.len() == 2 {
        emit_fn(&args[1], out);
    } else {
        out.push('0');
    }
    out.push(')');
}

/// Emits C code for 2-arg HEX$(value, width) → xb_hex2(value, width).
pub(crate) fn emit_hex2(args: &[IrExpr], out: &mut String, emit_fn: impl Fn(&IrExpr, &mut String)) {
    out.push_str("xb_hex2(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    emit_fn(&args[1], out);
    out.push(')');
}

/// Emits C code for STUFF$(into$, from$, start[, length]).
pub(crate) fn emit_stuff(
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) {
    out.push_str("xb_stuff(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    emit_fn(&args[1], out);
    out.push_str(", ");
    emit_fn(&args[2], out);
    out.push_str(", ");
    if args.len() == 4 {
        emit_fn(&args[3], out);
    } else {
        out.push_str("-1");
    }
    out.push(')');
}

/// Emits C code for RCLIP$/LCLIP$(s$[, n]). 1-arg → trim, 2-arg → remove N chars.
pub(crate) fn emit_clip(
    name: &str,
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) {
    let func = if args.len() == 2 {
        if name == "RCLIP$" {
            "xb_rclip2"
        } else {
            "xb_lclip2"
        }
    } else {
        if name == "RCLIP$" {
            "xb_rclip1"
        } else {
            "xb_lclip1"
        }
    };
    out.push_str(func);
    out.push('(');
    emit_fn(&args[0], out);
    if args.len() == 2 {
        out.push_str(", ");
        emit_fn(&args[1], out);
    }
    out.push(')');
}

/// Emits C code for 2-arg MID$(s$, start) → xb_mid2(s, start).
pub(crate) fn emit_mid2(args: &[IrExpr], out: &mut String, emit_fn: impl Fn(&IrExpr, &mut String)) {
    out.push_str("xb_mid2(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    emit_fn(&args[1], out);
    out.push(')');
}

/// Returns true if `name` is a type-conversion builtin handled by this module.
pub(crate) fn is_type_conversion(name: &str) -> bool {
    matches!(name, "DOUBLE" | "SINGLE" | "XLONG")
}

/// Emits C code for DOUBLE/SINGLE/XLONG type conversions.
/// Caller must ensure `is_type_conversion(name)` is true.
pub(crate) fn emit_type_conversion(
    name: &str,
    arg: &IrExpr,
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) {
    let prefix = match (name, arg.value_type) {
        ("XLONG", ValueType::String) => "atoi(",
        ("XLONG", ValueType::Float) => "(int)(",
        ("DOUBLE" | "SINGLE", ValueType::String) => "atof(",
        ("DOUBLE" | "SINGLE", ValueType::Integer) => "(double)(",
        _ => "(",
    };
    out.push_str(prefix);
    emit_fn(arg, out);
    out.push(')');
}

/// Emits a fallback `return` of the return variable at the end of a C function body.
pub(crate) fn emit_fallback_return(name: &str, return_type: ValueType, out: &mut String) {
    let ret_name = name.trim_end_matches('$');
    out.push_str("    return ");
    if return_type == ValueType::String {
        out.push_str("xb_str_");
    } else {
        out.push_str("xb_var_");
    }
    out.push_str(ret_name);
    out.push_str(";\n");
}
