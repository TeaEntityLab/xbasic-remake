use crate::c_emit_expr::emit_var_name;
use crate::c_emit_select::emit_body;
use crate::c_runtime::{emit_forward_decls, emit_globals, emit_header};
use crate::ir::{IrExpr, IrExprKind, IrItem, IrProgram, IrSymbol};
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
    /// Module-shared arrays (`SHARED a[]`) → element type, program-wide
    /// (CGEN-SHARED-ARR). Dual-use names stay here; the array facet is the
    /// `_arr` heap global (SHARED_DUAL) and the scalar facet is a per-function
    /// local. The interpreter keeps shared arrays in `state.shared` (one
    /// global). cgen.x/v0.1 use no SHARED arrays → byte-neutral on the corpus.
    static SHARED_ARRAYS: RefCell<HashMap<String, crate::ValueType>> = RefCell::new(HashMap::new());
    /// Shared-array names also used as a scalar somewhere. Their global
    /// pointer/`xb_ub_` cell take the `_arr` suffix so emit_globals matches
    /// every access site (xit `lineLast` / `funcAfterAddr`).
    static SHARED_DUAL: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// Per-function emit context: array names referenced but never `Dim`'d in the
    /// current function (auto-vivified — reads fold to the type default like the
    /// interpreter's missing-slot path), and the labels the current C function
    /// will actually contain (a `LabelAddress`/`goto` to any other name would be
    /// an undeclared C label; the interpreter yields 0 / errors only if executed).
    static FN_UNDIMMED_ARRAYS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// MODULE-DIM-SCOPE: names hoisted to file scope by `emit_module_dims` —
    /// count as "dimmed" in every function context so accesses don't fold to
    /// undimmed-array defaults.
    static HOISTED_MODULE_DIMS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
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
    static FN_ARRAY_PARAMS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
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
    static FN_BYREF_PARAMS: RefCell<Vec<(String, ValueType)>> = const { RefCell::new(Vec::new()) };
    /// By-ref String params whose body uses the `$`-suffixed name (collision
    /// case): the copy-out must read from the `_s`-suffixed C variable, not the
    /// copy-in local. Populated by `emit_hoisted_scalars` when a String scalar
    /// whose base name matches a byref param is hoisted with the `$` suffix.
    static FN_BYREF_STR_S: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// By-ref-array descriptor closure (docs/18): fn name → (descriptor params,
    /// must-be-dyn locals). A descriptor param is emitted `(T** xb_var_x_d,
    /// intptr_t* xb_ub_x)`. Populated once per `emit_program`; empty for the corpus.
    #[allow(clippy::type_complexity)]
    static DESC_INFO: RefCell<HashMap<String, (HashSet<String>, HashMap<String, ValueType>)>> = RefCell::new(HashMap::new());
    /// The current function's descriptor array params (subset of DESC_INFO).
    static FN_DESC: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
    /// Per-param descriptor flag per function (positional), so a call site passes
    /// the descriptor form at a descriptor position.
    static DEFINED_PARAM_DESC: RefCell<HashMap<String, Vec<bool>>> = RefCell::new(HashMap::new());
    /// The current function's composite return type name (e.g. `DCOMPLEX`), if any.
    /// Set per-function by `set_fn_context`; read by the Return emitter to
    /// assemble the struct from member variables before returning.
    static FN_COMPOSITE_RET: RefCell<Option<String>> = const { RefCell::new(None) };
    /// The current function's name (for use in Return emission).
    static FN_NAME: RefCell<String> = const { RefCell::new(String::new()) };
    /// Map from function name to composite return type name, for functions
    /// that return a composite (e.g. DCOMPLEX). Populated once per `emit_program`.
    static DEFINED_COMPOSITE_RET: RefCell<HashMap<String, String>> = RefCell::new(HashMap::new());
    /// When true, suppress `.R` extraction on composite-returning calls
    /// (the assignment handler needs the full struct, not just .R).
    static SUPPRESS_COMP_R: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

