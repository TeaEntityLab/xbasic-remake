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
            // The dynamic-name system already hoists these (as a pointer for a
            // late/repeated-DIM array, or a reset scalar). A composite member
            // array `type0.a` DIM'd 2+ times lands in dyn arrays *and* is seen
            // as a Symbol here — hoisting both is a C redefinition.
            || crate::c_emit::is_dyn_array(name)
            || crate::c_emit::is_dyn_scalar(name)
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

/// Array names *referenced* in `items` (subscript reads/writes, `UBOUND`) with the
/// symbol's element type — the array analogue of the scalar walk above. Recurses
/// control flow and nested expressions, not nested functions.
pub(crate) fn collect_array_refs(items: &[IrItem], refs: &mut HashSet<String>) {
    fn expr(e: &IrExpr, refs: &mut HashSet<String>) {
        match &e.kind {
            IrExprKind::ArrayAccess { symbol, index, extra_indices } => {
                refs.insert(symbol.name.clone());
                expr(index, refs);
                for x in extra_indices {
                    expr(x, refs);
                }
            }
            IrExprKind::ArrayUBound { symbol } => {
                refs.insert(symbol.name.clone());
            }
            IrExprKind::ByRef(inner) | IrExprKind::Not(inner) => expr(inner, refs),
            IrExprKind::Unary { operand, .. } => expr(operand, refs),
            IrExprKind::Comparison { left, right, .. }
            | IrExprKind::Arithmetic { left, right, .. }
            | IrExprKind::Boolean { left, right, .. }
            | IrExprKind::Logical { left, right, .. } => {
                expr(left, refs);
                expr(right, refs);
            }
            IrExprKind::FunctionCall { args, .. } => {
                for a in args {
                    expr(a, refs);
                }
            }
            _ => {}
        }
    }
    for it in items {
        match it {
            IrItem::Print { items, .. } => {
                for e in items {
                    expr(e, refs);
                }
            }
            IrItem::Assignment { value, .. } => expr(value, refs),
            IrItem::ArrayAssignment { target, index, extra_indices, value } => {
                refs.insert(target.name.clone());
                expr(index, refs);
                for x in extra_indices {
                    expr(x, refs);
                }
                expr(value, refs);
            }
            IrItem::MidAssign { target, start, length, value } => {
                expr(target, refs);
                expr(start, refs);
                if let Some(l) = length {
                    expr(l, refs);
                }
                expr(value, refs);
            }
            IrItem::BuiltinAssign { args, value, .. } => {
                for a in args {
                    expr(a, refs);
                }
                expr(value, refs);
            }
            IrItem::SharedAssignment { value, .. } => expr(value, refs),
            IrItem::If { condition, then_body, else_body } => {
                expr(condition, refs);
                collect_array_refs(then_body, refs);
                if let Some(b) = else_body {
                    collect_array_refs(b, refs);
                }
            }
            IrItem::While { condition, body } => {
                expr(condition, refs);
                collect_array_refs(body, refs);
            }
            IrItem::DoLoop { pre_condition, post_condition, body } => {
                if let Some((e, _)) = pre_condition {
                    expr(e, refs);
                }
                if let Some((e, _)) = post_condition {
                    expr(e, refs);
                }
                collect_array_refs(body, refs);
            }
            IrItem::For { start, end, step, body, .. } => {
                expr(start, refs);
                expr(end, refs);
                if let Some(s) = step {
                    expr(s, refs);
                }
                collect_array_refs(body, refs);
            }
            IrItem::Return { value: Some(e) } => expr(e, refs),
            IrItem::Call { args, .. } => {
                for a in args {
                    expr(a, refs);
                }
            }
            IrItem::SelectCase { selector, cases, default } => {
                expr(selector, refs);
                for c in cases {
                    for cond in &c.conditions {
                        expr(cond, refs);
                    }
                    collect_array_refs(&c.body, refs);
                }
                if let Some(b) = default {
                    collect_array_refs(b, refs);
                }
            }
            IrItem::Compound(items) => collect_array_refs(items, refs),
            IrItem::GosubExpr(e) | IrItem::GotoExpr(e) => expr(e, refs),
            _ => {}
        }
    }
}

