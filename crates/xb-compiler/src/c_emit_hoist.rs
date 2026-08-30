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
use crate::ir::{IrExpr, IrExprKind, IrItem, IrParam, IrProgram, IrSymbol};
use crate::ValueType;
use std::collections::{BTreeMap, HashMap, HashSet};

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
    let mut scalars: BTreeMap<(String, bool), ValueType> = BTreeMap::new();
    walk_items(body, &mut scalars);
    if scalars.is_empty() {
        return;
    }
    let mut dimmed: HashSet<(String, bool)> = HashSet::new();
    collect_dimmed(body, &mut dimmed);
    let array_params: HashSet<&str> = params
        .iter()
        .filter(|p| p.is_array)
        .map(|p| p.name.as_str())
        .collect();
    let params: HashSet<(&str, bool)> = params
        .iter()
        .map(|p| (p.name.as_str(), p.value_type == ValueType::String))
        .collect();
    let ind = "    ".repeat(indent);
    for ((name, is_str), vt) in &scalars {
        // Skip params (declared in the signature) and the function's own name.
        // Key by (name, is_str): a string param `addr$` must not suppress the
        // integer local `addr` (different C variable: xb_str_addr vs xb_var_addr).
        // A dual-use ARRAY param took the `_arr` name in the signature, so its
        // scalar facet still needs this local declaration — don't skip it.
        // A dual-use SCALAR param (xcol's `mode` used as `mode[mode]`) has its
        // scalar facet in the signature already — skip it; only the `_arr` facet
        // is hoisted by emit_dyn_decls.
        let is_array_param = array_params.contains(name.as_str());
        if (params.contains(&(name.as_str(), *is_str))
            && (!crate::c_emit::is_dual_use(name) || !is_array_param))
            || own_name == Some(name.as_str())
        {
            continue;
        }
        // A dual-use name (scalar AND array) is emitted as BOTH a scalar here
        // and a separate `_arr` array by the dyn hoist — so DON'T skip it even
        // though it is dimmed / dyn. Otherwise the dynamic-name system already
        // hoists the name (pointer for a late/repeated-DIM array, or a reset
        // scalar), and it also has an inline `Dim`; hoisting again = C redefinition.
        // A non-dual-use SHARED array is only the file-scope pointer; a local
        // scalar would shadow DIM-site writes (ary.x nameBufferIndex). Dual-use
        // SHARED (xit `lineLast = lineLast[func]`) still needs the local
        // integer scalar — the array facet is the `_arr` global.
        // Dotted STRING TYPE array members (`HOST.alias$[]`) are char**
        // globals (not shared-dual). Cross-function string leaves
        // (`host.name`) stay shared-dual and still need a local char*.
        if crate::c_emit::is_shared_string_array(name) && !crate::c_emit::is_shared_dual(name) {
            continue;
        }
        if crate::c_emit::is_shared_array(name) && !crate::c_emit::is_shared_dual(name) {
            continue;
        }
        if !crate::c_emit::is_dual_use(name)
            && !crate::c_emit::is_shared_dual(name)
            && (dimmed.contains(&(name.clone(), *is_str))
                || crate::c_emit::is_dyn_array(name)
                || crate::c_emit::is_dyn_scalar(name))
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
        // If this is a `$`-suffixed String local whose base name is a byref
        // String param, record it so the copy-out reads from this `_s`
        // variable (the body writes here, not to the copy-in local).
        if *is_str {
            if let Some(base) = name.strip_suffix('$') {
                if crate::c_emit::is_byref_str_param(base) {
                    crate::c_emit::record_byref_str_s(base);
                }
            }
        }
    }
}

fn note(sym: &IrSymbol, scalars: &mut BTreeMap<(String, bool), ValueType>) {
    // Key by (name, is_string): a name used as BOTH a String and a non-String
    // (`fillColour` — `xb_str_fillColour` and `xb_var_fillColour`) is two distinct
    // C variables, so both facets must be declared (name-only keying dropped one).
    let is_str = sym.value_type == ValueType::String;
    scalars
        .entry((sym.name.clone(), is_str))
        .or_insert(sym.value_type);
}

fn walk_expr(e: &IrExpr, scalars: &mut BTreeMap<(String, bool), ValueType>) {
    match &e.kind {
        IrExprKind::Symbol(s) => note(s, scalars),
        // `SharedVariable` reads a module-shared `xb_shared_` global, not a local.
        // `ArrayAccess`/`SizeOf` name arrays (declared via `Dim`).
        IrExprKind::SharedVariable(_)
        | IrExprKind::StringLiteral(_)
        | IrExprKind::IntegerLiteral(_)
        | IrExprKind::FloatLiteral(_)
        | IrExprKind::Constant { .. }
        | IrExprKind::SizeOf { .. }
        | IrExprKind::SizeOfType { .. }
        | IrExprKind::LabelAddress(_)
        | IrExprKind::FuncAddr(_) => {}
        // `ArrayUBound` of a STRING scalar (`UBOUND(ARGV$[])`) is emitted as
        // `xb_len(xb_str_ARGV_s) - 1` — a read of the scalar string variable.
        // Note it so it gets hoisted (the variable is not DIM'd, so the dimmed
        // skip won't fire). Non-string UBOUND is an array reference (skip).
        IrExprKind::ArrayUBound { symbol } => {
            if symbol.value_type == ValueType::String {
                note(symbol, scalars);
            }
        }
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
        IrExprKind::ArrayAccess {
            index,
            extra_indices,
            ..
        } => {
            walk_expr(index, scalars);
            for x in extra_indices {
                walk_expr(x, scalars);
            }
        }
    }
}

