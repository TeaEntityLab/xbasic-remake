use std::collections::BTreeMap;
use xb_frontend::{Expression, FunctionDecl, Program, Statement, TypeSuffix};

pub use crate::checked::{
    CheckedExpr, CheckedExprKind, CheckedItem, CheckedParam, CheckedProgram, CheckedSymbol,
    SemanticError, ValueType,
};

pub(crate) type ExprResult = Result<CheckedExpr, SemanticError>;
type ItemResult = Result<CheckedItem, SemanticError>;

#[derive(Debug, Clone)]
pub(crate) struct FuncSig {
    pub(crate) params: Vec<ValueType>,
    pub(crate) return_type: ValueType,
}

#[derive(Debug, Default)]
pub struct Analyzer {
    pub(crate) symbols: BTreeMap<String, ValueType>,
    pub(crate) constants: BTreeMap<String, String>,
    pub(crate) shared: BTreeMap<String, ValueType>,
    pub(crate) functions: BTreeMap<String, FuncSig>,
    pub(crate) return_type: Option<ValueType>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Scope {
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
            Statement::Return { value } => self.return_stmt(scope, value.as_ref()),
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

    fn function(&mut self, f: &FunctionDecl) -> ItemResult {
        let ret = ValueType::from_suffix(f.suffix);
        let param_types: Vec<ValueType> = f
            .params
            .iter()
            .map(|p| ValueType::from_suffix(p.suffix))
            .collect();
        self.functions.insert(
            f.name.clone(),
            FuncSig {
                params: param_types.clone(),
                return_type: ret,
            },
        );
        let mut scoped = Self {
            symbols: BTreeMap::new(),
            constants: self.constants.clone(),
            shared: self.shared.clone(),
            functions: self.functions.clone(),
            return_type: Some(ret),
        };
        for (p, vt) in f.params.iter().zip(param_types) {
            scoped.symbols.insert(p.name.clone(), vt);
        }
        let body = scoped.blk(&f.body, Scope::Function)?;
        self.shared = scoped.shared;
        let cps: Vec<CheckedParam> = f.params.iter().map(CheckedParam::from_ast).collect();
        Ok(CheckedItem::Function {
            name: f.name.clone(),
            params: cps,
            return_type: ret,
            body,
        })
    }
    fn return_stmt(&mut self, scope: Scope, value: Option<&Expression>) -> ItemResult {
        if scope != Scope::Function {
            return Err(SemanticError::ReturnOutsideFunction);
        }
        let ret = self.return_type.unwrap();
        let checked = match value {
            Some(e) => {
                let v = self.expr(e)?;
                if v.value_type != ret {
                    return Err(SemanticError::ReturnTypeMismatch {
                        expected: ret,
                        actual: v.value_type,
                    });
                }
                Some(v)
            }
            None => None,
        };
        Ok(CheckedItem::Return { value: checked })
    }

    fn blk(&mut self, s: &[Statement], sc: Scope) -> Result<Vec<CheckedItem>, SemanticError> {
        s.iter().map(|st| self.statement(st, sc)).collect()
    }
}
