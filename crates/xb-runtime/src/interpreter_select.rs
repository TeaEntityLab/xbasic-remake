use crate::eval::eval;
use crate::interpreter::{exec_items, Flow};
use crate::slot::RuntimeValue;
use crate::slot::{ExecutionState, RuntimeError, TypedSlot};
use xb_compiler::{IrExpr, IrExprKind, IrItem, IrProgram, IrSymbol, PrintSep};

pub(crate) fn exec_select_case(
    program: &IrProgram,
    selector: &IrExpr,
    cases: &[xb_compiler::IrCaseClause],
    default: Option<&[IrItem]>,
    func_body: &[IrItem],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<Flow, RuntimeError> {
    let sel = eval(program, selector, state, output)?;
    let mut matched = false;
    for case in cases {
        for cond in &case.conditions {
            let cv = eval(program, cond, state, output)?;
            if sel == cv {
                let flow = exec_items(program, &case.body, func_body, 0, state, output)?;
                match flow {
                    Flow::Continue | Flow::Break => {}
                    Flow::Return(_) => return Ok(flow),
                    Flow::Goto(_) | Flow::GosubReturn => return Ok(flow),
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
            let flow = exec_items(program, def, func_body, 0, state, output)?;
            match flow {
                Flow::Continue | Flow::Break => {}
                Flow::Return(_) => return Ok(flow),
                Flow::Goto(_) | Flow::GosubReturn => return Ok(flow),
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
    // Swap the entire slots (value + array contents), auto-declaring either
    // operand if it was never DIM'd (legacy XBasic). Shared arrays/scalars
    // live in `state.shared` and must be swapped there, not in `slots`.
    let l_is_shared = state.shared.contains_key(&left.name);
    let r_is_shared = state.shared.contains_key(&right.name);
    let l = if l_is_shared {
        state.shared.remove(&left.name).unwrap()
    } else {
        state
            .slots
            .remove(&left.name)
            .unwrap_or_else(|| crate::slot::TypedSlot::new(left.value_type))
    };
    let r = if r_is_shared {
        state.shared.remove(&right.name).unwrap()
    } else {
        state
            .slots
            .remove(&right.name)
            .unwrap_or_else(|| crate::slot::TypedSlot::new(right.value_type))
    };
    if l_is_shared {
        state.shared.insert(left.name.clone(), r);
    } else {
        state.slots.insert(left.name.clone(), r);
    }
    if r_is_shared {
        state.shared.insert(right.name.clone(), l);
    } else {
        state.slots.insert(right.name.clone(), l);
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
                let col = eval(program, &args[0], state, output)?;
                if let RuntimeValue::Integer(c) = col {
                    let cur = line.chars().count();
                    if (c as usize) > cur {
                        line.push_str(&" ".repeat(c as usize - cur));
                    }
                }
                continue;
            }
        }
        line.push_str(&eval(program, expr, state, output)?.render_faithful());
    }
    if state.line_pending {
        if let Some(last) = output.last_mut() {
            last.push_str(&line);
        } else {
            output.push(line);
        }
        state.line_pending = false;
    } else {
        output.push(line);
    }
    Ok(())
}

pub(crate) fn exec_shared(
    target: &IrSymbol,
    value: &IrExpr,
    program: &IrProgram,
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<(), RuntimeError> {
    // Coerce to the target type (XBasic implicit coercion).
    let v = crate::helpers::coerce_value(eval(program, value, state, output)?, target.value_type);
    let slot = state
        .shared
        .entry(target.name.clone())
        .or_insert_with(|| TypedSlot::new(target.value_type));
    slot.value = v;
    Ok(())
}