/// Record every user-defined function name for `program`. Called once per
/// `emit_program` before any body is emitted.
fn set_defined_funcs(program: &IrProgram) {
    DEFINED_FUNCS.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        for item in &program.items {
            if let IrItem::Function { name, body, .. } = item {
                // EXTERNAL FUNCTION declarations for recognized builtins
                // (SQRT, SIN, COS, EXP, etc.) have empty bodies. Skip them
                // so call sites use the C runtime helper (xb_sqrt, xb_sin)
                // instead of a zero-returning weak stub (xb_user_SQRT).
                if body.is_empty() && crate::is_builtin::is_builtin(name) {
                    continue;
                }
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
        // Fallback for functions with NO callsites in the compiled unit:
        // use DECLARE `@` markers from the program's `declare_byref` map.
        // Only insert when at least one param has `@` — a DECLARE with no
        // @ markers carries no byref info and should not block the env var
        // fallback for any future legacy source bugs.
        for (fname, flags) in &program.declare_byref {
            if !m.contains_key(fname) && flags.iter().any(|&f| f) {
                m.insert(fname.clone(), flags.clone());
            }
        }
        if let Ok(hints) = std::env::var("XB_BYREF_HINTS") {
            for entry in hints.split(';') {
                let parts: Vec<&str> = entry.splitn(2, ':').collect();
                if parts.len() != 2 {
                    continue;
                }
                let fname = parts[0];
                let positions: Vec<bool> = parts[1].split(',').map(|s| s.trim() == "1").collect();
                if !m.contains_key(fname) {
                    m.insert(fname.to_string(), positions);
                }
            }
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
    DESC_INFO.with(|s| {
        *s.borrow_mut() = crate::c_emit_hoist::collect_descriptor_params(program);
    });
    DEFINED_PARAM_DESC.with(|s| {
        let mut m = s.borrow_mut();
        m.clear();
        let info = DESC_INFO.with(|r| r.borrow().clone());
        for item in &program.items {
            if let IrItem::Function { name, params, .. } = item {
                m.entry(name.clone()).or_insert_with(|| {
                    let d = info.get(name).map(|(x, _)| x.clone()).unwrap_or_default();
                    params
                        .iter()
                        .map(|p| p.is_array && d.contains(&p.name))
                        .collect()
                });
            }
        }
    });
    DEFINED_COMPOSITE_RET.with(|s| {
        let mut m = s.borrow_mut();
        m.clear();
        for item in &program.items {
            if let IrItem::Function {
                name,
                return_type_name: Some(tn),
                ..
            } = item
            {
                if tn == "DCOMPLEX" || tn == "SCOMPLEX" {
                    m.entry(name.clone()).or_insert_with(|| tn.clone());
                }
            }
        }
    });
    SHARED_ARRAYS.with(|s| {
        let mut m = s.borrow_mut();
        m.clear();
        collect_shared_arrays(&program.items, &mut m);
        // System shared arrays (ARCH-02): ##ARGV$[], ##ENVP$[], ##REG[] are
        // runtime-provided but never DIM'd with SHARED. If the program references
        // them, seed them as shared so they get a file-scope heap global rather
        // than folding to defaults. Only seed if referenced to keep symbol count
        // stable for programs that don't use them.
        for (sys_name, sys_vt) in [
            ("ARGV$", crate::ValueType::String),
            ("ENVP$", crate::ValueType::String),
            ("REG", crate::ValueType::Integer),
        ] {
            if !m.contains_key(sys_name) && program_references_array(sys_name, &program.items) {
                m.insert(sys_name.to_string(), sys_vt);
            }
        }
        // Dual-use SHARED arrays stay heap globals (xit `lineLast[255]` /
        // `funcAfterAddr[255]`). Dropping them emitted a per-function
        // `intptr_t` stack/scalar plus `calloc` into that scalar. The sized
        // DIM is often nested in an EXTERNAL function body, so a top-level
        // keep-gate missed them. The array facet takes `_arr` (SHARED_DUAL)
        // so a local scalar still type-checks.
        if !m.is_empty() {
            let mut dual = std::collections::HashSet::new();
            collect_program_dual_use(&program.items, &mut dual);
            if std::env::var_os("XB_DEBUG_SHARED").is_some() {
                for (k, v) in m.iter() {
                    if k.contains("varData") || k.contains("nameList") {
                        eprintln!("IN-SHARED {} {:?} dual={}", k, v, dual.contains(k));
                    }
                }
            }
            // TYPE string *array members* (`HOST.alias[2]`): scalar DIM from
            // `DIM host:HOST` plus `host.alias[0]` in the same function.
            // Those are one `char**`, not a dual-use `char*` + `_arr`.
            // TYPE string *scalar* members (`HOST.name`) are only dual across
            // functions and still split. Integer dotted dual-use (xit
            // lineLast, host.addresses) is unchanged.
            let member_arr = collect_type_string_array_members(&program.items);
            SHARED_DUAL.with(|d| {
                d.borrow_mut().extend(
                    m.keys()
                        .filter(|n| dual.contains(*n) && !member_arr.contains(*n))
                        .cloned(),
                );
            });

            // Composite-member dual-use gate: a shared array member (dotted name)
            // that is ALSO DIM'd as a SCALAR anywhere — a scalar composite
            // `HOST host` vs an array composite `SHARED HOST host[]` both flatten
            // `host.address`. A global pointer coexists with scalar uses because
            // the local scalar declaration shadows the global in C (different
            // scopes, different types — valid). No function uses the same
            // composite member as both a parameter and a shared array (verified
            // for xin/xgr/xst). So only exclude NON-dotted names (true dual-use
            // scalar+array of one bare name); dotted composite members stay in
            // SHARED_ARRAYS and get a global decl (CGEN-SHARED-COMPOSITE).
            // However, a bare shared array that IS dual-use (scalar + array
            // facets, e.g. xui `gridType$`/`gridName$` with `STATIC` scalar in
            // AppearanceCode and `SHARED` array elsewhere) must stay as a
            // `_arr`-suffixed global (docs/18, xit lineLast) — otherwise the
            // array facet would be considered undimmed and mis-emitted as
            // `xb_setch` (xui CleanGridInfoArrays regression).
            let mut scalar_dimmed = std::collections::HashSet::new();
            collect_scalar_dimmed_names(&program.items, &mut scalar_dimmed);
            m.retain(|name, _| {
                !scalar_dimmed.contains(name) || name.contains('.') || dual.contains(name)
            });
            SHARED_DUAL.with(|d| d.borrow_mut().retain(|n| m.contains_key(n)));
        }
    });
}

/// Check if a function is user-defined in the current translation unit.
/// Used by RR-07 binding policy: native helpers only shadow when the
/// function is NOT user-defined, so compiled legacy bodies take precedence.
pub(crate) fn is_defined_func(name: &str) -> bool {
    DEFINED_FUNCS.with(|s| s.borrow().contains(name))
}

/// Recursively collect module-shared array names (`Dim { shared, is_array }`,
/// i.e. `SHARED a[]`) → element type, across function bodies and nested blocks.
fn collect_shared_arrays(items: &[IrItem], out: &mut HashMap<String, crate::ValueType>) {
    for item in items {
        match item {
            IrItem::Dim {
                symbol,
                is_array: true,
                shared: true,
                ..
            } => {
                out.entry(symbol.name.clone()).or_insert(symbol.value_type);
            }
            IrItem::Function { body, .. } => collect_shared_arrays(body, out),
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_shared_arrays(then_body, out);
                if let Some(eb) = else_body {
                    collect_shared_arrays(eb, out);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_shared_arrays(body, out)
            }
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_shared_arrays(&c.body, out);
                }
                if let Some(d) = default {
                    collect_shared_arrays(d, out);
                }
            }
            IrItem::Compound(items) => collect_shared_arrays(items, out),
            _ => {}
        }
    }
}
/// True if `name` is referenced as an array (ArrayAccess/ArrayUBound/SizeOf)
/// anywhere in `items` (including nested function bodies). Used to seed
/// system shared arrays like `ARGV$` that are never `Dim SHARED` but are
/// accessed as `##ARGV$[]`.
fn program_references_array(name: &str, items: &[IrItem]) -> bool {
    for item in items {
        if item_references_array(name, item) {
            return true;
        }
        match item {
            IrItem::Function { body, .. } => {
                if program_references_array(name, body) {
                    return true;
                }
            }
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                if program_references_array(name, then_body) {
                    return true;
                }
                if let Some(eb) = else_body {
                    if program_references_array(name, eb) {
                        return true;
                    }
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                if program_references_array(name, body) {
                    return true;
                }
            }
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    if program_references_array(name, &c.body) {
                        return true;
                    }
                }
                if let Some(d) = default {
                    if program_references_array(name, d) {
                        return true;
                    }
                }
            }
            IrItem::Compound(inner) => {
                if program_references_array(name, inner) {
                    return true;
                }
            }
            _ => {}
        }
    }
    false
}
fn expr_references_array(name: &str, expr: &crate::ir::IrExpr) -> bool {
    match &expr.kind {
        crate::ir::IrExprKind::ArrayAccess { symbol, .. }
        | crate::ir::IrExprKind::ArrayUBound { symbol }
        | crate::ir::IrExprKind::SizeOf { symbol } => symbol.name == name,
        crate::ir::IrExprKind::FunctionCall { args, .. } => {
            args.iter().any(|a| expr_references_array(name, a))
        }
        crate::ir::IrExprKind::Comparison { left, right, .. } => {
            expr_references_array(name, left) || expr_references_array(name, right)
        }
        crate::ir::IrExprKind::Arithmetic { left, right, .. } => {
            expr_references_array(name, left) || expr_references_array(name, right)
        }
        crate::ir::IrExprKind::Unary { operand, .. } => expr_references_array(name, operand),
        crate::ir::IrExprKind::Not(inner) => expr_references_array(name, inner),
        crate::ir::IrExprKind::Boolean { left, right, .. }
        | crate::ir::IrExprKind::Logical { left, right, .. } => {
            expr_references_array(name, left) || expr_references_array(name, right)
        }
        crate::ir::IrExprKind::ByRef(inner) => expr_references_array(name, inner),
        _ => false,
    }
}
fn item_references_array(name: &str, item: &IrItem) -> bool {
    match item {
        IrItem::Assignment { target, value } => {
            target.name == name || expr_references_array(name, value)
        }
        IrItem::ArrayAssignment {
            target,
            index,
            extra_indices,
            value,
        } => {
            target.name == name
                || expr_references_array(name, index)
                || extra_indices.iter().any(|e| expr_references_array(name, e))
                || expr_references_array(name, value)
        }
        IrItem::If { condition, .. } => expr_references_array(name, condition),
        IrItem::While { condition, .. } => expr_references_array(name, condition),
        IrItem::For {
            start, end, step, ..
        } => {
            expr_references_array(name, start)
                || expr_references_array(name, end)
                || step
                    .as_ref()
                    .is_some_and(|s| expr_references_array(name, s))
        }
        IrItem::DoLoop {
            pre_condition,
            post_condition,
            ..
        } => {
            pre_condition
                .as_ref()
                .is_some_and(|(c, _)| expr_references_array(name, c))
                || post_condition
                    .as_ref()
                    .is_some_and(|(c, _)| expr_references_array(name, c))
        }
        IrItem::SelectCase { selector, .. } => expr_references_array(name, selector),
        IrItem::Return { value } => value
            .as_ref()
            .is_some_and(|v| expr_references_array(name, v)),
        IrItem::Call { args, .. } => args.iter().any(|a| expr_references_array(name, a)),
        IrItem::Swap { left, right } => left.name == name || right.name == name,
        IrItem::SharedAssignment { target, value } => {
            target.name == name || expr_references_array(name, value)
        }
        IrItem::BuiltinAssign { args, value, .. } => {
            args.iter().any(|a| expr_references_array(name, a))
                || expr_references_array(name, value)
        }
        _ => false,
    }
}

