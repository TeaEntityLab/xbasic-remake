use crate::checked::{BooleanOp, LogicalOp, ValueType};
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
            IrExprKind::ByRef(inner) => format!("byref({})", self.emit_expr(inner)),
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
            IrExprKind::Unary { op, operand } => {
                let s = match op {
                    xb_frontend::UnaryOp::Neg => "neg",
                    xb_frontend::UnaryOp::Pos => "pos",
                };
                format!("{}({})", s, self.emit_expr(operand))
            }
            IrExprKind::Boolean { op, left, right } => {
                let s = match op {
                    BooleanOp::And => "and",
                    BooleanOp::Or => "or",
                    BooleanOp::Xor => "xor",
                };
                format!("{}({} {})", s, self.emit_expr(left), self.emit_expr(right))
            }
            IrExprKind::Logical { op, left, right } => {
                let s = match op {
                    LogicalOp::And => "land",
                    LogicalOp::Or => "lor",
                    LogicalOp::Xor => "lxor",
                };
                format!("{}({} {})", s, self.emit_expr(left), self.emit_expr(right))
            }
            IrExprKind::FunctionCall { name, args } => {
                let as_str: Vec<String> = args.iter().map(|a| self.emit_expr(a)).collect();
                format!("call {}({})", name, as_str.join(", "))
            }
            IrExprKind::ArrayAccess { symbol, index, extra_indices } => {
                let mut idx = self.emit_expr(index);
                for e in extra_indices {
                    idx.push(',');
                    idx.push_str(&self.emit_expr(e));
                }
                format!("array_access({}[{}])", self.emit_symbol(symbol), idx)
            }
            IrExprKind::ArrayUBound { symbol } => {
                format!("array_ubound({})", self.emit_symbol(symbol))
            }
            IrExprKind::FuncAddr(name) => format!("funcaddr({name})"),
            IrExprKind::SizeOf { symbol } => {
                format!("size_of({})", self.emit_symbol(symbol))
            }
            IrExprKind::SizeOfType { value_type } => {
                let t = match value_type {
                    ValueType::Integer => "integer",
                    ValueType::Giant => "giant",
                    ValueType::Float => "float",
                    ValueType::String => "string",
                };
                format!("size_of_type({t})")
            }
            IrExprKind::LabelAddress(name) => {
                format!("label_addr({name})")
            }
        }
    }
}
