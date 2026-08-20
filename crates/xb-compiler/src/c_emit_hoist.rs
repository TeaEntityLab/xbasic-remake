//! Scalar-variable hoisting for the C generator.
//!
//! XBasic auto-vivifies scalars on first use; the interpreter and the LLVM backend
//! allocate them lazily on reference. C requires every variable declared before use,
//! and the IR only carries a `Dim` for *explicitly* dimensioned names — so a plain
//! `FOR i = …` or an auto-vivified `kid`/`text` reference emitted an undeclared
//! `xb_var_i` / `xb_str_text` and failed `cc`.
//!
//! We therefore declare, at the top of each function body (and of `main`), every
//! scalar that is *referenced* but neither `Dim`'d nor a parameter (nor the
//! function's own return variable). Names that already have a `Dim` keep their
//! inline declaration, so this adds nothing for programs whose variables are all
//! dimensioned (the self-host tools and the v0.1 corpus) — CEmitter stays
//! byte-identical to `cgen.x` there.

use crate::c_emit::c_type;
use crate::c_emit_expr::{emit_default, emit_var_name};
use crate::ir::{IrExpr, IrExprKind, IrItem, IrParam, IrSymbol};
use crate::ValueType;
use std::collections::{BTreeMap, HashSet};

/// Emit `<ctype> xb_..name = <default>;` for each scalar referenced in `body` that
/// is not dimensioned, not a parameter, and not `own_name` (the function's return
/// variable). Deterministic order (`BTreeMap`).
pub(crate) fn emit_hoisted_scalars(
    body: &[IrItem],
    params: &[IrParam],
    own_name: Option<&str>,
    out: &mut String,
    indent: usize,
) {
    let mut scalars: BTreeMap<String, ValueType> = BTreeMap::new();
    walk_items(body, &mut scalars);
    if scalars.is_empty() {
        return;
    }
    let mut dimmed: HashSet<String> = HashSet::new();
    collect_dimmed(body, &mut dimmed);
    let params: HashSet<&str> = params.iter().map(|p| p.name.as_str()).collect();
    let ind = "    ".repeat(indent);
    for (name, vt) in &scalars {
        if dimmed.contains(name)
            || params.contains(name.as_str())
            || own_name == Some(name.as_str())
        {
            continue;
        }
        out.push_str(&ind);
        out.push_str(c_type(*vt));
        out.push(' ');
        emit_var_name(
            &IrSymbol {
                name: name.clone(),
                value_type: *vt,
            },
            out,
        );
        out.push_str(" = ");
        emit_default(*vt, out);
        out.push_str(";\n");
    }
}

fn note(sym: &IrSymbol, scalars: &mut BTreeMap<String, ValueType>) {
    scalars.entry(sym.name.clone()).or_insert(sym.value_type);
}

fn walk_expr(e: &IrExpr, scalars: &mut BTreeMap<String, ValueType>) {
    match &e.kind {
        IrExprKind::Symbol(s) => note(s, scalars),
        // `SharedVariable` reads a module-shared `xb_shared_` global, not a local.
        // `ArrayAccess`/`ArrayUBound`/`SizeOf` name arrays (declared via `Dim`).
        IrExprKind::SharedVariable(_)
        | IrExprKind::StringLiteral(_)
        | IrExprKind::IntegerLiteral(_)
        | IrExprKind::FloatLiteral(_)
        | IrExprKind::Constant { .. }
        | IrExprKind::ArrayUBound { .. }
        | IrExprKind::SizeOf { .. }
        | IrExprKind::SizeOfType { .. }
        | IrExprKind::LabelAddress(_)
        | IrExprKind::FuncAddr(_) => {}
        IrExprKind::ByRef(inner) | IrExprKind::Not(inner) => walk_expr(inner, scalars),
        IrExprKind::Unary { operand, .. } => walk_expr(operand, scalars),
        IrExprKind::Comparison { left, right, .. }
        | IrExprKind::Arithmetic { left, right, .. }
        | IrExprKind::Boolean { left, right, .. }
        | IrExprKind::Logical { left, right, .. } => {
            walk_expr(left, scalars);
            walk_expr(right, scalars);
        }
        IrExprKind::FunctionCall { args, .. } => {
            for a in args {
                walk_expr(a, scalars);
            }
        }
        IrExprKind::ArrayAccess { index, extra_indices, .. } => {
            walk_expr(index, scalars);
            for x in extra_indices {
                walk_expr(x, scalars);
            }
        }
    }
}