/// Label names present in `items` (recursing control flow, not nested functions) —
/// the set of `xb_label_<name>:` a single emitted C function will contain.
pub(crate) fn collect_labels(items: &[IrItem], labels: &mut HashSet<String>) {
    for it in items {
        match it {
            IrItem::Label(name) => {
                labels.insert(name.clone());
            }
            IrItem::If { then_body, else_body, .. } => {
                collect_labels(then_body, labels);
                if let Some(b) = else_body {
                    collect_labels(b, labels);
                }
            }
            IrItem::While { body, .. }
            | IrItem::For { body, .. }
            | IrItem::DoLoop { body, .. } => collect_labels(body, labels),
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_labels(&c.body, labels);
                }
                if let Some(b) = default {
                    collect_labels(b, labels);
                }
            }
            IrItem::Compound(items) => collect_labels(items, labels),
            _ => {}
        }
    }
}

/// Names with any `Dim` in `items` (scalar or array) — public wrapper over the
/// hoist pass's own dimmed-set walk, for the per-function emit context.
pub(crate) fn collect_dimmed_names(items: &[IrItem], dimmed: &mut HashSet<String>) {
    collect_dimmed(items, dimmed);
}

/// Names whose `Dim` cannot stay a plain in-place C declaration: referenced
/// *before* their first `Dim` in emission order (XBasic executes `DIM` mid-flow,
/// classically under a `GOSUB Initialize` label after the dispatch code), or
/// `Dim`'d more than once (C forbids redeclaration; the interpreter just resets
/// the slot). Such names get a hoisted declaration and their `Dim` sites become
/// (re)allocations/resets. The shared corpus compiles today, so it contains no
/// such name — this is byte-neutral there.
#[derive(Default)]
pub(crate) struct DynNames {
    /// name → element type, for names with an array `Dim` (sized or `[]`).
    pub arrays: BTreeMap<String, ValueType>,
    /// name → type, for names with only scalar `Dim`s.
    pub scalars: BTreeMap<String, ValueType>,
}

#[derive(Default)]
struct DynWalk {
    used: HashSet<String>,
    late: HashSet<String>,
    dim_count: BTreeMap<String, u32>,
    dim_info: BTreeMap<String, (bool, ValueType)>,
}

impl DynWalk {
    fn touch(&mut self, name: &str) {
        if !self.dim_count.contains_key(name) {
            // No Dim seen yet in emission order: a Dim later makes this "late".
            self.late.insert(name.to_string());
        }
        self.used.insert(name.to_string());
    }

    fn expr(&mut self, e: &IrExpr) {
        match &e.kind {
            IrExprKind::Symbol(s) => self.touch(&s.name),
            IrExprKind::ArrayAccess { symbol, index, extra_indices } => {
                self.touch(&symbol.name);
                self.expr(index);
                for x in extra_indices {
                    self.expr(x);
                }
            }
            IrExprKind::ArrayUBound { symbol } | IrExprKind::SizeOf { symbol } => {
                self.touch(&symbol.name);
            }
            IrExprKind::ByRef(inner) | IrExprKind::Not(inner) => self.expr(inner),
            IrExprKind::Unary { operand, .. } => self.expr(operand),
            IrExprKind::Comparison { left, right, .. }
            | IrExprKind::Arithmetic { left, right, .. }
            | IrExprKind::Boolean { left, right, .. }
            | IrExprKind::Logical { left, right, .. } => {
                self.expr(left);
                self.expr(right);
            }
            IrExprKind::FunctionCall { args, .. } => {
                for a in args {
                    self.expr(a);
                }
            }
            _ => {}
        }
    }

