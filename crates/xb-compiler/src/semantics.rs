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
    /// When true, apply XBasic legacy leniency (implicit coercion, auto-declared
    /// symbols, stubbed unknown calls). When false, enforce the strict v0.1 spec.
    pub(crate) permissive: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Scope {
    TopLevel,
    Function,
}

impl Analyzer {
    /// Permissive analysis used for CLI compilation and the legacy corpus.
    pub fn analyze(program: &Program) -> Result<CheckedProgram, SemanticError> {
        let mut analyzer = Self {
            permissive: true,
            ..Self::default()
        };
        analyzer.program(program)
    }

    /// Strict analysis enforcing the full v0.1 diagnostic contract.
    pub fn analyze_strict(program: &Program) -> Result<CheckedProgram, SemanticError> {
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
        let mut data_values = Vec::new();
        for (i, statement) in program.statements.iter().enumerate() {
            if let Statement::Data(vals) = statement {
                data_values.extend(vals.iter().cloned());
            }
            if let Statement::Function(f) = statement {
                for s in &f.body {
                    if let Statement::Data(vals) = s {
                        data_values.extend(vals.iter().cloned());
                    }
                }
                // Skip forward declarations (empty body) if a later
                // function with the same name exists
                if f.body.is_empty() {
                    let has_later = program.statements[i + 1..]
                        .iter()
                        .any(|s| matches!(s, Statement::Function(lf) if lf.name == f.name && !lf.body.is_empty()));
                    if has_later {
                        continue;
                    }
                }
            }
            items.push(self.statement(statement, Scope::TopLevel)?);
        }
        Ok(CheckedProgram { items, data_values })
    }
}
