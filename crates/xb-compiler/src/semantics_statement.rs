use xb_frontend::{Expression, Statement, TypeSuffix};

use crate::semantics_expr::ref_value_type;

use crate::semantics::{
    Analyzer, CheckedExpr, CheckedItem, CheckedSymbol, CompositeLayout, ItemResult, Scope,
    SemanticError, ValueType,
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
            Statement::Dim {
                name,
                suffix,
                size,
                extra_dims,
                is_array,
                redim,
                shared,
            } => self.dim(
                name,
                *suffix,
                size.as_ref(),
                extra_dims,
                *is_array,
                *redim,
                *shared,
            ),
            Statement::Assignment {
                target,
                suffix,
                value,
            } => self.assignment(target, *suffix, value),
            Statement::ArrayAssignment {
                target,
                index,
                extra_indices,
                value,
            } => self.array_assignment(target, index, extra_indices, value),
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
            } => self.shared_assignment(name, *suffix, value, scope),
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
            Statement::Inc {
                target,
                suffix,
                indices,
            } => self.inc_dec(target, *suffix, true, indices),
            Statement::Dec {
                target,
                suffix,
                indices,
            } => self.inc_dec(target, *suffix, false, indices),
            Statement::Swap {
                left,
                left_suffix,
                ref left_indices,
                right,
                right_suffix,
                ref right_indices,
            } => self.swap_stmt(
                left,
                *left_suffix,
                right,
                *right_suffix,
                left_indices.as_slice(),
                right_indices.as_slice(),
            ),
            Statement::Function(function) => self.function(function),
            Statement::Program(name) => Ok(CheckedItem::ProgramName(name.clone())),
            Statement::Import(_)
            | Statement::Declare { .. }
            | Statement::EndProgram
            | Statement::Data(_) => Ok(CheckedItem::Nop),
            Statement::Goto(expr) => match expr {
                Expression::Identifier { name, suffix: None }
                    if self.checked_symbol(name).is_err() || self.functions.contains_key(name) =>
                {
                    // A bare name that is not a local variable, or is a function
                    // name (not a label), resolves as a direct Goto to a label —
                    // the C emitter no-ops if the label is absent (interp errors
                    // only if executed).
                    Ok(CheckedItem::Goto(name.clone()))
                }
                _ => {
                    let checked = self.expr(expr)?;
                    Ok(CheckedItem::GotoExpr(checked))
                }
            },
            Statement::Gosub(expr) => match expr {
                Expression::Identifier { name, suffix: None }
                    if self.checked_symbol(name).is_err() || self.functions.contains_key(name) =>
                {
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
            Statement::Attach {
                left_name,
                left_suffix,
                left_indices,
                left_is_row,
                right_name,
                right_suffix,
                right_indices,
                right_is_row,
            } => self.attach_stmt(
                left_name,
                *left_suffix,
                left_indices,
                *left_is_row,
                right_name,
                *right_suffix,
                right_indices,
                *right_is_row,
            ),
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
        // FOR loop variables are always integer counters (the interpreter's
        // execute_for uses an integer slot). Don't use auto_symbol here: a
        // prior `y$ = ...` assignment poisons `self.symbols["y"]` with String,
        // which would make `auto_symbol("y")` return the wrong type.
        let sym = CheckedSymbol::new(var.to_owned(), ValueType::Integer);
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
        if self.constants.contains_key(name) {
            if !self.permissive {
                return Err(SemanticError::DuplicateConstant {
                    name: name.to_owned(),
                });
            } else {
                self.constants.insert(name.to_owned(), value.to_owned());
                return Ok(CheckedItem::ConstantDefinition {
                    name: name.to_owned(),
                    value: value.to_owned(),
                    value_type: ValueType::Integer,
                });
            }
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
        } else {
            value
        };
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
        // A single-`#` SharedName embeds its type suffix in the name
        // (`#formData$` lexes to name "formData$", suffix None) — infer the
        // declared type from the trailing char so the shared slot and its
        // shared-read sites agree (`ref_value_type`, same rule as reads).
        let req = ref_value_type(name, s);
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
                } else {
                    v
                };
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
        shared: bool,
        is_array: bool,
    ) -> ItemResult {
        self.composite_vars
            .insert(var.to_string(), type_name.to_string());
        let Some(layout) = self.composites.get(type_name).cloned() else {
            return Ok(CheckedItem::Nop);
        };
        let mut leaves = Vec::new();
        self.flatten_composite(var, &layout, &mut leaves);
        if is_array {
            // Array declared without a size yet; member arrays are DIM'd later.
            // A `SHARED` composite array registers so a later `DIM`/`REDIM` of it
            // routes to the module-shared store (REDIM-of-shared, via `dim()`).
            if shared {
                self.shared_arrays.insert(var.to_owned());
            }
            for (mname, vt) in &leaves {
                self.arrays.insert(mname.clone(), *vt);
            }
            Ok(CheckedItem::Nop)
        } else {
            // Scalar composite: one slot per recursively-flattened leaf member.
            let mut items = Vec::with_capacity(leaves.len());
            for (mname, vt) in leaves {
                self.symbols.insert(mname.clone(), vt);
                items.push(CheckedItem::Dim {
                    symbol: CheckedSymbol::new(mname, vt),
                    size: None,
                    extra_dims: Vec::new(),
                    is_array: false,
                    redim: false,
                    shared: false,
                });
            }
            Ok(CheckedItem::Compound(items))
        }
    }

    /// Flatten a composite layout into leaf `(dotted_name, value_type)` slots,
    /// recursing through nested composite members (struct-of-arrays model).
    pub(crate) fn flatten_composite(
        &self,
        prefix: &str,
        layout: &CompositeLayout,
        out: &mut Vec<(String, ValueType)>,
    ) {
        for m in &layout.members {
            let mname = format!("{prefix}.{}", m.name);
            if let Some(ct) = &m.composite_type {
                if let Some(sub) = self.composites.get(ct) {
                    self.flatten_composite(&mname, sub, out);
                    continue;
                }
            }
            out.push((mname, m.value_type));
        }
    }

    /// Lower `ATTACH src TO dst` — array row aliasing.
    /// Currently emits as Nop (parser correctness; runtime semantics follow
    /// once shared-array dimension tracking lands).
    pub(crate) fn attach_stmt(
        &self,
        _left_name: &str,
        _left_suffix: Option<TypeSuffix>,
        _left_indices: &[Expression],
        _left_is_row: bool,
        _right_name: &str,
        _right_suffix: Option<TypeSuffix>,
        _right_indices: &[Expression],
        _right_is_row: bool,
    ) -> ItemResult {
        Ok(CheckedItem::Nop)
    }
}
