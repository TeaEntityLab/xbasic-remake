use crate::checked::{
    ArithmeticOp, BooleanOp, CheckedProgram, ComparisonOp, LogicalOp, PrintSep, ValueType,
};
use crate::text_ir::TextIrEmitter;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrProgram {
    pub items: Vec<IrItem>,
    pub data_values: Vec<(String, String)>,
}
impl IrProgram {
    pub fn lower(program: &CheckedProgram) -> Self {
        Self {
            items: program.items.iter().map(IrItem::lower_item).collect(),
            data_values: program
                .data_values
                .iter()
                .map(|dv| match dv {
                    xb_frontend::DataValue::Integer(s) => ("int".to_string(), s.clone()),
                    xb_frontend::DataValue::Float(s) => ("float".to_string(), s.clone()),
                    xb_frontend::DataValue::String(s) => ("string".to_string(), s.clone()),
                })
                .collect(),
        }
    }

    pub fn summary(&self) -> String {
        TextIrEmitter::new().emit_program(self)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IrItem {
    Version(String),
    ProgramName(String),
    Print {
        items: Vec<IrExpr>,
        separators: Vec<PrintSep>,
    },
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
    MidAssign {
        target: IrExpr,
        start: IrExpr,
        length: Option<IrExpr>,
        value: IrExpr,
    },
    BuiltinAssign {
        name: String,
        args: Vec<IrExpr>,
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
    DoLoop {
        pre_condition: Option<(IrExpr, bool)>,
        post_condition: Option<(IrExpr, bool)>,
        body: Vec<IrItem>,
    },
    For {
        var: IrSymbol,
        start: IrExpr,
        end: IrExpr,
        step: Option<IrExpr>,
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
    ExitLoop,
    ExitSelect,
    Swap {
        left: IrSymbol,
        right: IrSymbol,
    },
    Nop,
    SelectCase {
        selector: IrExpr,
        cases: Vec<IrCaseClause>,
        default: Option<Vec<IrItem>>,
    },
    Compound(Vec<IrItem>),
    Read(Vec<IrSymbol>),
    Stop,
    Restore(Option<String>),
    Gosub(String),
    Label(String),
    Goto(String),
    GosubReturn,
    GosubExpr(IrExpr),
    GotoExpr(IrExpr),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrCaseClause {
    pub conditions: Vec<IrExpr>,
    pub body: Vec<IrItem>,
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
    /// `@expr` pass-by-reference argument (see `CheckedExprKind::ByRef`).
    ByRef(Box<IrExpr>),
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
    Unary {
        op: xb_frontend::UnaryOp,
        operand: Box<IrExpr>,
    },
    Not(Box<IrExpr>),
    Boolean {
        op: BooleanOp,
        left: Box<IrExpr>,
        right: Box<IrExpr>,
    },
    Logical {
        op: LogicalOp,
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
    ArrayUBound {
        symbol: IrSymbol,
    },
    SizeOf {
        symbol: IrSymbol,
    },
    SizeOfType {
        value_type: ValueType,
    },
    LabelAddress(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrSymbol {
    pub name: String,
    pub value_type: ValueType,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrParam {
    pub name: String,
    pub value_type: ValueType,
}
