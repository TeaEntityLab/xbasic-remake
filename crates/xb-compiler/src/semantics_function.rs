use std::collections::BTreeMap;
use xb_frontend::FunctionDecl;

use crate::checked::{CheckedExpr, CheckedParam, CheckedSymbol};
use crate::semantics::{Analyzer, CheckedItem, ItemResult, Scope, SemanticError, ValueType};

impl Analyzer {
    pub(crate) fn function(&mut self, f: &FunctionDecl) -> ItemResult {
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
}

impl Analyzer {
    pub(crate) fn shared_variable(
        &self,
        name: &str,
        s: Option<xb_frontend::TypeSuffix>,
    ) -> crate::semantics::ExprResult {
        use crate::checked::{CheckedExpr, CheckedExprKind, CheckedSymbol};
        use crate::semantics::{SemanticError, ValueType};
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
}

impl Analyzer {
    pub(crate) fn checked_symbol(&self, name: &str) -> Result<CheckedSymbol, SemanticError> {
        let Some(vt) = self.symbols.get(name).copied() else {
            return Err(SemanticError::UnknownSymbol {
                name: name.to_owned(),
            });
        };
        Ok(CheckedSymbol::new(name.to_owned(), vt))
    }
}

impl Analyzer {
    pub(crate) fn constant(&self, name: &str) -> crate::semantics::ExprResult {
        let value = self
            .constants
            .get(name)
            .cloned()
            .ok_or(SemanticError::UnknownConstant {
                name: name.to_owned(),
            })?;
        Ok(CheckedExpr::new(
            crate::checked::CheckedExprKind::Constant {
                name: name.to_owned(),
                value,
            },
            ValueType::Integer,
        ))
    }
}
