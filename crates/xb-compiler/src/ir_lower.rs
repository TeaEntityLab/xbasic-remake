use crate::checked::{CheckedExpr, CheckedExprKind, CheckedItem, CheckedParam, CheckedSymbol};
use crate::ir::{IrExpr, IrExprKind, IrItem, IrParam, IrSymbol};

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
impl IrItem {
    pub(crate) fn lower_item(item: &CheckedItem) -> Self {
        match item {
            CheckedItem::Version(value) => Self::Version(value.clone()),
            CheckedItem::Print(expr) => Self::Print(IrExpr::lower(expr)),
            CheckedItem::Dim { symbol, size } => Self::Dim {
                symbol: IrSymbol::lower(symbol),
                size: size.as_ref().map(IrExpr::lower),
            },
            CheckedItem::Assignment { target, value } => Self::Assignment {
                target: IrSymbol::lower(target),
                value: IrExpr::lower(value),
            },
            CheckedItem::ArrayAssignment {
                target,
                index,
                value,
            } => Self::ArrayAssignment {
                target: IrSymbol::lower(target),
                index: IrExpr::lower(index),
                value: IrExpr::lower(value),
            },
            CheckedItem::ConstantDefinition {
                name,
                value,
                value_type,
            } => Self::ConstantDefinition {
                name: name.clone(),
                value: value.clone(),
                value_type: *value_type,
            },
            CheckedItem::If {
                condition,
                then_body,
                else_body,
            } => Self::If {
                condition: IrExpr::lower(condition),
                then_body: then_body.iter().map(Self::lower_item).collect(),
                else_body: else_body
                    .as_ref()
                    .map(|body| body.iter().map(Self::lower_item).collect()),
            },
            CheckedItem::While { condition, body } => Self::While {
                condition: IrExpr::lower(condition),
                body: body.iter().map(Self::lower_item).collect(),
            },
            CheckedItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => Self::DoLoop {
                pre_condition: pre_condition
                    .as_ref()
                    .map(|(e, is_while)| (IrExpr::lower(e), *is_while)),
                post_condition: post_condition
                    .as_ref()
                    .map(|(e, is_while)| (IrExpr::lower(e), *is_while)),
                body: body.iter().map(Self::lower_item).collect(),
            },
            CheckedItem::For {
                var,
                start,
                end,
                step,
                body,
            } => Self::For {
                var: IrSymbol::lower(var),
                start: IrExpr::lower(start),
                end: IrExpr::lower(end),
                step: step.as_ref().map(IrExpr::lower),
                body: body.iter().map(Self::lower_item).collect(),
            },
            CheckedItem::SharedAssignment { target, value } => Self::SharedAssignment {
                target: IrSymbol::lower(target),
                value: IrExpr::lower(value),
            },
            CheckedItem::Function {
                name,
                params,
                return_type,
                body,
            } => Self::Function {
                name: name.clone(),
                params: params.iter().map(IrParam::lower).collect(),
                return_type: *return_type,
                body: body.iter().map(Self::lower_item).collect(),
            },
            CheckedItem::Return { value } => Self::Return {
                value: value.as_ref().map(IrExpr::lower),
            },
            CheckedItem::Call { name, args } => Self::Call {
                name: name.clone(),
                args: args.iter().map(IrExpr::lower).collect(),
            },
            CheckedItem::ExitLoop => Self::ExitLoop,
        }
    }
}

impl IrSymbol {
    pub(crate) fn lower(symbol: &CheckedSymbol) -> Self {
        Self {
            name: symbol.name.clone(),
            value_type: symbol.value_type,
        }
    }
}

impl IrParam {
    pub(crate) fn lower(p: &CheckedParam) -> Self {
        Self {
            name: p.name.clone(),
            value_type: p.value_type,
        }
    }
}
