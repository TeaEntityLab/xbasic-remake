use xb_frontend::{Expression, TypeSuffix};

use crate::checked::{CheckedItem, CheckedSymbol, SemanticError, ValueType};
use crate::semantics::{Analyzer, ItemResult};

impl Analyzer {
    pub(crate) fn dim(
        &mut self,
        name: &str,
        suffix: Option<TypeSuffix>,
        size: Option<&Expression>,
    ) -> ItemResult {
        let vt = ValueType::from_suffix(suffix);
        let checked_size = match size {
            Some(e) => {
                let ce = self.expr(e)?;
                if ce.value_type != ValueType::Integer {
                    return Err(SemanticError::IfConditionNotInteger {
                        actual: ce.value_type,
                    });
                }
                self.arrays.insert(name.to_owned(), vt);
                Some(ce)
            }
            None => None,
        };
        match self.symbols.insert(name.to_owned(), vt) {
            Some(_) => Err(SemanticError::DuplicateSymbol {
                name: name.to_owned(),
            }),
            None => Ok(CheckedItem::Dim {
                symbol: CheckedSymbol::new(name.to_owned(), vt),
                size: checked_size,
            }),
        }
    }

    pub(crate) fn assignment(&self, name: &str, value: &Expression) -> ItemResult {
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

    pub(crate) fn array_assignment(
        &self,
        name: &str,
        index: &Expression,
        value: &Expression,
    ) -> ItemResult {
        let target = self.checked_symbol(name)?;
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
}