/// Recursively collect names DIM'd as a SCALAR (`Dim { is_array: false }`), across
/// function bodies + nested blocks — for the CGEN-SHARED-ARR composite-member gate
/// (a name that is both a scalar composite member and a shared array member must
/// not become a global pointer).
fn collect_scalar_dimmed_names(items: &[IrItem], out: &mut HashSet<String>) {
    for item in items {
        match item {
            // Keyword-`SHARED` scalars are program storage (`xb_shared_<n>`):
            // they must NOT suppress other functions' auto-local hoisting of
            // the same name (xui's `window` is SHARED in one function and a
            // plain auto-local in several others).
            IrItem::Dim {
                symbol: _,
                is_array: false,
                shared: true,
                ..
            } => {}
            IrItem::Dim {
                symbol,
                is_array: false,
                ..
            } => {
                out.insert(symbol.name.clone());
            }
            IrItem::Function { body, .. } => collect_scalar_dimmed_names(body, out),
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_scalar_dimmed_names(then_body, out);
                if let Some(eb) = else_body {
                    collect_scalar_dimmed_names(eb, out);
                }
            }
            IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } => {
                collect_scalar_dimmed_names(body, out)
            }
            IrItem::SelectCase { cases, default, .. } => {
                for c in cases {
                    collect_scalar_dimmed_names(&c.body, out);
                }
                if let Some(d) = default {
                    collect_scalar_dimmed_names(d, out);
                }
            }
            IrItem::Compound(items) => collect_scalar_dimmed_names(items, out),
            _ => {}
        }
    }
}

/// Union of dual-use names (used as both scalar and array) across every function
/// body + the top level, for the CGEN-SHARED-ARR gate. Uses an empty forced-array
/// set: a conservative over-approximation (over-detecting only excludes more
/// shared arrays from the global treatment — always safe).
fn collect_program_dual_use(items: &[IrItem], out: &mut HashSet<String>) {
    let empty = HashSet::new();
    // Top-level (non-function) items.
    for n in crate::c_emit_hoist::collect_dual_use(items, &empty) {
        out.insert(n);
    }
    // Per-function scan: detects dual-use *within* a single function.
    for item in items {
        if let IrItem::Function { body, .. } = item {
            for n in crate::c_emit_hoist::collect_dual_use(body, &empty) {
                out.insert(n);
            }
        }
    }
    // Cross-function scan: a shared array used as a scalar in function A and
    // as an array in function B is dual-use at the program level. Flatten all
    // function bodies into one list so collect_dual_use sees both facets.
    let mut all_body_refs: Vec<&IrItem> = Vec::new();
    for item in items {
        if let IrItem::Function { body, .. } = item {
            all_body_refs.extend(body.iter());
        }
    }
    let all_body_items: Vec<IrItem> = all_body_refs.iter().map(|r| (*r).clone()).collect();
    for n in crate::c_emit_hoist::collect_dual_use(&all_body_items, &empty) {
        out.insert(n);
    }
}

/// True if `name` is a module-shared array emitted as one heap global rather
/// than a per-function local (CGEN-SHARED-ARR). Dual-use names are included;
/// their array facet uses `_arr` (`is_shared_dual`).
pub(crate) fn is_shared_array(name: &str) -> bool {
    SHARED_ARRAYS.with(|s| s.borrow().contains_key(name))
}

/// True if `name` is a shared array that is also used as a scalar somewhere
/// in the program — the global pointer/`xb_ub_` cell are `_arr`-suffixed.
pub(crate) fn is_shared_dual(name: &str) -> bool {
    SHARED_DUAL.with(|s| s.borrow().contains(name))
}

/// Dotted STRING shared array (`HOST.alias$[]`): one `char**` global, never a
/// dual-use `char*` scalar. `host.alias[0]` must be `char*`, not `char`.
pub(crate) fn is_shared_string_array(name: &str) -> bool {
    name.contains('.')
        && SHARED_ARRAYS.with(|s| s.borrow().get(name).copied() == Some(crate::ValueType::String))
}

/// Array-facet C name takes `_arr` when a scalar facet of the same name exists.
fn array_needs_arr_suffix(name: &str) -> bool {
    is_shared_dual(name) || (is_dual_use(name) && !is_shared_array(name))
}

/// The shared arrays (name, element type), sorted by name for a deterministic
/// global-declaration order.
pub(crate) fn shared_arrays_sorted() -> Vec<(String, crate::ValueType)> {
    SHARED_ARRAYS.with(|s| {
        let mut v: Vec<(String, crate::ValueType)> =
            s.borrow().iter().map(|(k, t)| (k.clone(), *t)).collect();
        v.sort_by(|a, b| a.0.cmp(&b.0));
        v
    })
}

