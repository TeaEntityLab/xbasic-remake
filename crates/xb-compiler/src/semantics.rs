use std::collections::BTreeMap;
use xb_frontend::{full_name, Program, Statement};

pub use crate::checked::{
    CheckedExpr, CheckedExprKind, CheckedItem, CheckedParam, CheckedProgram, CheckedSymbol,
    SemanticError, ValueType,
};

pub(crate) type ExprResult = Result<CheckedExpr, SemanticError>;
pub(crate) type ItemResult = Result<CheckedItem, SemanticError>;

#[derive(Debug, Clone)]
pub(crate) struct FuncSig {
    pub(crate) params: Vec<ValueType>,
    pub(crate) return_type: ValueType,
}

#[derive(Debug, Default)]
pub struct Analyzer {
    pub(crate) symbols: BTreeMap<String, ValueType>,
    pub(crate) arrays: BTreeMap<String, ValueType>,
    pub(crate) constants: BTreeMap<String, String>,
    pub(crate) shared: BTreeMap<String, ValueType>,
    pub(crate) functions: BTreeMap<String, FuncSig>,
    pub(crate) return_type: Option<ValueType>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Scope {
    TopLevel,
    Function,
}

impl Analyzer {
    pub fn analyze(program: &Program) -> Result<CheckedProgram, SemanticError> {
        let mut analyzer = Self::default();
        analyzer.program(program)
    }

    fn program(&mut self, program: &Program) -> Result<CheckedProgram, SemanticError> {
        // Pre-register all function signatures so call order doesn't matter.
        for statement in &program.statements {
            if let Statement::Function(f) = statement {
                let ret = ValueType::from_suffix(f.suffix);
                let param_types: Vec<ValueType> = f
                    .params
                    .iter()
                    .map(|p| ValueType::from_suffix(p.suffix))
                    .collect();
                let sig = FuncSig {
                    params: param_types,
                    return_type: ret,
                };
                self.functions.insert(f.name.clone(), sig.clone());
                self.functions
                    .insert(full_name(f.name.clone(), f.suffix), sig);
            }
        }
        let mut items = Vec::with_capacity(program.statements.len());
        for statement in &program.statements {
            items.push(self.statement(statement, Scope::TopLevel)?);
        }
        Ok(CheckedProgram { items })
    }
}
