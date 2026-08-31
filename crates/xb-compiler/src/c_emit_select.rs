use std::cell::{Cell, RefCell};

thread_local! {
    static SELECT_COUNTER: Cell<usize> = const { Cell::new(0) };
    static SELECT_STACK: RefCell<Vec<usize>> = const { RefCell::new(Vec::new()) };
}

use crate::c_emit::c_type;
use crate::c_emit_expr::emit_expr;
use crate::c_emit_stmt::emit_item;
use crate::checked::PrintSep;
use crate::ir::{IrCaseClause, IrExpr, IrExprKind, IrItem};
use crate::ValueType;

pub(crate) fn emit_select_case(
    selector: &IrExpr,
    cases: &[IrCaseClause],
    default: Option<&[IrItem]>,
    out: &mut String,
    indent: usize,
) {
    let id = SELECT_COUNTER.with(|c| {
        let v = c.get();
        c.set(v + 1);
        v
    });
    SELECT_STACK.with(|s| s.borrow_mut().push(id));
    let ind = "  ".repeat(indent);
    out.push_str(&ind);
    out.push_str("{\n");
    out.push_str(&ind);
    out.push_str(&format!("    {} _sel = ", c_type(selector.value_type)));
    emit_expr(selector, out);
    out.push_str(";\n");
    for (i, case) in cases.iter().enumerate() {
        out.push_str(&ind);
        if i == 0 {
            out.push_str("    if (");
        } else {
            out.push_str("    else if (");
        }
        let is_str = selector.value_type == ValueType::String;
        let conds: Vec<String> = case
            .conditions
            .iter()
            .map(|c| {
                let mut s = String::new();
                emit_expr(c, &mut s);
                if is_str {
                    // String selector: compare by content, never pointer identity
                    // (mirrors interp + the Comparison arm's xb_scmp).
                    format!("xb_scmp(_sel, {s}) == 0")
                } else {
                    format!("_sel == {s}")
                }
            })
            .collect();
        out.push_str(&conds.join(" || "));
        out.push_str(") {\n");
        for item in &case.body {
            emit_item(item, out, indent + 2);
        }
        out.push_str(&ind);
        out.push_str("    }\n");
    }
    if let Some(def) = default {
        out.push_str(&ind);
        out.push_str("    else {\n");
        for item in def {
            emit_item(item, out, indent + 2);
        }
        out.push_str(&ind);
        out.push_str("    }\n");
    }
    out.push_str(&ind);
    out.push_str(&format!("    _exit_sel_{id}:;\n"));
    out.push_str(&ind);
    out.push_str("}\n");
    SELECT_STACK.with(|s| s.borrow_mut().pop());
}

pub(crate) fn current_select_id() -> usize {
    SELECT_STACK.with(|s| s.borrow().last().copied().unwrap_or(0))
}

pub(crate) fn reset_select_state() {
    SELECT_COUNTER.with(|c| c.set(0));
    SELECT_STACK.with(|s| s.borrow_mut().clear());
}

pub(crate) fn emit_swap(
    left: &crate::ir::IrSymbol,
    right: &crate::ir::IrSymbol,
    out: &mut String,
    ind: &str,
) {
    // Array swap: when both sides are dynamic arrays (shared, local dyn, or
    // plain array params), swap the storage pointer and ub. This handles
    // `SWAP #arr[], local[]` where IR loses brackets (e.g., `swap qbasic$:string qb:integer`).
    let ldesc = crate::c_emit::is_descriptor_param(&left.name);
    let rdesc = crate::c_emit::is_descriptor_param(&right.name);
    let larr = crate::c_emit::is_dyn_array(&left.name) || crate::c_emit::is_array_param(&left.name);
    let rarr =
        crate::c_emit::is_dyn_array(&right.name) || crate::c_emit::is_array_param(&right.name);
    if (larr || ldesc) && (rarr || rdesc) {
        let l_base = crate::c_emit_expr::sanitize_c_ident(&left.name);
        let r_base = crate::c_emit_expr::sanitize_c_ident(&right.name);
        if l_base == r_base {
            return;
        }
        let mut lvar = String::new();
        crate::c_emit::emit_array_var_name(left, &mut lvar);
        let mut rvar = String::new();
        crate::c_emit::emit_array_var_name(right, &mut rvar);
        let ptr_ty = if left.value_type == crate::ValueType::String {
            "char**"
        } else {
            "intptr_t*"
        };
        out.push_str(ind);
        out.push_str(&format!(
            "{{ {ptr_ty} _swap_var_{l_base} = {lvar}; {lvar} = {rvar}; {rvar} = _swap_var_{l_base}; }}"
        ));
        let l_has_ub = crate::c_emit::is_dyn_array(&left.name)
            || crate::c_emit::is_descriptor_param(&left.name);
        let r_has_ub = crate::c_emit::is_dyn_array(&right.name)
            || crate::c_emit::is_descriptor_param(&right.name);
        if l_has_ub && r_has_ub {
            let mut lub = String::new();
            crate::c_emit::emit_array_ub_ref(&left.name, &mut lub);
            let mut rub = String::new();
            crate::c_emit::emit_array_ub_ref(&right.name, &mut rub);
            out.push_str(ind);
            out.push_str(&format!(
                "{{ intptr_t _swap_ub_{l_base} = {lub}; {lub} = {rub}; {rub} = _swap_ub_{l_base}; }}"
            ));
        }
        out.push('\n');
        return;
    }
    let ldesc = crate::c_emit::is_descriptor_param(&left.name);
    let lt = if ldesc {
        format!("{}*", c_type(left.value_type))
    } else {
        c_type(left.value_type).to_string()
    };
    let side = |s: &crate::ir::IrSymbol, out: &mut String| {
        if crate::c_emit::is_descriptor_param(&s.name) {
            out.push_str("(*");
            crate::c_emit::emit_descriptor_data_ptr(s, out);
            out.push(')');
        } else {
            crate::c_emit_expr::emit_var_name(s, out);
        }
    };
    let mut ln = String::new();
    side(left, &mut ln);
    let mut rn = String::new();
    side(right, &mut rn);
    let mut tmp = String::from("_swap_tmp_");
    crate::c_emit_expr::emit_var_name(left, &mut tmp);
    // Scope the temp in a block so repeated SWAPs of the same left variable
    // (two `SWAP a, x` in one function) don't redeclare the temp.
    out.push_str(ind);
    out.push_str(&format!(
        "{{ {lt} {tmp} = {ln}; {ln} = {rn}; {rn} = {tmp}; }}\n"
    ));
}

