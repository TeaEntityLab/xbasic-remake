use crate::checked::LogicalOp;
use crate::ir::{IrExpr, IrExprKind};

pub(crate) fn logical_op(op: LogicalOp) -> &'static str {
    match op {
        LogicalOp::And => "&&",
        LogicalOp::Or => "||",
        LogicalOp::Xor => "!=",
    }
}

pub(crate) fn emit_logical(expr: &IrExpr, out: &mut String) {
    if let IrExprKind::Logical { op, left, right } = &expr.kind {
        out.push_str("(((");
        crate::c_emit_expr::emit_expr(left, out);
        out.push_str(") != 0) ");
        out.push_str(logical_op(*op));
        out.push_str(" ((");
        crate::c_emit_expr::emit_expr(right, out);
        out.push_str(") != 0)) ? -1 : 0");
    }
}
