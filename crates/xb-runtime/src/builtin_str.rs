use crate::builtin::type_err;
use crate::interpreter::{RuntimeError, RuntimeValue};

pub(crate) fn eval_mid(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(start) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let bytes = s.as_bytes();
    let start_idx = (*start as usize).saturating_sub(1).min(bytes.len());
    let end_idx = if args.len() == 3 {
        let RuntimeValue::Integer(len) = &args[2] else {
            return Err(type_err(args[2].value_type()));
        };
        (start_idx + *len as usize).min(bytes.len())
    } else {
        bytes.len()
    };
    Ok(RuntimeValue::String(
        String::from_utf8_lossy(&bytes[start_idx..end_idx]).into_owned(),
    ))
}

pub(crate) fn eval_hexx(name: &str, args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let prefix = if name == "HEXX$" { "0x" } else { "" };
    let hex = format!("{prefix}{:X}", *n);
    if args.len() == 2 {
        let RuntimeValue::Integer(w) = &args[1] else {
            return Err(type_err(args[1].value_type()));
        };
        let padded = format!(
            "{prefix}{:0>width$}",
            format!("{:X}", *n),
            width = *w as usize
        );
        Ok(RuntimeValue::String(padded))
    } else {
        Ok(RuntimeValue::String(hex))
    }
}

pub(crate) fn eval_str_op(name: &str, args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    match name {
        "RJUST$" | "LJUST$" | "CJUST$" => eval_just(name, args),
        "RCLIP$" => eval_rclip(args),
        "LCLIP$" => eval_lclip(args),
        _ => unreachable!("eval_str_op: {name}"),
    }
}

fn eval_just(name: &str, args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
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
    } else if name == "CJUST$" {
        if s.len() >= width {
            s[..width].to_string()
        } else {
            let total = width - s.len();
            let left = total / 2;
            let right = total - left;
            format!("{}{}{}", " ".repeat(left), s, " ".repeat(right))
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

fn eval_rclip(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    if args.len() == 2 {
        let RuntimeValue::Integer(n) = &args[1] else {
            return Err(type_err(args[1].value_type()));
        };
        let end = s.len().saturating_sub(*n as usize);
        Ok(RuntimeValue::String(s[..end].to_string()))
    } else {
        Ok(RuntimeValue::String(s.trim_end().to_string()))
    }
}

fn eval_lclip(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    if args.len() == 2 {
        let RuntimeValue::Integer(n) = &args[1] else {
            return Err(type_err(args[1].value_type()));
        };
        let start = (*n as usize).min(s.len());
        Ok(RuntimeValue::String(s[start..].to_string()))
    } else {
        Ok(RuntimeValue::String(s.trim_start().to_string()))
    }
}

pub(crate) fn eval_chr_search(
    name: &str,
    args: &[RuntimeValue],
) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::String(set) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let forward = name.starts_with("INCHR");
    let start = if args.len() >= 3 {
        let RuntimeValue::Integer(v) = &args[2] else {
            return Err(type_err(args[2].value_type()));
        };
        *v
    } else if forward {
        1
    } else {
        s.len() as i32
    };
    let case_insensitive = name.ends_with('I');
    let chars: Vec<char> = if case_insensitive {
        s.to_lowercase().chars().collect()
    } else {
        s.chars().collect()
    };
    let set_chars: Vec<char> = if case_insensitive {
        set.to_lowercase().chars().collect()
    } else {
        set.chars().collect()
    };
    let start_idx = (start as usize).saturating_sub(1);
    if forward {
        for i in start_idx..chars.len() {
            if set_chars.contains(&chars[i]) {
                return Ok(RuntimeValue::Integer((i + 1) as i32));
            }
        }
    } else {
        let begin = start_idx.min(chars.len().saturating_sub(1));
        for i in (0..=begin).rev() {
            if set_chars.contains(&chars[i]) {
                return Ok(RuntimeValue::Integer((i + 1) as i32));
            }
        }
    }
    Ok(RuntimeValue::Integer(0))
}

pub(crate) fn eval_stuff(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(into) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::String(from) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let RuntimeValue::Integer(start) = &args[2] else {
        return Err(type_err(args[2].value_type()));
    };
    let into_chars: Vec<char> = into.chars().collect();
    let from_chars: Vec<char> = from.chars().collect();
    let start_idx = (*start as usize).saturating_sub(1).min(into_chars.len());
    let avail = into_chars.len() - start_idx;
    let max_from = if args.len() == 4 {
        let RuntimeValue::Integer(len) = &args[3] else {
            return Err(type_err(args[3].value_type()));
        };
        (*len as usize).min(from_chars.len())
    } else {
        from_chars.len()
    };
    let phase2 = max_from.min(avail);
    let mut result: Vec<char> = into_chars[..start_idx].to_vec();
    result.extend_from_slice(&from_chars[..phase2]);
    let phase3_start = start_idx + phase2;
    result.extend_from_slice(&into_chars[phase3_start..]);
    Ok(RuntimeValue::String(result.into_iter().collect()))
}

/// 2-arg BIN$/BINB$/OCT$/OCTO$: format with minimum digit width.
pub(crate) fn eval_int_to_str2(
    name: &str,
    args: &[RuntimeValue],
) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let (prefix, radix, digits) = match name {
        "BINB$" => ("0b", 2, format!("{:b}", *n)),
        "BIN$" => ("", 2, format!("{:b}", *n)),
        "OCTO$" => ("0o", 8, format!("{:o}", *n)),
        "OCT$" => ("", 8, format!("{:o}", *n)),
        _ => unreachable!(),
    };
    let _ = radix;
    if args.len() == 2 {
        let RuntimeValue::Integer(w) = &args[1] else {
            return Err(type_err(args[1].value_type()));
        };
        let width = *w as usize;
        let padded = if digits.len() >= width {
            digits
        } else {
            format!("{}{}", "0".repeat(width - digits.len()), digits)
        };
        Ok(RuntimeValue::String(format!("{prefix}{padded}")))
    } else {
        Ok(RuntimeValue::String(format!("{prefix}{digits}")))
    }
}
