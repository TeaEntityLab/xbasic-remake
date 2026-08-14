use std::collections::BTreeMap;
use xb_frontend::{ComparisonOp, Expression, FunctionDecl, Program, Statement, TypeSuffix};

pub use crate::checked::{
    CheckedExpr, CheckedExprKind, CheckedItem, CheckedProgram, CheckedSymbol, SemanticError,
    ValueType,
};

type ExprResult = Result<CheckedExpr, SemanticError>;
type ItemResult = Result<CheckedItem, SemanticError>;

#[derive(Debug, Default)]
pub struct Analyzer {
    symbols: BTreeMap<String, ValueType>,
    constants: BTreeMap<String, String>,
    shared: BTreeMap<String, ValueType>,
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

    fn statement(&mut self, statement: &Statement, scope: Scope) -> ItemResult {
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
            Statement::SharedAssignment {
                name,
                suffix,
                value,
            } => match scope {
                Scope::Function => self.shared_assignment(name, *suffix, value),
                Scope::TopLevel => {
                    Err(SemanticError::SharedAssignmentNotInFunction { name: name.clone() })
                }
            },
            Statement::If {
                condition,
                then_body,
                else_body,
            } => {
                let cond = self.expr(condition)?;
                if cond.value_type != ValueType::Integer {
                    return Err(SemanticError::IfConditionNotInteger {
                        actual: cond.value_type,
                    });
                }
                let then_body = self.blk(then_body, scope)?;
                let eb = else_body.as_ref().map(|b| self.blk(b, scope)).transpose()?;
                Ok(CheckedItem::If {
                    condition: cond,
                    then_body,
                    else_body: eb,
                })
            }
            Statement::Function(function) => self.function(function),
        }
    }

    fn constant_definition(&mut self, name: &str, value: &str) -> ItemResult {
        match self.constants.insert(name.to_owned(), value.to_owned()) {
            Some(_) => Err(SemanticError::DuplicateConstant {
                name: name.to_owned(),
            }),
            None => Ok(CheckedItem::ConstantDefinition {
                name: name.to_owned(),
                value: value.to_owned(),
                value_type: ValueType::Integer,
            }),
        }
    }
    fn shared_assignment(
        &mut self,
        name: &str,
        s: Option<TypeSuffix>,
        v: &Expression,
    ) -> ItemResult {
        let value = self.expr(v)?;
        let vt = self.declare_shared(name, s)?;
        if vt != value.value_type {
            return Err(SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: vt,
                actual: value.value_type,
            });
        }
        Ok(CheckedItem::SharedAssignment {
            target: CheckedSymbol::new(name.to_owned(), vt),
            value,
        })
    }
    fn declare_shared(
        &mut self,
        name: &str,
        s: Option<TypeSuffix>,
    ) -> Result<ValueType, SemanticError> {
        let req = ValueType::from_suffix(s);
        let declared = *self.shared.entry(name.to_owned()).or_insert(req);
        if declared == req {
            Ok(declared)
        } else {
            Err(SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: req,
                actual: declared,
            })
        }
    }

    fn dim(&mut self, name: &str, suffix: Option<TypeSuffix>) -> ItemResult {
        let vt = ValueType::from_suffix(suffix);
        match self.symbols.insert(name.to_owned(), vt) {
            Some(_) => Err(SemanticError::DuplicateSymbol {
                name: name.to_owned(),
            }),
            None => Ok(CheckedItem::Dim(CheckedSymbol::new(name.to_owned(), vt))),
        }
    }

    fn assignment(&self, name: &str, value: &Expression) -> ItemResult {
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

    fn function(&mut self, function: &FunctionDecl) -> ItemResult {
        let mut scoped = Self {
            symbols: BTreeMap::new(),
            constants: self.constants.clone(),
            shared: self.shared.clone(),
        };
        let body = scoped.blk(&function.body, Scope::Function)?;
        self.shared = scoped.shared;
        Ok(CheckedItem::Function {
            name: function.name.clone(),
            body,
        })
    }

    fn expr(&self, expr: &Expression) -> ExprResult {
        match expr {
            Expression::IntegerLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::IntegerLiteral(v.clone()),
                ValueType::Integer,
            )),
            Expression::FloatLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::FloatLiteral(v.clone()),
                ValueType::Float,
            )),
            Expression::StringLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::StringLiteral(v.clone()),
                ValueType::String,
            )),
            Expression::SystemConstant { name } => self.constant(name),
            Expression::SystemVariable { name, suffix } => self.shared_variable(name, *suffix),
            Expression::Identifier { name, .. } => self.symbol(name),
            Expression::Comparison { op, left, right } => self.comparison(*op, left, right),
        }
    }

    fn comparison(&self, op: ComparisonOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        if lv.value_type != rv.value_type {
            return Err(SemanticError::ComparisonTypeMismatch {
                left: lv.value_type,
                right: rv.value_type,
            });
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::Comparison {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            ValueType::Integer,
        ))
    }

    fn constant(&self, name: &str) -> ExprResult {
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

    fn shared_variable(&self, name: &str, s: Option<TypeSuffix>) -> ExprResult {
        let Some(declared) = self.shared.get(name).copied() else {
            return Err(SemanticError::UnknownSharedVariable {
                name: name.to_owned(),
            });
        };
        let requested = ValueType::from_suffix(s);
        if declared != requested {
            return Err(SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: requested,
                actual: declared,
            });
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::SharedVariable(CheckedSymbol::new(name.to_owned(), declared)),
            declared,
        ))
    }

    fn symbol(&self, name: &str) -> ExprResult {
        let s = self.checked_symbol(name)?;
        Ok(CheckedExpr::new(
            CheckedExprKind::Symbol(s.clone()),
            s.value_type,
        ))
    }

    fn checked_symbol(&self, name: &str) -> Result<CheckedSymbol, SemanticError> {
        let Some(vt) = self.symbols.get(name).copied() else {
            return Err(SemanticError::UnknownSymbol {
                name: name.to_owned(),
            });
        };
        Ok(CheckedSymbol::new(name.to_owned(), vt))
    }

    fn blk(&mut self, s: &[Statement], sc: Scope) -> Result<Vec<CheckedItem>, SemanticError> {
        s.iter().map(|st| self.statement(st, sc)).collect()
    }
}
