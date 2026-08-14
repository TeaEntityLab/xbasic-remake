use crate::checked::{
    ArithmeticOp, BooleanOp, CheckedItem, CheckedParam, CheckedProgram, CheckedSymbol,
    ComparisonOp, ValueType,
};
use crate::text_ir::TextIrEmitter;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrProgram {
    pub items: Vec<IrItem>,
}

impl IrProgram {
    pub fn lower(program: &CheckedProgram) -> Self {
        Self {
            items: program.items.iter().map(IrItem::lower_item).collect(),
        }
    }

    pub fn summary(&self) -> String {
        TextIrEmitter::new().emit_program(self)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IrItem {
    Version(String),
    Print(IrExpr),
    Dim {
        symbol: IrSymbol,
        size: Option<IrExpr>,
    },
    Assignment {
        target: IrSymbol,
        value: IrExpr,
    },
    ArrayAssignment {
        target: IrSymbol,
        index: IrExpr,
        value: IrExpr,
    },
    ConstantDefinition {
        name: String,
        value: String,
        value_type: ValueType,
    },
    SharedAssignment {
        target: IrSymbol,
        value: IrExpr,
    },
    If {
        condition: IrExpr,
        then_body: Vec<IrItem>,
        else_body: Option<Vec<IrItem>>,
    },
    While {
        condition: IrExpr,
        body: Vec<IrItem>,
    },
    For {
        var: IrSymbol,
        start: IrExpr,
        end: IrExpr,
        body: Vec<IrItem>,
    },
    Function {
        name: String,
        params: Vec<IrParam>,
        return_type: ValueType,
        body: Vec<IrItem>,
    },
    Return {
        value: Option<IrExpr>,
    },
    Call {
        name: String,
        args: Vec<IrExpr>,
    },
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
            CheckedItem::For {
                var,
                start,
                end,
                body,
            } => Self::For {
                var: IrSymbol::lower(var),
                start: IrExpr::lower(start),
                end: IrExpr::lower(end),
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
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrExpr {
    pub kind: IrExprKind,
    pub value_type: ValueType,
}

impl IrExpr {
    pub(crate) fn new(kind: IrExprKind, value_type: ValueType) -> Self {
        Self { kind, value_type }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IrExprKind {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    Constant {
        name: String,
        value: String,
    },
    SharedVariable(IrSymbol),
    Symbol(IrSymbol),
    Comparison {
        op: ComparisonOp,
        left: Box<IrExpr>,
        right: Box<IrExpr>,
    },
    Arithmetic {
        op: ArithmeticOp,
        left: Box<IrExpr>,
        right: Box<IrExpr>,
    },
    Not(Box<IrExpr>),
    Boolean {
        op: BooleanOp,
        left: Box<IrExpr>,
        right: Box<IrExpr>,
    },
    FunctionCall {
        name: String,
        args: Vec<IrExpr>,
    },
    ArrayAccess {
        symbol: IrSymbol,
        index: Box<IrExpr>,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrSymbol {
    pub name: String,
    pub value_type: ValueType,
}

impl IrSymbol {
    pub(crate) fn lower(symbol: &CheckedSymbol) -> Self {
        Self {
            name: symbol.name.clone(),
            value_type: symbol.value_type,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrParam {
    pub name: String,
    pub value_type: ValueType,
}

impl IrParam {
    fn lower(p: &CheckedParam) -> Self {
        Self {
            name: p.name.clone(),
            value_type: p.value_type,
        }
    }
}
