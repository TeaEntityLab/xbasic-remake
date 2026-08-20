use crate::c_emit_expr::emit_var_name;
use crate::c_emit_select::emit_body;
use crate::c_runtime::{emit_forward_decls, emit_globals, emit_header};
use crate::ir::{IrItem, IrProgram, IrSymbol};
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
    /// element type; scalars their type. Empty for the entire shared corpus.
    static FN_DYN: RefCell<crate::c_emit_hoist::DynNames> = RefCell::new(crate::c_emit_hoist::DynNames::default());
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
}

/// Declared param types of a user-defined function, or `None` for builtins /
/// unknown names (whose call sites are emitted as-is / stubbed).
pub(crate) fn defined_params(name: &str) -> Option<Vec<crate::ValueType>> {
    DEFINED_SIGS.with(|s| s.borrow().get(name).cloned())
}

/// Establish the per-function emit context for `items` (a function body, or the
/// whole program's items for `main` — the walkers skip nested `Function` bodies).
fn set_fn_context(items: &[IrItem], params: &[crate::ir::IrParam]) {
    let mut refs = HashSet::new();
    crate::c_emit_hoist::collect_array_refs(items, &mut refs);
    let mut dimmed = HashSet::new();
    crate::c_emit_hoist::collect_dimmed_names(items, &mut dimmed);
    for p in params {
        dimmed.insert(p.name.clone());
    }
    FN_DYN.with(|s| {
        *s.borrow_mut() = crate::c_emit_hoist::collect_dyn_names(items, params);
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
}

/// An array referenced in the current function without any `Dim` — reads fold to
/// the type default, `UBOUND` to -1, writes to a discarded evaluation (matching
/// the interpreter's missing-slot semantics; an *executed* write errors there,
/// which only unreached code paths hit in interpreter-clean programs).
pub(crate) fn is_undimmed_array(name: &str) -> bool {
    FN_UNDIMMED_ARRAYS.with(|s| s.borrow().contains(name))
}

/// Whether the current C function will contain `xb_label_<name>:`.
pub(crate) fn fn_has_label(name: &str) -> bool {
    FN_LABELS.with(|s| s.borrow().contains(name))
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
            out.push_str(&ind);
            out.push_str(c_type(*vt));
            out.push_str(" *");
            emit_var_name(
                &IrSymbol { name: name.clone(), value_type: *vt },
                out,
            );
            out.push_str(" = 0;\n");
            out.push_str(&ind);
            out.push_str("intptr_t xb_ub_");
            out.push_str(name);
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
            out.push_str(c_type(*return_type));
            out.push_str(" xb_user_");
            out.push_str(name);
            out.push('(');
            if params.is_empty() {
                out.push_str("void");
            }
            for (i, p) in params.iter().enumerate() {
                if i > 0 {
                    out.push_str(", ");
                }
                out.push_str(c_type(p.value_type));
                out.push(' ');
                emit_var_name(
                    &IrSymbol {
                        name: p.name.clone(),
                        value_type: p.value_type,
                    },
                    out,
                );
                // Duplicate param names: the interpreter's zip-binding writes the
                // slot per name, so the LAST occurrence wins; earlier dups get an
                // unused suffixed C name (C forbids duplicate parameters).
                if params[i + 1..].iter().any(|q| q.name == p.name) {
                    out.push_str(&format!("__dup{i}"));
                }
            }
            out.push_str(") {\n");
            set_fn_context(body, params);
            crate::c_emit_hoist::emit_hoisted_scalars(body, params, Some(name), out, 1);
            emit_dyn_decls(out, 1);
            if *return_type != ValueType::Integer {
                crate::c_emit_expr::emit_return_var_decl(name, *return_type, out);
            }
            crate::c_emit_goto::emit_computed_goto_prologue(body, out, 1);
            emit_body(body, out, 1);
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
    set_fn_context(&program.items, &[]);
    // Top-level scalars (walk_items ignores nested Function bodies).
    crate::c_emit_hoist::emit_hoisted_scalars(&program.items, &[], None, out, 1);
    emit_dyn_decls(out, 1);
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
        ValueType::Float => "double",
        ValueType::String => "char*",
    }
}
