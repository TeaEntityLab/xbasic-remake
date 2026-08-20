use crate::c_emit_expr::emit_var_name;
use crate::c_emit_select::emit_body;
use crate::c_runtime::{emit_forward_decls, emit_globals, emit_header};
use crate::ir::{IrExpr, IrItem, IrProgram, IrSymbol};
use crate::ValueType;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};

thread_local! {
    /// User-defined function names for the program currently being emitted, so a
    /// call site can tell a real callee from an unknown one (`is_unknown_call`).
    static DEFINED_FUNCS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// Param types per user-defined function, so call sites can reconcile arity
    /// (drop extra args, pad missing with zero-defaults) like the interpreter's
    /// `params.zip(args)` binding and the LLVM backend's `eval_args`.
    static DEFINED_SIGS: RefCell<HashMap<String, Vec<crate::ValueType>>> = RefCell::new(HashMap::new());
    /// Per-param `is_array` flag per user-defined function: a by-ref arg to an
    /// array/pointer param must be emitted as a pointer, not a value (a scalar
    /// float by-ref to `double *` is otherwise a hard cc error). See CGEN-BYREF-ARG.
    static DEFINED_PARAM_ARRAYS: RefCell<HashMap<String, Vec<bool>>> = RefCell::new(HashMap::new());
    /// Per-param `by_ref` flag per user-defined function, so a by-ref arg to a
    /// by-ref param is passed as a pointer (`&x`) to match the pointer param
    /// (CGEN-BYREF-WRITEBACK). Empty-ish for the corpus (no by-ref param).
    static DEFINED_PARAM_BYREF: RefCell<HashMap<String, Vec<bool>>> = RefCell::new(HashMap::new());
    /// Per-function emit context: array names referenced but never `Dim`'d in the
    /// current function (auto-vivified — reads fold to the type default like the
    /// interpreter's missing-slot path), and the labels the current C function
    /// will actually contain (a `LabelAddress`/`goto` to any other name would be
    /// an undeclared C label; the interpreter yields 0 / errors only if executed).
    static FN_UNDIMMED_ARRAYS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    static FN_LABELS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// Per-function GOSUB return-label occurrence counts: the first `GOSUB X` keeps
    /// the historical `xb_gosub_ret_X` (byte-identity with cgen.x on the shared
    /// corpus), repeats get `_2`, `_3`, … to avoid a C duplicate-label error.
    static GOSUB_RET_SEEN: RefCell<HashMap<String, u32>> = RefCell::new(HashMap::new());
    /// Names whose `Dim` sites become (re)allocations/resets instead of C
    /// declarations: referenced before their first `Dim` in emission order, or
    /// `Dim`'d 2+ times (see c_emit_hoist::collect_dyn_names). Arrays carry the
    static FN_DYN: RefCell<crate::c_emit_hoist::DynNames> = RefCell::new(crate::c_emit_hoist::DynNames::default());
    /// Per-function parameter names: a `Dim` of a name that is already a
    /// parameter must not re-declare it in C (would be a redefinition).
    static FN_PARAMS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// `&Func` synthetic ids: 1-based program-item order, mirroring the
    /// interpreter's eval.rs `function_id` (LLVM emits the same ids).
    static FUNC_IDS: RefCell<HashMap<String, i32>> = RefCell::new(HashMap::new());
    /// Names used as both a scalar and an array in the current function — emitted
    /// as a scalar `xb_var_x` plus a separate array `xb_var_x_arr` (interp's slot
    /// holds both a `value` and an `array`). Empty for the shared corpus.
    static FN_DUAL_USE: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// Per-function multi-dim array shapes: name → its declared dimension-size
    /// expressions (`[size, extra_dims…]`). A multi-dim `arr[i,j]` access needs
    /// the shape to compute the row-major flat offset (the interpreter flattens
    /// to a 1-D store). Only populated for arrays `Dim`'d with `extra_dims` in
    /// the current function; empty for the shared corpus (all 1-D), so no 1-D
    /// emission changes.
    static FN_ARRAY_DIMS: RefCell<HashMap<String, Vec<IrExpr>>> = RefCell::new(HashMap::new());
    /// By-reference SCALAR params of the current function (`@value`, not arrays):
    /// emitted as `T* x_ref` with copy-in (`T x = *x_ref;`) at the top and
    /// copy-out (`*x_ref = x;`) before every return, so writes reach the caller
    /// (CGEN-BYREF-WRITEBACK). Empty for the corpus (no by-ref param).
    static FN_BYREF_PARAMS: RefCell<Vec<(String, ValueType)>> = RefCell::new(Vec::new());
}