    fn items(&mut self, items: &[IrItem]) {
        for it in items {
            match it {
                IrItem::Dim { symbol, size, is_array, .. } => {
                    let e = self
                        .dim_info
                        .entry(symbol.name.clone())
                        .or_insert((false, symbol.value_type));
                    e.0 |= *is_array || size.is_some();
                    *self.dim_count.entry(symbol.name.clone()).or_insert(0) += 1;
                    if let Some(sz) = size {
                        self.expr(sz);
                    }
                }
                IrItem::Print { items, .. } => {
                    for e in items {
                        self.expr(e);
                    }
                }
                IrItem::Assignment { target, value } => {
                    self.touch(&target.name);
                    self.expr(value);
                }
                IrItem::ArrayAssignment { target, index, extra_indices, value } => {
                    self.touch(&target.name);
                    self.expr(index);
                    for x in extra_indices {
                        self.expr(x);
                    }
                    self.expr(value);
                }
                IrItem::MidAssign { target, start, length, value } => {
                    self.expr(target);
                    self.expr(start);
                    if let Some(l) = length {
                        self.expr(l);
                    }
                    self.expr(value);
                }
                IrItem::BuiltinAssign { args, value, .. } => {
                    for a in args {
                        self.expr(a);
                    }
                    self.expr(value);
                }
                IrItem::SharedAssignment { value, .. } => self.expr(value),
                IrItem::If { condition, then_body, else_body } => {
                    self.expr(condition);
                    self.items(then_body);
                    if let Some(b) = else_body {
                        self.items(b);
                    }
                }
                IrItem::While { condition, body } => {
                    self.expr(condition);
                    self.items(body);
                }
                IrItem::DoLoop { pre_condition, post_condition, body } => {
                    if let Some((e, _)) = pre_condition {
                        self.expr(e);
                    }
                    self.items(body);
                    if let Some((e, _)) = post_condition {
                        self.expr(e);
                    }
                }
                IrItem::For { var, start, end, step, body } => {
                    self.touch(&var.name);
                    self.expr(start);
                    self.expr(end);
                    if let Some(s) = step {
                        self.expr(s);
                    }
                    self.items(body);
                }
                IrItem::Return { value: Some(e) } => self.expr(e),
                IrItem::Call { args, .. } => {
                    for a in args {
                        self.expr(a);
                    }
                }
                IrItem::Swap { left, right } => {
                    self.touch(&left.name);
                    self.touch(&right.name);
                }
                IrItem::Read(syms) => {
                    for s in syms {
                        self.touch(&s.name);
                    }
                }
                IrItem::SelectCase { selector, cases, default } => {
                    self.expr(selector);
                    for c in cases {
                        for cond in &c.conditions {
                            self.expr(cond);
                        }
                        self.items(&c.body);
                    }
                    if let Some(b) = default {
                        self.items(b);
                    }
                }
                IrItem::Compound(items) => self.items(items),
                IrItem::GosubExpr(e) | IrItem::GotoExpr(e) => self.expr(e),
                _ => {}
            }
        }
    }
}

/// Does `items` (a function body) contain a `GOSUB` (goto-based) construct?
/// A `GOSUB`'s `goto` cannot legally jump over a C variable-length-array
/// declaration, so in such a function sized array `DIM`s must be heap-allocated
/// (dyn) rather than stack VLAs.
pub(crate) fn has_gosub(items: &[IrItem]) -> bool {
    items.iter().any(|it| match it {
        IrItem::Gosub(_) | IrItem::GosubExpr(_) | IrItem::GosubReturn => true,
        IrItem::If { then_body, else_body, .. } => {
            has_gosub(then_body) || else_body.as_deref().is_some_and(has_gosub)
        }
        IrItem::While { body, .. }
        | IrItem::For { body, .. }
        | IrItem::DoLoop { body, .. }
        | IrItem::Compound(body) => has_gosub(body),
        IrItem::SelectCase { cases, default, .. } => {
            cases.iter().any(|c| has_gosub(&c.body))
                || default.as_deref().is_some_and(has_gosub)
        }
        _ => false,
    })
}

pub(crate) fn collect_dyn_names(items: &[IrItem], params: &[IrParam], has_gosub: bool) -> DynNames {
    let mut w = DynWalk::default();
    w.items(items);
    let params: HashSet<&str> = params.iter().map(|p| p.name.as_str()).collect();
    let mut dyn_names = DynNames::default();
    for (name, count) in &w.dim_count {
        if params.contains(name.as_str()) {
            continue;
        }
        let (is_array, vt) = w.dim_info[name];
        let late = w.late.contains(name);
        // A GOSUB function's sized array DIMs must be heap (dyn), not stack VLAs
        // — a GOSUB `goto` bypassing a VLA declaration is a hard C error
        // (gif/gifview). Force every array DIM to dyn there.
        let force = has_gosub && is_array;
        if !force && !late && *count < 2 {
            continue;
        }
        if is_array {
            dyn_names.arrays.insert(name.clone(), vt);
        } else {
            dyn_names.scalars.insert(name.clone(), vt);
        }
    }
    dyn_names
}