/// Record, per callee position, whether an `@arg` (`ByRef`) and/or a by-value arg
/// is ever passed there, across every call site in the program. A param is by-ref
/// (a C pointer with copy-in/copy-out) iff `seen_byref && !seen_byval` - the
/// call-site-driven model the interpreter uses, restricted to positions that are
#[allow(clippy::collapsible_match)]
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
            K::ArrayAccess {
                index,
                extra_indices,
                ..
            } => {
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
            IrItem::Dim {
                size, extra_dims, ..
            } => {
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
            IrItem::ArrayAssignment {
                index,
                extra_indices,
                value,
                ..
            } => {
                walk_expr(index, m);
                for x in extra_indices {
                    walk_expr(x, m);
                }
                walk_expr(value, m);
            }
            IrItem::MidAssign {
                target,
                start,
                length,
                value,
            } => {
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
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
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
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => {
                if let Some((e, _)) = pre_condition {
                    walk_expr(e, m);
                }
                if let Some((e, _)) = post_condition {
                    walk_expr(e, m);
                }
                collect_callsite_byref(body, m);
            }
            IrItem::For {
                start,
                end,
                step,
                body,
                ..
            } => {
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
            IrItem::SelectCase {
                selector,
                cases,
                default,
            } => {
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
pub(crate) fn set_fn_context(
    name: &str,
    items: &[IrItem],
    params: &[crate::ir::IrParam],
    return_type_name: Option<&str>,
) {
    let mut refs = HashSet::new();
    crate::c_emit_hoist::collect_array_refs(items, &mut refs);
    // Array storage comes only from an *array* `Dim`; a name with only a scalar
    // `Dim` but referenced as an array has no `_arr` facet, so it must fold like
    // an undimmed array (dual-use composite member `px3D.shape[i].x`).
    let mut dimmed = HashSet::new();
    crate::c_emit_hoist::collect_array_dimmed_names(items, &mut dimmed);
    HOISTED_MODULE_DIMS.with(|h| dimmed.extend(h.borrow().iter().cloned()));
    for p in params {
        if p.is_array {
            dimmed.insert(p.name.clone());
        }
    }
    let fn_has_gosub = crate::c_emit_hoist::has_gosub(items);
    let (descriptors, descriptor_locals) =
        DESC_INFO.with(|s| s.borrow().get(name).cloned().unwrap_or_default());
    FN_DESC.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        set.extend(descriptors.iter().cloned());
    });
    FN_COMPOSITE_RET.with(|s| {
        *s.borrow_mut() = return_type_name
            .filter(|tn| *tn == "DCOMPLEX" || *tn == "SCOMPLEX")
            .map(|tn| tn.to_string());
    });
    FN_NAME.with(|s| {
        *s.borrow_mut() = name.to_string();
    });
    FN_DYN.with(|s| {
        let mut dyn_names =
            crate::c_emit_hoist::collect_dyn_names(items, params, fn_has_gosub, &descriptor_locals);
        // Descriptor-forward names (`@x[]` into a callee descriptor-array
        // position): the call site emits `&x, &xb_ub_x`, so the caller needs
        // the pointer+ubound pair declared even with no `Dim`. Adding to
        // `arrays` also makes the scalar hoist skip the plain-scalar facet
        // (no redefinition). Corpus has no such call → byte-neutral.
        let mut fwd: Vec<(String, ValueType)> = Vec::new();
        crate::c_emit_hoist::collect_descriptor_forwards(items, &mut fwd);
        let param_names: HashSet<&str> = params.iter().map(|p| p.name.as_str()).collect();
        for (n, vt) in fwd {
            if dyn_names.arrays.contains_key(&n)
                || param_names.contains(n.as_str())
                || is_shared_array(&n)
            {
                continue;
            }
            dyn_names.arrays.entry(n).or_insert(vt);
        }
        *s.borrow_mut() = dyn_names;
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
    GOSUB_RET_SEEN.with(|s| s.borrow_mut().clear());
    FN_PARAMS.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        set.extend(params.iter().map(|p| p.name.clone()));
    });
    FN_ARRAY_PARAMS.with(|s| {
        let mut set = s.borrow_mut();
        set.clear();
        set.extend(params.iter().filter(|p| p.is_array).map(|p| p.name.clone()));
    });
    let peel_host_str = FN_DUAL_USE.with(|s| {
        let forced_array: HashSet<String> = descriptors
            .iter()
            .cloned()
            .chain(descriptor_locals.keys().cloned())
            .collect();
        let mut set = crate::c_emit_hoist::collect_dual_use(items, &forced_array);
        // A name used as both scalar and array splits into a scalar var + a
        // separate `_arr` array. A genuine dual-use PARAM (qbtoxb's `token[]`,
        // also read as a scalar `token = token[i]`) keeps this split: the array
        // param takes the `_arr` name, a local scalar takes the base name. But a
        // *scalar* param only looks array-ish — e.g. String `path$` with
        // `UBOUND(path$)`/`path${i}` byte-ops — and is a single scalar C decl
        // that must NOT split. So drop non-array params from the set. The corpus
        // has no dual-use array param, so this stays byte-neutral there.
        for p in params {
            // Only drop STRING non-array params: a scalar string param with
            // `path${i}`/`UBOUND(path$)` byte-ops looks array-ish but is a
            // single scalar C decl that must NOT split. A non-string scalar
            // param with a real `ArrayAccess` (xcol's `GOSUB @mode[mode]`)
            // IS genuinely dual-use and must split into scalar + _arr.
            // Exception: if the name also has a non-string array DIM (xgr's
            // `def:string` + `dim def:integer[80]`), the integer facet IS
            // genuinely dual-use — don't drop.
            if !p.is_array
                && p.value_type == ValueType::String
                && array_dim_type(items, &p.name).is_none()
            {
                set.remove(&p.name);
            }
        }
        // HOST TYPE string array members (`alias$[]`) are `char**`, not a
        // dual-use `char*` + `_arr`. Indexing the scalar makes `[0]` a char.
        let peel: Vec<String> = set
            .iter()
            .filter(|n| {
                n.contains('.') && (is_shared_string_array(n) || has_string_scalar_dim(items, n))
            })
            .cloned()
            .collect();
        for n in &peel {
            set.remove(n);
        }
        *s.borrow_mut() = set;
        peel
    });
    FN_DYN.with(|dyn_s| {
        let mut dyn_names = dyn_s.borrow_mut();
        for n in &peel_host_str {
            dyn_names
                .arrays
                .entry(n.clone())
                .or_insert(ValueType::String);
        }
    });
    // A dual-use SCALAR param (xcol's `mode` used as `GOSUB @mode[mode]`) needs
    // its array facet (`_arr`) declared as a dyn array. The scalar facet is the
    // param itself; the array facet is a local heap pointer + ubound cell.
    // But if the same name also has an ARRAY param (Kittedy's `adjacent` has
    // both `adjacent:integer` and `adjacent:integer[]`), the array facet is
    // already declared in the signature — skip the injection.
    let array_param_names: HashSet<String> = params
        .iter()
        .filter(|p| p.is_array)
        .map(|p| p.name.clone())
        .collect();
    FN_DUAL_USE.with(|dual| {
        let dual_set = dual.borrow();
        FN_DYN.with(|dyn_s| {
            let mut dyn_names = dyn_s.borrow_mut();
            for p in params {
                if !p.is_array && dual_set.contains(&p.name) && !array_param_names.contains(&p.name)
                {
                    // Use the array DIM's type, not the param's type: a STRING
                    // param (xgr's `def:string`) with a separate INTEGER array
                    // DIM (`def:integer[80]`) needs `intptr_t *xb_var_def_arr`,
                    // not `char** xb_str_def_arr`.
                    let arr_vt = array_dim_type(items, &p.name).unwrap_or(p.value_type);
                    dyn_names.arrays.entry(p.name.clone()).or_insert(arr_vt);
                }
            }
        });
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
    FN_BYREF_STR_S.with(|s| s.borrow_mut().clear());
}

/// Copy-in prologue: `T x = *x_ref;` for each by-ref scalar param, so the body
/// works on a local (unchanged) and the pointer param carries the caller's value.
pub(crate) fn emit_byref_copy_in(out: &mut String, indent: usize) {
    let ind = "    ".repeat(indent);
    FN_BYREF_PARAMS.with(|s| {
        for (name, vt) in s.borrow().iter() {
            let sym = IrSymbol {
                name: name.clone(),
                value_type: *vt,
            };
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
            // For String byref params with a name collision (e.g. `error` Integer
            // + `error$` String), the body uses the `$`-suffixed name (`error$` →
            // `xb_str_error_s`), while the copy-in uses the bare param name
            // (`error` → `xb_str_error`). The copy-out must read from the `_s`
            // variable to pick up the body's writes.
            let read_name = if *vt == crate::ValueType::String
                && FN_BYREF_STR_S.with(|s| s.borrow().contains(name))
            {
                format!("{}$", name)
            } else {
                name.clone()
            };
            let ref_sym = IrSymbol {
                name: name.clone(),
                value_type: *vt,
            };
            let read_sym = IrSymbol {
                name: read_name,
                value_type: *vt,
            };
            out.push_str(&ind);
            out.push('*');
            crate::c_emit_expr::emit_var_name(&ref_sym, out);
            out.push_str("_ref = ");
            crate::c_emit_expr::emit_var_name(&read_sym, out);
            out.push_str(";\n");
        }
    });
}

/// Record that a byref String param's body uses the `$`-suffixed name (the
pub(crate) fn record_byref_str_s(base_name: &str) {
    FN_BYREF_STR_S.with(|s| {
        s.borrow_mut().insert(base_name.to_owned());
    });
}

/// Whether `base_name` is a byref String param of the current function.
pub(crate) fn is_byref_str_param(base_name: &str) -> bool {
    FN_BYREF_PARAMS.with(|s| {
        s.borrow()
            .iter()
            .any(|(n, vt)| n == base_name && *vt == crate::ValueType::String)
    })
}
/// An array referenced in the current function without any `Dim` — reads fold to
/// the type default, `UBOUND` to -1, writes to a discarded evaluation (matching
/// the interpreter's missing-slot semantics; an *executed* write errors there,
/// which only unreached code paths hit in interpreter-clean programs).
pub(crate) fn is_undimmed_array(name: &str) -> bool {
    // A module-shared array is a global (emit_globals), available in any function
    // even one that only reads it (no local `Dim`) — never "undimmed" (must not
    // fold to defaults). CGEN-SHARED-ARR.
    // Descriptor by-ref array params (`@a[]` → `T** data_d + ub`) have backing
    // storage via the caller and must not fold to type defaults; check before
    // FN_UNDIMMED_ARRAYS (ARCH-01, c_emit_expr.rs ArrayAccess asymmetry).
    !is_shared_array(name)
        && !is_descriptor_param(name)
        && FN_UNDIMMED_ARRAYS.with(|s| s.borrow().contains(name))
}

/// Whether `name` is used as both a scalar and an array in the current function
/// (see FN_DUAL_USE). Its array identity carries an `_arr` suffix in C.
pub(crate) fn is_dual_use(name: &str) -> bool {
    FN_DUAL_USE.with(|s| s.borrow().contains(name))
}

/// True if `name` is a by-ref-array descriptor param of the current function —
/// emitted `(T** xb_var_x_d, intptr_t* xb_ub_x)` with accesses `(*xb_var_x_d)[i]`,
/// `UBOUND` `*xb_ub_x`, `REDIM` via realloc (docs/18).
pub(crate) fn is_descriptor_param(name: &str) -> bool {
    FN_DESC.with(|s| s.borrow().contains(name))
}

/// The raw C array name `xb_var_x`/`xb_str_x` (+`_arr` if dual-use), WITHOUT the
/// descriptor deref — used to build the `_d` descriptor names + param decls.
pub(crate) fn emit_raw_array_name(symbol: &IrSymbol, out: &mut String) {
    crate::c_emit_expr::emit_var_name(symbol, out);
    // Dual-use shared arrays (xit `lineLast`) keep a local scalar `xb_var_x`
    // and a file-scope pointer `xb_var_x_arr`. Non-dual shared arrays stay
    // unsuffixed. Dotted STRING members are not shared-dual, so they keep
    // the unsuffixed `char**` global (`host.alias`).
    if array_needs_arr_suffix(&symbol.name) {
        out.push_str("_arr");
    }
}

/// Emit the C name for a symbol used in ARRAY context. A descriptor param derefs
/// its data pointer `(*xb_var_x_d)`; a dual-use name gets an `_arr` suffix so its
/// array storage is a distinct C variable from its scalar (`xb_var_hash_arr`).
pub(crate) fn emit_array_var_name(symbol: &IrSymbol, out: &mut String) {
    if is_descriptor_param(&symbol.name) {
        out.push_str("(*");
        crate::c_emit_expr::emit_var_name(symbol, out);
        out.push_str("_dd)");
        return;
    }
    emit_raw_array_name(symbol, out);
}

/// Emit a reference to an array's ubound cell: `(*xb_ub_x)` for a descriptor param,
/// else `xb_ub_<ident>` (a dyn local's tracked bound).
pub(crate) fn emit_array_ub_ref(name: &str, out: &mut String) {
    if is_descriptor_param(name) {
        out.push_str("(*xb_ub_");
        out.push_str(&crate::c_emit_expr::sanitize_c_ident(name));
        out.push(')');
    } else {
        out.push_str("xb_ub_");
        out.push_str(&array_ident(name));
    }
}

/// The `xb_ub_`/dyn-pointer identifier suffix for an array name — `_arr`-tagged
/// for a dual-use name so it matches `emit_array_var_name`.
pub(crate) fn array_ident(name: &str) -> String {
    let base = crate::c_emit_expr::sanitize_c_ident(name);
    if array_needs_arr_suffix(name) {
        format!("{base}_arr")
    } else {
        base
    }
}

/// The descriptor data-pointer name for a by-ref-array param: `xb_var_x_d` /
/// `xb_str_x_d` (a `T**`). Raw (no deref) — for decls + call-site forwarding.
pub(crate) fn emit_descriptor_data_ptr(symbol: &IrSymbol, out: &mut String) {
    crate::c_emit_expr::emit_var_name(symbol, out);
    out.push_str("_dd");
}

/// The descriptor ubound identifier `xb_ub_<name>` (an `intptr_t*` param).
pub(crate) fn descriptor_ub_ident(name: &str) -> String {
    format!("xb_ub_{}", crate::c_emit_expr::sanitize_c_ident(name))
}

/// Emit the two C params for a descriptor by-ref array param `p`:
/// `T **xb_var_p_d, intptr_t *xb_ub_p` (docs/18).
pub(crate) fn emit_descriptor_param_decl(p: &crate::ir::IrParam, out: &mut String) {
    let sym = IrSymbol {
        name: p.name.clone(),
        value_type: p.value_type,
    };
    out.push_str(c_type(p.value_type));
    out.push_str(" **");
    emit_descriptor_data_ptr(&sym, out);
    out.push_str(", intptr_t *");
    out.push_str(&descriptor_ub_ident(&p.name));
}

/// The descriptor array params of `name` (from the program analysis), keyed by
/// function name — usable during signature/forward-decl emission before the
/// per-function `FN_DESC` context is set.
pub(crate) fn fn_descriptor_params(name: &str) -> HashSet<String> {
    DESC_INFO.with(|s| {
        s.borrow()
            .get(name)
            .map(|(d, _)| d.clone())
            .unwrap_or_default()
    })
}

/// Per-param descriptor flags of a user-defined callee, so a call site passes the
/// 2-arg descriptor at a descriptor position (docs/18).
pub(crate) fn defined_param_descriptor(name: &str) -> Option<Vec<bool>> {
    DEFINED_PARAM_DESC.with(|s| s.borrow().get(name).cloned())
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
    if index.value_type == ValueType::Float {
        out.push_str("(intptr_t)(");
        crate::c_emit_expr::emit_expr(index, out);
        out.push(')');
    } else {
        crate::c_emit_expr::emit_expr(index, out);
    }
}
/// Whether the current C function will contain `xb_label_<name>:`.
pub(crate) fn fn_has_label(name: &str) -> bool {
    FN_LABELS.with(|s| s.borrow().contains(name))
}

/// The current function's name, for use in Return emission.
pub(crate) fn current_fn_name() -> Option<String> {
    FN_NAME.with(|s| {
        let name = s.borrow();
        if name.is_empty() {
            None
        } else {
            Some(name.clone())
        }
    })
}

/// The current function's composite return type name, if any.
pub(crate) fn current_composite_ret() -> Option<String> {
    FN_COMPOSITE_RET.with(|s| s.borrow().clone())
}

/// The composite return type name of a user-defined function, if any.
pub(crate) fn func_return_composite(name: &str) -> Option<String> {
    DEFINED_COMPOSITE_RET.with(|s| s.borrow().get(name).cloned())
}

pub(crate) fn is_suppress_comp_r() -> bool {
    SUPPRESS_COMP_R.with(|s| s.get())
}

/// Whether `name` is a parameter of the current function — a `Dim` of a param
/// name must not re-declare it in C (would be a redefinition).
pub(crate) fn is_fn_param(name: &str) -> bool {
    FN_PARAMS.with(|s| s.borrow().contains(name))
}

/// True if `name` is an `is_array` parameter of the current function.
pub(crate) fn is_array_param(name: &str) -> bool {
    FN_ARRAY_PARAMS.with(|s| s.borrow().contains(name))
}

pub(crate) fn next_comp_tmp_id() -> usize {
    static COUNTER: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);
    COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed)
}

/// An array whose `Dim` is late/repeated: declared at function top as a pointer
/// (`<T>* xb_var_x = 0;` + `intptr_t xb_ub_x = -1;`), allocated at the `Dim`.
pub(crate) fn is_dyn_array(name: &str) -> bool {
    // A module-shared array is a heap global (dyn pointer), so it always takes the
    // realloc/pointer path — never a stack fixed array (CGEN-SHARED-ARR).
    is_shared_array(name) || FN_DYN.with(|s| s.borrow().arrays.contains_key(name))
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
            // A module-shared array is emitted ONCE as a global (emit_globals),
            // never as a per-function local (CGEN-SHARED-ARR).
            if is_shared_array(name) {
                continue;
            }
            let sym = IrSymbol {
                name: name.clone(),
                value_type: *vt,
            };
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
            if is_shared_array(name) {
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

/// Find the value type of a non-string array DIM for `name` in `items`
/// (recursing control flow). Returns `None` if no such DIM exists.
/// Used to detect whether a STRING param's name also has a separate INTEGER
/// array DIM (xgr's `def:string` + `dim def:integer[80]`).
fn array_dim_type(items: &[IrItem], name: &str) -> Option<ValueType> {
    fn search(items: &[IrItem], name: &str) -> Option<ValueType> {
        for it in items {
            match it {
                IrItem::Dim {
                    symbol,
                    size,
                    is_array,
                    ..
                } if (*is_array || size.is_some())
                    && symbol.name == name
                    && symbol.value_type != ValueType::String =>
                {
                    return Some(symbol.value_type);
                }
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    if let Some(v) = search(then_body, name) {
                        return Some(v);
                    }
                    if let Some(b) = else_body {
                        if let Some(v) = search(b, name) {
                            return Some(v);
                        }
                    }
                }
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. }
                | IrItem::Compound(body) => {
                    if let Some(v) = search(body, name) {
                        return Some(v);
                    }
                }
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        if let Some(v) = search(&c.body, name) {
                            return Some(v);
                        }
                    }
                    if let Some(b) = default {
                        if let Some(v) = search(b, name) {
                            return Some(v);
                        }
                    }
                }
                _ => {}
            }
        }
        None
    }
    search(items, name)
}

/// True if `name` has a scalar STRING DIM in `items` (flattened `DIM host:HOST`
/// leaf `host.alias:string`, as opposed to `DIM host.alias$[]`).
fn has_string_scalar_dim(items: &[IrItem], name: &str) -> bool {
    fn search(items: &[IrItem], name: &str) -> bool {
        for it in items {
            match it {
                IrItem::Dim {
                    symbol,
                    size,
                    is_array,
                    ..
                } if !*is_array
                    && size.is_none()
                    && symbol.name == name
                    && symbol.value_type == ValueType::String =>
                {
                    return true;
                }
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    if search(then_body, name) {
                        return true;
                    }
                    if let Some(b) = else_body {
                        if search(b, name) {
                            return true;
                        }
                    }
                }
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. }
                | IrItem::Compound(body) => {
                    if search(body, name) {
                        return true;
                    }
                }
                IrItem::SelectCase { cases, default, .. } => {
                    for c in cases {
                        if search(&c.body, name) {
                            return true;
                        }
                    }
                    if let Some(b) = default {
                        if search(b, name) {
                            return true;
                        }
                    }
                }
                _ => {}
            }
        }
        false
    }
    search(items, name)
}

