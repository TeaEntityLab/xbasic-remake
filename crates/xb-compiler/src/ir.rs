use crate::checked::{
    CheckedExpr, CheckedExprKind, CheckedItem, CheckedParam, CheckedProgram, CheckedSymbol,
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
    },
    Assignment {
        target: IrSymbol,
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
    Function {
        name: String,
        params: Vec<IrParam>,
        return_type: ValueType,
        body: Vec<IrItem>,
    },
    Return {
        value: Option<IrExpr>,
    },
}

impl IrItem {
    fn lower_item(item: &CheckedItem) -> Self {
        match item {
            CheckedItem::Version(value) => Self::Version(value.clone()),
            CheckedItem::Print(expr) => Self::Print(IrExpr::lower(expr)),
            CheckedItem::Dim(symbol) => Self::Dim {
                symbol: IrSymbol::lower(symbol),
            },
            CheckedItem::Assignment { target, value } => Self::Assignment {
                target: IrSymbol::lower(target),
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
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrExpr {
    pub kind: IrExprKind,
    pub value_type: ValueType,
}

impl IrExpr {
    fn new(kind: IrExprKind, value_type: ValueType) -> Self {
        Self { kind, value_type }
    }

    fn lower(expr: &CheckedExpr) -> Self {
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
            CheckedExprKind::FunctionCall { name, args } => IrExprKind::FunctionCall {
                name: name.clone(),
                args: args.iter().map(IrExpr::lower).collect(),
            },
        };
        Self::new(kind, expr.value_type)
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
    FunctionCall {
        name: String,
        args: Vec<IrExpr>,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrSymbol {
    pub name: String,
    pub value_type: ValueType,
}

impl IrSymbol {
    fn lower(symbol: &CheckedSymbol) -> Self {
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::semantics::Analyzer;
    use xb_frontend::parse_program;

    #[test]
    fn lowers_version_function_and_print_into_ir() {
        let program =
            parse_program("VERSION \"6.5.0\"\nFUNCTION Main\nPRINT \"hello\"\nEND FUNCTION\n")
                .unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        let ir = IrProgram::lower(&checked);
        assert_eq!(ir.items.len(), 2);
        assert!(matches!(ir.items[0], IrItem::Version(ref version) if version == "6.5.0"));
        assert!(matches!(
            ir.items[1],
            IrItem::Function { ref name, ref body, .. }
                if name == "Main" && matches!(body.first(), Some(IrItem::Print(IrExpr { value_type: ValueType::String, .. })))
        ));
    }
    #[test]
    fn lowers_assignment_into_typed_ir() {
        let program = parse_program("DIM name$\nname$ = \"hello\"\nPRINT name$\n").unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        let ir = IrProgram::lower(&checked);
        assert!(matches!(
            ir.items[1],
            IrItem::Assignment { ref target, ref value }
                if target.name == "name" && target.value_type == ValueType::String && value.value_type == ValueType::String
        ));
    }

    #[test]
    fn lowers_constant_definition_and_reference_into_typed_ir() {
        // Given
        let program = parse_program("$$Answer = 42\nPRINT $$Answer\n").unwrap();
        let checked = Analyzer::analyze(&program).unwrap();

        // When
        let ir = IrProgram::lower(&checked);

        // Then
        assert!(matches!(
            &ir.items[..],
            [
                IrItem::ConstantDefinition { name, value, value_type: ValueType::Integer },
                IrItem::Print(IrExpr { kind: IrExprKind::Constant { name: reference, value: resolved }, value_type: ValueType::Integer })
            ] if name == "Answer" && value == "42" && reference == "Answer" && resolved == "42"
        ));
    }
}
