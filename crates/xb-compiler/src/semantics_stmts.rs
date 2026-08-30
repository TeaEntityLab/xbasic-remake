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
        // A `SHARED`-declared array stays shared across DIM/REDIM in this function,
        // so a `REDIM` of it (parser-marked `shared=false`) still resizes the
        // module-shared storage instead of shadowing it with a fresh local.
        // Keyword-`SHARED` scalars are captured separately: their reads/writes
        // route to the shared slot (classic BASIC), other scopes keep locals.
        let keyword_shared_scalar = shared && !is_array;
        let shared = shared || self.shared_arrays.contains(name);
        if shared && is_array {
            self.shared_arrays.insert(name.to_owned());
        }
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
        let sym_name: String = if is_array {
            full_name.clone()
        } else {
            // Collision-aware slot (matches reads via `symbol`/`slot_name`): a
            // scalar `STRING imm$` colliding with `XLONG imm` must declare slot
            // `imm$`, not bare `imm` — otherwise both DIM the same `imm`, flagging
            // it dyn (2 DIMs of one name) and leaving one type facet undeclared
            // in C (xdis `imm`/`imm$`). Non-colliding → bare name (byte-neutral).
            self.slot_name(name, suffix)
        };
        if keyword_shared_scalar {
            self.shared_scalars.insert(sym_name.clone());
        }
        if keyword_shared_scalar {
            self.shared.insert(sym_name.clone(), vt);
        }
        let previous = self.symbols.insert(sym_name.clone(), vt);
        // REDIM legitimately re-declares an existing array; only DIM flags a dup.
        if !self.permissive && previous.is_some() && !redim {
            return Err(crate::checked::SemanticError::DuplicateSymbol {
                name: sym_name.clone(),
            });
        }
        Ok(CheckedItem::Dim {
            symbol: CheckedSymbol::new(sym_name, vt),
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
        // Track whether this variable was already declared before this
        // assignment, so we can infer the type from the RHS for new
        // auto-declared variables without an explicit type suffix.
        let was_known = self.symbols.contains_key(name);
        // XBasic auto-declares locals on assignment; record the type so later
        // references (and brace-notation detection) resolve it. For new,
        // unsuffixed variables we tentatively register Integer (the XBasic
        // default) so self-references in the RHS resolve; we may upgrade
        // after evaluating the RHS.
        self.symbols.entry(name.to_owned()).or_insert(suffix_vt);
        // Keyword-`SHARED` scalar: the write goes to the shared slot.
        let shared_slot = self.slot_name(name, suffix);
        if self.shared_scalars.contains(&shared_slot) {
            let value = self.expr(value)?;
            let value = if suffix_vt != value.value_type {
                CheckedExpr::new(value.kind.clone(), suffix_vt)
            } else {
                value
            };
            return Ok(CheckedItem::SharedAssignment {
                target: CheckedSymbol::new(shared_slot, suffix_vt),
                value,
            });
        }
        let target = if !name.contains('.') && self.collisions.contains(name) {
            CheckedSymbol::new(self.slot_name(name, suffix), suffix_vt)
        } else if self.symbols.contains_key(name) {
            let sym = self.checked_symbol(name)?;
                // A composite member slot (dotted name) has an authoritative
                // declared type and no suffix; trust it. An unsuffixed name
                // also trusts the declared type — `DOUBLE a` in a function
                // parameter list declares `a` as Float, and assigning to `a`
                // (no suffix) must keep Float, not the Integer default.
                // A differing *suffix* denotes a distinct variable (`v0` vs `v0$`).
                if suffix.is_none() || sym.value_type == suffix_vt || name.contains('.') {
                    sym
                } else {
                    CheckedSymbol::new(xb_frontend::full_name(name.to_owned(), suffix), suffix_vt)
                }
        } else {
            // Auto-declare unknown variables based on type suffix
            CheckedSymbol::new(name.to_owned(), suffix_vt)
        };
        let value = self.expr(value)?;
        // Type inference: for newly auto-declared variables without a type
        // suffix, adopt the RHS value type instead of defaulting to Integer.
        // XBasic's runtime uses a variant type system where any slot can hold
        // double values regardless of declared type. The CEmitter can't
        // replicate this, so we infer Float from the RHS to preserve double
        // precision in computations (e.g. ASIN's `theSign = +1#`). The C
        // emitter adds explicit casts where Float variables are used in integer
        // contexts (array subscripts, MOD).
        let (target, value) = if !was_known && suffix.is_none() && value.value_type != target.value_type
        {
            self.symbols.insert(name.to_owned(), value.value_type);
            let target = CheckedSymbol::new(target.name.clone(), value.value_type);
            (target, value)
        } else {
            if !self.permissive
                && !crate::semantics_expr::types_coercible(value.value_type, target.value_type)
            {
                return Err(crate::checked::SemanticError::TypeMismatch {
                    name: name.to_owned(),
                    expected: target.value_type,
                    actual: value.value_type,
                });
            }
            let value = if target.value_type != value.value_type {
                CheckedExpr::new(value.kind.clone(), target.value_type)
            } else {
                value
            };
            (target, value)
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
            // Keyword-`SHARED` scalar: the byte write mutates the shared
            // string's storage (`xb_shared_<name>` / state.shared).
            let slot = self.slot_name(base, Some(TypeSuffix::String));
            let shared_slot = self.shared_scalars.contains(slot.as_str());
            let sym = if shared_slot {
                CheckedSymbol::new(slot.clone(), ValueType::String)
            } else {
                self.checked_symbol(base)?
            };
            let target_kind = if shared_slot {
                CheckedExprKind::SharedVariable(sym)
            } else {
                CheckedExprKind::Symbol(sym)
            };
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
                target: CheckedExpr::new(target_kind, ValueType::String),
                start: pos,
                length: Some(one),
                value: chr,
            });
        }
        // A composite member array (`library.name`) stores its element type in
        // `self.arrays`, not `self.symbols` — `auto_symbol` would default the
        // dotted leaf to Integer (no `$`) and the write would emit `xb_var_*` for a
        // String member (mismatching the read/global `xb_str_*`). Mirror the read
        // path (`array_access`): prefer the declared array element type.
        let target = {
            let vt = self
                .arrays
                .get(name)
                .copied()
                .unwrap_or_else(|| self.auto_symbol(name).value_type);
            crate::checked::CheckedSymbol::new(name.to_owned(), vt)
        };
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
        indices: &[Expression],
    ) -> ItemResult {
        let target = if self.symbols.contains_key(name) {
            self.checked_symbol(name)?
        } else {
            let vt = ValueType::from_suffix(suffix);
            CheckedSymbol::new(name.to_owned(), vt)
        };
        // An indexed target (`INC Ary_varData[pIndex].numElements`) reads and
        // writes through the member-array element; a bare flattened name would
        // increment the wrong (scalar) storage.
        if !indices.is_empty() {
            let read = self.array_access(name, &indices[0], &indices[1..])?;
            let sym = match &read.kind {
                CheckedExprKind::ArrayAccess { symbol, .. } => symbol.clone(),
                _ => unreachable!("indexed INC/DEC read is an ArrayAccess"),
            };
            let one = CheckedExpr::new(
                CheckedExprKind::IntegerLiteral("1".to_owned()),
                ValueType::Integer,
            );
            let op = if is_inc {
                ArithmeticOp::Add
            } else {
                ArithmeticOp::Sub
            };
            let value = CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op,
                    left: Box::new(read.clone()),
                    right: Box::new(one),
                },
                ValueType::Integer,
            );
            let index = self.expr(&indices[0])?;
            let extra_indices = indices[1..]
                .iter()
                .map(|e| self.expr(e))
                .collect::<Result<Vec<_>, _>>()?;
            return Ok(CheckedItem::ArrayAssignment {
                target: sym,
                index,
                extra_indices,
                value,
            });
        }
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
        let shared_slot = self.slot_name(name, suffix);
        if self.shared_scalars.contains(&shared_slot) {
            return Ok(CheckedItem::SharedAssignment {
                target: CheckedSymbol::new(shared_slot, target.value_type),
                value,
            });
        }
        Ok(CheckedItem::Assignment { target, value })
    }

    pub(crate) fn swap_stmt(
        &self,
        left: &str,
        _left_suffix: Option<TypeSuffix>,
        right: &str,
        _right_suffix: Option<TypeSuffix>,
        left_indices: &[Expression],
        right_indices: &[Expression],
    ) -> ItemResult {
        // Both sides plain scalars, neither keyword-`SHARED`: single Swap item
        // (legacy emission). A shared side routes its write through the shared
        // slot, so either-shared swaps take the temp-Compound path below.
        if left_indices.is_empty()
            && right_indices.is_empty()
            && !self.shared_scalars.contains(left)
            && !self.shared_scalars.contains(right)
        {
            let left_sym = self.auto_symbol(left);
            let right_sym = self.auto_symbol(right);
            return Ok(CheckedItem::Swap {
                left: left_sym,
                right: right_sym,
            });
        }
        // Indexed side(s): tmp = L; L = R; R = tmp — as a Compound so
        // subscripts survive. Reads go through array_access resolution
        // (facets, descriptor params); the temp is a fresh symbol the
        // hoister declares from the leading Assignment target.
        let tmp_name = format!(
            "__swap_tmp_{}_{}",
            crate::c_emit_expr::sanitize_c_ident(left),
            crate::c_emit_expr::sanitize_c_ident(right)
        );
        let left_vt = if left_indices.is_empty() {
            self.checked_symbol(left)
                .map(|s| s.value_type)
                .unwrap_or(ValueType::from_suffix(_left_suffix))
        } else {
            // Indexed side: element type of the referenced array.
            self.auto_symbol(left).value_type
        };
        let right_vt = if right_indices.is_empty() {
            self.checked_symbol(right)
                .map(|s| s.value_type)
                .unwrap_or(ValueType::from_suffix(_right_suffix))
        } else {
            self.auto_symbol(right).value_type
        };
        let tmp_vt = left_vt;
        let tmp_sym = CheckedSymbol::new(tmp_name, tmp_vt);
        let mut items: Vec<CheckedItem> = Vec::new();
        let _left_read = if left_indices.is_empty() {
            self.expr(&Expression::Identifier {
                name: left.to_owned(),
                suffix: None,
            })?
        } else {
            self.array_access(left, &left_indices[0], &left_indices[1..])?
        };
        let right_read = if right_indices.is_empty() {
            self.expr(&Expression::Identifier {
                name: right.to_owned(),
                suffix: None,
            })?
        } else {
            self.array_access(right, &right_indices[0], &right_indices[1..])?
        };
        // 2. L = R
        if !left_indices.is_empty() {
            let l_index = self.expr(&left_indices[0])?;
            let l_extra = left_indices[1..]
                .iter()
                .map(|e| self.expr(e))
                .collect::<Result<Vec<_>, _>>()?;
            items.push(CheckedItem::ArrayAssignment {
                target: CheckedSymbol::new(left.to_owned(), left_vt),
                index: l_index,
                extra_indices: l_extra,
                value: right_read.clone(),
            });
        } else if self.shared_scalars.contains(left) {
            items.push(CheckedItem::SharedAssignment {
                target: CheckedSymbol::new(self.slot_name(left, None), left_vt),
                value: right_read.clone(),
            });
        } else {
            items.push(CheckedItem::Assignment {
                target: self.auto_symbol(left),
                value: right_read.clone(),
            });
        }
        // 3. R = tmp
        if !right_indices.is_empty() {
            let r_index = self.expr(&right_indices[0])?;
            let r_extra = right_indices[1..]
                .iter()
                .map(|e| self.expr(e))
                .collect::<Result<Vec<_>, _>>()?;
            items.push(CheckedItem::ArrayAssignment {
                target: CheckedSymbol::new(right.to_owned(), right_vt),
                index: r_index,
                extra_indices: r_extra,
                value: CheckedExpr::new(CheckedExprKind::Symbol(tmp_sym), tmp_vt),
            });
        } else if self.shared_scalars.contains(right) {
            items.push(CheckedItem::SharedAssignment {
                target: CheckedSymbol::new(self.slot_name(right, None), right_vt),
                value: CheckedExpr::new(CheckedExprKind::Symbol(tmp_sym), tmp_vt),
            });
        } else {
            items.push(CheckedItem::Assignment {
                target: self.auto_symbol(right),
                value: CheckedExpr::new(CheckedExprKind::Symbol(tmp_sym), tmp_vt),
            });
        }
        Ok(CheckedItem::Compound(items))
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
