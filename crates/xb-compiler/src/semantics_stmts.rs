use xb_frontend::{ArithmeticOp, Expression, TypeSuffix};

use crate::checked::{CheckedExpr, CheckedExprKind, CheckedItem, CheckedSymbol, ValueType};
use crate::semantics::{Analyzer, ItemResult};

impl Analyzer {
    pub(crate) fn dim(
        &mut self,
        name: &str,
        suffix: Option<TypeSuffix>,
        size: Option<&Expression>,
        extra_dims: &[Expression],
        is_array: bool,
        redim: bool,
        shared: bool,
    ) -> ItemResult {
        let checked_extra_dims = extra_dims
            .iter()
            .map(|e| self.expr(e))
            .collect::<Result<Vec<_>, _>>()?;
        // Composite array DIM: expand into one member-array per struct member.
        if let Some(type_name) = self.composite_vars.get(name).cloned() {
            if let Some(layout) = self.composites.get(&type_name).cloned() {
                let checked_size = match size {
                    Some(e) => Some(self.expr(e)?),
                    None => None,
                };
                let mut leaves = Vec::new();
                self.flatten_composite(name, &layout, &mut leaves);
                let mut items = Vec::with_capacity(leaves.len());
                for (mname, vt) in leaves {
                    self.arrays.insert(mname.clone(), vt);
                    self.symbols.insert(mname.clone(), vt);
                    items.push(CheckedItem::Dim {
                        symbol: CheckedSymbol::new(mname, vt),
                        size: checked_size.clone(),
                        extra_dims: checked_extra_dims.clone(),
                        is_array: true,
                        redim,
                        shared,
                    });
                }
                return Ok(CheckedItem::Compound(items));
            }
        }
        let vt = ValueType::from_suffix(suffix);
        let full_name = match suffix {
            Some(TypeSuffix::String) => format!("{name}$"),
            Some(TypeSuffix::Single) => format!("{name}!"),
            Some(TypeSuffix::Double) => format!("{name}#"),
            Some(TypeSuffix::Integer) => format!("{name}%"),
            Some(TypeSuffix::Giant) => format!("{name}&&"),
            None => name.to_owned(),
        };
        // Any bracketed declaration — sized `a[n]` or empty `a[]` — is an array.
        let checked_size = match size {
            Some(e) => {
                let ce = self.expr(e)?;
                self.arrays.insert(full_name.clone(), vt);
                Some(ce)
            }
            None => {
                if is_array {
                    self.arrays.insert(full_name.clone(), vt);
                }
                None
            }
        };
        let sym_name = if is_array { &full_name } else { name };
        let previous = self.symbols.insert(sym_name.to_owned(), vt);
        // REDIM legitimately re-declares an existing array; only DIM flags a dup.
        if !self.permissive && previous.is_some() && !redim {
            return Err(crate::checked::SemanticError::DuplicateSymbol {
                name: sym_name.to_owned(),
            });
        }
        Ok(CheckedItem::Dim {
            symbol: CheckedSymbol::new(sym_name.to_owned(), vt),
            size: checked_size,
            extra_dims: checked_extra_dims,
            is_array,
            redim,
            shared,
        })
    }