/// Dotted STRING names that are a TYPE array member: a scalar STRING DIM and
/// an `ArrayAccess`/`ArrayAssignment` (not mere `UBOUND`) in the same function.
/// `HOST.alias[2]` in Xin(); not `HOST.name` (indexed only in other functions).
fn collect_type_string_array_members(items: &[IrItem]) -> HashSet<String> {
    let mut out = HashSet::new();
    scan_fn(items, &mut out);
    for item in items {
        if let IrItem::Function { body, .. } = item {
            scan_fn(body, &mut out);
        }
    }
    out
}

fn scan_fn(body: &[IrItem], out: &mut HashSet<String>) {
    let mut indexed = HashSet::new();
    collect_indexed_names(body, &mut indexed);
    for n in indexed {
        if n.contains('.') && has_string_scalar_dim(body, &n) {
            out.insert(n);
        }
    }
}
#[allow(clippy::collapsible_match)]
fn collect_indexed_names(items: &[IrItem], out: &mut HashSet<String>) {
    fn expr(e: &IrExpr, out: &mut HashSet<String>) {
        match &e.kind {
            IrExprKind::ArrayAccess {
                symbol,
                index,
                extra_indices,
            } => {
                out.insert(symbol.name.clone());
                expr(index, out);
                for x in extra_indices {
                    expr(x, out);
                }
            }
            IrExprKind::ByRef(inner) | IrExprKind::Not(inner) => expr(inner, out),
            IrExprKind::Unary { operand, .. } => expr(operand, out),
            IrExprKind::Comparison { left, right, .. }
            | IrExprKind::Arithmetic { left, right, .. }
            | IrExprKind::Boolean { left, right, .. }
            | IrExprKind::Logical { left, right, .. } => {
                expr(left, out);
                expr(right, out);
            }
            IrExprKind::FunctionCall { args, .. } => {
                for a in args {
                    expr(a, out);
                }
            }
            _ => {}
        }
    }
    for it in items {
        match it {
            IrItem::Print { items, .. } => {
                for e in items {
                    expr(e, out);
                }
            }
            IrItem::Assignment { value, .. } | IrItem::SharedAssignment { value, .. } => {
                expr(value, out)
            }
            IrItem::ArrayAssignment {
                target,
                index,
                extra_indices,
                value,
                ..
            } => {
                out.insert(target.name.clone());
                expr(index, out);
                for x in extra_indices {
                    expr(x, out);
                }
                expr(value, out);
            }
            IrItem::Call { args, .. } => {
                for a in args {
                    expr(a, out);
                }
            }
            IrItem::Return { value } => {
                if let Some(v) = value {
                    expr(v, out);
                }
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
                ..
            } => {
                expr(condition, out);
                collect_indexed_names(then_body, out);
                if let Some(b) = else_body {
                    collect_indexed_names(b, out);
                }
            }
            IrItem::While { body, .. } | IrItem::DoLoop { body, .. } | IrItem::Compound(body) => {
                collect_indexed_names(body, out)
            }
            IrItem::For {
                start,
                end,
                step,
                body,
                ..
            } => {
                expr(start, out);
                expr(end, out);
                if let Some(s) = step {
                    expr(s, out);
                }
                collect_indexed_names(body, out);
            }
            IrItem::SelectCase {
                selector,
                cases,
                default,
            } => {
                expr(selector, out);
                for c in cases {
                    for cond in &c.conditions {
                        expr(cond, out);
                    }
                    collect_indexed_names(&c.body, out);
                }
                if let Some(d) = default {
                    collect_indexed_names(d, out);
                }
            }
            IrItem::GosubExpr(e) | IrItem::GotoExpr(e) => expr(e, out),
            _ => {}
        }
    }
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
        emit_module_dims(program, &mut body);
        emit_functions(program, &mut body);
        if !weak_symbols_enabled() {
            emit_main(program, &mut body);
        }
        let mut out = String::new();
        emit_version_global(program, &mut out);
        emit_program_name_global(program, &mut out);
        emit_header(&mut out);
        emit_composite_typedefs(program, &mut out);
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
                "static char* xb_str_n(const char* s, size_t n) { char* d = xb_alloc(n); if (n) memcpy(d, s, n); return d; }\n",
            );
        }
        if body.contains("xb_xst_str_to_num(") {
            crate::c_runtime::emit_xst_runtime(&mut out);
        }
        if body.contains("xb_back_to_bin(") {
            crate::c_runtime::emit_back_to_bin_runtime(&mut out);
        }
        if body.contains("xb_quicksort(") {
            crate::c_runtime::emit_quicksort_runtime(&mut out);
        }
        if body.contains("xb_copyarray(") {
            crate::c_runtime::emit_copyarray_runtime(&mut out);
        }
        if body.contains("xb_gui_next_callback(") {
            crate::c_runtime::emit_gui_runtime(&mut out);
        }
        if body.contains("xb_write_file(")
            || body.contains("xb_read_file(")
            || body.contains("xb_getstdhandle(")
        {
            crate::c_runtime::emit_kernel32_runtime(&mut out);
        }
        if body.contains("xb_xin_") {
            crate::c_emit_xin::emit_xin_runtime(&mut out);
        }
        if body.contains("xb_xgr_process_messages(") {
            crate::c_runtime::emit_xgr_process_messages_runtime(&mut out);
        }
        out.push_str(&body);
        out
    }
}

