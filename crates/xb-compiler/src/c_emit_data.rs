use crate::c_emit_expr::emit_var_name;
use crate::ir::IrSymbol;

pub(crate) fn emit_read(symbols: &[IrSymbol], out: &mut String, indent: usize) {
    let pad = "  ".repeat(indent);
    for sym in symbols {
        match sym.value_type {
            crate::ValueType::Integer => {
                out.push_str(&pad);
                out.push_str("xb_read_int(&");
                emit_var_name(sym, out);
                out.push_str(");\n");
            }
            crate::ValueType::Giant => {
                out.push_str(&pad);
                out.push_str("xb_read_giant(&");
                emit_var_name(sym, out);
                out.push_str(");\n");
            }
            crate::ValueType::Float => {
                out.push_str(&pad);
                out.push_str("xb_read_float(&");
                emit_var_name(sym, out);
                out.push_str(");\n");
            }
            crate::ValueType::String => {
                out.push_str(&pad);
                emit_var_name(sym, out);
                out.push_str(" = xb_read_str();\n");
            }
        }
    }
}

pub(crate) fn emit_restore(label: Option<&str>, out: &mut String, indent: usize) {
    let pad = "  ".repeat(indent);
    match label {
        Some(_) => {
            out.push_str(&format!("{pad}xb_restore(0);\n"));
        }
        None => {
            out.push_str(&format!("{pad}xb_restore(0);\n"));
        }
    }
}
