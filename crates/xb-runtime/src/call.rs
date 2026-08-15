use std::collections::BTreeMap;
use xb_compiler::{IrExpr, IrItem, IrParam, IrProgram, ValueType};
type FuncInfo<'a> = (&'a str, &'a [IrParam], &'a [IrItem], ValueType);

use crate::eval::eval;
use crate::interpreter::{exec_items, ExecutionState, Flow, RuntimeError, RuntimeValue, TypedSlot};

pub(crate) fn call_function(
    program: &IrProgram,
    name: &str,
    args: &[IrExpr],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<RuntimeValue, RuntimeError> {
    match name {
        "READLINE$" => {
            if state.input_pos < state.input.len() {
                let line = state.input[state.input_pos].clone();
                state.input_pos += 1;
                return Ok(RuntimeValue::String(line));
            }
            return Ok(RuntimeValue::String(String::new()));
        }
        "INLINE$" => {
            if let Some(IrExpr {
                kind: xb_compiler::IrExprKind::StringLiteral(prompt),
                ..
            }) = args.first()
            {
                output.push(prompt.clone());
            }
            if state.input_pos < state.input.len() {
                let line = state.input[state.input_pos].clone();
                state.input_pos += 1;
                return Ok(RuntimeValue::String(line));
            }
            return Ok(RuntimeValue::String(String::new()));
        }
        "EOF" => {
            return Ok(RuntimeValue::Integer(
                if state.input_pos >= state.input.len() {
                    1
                } else {
                    0
                },
            ));
        }
        _ => {}
    }
    if is_builtin(name) {
        let mut vals = Vec::with_capacity(args.len());
        for arg in args {
            vals.push(eval(program, arg, state)?);
        }
        return crate::builtin::eval_builtin(name, &vals);
    }
    let (fname, params, body, return_type) = find_function(program, name)?;
    let mut local = BTreeMap::new();
    let mut ret_slot = TypedSlot::new(return_type);
    if return_type == ValueType::String {
        ret_slot.set(RuntimeValue::String(String::new()));
    }
    local.insert(fname.to_string(), ret_slot);
    for (p, arg) in params.iter().zip(args) {
        let v = eval(program, arg, state)?;
        if v.value_type() != p.value_type {
            return Err(RuntimeError::TypeMismatch {
                expected: p.value_type,
                actual: v.value_type(),
            });
        }
        let mut slot = TypedSlot::new(p.value_type);
        slot.set(v);
        local.insert(p.name.clone(), slot);
    }
    let mut sub = ExecutionState {
        metadata: state.metadata.clone(),
        slots: local,
        shared: state.shared.clone(),
        input: state.input.clone(),
        input_pos: state.input_pos,
        data_segment: Vec::new(),
        data_pos: 0,
    };
    let result = match exec_items(program, body, &mut sub, output)? {
        Flow::Return(Some(v)) => Ok(v),
        Flow::Return(None) => {
            let ret = sub.slots.get(fname).map(|s| s.value.clone());
            Ok(ret.unwrap_or(RuntimeValue::Integer(0)))
        }
        _ => {
            let ret = sub.slots.get(fname).map(|s| s.value.clone());
            Ok(ret.unwrap_or(RuntimeValue::Integer(0)))
        }
    };
    state.input_pos = sub.input_pos;
    state.shared = sub.shared;
    result
}

fn find_function<'a>(program: &'a IrProgram, name: &str) -> Result<FuncInfo<'a>, RuntimeError> {
    for item in &program.items {
        if let IrItem::Function {
            name: fname,
            params,
            body,
            return_type,
        } = item
        {
            if fname == name {
                return Ok((fname, params, body, *return_type));
            }
        }
    }
    Err(RuntimeError::UnknownFunction {
        name: name.to_owned(),
    })
}

fn is_builtin(name: &str) -> bool {
    matches!(
        name,
        "LEN"
            | "ASC"
            | "CHR$"
            | "LEFT$"
            | "RIGHT$"
            | "MID$"
            | "INSTR"
            | "RINSTR"
            | "INSTRI"
            | "RINSTRI"
            | "VAL"
            | "STR$"
            | "UCASE$"
            | "LCASE$"
            | "TRIM$"
            | "LTRIM$"
            | "RTRIM$"
            | "SPACE$"
            | "ABS"
            | "SGN"
            | "INT"
            | "FIX"
            | "MAX"
            | "MIN"
            | "HEX$"
            | "BIN$"
            | "OCT$"
            | "HEXX$"
            | "RJUST$"
            | "LJUST$"
            | "STRING$"
            | "STRING"
            | "DOUBLE"
            | "SINGLE"
            | "XLONG"
            | "SQRT"
            | "SIN"
            | "COS"
            | "TAN"
            | "EXP"
            | "LOG"
            | "ATN"
            | "ACOS"
            | "ASIN"
            | "ATAN2"
            | "LOG10"
            | "POWER"
            | "SINH"
            | "COSH"
            | "TANH"
            | "ASINH"
            | "ACOSH"
            | "ATANH"
            | "EXP10"
            | "EXP2"
            | "COT"
            | "SEC"
            | "CSC"
            | "COTH"
            | "SECH"
            | "CSCH"
            | "ACOT"
            | "ASEC"
            | "ACSC"
            | "ACOTH"
            | "ASECH"
            | "ACSCH"
            | "RND"
            | "CEIL"
            | "FLOOR"
            | "ROUND"
            | "TIMER"
            | "TIME$"
            | "DATE$"
            | "INLINE$"
            | "EOF"
    )
}