fn walk_items(items: &[IrItem], scalars: &mut BTreeMap<String, ValueType>) {
    for it in items {
        match it {
            IrItem::Print { items, .. } => {
                for e in items {
                    walk_expr(e, scalars);
                }
            }
            IrItem::Assignment { target, value } => {
                note(target, scalars);
                walk_expr(value, scalars);
            }
            // `target` is an array; walk the indices and the value.
            IrItem::ArrayAssignment { index, extra_indices, value, .. } => {
                walk_expr(index, scalars);
                for x in extra_indices {
                    walk_expr(x, scalars);
                }
                walk_expr(value, scalars);
            }
            IrItem::MidAssign { target, start, length, value } => {
                walk_expr(target, scalars);
                walk_expr(start, scalars);
                if let Some(l) = length {
                    walk_expr(l, scalars);
                }
                walk_expr(value, scalars);
            }
            IrItem::BuiltinAssign { args, value, .. } => {
                for a in args {
                    walk_expr(a, scalars);
                }
                walk_expr(value, scalars);
            }
            // `target` is a shared `xb_shared_` global; only the value is local.
            IrItem::SharedAssignment { value, .. } => walk_expr(value, scalars),
            IrItem::If { condition, then_body, else_body } => {
                walk_expr(condition, scalars);
                walk_items(then_body, scalars);
                if let Some(b) = else_body {
                    walk_items(b, scalars);
                }
            }
            IrItem::While { condition, body } => {
                walk_expr(condition, scalars);
                walk_items(body, scalars);
            }
            IrItem::DoLoop { pre_condition, post_condition, body } => {
                if let Some((e, _)) = pre_condition {
                    walk_expr(e, scalars);
                }
                if let Some((e, _)) = post_condition {
                    walk_expr(e, scalars);
                }
                walk_items(body, scalars);
            }
            IrItem::For { var, start, end, step, body } => {
                note(var, scalars);
                walk_expr(start, scalars);
                walk_expr(end, scalars);
                if let Some(s) = step {
                    walk_expr(s, scalars);
                }
                walk_items(body, scalars);
            }
            IrItem::Return { value: Some(e) } => walk_expr(e, scalars),
            IrItem::Call { args, .. } => {
                for a in args {
                    walk_expr(a, scalars);
                }
            }
            IrItem::Swap { left, right } => {
                note(left, scalars);
                note(right, scalars);
            }
            IrItem::SelectCase { selector, cases, default } => {
                walk_expr(selector, scalars);
                for c in cases {
                    for cond in &c.conditions {
                        walk_expr(cond, scalars);
                    }
                    walk_items(&c.body, scalars);
                }
                if let Some(b) = default {
                    walk_items(b, scalars);
                }
            }
            IrItem::Compound(items) => walk_items(items, scalars),
            IrItem::Read(syms) => {
                for s in syms {
                    note(s, scalars);
                }
            }
            IrItem::GosubExpr(e) | IrItem::GotoExpr(e) => walk_expr(e, scalars),
            // `Dim` declares (handled by collect_dimmed); nested `Function` items do
            // not occur inside a body; the rest carry no scalar references.
            _ => {}
        }
    }
}

/// Names dimensioned anywhere in `items` (recursing control flow, not nested
/// functions) — scalars *and* arrays. Such names keep their inline `Dim`
/// declaration and must not be hoisted (double declaration).
fn collect_dimmed(items: &[IrItem], dimmed: &mut HashSet<String>) {
    for it in items {
        match it {
            IrItem::Dim { symbol, .. } => {
                dimmed.insert(symbol.name.clone());
            }
            IrItem::If { then_body, else_body, .. } => {
                collect_dimmed(then_body, dimmed);
                if let Some(b) = else_body {
                    collect_dimmed(b, dimmed);
                }
            }
            IrItem::While { body, .. }
            | IrItem::For { body, .. }
            | IrItem::DoLoop { body, .. } => collect_dimmed(body, dimmed),
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_dimmed(&c.body, dimmed);
                }
                if let Some(b) = default {
                    collect_dimmed(b, dimmed);
                }
            }
            IrItem::Compound(items) => collect_dimmed(items, dimmed),
            _ => {}
        }
    }
}
