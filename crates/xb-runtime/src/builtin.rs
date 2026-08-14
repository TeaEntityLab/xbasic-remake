use crate::interpreter::{RuntimeError, RuntimeValue};

pub(crate) fn eval_builtin(
    name: &str,
    args: &[RuntimeValue],
) -> Result<RuntimeValue, RuntimeError> {
    match name {
        "LEN" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::Integer(s.len() as i32))
        }
        "ASC" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            if s.is_empty() {
                return Err(RuntimeError::InvalidLiteral {
                    literal: "empty string".into(),
                    value_type: xb_compiler::ValueType::Integer,
                });
            }
            Ok(RuntimeValue::Integer(s.as_bytes()[0] as i32))
        }
        "CHR$" => {
            let RuntimeValue::Integer(n) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(
                char::from_u32(*n as u32)
                    .map(|c| c.to_string())
                    .unwrap_or_default(),
            ))
        }
        "LEFT$" => string_slice(args, |s, n| s.chars().take(n).collect()),
        "RIGHT$" => string_slice(args, |s, n| {
            let chars: Vec<char> = s.chars().collect();
            let start = chars.len().saturating_sub(n);
            chars[start..].iter().collect()
        }),
        "MID$" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            let RuntimeValue::Integer(start) = &args[1] else {
                return Err(type_err(args[1].value_type()));
            };
            let RuntimeValue::Integer(len) = &args[2] else {
                return Err(type_err(args[2].value_type()));
            };
            let chars: Vec<char> = s.chars().collect();
            let start_idx = (*start as usize).saturating_sub(1).min(chars.len());
            let end_idx = (start_idx + *len as usize).min(chars.len());
            Ok(RuntimeValue::String(
                chars[start_idx..end_idx].iter().collect(),
            ))
        }
        _ => Err(RuntimeError::UnknownFunction {
            name: name.to_owned(),
        }),
    }
}

fn string_slice(
    args: &[RuntimeValue],
    f: impl Fn(&str, usize) -> String,
) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(n) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    Ok(RuntimeValue::String(f(s, *n as usize)))
}

fn type_err(actual: xb_compiler::ValueType) -> RuntimeError {
    RuntimeError::TypeMismatch {
        expected: xb_compiler::ValueType::String,
        actual,
    }
}