    pub(crate) fn assignment(
        &mut self,
        name: &str,
        suffix: Option<TypeSuffix>,
        value: &Expression,
    ) -> ItemResult {
        let suffix_vt = ValueType::from_suffix(suffix);
        // XBasic auto-declares locals on assignment; record the type so later
        // references (and brace-notation detection) resolve it.
        self.symbols.entry(name.to_owned()).or_insert(suffix_vt);
        let target = if !name.contains('.') && self.collisions.contains(name) {
            CheckedSymbol::new(self.slot_name(name, suffix), suffix_vt)
        } else if self.symbols.contains_key(name) {
            let sym = self.checked_symbol(name)?;
            // A composite member slot (dotted name) has an authoritative declared
            // type and no suffix; trust it. Otherwise a differing suffix denotes a
            // distinct variable (`v0` vs `v0$`).
            if sym.value_type == suffix_vt || name.contains('.') {
                sym
            } else {
                CheckedSymbol::new(xb_frontend::full_name(name.to_owned(), suffix), suffix_vt)
            }
        } else {
            // Auto-declare unknown variables based on type suffix
            CheckedSymbol::new(name.to_owned(), suffix_vt)
        };
        let value = self.expr(value)?;
        if !self.permissive
            && !crate::semantics_expr::types_coercible(value.value_type, target.value_type)
        {
            return Err(crate::checked::SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: target.value_type,
                actual: value.value_type,
            });
        }
        // Coerce compatible mismatches (e.g. Integer -> Float) to the target type.
        let value = if target.value_type != value.value_type {
            CheckedExpr::new(value.kind.clone(), target.value_type)
        } else {
            value
        };
        Ok(CheckedItem::Assignment { target, value })
    }

    pub(crate) fn array_assignment(
        &self,
        name: &str,
        index: &Expression,
        extra: &[Expression],
        value: &Expression,
    ) -> ItemResult {
        // Brace-notation byte write: `s${off} = v` parses as an array assignment
        // to `s$`. When `s$` is a declared scalar string, lower it to
        // MID$(s, off + 1, 1) = CHR$(v) (0-based offset -> 1-based MID$).
        let base = name.trim_end_matches('$');
        if !self.arrays.contains_key(name) && self.symbols.get(base) == Some(&ValueType::String) {
            let sym = self.checked_symbol(base)?;
            let idx = self.expr(index)?;
            let one = CheckedExpr::new(
                CheckedExprKind::IntegerLiteral("1".to_owned()),
                ValueType::Integer,
            );
            let pos = CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op: ArithmeticOp::Add,
                    left: Box::new(idx),
                    right: Box::new(one.clone()),
                },
                ValueType::Integer,
            );
            let val = self.expr(value)?;
            let chr = CheckedExpr::new(
                CheckedExprKind::FunctionCall {
                    name: "CHR$".to_owned(),
                    args: vec![val],
                },
                ValueType::String,
            );
            return Ok(CheckedItem::MidAssign {
                target: CheckedExpr::new(CheckedExprKind::Symbol(sym), ValueType::String),
                start: pos,
                length: Some(one),
                value: chr,
            });
        }
        let target = self.auto_symbol(name);
        let index = self.expr(index)?;
        let value = self.expr(value)?;
        // Relaxed: allow any type assignment (XBasic implicit coercion)
        let value = if target.value_type != value.value_type {
            CheckedExpr::new(value.kind.clone(), target.value_type)
        } else {
            value
        };
        let extra_indices = extra
            .iter()
            .map(|e| self.expr(e))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(CheckedItem::ArrayAssignment {
            target,
            index,
            extra_indices,
            value,
        })
    }
    pub(crate) fn mid_assign(
        &self,
        target: &Expression,
        start: &Expression,
        length: Option<&Expression>,
        value: &Expression,
    ) -> ItemResult {
        let target = self.expr(target)?;
        let start = self.expr(start)?;
        let length = match length {
            Some(e) => Some(self.expr(e)?),
            None => None,
        };
        let value = self.expr(value)?;
        Ok(CheckedItem::MidAssign {
            target,
            start,
            length,
            value,
        })
    }
    pub(crate) fn builtin_assign(
        &self,
        name: &str,
        args: &[Expression],
        value: &Expression,
    ) -> ItemResult {
        let args: Vec<CheckedExpr> = args
            .iter()
            .map(|a| self.expr(a))
            .collect::<Result<_, _>>()?;
        let value = self.expr(value)?;
        Ok(CheckedItem::BuiltinAssign {
            name: name.to_string(),
            args,
            value,
        })
    }
    pub(crate) fn inc_dec(
        &self,
        name: &str,
        suffix: Option<TypeSuffix>,
        is_inc: bool,
    ) -> ItemResult {
        let target = if self.symbols.contains_key(name) {
            self.checked_symbol(name)?
        } else {
            let vt = ValueType::from_suffix(suffix);
            CheckedSymbol::new(name.to_owned(), vt)
        };
        let one = Expression::IntegerLiteral("1".to_string());
        let current = Expression::Identifier {
            name: name.to_owned(),
            suffix,
        };
        let value_expr = Expression::Arithmetic {
            op: if is_inc {
                ArithmeticOp::Add
            } else {
                ArithmeticOp::Sub
            },
            left: Box::new(current),
            right: Box::new(one),
        };
        let value = self.expr(&value_expr)?;
        // Relaxed: allow any type (XBasic implicit coercion)
        let value = if target.value_type != value.value_type {
            CheckedExpr::new(value.kind.clone(), target.value_type)
        } else {
            value
        };
        Ok(CheckedItem::Assignment { target, value })
    }

    pub(crate) fn swap_stmt(
        &self,
        left: &str,
        _left_suffix: Option<TypeSuffix>,
        right: &str,
        _right_suffix: Option<TypeSuffix>,
    ) -> ItemResult {
        let left_sym = self.auto_symbol(left);
        let right_sym = self.auto_symbol(right);
        // Relaxed: allow any type swap (XBasic implicit coercion)
        Ok(CheckedItem::Swap {
            left: left_sym,
            right: right_sym,
        })
    }
}
impl Analyzer {
    pub(crate) fn read_stmt(&mut self, vars: &[(String, Option<TypeSuffix>)]) -> ItemResult {
        let mut symbols = Vec::with_capacity(vars.len());
        for (name, suffix) in vars {
            let vt = ValueType::from_suffix(*suffix);
            let sym = match self.checked_symbol(name) {
                Ok(s) => s,
                Err(_) => {
                    self.symbols.insert(name.clone(), vt);
                    CheckedSymbol::new(name.clone(), vt)
                }
            };
            symbols.push(sym);
        }
        Ok(CheckedItem::Read(symbols))
    }
}
