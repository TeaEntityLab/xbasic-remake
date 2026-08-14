use crate::semantics::{
    CheckedExpr, CheckedExprKind, CheckedItem, CheckedProgram, CheckedSymbol, ValueType,
};

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
        let mut out = String::new();
        for item in &self.items {
            item.write_summary(&mut out, 0);
        }
        out
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IrItem {
    Version(String),
    Print(IrExpr),
    Dim { symbol: IrSymbol },
    Assignment { target: IrSymbol, value: IrExpr },
    Function { name: String, body: Vec<IrItem> },
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
            CheckedItem::Function { name, body } => Self::Function {
                name: name.clone(),
                body: body.iter().map(Self::lower_item).collect(),
            },
        }
    }

    fn write_summary(&self, out: &mut String, indent: usize) {
        let prefix = "  ".repeat(indent);
        match self {
            Self::Version(value) => out.push_str(&format!("{prefix}version {value}\n")),
            Self::Print(expr) => out.push_str(&format!("{prefix}print {}\n", expr.summary())),
            Self::Dim { symbol } => out.push_str(&format!("{prefix}dim {}\n", symbol.summary())),
            Self::Assignment { target, value } => {
                out.push_str(&format!(
                    "{prefix}assign {} = {}\n",
                    target.summary(),
                    value.summary()
                ));
            }
            Self::Function { name, body } => {
                out.push_str(&format!("{prefix}function {name}\n"));
                for item in body {
                    item.write_summary(out, indent + 1);
                }
                out.push_str(&format!("{prefix}end function\n"));
            }
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
            CheckedExprKind::Symbol(symbol) => IrExprKind::Symbol(IrSymbol::lower(symbol)),
        };
        Self::new(kind, expr.value_type)
    }

    fn summary(&self) -> String {
        match &self.kind {
            IrExprKind::StringLiteral(value) => format!("string({value:?})"),
            IrExprKind::IntegerLiteral(value) => format!("integer({value})"),
            IrExprKind::FloatLiteral(value) => format!("float({value})"),
            IrExprKind::Symbol(symbol) => format!("symbol({})", symbol.summary()),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IrExprKind {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    Symbol(IrSymbol),
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

    fn summary(&self) -> String {
        format!("{}:{}", self.name, value_type_name(self.value_type))
    }
}

fn value_type_name(value_type: ValueType) -> &'static str {
    match value_type {
        ValueType::Integer => "integer",
        ValueType::Float => "float",
        ValueType::String => "string",
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
            IrItem::Function { ref name, ref body }
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
    fn writes_stable_summary_without_debug_formatting() {
        let program =
            parse_program("VERSION \"6.5.0\"\nDIM name$\nname$ = \"hello\"\nPRINT name$\n")
                .unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        let ir = IrProgram::lower(&checked);
        assert_eq!(
            ir.summary(),
            "version 6.5.0\ndim name:string\nassign name:string = string(\"hello\")\nprint symbol(name:string)\n"
        );
    }
}
