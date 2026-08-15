use crate::c_emit_expr::{emit_default, emit_expr, emit_var_name};
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
        let mut out = String::new();
        emit_header(&mut out);
        emit_forward_decls(program, &mut out);
        emit_globals(program, &mut out);
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
            out.push(' ');
            out.push_str("xb_user_");
            out.push_str(name);
            out.push('(');
            if params.is_empty() {
                out.push_str("void");
            } else {
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
            }
            out.push_str(") {\n");
            crate::c_emit_expr::emit_return_var_decl(name, *return_type, out);
            emit_body(body, out, 1);
            crate::c_emit_expr::emit_fallback_return(name, *return_type, out);
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
                IrItem::Function { .. } | IrItem::ConstantDefinition { .. }
            )
        })
        .collect();
    let has_main = program
        .items
        .iter()
        .any(|i| matches!(i, IrItem::Function { name, .. } if name == "Main"));
    out.push_str("int main(void) {\n");
    emit_body(top, out, 1);
    if has_main {
        out.push_str("    xb_user_Main();\n");
    }
    out.push_str("    fflush(stdout);\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
}

fn emit_body<'a, I>(items: I, out: &mut String, indent: usize)
where
    I: IntoIterator<Item = &'a IrItem>,
{
    for item in items {
        emit_item(item, out, indent);
    }
}

fn emit_item(item: &IrItem, out: &mut String, indent: usize) {
    let ind = "    ".repeat(indent);
    match item {
        IrItem::Version(_) => {}
        IrItem::Print(expr) => {
            out.push_str(&ind);
            match expr.value_type {
                ValueType::Integer => out.push_str("xb_print_int("),
                ValueType::Float => out.push_str("xb_print_float("),
                ValueType::String => out.push_str("xb_print_str("),
            }
            emit_expr(expr, out);
            out.push_str(");\n");
        }
        IrItem::Dim { symbol, size } => {
            out.push_str(&ind);
            match size {
                Some(sz) => {
                    out.push_str(c_type(symbol.value_type));
                    out.push(' ');
                    emit_var_name(symbol, out);
                    out.push('[');
                    emit_expr(sz, out);
                    out.push_str("];\n");
                    if symbol.value_type == ValueType::String {
                        out.push_str(&ind);
                        out.push_str("for (int _i = 0; _i < ");
                        emit_expr(sz, out);
                        out.push_str("; _i++) ");
                        emit_var_name(symbol, out);
                        out.push_str("[_i] = xb_strdup(\"\");\n");
                    }
                }
                None => {
                    out.push_str(c_type(symbol.value_type));
                    out.push(' ');
                    emit_var_name(symbol, out);
                    out.push_str(" = ");
                    emit_default(symbol.value_type, out);
                    out.push_str(";\n");
                }
            }
        }
        IrItem::Assignment { target, value } => {
            out.push_str(&ind);
            emit_var_name(target, out);
            out.push_str(" = ");
            emit_expr(value, out);
            out.push_str(";\n");
        }
        IrItem::ArrayAssignment {
            target,
            index,
            value,
        } => {
            out.push_str(&ind);
            emit_var_name(target, out);
            out.push('[');
            emit_expr(index, out);
            out.push_str("] = ");
            emit_expr(value, out);
            out.push_str(";\n");
        }
        IrItem::ConstantDefinition { .. } => {}
        IrItem::SharedAssignment { target, value } => {
            out.push_str(&ind);
            out.push_str("xb_shared_");
            out.push_str(&target.name);
            out.push_str(" = ");
            emit_expr(value, out);
            out.push_str(";\n");
        }
        IrItem::If {
            condition,
            then_body,
            else_body,
        } => {
            out.push_str(&ind);
            out.push_str("if (");
            emit_expr(condition, out);
            out.push_str(") {\n");
            emit_body(then_body, out, indent + 1);
            if let Some(eb) = else_body {
                out.push_str(&ind);
                out.push_str("} else {\n");
                emit_body(eb, out, indent + 1);
            }
            out.push_str(&ind);
            out.push_str("}\n");
        }
        IrItem::While { condition, body } => {
            out.push_str(&ind);
            out.push_str("while (");
            emit_expr(condition, out);
            out.push_str(") {\n");
            emit_body(body, out, indent + 1);
            out.push_str(&ind);
            out.push_str("}\n");
        }
        IrItem::For {
            var,
            start,
            end,
            body,
        } => {
            out.push_str(&ind);
            out.push_str("for (");
            emit_var_name(var, out);
            out.push_str(" = ");
            emit_expr(start, out);
            out.push_str("; ");
            emit_var_name(var, out);
            out.push_str(" <= ");
            emit_expr(end, out);
            out.push_str("; ");
            emit_var_name(var, out);
            out.push_str("++) {\n");
            emit_body(body, out, indent + 1);
            out.push_str(&ind);
            out.push_str("}\n");
        }
        IrItem::Function { .. } => {}
        IrItem::Return { value } => {
            out.push_str(&ind);
            match value {
                Some(e) => {
                    out.push_str("return ");
                    emit_expr(e, out);
                    out.push_str(";\n");
                }
                None => out.push_str("return 0;\n"),
            }
        }
        IrItem::Call { name, args } => {
            out.push_str(&ind);
            out.push_str("xb_user_");
            out.push_str(name);
            out.push('(');
            for (i, arg) in args.iter().enumerate() {
                if i > 0 {
                    out.push_str(", ");
                }
                emit_expr(arg, out);
            }
            out.push_str(");\n");
        }
        IrItem::ExitLoop => {
            out.push_str(&ind);
            out.push_str("break;\n");
        }
    }
}
