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
            permissive: self.permissive,
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
        use crate::semantics::ValueType;
        let Some(declared) = self.shared.get(name).copied() else {
            if !self.permissive {
                return Err(SemanticError::UnknownSharedVariable {
                    name: name.to_owned(),
                });
            }
            // Permissive: auto-declare unknown shared variables from the suffix.
            let vt = ValueType::from_suffix(s);
            return Ok(CheckedExpr::new(
                CheckedExprKind::SharedVariable(CheckedSymbol::new(name.to_owned(), vt)),
                vt,
            ));
        };
        // Relaxed: allow any suffix type for shared variables
        let _requested = ValueType::from_suffix(s);
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

    /// Like checked_symbol but auto-declares unknown symbols as Integer
    pub(crate) fn auto_symbol(&self, name: &str) -> CheckedSymbol {
        let vt = self.symbols.get(name).copied().unwrap_or(ValueType::Integer);
        CheckedSymbol::new(name.to_owned(), vt)
    }
}
impl Analyzer {
    pub(crate) fn constant(&self, name: &str) -> crate::semantics::ExprResult {
        let value = if let Some(v) = self.constants.get(name) {
            v.clone()
        } else {
            // Built-in system constants resolve unless the program redefines them.
            match name {
                "TRUE" => "-1".to_owned(),
                "FALSE" => "0".to_owned(),
                _ => {
                    if !self.permissive {
                        return Err(SemanticError::UnknownConstant {
                            name: name.to_owned(),
                        });
                    }
                    "0".to_owned()
                }
            }
        };
        Ok(CheckedExpr::new(
            crate::checked::CheckedExprKind::Constant {
                name: name.to_owned(),
                value,
            },
            ValueType::Integer,
        ))
    }
}
