use std::cell::{Cell, RefCell};

thread_local! {
    static SELECT_COUNTER: Cell<usize> = Cell::new(0);
    static SELECT_STACK: RefCell<Vec<usize>> = RefCell::new(Vec::new());
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
        let conds: Vec<String> = case
            .conditions
            .iter()
            .map(|c| {
                let mut s = String::new();
                emit_expr(c, &mut s);
                format!("_sel == {s}")
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
    let lt = c_type(left.value_type);
    let mut ln = String::new();
    crate::c_emit_expr::emit_var_name(left, &mut ln);
    let mut rn = String::new();
    crate::c_emit_expr::emit_var_name(right, &mut rn);
    out.push_str(ind);
    out.push_str(&format!("{lt} _swap_tmp_{ln} = {ln};\n"));
    out.push_str(ind);
    out.push_str(&format!("{ln} = {rn};\n"));
    out.push_str(ind);
    out.push_str(&format!("{rn} = _swap_tmp_{ln};\n"));
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
                out.push_str("{ char* _p = xb_strdup(\"\"); char* _t = xb_tab(strlen(_p), ");
                emit_expr(&args[0], out);
                out.push_str("); _p = xb_concat(_p, _t); xb_print_str(_p); }\n");
                return;
            }
        }
        out.push_str(&ind);
        match items[0].value_type {
            ValueType::Integer => out.push_str("xb_print_int("),
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
    out.push_str(";");
    for (i, expr) in items.iter().enumerate().skip(1) {
        if let PrintSep::Comma = separators[i - 1] {
            out.push_str(" _p = xb_concat(_p, \"\\t\");");
        }
        // Check if this item is a TAB call
        if let IrExprKind::FunctionCall { name, args } = &expr.kind {
            if name == "TAB" && args.len() == 1 {
                out.push_str(" { char* _t = xb_tab(strlen(_p), ");
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
        ValueType::Float => {
            out.push_str("xb_str_float(");
            emit_expr(expr, out);
            out.push(')');
        }
        ValueType::String => emit_expr(expr, out),
    }
}
