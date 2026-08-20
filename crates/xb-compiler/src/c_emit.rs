use crate::c_emit_expr::emit_var_name;
use crate::c_emit_select::emit_body;
use crate::c_runtime::{emit_forward_decls, emit_globals, emit_header};
use crate::ir::{IrItem, IrProgram, IrSymbol};
use crate::ValueType;
use std::cell::RefCell;
use std::collections::HashSet;

thread_local! {
    /// User-defined function names for the program currently being emitted, so a
    /// call site can tell a real callee from an unknown one (`is_unknown_call`).
    static DEFINED_FUNCS: RefCell<HashSet<String>> = RefCell::new(HashSet::new());
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
        let mut out = String::new();
        emit_version_global(program, &mut out);
        emit_program_name_global(program, &mut out);
        emit_header(&mut out);
        emit_globals(program, &mut out);
        emit_forward_decls(program, &mut out);
        emit_functions(program, &mut out);
        emit_main(program, &mut out);
        out
    }
}

fn emit_functions(program: &IrProgram, out: &mut String) {
    for item in &program.items {
        if let IrItem::Function {
            name,
            params,
            return_type,
            body,
        } = item
        {
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
            }
            out.push_str(") {\n");
            if *return_type != ValueType::Integer {
                crate::c_emit_expr::emit_return_var_decl(name, *return_type, out);
            }
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