/// Record every user-defined function name for `program`. Called once per
/// `emit_program` before any body is emitted.
fn set_defined_funcs(program: &IrProgram) {
    DEFINED_FUNCS.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        for item in &program.items {
            if let IrItem::Function { name, .. } = item {
                set.insert(name.clone());
            }
        }
    });
    DEFINED_SIGS.with(|s| {
        let mut sigs = s.borrow_mut();
        sigs.clear();
        for item in &program.items {
            if let IrItem::Function { name, params, .. } = item {
                // First-wins, matching find_function / emit_functions dedup.
                sigs.entry(name.clone())
                    .or_insert_with(|| params.iter().map(|p| p.value_type).collect());
            }
        }
    });
    DEFINED_PARAM_ARRAYS.with(|s| {
        let mut m = s.borrow_mut();
        m.clear();
        for item in &program.items {
            if let IrItem::Function { name, params, .. } = item {
                m.entry(name.clone())
                    .or_insert_with(|| params.iter().map(|p| p.is_array).collect());
            }
        }
    });
    DEFINED_PARAM_BYREF.with(|s| {
        let mut m = s.borrow_mut();
        m.clear();
        // Call-site driven: a param is by-ref iff EVERY call passes `@arg` there
        // and none passes it by value. This matches the interpreter (whose
        // write-back keys on the *arg* being `ByRef`, not the param decl - a
        // `DECLARE @p` defined without `@` still writes back, e.g. geo's
        // `GeoPerpendicularLine @L2`) while keeping a fixed C signature that
        // type-checks every call. A param `@`-ed at some sites but passed by value
        // at others (ary's `ArySetSINGLE value!`, spuriously `@`-ed) stays by
        // value; the interp's write-back there is a no-op (callee never writes it).
        // A composite `@v` has already flattened to per-member `byref(...)` args.
        let mut seen: HashMap<String, Vec<(bool, bool)>> = HashMap::new();
        collect_callsite_byref(&program.items, &mut seen);
        for (name, states) in seen {
            m.insert(name, states.iter().map(|(br, bv)| *br && !*bv).collect());
        }
    });
    FUNC_IDS.with(|s| {
        let mut ids = s.borrow_mut();
        ids.clear();
        let mut id: i32 = 0;
        for item in &program.items {
            if let IrItem::Function { name, .. } = item {
                // Mirror eval.rs function_id exactly: every Function item
                // (including forward-decl duplicates) increments; first
                // occurrence of a name wins.
                id += 1;
                ids.entry(name.clone()).or_insert(id);
            }
        }
    });
}

