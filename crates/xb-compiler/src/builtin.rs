use crate::checked::{CheckedExpr, CheckedExprKind, ValueType};
use crate::semantics::{ExprResult, SemanticError};
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
        "ATN" => (&[ValueType::Float][..], ValueType::Float),
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
        "HEX$" => (&[ValueType::Integer][..], ValueType::String),
        "BIN$" => (&[ValueType::Integer][..], ValueType::String),
        "OCT$" => (&[ValueType::Integer][..], ValueType::String),
        "HEXX$" => (&[ValueType::Integer][..], ValueType::String),
        "RJUST$" => (
            &[ValueType::String, ValueType::Integer][..],
            ValueType::String,
        ),
        "LJUST$" => (
            &[ValueType::String, ValueType::Integer][..],
            ValueType::String,
        ),
        "RCLIP$" => (&[ValueType::String][..], ValueType::String),
        "LCLIP$" => (&[ValueType::String][..], ValueType::String),
        "INCHR" => (
            &[ValueType::String, ValueType::String, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "RINCHR" => (
            &[ValueType::String, ValueType::String, ValueType::Integer][..],
            ValueType::Integer,
        ),
        "STUFF$" => (
            &[ValueType::String, ValueType::String, ValueType::Integer][..],
            ValueType::String,
        ),
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
        "INSTR" if args.len() == 3 => 3,
        "RINSTR" if args.len() == 3 => 3,
        "INSTRI" if args.len() == 3 => 3,
        "RINSTRI" if args.len() == 3 => 3,
        "HEX$" if args.len() == 2 => 2,
        "HEXX$" if args.len() == 2 => 2,
        "RCLIP$" if args.len() == 2 => 2,
        "LCLIP$" if args.len() == 2 => 2,
        "STUFF$" if args.len() == 4 => 4,
        "MID$" if args.len() == 2 => 2,
        _ => s.params.len(),
    };
    if args.len() != expected_args {
        return Err(SemanticError::FunctionArgCount {
            name: name.to_owned(),
            expected: s.params.len(),
            actual: args.len(),
        });
    }
    let instr3 = matches!(name, "INSTR" | "RINSTR" | "INSTRI" | "RINSTRI") && args.len() == 3;
    let mut checked = Vec::with_capacity(args.len());
    for (i, arg) in args.iter().enumerate() {
        let v = analyzer.expr(arg)?;
        let expected = if instr3 && i == 2 {
            ValueType::Integer
        } else if i < s.params.len() {
            s.params[i]
        } else {
            ValueType::Integer
        };
        if v.value_type != expected {
            return Err(SemanticError::FunctionArgType {
                name: name.to_owned(),
                index: i,
                expected,
                actual: v.value_type,
            });
        }
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
