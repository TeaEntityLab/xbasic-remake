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
    #[error("duplicate constant {name}")]
    DuplicateConstant { name: String },
    #[error("unknown constant {name}")]
    UnknownConstant { name: String },
    #[error("constant definition {name} is not at top level")]
    ConstantDefinitionNotTopLevel { name: String },
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
    ConstantDefinition {
        name: String,
        value: String,
        value_type: ValueType,
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
    Constant { name: String, value: String },
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
    constants: BTreeMap<String, String>,
}

#[derive(Debug, Clone, Copy)]
enum Scope {
    TopLevel,
    Function,
}

impl Analyzer {
    pub fn analyze(program: &Program) -> Result<CheckedProgram, SemanticError> {
        let mut analyzer = Self::default();
        analyzer.program(program)
    }

    fn program(&mut self, program: &Program) -> Result<CheckedProgram, SemanticError> {
        let mut items = Vec::with_capacity(program.statements.len());
        for statement in &program.statements {
            items.push(self.statement(statement, Scope::TopLevel)?);
        }
        Ok(CheckedProgram { items })
    }

    fn statement(
        &mut self,
        statement: &Statement,
        scope: Scope,
    ) -> Result<CheckedItem, SemanticError> {
        match statement {
            Statement::Version(value) => Ok(CheckedItem::Version(value.clone())),
            Statement::Print(expr) => Ok(CheckedItem::Print(self.expr(expr)?)),
            Statement::Dim { name, suffix } => self.dim(name, *suffix),
            Statement::Assignment { target, value, .. } => self.assignment(target, value),
            Statement::ConstantDefinition { name, value } => match scope {
                Scope::TopLevel => self.constant_definition(name, value),
                Scope::Function => {
                    Err(SemanticError::ConstantDefinitionNotTopLevel { name: name.clone() })
                }
            },
            Statement::Function(function) => self.function(function),
        }
    }

    fn constant_definition(
        &mut self,
        name: &str,
        value: &str,
    ) -> Result<CheckedItem, SemanticError> {
        if self
            .constants
            .insert(name.to_owned(), value.to_owned())
            .is_some()
        {
            return Err(SemanticError::DuplicateConstant {
                name: name.to_owned(),
            });
        }
        Ok(CheckedItem::ConstantDefinition {
            name: name.to_owned(),
            value: value.to_owned(),
            value_type: ValueType::Integer,
        })
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

    fn function(&self, function: &FunctionDecl) -> Result<CheckedItem, SemanticError> {
        let mut scoped = Self {
            symbols: BTreeMap::new(),
            constants: self.constants.clone(),
        };
        let body = function
            .body
            .iter()
            .map(|statement| scoped.statement(statement, Scope::Function))
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
            Expression::SystemConstant { name } => self.constant(name),
            Expression::Identifier { name, .. } => self.symbol(name),
        }
    }

    fn constant(&self, name: &str) -> Result<CheckedExpr, SemanticError> {
        let Some(value) = self.constants.get(name) else {
            return Err(SemanticError::UnknownConstant {
                name: name.to_owned(),
            });
        };
        Ok(CheckedExpr::new(
            CheckedExprKind::Constant {
                name: name.to_owned(),
                value: value.clone(),
            },
            ValueType::Integer,
        ))
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
