use crate::checked::{CheckedExpr, CheckedExprKind, ValueType};
use crate::semantics::ExprResult;
use xb_frontend::Expression;

struct BuiltinSig {
    params: &'static [ValueType],
    return_type: ValueType,
}

fn sig(name: &str) -> Option<BuiltinSig> {
    let (params, rt) = match name {
        "LEN" => (&[ValueType::String][..], ValueType::Integer),
        "ASC" => (&[ValueType::String][..], ValueType::Integer),
        "CHR$" => (&[ValueType::Integer][..], ValueType::String),
        "LEFT$" => (
            &[ValueType::String, ValueType::Integer][..],
            ValueType::String,
        ),
        "RIGHT$" => (
            &[ValueType::String, ValueType::Integer][..],
            ValueType::String,
        ),
        "MID$" => (
            &[ValueType::String, ValueType::Integer, ValueType::Integer][..],
            ValueType::String,
        ),
        "INSTR" => (
            &[ValueType::String, ValueType::String][..],
            ValueType::Integer,
        ),
        "RINSTR" => (
            &[ValueType::String, ValueType::String][..],
            ValueType::Integer,
        ),
        "INSTRI" => (
            &[ValueType::String, ValueType::String][..],
            ValueType::Integer,
        ),
        "RINSTRI" => (
            &[ValueType::String, ValueType::String][..],
            ValueType::Integer,
        ),
        "VAL" => (&[ValueType::String][..], ValueType::Integer),
        "STR$" => (&[ValueType::Integer][..], ValueType::String),
        "STRING$" => (&[ValueType::Integer][..], ValueType::String),
        "STRING" => (&[ValueType::Integer][..], ValueType::String),
        "SIGNED$" => (&[ValueType::Integer][..], ValueType::String),
        "NULL$" => (&[ValueType::Integer][..], ValueType::String),
        "SQRT" => (&[ValueType::Float][..], ValueType::Float),
        "SIN" => (&[ValueType::Float][..], ValueType::Float),
        "COS" => (&[ValueType::Float][..], ValueType::Float),
        "TAN" => (&[ValueType::Float][..], ValueType::Float),
        "EXP" => (&[ValueType::Float][..], ValueType::Float),
        "LOG" => (&[ValueType::Float][..], ValueType::Float),
        "ATN" | "ATAN" => (&[ValueType::Float][..], ValueType::Float),
        "ACOS" => (&[ValueType::Float][..], ValueType::Float),
        "ASIN" => (&[ValueType::Float][..], ValueType::Float),
        "ATAN2" => (&[ValueType::Float, ValueType::Float][..], ValueType::Float),
        "LOG10" => (&[ValueType::Float][..], ValueType::Float),
        "POWER" => (&[ValueType::Float, ValueType::Float][..], ValueType::Float),
        "SINH" => (&[ValueType::Float][..], ValueType::Float),
        "COSH" => (&[ValueType::Float][..], ValueType::Float),
        "TANH" => (&[ValueType::Float][..], ValueType::Float),
        "ASINH" => (&[ValueType::Float][..], ValueType::Float),
        "ACOSH" => (&[ValueType::Float][..], ValueType::Float),
        "ATANH" => (&[ValueType::Float][..], ValueType::Float),
        "EXP10" => (&[ValueType::Float][..], ValueType::Float),
        "EXP2" => (&[ValueType::Float][..], ValueType::Float),
        "COT" => (&[ValueType::Float][..], ValueType::Float),
        "SEC" => (&[ValueType::Float][..], ValueType::Float),
        "CSC" => (&[ValueType::Float][..], ValueType::Float),
        "COTH" => (&[ValueType::Float][..], ValueType::Float),
        "SECH" => (&[ValueType::Float][..], ValueType::Float),
        "CSCH" => (&[ValueType::Float][..], ValueType::Float),
        "ACOT" => (&[ValueType::Float][..], ValueType::Float),
        "ASEC" => (&[ValueType::Float][..], ValueType::Float),
        "ACSC" => (&[ValueType::Float][..], ValueType::Float),
        "ACOTH" => (&[ValueType::Float][..], ValueType::Float),
        "ASECH" => (&[ValueType::Float][..], ValueType::Float),
        "ACSCH" => (&[ValueType::Float][..], ValueType::Float),
        "INLINE$" => (&[ValueType::String][..], ValueType::String),
        "UCASE$" => (&[ValueType::String][..], ValueType::String),
        "LCASE$" => (&[ValueType::String][..], ValueType::String),
        "TRIM$" => (&[ValueType::String][..], ValueType::String),
        "LTRIM$" => (&[ValueType::String][..], ValueType::String),
        "RTRIM$" => (&[ValueType::String][..], ValueType::String),
        "SPACE$" => (&[ValueType::Integer][..], ValueType::String),
        "ABS" => (&[ValueType::Integer][..], ValueType::Integer),
        "SGN" => (&[ValueType::Integer][..], ValueType::Integer),
        "INT" => (&[ValueType::Float][..], ValueType::Integer),
        "FIX" => (&[ValueType::Float][..], ValueType::Integer),
        "MAX" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "MIN" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "ROTATEL" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "ROTATER" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "DHIGH" => (&[ValueType::Float][..], ValueType::Integer),
        "DLOW" => (&[ValueType::Float][..], ValueType::Integer),
        "DMAKE" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Float,
        ),
        "GMAKE" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Giant,
        ),
        "SMAKE" => (&[ValueType::Integer][..], ValueType::Float),
        "XMAKE" => (&[ValueType::Float][..], ValueType::Integer),
        "ERROR" => (&[ValueType::Integer][..], ValueType::Integer),
        "ERROR$" => (&[ValueType::Integer][..], ValueType::String),
        "BITFIELD" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "EXTS" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "EXTU" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "CLR" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "SET" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "MAKE" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "HIGH0" => (&[ValueType::Integer][..], ValueType::Integer),
        "HIGH1" => (&[ValueType::Integer][..], ValueType::Integer),
        "GHIGH" => (&[ValueType::Giant][..], ValueType::Integer),
        "GLOW" => (&[ValueType::Giant][..], ValueType::Integer),
        "SIGN" => (&[ValueType::Float][..], ValueType::Integer),
        "CJUST$" | "RJUST$" | "LJUST$" => (
            &[ValueType::String, ValueType::Integer][..],
            ValueType::String,
        ),
        "OCTO$" | "BINB$" | "HEX$" | "BIN$" | "OCT$" | "HEXX$" => {
            (&[ValueType::Integer][..], ValueType::String)
        }
        "QUIT" => (&[ValueType::Integer][..], ValueType::Integer),
        "INCHR" | "RINCHR" | "INCHRI" | "RINCHRI" => (
            &[ValueType::String, ValueType::String][..],
            ValueType::Integer,
        ),
        "STUFF$" => (
            &[ValueType::String, ValueType::String, ValueType::Integer][..],
            ValueType::String,
        ),
        "RCLIP$" | "LCLIP$" => (&[ValueType::String][..], ValueType::String),
        "FORMAT$" => (
            &[ValueType::String, ValueType::String][..],
            ValueType::String,
        ),
        "SHELL" => (&[ValueType::String][..], ValueType::Integer),
        "LIBRARY" => (&[ValueType::Integer][..], ValueType::Integer),
        "READLINE$" => (&[][..], ValueType::String),
        "EOF" => (&[][..], ValueType::Integer),
        "RND" => (&[][..], ValueType::Float),
        "CEIL" => (&[ValueType::Float][..], ValueType::Float),
        "FLOOR" => (&[ValueType::Float][..], ValueType::Float),
        "ROUND" => (&[ValueType::Float][..], ValueType::Float),
        "TIMER" => (&[][..], ValueType::Float),
        "TIME$" => (&[][..], ValueType::String),
        "DATE$" => (&[][..], ValueType::String),
        "VERSION$" => (&[ValueType::Integer][..], ValueType::String),
        "CSIZE" => (&[ValueType::String][..], ValueType::Integer),
        "CSIZE$" => (&[ValueType::String][..], ValueType::String),
        "PROGRAM$" => (&[ValueType::Integer][..], ValueType::String),
        "UBOUND" => (&[ValueType::Integer][..], ValueType::Integer),
        "OPEN" => (
            &[ValueType::String, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "CLOSE" => (&[ValueType::Integer][..], ValueType::Integer),
        "LOF" => (&[ValueType::Integer][..], ValueType::Integer),
        "POF" => (&[ValueType::Integer][..], ValueType::Integer),
        "SEEK" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "INFILE$" => (&[ValueType::Integer][..], ValueType::String),
        "SIZE" => (&[ValueType::Integer][..], ValueType::Integer),
        "TAB" => (&[ValueType::Integer][..], ValueType::String),
        "ISDATA" => (&[ValueType::String][..], ValueType::Integer),
        "INKEY$" => (&[][..], ValueType::String),
        "WAITKEY" => (&[][..], ValueType::Integer),
        "ISNODE" => (&[ValueType::String][..], ValueType::Integer),
        "SUBADDRESS" => (&[ValueType::Integer][..], ValueType::Integer),
        "GOADDRESS" => (&[ValueType::Integer][..], ValueType::Integer),
        "GOADDR" => (&[ValueType::Integer][..], ValueType::Integer),
        "SUBADDR" => (&[ValueType::Integer][..], ValueType::Integer),
        "CSTRING$" => (&[ValueType::Integer][..], ValueType::String),
        "FUNCADDRESS" => (&[ValueType::Integer][..], ValueType::Integer),
        "SBYTEAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "UBYTEAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "SSHORTAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "USHORTAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "SLONGAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "ULONGAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "XLONGAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "GIANTAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Giant,
        ),
        "SINGLEAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Float,
        ),
        "DOUBLEAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Float,
        ),
        "SUBADDRAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "GOADDRAT" => (
            &[ValueType::Integer, ValueType::Integer][..],
            ValueType::Integer,
        ),
        _ => return None,
    };
    Some(BuiltinSig {
        params,
        return_type: rt,
    })
}

