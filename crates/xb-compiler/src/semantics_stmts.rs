use xb_frontend::{ArithmeticOp, Expression, TypeSuffix};

use crate::checked::{CheckedExpr, CheckedItem, CheckedSymbol, SemanticError, ValueType};
use crate::semantics::{Analyzer, ItemResult};

impl Analyzer {
    pub(crate) fn dim(
        &mut self,
        name: &str,
        suffix: Option<TypeSuffix>,
        size: Option<&Expression>,
    ) -> ItemResult {
        let vt = ValueType::from_suffix(suffix);
        let full_name = match suffix {
            Some(TypeSuffix::String) => format!("{name}$"),
            Some(TypeSuffix::Single) => format!("{name}!"),
            Some(TypeSuffix::Double) => format!("{name}#"),
            Some(TypeSuffix::Integer) => format!("{name}%"),
            None => name.to_owned(),
        };
        let checked_size = match size {
            Some(e) => {
                let ce = self.expr(e)?;
                // Allow any type for array size (auto-declared as integer)
                self.arrays.insert(full_name.clone(), vt);
                Some(ce)
            }
            None => None,
        };
        let sym_name = if size.is_some() { &full_name } else { name };
        match self.symbols.insert(sym_name.to_owned(), vt) {
            Some(_) => Err(SemanticError::DuplicateSymbol {
                name: sym_name.to_owned(),
            }),
            None => Ok(CheckedItem::Dim {
                symbol: CheckedSymbol::new(sym_name.to_owned(), vt),
                size: checked_size,
            }),
        }
    }

    pub(crate) fn assignment(&self, name: &str, suffix: Option<TypeSuffix>, value: &Expression) -> ItemResult {
        let suffix_vt = ValueType::from_suffix(suffix);
        let target = if self.symbols.contains_key(name) {
            let sym = self.checked_symbol(name)?;
            // If found type matches suffix type, use it; otherwise treat as different variable
            if sym.value_type == suffix_vt {
                sym
            } else {
                CheckedSymbol::new(name.to_owned(), suffix_vt)
            }
        } else {
            // Auto-declare unknown variables based on type suffix
            CheckedSymbol::new(name.to_owned(), suffix_vt)
        };
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

    pub(crate) fn array_assignment(
        &self,
        name: &str,
        index: &Expression,
        value: &Expression,
    ) -> ItemResult {
        let target = self.auto_symbol(name);
        let index = self.expr(index)?;
        let value = self.expr(value)?;
        if target.value_type != value.value_type {
            return Err(SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: target.value_type,
                actual: value.value_type,
            });
        }
        Ok(CheckedItem::ArrayAssignment {
            target,
            index,
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
        let args: Vec<CheckedExpr> = args.iter().map(|a| self.expr(a)).collect::<Result<_, _>>()?;
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
        if target.value_type != value.value_type {
            return Err(SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: target.value_type,
                actual: value.value_type,
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
    ) -> ItemResult {
        let left_sym = self.auto_symbol(left);
        let right_sym = self.auto_symbol(right);
        if left_sym.value_type != right_sym.value_type {
            return Err(SemanticError::TypeMismatch {
                name: left.to_owned(),
                expected: left_sym.value_type,
                actual: right_sym.value_type,
            });
        }
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