fn walk_items(items: &[IrItem], scalars: &mut BTreeMap<(String, bool), ValueType>) {
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
            IrItem::ArrayAssignment {
                index,
                extra_indices,
                value,
                ..
            } => {
                walk_expr(index, scalars);
                for x in extra_indices {
                    walk_expr(x, scalars);
                }
                walk_expr(value, scalars);
            }
            IrItem::MidAssign {
                target,
                start,
                length,
                value,
            } => {
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
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
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
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => {
                if let Some((e, _)) = pre_condition {
                    walk_expr(e, scalars);
                }
                if let Some((e, _)) = post_condition {
                    walk_expr(e, scalars);
                }
                walk_items(body, scalars);
            }
            IrItem::For {
                var,
                start,
                end,
                step,
                body,
            } => {
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
            IrItem::SelectCase {
                selector,
                cases,
                default,
            } => {
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
            // A `Dim`'s size/extra-dim expressions can reference scalars that
            // appear nowhere else (`DIM hash[uhash]` where `uhash` is only read
            // here — the interpreter reads it as the 0 default). Walk them so
            // such scalars are hoisted; the declared `symbol` itself is an array,
            // handled by collect_dimmed.
            IrItem::Dim {
                symbol,
                size,
                is_array,
                shared,
                extra_dims,
                ..
            } => {
                // A scalar `DIM a` (no size, not an array, not shared) registers
                // `a` as a scalar context so `collect_dual_use` finds it when `a`
                // is also used as an array (DIM a + DIM a[3] → dual-use). The
                // hoist excludes DIM'd names, so this doesn't double-declare.
                // SHARED DIMs are excluded: `dim shared g:integer` + `dim shared
                // g:integer[3]` is a shared array, not dual-use — noting the
                // scalar facet would falsely trigger the dual-use gate and remove
                // the shared array global (CGEN-SHARED-ARR regression).
                if !*is_array && size.is_none() && !*shared {
                    note(symbol, scalars);
                }
                if let Some(sz) = size {
                    walk_expr(sz, scalars);
                }
                for e in extra_dims {
                    walk_expr(e, scalars);
                }
            }
            // Nested `Function` items do not occur inside a body; the rest carry
            // no scalar references.
            _ => {}
        }
    }
}

/// True if `name` is referenced as a scalar (bare `Symbol`) anywhere in `items`.
pub(crate) fn body_uses_name(items: &[IrItem], name: &str) -> bool {
    let mut scalars = BTreeMap::new();
    walk_items(items, &mut scalars);
    scalars.keys().any(|(n, _)| n == name)
}

/// True if `name` is dimensioned (via `Dim`) anywhere in `items`.
pub(crate) fn body_dims_name(items: &[IrItem], name: &str) -> bool {
    let mut dimmed = HashSet::new();
    collect_dimmed(items, &mut dimmed);
    dimmed.iter().any(|(n, _)| n == name)
}

/// Names dimensioned anywhere in `items` (recursing control flow, not nested
/// functions) — scalars *and* arrays. Such names keep their inline `Dim`
/// declaration and must not be hoisted (double declaration).
/// Keyed by (name, is_string): a string `DIM addr$` must not suppress the
/// integer scalar `addr` (different C variable).
fn collect_dimmed(items: &[IrItem], dimmed: &mut HashSet<(String, bool)>) {
    for it in items {
        match it {
            IrItem::Dim {
                symbol,
                shared: true,
                is_array: false,
                ..
            } => {}
            IrItem::Dim { symbol, .. } => {
                dimmed.insert((symbol.name.clone(), symbol.value_type == ValueType::String));
            }
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_dimmed(then_body, dimmed);
                if let Some(b) = else_body {
                    collect_dimmed(b, dimmed);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_dimmed(body, dimmed)
            }
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

/// Names passed as `@x` (ByRef Symbol) to a callee position that is a
/// *descriptor-array* param — with the symbol's type. Such a call site emits
/// the two-element descriptor forward `&x, &xb_ub_x`, so the caller must
/// declare BOTH the raw array pointer and the ubound cell even when `x` has
/// no `Dim` anywhere in the caller (xit RunJump's undeclared `text$` forwarded
/// to TokenArrayToText). Recurses control flow, not nested functions.
pub(crate) fn collect_descriptor_forwards(items: &[IrItem], out: &mut Vec<(String, ValueType)>) {
    fn expr(e: &IrExpr, out: &mut Vec<(String, ValueType)>) {
        if let IrExprKind::ByRef(inner) = &e.kind {
            if let IrExprKind::Symbol(s) = &inner.kind {
                out.push((s.name.clone(), s.value_type));
            }
        }
    }
    for it in items {
        match it {
            IrItem::Call { name, args } => {
                let desc = crate::c_emit::defined_param_descriptor(name);
                if let Some(pd) = desc {
                    for (i, a) in args.iter().enumerate() {
                        if !pd.get(i).copied().unwrap_or(false) {
                            continue;
                        }
                        expr(a, out);
                    }
                }
            }
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_descriptor_forwards(then_body, out);
                if let Some(b) = else_body {
                    collect_descriptor_forwards(b, out);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_descriptor_forwards(body, out)
            }
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_descriptor_forwards(&c.body, out);
                }
                if let Some(d) = default {
                    collect_descriptor_forwards(d, out);
                }
            }
            IrItem::Compound(body) => collect_descriptor_forwards(body, out),
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
            IrExprKind::ArrayAccess {
                symbol,
                index,
                extra_indices,
            } => {
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
            IrItem::ArrayAssignment {
                target,
                index,
                extra_indices,
                value,
            } => {
                refs.insert(target.name.clone());
                expr(index, refs);
                for x in extra_indices {
                    expr(x, refs);
                }
                expr(value, refs);
            }
            IrItem::MidAssign {
                target,
                start,
                length,
                value,
            } => {
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
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
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
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => {
                if let Some((e, _)) = pre_condition {
                    expr(e, refs);
                }
                if let Some((e, _)) = post_condition {
                    expr(e, refs);
                }
                collect_array_refs(body, refs);
            }
            IrItem::For {
                start,
                end,
                step,
                body,
                ..
            } => {
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
            IrItem::SelectCase {
                selector,
                cases,
                default,
            } => {
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
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_labels(then_body, labels);
                if let Some(b) = else_body {
                    collect_labels(b, labels);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_labels(body, labels)
            }
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

/// Disambiguate duplicate `Label` names within one function body.
///
/// XBasic allows a `SUB foo` (a gosub label) and an explicit `foo:` label in
/// the same FUNCTION — xit's WizardCompErrors has `SUB ShowError` whose body
/// ends with its own `ShowError:` label. Both lower to
/// `IrItem::Label("ShowError")`, which the C backend emits as two identical C
/// labels — a cc redefinition error.
///
/// Occurrence 0 of each name keeps its original name (so `GOSUB name`, which
/// targets the SUB entry = first occurrence, is untouched). Later occurrences
/// are renamed `<name>_dup<k>`. Every `Goto` targeting a duplicated name
/// resolves FORWARD: the next occurrence strictly after the goto's position;
/// with no forward occurrence, the first occurrence (original name).
///
/// Returns `None` when the body has no duplicate labels — callers keep using
/// the original slice, so programs without duplicates emit byte-identically.
pub(crate) fn disambiguate_labels(items: &[IrItem]) -> Option<Vec<IrItem>> {
    // Flatten in emission order (depth-first pre-order matches emit_body).
    fn flatten<'a>(items: &'a [IrItem], out: &mut Vec<&'a IrItem>) {
        for it in items {
            out.push(it);
            match it {
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    flatten(then_body, out);
                    if let Some(b) = else_body {
                        flatten(b, out);
                    }
                }
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. } => flatten(body, out),
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        flatten(&c.body, out);
                    }
                    if let Some(d) = default {
                        flatten(d, out);
                    }
                }
                IrItem::Compound(body) => flatten(body, out),
                _ => {}
            }
        }
    }

    let mut flat: Vec<&IrItem> = Vec::new();
    flatten(items, &mut flat);

    let mut occ: HashMap<&str, Vec<usize>> = HashMap::new();
    for (i, it) in flat.iter().enumerate() {
        if let IrItem::Label(n) = it {
            occ.entry(n.as_str()).or_default().push(i);
        }
    }
    let dups: HashSet<&str> = occ
        .iter()
        .filter(|(_, v)| v.len() > 1)
        .map(|(k, _)| *k)
        .collect();
    if dups.is_empty() {
        return None;
    }

    // Rename later occurrences of each duplicated label.
    let mut label_rename: HashMap<usize, String> = HashMap::new();
    for (name, positions) in &occ {
        if positions.len() == 1 {
            continue;
        }
        for (k, &pos) in positions.iter().enumerate().skip(1) {
            label_rename.insert(pos, format!("{name}_dup{k}"));
        }
    }
    // Resolve each Goto to a duplicated name forward; fall back to the first
    // occurrence (which keeps the original name).
    let mut goto_target: HashMap<usize, String> = HashMap::new();
    for (i, it) in flat.iter().enumerate() {
        if let IrItem::Goto(n) = it {
            if !dups.contains(n.as_str()) {
                continue;
            }
            let target = occ[n.as_str()]
                .iter()
                .find(|&&p| p > i)
                .map(|&p| label_rename.get(&p).cloned().unwrap_or_else(|| n.clone()))
                .unwrap_or_else(|| n.clone());
            goto_target.insert(i, target);
        }
    }

    fn rebuild(
        items: &[IrItem],
        idx: &mut usize,
        label_rename: &HashMap<usize, String>,
        goto_target: &HashMap<usize, String>,
        out: &mut Vec<IrItem>,
    ) {
        for it in items {
            let i = *idx;
            *idx += 1;
            match it {
                IrItem::Label(_) => match label_rename.get(&i) {
                    Some(nn) => out.push(IrItem::Label(nn.clone())),
                    None => out.push(it.clone()),
                },
                IrItem::Goto(_) => match goto_target.get(&i) {
                    Some(nn) => out.push(IrItem::Goto(nn.clone())),
                    None => out.push(it.clone()),
                },
                IrItem::If {
                    condition,
                    then_body,
                    else_body,
                } => {
                    let mut tb = Vec::new();
                    rebuild(then_body, idx, label_rename, goto_target, &mut tb);
                    let eb = else_body.as_ref().map(|b| {
                        let mut v = Vec::new();
                        rebuild(b, idx, label_rename, goto_target, &mut v);
                        v
                    });
                    out.push(IrItem::If {
                        condition: condition.clone(),
                        then_body: tb,
                        else_body: eb,
                    });
                }
                IrItem::While { condition, body } => {
                    let mut b = Vec::new();
                    rebuild(body, idx, label_rename, goto_target, &mut b);
                    out.push(IrItem::While {
                        condition: condition.clone(),
                        body: b,
                    });
                }
                IrItem::DoLoop {
                    pre_condition,
                    post_condition,
                    body,
                } => {
                    let mut b = Vec::new();
                    rebuild(body, idx, label_rename, goto_target, &mut b);
                    out.push(IrItem::DoLoop {
                        pre_condition: pre_condition.clone(),
                        post_condition: post_condition.clone(),
                        body: b,
                    });
                }
                IrItem::For {
                    var,
                    start,
                    end,
                    step,
                    body,
                } => {
                    let mut b = Vec::new();
                    rebuild(body, idx, label_rename, goto_target, &mut b);
                    out.push(IrItem::For {
                        var: var.clone(),
                        start: start.clone(),
                        end: end.clone(),
                        step: step.clone(),
                        body: b,
                    });
                }
                IrItem::SelectCase {
                    selector,
                    cases,
                    default,
                } => {
                    let mut cs = Vec::new();
                    for c in cases {
                        let mut b = Vec::new();
                        rebuild(&c.body, idx, label_rename, goto_target, &mut b);
                        cs.push(crate::ir::IrCaseClause {
                            conditions: c.conditions.clone(),
                            body: b,
                        });
                    }
                    let d = default.as_ref().map(|b| {
                        let mut v = Vec::new();
                        rebuild(b, idx, label_rename, goto_target, &mut v);
                        v
                    });
                    out.push(IrItem::SelectCase {
                        selector: selector.clone(),
                        cases: cs,
                        default: d,
                    });
                }
                IrItem::Compound(body) => {
                    let mut b = Vec::new();
                    rebuild(body, idx, label_rename, goto_target, &mut b);
                    out.push(IrItem::Compound(b));
                }
                _ => out.push(it.clone()),
            }
        }
    }

    let mut out = Vec::with_capacity(items.len());
    let mut idx = 0usize;
    rebuild(items, &mut idx, &label_rename, &goto_target, &mut out);
    Some(out)
}

/// Multi-dim array shapes `Dim`'d in `items` (a function body): name → its
/// declared dimension-size expressions `[size, extra_dims…]`. Only arrays with
/// `extra_dims` (genuinely multi-dim) are recorded; a 1-D array is absent, so
/// the emitter's multi-dim path never fires for it (1-D stays byte-identical).
/// Recurses control flow but not nested `Function` bodies.
pub(crate) fn collect_array_dims(items: &[IrItem], out: &mut HashMap<String, Vec<IrExpr>>) {
    for it in items {
        match it {
            IrItem::Dim {
                symbol,
                size: Some(sz),
                extra_dims,
                ..
            } if !extra_dims.is_empty() => {
                let mut dims = Vec::with_capacity(1 + extra_dims.len());
                dims.push(sz.clone());
                dims.extend(extra_dims.iter().cloned());
                out.insert(symbol.name.clone(), dims);
            }
            // Track 1-D fixed-size arrays too (needed by ATTACH Case 3 to
            // distinguish declared arrays from auto-vivified variables).
            IrItem::Dim {
                symbol,
                size: Some(sz),
                extra_dims,
                ..
            } if extra_dims.is_empty() => {
                out.insert(symbol.name.clone(), vec![sz.clone()]);
            }
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_array_dims(then_body, out);
                if let Some(b) = else_body {
                    collect_array_dims(b, out);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_array_dims(body, out)
            }
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_array_dims(&c.body, out);
                }
                if let Some(b) = default {
                    collect_array_dims(b, out);
                }
            }
            IrItem::Compound(items) => collect_array_dims(items, out),
            _ => {}
        }
    }
}

/// Names with an *array* `Dim` (`is_array` or sized) in `items`. A name with only
/// a *scalar* `Dim` but referenced as an array (a flattened composite array member
/// `px3D.shape[i].x`, DIM'd scalar from its TYPE decl but indexed) has no array
/// storage, so its array accesses must fold like a truly undimmed array. Recurses
/// control flow but not nested `Function` bodies.
pub(crate) fn collect_array_dimmed_names(items: &[IrItem], out: &mut HashSet<String>) {
    for it in items {
        match it {
            IrItem::Dim {
                symbol,
                size,
                is_array,
                ..
            } if *is_array || size.is_some() => {
                out.insert(symbol.name.clone());
            }
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_array_dimmed_names(then_body, out);
                if let Some(b) = else_body {
                    collect_array_dimmed_names(b, out);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_array_dimmed_names(body, out)
            }
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_array_dimmed_names(&c.body, out);
                }
                if let Some(b) = default {
                    collect_array_dimmed_names(b, out);
                }
            }
            IrItem::Compound(items) => collect_array_dimmed_names(items, out),
            _ => {}
        }
    }
}

