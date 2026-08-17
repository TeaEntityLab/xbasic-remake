use std::collections::BTreeMap;
use xb_frontend::{full_name, Program, Statement, TypeMember};

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
    /// Composite TYPE name per parameter (`None` for scalars); drives call-site
    /// flattening of composite arguments.
    pub(crate) param_composites: Vec<Option<String>>,
}

#[derive(Debug, Clone)]
pub(crate) struct CompositeMember {
    pub(crate) name: String,
    pub(crate) value_type: ValueType,
    /// Byte width of this member; used when serializing composite records.
    #[allow(dead_code)]
    pub(crate) byte_size: usize,
    /// If this member is itself a composite TYPE, its type name (for recursive
    /// struct-of-arrays flattening). `None` for primitive members.
    pub(crate) composite_type: Option<String>,
}

#[derive(Debug, Clone)]
pub(crate) struct CompositeLayout {
    pub(crate) members: Vec<CompositeMember>,
    pub(crate) byte_len: usize,
}

#[derive(Debug, Default)]
pub struct Analyzer {
    pub(crate) symbols: BTreeMap<String, ValueType>,
    pub(crate) arrays: BTreeMap<String, ValueType>,
    pub(crate) constants: BTreeMap<String, String>,
    pub(crate) shared: BTreeMap<String, ValueType>,
    pub(crate) functions: BTreeMap<String, FuncSig>,
    pub(crate) return_type: Option<ValueType>,
    /// Registry of composite TYPE layouts, keyed by type name.
    pub(crate) composites: BTreeMap<String, CompositeLayout>,
    /// Map from a composite variable name to its declared type name.
    pub(crate) composite_vars: BTreeMap<String, String>,
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
                let param_composites: Vec<Option<String>> =
                    f.params.iter().map(|p| p.type_name.clone()).collect();
                let sig = FuncSig {
                    params: param_types,
                    return_type: ret,
                    param_composites,
                };
                self.functions.insert(f.name.clone(), sig.clone());
                self.functions
                    .insert(full_name(f.name.clone(), f.suffix), sig);
            }
            if let Statement::TypeDecl { name, members } = statement {
                self.register_type(name, members);
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

    /// Register a composite TYPE layout (members with types and byte sizes).
    pub(crate) fn register_type(&mut self, name: &str, members: &[TypeMember]) {
        let mut layout_members = Vec::with_capacity(members.len());
        let mut byte_len = 0usize;
        for m in members {
            // A member whose type name is an already-registered composite is a
            // nested composite; carry its type name and use its byte length.
            let nested = self.composites.get(&m.type_name);
            let composite_type = nested.map(|_| m.type_name.clone());
            let byte_size = match nested {
                Some(layout) => layout.byte_len,
                None => m.byte_size,
            };
            let value_type = if m.is_string {
                ValueType::String
            } else if m.is_float {
                ValueType::Float
            } else {
                ValueType::Integer
            };
            layout_members.push(CompositeMember {
                name: m.name.clone(),
                value_type,
                byte_size,
                composite_type,
            });
            byte_len += byte_size;
        }
        self.composites.insert(
            name.to_string(),
            CompositeLayout {
                members: layout_members,
                byte_len,
            },
        );
    }
}
