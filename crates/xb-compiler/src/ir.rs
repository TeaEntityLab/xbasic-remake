use xb_frontend::{Expression, FunctionDecl, Program, Statement, TypeSuffix};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrProgram {
    pub items: Vec<IrItem>,
}

impl IrProgram {
    pub fn lower(program: &Program) -> Self {
        Self {
            items: program
                .statements
                .iter()
                .map(IrItem::lower_statement)
                .collect(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IrItem {
    Version(String),
    Print(IrExpr),
    Dim { symbol: IrSymbol },
    Function { name: String, body: Vec<IrItem> },
}

impl IrItem {
    fn lower_statement(statement: &Statement) -> Self {
        match statement {
            Statement::Version(value) => Self::Version(value.clone()),
            Statement::Print(expr) => Self::Print(IrExpr::lower(expr)),
            Statement::Dim { name, suffix } => Self::Dim {
                symbol: IrSymbol::new(name.clone(), *suffix),
            },
            Statement::Function(function) => Self::lower_function(function),
        }
    }

    fn lower_function(function: &FunctionDecl) -> Self {
        let body = function.body.iter().map(Self::lower_statement).collect();
        Self::Function {
            name: function.name.clone(),
            body,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IrExpr {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    Symbol(IrSymbol),
}

impl IrExpr {
    fn lower(expr: &Expression) -> Self {
        match expr {
            Expression::StringLiteral(value) => Self::StringLiteral(value.clone()),
            Expression::IntegerLiteral(value) => Self::IntegerLiteral(value.clone()),
            Expression::FloatLiteral(value) => Self::FloatLiteral(value.clone()),
            Expression::Identifier { name, suffix } => {
                Self::Symbol(IrSymbol::new(name.clone(), *suffix))
            }
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrSymbol {
    pub name: String,
    pub suffix: Option<TypeSuffix>,
}

impl IrSymbol {
    pub fn new(name: String, suffix: Option<TypeSuffix>) -> Self {
        Self { name, suffix }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use xb_frontend::parse_program;

    #[test]
    fn lowers_version_function_and_print_into_ir() {
        let program =
            parse_program("VERSION \"6.5.0\"\nFUNCTION Main\nPRINT \"hello\"\nEND FUNCTION\n")
                .unwrap();
        let ir = IrProgram::lower(&program);
        assert_eq!(ir.items.len(), 2);
        assert!(matches!(ir.items[0], IrItem::Version(ref version) if version == "6.5.0"));
        assert!(matches!(
            ir.items[1],
            IrItem::Function { ref name, ref body }
                if name == "Main" && matches!(body.first(), Some(IrItem::Print(IrExpr::StringLiteral(value))) if value == "hello")
        ));
    }
}
