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
        "BINB$" => out.push_str("xb_binb"),
        "OCT$" => out.push_str("xb_oct"),
        "OCTO$" => out.push_str("xb_octo"),
        "STRING$" | "STRING" => out.push_str("xb_string"),
        "SQRT" => out.push_str("xb_sqrt"),
        "SIN" => out.push_str("xb_sin"),
        "COS" => out.push_str("xb_cos"),
        "TAN" => out.push_str("xb_tan"),
        "EXP" => out.push_str("xb_exp"),
        "LOG" => out.push_str("xb_log"),
        "ACOS" => out.push_str("xb_acos"),
        "ASIN" => out.push_str("xb_asin"),
        "ATN" | "ATAN" => out.push_str("xb_atan"),
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
        "LJUST$" => out.push_str("xb_ljust"),
        "CJUST$" => out.push_str("xb_cjust"),
        "RJUST$" => out.push_str("xb_rjust"),
        "INCHR" => out.push_str("xb_inchr"),
        "RINCHR" => out.push_str("xb_rinchr"),
        "INCHRI" => out.push_str("xb_inchri"),
        "RINCHRI" => out.push_str("xb_rinchri"),
        "STUFF$" => out.push_str("xb_stuff"),
        "EOF" => out.push_str("xb_eof"),
        "VERSION$" => out.push_str("xb_version"),
        "SIGNED$" => out.push_str("xb_signed"),
        "NULL$" => out.push_str("xb_null"),
        "ROTATEL" => out.push_str("xb_rotatel"),
        "ROTATER" => out.push_str("xb_rotater"),
        "DHIGH" => out.push_str("xb_dhigh"),
        "DLOW" => out.push_str("xb_dlow"),
        "DMAKE" => out.push_str("xb_dmake"),
        "GMAKE" => out.push_str("xb_gmake"),
        "SMAKE" => out.push_str("xb_smake"),
        "ERROR$" => out.push_str("xb_error_str"),
        "QUIT" => out.push_str("xb_quit"),
        "ERROR" => out.push_str("xb_error"),
        "BITFIELD" => out.push_str("xb_bitfield"),
        "EXTS" => out.push_str("xb_exts"),
        "EXTU" => out.push_str("xb_extu"),
        "CLR" => out.push_str("xb_clr"),
        "SET" => out.push_str("xb_set"),
        "MAKE" => out.push_str("xb_make"),
        "HIGH0" => out.push_str("xb_high0"),
        "HIGH1" => out.push_str("xb_high1"),
        "GHIGH" => out.push_str("xb_ghigh"),
        "GLOW" => out.push_str("xb_glow"),
        "SIGN" => out.push_str("xb_sign"),
        "XMAKE" => out.push_str("xb_xmake"),
        "FORMAT$" => out.push_str("xb_format"),
        "SHELL" => out.push_str("xb_shell"),
        "LIBRARY" => out.push_str("xb_library"),
        "CSIZE" => out.push_str("xb_csize"),
        "CSIZE$" => out.push_str("xb_csize_str"),
        "PROGRAM$" => out.push_str("xb_program_name"),
        "OPEN" => out.push_str("xb_open"),
        "CLOSE" => out.push_str("xb_close"),
        "LOF" => out.push_str("xb_lof"),
        "POF" => out.push_str("xb_pof"),
        "SEEK" => out.push_str("xb_seek"),
        "INFILE$" => out.push_str("xb_infile"),
        "ISDATA" => out.push_str("xb_isdata"),
        "INKEY$" => out.push_str("xb_inkey"),
        "WAITKEY" => out.push_str("xb_waitkey"),
        "ISNODE" => out.push_str("xb_isnode"),
        "GOADDR" => out.push_str("xb_goaddr"),
        "SUBADDR" => out.push_str("xb_subaddr"),
        "CSTRING$" => out.push_str("xb_cstring"),
        "FUNCADDRESS" => out.push_str("xb_funcaddress"),
        "SBYTEAT" => out.push_str("xb_sbyteat"),
        "UBYTEAT" => out.push_str("xb_ubyteat"),
        "SSHORTAT" => out.push_str("xb_sshortat"),
        "USHORTAT" => out.push_str("xb_ushortat"),
        "SLONGAT" => out.push_str("xb_slongat"),
        "ULONGAT" => out.push_str("xb_ulongat"),
        "XLONGAT" => out.push_str("xb_xlongat"),
        "GIANTAT" => out.push_str("xb_giantat"),
        "SINGLEAT" => out.push_str("xb_singleat"),
        "DOUBLEAT" => out.push_str("xb_doubleat"),
        "SUBADDRAT" => out.push_str("xb_subaddrat"),
        "GOADDRAT" => out.push_str("xb_goaddrat"),
        _ => {
            out.push_str("xb_user_");
            out.push_str(name);
        }
    }
}

/// Returns true if `name` is a type-conversion builtin handled by this module.
pub(crate) fn is_type_conversion(name: &str) -> bool {
    matches!(
        name,
        "DOUBLE"
            | "SINGLE"
            | "XLONG"
            | "SBYTE"
            | "UBYTE"
            | "SSHORT"
            | "USHORT"
            | "SLONG"
            | "ULONG"
            | "GIANT"
    )
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
        (
            "XLONG" | "SBYTE" | "UBYTE" | "SSHORT" | "USHORT" | "SLONG" | "ULONG" | "GIANT",
            ValueType::String,
        ) => "atoi(",
        (
            "XLONG" | "SBYTE" | "UBYTE" | "SSHORT" | "USHORT" | "SLONG" | "ULONG" | "GIANT",
            ValueType::Float,
        ) => "(int)(",
        ("DOUBLE" | "SINGLE", ValueType::String) => "atof(",
        ("DOUBLE" | "SINGLE", ValueType::Integer) => "(double)(",
        _ => "(",
    };
    out.push_str(prefix);
    emit_fn(arg, out);
    out.push(')');
}