/// Array names `Dim`'d with an explicit *size* or `REDIM`'d — a genuine resize
/// (not a bare `DIM x[]` empty reset). Seeds the descriptor closure (docs/18): an
/// empty `DIM x[]` of a param (qbtoxb) must NOT force a descriptor, but
/// `DIM x[n]`/`REDIM x[n]` (which reallocs the caller's array) must.
pub(crate) fn collect_resize_dimmed_names(items: &[IrItem], out: &mut HashSet<String>) {
    for it in items {
        match it {
            IrItem::Dim {
                symbol,
                size,
                redim,
                ..
            } if *redim || size.is_some() => {
                out.insert(symbol.name.clone());
            }
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_resize_dimmed_names(then_body, out);
                if let Some(b) = else_body {
                    collect_resize_dimmed_names(b, out);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_resize_dimmed_names(body, out)
            }
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_resize_dimmed_names(&c.body, out);
                }
                if let Some(b) = default {
                    collect_resize_dimmed_names(b, out);
                }
            }
            IrItem::Compound(items) => collect_resize_dimmed_names(items, out),
            _ => {}
        }
    }
}

/// Names used as BOTH a scalar (a bare `Symbol` read/write, `FOR` var, …) AND
/// an array (`a[i]`, `UBOUND(a[])`, array `DIM`). The interpreter's `TypedSlot`
/// holds independent `value` (scalar) and `array` fields, so one such name is
/// two things at once; the C backend mirrors it as a scalar `xb_var_x` plus a
/// separate array `xb_var_x_arr` (routed by IR-node kind at emission). Empty for
/// the shared corpus (no dual-use name), so this is byte-neutral there.
pub(crate) fn collect_dual_use(items: &[IrItem], extra_array: &HashSet<String>) -> HashSet<String> {
    let mut scalar_ctx: BTreeMap<(String, bool), ValueType> = BTreeMap::new();
    walk_items(items, &mut scalar_ctx);
    let mut array_ctx: HashSet<String> = HashSet::new();
    collect_array_refs(items, &mut array_ctx);
    // Also treat an array `DIM` as array-context: `DIM a[]` + `SWAP a, z`
    // (scalar) makes `a` dual-use even when `a[i]` is never accessed (adatadim).
    fn array_dims(items: &[IrItem], out: &mut HashSet<String>) {
        for it in items {
            match it {
                IrItem::Dim {
                    symbol,
                    size,
                    is_array,
                    ..
                } if *is_array || size.is_some() => {
                    out.insert(symbol.name.clone());
                }
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    array_dims(then_body, out);
                    if let Some(b) = else_body {
                        array_dims(b, out);
                    }
                }
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. }
                | IrItem::Compound(body) => array_dims(body, out),
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        array_dims(&c.body, out);
                    }
                    if let Some(b) = default {
                        array_dims(b, out);
                    }
                }
                _ => {}
            }
        }
    }
    array_dims(items, &mut array_ctx);
    // Names forced to arrays (by-ref descriptor params / descriptor-dyn locals) are
    // array-context too: one with a scalar use (`~error`, `maxZ = z`) is dual-use —
    // a scalar facet `xb_var_x` plus the array facet `xb_var_x_arr` (docs/18).
    array_ctx.extend(extra_array.iter().cloned());
    scalar_ctx
        .into_keys()
        .map(|(n, _)| n)
        .filter(|n| array_ctx.contains(n))
        .collect()
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
    /// Array names `Dim`'d inside a nested control-flow block (an `IF`/`FOR`/…
    /// body, not the function top level). A sized C array declared in a block is
    /// a block-scoped VLA that later out-of-block uses can't see (qbtoxb's
    /// `#line`, `REDIM`'d inside an `IF`), so such names must be function-hoisted
    /// (dyn). This is structural, so it round-trips through the text IR (unlike
    /// the `redim` flag, which the frozen v0.1 golden IR does not serialize).
    nested_arrays: HashSet<String>,
    /// Array DIMs with NO size (`DIM a$[]`): inherently dynamic under the
    /// auto-vivify contract — any write may grow the storage, so the name must
    /// register as dyn (heap pointer + `xb_ub_` cell + write grow-guard) even
    /// when DIM'd exactly once and never REDIM'd.
    unsized_arrays: HashSet<String>,
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
            IrExprKind::ArrayAccess {
                symbol,
                index,
                extra_indices,
            } => {
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

    fn items(&mut self, items: &[IrItem], nested: bool) {
        for it in items {
            match it {
                IrItem::Dim {
                    symbol,
                    size,
                    extra_dims,
                    is_array,
                    ..
                } => {
                    let e = self
                        .dim_info
                        .entry(symbol.name.clone())
                        .or_insert((false, symbol.value_type));
                    let arr = *is_array || size.is_some();
                    e.0 |= arr;
                    *self.dim_count.entry(symbol.name.clone()).or_insert(0) += 1;
                    if nested && arr {
                        self.nested_arrays.insert(symbol.name.clone());
                    }
                    if *is_array && size.is_none() && extra_dims.is_empty() {
                        self.unsized_arrays.insert(symbol.name.clone());
                    }
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
                IrItem::ArrayAssignment {
                    target,
                    index,
                    extra_indices,
                    value,
                } => {
                    self.touch(&target.name);
                    self.expr(index);
                    for x in extra_indices {
                        self.expr(x);
                    }
                    self.expr(value);
                }
                IrItem::MidAssign {
                    target,
                    start,
                    length,
                    value,
                } => {
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
                IrItem::If {
                    condition,
                    then_body,
                    else_body,
                } => {
                    self.expr(condition);
                    self.items(then_body, true);
                    if let Some(b) = else_body {
                        self.items(b, true);
                    }
                }
                IrItem::While { condition, body } => {
                    self.expr(condition);
                    self.items(body, true);
                }
                IrItem::DoLoop {
                    pre_condition,
                    post_condition,
                    body,
                } => {
                    if let Some((e, _)) = pre_condition {
                        self.expr(e);
                    }
                    self.items(body, true);
                    if let Some((e, _)) = post_condition {
                        self.expr(e);
                    }
                }
                IrItem::For {
                    var,
                    start,
                    end,
                    step,
                    body,
                } => {
                    self.touch(&var.name);
                    self.expr(start);
                    self.expr(end);
                    if let Some(s) = step {
                        self.expr(s);
                    }
                    self.items(body, true);
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
                IrItem::SelectCase {
                    selector,
                    cases,
                    default,
                } => {
                    self.expr(selector);
                    for c in cases {
                        for cond in &c.conditions {
                            self.expr(cond);
                        }
                        self.items(&c.body, true);
                    }
                    if let Some(b) = default {
                        self.items(b, true);
                    }
                }
                IrItem::Compound(items) => self.items(items, nested),
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
        IrItem::If {
            then_body,
            else_body,
            ..
        } => has_gosub(then_body) || else_body.as_deref().is_some_and(has_gosub),
        IrItem::While { body, .. }
        | IrItem::For { body, .. }
        | IrItem::DoLoop { body, .. }
        | IrItem::Compound(body) => has_gosub(body),
        IrItem::SelectCase { cases, default, .. } => {
            cases.iter().any(|c| has_gosub(&c.body)) || default.as_deref().is_some_and(has_gosub)
        }
        _ => false,
    })
}

pub(crate) fn collect_dyn_names(
    items: &[IrItem],
    params: &[IrParam],
    has_gosub: bool,
    descriptor_locals: &HashMap<String, ValueType>,
) -> DynNames {
    let mut w = DynWalk::default();
    w.items(items, false);
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
        // (gif/gifview). An array DIM'd inside a nested block must also be heap:
        // a block-scoped VLA can't be seen by later out-of-block uses (qbtoxb's
        // `#line`, `REDIM`'d inside an `IF`). Force both to dyn.
        // A local array passed `@x[]` to a by-ref descriptor position (docs/18)
        // must be a heap pointer with a length cell so the callee can read its
        // length / realloc + write back — force it dyn.
        let force = is_array
            && (has_gosub
                || w.nested_arrays.contains(name)
                || w.unsized_arrays.contains(name)
                || descriptor_locals.contains_key(name));
        if !force && !late && *count < 2 {
            continue;
        }
        if is_array {
            dyn_names.arrays.insert(name.clone(), vt);
        } else {
            dyn_names.scalars.insert(name.clone(), vt);
        }
    }
    // A local passed `@x[]` to a descriptor position but never `Dim`'d here (e.g.
    // Kittedy's `colors` — an initially-empty array the callee REDIMs) is not in
    // `dim_count`; force it dyn with the by-ref arg's element type so the C decl is
    // a heap pointer + `xb_ub_` cell, matching the descriptor call-site (docs/18).
    for (name, vt) in descriptor_locals {
        if !params.contains(name.as_str()) {
            dyn_names.arrays.entry(name.clone()).or_insert(*vt);
            dyn_names.scalars.remove(name);
        }
    }
    dyn_names
}

/// A whole-array by-ref arg `@x[]` lowers to `ByRef(Symbol(x))` (or
/// `SharedVariable`). Return the array name.
fn byref_array_name(e: &IrExpr) -> Option<(String, ValueType)> {
    let inner = match &e.kind {
        IrExprKind::ByRef(b) => &b.kind,
        k => k,
    };
    match inner {
        IrExprKind::Symbol(s) | IrExprKind::SharedVariable(s) => {
            Some((s.name.clone(), s.value_type))
        }
        _ => None,
    }
}

/// Does builtin `name` need a length/descriptor for its by-ref array arg at 0-based
/// `pos`? `XstQuickSort(@a[],@n[],…)` and `XstCopyArray(@src[],@dst[])` both need
/// length for arg 0 (bound/source) and a resizable descriptor for arg 1.
pub(crate) fn builtin_needs_descriptor(name: &str, pos: usize) -> bool {
    matches!(name, "XstQuickSort" | "XstCopyArray") && pos < 2
}

/// Collect `UBOUND`/`SIZE` array-name targets + `(callee, arg_pos, arg_name)` call
/// edges, recursively over items + expression `FunctionCall`s.
fn collect_desc_info(
    items: &[IrItem],
    ubound: &mut HashSet<String>,
    edges: &mut Vec<(String, usize, String, ValueType)>,
) {
    fn args_edges(
        name: &str,
        args: &[IrExpr],
        edges: &mut Vec<(String, usize, String, ValueType)>,
    ) {
        for (i, a) in args.iter().enumerate() {
            if let Some((s, vt)) = byref_array_name(a) {
                edges.push((name.to_string(), i, s, vt));
            }
        }
    }
    fn expr(
        e: &IrExpr,
        ub: &mut HashSet<String>,
        edges: &mut Vec<(String, usize, String, ValueType)>,
    ) {
        match &e.kind {
            IrExprKind::ArrayUBound { symbol } | IrExprKind::SizeOf { symbol } => {
                ub.insert(symbol.name.clone());
            }
            IrExprKind::FunctionCall { name, args } => {
                args_edges(name, args, edges);
                for a in args {
                    expr(a, ub, edges);
                }
            }
            IrExprKind::ByRef(inner) | IrExprKind::Not(inner) => expr(inner, ub, edges),
            IrExprKind::Unary { operand, .. } => expr(operand, ub, edges),
            IrExprKind::Comparison { left, right, .. }
            | IrExprKind::Arithmetic { left, right, .. }
            | IrExprKind::Boolean { left, right, .. }
            | IrExprKind::Logical { left, right, .. } => {
                expr(left, ub, edges);
                expr(right, ub, edges);
            }
            IrExprKind::ArrayAccess {
                index,
                extra_indices,
                ..
            } => {
                expr(index, ub, edges);
                for x in extra_indices {
                    expr(x, ub, edges);
                }
            }
            _ => {}
        }
    }
    for it in items {
        match it {
            IrItem::Call { name, args } => {
                args_edges(name, args, edges);
                for a in args {
                    expr(a, ubound, edges);
                }
            }
            IrItem::Assignment { value, .. } => expr(value, ubound, edges),
            IrItem::ArrayAssignment {
                index,
                extra_indices,
                value,
                ..
            } => {
                expr(index, ubound, edges);
                for x in extra_indices {
                    expr(x, ubound, edges);
                }
                expr(value, ubound, edges);
            }
            IrItem::MidAssign {
                target,
                start,
                length,
                value,
            } => {
                expr(target, ubound, edges);
                expr(start, ubound, edges);
                if let Some(l) = length {
                    expr(l, ubound, edges);
                }
                expr(value, ubound, edges);
            }
            IrItem::BuiltinAssign { args, value, .. } => {
                for a in args {
                    expr(a, ubound, edges);
                }
                expr(value, ubound, edges);
            }
            IrItem::SharedAssignment { value, .. } => expr(value, ubound, edges),
            IrItem::Print { items, .. } => {
                for e in items {
                    expr(e, ubound, edges);
                }
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                expr(condition, ubound, edges);
                collect_desc_info(then_body, ubound, edges);
                if let Some(b) = else_body {
                    collect_desc_info(b, ubound, edges);
                }
            }
            IrItem::While { condition, body } => {
                expr(condition, ubound, edges);
                collect_desc_info(body, ubound, edges);
            }
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => {
                if let Some((e, _)) = pre_condition {
                    expr(e, ubound, edges);
                }
                if let Some((e, _)) = post_condition {
                    expr(e, ubound, edges);
                }
                collect_desc_info(body, ubound, edges);
            }
            IrItem::For {
                start,
                end,
                step,
                body,
                ..
            } => {
                expr(start, ubound, edges);
                expr(end, ubound, edges);
                if let Some(s) = step {
                    expr(s, ubound, edges);
                }
                collect_desc_info(body, ubound, edges);
            }
            IrItem::Return { value: Some(e) } => expr(e, ubound, edges),
            IrItem::SelectCase {
                selector,
                cases,
                default,
            } => {
                expr(selector, ubound, edges);
                for c in cases {
                    for cond in &c.conditions {
                        expr(cond, ubound, edges);
                    }
                    collect_desc_info(&c.body, ubound, edges);
                }
                if let Some(d) = default {
                    collect_desc_info(d, ubound, edges);
                }
            }
            IrItem::Dim { size: Some(e), .. } => expr(e, ubound, edges),
            _ => {}
        }
    }
}

/// Program-level by-ref-array descriptor closure (docs/18). A param needs the
/// `(T** data_d, intptr_t* ub)` descriptor iff its body `UBOUND`s/`SIZE`s/`DIM`s/
/// `REDIM`s it or passes it to `XstQuickSort`/`XstCopyArray` (pos 0/1), OR it is
/// passed `@x[]` to a callee position that is itself a descriptor (backward
/// fixpoint). Returns per-fn (descriptor params, must-be-dyn locals). Empty for the
/// whole shared corpus → emission unchanged → sync-safe.
pub(crate) fn collect_descriptor_params(
    program: &IrProgram,
) -> HashMap<String, (HashSet<String>, HashMap<String, ValueType>)> {
    struct F {
        name: String,
        array_params: Vec<String>,
        edges: Vec<(String, usize, String, ValueType)>,
    }
    let mut params_of: HashMap<String, Vec<(String, bool)>> = HashMap::new();
    let mut fns: Vec<F> = Vec::new();
    let mut desc: HashMap<String, HashSet<String>> = HashMap::new();
    let mut dyn_locals: HashMap<String, HashMap<String, ValueType>> = HashMap::new();
    let mut seen: HashSet<String> = HashSet::new();

    for it in &program.items {
        let IrItem::Function {
            name, params, body, ..
        } = it
        else {
            continue;
        };
        if !seen.insert(name.clone()) {
            continue; // first-wins, matching emit_functions dedup
        }
        params_of.insert(
            name.clone(),
            params
                .iter()
                .map(|p| (p.name.clone(), p.is_array))
                .collect(),
        );
        let array_params: Vec<String> = params
            .iter()
            .filter(|p| p.is_array)
            .map(|p| p.name.clone())
            .collect();
        let mut ubound = HashSet::new();
        let mut edges = Vec::new();
        collect_desc_info(body, &mut ubound, &mut edges);
        let mut resized = HashSet::new();
        collect_resize_dimmed_names(body, &mut resized);
        // Seed: array param genuinely RESIZED here (`DIM x[n]`/`REDIM x[n]`, which
        // reallocs the caller's array). A bare `UBOUND`/`SIZE`/empty-`DIM x[]` does
        // NOT seed — it stays a plain array unless made a descriptor by resize
        // reachability (propagation), so read-only `UBOUND` uses `sizeof` as before
        // (docs/18; avoids qbtoxb's stubbed-Xst-array-builtin arrays becoming
        // descriptors and crashing).
        let mut d = HashSet::new();
        for ap in &array_params {
            if resized.contains(ap) {
                d.insert(ap.clone());
            }
        }
        // Seed: array param passed to an Xst descriptor position.
        for (callee, pos, sym, _vt) in &edges {
            if builtin_needs_descriptor(callee, *pos) && array_params.iter().any(|p| p == sym) {
                d.insert(sym.clone());
            }
        }
        if !d.is_empty() {
            desc.insert(name.clone(), d);
        }
        fns.push(F {
            name: name.clone(),
            array_params,
            edges,
        });
    }

    // Backward fixpoint: `@x[]` passed to a descriptor position makes `x` a
    // descriptor (param) / dyn (local).
    loop {
        let mut changed = false;
        for f in &fns {
            for (callee, pos, sym, vt) in &f.edges {
                let target_desc = builtin_needs_descriptor(callee, *pos)
                    || params_of
                        .get(callee)
                        .and_then(|cp| cp.get(*pos))
                        .map(|(pn, _)| desc.get(callee).is_some_and(|s| s.contains(pn)))
                        .unwrap_or(false);
                if !target_desc {
                    continue;
                }
                if f.array_params.iter().any(|p| p == sym) {
                    if desc.entry(f.name.clone()).or_default().insert(sym.clone()) {
                        changed = true;
                    }
                } else if dyn_locals
                    .entry(f.name.clone())
                    .or_default()
                    .insert(sym.clone(), *vt)
                    .is_none()
                {
                    changed = true;
                }
            }
        }
        if !changed {
            break;
        }
    }

    let mut result = HashMap::new();
    for f in &fns {
        result.insert(
            f.name.clone(),
            (
                desc.get(&f.name).cloned().unwrap_or_default(),
                dyn_locals.get(&f.name).cloned().unwrap_or_default(),
            ),
        );
    }
    result
}
