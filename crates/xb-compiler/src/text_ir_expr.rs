use crate::checked::BooleanOp;
use crate::ir::{IrExpr, IrExprKind};

use crate::text_ir::TextIrEmitter;

impl TextIrEmitter {
    pub(crate) fn emit_expr(self, expr: &IrExpr) -> String {
        match &expr.kind {
            IrExprKind::StringLiteral(value) => format!("string({value:?})"),
            IrExprKind::IntegerLiteral(value) => format!("integer({value})"),
            IrExprKind::FloatLiteral(value) => format!("float({value})"),
            IrExprKind::Constant { name, value } => format!(
                "constant($${name}:{} = integer({value}))",
                self.emit_type(expr.value_type)
            ),
            IrExprKind::SharedVariable(symbol) => format!("shared(##{})", self.emit_symbol(symbol)),
            IrExprKind::Symbol(symbol) => format!("symbol({})", self.emit_symbol(symbol)),
            IrExprKind::Comparison { op, left, right } => {
                format!(
                    "compare({} {} {})",
                    self.emit_expr(left),
                    self.emit_op(*op),
                    self.emit_expr(right)
                )
            }
            IrExprKind::Arithmetic { op, left, right } => {
                format!(
                    "arith({} {} {})",
                    self.emit_expr(left),
                    self.emit_arith_op(*op),
                    self.emit_expr(right)
                )
            }
            IrExprKind::Not(inner) => format!("not({})", self.emit_expr(inner)),
            IrExprKind::Boolean { op, left, right } => {
                let s = match op {
                    BooleanOp::And => "and",
                    BooleanOp::Or => "or",
                    BooleanOp::Xor => "xor",
                };
                format!("{}({} {})", s, self.emit_expr(left), self.emit_expr(right))
            }
            IrExprKind::FunctionCall { name, args } => {
                let as_str: Vec<String> = args.iter().map(|a| self.emit_expr(a)).collect();
                format!("call {}({})", name, as_str.join(", "))
            }
            IrExprKind::ArrayAccess { symbol, index } => {
                format!(
                    "array_access({}[{}])",
                    self.emit_symbol(symbol),
                    self.emit_expr(index)
                )
            }
        }
    }
}
