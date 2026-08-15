use crate::c_emit_helpers::{
    arith_op, boolean_op, cmp_op, emit_c_function_name, emit_c_string, emit_type_conversion,
    is_type_conversion,
};
use crate::checked::ArithmeticOp;
use crate::ir::{IrExpr, IrExprKind, IrSymbol};
use crate::ValueType;

pub(crate) fn emit_expr(expr: &IrExpr, out: &mut String) {
    match &expr.kind {
        IrExprKind::StringLiteral(v) => {
            out.push_str("xb_str(\"");
            emit_c_string(v, out);
            out.push_str("\")");
        }
        IrExprKind::IntegerLiteral(v) => {
            out.push_str(v);
        }
        IrExprKind::FloatLiteral(v) => {
            out.push_str(v);
        }
        IrExprKind::Constant { value, .. } => {
            out.push_str(value);
        }
        IrExprKind::SharedVariable(s) => {
            out.push_str("xb_shared_");
            out.push_str(&s.name);
        }
        IrExprKind::Symbol(s) => {
            emit_symbol_ref(s, out);
        }
        IrExprKind::Comparison { op, left, right } => {
            if left.value_type == ValueType::String || right.value_type == ValueType::String {
                out.push_str("(-(strcmp(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push_str(") ");
                out.push_str(cmp_op(*op));
                out.push_str(" 0))");
            } else {
                out.push_str("-(");
                emit_expr(left, out);
                out.push(' ');
                out.push_str(cmp_op(*op));
                out.push(' ');
                emit_expr(right, out);
                out.push(')');
            }
        }
        IrExprKind::Arithmetic { op, left, right } => {
            if op == &ArithmeticOp::Add
                && (left.value_type == ValueType::String || right.value_type == ValueType::String)
            {
                out.push_str("xb_concat(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push(')');
            } else if op == &ArithmeticOp::Pow {
                out.push_str("pow(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push(')');
            } else if op == &ArithmeticOp::IntegerDiv
                && (left.value_type == ValueType::Float || right.value_type == ValueType::Float)
            {
                out.push_str("(double)(int)(");
                emit_expr(left, out);
                out.push_str(" / ");
                emit_expr(right, out);
                out.push(')');
            } else {
                out.push('(');
                emit_expr(left, out);
                out.push(' ');
                out.push_str(arith_op(*op));
                out.push(' ');
                emit_expr(right, out);
                out.push(')');
            }
        }
        IrExprKind::Not(inner) => {
            out.push_str("(~");
            emit_expr(inner, out);
            out.push(')');
        }
        IrExprKind::Boolean { op, left, right } => {
            out.push_str("((");
            emit_expr(left, out);
            out.push_str(") ");
            out.push_str(boolean_op(*op));
            out.push_str(" (");
            emit_expr(right, out);
            out.push_str("))");
        }
        IrExprKind::FunctionCall { name, args } => {
            if name == "CHR$" {
                if args.len() == 1 {
                    out.push_str("xb_chr");
                    out.push('(');
                    emit_expr(&args[0], out);
                    out.push_str(", 1)");
                } else {
                    out.push_str("xb_chr");
                    out.push('(');
                    for (i, arg) in args.iter().enumerate() {
                        if i > 0 {
                            out.push_str(", ");
                        }
                        emit_expr(arg, out);
                    }
                    out.push(')');
                }
            } else if name == "INSTR" {
                if args.len() == 2 {
                    out.push_str("xb_instr2");
                } else {
                    out.push_str("xb_instr3");
                }
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if name == "RINSTR" {
                if args.len() == 2 {
                    out.push_str("xb_rinstr2");
                } else {
                    out.push_str("xb_rinstr3");
                }
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
            } else if name == "INSTRI" || name == "RINSTRI" {
                let base = if name == "INSTRI" {
                    "xb_instri"
                } else {
                    "xb_rinstri"
                };
                out.push_str(base);
                out.push_str(if args.len() == 2 { "2" } else { "3" });
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else if name == "ABS" && expr.value_type == ValueType::Float {
                out.push_str("xb_fabs(");
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
            } else if is_type_conversion(name) {
                emit_type_conversion(name, &args[0], out, emit_expr);
            } else if name == "HEXX$" {
                crate::c_emit_helpers::emit_hexx(args, out, emit_expr);
            } else if name == "STR$" && !args.is_empty() && args[0].value_type == ValueType::Float {
                out.push_str("xb_str_float(");
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            } else {
                emit_c_function_name(name, out);
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push(')');
            }
        }
        IrExprKind::ArrayAccess { symbol, index } => {
            emit_symbol_ref(symbol, out);
            out.push('[');
            emit_expr(index, out);
            out.push(']');
        }
    }
}

fn emit_symbol_ref(s: &IrSymbol, out: &mut String) {
    emit_var_name(s, out);
}

pub(crate) fn emit_var_name(symbol: &IrSymbol, out: &mut String) {
    match symbol.value_type {
        ValueType::String => {
            out.push_str("xb_str_");
        }
        _ => {
            out.push_str("xb_var_");
        }
    }
    out.push_str(&symbol.name);
}

pub(crate) fn emit_default(vt: ValueType, out: &mut String) {
    match vt {
        ValueType::Integer => out.push('0'),
        ValueType::Float => out.push_str("0.0"),
        ValueType::String => out.push_str("xb_strdup(\"\")"),
    }
}

/// Emits the return-variable declaration at the top of a C function body.
pub(crate) fn emit_return_var_decl(name: &str, return_type: ValueType, out: &mut String) {
    let ret_name = name.trim_end_matches('$');
    out.push_str("    ");
    out.push_str(crate::c_runtime::c_type(return_type));
    out.push(' ');
    emit_var_name(
        &IrSymbol {
            name: ret_name.to_string(),
            value_type: return_type,
        },
        out,
    );
    out.push_str(" = ");
    emit_default(return_type, out);
    out.push_str(";\n");
}

/// Emits a fallback `return` of the return variable at the end of a C function body.
pub(crate) fn emit_fallback_return(name: &str, return_type: ValueType, out: &mut String) {
    let ret_name = name.trim_end_matches('$');
    out.push_str("    return ");
    emit_var_name(
        &IrSymbol {
            name: ret_name.to_string(),
            value_type: return_type,
        },
        out,
    );
    out.push_str(";\n");
}