/// Record, per callee position, whether an `@arg` (`ByRef`) and/or a by-value arg
/// is ever passed there, across every call site in the program. A param is by-ref
/// (a C pointer with copy-in/copy-out) iff `seen_byref && !seen_byval` - the
/// call-site-driven model the interpreter uses, restricted to positions that are
/// *consistently* `@` so the fixed C signature still type-checks every call.
fn collect_callsite_byref(items: &[IrItem], m: &mut HashMap<String, Vec<(bool, bool)>>) {
    fn record(name: &str, args: &[IrExpr], m: &mut HashMap<String, Vec<(bool, bool)>>) {
        let v = m.entry(name.to_owned()).or_default();
        if v.len() < args.len() {
            v.resize(args.len(), (false, false));
        }
        for (i, a) in args.iter().enumerate() {
            if matches!(a.kind, crate::ir::IrExprKind::ByRef(_)) {
                v[i].0 = true;
            } else {
                v[i].1 = true;
            }
        }
    }
    fn walk_expr(e: &IrExpr, m: &mut HashMap<String, Vec<(bool, bool)>>) {
        use crate::ir::IrExprKind as K;
        match &e.kind {
            K::FunctionCall { name, args } => {
                record(name, args, m);
                for a in args {
                    walk_expr(a, m);
                }
            }
            K::ByRef(inner) | K::Not(inner) => walk_expr(inner, m),
            K::Unary { operand, .. } => walk_expr(operand, m),
            K::Comparison { left, right, .. }
            | K::Arithmetic { left, right, .. }
            | K::Boolean { left, right, .. }
            | K::Logical { left, right, .. } => {
                walk_expr(left, m);
                walk_expr(right, m);
            }
            K::ArrayAccess { index, extra_indices, .. } => {
                walk_expr(index, m);
                for x in extra_indices {
                    walk_expr(x, m);
                }
            }
            _ => {}
        }
    }
    for it in items {
        match it {
            IrItem::Call { name, args } => {
                record(name, args, m);
                for a in args {
                    walk_expr(a, m);
                }
            }
            IrItem::Print { items, .. } => {
                for e in items {
                    walk_expr(e, m);
                }
            }
            IrItem::Dim { size, extra_dims, .. } => {
                if let Some(s) = size {
                    walk_expr(s, m);
                }
                for x in extra_dims {
                    walk_expr(x, m);
                }
            }
            IrItem::Assignment { value, .. } | IrItem::SharedAssignment { value, .. } => {
                walk_expr(value, m);
            }
            IrItem::ArrayAssignment { index, extra_indices, value, .. } => {
                walk_expr(index, m);
                for x in extra_indices {
                    walk_expr(x, m);
                }
                walk_expr(value, m);
            }
            IrItem::MidAssign { target, start, length, value } => {
                walk_expr(target, m);
                walk_expr(start, m);
                if let Some(l) = length {
                    walk_expr(l, m);
                }
                walk_expr(value, m);
            }
            IrItem::BuiltinAssign { args, value, .. } => {
                for a in args {
                    walk_expr(a, m);
                }
                walk_expr(value, m);
            }
            IrItem::If { condition, then_body, else_body } => {
                walk_expr(condition, m);
                collect_callsite_byref(then_body, m);
                if let Some(e) = else_body {
                    collect_callsite_byref(e, m);
                }
            }
            IrItem::While { condition, body } => {
                walk_expr(condition, m);
                collect_callsite_byref(body, m);
            }
            IrItem::DoLoop { pre_condition, post_condition, body } => {
                if let Some((e, _)) = pre_condition {
                    walk_expr(e, m);
                }
                if let Some((e, _)) = post_condition {
                    walk_expr(e, m);
                }
                collect_callsite_byref(body, m);
            }
            IrItem::For { start, end, step, body, .. } => {
                walk_expr(start, m);
                walk_expr(end, m);
                if let Some(s) = step {
                    walk_expr(s, m);
                }
                collect_callsite_byref(body, m);
            }
            IrItem::Function { body, .. } => collect_callsite_byref(body, m),
            IrItem::Return { value } => {
                if let Some(v) = value {
                    walk_expr(v, m);
                }
            }
            IrItem::SelectCase { selector, cases, default } => {
                walk_expr(selector, m);
                for c in cases {
                    for cond in &c.conditions {
                        walk_expr(cond, m);
                    }
                    collect_callsite_byref(&c.body, m);
                }
                if let Some(d) = default {
                    collect_callsite_byref(d, m);
                }
            }
            IrItem::Compound(items) => collect_callsite_byref(items, m),
            IrItem::GosubExpr(e) | IrItem::GotoExpr(e) => walk_expr(e, m),
            _ => {}
        }
    }
}

/// Declared param types of a user-defined function, or `None` for builtins /
/// unknown names (whose call sites are emitted as-is / stubbed).
pub(crate) fn defined_params(name: &str) -> Option<Vec<crate::ValueType>> {
    DEFINED_SIGS.with(|s| s.borrow().get(name).cloned())
}

/// Per-param `is_array` flags of a user-defined callee (for by-ref arg emission).
pub(crate) fn defined_param_arrays(name: &str) -> Option<Vec<bool>> {
    DEFINED_PARAM_ARRAYS.with(|s| s.borrow().get(name).cloned())
}

/// Per-param `by_ref` flags of a user-defined callee (for by-ref arg emission).
pub(crate) fn defined_param_byref(name: &str) -> Option<Vec<bool>> {
    DEFINED_PARAM_BYREF.with(|s| s.borrow().get(name).cloned())
}

/// The interpreter's synthetic `&Func` value: 1-based program-item order
/// (eval.rs `function_id`), or 0 for a name with no Function item.
pub(crate) fn func_addr_id(name: &str) -> i32 {
    FUNC_IDS.with(|s| s.borrow().get(name).copied().unwrap_or(0))
}

