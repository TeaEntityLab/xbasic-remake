use crate::checked::{ArithmeticOp, ComparisonOp};
use crate::ir::IrSymbol;
use crate::text_ir::TextIrEmitter;
use crate::ValueType;

impl TextIrEmitter {
    pub(crate) fn emit_op(self, op: ComparisonOp) -> &'static str {
        match op {
            ComparisonOp::Equal => "=",
            ComparisonOp::NotEqual => "<>",
            ComparisonOp::Less => "<",
            ComparisonOp::Greater => ">",
            ComparisonOp::LessEqual => "<=",
            ComparisonOp::GreaterEqual => ">=",
        }
    }
    pub(crate) fn emit_arith_op(self, op: ArithmeticOp) -> &'static str {
        match op {
            ArithmeticOp::Add => "+",
            ArithmeticOp::Sub => "-",
            ArithmeticOp::Mul => "*",
            ArithmeticOp::Div => "/",
            ArithmeticOp::IntegerDiv => "\\",
            ArithmeticOp::Mod => "mod",
            ArithmeticOp::Pow => "**",
        }
    }
    pub(crate) fn emit_symbol(self, symbol: &IrSymbol) -> String {
        format!("{}:{}", symbol.name, self.emit_type(symbol.value_type))
    }
    pub(crate) fn emit_type(self, value_type: ValueType) -> &'static str {
        match value_type {
            ValueType::Integer => "integer",
            ValueType::Float => "float",
            ValueType::String => "string",
        }
    }
}
