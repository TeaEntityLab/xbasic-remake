use crate::builtin::type_err;
use crate::interpreter::{RuntimeError, RuntimeValue};

pub(crate) fn eval_atan2(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(a) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Float(b) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    Ok(RuntimeValue::Float(a.atan2(*b)))
}

pub(crate) fn eval_power(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(a) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Float(b) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    Ok(RuntimeValue::Float(a.powf(*b)))
}

pub(crate) fn eval_rinstr(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(hay) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::String(needle) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let end = if args.len() == 3 {
        let RuntimeValue::Integer(s) = &args[2] else {
            return Err(type_err(args[2].value_type()));
        };
        (*s as usize).min(hay.len())
    } else {
        hay.len()
    };
    if needle.is_empty() {
        return Ok(RuntimeValue::Integer(0));
    }
    Ok(RuntimeValue::Integer(
        hay[..end]
            .rfind(needle.as_str())
            .map(|i| (i + 1) as i32)
            .unwrap_or(0),
    ))
}

pub(crate) fn eval_reciprocal(
    name: &str,
    args: &[RuntimeValue],
) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let v = *v;
    let r = match name {
        "EXP2" => (2.0f64).powf(v),
        "COT" => 1.0 / v.tan(),
        "SEC" => 1.0 / v.cos(),
        "CSC" => 1.0 / v.sin(),
        "SECH" => 1.0 / v.cosh(),
        "CSCH" => 1.0 / v.sinh(),
        "COTH" => 1.0 / v.tanh(),
        "ACOT" => {
            if v > 1.0 {
                (1.0 / v).atan()
            } else {
                std::f64::consts::FRAC_PI_2 - v.atan()
            }
        }
        "ASEC" => std::f64::consts::FRAC_PI_2 - (1.0 / v).asin(),
        "ACSC" => (1.0 / v).asin(),
        "ACOTH" => (1.0 / v).atanh(),
        "ASECH" => (1.0 / v).acosh(),
        "ACSCH" => (1.0 / v).asinh(),
        _ => {
            return Err(RuntimeError::UnknownFunction {
                name: name.to_owned(),
            })
        }
    };
    Ok(RuntimeValue::Float(r))
}

pub(crate) fn eval_instri(name: &str, args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(hay) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::String(needle) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    if needle.is_empty() {
        return Ok(RuntimeValue::Integer(0));
    }
    let needle_lower = needle.to_lowercase();
    let pos = if name == "RINSTRI" {
        let end = if args.len() == 3 {
            let RuntimeValue::Integer(s) = &args[2] else {
                return Err(type_err(args[2].value_type()));
            };
            (*s as usize).min(hay.len())
        } else {
            hay.len()
        };
        hay[..end]
            .to_lowercase()
            .rfind(needle_lower.as_str())
            .map(|i| (i + 1) as i32)
            .unwrap_or(0)
    } else {
        let start = if args.len() == 3 {
            let RuntimeValue::Integer(s) = &args[2] else {
                return Err(type_err(args[2].value_type()));
            };
            *s as usize
        } else {
            0
        };
        hay.to_lowercase()[start..]
            .find(needle_lower.as_str())
            .map(|i| (i + start + 1) as i32)
            .unwrap_or(0)
    };
    Ok(RuntimeValue::Integer(pos))
}

pub(crate) fn eval_abs(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    match &args[0] {
        RuntimeValue::Integer(n) => Ok(RuntimeValue::Integer(n.wrapping_abs())),
        RuntimeValue::Float(n) => Ok(RuntimeValue::Float(n.abs())),
        _ => Err(type_err(args[0].value_type())),
    }
}

pub(crate) fn eval_to_float(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    match &args[0] {
        RuntimeValue::Integer(n) => Ok(RuntimeValue::Float(*n as f64)),
        RuntimeValue::Float(n) => Ok(RuntimeValue::Float(*n)),
        RuntimeValue::String(s) => Ok(RuntimeValue::Float(s.parse().unwrap_or(0.0))),
    }
}

pub(crate) fn eval_to_int(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    match &args[0] {
        RuntimeValue::Integer(n) => Ok(RuntimeValue::Integer(*n)),
        RuntimeValue::Float(n) => Ok(RuntimeValue::Integer(*n as i32)),
        RuntimeValue::String(s) => Ok(RuntimeValue::Integer(s.parse().unwrap_or(0))),
    }
}

pub(crate) fn eval_hexx(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let hex = format!("{:X}", *n);
    if args.len() == 2 {
        let RuntimeValue::Integer(w) = &args[1] else {
            return Err(type_err(args[1].value_type()));
        };
        let padded = format!("{:0>width$}", hex, width = *w as usize);
        Ok(RuntimeValue::String(padded))
    } else {
        Ok(RuntimeValue::String(hex))
    }
}

pub(crate) fn eval_just(name: &str, args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(w) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let width = *w as usize;
    let result = if name == "RJUST$" {
        if s.len() >= width {
            s.clone()
        } else {
            format!("{:>width$}", s, width = width)
        }
    } else {
        if s.len() >= width {
            s.clone()
        } else {
            format!("{:<width$}", s, width = width)
        }
    };
    Ok(RuntimeValue::String(result))
}
