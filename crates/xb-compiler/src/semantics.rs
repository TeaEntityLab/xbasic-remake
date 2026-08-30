use std::collections::{BTreeMap, BTreeSet};
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
    /// Composite TYPE name when the function returns a composite (`None` for
    /// primitive returns); drives call-site flattening of composite return values.
    #[allow(dead_code)]
    pub(crate) return_composite: Option<String>,
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
    /// For a `FUNCADDR` member, the declared param type names — used to flatten
    /// composite args of an indirect call through this member. Empty otherwise.
    pub(crate) funcaddr_params: Vec<String>,
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
    /// Composite TYPE name when the current function returns a composite
    /// (e.g. `DCOMPLEX`); `None` for primitive return types. Set per-function.
    pub(crate) return_composite: Option<String>,
    pub(crate) composites: BTreeMap<String, CompositeLayout>,
    /// Map from a composite variable name to its declared type name.
    pub(crate) composite_vars: BTreeMap<String, String>,
    /// When true, apply XBasic legacy leniency (implicit coercion, auto-declared
    /// symbols, stubbed unknown calls). When false, enforce the strict v0.1 spec.
    pub(crate) permissive: bool,
    /// Base names used with both a string and a non-string type in one scope,
    /// whose slots must be disambiguated (see `slot_name`, VAR-SUFFIX-COLLISION).
    pub(crate) collisions: BTreeSet<String>,
    /// Array names declared `SHARED` in the *current* function (reset per function).
    /// A `DIM`/`REDIM` of one of these routes to the module-shared store, so a
    /// `REDIM` of a `SHARED` array (or composite array) resizes the shared storage
    /// instead of shadowing it with a fresh local (`REDIM`-of-shared).
    pub(crate) shared_arrays: BTreeSet<String>,
    /// Names written via `#name = value` (SharedAssignment) ANYWHERE in the
    /// program, pre-scanned before statement checking. A single-`#` READ of
    /// such a name resolves through the shared slot (legacy `#x` is the
    /// shared scalar form) instead of a fresh local — fixing the write/read
    /// split that left cross-function shared scalars at their type default.
    pub(crate) shared_writes: BTreeSet<String>,
    /// Keyword-`SHARED` scalar names declared in the scope under analysis
    /// (reset per function). Reads and writes of these route to the shared
    /// slot (classic BASIC `SHARED y` refers to module-level storage);
    /// functions without the declaration keep their own locals.
    pub(crate) shared_scalars: BTreeSet<String>,
    /// Per-function byref flags from DECLARE `@` markers (collected in
    /// `program()`, used as CEmitter fallback when no callsite info exists).
    pub(crate) declare_byref: std::collections::HashMap<String, Vec<bool>>,
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

    /// Permissive analysis with pre-populated constants (from IMPORTed libs).
    pub fn analyze_with_constants(
        program: &Program,
        constants: BTreeMap<String, String>,
    ) -> Result<CheckedProgram, SemanticError> {
        let mut analyzer = Self {
            permissive: true,
            constants,
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
        Self::register_builtin_composites(&mut self.composites);
        // Pre-scan: every `#name = value` target (SharedAssignment) in the
        // program, so single-`#` READS can resolve through the shared slot
        // regardless of statement order (the write may live in a later
        // function than the read).
        Self::scan_shared_writes(&program.statements, &mut self.shared_writes);
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
                    return_composite: f.return_type_name.clone(),
                };
                self.functions.insert(f.name.clone(), sig.clone());
                self.functions
                    .insert(full_name(f.name.clone(), f.suffix), sig);
            }
            if let Statement::TypeDecl { name, members } = statement {
                self.register_type(name, members);
            }
        }
        // Collect DECLARE @ byref flags for CEmitter fallback.
        for statement in &program.statements {
            if let Statement::Declare { name, args } = statement {
                self.declare_byref
                    .insert(name.clone(), args.iter().map(|(_, br)| *br).collect());
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
        let string_constants: Vec<(String, String)> = self
            .constants
            .iter()
            .filter(|(name, _)| name.ends_with('$'))
            .map(|(n, v)| (n.clone(), v.clone()))
            .collect();
        Ok(CheckedProgram {
            items,
            data_values,
            string_constants,
            declare_byref: std::mem::take(&mut self.declare_byref),
        })
    }
    /// Recursively collect SharedAssignment (`#name = value`) target names —
    /// functions, control flow, and compound statements included.
    fn scan_shared_writes(statements: &[Statement], out: &mut BTreeSet<String>) {
        for s in statements {
            match s {
                Statement::SharedAssignment { name, .. } => {
                    out.insert(name.clone());
                }
                Statement::Function(f) => Self::scan_shared_writes(&f.body, out),
                Statement::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    Self::scan_shared_writes(then_body, out);
                    if let Some(eb) = else_body {
                        Self::scan_shared_writes(eb, out);
                    }
                }
                Statement::While { body, .. }
                | Statement::DoLoop { body, .. }
                | Statement::For { body, .. } => Self::scan_shared_writes(body, out),
                Statement::SelectCase { cases, default, .. } => {
                    for c in cases {
                        Self::scan_shared_writes(&c.body, out);
                    }
                    if let Some(d) = default {
                        Self::scan_shared_writes(d, out);
                    }
                }
                Statement::Compound(inner) => Self::scan_shared_writes(inner, out),
                _ => {}
            }
        }
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
                funcaddr_params: m.funcaddr_params.clone(),
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

    /// Register XBasic built-in composite types: DCOMPLEX (.R, .I — both DOUBLE)
    /// and SCOMPLEX (.R, .I — both SINGLE/FLOAT). These are not declared with
    /// TYPE0 in user code; they're language built-ins used by xcm.x.
    fn register_builtin_composites(composites: &mut BTreeMap<String, CompositeLayout>) {
        composites.insert(
            "DCOMPLEX".to_string(),
            CompositeLayout {
                members: vec![
                    CompositeMember {
                        name: "R".to_string(),
                        value_type: ValueType::Float,
                        byte_size: 8,
                        composite_type: None,
                        funcaddr_params: Vec::new(),
                    },
                    CompositeMember {
                        name: "I".to_string(),
                        value_type: ValueType::Float,
                        byte_size: 8,
                        composite_type: None,
                        funcaddr_params: Vec::new(),
                    },
                ],
                byte_len: 16,
            },
        );
        composites.insert(
            "SCOMPLEX".to_string(),
            CompositeLayout {
                members: vec![
                    CompositeMember {
                        name: "R".to_string(),
                        value_type: ValueType::Float,
                        byte_size: 4,
                        composite_type: None,
                        funcaddr_params: Vec::new(),
                    },
                    CompositeMember {
                        name: "I".to_string(),
                        value_type: ValueType::Float,
                        byte_size: 4,
                        composite_type: None,
                        funcaddr_params: Vec::new(),
                    },
                ],
                byte_len: 8,
            },
        );
    }
}
