use crate::c_emit_expr::{emit_default, emit_expr, emit_var_name};
use crate::c_emit_select::emit_body;
use crate::c_runtime::c_type;
use crate::ir::IrItem;
use crate::ValueType;
pub(crate) fn emit_item(item: &IrItem, out: &mut String, indent: usize) {
    let ind = "    ".repeat(indent);
    match item {
        IrItem::Version(_) => {}
        IrItem::Print { items, separators } => {
            crate::c_emit_select::emit_print(items, separators, out, indent);
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
        IrItem::DoLoop {
            pre_condition,
            post_condition,
            body,
        } => {
            match pre_condition {
                Some((cond, is_while)) => {
                    out.push_str(&ind);
                    out.push_str("while (");
                    if !*is_while {
                        out.push_str("!(");
                        emit_expr(cond, out);
                        out.push(')');
                    } else {
                        emit_expr(cond, out);
                    }
                    out.push_str(") {\n");
                }
                None => {
                    if post_condition.is_some() {
                        out.push_str(&ind);
                        out.push_str("do {\n");
                    } else {
                        out.push_str(&ind);
                        out.push_str("while (1) {\n");
                    }
                }
            }
            emit_body(body, out, indent + 1);
            match post_condition {
                Some((cond, is_while)) => {
                    out.push_str(&ind);
                    out.push_str("} while (");
                    if !*is_while {
                        out.push_str("!(");
                        emit_expr(cond, out);
                        out.push(')');
                    } else {
                        emit_expr(cond, out);
                    }
                    out.push_str(");\n");
                }
                None => {
                    out.push_str(&ind);
                    out.push_str("}\n");
                }
            }
        }
        IrItem::For {
            var,
            start,
            end,
            step,
            body,
        } => {
            out.push_str(&ind);
            out.push_str("for (");
            emit_var_name(var, out);
            out.push_str(" = ");
            emit_expr(start, out);
            out.push_str("; ");
            match step {
                Some(s) => {
                    let neg = matches!(
                        &s.kind,
                        crate::ir::IrExprKind::IntegerLiteral(v) if v.starts_with('-')
                    );
                    emit_var_name(var, out);
                    if neg {
                        out.push_str(" >= ");
                    } else {
                        out.push_str(" <= ");
                    }
                    emit_expr(end, out);
                    out.push_str("; ");
                    emit_var_name(var, out);
                    out.push_str(" += ");
                    emit_expr(s, out);
                }
                None => {
                    emit_var_name(var, out);
                    out.push_str(" <= ");
                    emit_expr(end, out);
                    out.push_str("; ");
                    emit_var_name(var, out);
                    out.push_str("++");
                }
            }
            out.push_str(") {\n");
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
        IrItem::ExitSelect => {
            let id = crate::c_emit_select::current_select_id();
            out.push_str(&ind);
            out.push_str(&format!("goto _exit_sel_{id};\n"));
        }
        IrItem::Swap { left, right } => {
            crate::c_emit_select::emit_swap(left, right, out, &ind);
        }
        IrItem::Nop => {}
        IrItem::SelectCase {
            selector,
            cases,
            default,
        } => {
            crate::c_emit_select::emit_select_case(selector, cases, default.as_deref(), out, indent)
        }
        IrItem::Compound(items) => {
            for item in items {
                emit_item(item, out, indent);
            }
        }
        IrItem::Read(symbols) => crate::c_emit_data::emit_read(symbols, out, indent),
        IrItem::Restore(label) => crate::c_emit_data::emit_restore(label.as_deref(), out, indent),
        IrItem::Stop => {
            out.push_str(&ind);
            out.push_str("exit(0);\n");
        }
    }
}
