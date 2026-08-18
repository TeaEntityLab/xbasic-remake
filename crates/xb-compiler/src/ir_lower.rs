use crate::checked::{CheckedExpr, CheckedExprKind, CheckedItem, CheckedParam, CheckedSymbol};
use crate::ir::{IrCaseClause, IrExpr, IrExprKind, IrItem, IrParam, IrSymbol};

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
            CheckedExprKind::ByRef(inner) => IrExprKind::ByRef(Box::new(IrExpr::lower(inner))),
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
            CheckedExprKind::Unary { op, operand } => IrExprKind::Unary {
                op: *op,
                operand: Box::new(IrExpr::lower(operand)),
            },
            CheckedExprKind::Boolean { op, left, right } => IrExprKind::Boolean {
                op: *op,
                left: Box::new(IrExpr::lower(left)),
                right: Box::new(IrExpr::lower(right)),
            },
            CheckedExprKind::Logical { op, left, right } => IrExprKind::Logical {
                op: *op,
                left: Box::new(IrExpr::lower(left)),
                right: Box::new(IrExpr::lower(right)),
            },
            CheckedExprKind::ArrayAccess { symbol, index } => IrExprKind::ArrayAccess {
                symbol: IrSymbol::lower(symbol),
                index: Box::new(IrExpr::lower(index)),
            },
            CheckedExprKind::ArrayRef { symbol } => IrExprKind::Symbol(IrSymbol::lower(symbol)),
            CheckedExprKind::ArrayUBound { symbol } => IrExprKind::ArrayUBound {
                symbol: IrSymbol::lower(symbol),
            },
            CheckedExprKind::SizeOf { symbol } => IrExprKind::SizeOf {
                symbol: IrSymbol::lower(symbol),
            },
            CheckedExprKind::SizeOfType { value_type } => IrExprKind::SizeOfType {
                value_type: *value_type,
            },
            CheckedExprKind::FunctionCall { name, args } => IrExprKind::FunctionCall {
                name: name.clone(),
                args: args.iter().map(IrExpr::lower).collect(),
            },
            CheckedExprKind::LabelAddress(name) => IrExprKind::LabelAddress(name.clone()),
        };
        Self::new(kind, expr.value_type)
    }
}
impl IrItem {
    pub(crate) fn lower_item(item: &CheckedItem) -> Self {
        match item {
            CheckedItem::Version(value) => Self::Version(value.clone()),
            CheckedItem::ProgramName(value) => Self::ProgramName(value.clone()),
            CheckedItem::Print { items, separators } => Self::Print {
                items: items.iter().map(IrExpr::lower).collect(),
                separators: separators.clone(),
            },
            CheckedItem::Dim {
                symbol,
                size,
                is_array,
                redim,
            } => Self::Dim {
                symbol: IrSymbol::lower(symbol),
                size: size.as_ref().map(IrExpr::lower),
                is_array: *is_array,
                redim: *redim,
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
            CheckedItem::MidAssign {
                target,
                start,
                length,
                value,
            } => Self::MidAssign {
                target: IrExpr::lower(target),
                start: IrExpr::lower(start),
                length: length.as_ref().map(|e| IrExpr::lower(e)),
                value: IrExpr::lower(value),
            },
            CheckedItem::BuiltinAssign { name, args, value } => Self::BuiltinAssign {
                name: name.clone(),
                args: args.iter().map(IrExpr::lower).collect(),
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
            CheckedItem::ExitSelect => Self::ExitSelect,
            CheckedItem::Swap { left, right } => Self::Swap {
                left: IrSymbol::lower(left),
                right: IrSymbol::lower(right),
            },
            CheckedItem::Nop => Self::Nop,
            CheckedItem::SelectCase {
                selector,
                cases,
                default,
            } => Self::SelectCase {
                selector: IrExpr::lower(selector),
                cases: cases
                    .iter()
                    .map(|c| IrCaseClause {
                        conditions: c.conditions.iter().map(IrExpr::lower).collect(),
                        body: c.body.iter().map(Self::lower_item).collect(),
                    })
                    .collect(),
                default: default
                    .as_ref()
                    .map(|d| d.iter().map(Self::lower_item).collect()),
            },
            CheckedItem::Compound(items) => {
                Self::Compound(items.iter().map(Self::lower_item).collect())
            }
            CheckedItem::Read(symbols) => {
                let mut items: Vec<Self> = symbols
                    .iter()
                    .map(|s| Self::Dim {
                        symbol: IrSymbol::lower(s),
                        size: None,
                        is_array: false,
                        redim: false,
                    })
                    .collect();
                items.push(Self::Read(symbols.iter().map(IrSymbol::lower).collect()));
                Self::Compound(items)
            }
            CheckedItem::Restore(label) => Self::Restore(label.clone()),
            CheckedItem::Stop => Self::Stop,
            CheckedItem::Gosub(name) => Self::Gosub(name.clone()),
            CheckedItem::Label(name) => Self::Label(name.clone()),
            CheckedItem::Goto(name) => Self::Goto(name.clone()),
            CheckedItem::GosubReturn => Self::GosubReturn,
            CheckedItem::GosubExpr(expr) => Self::GosubExpr(IrExpr::lower(expr)),
            CheckedItem::GotoExpr(expr) => Self::GotoExpr(IrExpr::lower(expr)),
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