/// Emit struct typedefs for built-in composite types (DCOMPLEX, SCOMPLEX) when
/// any function in the program returns that type. The C emitter flattens
/// composite *parameters* into member scalars, but composite *returns* need a
/// real struct type so `return funcname;` can return the assembled value.
fn emit_composite_typedefs(program: &IrProgram, out: &mut String) {
    let mut needed: HashSet<&str> = HashSet::new();
    for item in &program.items {
        if let IrItem::Function {
            return_type_name: Some(tn),
            ..
        } = item
        {
            needed.insert(tn.as_str());
        }
    }
    for tn in &needed {
        match *tn {
            "DCOMPLEX" => out.push_str("typedef struct { double R; double I; } xb_dcomplex;\n"),
            "SCOMPLEX" => out.push_str("typedef struct { float R; float I; } xb_scomplex;\n"),
            _ => {}
        }
    }
}

/// Map a composite TYPE name to its C struct typedef name.
pub(crate) fn composite_c_type(type_name: &str) -> &'static str {
    match type_name {
        "DCOMPLEX" => "xb_dcomplex",
        "SCOMPLEX" => "xb_scomplex",
        _ => "intptr_t",
    }
}

/// Emit the fallback return for a composite-returning function: assemble the
/// struct from the function name's member variables and return it.
/// Called at the end of the function body (fall-through path).
fn emit_composite_fallback_return(name: &str, type_name: &str, out: &mut String) {
    let members: &[(&str, &str)] = match type_name {
        "DCOMPLEX" => &[("R", "xb_var_"), ("I", "xb_var_")],
        "SCOMPLEX" => &[("R", "xb_var_"), ("I", "xb_var_")],
        _ => &[],
    };
    out.push_str("    xb_var_");
    out.push_str(name);
    out.push_str(".R = ");
    out.push_str(members[0].1);
    out.push_str(name);
    out.push_str("_R;\n");
    out.push_str("    xb_var_");
    out.push_str(name);
    out.push_str(".I = ");
    out.push_str(members[1].1);
    out.push_str(name);
    out.push_str("_I;\n");
    out.push_str("    return xb_var_");
    out.push_str(name);
    out.push_str(";\n");
}