/// Establish the per-function emit context for `items` (a function body, or the
/// whole program's items for `main` — the walkers skip nested `Function` bodies).
fn set_fn_context(name: &str, items: &[IrItem], params: &[crate::ir::IrParam]) {
    let mut refs = HashSet::new();
    crate::c_emit_hoist::collect_array_refs(items, &mut refs);
    // Array storage comes only from an *array* `Dim`; a name with only a scalar
    // `Dim` but referenced as an array has no `_arr` facet, so it must fold like
    // an undimmed array (dual-use composite member `px3D.shape[i].x`).
    let mut dimmed = HashSet::new();
    crate::c_emit_hoist::collect_array_dimmed_names(items, &mut dimmed);
    for p in params {
        dimmed.insert(p.name.clone());
    }
    let fn_has_gosub = crate::c_emit_hoist::has_gosub(items);
    FN_DYN.with(|s| {
        *s.borrow_mut() = crate::c_emit_hoist::collect_dyn_names(items, params, fn_has_gosub);
    });
    FN_UNDIMMED_ARRAYS.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        set.extend(refs.into_iter().filter(|n| !dimmed.contains(n)));
    });
    FN_LABELS.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        crate::c_emit_hoist::collect_labels(items, &mut set);
    });
    FN_PARAMS.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        set.extend(params.iter().map(|p| p.name.clone()));
    });
    FN_DUAL_USE.with(|s| {
        let mut set = crate::c_emit_hoist::collect_dual_use(items);
        // A name used as both scalar and array splits into a scalar var + a
        // separate `_arr` array. A genuine dual-use PARAM (qbtoxb's `token[]`,
        // also read as a scalar `token = token[i]`) keeps this split: the array
        // param takes the `_arr` name, a local scalar takes the base name. But a
        // *scalar* param only looks array-ish — e.g. String `path$` with
        // `UBOUND(path$)`/`path${i}` byte-ops — and is a single scalar C decl
        // that must NOT split. So drop non-array params from the set. The corpus
        // has no dual-use array param, so this stays byte-neutral there.
        for p in params {
            if !p.is_array {
                set.remove(&p.name);
            }
        }
        *s.borrow_mut() = set;
    });
    FN_ARRAY_DIMS.with(|s| {
        let mut m = s.borrow_mut();
        m.clear();
        crate::c_emit_hoist::collect_array_dims(items, &mut m);
    });
    FN_BYREF_PARAMS.with(|s| {
        let mut v = s.borrow_mut();
        v.clear();
        // By-ref SCALAR params only (call-site driven): a by-ref ARRAY param is
        // already a pointer (its element writes reach the caller directly), so it
        // needs no copy-out. Position i is by-ref iff some call passes `@` there.
        let byref = defined_param_byref(name).unwrap_or_default();
        v.extend(
            params
                .iter()
                .enumerate()
                .filter(|(i, p)| {
                    !p.is_array
                        && byref.get(*i).copied().unwrap_or(false)
                        // Skip a by-ref scalar sharing an array param's name (see
                        // emit_functions): it stays a plain value param, no copy-out.
                        && !params.iter().any(|q| q.is_array && q.name == p.name)
                })
                .map(|(_, p)| (p.name.clone(), p.value_type)),
        );
    });
    GOSUB_RET_SEEN.with(|s| s.borrow_mut().clear());
}

/// Copy-in prologue: `T x = *x_ref;` for each by-ref scalar param, so the body
/// works on a local (unchanged) and the pointer param carries the caller's value.
pub(crate) fn emit_byref_copy_in(out: &mut String, indent: usize) {
    let ind = "    ".repeat(indent);
    FN_BYREF_PARAMS.with(|s| {
        for (name, vt) in s.borrow().iter() {
            let sym = IrSymbol { name: name.clone(), value_type: *vt };
            out.push_str(&ind);
            out.push_str(c_type(*vt));
            out.push(' ');
            crate::c_emit_expr::emit_var_name(&sym, out);
            out.push_str(" = *");
            crate::c_emit_expr::emit_var_name(&sym, out);
            out.push_str("_ref;\n");
        }
    });
}

/// Copy-out epilogue: `*x_ref = x;` for each by-ref scalar param, emitted before
/// every function return so the local's final value reaches the caller (mirrors
/// the interpreter's post-call by-ref write-back).
pub(crate) fn emit_byref_copy_out(out: &mut String, indent: usize) {
    let ind = "    ".repeat(indent);
    FN_BYREF_PARAMS.with(|s| {
        for (name, vt) in s.borrow().iter() {
            let sym = IrSymbol { name: name.clone(), value_type: *vt };
            out.push_str(&ind);
            out.push('*');
            crate::c_emit_expr::emit_var_name(&sym, out);
            out.push_str("_ref = ");
            crate::c_emit_expr::emit_var_name(&sym, out);
            out.push_str(";\n");
        }
    });
}

/// An array referenced in the current function without any `Dim` — reads fold to
/// the type default, `UBOUND` to -1, writes to a discarded evaluation (matching
/// the interpreter's missing-slot semantics; an *executed* write errors there,
/// which only unreached code paths hit in interpreter-clean programs).
pub(crate) fn is_undimmed_array(name: &str) -> bool {
    FN_UNDIMMED_ARRAYS.with(|s| s.borrow().contains(name))
}