pub fn builtin_return_type(name: &str) -> Option<ValueType> {
    sig(name).map(|s| s.return_type)
}

/// Declared parameter types of a fixed-signature builtin (`None` for variadic /
/// unknown builtins). Lets callers coerce arguments to the builtin's contract —
/// e.g. the interpreter narrows a Giant argument to an Integer parameter, matching
/// the C backends, instead of erroring.
pub fn builtin_param_types(name: &str) -> Option<&'static [ValueType]> {
    sig(name).map(|s| s.params)
}

pub fn is_zero_arg_builtin(name: &str) -> bool {
    sig(name).is_some_and(|s| s.params.is_empty())
}

pub fn builtin_call(
    analyzer: &crate::semantics::Analyzer,
    name: &str,
    args: &[Expression],
    rt: ValueType,
) -> ExprResult {
    let s = sig(name).unwrap();
    let expected_args: usize = match name {
        "CHR$" if args.len() == 2 => 2,
        "INSTR" | "RINSTR" | "INSTRI" | "RINSTRI" if args.len() == 3 => 3,
        "INCHR" | "RINCHR" | "INCHRI" | "RINCHRI" if args.len() == 3 => 3,
        "HEX$" | "HEXX$" | "OCTO$" | "BINB$" | "BIN$" | "OCT$" if args.len() == 2 => 2,
        "RCLIP$" | "LCLIP$" if args.len() == 2 => 2,
        "STUFF$" if args.len() == 4 => 4,
        "MID$" if args.len() == 2 => 2,
        "EXTS" | "EXTU" | "CLR" | "SET" | "MAKE" if args.len() == 3 => 3,
        _ => s.params.len(),
    };
    // Relaxed: allow variable arg counts
    let _ = expected_args;
    let instr3 = matches!(
        name,
        "INSTR" | "RINSTR" | "INSTRI" | "RINSTRI" | "INCHR" | "RINCHR" | "INCHRI" | "RINCHRI"
    ) && args.len() == 3;
    let mut checked = Vec::with_capacity(args.len());
    for (i, arg) in args.iter().enumerate() {
        let v = analyzer.expr(arg)?;
        let expected = if instr3 && i == 2 {
            ValueType::Integer
        } else if name == "FORMAT$" && i == 1 {
            v.value_type
        } else if i < s.params.len() {
            s.params[i]
        } else {
            ValueType::Integer
        };
        // Relaxed: allow any type for function args (XBasic implicit coercion)
        let v = if v.value_type != expected {
            CheckedExpr::new(v.kind.clone(), expected)
        } else {
            v
        };
        checked.push(v);
    }
    Ok(CheckedExpr::new(
        CheckedExprKind::FunctionCall {
            name: name.to_owned(),
            args: checked,
        },
        rt,
    ))
}