fn emit_functions(program: &IrProgram, out: &mut String) {
    let mut seen = HashSet::new();
    for item in &program.items {
        if let IrItem::Function {
            name,
            params,
            return_type,
            return_type_name,
            body,
        } = item
        {
            // XBasic forward declarations lower to a duplicate empty definition; the
            // interpreter's find_function resolves the FIRST occurrence, so emit each
            // name once (first-wins) to match and avoid a C redefinition.
            if !seen.insert(name.clone()) {
                continue;
            }
            // Skip EXTERNAL FUNCTION declarations for recognized builtins —
            // their call sites use the C runtime helper (xb_sqrt, xb_sin),
            // not a zero-returning weak stub.
            if body.is_empty() && crate::is_builtin::is_builtin(name) {
                continue;
            }
            // Disambiguate duplicate labels (SUB name colliding with an explicit
            // label of the same name) BEFORE establishing the context, so
            // FN_LABELS sees the renamed set. No duplicates → the original body.
            let disambiguated;
            let body: &[IrItem] = match crate::c_emit_hoist::disambiguate_labels(body) {
                Some(v) => {
                    disambiguated = v;
                    &disambiguated
                }
                None => body,
            };
            // Establish the per-function context BEFORE the signature so a
            // dual-use array param is emitted with its `_arr` array name.
            set_fn_context(name, body, params, return_type_name.as_deref());
            if weak_symbols_enabled() {
                out.push_str("__attribute__((weak)) ");
            }
            // Composite return type: emit the struct typedef name instead of
            // the primitive C type (e.g. `xb_dcomplex` instead of `double`).
            if let Some(tn) = return_type_name.as_deref() {
                if tn == "DCOMPLEX" || tn == "SCOMPLEX" {
                    out.push_str(composite_c_type(tn));
                } else {
                    out.push_str(c_type(*return_type));
                }
            } else {
                out.push_str(c_type(*return_type));
            }
            out.push_str(" xb_user_");
            out.push_str(name);
            out.push('(');
            if params.is_empty() {
                out.push_str("void");
            }
            let byref = defined_param_byref(name).unwrap_or_default();
            let descriptors = fn_descriptor_params(name);
            for (i, p) in params.iter().enumerate() {
                if i > 0 {
                    out.push_str(", ");
                }
                if p.is_array && descriptors.contains(&p.name) {
                    emit_descriptor_param_decl(p, out);
                    continue;
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
                if params[i + 1..].iter().any(|q| {
                    q.name == p.name && (q.value_type == crate::ValueType::String) == p_str
                }) {
                    out.push_str(&format!("__dup{i}"));
                }
            }
            out.push_str(") {\n");
            emit_byref_copy_in(out, 1);
            crate::c_emit_hoist::emit_hoisted_scalars(body, params, Some(name), out, 1);
            emit_dyn_decls(out, 1);
            // An Integer-returning function that references its own name as a
            // variable (e.g. `Break = 0` in FUNCTION Break) needs the return
            // variable declared and returned, not just `return 0;`. The v0.1
            // corpus has no such function, so this is byte-neutral.
            let own_name_used = *return_type == ValueType::Integer
                && crate::c_emit_hoist::body_uses_name(body, name)
                && !crate::c_emit_hoist::body_dims_name(body, name);
            let is_composite_ret = return_type_name
                .as_deref()
                .map(|tn| tn == "DCOMPLEX" || tn == "SCOMPLEX")
                .unwrap_or(false);
            if is_composite_ret {
                // Composite return: declare the function name as a struct local.
                // The member variables (funcname.R, funcname.I) are already
                // hoisted as separate doubles by emit_hoisted_scalars; the struct
                // local is assembled from them at the return point.
                let tn = return_type_name.as_deref().unwrap();
                out.push_str("    ");
                out.push_str(composite_c_type(tn));
                out.push_str(" xb_var_");
                out.push_str(name);
                out.push_str(" = {0};\n");
            } else if *return_type != ValueType::Integer || own_name_used {
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
            if is_composite_ret {
                emit_composite_fallback_return(name, return_type_name.as_deref().unwrap(), out);
            } else if *return_type != ValueType::Integer || own_name_used {
                emit_fallback_return(name, *return_type, out);
            } else {
                out.push_str("    return 0;\n");
            }
            out.push_str("}\n\n");
        }
    }
}

/// MODULE-DIM-SCOPE: a top-level array DIM eligible for file-scope hoisting —
/// fixed-size, non-string (string elements need `xb_str("")` runtime init),
/// non-shared (already global), non-dyn (calloc must stay at the DIM site).
fn hoistable_module_dim(item: &IrItem) -> bool {
    match item {
        IrItem::Dim {
            symbol,
            size,
            is_array,
            extra_dims,
            ..
        } => {
            let sized = size.is_some() && !extra_dims.is_empty()
                || (size.is_some() && extra_dims.is_empty());
            sized
                && (*is_array || size.is_some())
                && symbol.value_type != ValueType::String
                && !is_shared_array(&symbol.name)
                && !is_dyn_array(&symbol.name)
        }
        _ => false,
    }
}

/// Emit file-scope `static` declarations for hoistable module-level array
/// DIMs when the program defines any function: C `main()` locals are invisible
/// to called functions, so module-level arrays referenced across functions
/// must live at file scope. Behaviorally transparent (same storage, zero-init).
fn emit_module_dims(program: &IrProgram, out: &mut String) {
    let has_fn = program
        .items
        .iter()
        .any(|i| matches!(i, IrItem::Function { .. }));
    HOISTED_MODULE_DIMS.with(|s| s.borrow_mut().clear());
    if !has_fn {
        return;
    }
    HOISTED_MODULE_DIMS.with(|s| {
        let mut set = s.borrow_mut();
        for item in &program.items {
            if let IrItem::Dim { symbol, .. } = item {
                if hoistable_module_dim(item) {
                    set.insert(symbol.name.clone());
                }
            }
        }
    });
    for item in &program.items {
        if let IrItem::Dim {
            symbol,
            size,
            extra_dims,
            ..
        } = item
        {
            if !hoistable_module_dim(item) {
                continue;
            }
            let mut dims = Vec::new();
            if let Some(sz) = size {
                dims.push(sz.clone());
            }
            dims.extend(extra_dims.iter().cloned());
            out.push_str("static ");
            out.push_str(c_type(symbol.value_type));
            out.push(' ');
            emit_array_var_name(symbol, out);
            out.push('[');
            emit_flat_size(&dims, out);
            out.push_str("];\n");
        }
    }
}

fn emit_main(program: &IrProgram, out: &mut String) {
    // MODULE-DIM-SCOPE: with functions present, hoistable module DIMs live at
    // file scope (emit_module_dims) and are skipped here. Without functions
    // emit_module_dims early-returns, so the DIM must stay in main()'s body —
    // filtering unconditionally dropped it entirely (undeclared xb_var_N).
    let has_fn = program
        .items
        .iter()
        .any(|i| matches!(i, IrItem::Function { .. }));
    let top: Vec<&IrItem> = program
        .items
        .iter()
        .filter(|i| {
            if matches!(
                i,
                IrItem::Function { .. } | IrItem::Version(_) | IrItem::ProgramName(_)
            ) {
                return false;
            }
            !(has_fn && hoistable_module_dim(i))
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
    // File-scope weak definitions for system shared arrays so that
    // main's startup init can always reference them without undefined-
    // symbol errors, even for programs that don't directly use ARGV$.
    // The real definitions (when needed) are weak in xst.o and will
    // coalesce; otherwise these stay as 0/-1 singletons.
    // Skip if already emitted by emit_globals (SHARED_ARRAYS has them).
    if !crate::c_emit::is_shared_array("ARGV$") {
        out.push_str("__attribute__((weak)) char** xb_str_ARGV_s_arr = (char**)0;\n");
        out.push_str("__attribute__((weak)) intptr_t xb_ub_ARGV_s_arr = -1;\n");
    }
    if !crate::c_emit::is_shared_array("ENVP$") {
        out.push_str("__attribute__((weak)) char** xb_str_ENVP_s_arr = (char**)0;\n");
        out.push_str("__attribute__((weak)) intptr_t xb_ub_ENVP_s_arr = -1;\n");
    }
    out.push_str("int main(int argc, char **argv) {\n");
    // ARCH-02: populate system shared arrays from process startup.
    out.push_str("    if (xb_str_ARGV_s_arr == (char**)0) {\n");
    out.push_str("        xb_ub_ARGV_s_arr = (intptr_t)argc - 1;\n");
    out.push_str("        if (argc > 0) {\n");
    out.push_str("            xb_str_ARGV_s_arr = (char**)calloc((size_t)argc, sizeof(char*));\n");
    out.push_str("            if (xb_str_ARGV_s_arr) {\n");
    out.push_str(
        "                for (int _i = 0; _i < argc; _i++) xb_str_ARGV_s_arr[_i] = xb_str(argv[_i]);\n",
    );
    out.push_str("            } else { xb_ub_ARGV_s_arr = -1; }\n");
    out.push_str("        }\n");
    out.push_str("    }\n");
    out.push_str("    {\n");
    out.push_str("        extern char** environ;\n");
    out.push_str("        if (xb_str_ENVP_s_arr == (char**)0 && environ) {\n");
    out.push_str("            int _envc = 0; while (environ[_envc]) _envc++;\n");
    out.push_str("            xb_ub_ENVP_s_arr = (intptr_t)_envc - 1;\n");
    out.push_str("            if (_envc > 0) {\n");
    out.push_str(
        "                xb_str_ENVP_s_arr = (char**)calloc((size_t)_envc, sizeof(char*));\n",
    );
    out.push_str("                if (xb_str_ENVP_s_arr) {\n");
    out.push_str("                    for (int _i = 0; _i < _envc; _i++) xb_str_ENVP_s_arr[_i] = xb_str(environ[_i]);\n");
    out.push_str("                } else { xb_ub_ENVP_s_arr = -1; }\n");
    out.push_str("            }\n");
    out.push_str("        }\n");
    out.push_str("    }\n");
    emit_data_init(program, out);
    set_fn_context("", &program.items, &[], None);
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
/// Escape a string for safe embedding in a C double-quoted string literal.
pub(crate) fn c_escape(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "\\n")
        .replace('\t', "\\t")
        .replace('\r', "\\r")
}

fn emit_data_init(program: &IrProgram, out: &mut String) {
    for (tag, val) in &program.data_values {
        match tag.as_str() {
            "int" => out.push_str(&format!("    xb_data_add_int({val});\n")),
            "float" => out.push_str(&format!("    xb_data_add_float({val});\n")),
            _ => {
                out.push_str(&format!("    xb_data_add_str(\"{}\");\n", c_escape(val)));
            }
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
    out.push_str(&format!(
        "static const char* xb_version_str = \"{}\";\n",
        c_escape(ver)
    ));
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
        "static const char* xb_program_name_str = \"{}\";\n",
        c_escape(name)
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

/// Library-mode emission (env `XB_WEAK_SYMBOLS` set): function definitions and
/// file-scope globals get `__attribute__((weak))` and `main` is omitted, so the
/// per-library C outputs link together into one binary (the original XBasic
/// build links xit/xst/xgr/... objects side by side). Duplicate strong symbols
/// across libraries — INTERNAL functions defined in several libs, shared tables
/// like `charsetSymbol` — otherwise fail the link with 128 duplicates. Weak +
/// first-definition-wins mirrors the emitter's own first-wins function dedup.
/// Unset by default: emitted bytes are identical, so every sync/bootstrap/demo
/// suite is untouched.
pub(crate) fn weak_symbols_enabled() -> bool {
    std::env::var_os("XB_WEAK_SYMBOLS").is_some()
}

pub(crate) fn c_type(vt: ValueType) -> &'static str {
    match vt {
        ValueType::Integer => "intptr_t",
        ValueType::Giant => "int64_t",
        ValueType::Float => "double",
        ValueType::String => "char*",
    }
}
#[cfg(test)]
mod c_emit_argv_tests {

    #[test]
    fn c_emit_argv_init_and_main_signature() {
        // Lock ARCH-02: xst's ##ARGV$[] should be a shared heap global with
        // startup init, not a scalar stub. This test guards the panel's
        // strongest objection falsifier (XstGetCommandLineArguments(-1)).
        let manifest_dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR"));
        let xst_path = manifest_dir.join("../../xbasic/lib/xst.x");
        let src = std::fs::read_to_string(&xst_path)
            .unwrap_or_else(|e| panic!("read {}: {e}", xst_path.display()));
        let prog = crate::FrontendUnit::parse(&src)
            .expect("parse xst.x")
            .lower_ir()
            .expect("lower xst.x");
        let c = crate::CEmitter::new().emit_program(&prog);
        assert!(
            c.contains("int main(int argc, char **argv)"),
            "main should be int main(int argc, char **argv) with ARGV$ init"
        );
        assert!(
            c.contains("char** xb_str_ARGV_s_arr"),
            "file-scope def for ARGV$"
        );
        assert!(
            c.contains("xb_ub_ARGV_s_arr = (intptr_t)argc - 1"),
            "ARGV$ ub init from argc"
        );
        assert!(
            c.contains("xb_str_ARGV_s_arr[xb_var_i]"),
            "ARGV$ access should be via shared global, not xb_str(\"\") stub"
        );
        // ENVP$ should also be present (same mechanism)
        assert!(c.contains("xb_str_ENVP_s_arr"), "ENVP$ global");
    }
    #[test]
    fn declare_byref_markers_reach_cemitter() {
        // DECLARE FUNCTION Foo (x, @y) → y should be byref in C output.
        let src = "\
DECLARE FUNCTION Foo (x, @y)
FUNCTION Foo (x, y)
    y = x * 2
END FUNCTION
";
        let prog = crate::FrontendUnit::parse(src)
            .expect("parse")
            .lower_ir()
            .expect("lower");
        // DECLARE byref info should be in IrProgram.
        assert_eq!(
            prog.declare_byref.get("Foo"),
            Some(&vec![false, true]),
            "DECLARE @y should produce byref=[false, true]"
        );
        let c = crate::CEmitter::new().emit_program(&prog);
        // Foo has no callsites, so DECLARE byref fallback should make y a pointer.
        assert!(
            c.contains("intptr_t *xb_var_y_ref"),
            "DECLARE @y should produce byref pointer param when no callsite exists"
        );
    }

    #[test]
    fn declare_no_at_markers_does_not_block_env_hints() {
        // DECLARE without @ should NOT insert byref info, allowing env var fallback.
        let src = "\
DECLARE FUNCTION Bar (a, b)
FUNCTION Bar (a, b)
    a = b + 1
END FUNCTION
";
        let prog = crate::FrontendUnit::parse(src)
            .expect("parse")
            .lower_ir()
            .expect("lower");
        // No @ markers → declare_byref should have [false, false] but NOT be used
        // as fallback (only inserted if any param has @).
        assert_eq!(
            prog.declare_byref.get("Bar"),
            Some(&vec![false, false]),
            "DECLARE without @ records all-false"
        );
        let c = crate::CEmitter::new().emit_program(&prog);
        // Bar has no callsites and no @ → params should be byval.
        assert!(
            !c.contains("*xb_var_a_ref"),
            "DECLARE without @ should NOT produce byref pointer"
        );
    }
}