/// Whether `name` is used as both a scalar and an array in the current function
/// (see FN_DUAL_USE). Its array identity carries an `_arr` suffix in C.
pub(crate) fn is_dual_use(name: &str) -> bool {
    FN_DUAL_USE.with(|s| s.borrow().contains(name))
}

/// Emit the C name for a symbol used in ARRAY context. Identical to
/// `emit_var_name` except a dual-use name gets an `_arr` suffix so its array
/// storage is a distinct C variable from its scalar (`xb_var_hash_arr`).
pub(crate) fn emit_array_var_name(symbol: &IrSymbol, out: &mut String) {
    crate::c_emit_expr::emit_var_name(symbol, out);
    if is_dual_use(&symbol.name) {
        out.push_str("_arr");
    }
}

/// The `xb_ub_`/dyn-pointer identifier suffix for an array name — `_arr`-tagged
/// for a dual-use name so it matches `emit_array_var_name`.
pub(crate) fn array_ident(name: &str) -> String {
    let base = crate::c_emit_expr::sanitize_c_ident(name);
    if is_dual_use(name) {
        format!("{base}_arr")
    } else {
        base
    }
}

/// The declared dimension-size expressions of a multi-dim array in the current
/// function, or `None` for a 1-D / by-ref / unknown array. Present only for
/// arrays `Dim`'d here with `extra_dims`.
pub(crate) fn array_dims(name: &str) -> Option<Vec<IrExpr>> {
    FN_ARRAY_DIMS.with(|s| s.borrow().get(name).cloned())
}

/// Emit the row-major flat offset for a multi-dim access `arr[i0,i1,…]` given the
/// array's declared dimension-size expressions `dims` (`[d0,d1,…]`). Mirrors the
/// interpreter's flattening (`slot.rs::array_offset`: `off = off*(dk+1) + ik`),
/// i.e. `Σ_k ik · ∏_{m>k}(dm+1)`. Each `dm+1` is the element count of dimension
/// `m` (XBasic `DIM a[n]` has indices `0..=n`).
pub(crate) fn emit_flat_offset(dims: &[IrExpr], indices: &[&IrExpr], out: &mut String) {
    out.push('(');
    for (k, idx) in indices.iter().enumerate() {
        if k > 0 {
            out.push_str(" + ");
        }
        out.push('(');
        crate::c_emit_expr::emit_expr(idx, out);
        out.push(')');
        for d in &dims[k + 1..] {
            out.push_str(" * ((");
            crate::c_emit_expr::emit_expr(d, out);
            out.push_str(")+1)");
        }
    }
    out.push(')');
}

/// Emit the flattened element count `∏_k (dk+1)` for a multi-dim array's storage.
pub(crate) fn emit_flat_size(dims: &[IrExpr], out: &mut String) {
    out.push('(');
    for (k, d) in dims.iter().enumerate() {
        if k > 0 {
            out.push_str(" * ");
        }
        out.push_str("((");
        crate::c_emit_expr::emit_expr(d, out);
        out.push_str(")+1)");
    }
    out.push(')');
}

/// Emit the C subscript for an array access/assignment. For a multi-dim access
/// (`extra_indices` present) whose shape is known locally, emit the row-major
/// flat offset; otherwise emit the single `index` unchanged (1-D, and the
/// byte-identical path for by-ref arrays whose shape isn't visible here — those
/// keep the historical 1-D approximation, matching the shared corpus exactly).
pub(crate) fn emit_array_subscript(
    name: &str,
    index: &IrExpr,
    extra_indices: &[IrExpr],
    out: &mut String,
) {
    if !extra_indices.is_empty() {
        if let Some(dims) = array_dims(name) {
            if dims.len() == 1 + extra_indices.len() {
                let mut indices: Vec<&IrExpr> = Vec::with_capacity(dims.len());
                indices.push(index);
                indices.extend(extra_indices.iter());
                emit_flat_offset(&dims, &indices, out);
                return;
            }
        }
    }
    crate::c_emit_expr::emit_expr(index, out);
}
/// Whether the current C function will contain `xb_label_<name>:`.
pub(crate) fn fn_has_label(name: &str) -> bool {
    FN_LABELS.with(|s| s.borrow().contains(name))
}

/// Whether `name` is a parameter of the current function — a `Dim` of a param
/// name must not re-declare it in C (would be a redefinition).
pub(crate) fn is_fn_param(name: &str) -> bool {
    FN_PARAMS.with(|s| s.borrow().contains(name))
}

