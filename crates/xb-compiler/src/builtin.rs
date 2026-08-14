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

pub fn builtin_call(
    analyzer: &crate::semantics::Analyzer,
    name: &str,
    args: &[Expression],
    rt: ValueType,
) -> ExprResult {
    let s = sig(name).unwrap();
    if args.len() != s.params.len() {
        return Err(SemanticError::FunctionArgCount {
            name: name.to_owned(),
            expected: s.params.len(),
            actual: args.len(),
        });
    }
    let mut checked = Vec::with_capacity(args.len());
    for (i, arg) in args.iter().enumerate() {
        let v = analyzer.expr(arg)?;
        if v.value_type != s.params[i] {
            return Err(SemanticError::FunctionArgType {
                name: name.to_owned(),
                index: i,
                expected: s.params[i],
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