pub(crate) fn emit_body<'a, I>(items: I, out: &mut String, indent: usize)
where
    I: IntoIterator<Item = &'a IrItem>,
{
    for item in items {
        emit_item(item, out, indent);
    }
}

pub(crate) fn emit_print(
    items: &[IrExpr],
    separators: &[PrintSep],
    out: &mut String,
    indent: usize,
) {
    let ind = "    ".repeat(indent);
    if items.is_empty() {
        out.push_str(&ind);
        out.push_str("printf(\"\\n\");\n");
        return;
    }
    if items.len() == 1 {
        // Check if it's a TAB call
        if let IrExprKind::FunctionCall { name, args } = &items[0].kind {
            if name == "TAB" && args.len() == 1 {
                out.push_str(&ind);
                out.push_str("{ char* _p = xb_str(\"\"); char* _t = xb_tab(xb_len(_p), ");
                emit_expr(&args[0], out);
                out.push_str("); _p = xb_concat(_p, _t); xb_print_str(_p); }\n");
                return;
            }
        }
        out.push_str(&ind);
        match items[0].value_type {
            ValueType::Integer => out.push_str("xb_print_int("),
            ValueType::Giant => out.push_str("xb_print_giant("),
            ValueType::Float => out.push_str("xb_print_float("),
            ValueType::String => out.push_str("xb_print_str("),
        }
        emit_expr(&items[0], out);
        out.push_str(");\n");
        return;
    }
    out.push_str(&ind);
    out.push_str("{ char* _p = ");
    // Check if first item is TAB
    if let IrExprKind::FunctionCall { name, args } = &items[0].kind {
        if name == "TAB" && args.len() == 1 {
            out.push_str("xb_tab(0, ");
            emit_expr(&args[0], out);
            out.push(')');
        } else {
            emit_str_expr(&items[0], out);
        }
    } else {
        emit_str_expr(&items[0], out);
    }
    out.push(';');
    for (i, expr) in items.iter().enumerate().skip(1) {
        if let PrintSep::Comma = separators[i - 1] {
            out.push_str(" _p = xb_concat(_p, xb_str(\"\\t\"));");
        }
        // Check if this item is a TAB call
        if let IrExprKind::FunctionCall { name, args } = &expr.kind {
            if name == "TAB" && args.len() == 1 {
                out.push_str(" { char* _t = xb_tab(xb_len(_p), ");
                emit_expr(&args[0], out);
                out.push_str("); _p = xb_concat(_p, _t); }");
                continue;
            }
        }
        out.push_str(" { char* _t = ");
        emit_str_expr(expr, out);
        out.push_str("; _p = xb_concat(_p, _t); }");
    }
    out.push_str(" xb_print_str(_p); }\n");
}

fn emit_str_expr(expr: &IrExpr, out: &mut String) {
    match expr.value_type {
        ValueType::Integer => {
            out.push_str("xb_str_num(");
            emit_expr(expr, out);
            out.push(')');
        }
        ValueType::Giant => {
            out.push_str("xb_str_giant(");
            emit_expr(expr, out);
            out.push(')');
        }
        ValueType::Float => {
            out.push_str("xb_str_float(");
            emit_expr(expr, out);
            out.push(')');
        }
        ValueType::String => emit_expr(expr, out),
    }
}
