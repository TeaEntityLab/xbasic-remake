use crate::builtin::type_err;
use crate::interpreter::{RuntimeError, RuntimeValue};

pub(crate) fn eval_mid(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(start) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let bytes: &[u8] = s;
    let start_idx = (*start as usize).saturating_sub(1).min(bytes.len());
    let end_idx = if args.len() == 3 {
        let RuntimeValue::Integer(len) = &args[2] else {
            return Err(type_err(args[2].value_type()));
        };
        (start_idx.saturating_add((*len).max(0) as usize)).min(bytes.len())
    } else {
        bytes.len()
    };
    Ok(RuntimeValue::String(bytes[start_idx..end_idx].to_vec()))
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
        width = (*w).max(0) as usize
        );
        Ok(RuntimeValue::from_string(padded))
    } else {
        Ok(RuntimeValue::from_string(hex))
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
    let width = (*w).max(0) as usize;
    let result: Vec<u8> = if s.len() >= width {
        if name == "CJUST$" {
            s[..width].to_vec()
        } else {
            s.clone()
        }
    } else if name == "RJUST$" {
        let mut v = vec![b' '; width - s.len()];
        v.extend_from_slice(s);
        v
    } else if name == "CJUST$" {
        let left = (width - s.len()) / 2;
        let mut v = vec![b' '; left];
        v.extend_from_slice(s);
        v.resize(width, b' ');
        v
    } else {
        let mut v = s.clone();
        v.resize(width, b' ');
        v
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
        Ok(RuntimeValue::String(s[..end].to_vec()))
    } else {
        Ok(RuntimeValue::String(
            crate::builtin::byte_trim(s, false, true).to_vec(),
        ))
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
        Ok(RuntimeValue::String(s[start..].to_vec()))
    } else {
        Ok(RuntimeValue::String(
            crate::builtin::byte_trim(s, true, false).to_vec(),
        ))
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
    let fold = |b: u8| {
        if case_insensitive {
            b.to_ascii_lowercase()
        } else {
            b
        }
    };
    let chars: Vec<u8> = s.iter().map(|&b| fold(b)).collect();
    let set_bytes: Vec<u8> = set.iter().map(|&b| fold(b)).collect();
    let start_idx = (start as usize).saturating_sub(1);
    if forward {
        for (i, &c) in chars.iter().enumerate().skip(start_idx) {
            if set_bytes.contains(&c) {
                return Ok(RuntimeValue::Integer((i + 1) as i32));
            }
        }
    } else {
        let begin = start_idx.min(chars.len().saturating_sub(1));
        for i in (0..=begin).rev() {
            if set_bytes.contains(&chars[i]) {
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
    let into_bytes: &[u8] = into;
    let from_bytes: &[u8] = from;
    let start_idx = (*start as usize).saturating_sub(1).min(into_bytes.len());
    let avail = into_bytes.len() - start_idx;
    let max_from = if args.len() == 4 {
        let RuntimeValue::Integer(len) = &args[3] else {
            return Err(type_err(args[3].value_type()));
        };
        (*len as usize).min(from_bytes.len())
    } else {
        from_bytes.len()
    };
    let phase2 = max_from.min(avail);
    let mut result: Vec<u8> = into_bytes[..start_idx].to_vec();
    result.extend_from_slice(&from_bytes[..phase2]);
    let phase3_start = start_idx + phase2;
    result.extend_from_slice(&into_bytes[phase3_start..]);
    Ok(RuntimeValue::String(result))
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
        let width = (*w).max(0) as usize;
        let padded = if digits.len() >= width {
            digits
        } else {
            format!("{}{}", "0".repeat(width - digits.len()), digits)
        };
        Ok(RuntimeValue::from_string(format!("{prefix}{padded}")))
    } else {
        Ok(RuntimeValue::from_string(format!("{prefix}{digits}")))
    }
}
