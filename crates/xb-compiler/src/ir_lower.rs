use crate::checked::{CheckedExpr, CheckedExprKind};
use crate::ir::{IrExpr, IrExprKind, IrSymbol};

impl IrExpr {
    pub(crate) fn lower(expr: &CheckedExpr) -> Self {
        let kind = match &expr.kind {
            CheckedExprKind::StringLiteral(value) => IrExprKind::StringLiteral(value.clone()),
            CheckedExprKind::IntegerLiteral(value) => IrExprKind::IntegerLiteral(value.clone()),
            CheckedExprKind::FloatLiteral(value) => IrExprKind::FloatLiteral(value.clone()),
            CheckedExprKind::Constant { name, value } => IrExprKind::Constant {
                name: name.clone(),
                value: value.clone(),
            },
            CheckedExprKind::SharedVariable(symbol) => {
                IrExprKind::SharedVariable(IrSymbol::lower(symbol))
            }
            CheckedExprKind::Symbol(symbol) => IrExprKind::Symbol(IrSymbol::lower(symbol)),
            CheckedExprKind::Comparison { op, left, right } => IrExprKind::Comparison {
                op: *op,
                left: Box::new(IrExpr::lower(left)),
                right: Box::new(IrExpr::lower(right)),
            },
            CheckedExprKind::Arithmetic { op, left, right } => IrExprKind::Arithmetic {
                op: *op,
                left: Box::new(IrExpr::lower(left)),
                right: Box::new(IrExpr::lower(right)),
            },
            CheckedExprKind::Not(inner) => IrExprKind::Not(Box::new(IrExpr::lower(inner))),
            CheckedExprKind::Boolean { op, left, right } => IrExprKind::Boolean {
                op: *op,
                left: Box::new(IrExpr::lower(left)),
                right: Box::new(IrExpr::lower(right)),
            },
            CheckedExprKind::ArrayAccess { symbol, index } => IrExprKind::ArrayAccess {
                symbol: IrSymbol::lower(symbol),
                index: Box::new(IrExpr::lower(index)),
            },
            CheckedExprKind::FunctionCall { name, args } => IrExprKind::FunctionCall {
                name: name.clone(),
                args: args.iter().map(IrExpr::lower).collect(),
            },
        };
        Self::new(kind, expr.value_type)
    }
}
