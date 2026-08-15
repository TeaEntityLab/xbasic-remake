use crate::checked::{ArithmeticOp, BooleanOp, ComparisonOp};
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
                out.push_str("(strcmp(");
                emit_expr(left, out);
                out.push_str(", ");
                emit_expr(right, out);
                out.push_str(") ");
                out.push_str(cmp_op(*op));
                out.push_str(" 0)");
            } else {
                out.push('(');
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

fn emit_c_function_name(name: &str, out: &mut String) {
    match name {
        "LEN" => out.push_str("xb_len"),
        "ASC" => out.push_str("xb_asc"),
        "CHR$" => out.push_str("xb_chr"),
        "LEFT$" => out.push_str("xb_left"),
        "RIGHT$" => out.push_str("xb_right"),
        "MID$" => out.push_str("xb_mid"),
        "INSTR" => out.push_str("xb_instr"),
        "VAL" => out.push_str("xb_val"),
        "STR$" => out.push_str("xb_str_num"),
        "READLINE$" => out.push_str("xb_readline"),
        "EOF" => out.push_str("xb_eof"),
        _ => {
            out.push_str("xb_user_");
            out.push_str(name);
        }
    }
}

fn cmp_op(op: ComparisonOp) -> &'static str {
    match op {
        ComparisonOp::Equal => "==",
        ComparisonOp::NotEqual => "!=",
        ComparisonOp::Less => "<",
        ComparisonOp::Greater => ">",
        ComparisonOp::LessEqual => "<=",
        ComparisonOp::GreaterEqual => ">=",
    }
}

fn arith_op(op: ArithmeticOp) -> &'static str {
    match op {
        ArithmeticOp::Add => "+",
        ArithmeticOp::Sub => "-",
        ArithmeticOp::Mul => "*",
        ArithmeticOp::Div => "/",
    }
}

fn boolean_op(op: BooleanOp) -> &'static str {
    match op {
        BooleanOp::And => "&",
        BooleanOp::Or => "|",
    }
}

fn emit_c_string(s: &str, out: &mut String) {
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\t' => out.push_str("\\t"),
            '\r' => out.push_str("\\r"),
            '\0' => out.push_str("\\0"),
            c if (c as u32) < 0x20 => {
                out.push_str(&format!("\\x{:02x}", c as u32));
            }
            c => out.push(c),
        }
    }
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
