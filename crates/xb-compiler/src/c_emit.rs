use crate::c_emit_expr::emit_var_name;
use crate::c_emit_select::emit_body;
use crate::c_runtime::{c_type, emit_forward_decls, emit_globals, emit_header};
use crate::ir::{IrItem, IrProgram, IrSymbol};
use crate::ValueType;

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
        let mut out = String::new();
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
                crate::c_emit_expr::emit_fallback_return(name, *return_type, out);
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
        .filter(|i| !matches!(i, IrItem::Function { .. } | IrItem::Version(_)))
        .collect();
    let has_main = program
        .items
        .iter()
        .any(|i| matches!(i, IrItem::Function { name, .. } if name == "Main"));
    out.push_str("int main(void) {\n");
    emit_data_init(program, out);
    emit_body(top, out, 1);
    if has_main {
        out.push_str("    xb_user_Main();\n");
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
