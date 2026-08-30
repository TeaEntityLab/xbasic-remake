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
                return Ok(RuntimeValue::Integer(0));
            }
            Ok(RuntimeValue::Integer(s[0] as i32))
        }
        "CHR$" => {
            let RuntimeValue::Integer(n) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            let byte = *n as u8;
            if args.len() == 2 {
                let RuntimeValue::Integer(count) = &args[1] else {
                    return Err(type_err(args[1].value_type()));
                };
                let count = (*count).max(1) as usize;
                Ok(RuntimeValue::String(vec![byte; count]))
            } else {
                Ok(RuntimeValue::String(vec![byte]))
            }
        }
        "LEFT$" => string_slice(args, |s, n| {
            let end = n.min(s.len());
            s[..end].to_vec()
        }),
        "RIGHT$" => string_slice(args, |s, n| {
            let start = s.len().saturating_sub(n);
            s[start..].to_vec()
        }),
        "MID$" => crate::builtin_str::eval_mid(args),
        "INSTR" => {
            let RuntimeValue::String(hay) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            let RuntimeValue::String(needle) = &args[1] else {
                return Err(type_err(args[1].value_type()));
            };
            let start = if args.len() == 3 {
                let RuntimeValue::Integer(s) = &args[2] else {
                    return Err(type_err(args[2].value_type()));
                };
                *s as usize
            } else {
                0
            };
            let start = start.saturating_sub(1).min(hay.len());
            Ok(RuntimeValue::Integer(
                byte_find(&hay[start..], needle)
                    .map(|i| (start + i + 1) as i32)
                    .unwrap_or(0),
            ))
        }
        "RINSTR" => crate::builtin_math::eval_rinstr(args),
        "INSTRI" | "RINSTRI" => crate::builtin_math::eval_instri(name, args),
        "VAL" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            let text = String::from_utf8_lossy(s);
            let trimmed = text.trim();
            let v = if let Some(hex) = trimmed
                .strip_prefix("0x")
                .or_else(|| trimmed.strip_prefix("0X"))
            {
                i32::from_str_radix(hex, 16).unwrap_or(0)
            } else {
                trimmed.parse().unwrap_or(0)
            };
            Ok(RuntimeValue::Integer(v))
        }
        "STR$" => match &args[0] {
            RuntimeValue::Integer(n) => Ok(RuntimeValue::from_string(n.to_string())),
            RuntimeValue::Float(n) => Ok(RuntimeValue::from_string(n.to_string())),
            _ => Err(type_err(args[0].value_type())),
        },
        "STRING$" | "STRING" => int_to_string(args, |n| n.to_string()),
        "SIGNED$" => int_to_string(args, |n| {
            if n >= 0 {
                format!("+{n}")
            } else {
                n.to_string()
            }
        }),
        "NULL$" => {
            let RuntimeValue::Integer(n) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(vec![0u8; (*n).max(0) as usize]))
        }
        "SQRT" => float_fn(args, |v| v.sqrt()),
        "SIN" => float_fn(args, |v| v.sin()),
        "COS" => float_fn(args, |v| v.cos()),
        "TAN" => float_fn(args, |v| v.tan()),
        "EXP" => float_fn(args, |v| v.exp()),
        "LOG" => float_fn(args, |v| v.ln()),
        "ATN" | "ATAN" => float_fn(args, |v| v.atan()),
        "ACOS" => float_fn(args, |v| v.acos()),
        "ASIN" => float_fn(args, |v| v.asin()),
        "LOG10" => float_fn(args, |v| v.log10()),
        "SINH" => float_fn(args, |v| v.sinh()),
        "COSH" => float_fn(args, |v| v.cosh()),
        "TANH" => float_fn(args, |v| v.tanh()),
        "ASINH" => float_fn(args, |v| v.asinh()),
        "ACOSH" => float_fn(args, |v| v.acosh()),
        "ATANH" => float_fn(args, |v| v.atanh()),
        "EXP10" => float_fn(args, |v| (10.0f64).powf(v)),
        "EXP2" | "COT" | "SEC" | "CSC" | "SECH" | "CSCH" | "COTH" | "ACOT" | "ASEC" | "ACSC"
        | "ACOTH" | "ASECH" | "ACSCH" => crate::builtin_math::eval_reciprocal(name, args),
        "ATAN2" => crate::builtin_math::eval_atan2(args),
        "POWER" => crate::builtin_math::eval_power(args),
        "UCASE$" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(
                s.iter().map(|b| b.to_ascii_uppercase()).collect(),
            ))
        }
        "LCASE$" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(
                s.iter().map(|b| b.to_ascii_lowercase()).collect(),
            ))
        }
        "TRIM$" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(byte_trim(s, true, true).to_vec()))
        }
        "LTRIM$" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(byte_trim(s, true, false).to_vec()))
        }
        "RTRIM$" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(byte_trim(s, false, true).to_vec()))
        }
        "SPACE$" => {
            let RuntimeValue::Integer(n) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::String(vec![b' '; (*n).max(0) as usize]))
        }
        "ABS" => crate::builtin_math::eval_abs(args),
        "DOUBLE" | "SINGLE" => crate::builtin_math::eval_to_float(args),
        "XLONG" | "SBYTE" | "UBYTE" | "SSHORT" | "USHORT" | "SLONG" | "ULONG" => {
            crate::builtin_math::eval_to_int(args)
        }
        "GIANT" => crate::builtin_math::eval_to_giant(args),
        "SGN" => {
            let RuntimeValue::Integer(n) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::Integer(n.signum()))
        }
        "INT" => {
            let RuntimeValue::Float(n) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::Integer(*n as i32))
        }
        "FIX" => {
            let RuntimeValue::Float(n) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::Integer(*n as i32))
        }
        "MAX" | "MIN" => {
            let RuntimeValue::Integer(a) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            let RuntimeValue::Integer(b) = &args[1] else {
                return Err(type_err(args[1].value_type()));
            };
            Ok(RuntimeValue::Integer(if name == "MAX" {
                *a.max(b)
            } else {
                *a.min(b)
            }))
        }
        "ROTATEL" | "ROTATER" | "DHIGH" | "DLOW" | "DMAKE" | "GMAKE" | "SMAKE" | "XMAKE"
        | "BITFIELD" | "EXTS" | "EXTU" | "CLR" | "SET" | "MAKE" | "HIGH0" | "HIGH1" | "GHIGH"
        | "GLOW" | "SIGN" => crate::builtin_math::eval_bit_reinterp(name, args),
        "HEX$" | "HEXX$" => crate::builtin_str::eval_hexx(name, args),
        "BIN$" | "BINB$" | "OCT$" | "OCTO$" => crate::builtin_str::eval_int_to_str2(name, args),
        "RJUST$" | "LJUST$" | "CJUST$" | "RCLIP$" | "LCLIP$" => {
            crate::builtin_str::eval_str_op(name, args)
        }
        "INCHR" | "RINCHR" | "INCHRI" | "RINCHRI" => {
            crate::builtin_str::eval_chr_search(name, args)
        }
        "STUFF$" => crate::builtin_str::eval_stuff(args),
        "FORMAT$" => crate::builtin_format::eval_format(args),
        "RND" => Ok(RuntimeValue::Float(crate::rng::next_rand())),
        "CEIL" | "FLOOR" | "ROUND" => crate::builtin_math::eval_rounding(name, args),
        "TIMER" => Ok(RuntimeValue::Float(crate::time_helpers::timer())),
        "TIME$" => Ok(RuntimeValue::from_string(crate::time_helpers::time_str())),
        "DATE$" => Ok(RuntimeValue::from_string(crate::time_helpers::date_str())),
        "CSIZE" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            let n = s.iter().position(|&b| b == 0).unwrap_or(s.len());
            Ok(RuntimeValue::Integer(n as i32))
        }
        "CSIZE$" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            let n = s.iter().position(|&b| b == 0).unwrap_or(s.len());
            Ok(RuntimeValue::String(s[..n].to_vec()))
        }
        "ISDATA" => {
            let RuntimeValue::String(s) = &args[0] else {
                return Err(type_err(args[0].value_type()));
            };
            Ok(RuntimeValue::Integer(if !s.is_empty() { -1 } else { 0 }))
        }
        "ISNODE" => {
            // Multi-dim array nodes not supported in remake; always return false
            Ok(RuntimeValue::Integer(0))
        }
        "INKEY$" => {
            // Non-blocking read of a single char from stdin
            // In the interpreter, we read from the input buffer
            Ok(RuntimeValue::from_str(""))
        }
        "WAITKEY" => {
            // Blocking read of a single key; returns key code
            Ok(RuntimeValue::Integer(0))
        }
        "GOADDR" | "SUBADDR" => {
            // Identity type conversion functions
            Ok(args[0].clone())
        }
        "FUNCADDRESS" => {
            // In interpreter, function addresses are not available; return 0
            Ok(RuntimeValue::Integer(0))
        }
        "CSTRING$" => {
            // In interpreter, no real memory; return empty string
            Ok(RuntimeValue::from_str(""))
        }
        "SBYTEAT" | "UBYTEAT" | "SSHORTAT" | "USHORTAT" | "SLONGAT" | "ULONGAT" | "XLONGAT"
        | "GIANTAT" | "SUBADDRAT" | "GOADDRAT" => {
            // Direct memory access: in interpreter, return 0 (no real memory)
            Ok(RuntimeValue::Integer(0))
        }
        "SINGLEAT" | "DOUBLEAT" => {
            // Direct memory access for floats: in interpreter, return 0.0
            Ok(RuntimeValue::Float(0.0))
        }
        _ => Err(RuntimeError::UnknownFunction {
            name: name.to_owned(),
        }),
    }
}

