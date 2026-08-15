use crate::checked::{ArithmeticOp, ComparisonOp};
use crate::ir::IrExpr;
use crate::ValueType;

pub(crate) fn extract_parens(s: &str) -> Result<(&str, &str), String> {
    let bytes = s.as_bytes();
    let mut depth = 1;
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'(' => depth += 1,
            b')' => {
                depth -= 1;
                if depth == 0 {
                    return Ok((&s[..i], &s[i + 1..]));
                }
            }
            b'"' => {
                i += 1;
                while i < bytes.len() && bytes[i] != b'"' {
                    if bytes[i] == b'\\' {
                        i += 1;
                    }
                    i += 1;
                }
            }
            _ => {}
        }
        i += 1;
    }
    Err("unbalanced parens".into())
}

pub(crate) fn parse_symbol(s: &str) -> Result<(String, ValueType), String> {
    let colon = s
        .find(':')
        .ok_or_else(|| format!("missing : in symbol: {s}"))?;
    let name = s[..colon].to_string();
    let vt = parse_type(s[colon + 1..].trim())?;
    Ok((name, vt))
}

pub(crate) fn parse_type(s: &str) -> Result<ValueType, String> {
    match s {
        "integer" => Ok(ValueType::Integer),
        "float" => Ok(ValueType::Float),
        "string" => Ok(ValueType::String),
        _ => Err(format!("unknown type: {s}")),
    }
}

pub(crate) fn parse_cmp_op(s: &str) -> Result<(ComparisonOp, &str), String> {
    if let Some(r) = s.strip_prefix("<>") {
        return Ok((ComparisonOp::NotEqual, r));
    }
    if let Some(r) = s.strip_prefix("<=") {
        return Ok((ComparisonOp::LessEqual, r));
    }
    if let Some(r) = s.strip_prefix(">=") {
        return Ok((ComparisonOp::GreaterEqual, r));
    }
    if let Some(r) = s.strip_prefix('=') {
        return Ok((ComparisonOp::Equal, r));
    }
    if let Some(r) = s.strip_prefix('<') {
        return Ok((ComparisonOp::Less, r));
    }
    if let Some(r) = s.strip_prefix('>') {
        return Ok((ComparisonOp::Greater, r));
    }
    Err(format!("expected comparison op, got: {s}"))
}

pub(crate) fn parse_arith_op(s: &str) -> Result<(ArithmeticOp, &str), String> {
    if let Some(r) = s.strip_prefix("** ") {
        return Ok((ArithmeticOp::Pow, r));
    }
    if let Some(r) = s.strip_prefix('+') {
        return Ok((ArithmeticOp::Add, r));
    }
    if let Some(r) = s.strip_prefix('-') {
        return Ok((ArithmeticOp::Sub, r));
    }
    if let Some(r) = s.strip_prefix('*') {
        return Ok((ArithmeticOp::Mul, r));
    }
    if let Some(r) = s.strip_prefix('/') {
        return Ok((ArithmeticOp::Div, r));
    }
    if let Some(r) = s.strip_prefix("\\ ") {
        return Ok((ArithmeticOp::IntegerDiv, r));
    }
    if let Some(r) = s.strip_prefix("mod ") {
        return Ok((ArithmeticOp::Mod, r));
    }
    if let Some(r) = s.strip_prefix("shl ") {
        return Ok((ArithmeticOp::Shl, r));
    }
    if let Some(r) = s.strip_prefix("shr ") {
        return Ok((ArithmeticOp::Shr, r));
    }
    Err(format!("expected arith op, got: {s}"))
}

pub(crate) fn parse_rust_string(s: &str) -> Result<String, String> {
    let s = s.trim();
    if !s.starts_with('"') || !s.ends_with('"') {
        return Err(format!("not a quoted string: {s}"));
    }
    let inner = &s[1..s.len() - 1];
    let mut result = String::new();
    let mut chars = inner.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\\' {
            match chars.next() {
                Some('n') => result.push('\n'),
                Some('t') => result.push('\t'),
                Some('r') => result.push('\r'),
                Some('\\') => result.push('\\'),
                Some('"') => result.push('"'),
                Some('0') => result.push('\0'),
                Some(c) => result.push(c),
                None => return Err("unterminated escape".into()),
            }
        } else {
            result.push(c);
        }
    }
    Ok(result)
}

pub(crate) fn infer_arith_type(op: ArithmeticOp, left: &IrExpr, right: &IrExpr) -> ValueType {
    if op == ArithmeticOp::Add
        && (left.value_type == ValueType::String || right.value_type == ValueType::String)
    {
        ValueType::String
    } else if op == ArithmeticOp::IntegerDiv || op == ArithmeticOp::Mod {
        ValueType::Integer
    } else if left.value_type == ValueType::Float || right.value_type == ValueType::Float {
        ValueType::Float
    } else {
        ValueType::Integer
    }
}

pub(crate) fn parse_symbol_decl(s: &str) -> Result<crate::ir::IrSymbol, String> {
    let colon = s
        .find(':')
        .ok_or_else(|| format!("missing : in symbol: {s}"))?;
    let name = s[..colon].to_string();
    let vt = parse_type(s[colon + 1..].trim())?;
    Ok(crate::ir::IrSymbol {
        name,
        value_type: vt,
    })
}

pub(crate) fn parse_params(s: &str) -> Result<Vec<crate::ir::IrParam>, String> {
    let s = s.trim();
    if s.is_empty() {
        return Ok(Vec::new());
    }
    s.split(',')
        .map(|p| {
            let p = p.trim();
            let colon = p
                .find(':')
                .ok_or_else(|| format!("missing : in param: {p}"))?;
            let name = p[..colon].to_string();
            let vt = parse_type(p[colon + 1..].trim())?;
            Ok(crate::ir::IrParam {
                name,
                value_type: vt,
            })
        })
        .collect()
}
