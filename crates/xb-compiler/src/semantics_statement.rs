use std::collections::BTreeMap;
use xb_frontend::{Expression, FunctionDecl, Statement, TypeSuffix};

use crate::checked::CheckedParam;
use crate::semantics::{
    Analyzer, CheckedItem, CheckedSymbol, ExprResult, ItemResult, Scope, SemanticError, ValueType,
};

impl Analyzer {
    pub(crate) fn statement(&mut self, statement: &Statement, scope: Scope) -> ItemResult {
        match statement {
            Statement::Version(value) => Ok(CheckedItem::Version(value.clone())),
            Statement::Print(expr) => Ok(CheckedItem::Print(self.expr(expr)?)),
            Statement::Dim { name, suffix, size } => self.dim(name, *suffix, size.as_ref()),
            Statement::Assignment { target, value, .. } => self.assignment(target, value),
            Statement::ArrayAssignment {
                target,
                index,
                value,
            } => self.array_assignment(target, index, value),
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
            } => self.if_stmt(condition, then_body, else_body.as_deref(), scope),
            Statement::While { condition, body } => {
                let cond = self.check_integer(condition)?;
                let body = self.blk(body, scope)?;
                Ok(CheckedItem::While {
                    condition: cond,
                    body,
                })
            }
            Statement::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => self.do_loop_stmt(pre_condition, post_condition, body, scope),
            Statement::For {
                var,
                start,
                end,
                step,
                body,
            } => self.for_stmt(var, start, end, step.as_ref(), body, scope),
            Statement::Return { value } => self.return_stmt(scope, value.as_ref()),
            Statement::Call { name, args } => self.call_stmt(name, args),
            Statement::ExitLoop => Ok(CheckedItem::ExitLoop),
            Statement::Function(function) => self.function(function),
        }
    }

    fn check_integer(&mut self, expr: &Expression) -> ExprResult {
        let cond = self.expr(expr)?;
        if cond.value_type != ValueType::Integer {
            return Err(SemanticError::IfConditionNotInteger {
                actual: cond.value_type,
            });
        }
        Ok(cond)
    }

    fn if_stmt(
        &mut self,
        condition: &Expression,
        then_body: &[Statement],
        else_body: Option<&[Statement]>,
        scope: Scope,
    ) -> ItemResult {
        let cond = self.check_integer(condition)?;
        let then_body = self.blk(then_body, scope)?;
        let eb = else_body.map(|b| self.blk(b, scope)).transpose()?;
        Ok(CheckedItem::If {
            condition: cond,
            then_body,
            else_body: eb,
        })
    }

    fn do_loop_stmt(
        &mut self,
        pre_condition: &Option<(Expression, bool)>,
        post_condition: &Option<(Expression, bool)>,
        body: &[Statement],
        scope: Scope,
    ) -> ItemResult {
        let pre = pre_condition
            .as_ref()
            .map(|(e, is_while)| self.check_integer(e).map(|c| (c, *is_while)))
            .transpose()?;
        let post = post_condition
            .as_ref()
            .map(|(e, is_while)| self.check_integer(e).map(|c| (c, *is_while)))
            .transpose()?;
        let body = self.blk(body, scope)?;
        Ok(CheckedItem::DoLoop {
            pre_condition: pre,
            post_condition: post,
            body,
        })
    }

    fn for_stmt(
        &mut self,
        var: &str,
        start: &Expression,
        end: &Expression,
        step: Option<&Expression>,
        body: &[Statement],
        scope: Scope,
    ) -> ItemResult {
        let sym = self.checked_symbol(var)?;
        if sym.value_type != ValueType::Integer {
            return Err(SemanticError::IfConditionNotInteger {
                actual: sym.value_type,
            });
        }
        let start = self.expr(start)?;
        let end = self.expr(end)?;
        let step = step.map(|s| self.expr(s)).transpose()?;
        let body = self.blk(body, scope)?;
        Ok(CheckedItem::For {
            var: sym,
            start,
            end,
            step,
            body,
        })
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

    fn function(&mut self, f: &FunctionDecl) -> ItemResult {
        let ret = ValueType::from_suffix(f.suffix);
        let param_types: Vec<ValueType> = f
            .params
            .iter()
            .map(|p| ValueType::from_suffix(p.suffix))
            .collect();
        let mut scoped = Self {
            symbols: BTreeMap::new(),
            arrays: BTreeMap::new(),
            constants: self.constants.clone(),
            shared: self.shared.clone(),
            functions: self.functions.clone(),
            return_type: Some(ret),
        };
        for (p, vt) in f.params.iter().zip(param_types) {
            scoped.symbols.insert(p.name.clone(), vt);
        }
        scoped.symbols.insert(f.name.clone(), ret);
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

    pub(crate) fn blk(
        &mut self,
        s: &[Statement],
        sc: Scope,
    ) -> Result<Vec<CheckedItem>, SemanticError> {
        s.iter().map(|st| self.statement(st, sc)).collect()
    }
}