fn string_slice(
    args: &[RuntimeValue],
    f: impl Fn(&[u8], usize) -> Vec<u8>,
) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(s) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(n) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    Ok(RuntimeValue::String(f(s, *n as usize)))
}

fn int_to_string(
    args: &[RuntimeValue],
    f: impl Fn(i32) -> String,
) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    Ok(RuntimeValue::from_string(f(*n)))
}

fn float_fn(args: &[RuntimeValue], f: impl Fn(f64) -> f64) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    Ok(RuntimeValue::Float(f(*n)))
}

pub(crate) fn type_err(actual: xb_compiler::ValueType) -> RuntimeError {
    RuntimeError::TypeMismatch {
        expected: xb_compiler::ValueType::String,
        actual,
    }
}

/// Find the first byte-offset of `needle` in `hay` (empty needle -> Some(0)).
pub(crate) fn byte_find(hay: &[u8], needle: &[u8]) -> Option<usize> {
    if needle.is_empty() {
        return Some(0);
    }
    if needle.len() > hay.len() {
        return None;
    }
    hay.windows(needle.len()).position(|w| w == needle)
}

/// Find the last byte-offset of `needle` in `hay` (empty needle -> None).
pub(crate) fn byte_rfind(hay: &[u8], needle: &[u8]) -> Option<usize> {
    if needle.is_empty() || needle.len() > hay.len() {
        return None;
    }
    hay.windows(needle.len()).rposition(|w| w == needle)
}

/// Trim ASCII whitespace bytes from the start and/or end.
pub(crate) fn byte_trim(s: &[u8], start: bool, end: bool) -> &[u8] {
    let mut a = 0;
    let mut b = s.len();
    if start {
        while a < b && s[a].is_ascii_whitespace() {
            a += 1;
        }
    }
    if end {
        while b > a && s[b - 1].is_ascii_whitespace() {
            b -= 1;
        }
    }
    &s[a..b]
}
