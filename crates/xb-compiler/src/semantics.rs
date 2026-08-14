use std::collections::BTreeMap;
use thiserror::Error;
use xb_frontend::{Expression, FunctionDecl, Program, Statement, TypeSuffix};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ValueType {
    Integer,
    Float,
    String,
}

impl ValueType {
    pub const fn from_suffix(suffix: Option<TypeSuffix>) -> Self {
        match suffix {
            Some(TypeSuffix::String) => Self::String,
            Some(TypeSuffix::Single | TypeSuffix::Double) => Self::Float,
            Some(TypeSuffix::Integer) | None => Self::Integer,
        }
    }
}

#[derive(Debug, Error, PartialEq, Eq)]
pub enum SemanticError {
    #[error("duplicate symbol {name}")]
    DuplicateSymbol { name: String },
    #[error("unknown symbol {name}")]
    UnknownSymbol { name: String },
    #[error("type mismatch for {name}: expected {expected:?}, got {actual:?}")]
    TypeMismatch {
        name: String,
        expected: ValueType,
        actual: ValueType,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedProgram {
    pub items: Vec<CheckedItem>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CheckedItem {
    Version(String),
    Print(CheckedExpr),
    Dim(CheckedSymbol),
    Assignment {
        target: CheckedSymbol,
        value: CheckedExpr,
    },
    Function {
        name: String,
        body: Vec<CheckedItem>,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedExpr {
    pub kind: CheckedExprKind,
    pub value_type: ValueType,
}

impl CheckedExpr {
    fn new(kind: CheckedExprKind, value_type: ValueType) -> Self {
        Self { kind, value_type }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CheckedExprKind {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    Symbol(CheckedSymbol),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CheckedSymbol {
    pub name: String,
    pub value_type: ValueType,
}

impl CheckedSymbol {
    fn new(name: String, value_type: ValueType) -> Self {
        Self { name, value_type }
    }
}

#[derive(Debug, Default)]
pub struct Analyzer {
    symbols: BTreeMap<String, ValueType>,
}

impl Analyzer {
    pub fn analyze(program: &Program) -> Result<CheckedProgram, SemanticError> {
        let mut analyzer = Self::default();
        analyzer.program(program)
    }

    fn program(&mut self, program: &Program) -> Result<CheckedProgram, SemanticError> {
        let mut items = Vec::with_capacity(program.statements.len());
        for statement in &program.statements {
            items.push(self.statement(statement)?);
        }
        Ok(CheckedProgram { items })
    }

    fn statement(&mut self, statement: &Statement) -> Result<CheckedItem, SemanticError> {
        match statement {
            Statement::Version(value) => Ok(CheckedItem::Version(value.clone())),
            Statement::Print(expr) => Ok(CheckedItem::Print(self.expr(expr)?)),
            Statement::Dim { name, suffix } => self.dim(name, *suffix),
            Statement::Assignment { target, value, .. } => self.assignment(target, value),
            Statement::Function(function) => self.function(function),
        }
    }

    fn dim(
        &mut self,
        name: &str,
        suffix: Option<TypeSuffix>,
    ) -> Result<CheckedItem, SemanticError> {
        let value_type = ValueType::from_suffix(suffix);
        if self.symbols.insert(name.to_owned(), value_type).is_some() {
            return Err(SemanticError::DuplicateSymbol {
                name: name.to_owned(),
            });
        }
        Ok(CheckedItem::Dim(CheckedSymbol::new(
            name.to_owned(),
            value_type,
        )))
    }

    fn assignment(&self, name: &str, value: &Expression) -> Result<CheckedItem, SemanticError> {
        let target = self.checked_symbol(name)?;
        let value = self.expr(value)?;
        if target.value_type != value.value_type {
            return Err(SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: target.value_type,
                actual: value.value_type,
            });
        }
        Ok(CheckedItem::Assignment { target, value })
    }

    fn function(&mut self, function: &FunctionDecl) -> Result<CheckedItem, SemanticError> {
        let mut scoped = Self::default();
        let body = function
            .body
            .iter()
            .map(|statement| scoped.statement(statement))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(CheckedItem::Function {
            name: function.name.clone(),
            body,
        })
    }

    fn expr(&self, expr: &Expression) -> Result<CheckedExpr, SemanticError> {
        match expr {
            Expression::StringLiteral(value) => Ok(CheckedExpr::new(
                CheckedExprKind::StringLiteral(value.clone()),
                ValueType::String,
            )),
            Expression::IntegerLiteral(value) => Ok(CheckedExpr::new(
                CheckedExprKind::IntegerLiteral(value.clone()),
                ValueType::Integer,
            )),
            Expression::FloatLiteral(value) => Ok(CheckedExpr::new(
                CheckedExprKind::FloatLiteral(value.clone()),
                ValueType::Float,
            )),
            Expression::Identifier { name, .. } => self.symbol(name),
        }
    }

    fn symbol(&self, name: &str) -> Result<CheckedExpr, SemanticError> {
        let symbol = self.checked_symbol(name)?;
        Ok(CheckedExpr::new(
            CheckedExprKind::Symbol(symbol.clone()),
            symbol.value_type,
        ))
    }

    fn checked_symbol(&self, name: &str) -> Result<CheckedSymbol, SemanticError> {
        let Some(value_type) = self.symbols.get(name).copied() else {
            return Err(SemanticError::UnknownSymbol {
                name: name.to_owned(),
            });
        };
        Ok(CheckedSymbol::new(name.to_owned(), value_type))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use xb_frontend::parse_program;

    #[test]
    fn resolves_dimmed_symbol_when_printed() {
        let program = parse_program("DIM name$\nPRINT name$\n").unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        assert!(matches!(
            checked.items[1],
            CheckedItem::Print(CheckedExpr {
                value_type: ValueType::String,
                ..
            })
        ));
    }

    #[test]
    fn accepts_assignment_when_type_matches_dimmed_symbol() {
        let program = parse_program("DIM name$\nname$ = \"hello\"\n").unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        assert!(
            matches!(checked.items[1], CheckedItem::Assignment { ref target, ref value } if target.value_type == ValueType::String && value.value_type == ValueType::String)
        );
    }

    #[test]
    fn rejects_assignment_to_unknown_symbol() {
        let program = parse_program("name$ = \"hello\"\n").unwrap();
        let result = Analyzer::analyze(&program);
        assert!(matches!(result, Err(SemanticError::UnknownSymbol { ref name }) if name == "name"));
    }

    #[test]
    fn rejects_assignment_type_mismatch() {
        let program = parse_program("DIM name$\nname$ = 42\n").unwrap();
        let result = Analyzer::analyze(&program);
        assert!(matches!(
            result,
            Err(SemanticError::TypeMismatch {
                ref name,
                expected: ValueType::String,
                actual: ValueType::Integer,
            }) if name == "name"
        ));
    }

    #[test]
    fn rejects_duplicate_symbols_in_scope() {
        let program = parse_program("DIM name$\nDIM name$\n").unwrap();
        let result = Analyzer::analyze(&program);
        assert!(
            matches!(result, Err(SemanticError::DuplicateSymbol { ref name }) if name == "name")
        );
    }

    #[test]
    fn rejects_unknown_symbol_in_print() {
        let program = parse_program("PRINT missing\n").unwrap();
        let result = Analyzer::analyze(&program);
        assert!(
            matches!(result, Err(SemanticError::UnknownSymbol { ref name }) if name == "missing")
        );
    }
}
