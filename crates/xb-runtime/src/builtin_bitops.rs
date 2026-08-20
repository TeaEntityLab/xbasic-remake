use crate::builtin::type_err;
use crate::interpreter::{RuntimeError, RuntimeValue};

pub(crate) fn eval_bit_op(name: &str, args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    match name {
        "BITFIELD" => eval_bitfield(args),
        "EXTS" => eval_exts(args),
        "EXTU" => eval_extu(args),
        "CLR" => eval_clr(args),
        "SET" => eval_set(args),
        "MAKE" => eval_make(args),
        "HIGH0" => eval_high0(args),
        "HIGH1" => eval_high1(args),
        "GHIGH" => eval_ghigh(args),
        "GLOW" => eval_glow(args),
        "SIGN" => eval_sign(args),
        _ => unreachable!(),
    }
}

fn extract_width_offset(args: &[RuntimeValue]) -> (u32, u32) {
    if args.len() == 3 {
        let RuntimeValue::Integer(w) = &args[1] else {
            return (0, 0);
        };
        let RuntimeValue::Integer(o) = &args[2] else {
            return (0, 0);
        };
        (*w as u32, *o as u32)
    } else {
        let RuntimeValue::Integer(bs) = &args[1] else {
            return (0, 0);
        };
        ((*bs as u32 >> 8) & 0xFF, *bs as u32 & 0xFF)
    }
}

pub(crate) fn eval_bitfield(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(w) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let RuntimeValue::Integer(o) = &args[1] else {
        return Err(type_err(args[1].value_type()));
    };
    Ok(RuntimeValue::Integer(
        (((*w as u32) << 8) | (*o as u32)) as i32,
    ))
}

pub(crate) fn eval_exts(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let (w, o) = extract_width_offset(args);
    let mask = if w >= 32 { 0xFFFFFFFF } else { (1u32 << w) - 1 };
    let bits = (*v as u32 >> o) & mask;
    if bits & (1 << (w - 1)) != 0 && w < 32 {
        Ok(RuntimeValue::Integer((bits | !mask) as i32))
    } else {
        Ok(RuntimeValue::Integer(bits as i32))
    }
}

pub(crate) fn eval_extu(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let (w, o) = extract_width_offset(args);
    let mask = if w >= 32 { 0xFFFFFFFF } else { (1u32 << w) - 1 };
    Ok(RuntimeValue::Integer(((*v as u32 >> o) & mask) as i32))
}

pub(crate) fn eval_clr(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let (w, o) = extract_width_offset(args);
    let mask = if w >= 32 { 0xFFFFFFFF } else { (1u32 << w) - 1 };
    Ok(RuntimeValue::Integer(
        (*v as i32 & !((mask as i32) << o)) as i32,
    ))
}

pub(crate) fn eval_set(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let (w, o) = extract_width_offset(args);
    let mask = if w >= 32 { 0xFFFFFFFF } else { (1u32 << w) - 1 };
    Ok(RuntimeValue::Integer((*v as u32 | (mask << o)) as i32))
}

pub(crate) fn eval_make(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let (w, o) = extract_width_offset(args);
    let mask = if w >= 32 { 0xFFFFFFFF } else { (1u32 << w) - 1 };
    Ok(RuntimeValue::Integer(((*v as u32 & mask) << o) as i32))
}

pub(crate) fn eval_high0(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let bits = !(*v as u32);
    for i in (0..32).rev() {
        if bits & (1 << i) != 0 {
            return Ok(RuntimeValue::Integer(i as i32));
        }
    }
    Ok(RuntimeValue::Integer(0))
}

pub(crate) fn eval_high1(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Integer(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let bits = *v as u32;
    for i in (0..32).rev() {
        if bits & (1 << i) != 0 {
            return Ok(RuntimeValue::Integer(i as i32));
        }
    }
    Ok(RuntimeValue::Integer(0))
}

pub(crate) fn eval_ghigh(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    // High 32 bits of the 64-bit value. An INTEGER (i32) sign-extends to GIANT,
    // so its high word is the replicated sign bit (`v >> 31`).
    match &args[0] {
        RuntimeValue::Giant(v) => Ok(RuntimeValue::Integer((*v >> 32) as i32)),
        RuntimeValue::Integer(v) => Ok(RuntimeValue::Integer(*v >> 31)),
        _ => Err(type_err(args[0].value_type())),
    }
}

pub(crate) fn eval_glow(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    // Low 32 bits, reinterpreted as i32.
    match &args[0] {
        RuntimeValue::Giant(v) => Ok(RuntimeValue::Integer(*v as i32)),
        RuntimeValue::Integer(v) => Ok(RuntimeValue::Integer(*v)),
        _ => Err(type_err(args[0].value_type())),
    }
}

pub(crate) fn eval_sign(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::Float(v) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    Ok(RuntimeValue::Integer(if *v < 0.0 { -1 } else { 1 }))
}
