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
        crate::builtin::byte_rfind(&hay[..end], needle)
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
    let needle_lower: Vec<u8> = needle.iter().map(|b| b.to_ascii_lowercase()).collect();
    let hay_lower: Vec<u8> = hay.iter().map(|b| b.to_ascii_lowercase()).collect();
    let pos = if name == "RINSTRI" {
        let end = if args.len() == 3 {
            let RuntimeValue::Integer(s) = &args[2] else {
                return Err(type_err(args[2].value_type()));
            };
            (*s as usize).min(hay_lower.len())
        } else {
            hay_lower.len()
        };
        crate::builtin::byte_rfind(&hay_lower[..end], &needle_lower)
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
        let start = start.min(hay_lower.len());
        crate::builtin::byte_find(&hay_lower[start..], &needle_lower)
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
        RuntimeValue::Giant(n) => Ok(RuntimeValue::Float(*n as f64)),
        RuntimeValue::Float(n) => Ok(RuntimeValue::Float(*n)),
        RuntimeValue::String(s) => Ok(RuntimeValue::Float(
            String::from_utf8_lossy(s).parse().unwrap_or(0.0),
        )),
    }
}

pub(crate) fn eval_to_int(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    match &args[0] {
        RuntimeValue::Integer(n) => Ok(RuntimeValue::Integer(*n)),
        RuntimeValue::Giant(n) => Ok(RuntimeValue::Integer(*n as i32)),
        RuntimeValue::Float(n) => Ok(RuntimeValue::Integer(*n as i32)),
        RuntimeValue::String(s) => Ok(RuntimeValue::Integer(
            String::from_utf8_lossy(s).parse().unwrap_or(0),
        )),
    }
}

/// GIANT() conversion — widen any numeric/string to a 64-bit GIANT.
pub(crate) fn eval_to_giant(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    match &args[0] {
        RuntimeValue::Integer(n) => Ok(RuntimeValue::Giant(*n as i64)),
        RuntimeValue::Giant(n) => Ok(RuntimeValue::Giant(*n)),
        RuntimeValue::Float(n) => Ok(RuntimeValue::Giant(*n as i64)),
        RuntimeValue::String(s) => Ok(RuntimeValue::Giant(
            String::from_utf8_lossy(s).trim().parse().unwrap_or(0),
        )),
    }
}

pub(crate) fn eval_rounding(
    name: &str,
    args: &[RuntimeValue],
) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let v = match name {
        "CEIL" => n.ceil(),
        "FLOOR" => n.floor(),
        "ROUND" => n.round(),
        _ => unreachable!(),
    };
    Ok(RuntimeValue::Float(v))
}

pub(crate) fn eval_rotatel(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(a) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(b) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let n = (*b as u32) % 32;
    Ok(RuntimeValue::Integer((*a as u32).rotate_left(n) as i32))
}

pub(crate) fn eval_rotater(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(a) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(b) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let n = (*b as u32) % 32;
    Ok(RuntimeValue::Integer((*a as u32).rotate_right(n) as i32))
}

pub(crate) fn eval_dhigh(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    Ok(RuntimeValue::Integer((n.to_bits() >> 32) as i32))
}

pub(crate) fn eval_dlow(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    Ok(RuntimeValue::Integer(n.to_bits() as i32))
}

pub(crate) fn eval_dmake(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(hi) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(lo) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let bits = ((*hi as u64) << 32) | (*lo as u64);
    Ok(RuntimeValue::Float(f64::from_bits(bits)))
}

pub(crate) fn eval_gmake(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(hi) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(lo) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    let bits = ((*hi as u32 as u64) << 32) | (*lo as u32 as u64);
    Ok(RuntimeValue::Giant(bits as i64))
}

pub(crate) fn eval_smake(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    Ok(RuntimeValue::Float(f32::from_bits(*n as u32) as f64))
}

pub(crate) fn eval_xmake(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(n) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    Ok(RuntimeValue::Integer((*n as f32).to_bits() as i32))
}

pub(crate) fn eval_bit_reinterp(
    name: &str,
    args: &[RuntimeValue],
) -> Result<RuntimeValue, RuntimeError> {
    match name {
        "ROTATEL" => eval_rotatel(args),
        "ROTATER" => eval_rotater(args),
        "DHIGH" => eval_dhigh(args),
        "DLOW" => eval_dlow(args),
        "DMAKE" => eval_dmake(args),
        "GMAKE" => eval_gmake(args),
        "SMAKE" => eval_smake(args),
        "XMAKE" => eval_xmake(args),
        "BITFIELD" | "EXTS" | "EXTU" | "CLR" | "SET" | "MAKE" | "HIGH0" | "HIGH1" | "GHIGH"
        | "GLOW" | "SIGN" => crate::builtin_bitops::eval_bit_op(name, args),
        _ => unreachable!(),
    }
}
