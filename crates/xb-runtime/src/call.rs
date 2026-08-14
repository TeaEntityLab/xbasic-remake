use std::collections::BTreeMap;
use xb_compiler::{IrExpr, IrItem, IrParam, IrProgram};

use crate::interpreter::{
    eval, exec_items, ExecutionState, Flow, RuntimeError, RuntimeValue, TypedSlot,
};

pub(crate) fn call_function(
    program: &IrProgram,
    name: &str,
    args: &[IrExpr],
    state: &ExecutionState,
    output: &mut Vec<String>,
) -> Result<RuntimeValue, RuntimeError> {
    if is_builtin(name) {
        let mut vals = Vec::with_capacity(args.len());
        for arg in args {
            vals.push(eval(program, arg, state)?);
        }
        return crate::builtin::eval_builtin(name, &vals);
    }
    let (params, body) = find_function(program, name)?;
    let mut local = BTreeMap::new();
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
    };
    match exec_items(program, body, &mut sub, output)? {
        Flow::Return(Some(v)) => Ok(v),
        _ => Ok(RuntimeValue::Integer(0)),
    }
}
fn find_function<'a>(
    program: &'a IrProgram,
    name: &str,
) -> Result<(&'a [IrParam], &'a [IrItem]), RuntimeError> {
    for item in &program.items {
        if let IrItem::Function {
            name: fname,
            params,
            body,
            ..
        } = item
        {
            if fname == name {
                return Ok((params, body));
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
        "LEN" | "ASC" | "CHR$" | "LEFT$" | "RIGHT$" | "MID$" | "INSTR" | "VAL" | "STR$"
    )
}
