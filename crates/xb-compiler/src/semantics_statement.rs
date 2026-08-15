use xb_frontend::{Expression, Statement, TypeSuffix};

use crate::semantics::{
    Analyzer, CheckedItem, CheckedSymbol, ExprResult, ItemResult, Scope, SemanticError, ValueType,
};

impl Analyzer {
    pub(crate) fn statement(&mut self, statement: &Statement, scope: Scope) -> ItemResult {
        match statement {
            Statement::Version(value) => Ok(CheckedItem::Version(value.clone())),
            Statement::Print { items, separators } => {
                let checked_items = items
                    .iter()
                    .map(|e| self.expr(e))
                    .collect::<Result<Vec<_>, _>>()?;
                Ok(CheckedItem::Print {
                    items: checked_items,
                    separators: separators.clone(),
                })
            }
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
            Statement::ExitSelect => Ok(CheckedItem::ExitSelect),
            Statement::Inc { target, suffix } => self.inc_dec(target, *suffix, true),
            Statement::Dec { target, suffix } => self.inc_dec(target, *suffix, false),
            Statement::Swap {
                left,
                left_suffix,
                right,
                right_suffix,
            } => self.swap_stmt(left, *left_suffix, right, *right_suffix),
            Statement::Function(function) => self.function(function),
            Statement::Import(_)
            | Statement::Declare { .. }
            | Statement::Program(_)
            | Statement::EndProgram
            | Statement::Goto(_)
            | Statement::Data(_) => Ok(CheckedItem::Nop),
            Statement::Read(vars) => self.read_stmt(vars),
            Statement::Restore(label) => Ok(CheckedItem::Restore(label.clone())),
            Statement::Stop => Ok(CheckedItem::Stop),
            Statement::SelectCase {
                selector,
                cases,
                default,
            } => self.select_case(selector, cases, default.as_deref(), scope),
            Statement::Compound(stmts) => {
                let mut items = Vec::new();
                for s in stmts {
                    items.push(self.statement(s, scope)?);
                }
                Ok(CheckedItem::Compound(items))
            }
        }
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