/// An array whose `Dim` is late/repeated: declared at function top as a pointer
/// (`<T>* xb_var_x = 0;` + `intptr_t xb_ub_x = -1;`), allocated at the `Dim`.
pub(crate) fn is_dyn_array(name: &str) -> bool {
    FN_DYN.with(|s| s.borrow().arrays.contains_key(name))
}

/// A scalar whose `Dim` is late/repeated: declared at function top, reset at the
/// `Dim` site.
pub(crate) fn is_dyn_scalar(name: &str) -> bool {
    FN_DYN.with(|s| s.borrow().scalars.contains_key(name))
}

/// Emit the hoisted declarations for dynamic names (pointer + upper-bound var per
/// array, plain scalar per scalar). No-op when the sets are empty (the entire
/// shared corpus), keeping CEmitter byte-identical to cgen.x there.
pub(crate) fn emit_dyn_decls(out: &mut String, indent: usize) {
    use crate::c_emit_expr::{emit_default, emit_var_name};
    use crate::ir::IrSymbol;
    let ind = "    ".repeat(indent);
    FN_DYN.with(|s| {
        let dyn_names = s.borrow();
        for (name, vt) in &dyn_names.arrays {
            let sym = IrSymbol { name: name.clone(), value_type: *vt };
            out.push_str(&ind);
            out.push_str(c_type(*vt));
            out.push_str(" *");
            emit_array_var_name(&sym, out);
            out.push_str(" = 0;\n");
            out.push_str(&ind);
            out.push_str("intptr_t xb_ub_");
            out.push_str(&array_ident(name));
            out.push_str(" = -1;\n");
        }
        for (name, vt) in &dyn_names.scalars {
            out.push_str(&ind);
            out.push_str(c_type(*vt));
            out.push(' ');
            emit_var_name(
                &IrSymbol { name: name.clone(), value_type: *vt },
                out,
            );
            out.push_str(" = ");
            emit_default(*vt, out);
            out.push_str(";\n");
        }
    });
}

/// A recognized builtin that has neither a special emitter arm nor a real C
/// helper — its name maps to the `xb_user_` fallback (e.g. a call-form
/// `UBOUND`). The interpreter errors only if such a call executes; call sites
/// yield the zero-default so the program compiles.
pub(crate) fn is_builtin_without_helper(name: &str) -> bool {
    if !crate::is_builtin::is_builtin(name) {
        return false;
    }
    let mut probe = String::new();
    crate::c_emit_helpers::emit_c_function_name(name, &mut probe);
    probe.starts_with("xb_user_")
}

/// Per-site GOSUB return-label suffix: `""` for the first `GOSUB name`, `"_2"`,
/// `"_3"`, … for repeats (C labels must be unique per function).
pub(crate) fn gosub_ret_suffix(name: &str) -> String {
    GOSUB_RET_SEEN.with(|s| {
        let mut map = s.borrow_mut();
        let n = map.entry(name.to_string()).or_insert(0);
        *n += 1;
        if *n == 1 {
            String::new()
        } else {
            format!("_{n}")
        }
    })
}

/// A called name that is neither a user-defined function, a recognized builtin,
/// nor a deferred builtin — i.e. one the C generator would emit as an (undeclared)
/// `xb_user_<name>`. The interpreter (`call.rs`) and the LLVM backend (`lib.rs`)
/// stub these to the zero-default; the C generator does the same at each call site
/// so undefined/external calls (GUI `Xgr*`/`Xui*`, forward-referenced library
/// functions) compile and match byte-for-byte instead of failing `cc`.
pub(crate) fn is_unknown_call(name: &str) -> bool {
    if DEFINED_FUNCS.with(|s| s.borrow().contains(name)) {
        return false;
    }
    // A recognized/deferred builtin has a real runtime impl (or must be left alone
    // rather than replaced by a wrong constant) — never stub it.
    if crate::is_builtin::is_builtin(name) {
        return false;
    }
    // Only names the generator maps to its `xb_user_` fallback are stubbable; a
    // builtin the emitter special-cases (e.g. `READLINE$`) maps to `xb_<name>`.
    let mut probe = String::new();
    crate::c_emit_helpers::emit_c_function_name(name, &mut probe);
    probe.starts_with("xb_user_")
}

pub struct CEmitter;

impl Default for CEmitter {
    fn default() -> Self {
        Self::new()
    }
}

impl CEmitter {
    pub const fn new() -> Self {
        Self
    }

