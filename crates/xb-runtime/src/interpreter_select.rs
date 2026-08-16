use crate::eval::eval;
use crate::helpers::require_type;
use crate::interpreter::{exec_items, Flow};
use crate::slot::{ExecutionState, RuntimeError, TypedSlot};
use xb_compiler::{IrExpr, IrExprKind, IrItem, IrProgram, IrSymbol, PrintSep};
use crate::slot::RuntimeValue;

pub(crate) fn exec_select_case(
    program: &IrProgram,
    selector: &IrExpr,
    cases: &[xb_compiler::IrCaseClause],
    default: Option<&[IrItem]>,
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<Flow, RuntimeError> {
    let sel = eval(program, selector, state)?;
    let mut matched = false;
    for case in cases {
        for cond in &case.conditions {
            let cv = eval(program, cond, state)?;
            if sel == cv {
                let flow = exec_items(program, &case.body, state, output)?;
                match flow {
                    Flow::Continue | Flow::Break => {}
                    Flow::Return(_) => return Ok(flow),
                    Flow::Goto(_) | Flow::Gosub(_) | Flow::GosubReturn => return Ok(flow),
                }
                matched = true;
                break;
            }
        }
        if matched {
            break;
        }
    }
    if !matched {
        if let Some(def) = default {
            let flow = exec_items(program, def, state, output)?;
            match flow {
                Flow::Continue | Flow::Break => {}
                Flow::Return(_) => return Ok(flow),
                Flow::Goto(_) | Flow::Gosub(_) | Flow::GosubReturn => return Ok(flow),
            }
        }
    }
    Ok(Flow::Continue)
}

pub(crate) fn exec_swap(
    left: &xb_compiler::IrSymbol,
    right: &xb_compiler::IrSymbol,
    state: &mut ExecutionState,
) -> Result<(), RuntimeError> {
    let lv = state
        .slots
        .get(&left.name)
        .map(|s| s.value.clone())
        .ok_or_else(|| RuntimeError::UnknownSlot {
            name: left.name.clone(),
        })?;
    let rv = state
        .slots
        .get(&right.name)
        .map(|s| s.value.clone())
        .ok_or_else(|| RuntimeError::UnknownSlot {
            name: right.name.clone(),
        })?;
    if let Some(slot) = state.slots.get_mut(&left.name) {
        slot.value = rv;
    }
    if let Some(slot) = state.slots.get_mut(&right.name) {
        slot.value = lv;
    }
    Ok(())
}

pub(crate) fn exec_print(
    items: &[IrExpr],
    separators: &[PrintSep],
    program: &IrProgram,
    output: &mut Vec<String>,
    state: &mut ExecutionState,
) -> Result<(), RuntimeError> {
    let mut line = String::new();
    for (i, expr) in items.iter().enumerate() {
        if i > 0 {
            line.push_str(match separators[i - 1] {
                PrintSep::Semicolon => "",
                PrintSep::Comma => "\t",
            });
        }
        // Handle TAB() specially — pad to column
        if let IrExprKind::FunctionCall { name, args } = &expr.kind {
            if name == "TAB" && args.len() == 1 {
                let col = eval(program, &args[0], state)?;
                if let RuntimeValue::Integer(c) = col {
                    let cur = line.chars().count();
                    if (c as usize) > cur {
                        line.push_str(&" ".repeat(c as usize - cur));
                    }
                }
                continue;
            }
        }
        line.push_str(&eval(program, expr, state)?.render());
    }
    output.push(line);
    Ok(())
}

pub(crate) fn exec_shared(
    target: &IrSymbol,
    value: &IrExpr,
    program: &IrProgram,
    state: &mut ExecutionState,
) -> Result<(), RuntimeError> {
    let v = eval(program, value, state)?;
    require_type(target.value_type, v.value_type())?;
    let slot = state
        .shared
        .entry(target.name.clone())
        .or_insert_with(|| TypedSlot::new(target.value_type));
    require_type(slot.value_type, target.value_type)?;
    slot.value = v;
    Ok(())
}
