use xb_frontend::{Expression, Statement, TypeSuffix};

use crate::semantics::{
    Analyzer, CheckedExpr, CheckedItem, CheckedSymbol, ItemResult, Scope, SemanticError, ValueType,
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
            Statement::Assignment { target, suffix, value } => self.assignment(target, *suffix, value),
            Statement::ArrayAssignment {
                target,
                index,
                value,
            } => self.array_assignment(target, index, value),
            Statement::MidAssign {
                target,
                start,
                length,
                value,
            } => self.mid_assign(target, start, length.as_ref(), value),
            Statement::BuiltinAssign { name, args, value } => {
                self.builtin_assign(name, args, value)
            }
            Statement::ConstantDefinition { name, value } => {
                self.constant_definition(name, value, scope)
            }
            Statement::SharedAssignment {
                name,
                suffix,
                value,
            } => {
                self.shared_assignment(name, *suffix, value, scope)
            }
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
            Statement::ExitFunction => Ok(CheckedItem::Return { value: None }),
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
            Statement::Program(name) => Ok(CheckedItem::ProgramName(name.clone())),
            Statement::Import(_)
            | Statement::Declare { .. }
            | Statement::EndProgram
            | Statement::Data(_) => Ok(CheckedItem::Nop),
            Statement::Goto(expr) => match expr {
                Expression::Identifier { name, suffix: None } if self.checked_symbol(name).is_err() => {
                    Ok(CheckedItem::Goto(name.clone()))
                }
                _ => {
                    let checked = self.expr(expr)?;
                    Ok(CheckedItem::GotoExpr(checked))
                }
            },
            Statement::Gosub(expr) => match expr {
                Expression::Identifier { name, suffix: None } if self.checked_symbol(name).is_err() => {
                    Ok(CheckedItem::Gosub(name.clone()))
                }
                _ => {
                    let checked = self.expr(expr)?;
                    Ok(CheckedItem::GosubExpr(checked))
                }
            },
            Statement::Label(name) => Ok(CheckedItem::Label(name.clone())),
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
            Statement::TypeDecl { name, members } => {
                self.register_type(name, members);
                Ok(CheckedItem::Nop)
            }
            Statement::CompositeDecl {
                type_name,
                var,
                shared,
                is_array,
            } => self.composite_decl(type_name, var, *shared, *is_array),
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
        let sym = self.auto_symbol(var);
        // Allow any type for FOR loop variable (auto-declared as integer)
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

    fn constant_definition(&mut self, name: &str, value: &str, scope: Scope) -> ItemResult {
        if !self.permissive && scope != Scope::TopLevel {
            return Err(SemanticError::ConstantDefinitionNotTopLevel {
                name: name.to_owned(),
            });
        }
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
        scope: Scope,
    ) -> ItemResult {
        if !self.permissive && scope == Scope::TopLevel {
            return Err(SemanticError::SharedAssignmentNotInFunction {
                name: name.to_owned(),
            });
        }
        let value = self.expr(v)?;
        let vt = self.declare_shared(name, s)?;
        // Relaxed: allow any type (XBasic implicit coercion)
        let value = if vt != value.value_type {
            CheckedExpr::new(value.kind.clone(), vt)
        } else { value };
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
        // Relaxed: always return declared type
        Ok(declared)
    }

    fn return_stmt(&mut self, scope: Scope, value: Option<&Expression>) -> ItemResult {
        if scope != Scope::Function {
            if value.is_none() {
                return Ok(CheckedItem::GosubReturn);
            }
            return Err(SemanticError::ReturnOutsideFunction);
        }
        let ret = self.return_type.unwrap();
        let checked = match value {
            Some(e) => {
                let v = self.expr(e)?;
                if !self.permissive && !crate::semantics_expr::types_coercible(v.value_type, ret) {
                    return Err(SemanticError::ReturnTypeMismatch {
                        expected: ret,
                        actual: v.value_type,
                    });
                }
                // Coerce compatible mismatches to the declared return type.
                let v = if v.value_type != ret {
                    CheckedExpr::new(v.kind.clone(), ret)
                } else { v };
                Some(v)
            }
            // RETURN without value = GOSUB return (falls back to function return at runtime)
            None => return Ok(CheckedItem::GosubReturn),
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

    /// Lower a composite variable declaration (`TYPE0 var` / `TYPE0 var[]`).
    /// Uses a struct-of-arrays model: each member becomes its own slot named
    /// `var.member`, so member access lowers to ordinary symbol/array access.
    pub(crate) fn composite_decl(
        &mut self,
        type_name: &str,
        var: &str,
        _shared: bool,
        is_array: bool,
    ) -> ItemResult {
        self.composite_vars
            .insert(var.to_string(), type_name.to_string());
        let Some(layout) = self.composites.get(type_name).cloned() else {
            return Ok(CheckedItem::Nop);
        };
        if is_array {
            // Array declared without a size yet; member arrays are DIM'd later.
            for m in &layout.members {
                self.arrays.insert(format!("{var}.{}", m.name), m.value_type);
            }
            Ok(CheckedItem::Nop)
        } else {
            // Scalar composite: allocate one slot per member.
            let mut items = Vec::with_capacity(layout.members.len());
            for m in &layout.members {
                let mname = format!("{var}.{}", m.name);
                self.symbols.insert(mname.clone(), m.value_type);
                items.push(CheckedItem::Dim {
                    symbol: CheckedSymbol::new(mname, m.value_type),
                    size: None,
                });
            }
            Ok(CheckedItem::Compound(items))
        }
    }
}