    pub fn emit_program(&self, program: &IrProgram) -> String {
        crate::c_emit_select::reset_select_state();
        set_defined_funcs(program);
        // Bodies first, so usage-gated helpers (xb_inline) can be emitted only
        // when referenced — programs that never use them (the entire shared
        // corpus) stay byte-identical to cgen.x.
        let mut body = String::new();
        emit_globals(program, &mut body);
        emit_forward_decls(program, &mut body);
        emit_functions(program, &mut body);
        emit_main(program, &mut body);
        let mut out = String::new();
        emit_version_global(program, &mut out);
        emit_program_name_global(program, &mut out);
        emit_header(&mut out);
        if body.contains("xb_inline(") {
            // INLINE$: a literal prompt becomes its own output line, then the
            // next stdin line (or "" at EOF) — call.rs "INLINE$".
            out.push_str(
                "static char* xb_inline(const char* prompt) {\n    if (prompt) xb_print_str(prompt);\n    return xb_readline();\n}\n",
            );
        }
        if body.contains("xb_str_n(") {
            // Length-carrying literal constructor for embedded-NUL strings
            // (xb_str/strlen would truncate). Usage-gated: byte-neutral for
            // programs without NUL literals (the entire shared corpus).
            out.push_str(
                "static char* xb_str_n(const char* s, size_t n) { char* d = xb_alloc(n); memcpy(d, s, n); return d; }\n",
            );
        }
        out.push_str(&body);
        out
    }
}

fn emit_functions(program: &IrProgram, out: &mut String) {
    let mut seen = HashSet::new();
    for item in &program.items {
        if let IrItem::Function {
            name,
            params,
            return_type,
            body,
        } = item
        {
            // XBasic forward declarations lower to a duplicate empty definition; the
            // interpreter's find_function resolves the FIRST occurrence, so emit each
            // name once (first-wins) to match and avoid a C redefinition.
            if !seen.insert(name.clone()) {
                continue;
            }
            // Establish the per-function context BEFORE the signature so a
            // dual-use array param is emitted with its `_arr` array name.
            set_fn_context(name, body, params);
            out.push_str(c_type(*return_type));
            out.push_str(" xb_user_");
            out.push_str(name);
            out.push('(');
            if params.is_empty() {
                out.push_str("void");
            }
            let byref = defined_param_byref(name).unwrap_or_default();
            for (i, p) in params.iter().enumerate() {
                if i > 0 {
                    out.push_str(", ");
                }
                // A by-ref SCALAR whose base name is ALSO an array param (Kittedy's
                // `@adjacent, @adjacent[]`) can't take the `_ref` scalar treatment:
                // its copy-in local would collide with the array pointer param. Fall
                // back to a plain value param (the original emission) for that name.
                let p_byref = byref.get(i).copied().unwrap_or(false)
                    && !params.iter().any(|q| q.is_array && q.name == p.name);
                out.push_str(c_type(p.value_type));
                // Array param → pointer (body `p[i]` binds). A by-ref SCALAR param
                // is also a pointer (`x_ref`) with a copied-in local `x`; by-ref is
                // call-site driven (`@arg`), matching the interpreter's write-back
                // (CGEN-BYREF-WRITEBACK). A plain scalar param stays a value.
                out.push_str(if p.is_array || p_byref { " *" } else { " " });
                if p_byref && !p.is_array {
                    emit_var_name(
                        &IrSymbol {
                            name: p.name.clone(),
                            value_type: p.value_type,
                        },
                        out,
                    );
                    out.push_str("_ref");
                } else if p.is_array && is_dual_use(&p.name) {
                    emit_array_var_name(
                        &IrSymbol {
                            name: p.name.clone(),
                            value_type: p.value_type,
                        },
                        out,
                    );
                } else {
                    emit_var_name(
                        &IrSymbol {
                            name: p.name.clone(),
                            value_type: p.value_type,
                        },
                        out,
                    );
                }
                // Duplicate param *C names*: the interpreter's zip-binding writes
                // the slot per name so the LAST occurrence wins; earlier dups get
                // an unused suffixed C name (C forbids duplicate parameters). Two
                // params collide only when they share the emitted name — same raw
                // name AND same string-ness (`v0` Integer and `v0` String map to
                // xb_var_v0 vs xb_str_v0, distinct, so must NOT be renamed).
                let p_str = p.value_type == crate::ValueType::String;
                if params[i + 1..]
                    .iter()
                    .any(|q| q.name == p.name && (q.value_type == crate::ValueType::String) == p_str)
                {
                    out.push_str(&format!("__dup{i}"));
                }
            }
            out.push_str(") {\n");
            emit_byref_copy_in(out, 1);
            crate::c_emit_hoist::emit_hoisted_scalars(body, params, Some(name), out, 1);
            emit_dyn_decls(out, 1);
            if *return_type != ValueType::Integer {
                crate::c_emit_expr::emit_return_var_decl(name, *return_type, out);
            }
            // Isolate this function's GOSUB frames from a caller's: a function-level
            // `RETURN` lowers to `GosubReturn`, which must return from the FUNCTION
            // (not pop a caller's gosub frame off the shared global stack). Capture
            // the entry `sp`; `GosubReturn` pops only while `sp > base` (CGEN-GOSUB-SCOPE).
            if crate::c_emit_hoist::has_gosub(body) {
                out.push_str("    int xb_gosub_base = xb_gosub_sp;\n");
            }
            crate::c_emit_goto::emit_computed_goto_prologue(body, out, 1);
            emit_body(body, out, 1);
            emit_byref_copy_out(out, 1);
            if *return_type != ValueType::Integer {
                emit_fallback_return(name, *return_type, out);
            } else {
                out.push_str("    return 0;\n");
            }
            out.push_str("}\n\n");
        }
    }
}

fn emit_main(program: &IrProgram, out: &mut String) {
    let top: Vec<&IrItem> = program
        .items
        .iter()
        .filter(|i| {
            !matches!(
                i,
                IrItem::Function { .. } | IrItem::Version(_) | IrItem::ProgramName(_)
            )
        })
        .collect();
    // Entry point: mirror IrProgram::entry_or_first("Main") / the interpreter's
    // execute_main — call the `Main` function, or, when absent, the first defined
    // function (legacy XBasic runs the first function, commonly `Entry`). Only a
    // parameterless entry is callable from C `main`.
    let entry = program
        .items
        .iter()
        .find_map(|i| match i {
            IrItem::Function { name, params, .. } if name == "Main" => Some((name, params)),
            _ => None,
        })
        .or_else(|| {
            program.items.iter().find_map(|i| match i {
                IrItem::Function { name, params, .. } => Some((name, params)),
                _ => None,
            })
        });
    out.push_str("int main(void) {\n");
    emit_data_init(program, out);
    set_fn_context("", &program.items, &[]);
    // Top-level scalars (walk_items ignores nested Function bodies).
    crate::c_emit_hoist::emit_hoisted_scalars(&program.items, &[], None, out, 1);
    emit_dyn_decls(out, 1);
    if crate::c_emit_hoist::has_gosub(&program.items) {
        out.push_str("    int xb_gosub_base = xb_gosub_sp;\n");
    }
    crate::c_emit_goto::emit_computed_goto_prologue(&program.items, out, 1);
    emit_body(top, out, 1);
    if let Some((name, params)) = entry {
        if params.is_empty() {
            out.push_str("    xb_user_");
            out.push_str(name);
            out.push_str("();\n");
        }
    }
    out.push_str("    fflush(stdout);\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
}

fn emit_data_init(program: &IrProgram, out: &mut String) {
    for (tag, val) in &program.data_values {
        match tag.as_str() {
            "int" => out.push_str(&format!("    xb_data_add_int({val});\n")),
            "float" => out.push_str(&format!("    xb_data_add_float({val});\n")),
            _ => out.push_str(&format!("    xb_data_add_str(\"{val}\");\n")),
        }
    }
}

fn emit_version_global(program: &IrProgram, out: &mut String) {
    let ver = program
        .items
        .iter()
        .find_map(|i| {
            if let IrItem::Version(v) = i {
                Some(v.as_str())
            } else {
                None
            }
        })
        .unwrap_or("");
    out.push_str(&format!("static const char* xb_version_str = \"{ver}\";\n"));
}

fn emit_program_name_global(program: &IrProgram, out: &mut String) {
    let name = program
        .items
        .iter()
        .find_map(|i| {
            if let IrItem::ProgramName(v) = i {
                Some(v.as_str())
            } else {
                None
            }
        })
        .unwrap_or("");
    out.push_str(&format!(
        "static const char* xb_program_name_str = \"{name}\";\n"
    ));
}

fn emit_fallback_return(name: &str, return_type: ValueType, out: &mut String) {
    let ret_name = name.trim_end_matches('$');
    out.push_str("    return ");
    if return_type == ValueType::String {
        out.push_str("xb_str_");
    } else {
        out.push_str("xb_var_");
    }
    out.push_str(ret_name);
    out.push_str(";\n");
}

pub(crate) fn c_type(vt: ValueType) -> &'static str {
    match vt {
        ValueType::Integer => "intptr_t",
        ValueType::Giant => "int64_t",
        ValueType::Float => "double",
        ValueType::String => "char*",
    }
}
