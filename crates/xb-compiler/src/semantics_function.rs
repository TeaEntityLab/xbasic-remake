use std::collections::{BTreeMap, BTreeSet};
use xb_frontend::{Expression, FunctionDecl, Statement};

use crate::checked::{CheckedExpr, CheckedParam, CheckedSymbol};
use crate::semantics::{Analyzer, CheckedItem, ItemResult, Scope, SemanticError, ValueType};

impl Analyzer {
    pub(crate) fn function(&mut self, f: &FunctionDecl) -> ItemResult {
        let ret = ValueType::from_suffix(f.suffix);
        // A GOSUB-reached local SUB shares the caller's scope; inline it as a label
        // routine analyzed in THIS function's scope so its variables share the
        // caller's symbol table (types) and collision set (GOSUB-SCOPE).
        let inlined = Self::inline_gosub_subs(&f.body);
        let mut scoped = Self {
            symbols: BTreeMap::new(),
            arrays: BTreeMap::new(),
            constants: self.constants.clone(),
            shared: self.shared.clone(),
            functions: self.functions.clone(),
            return_type: Some(ret),
            composites: self.composites.clone(),
            composite_vars: self.composite_vars.clone(),
            permissive: self.permissive,
            collisions: Self::scan_body_collisions(&inlined),
            shared_arrays: BTreeSet::new(),
            // Shared-write names are program-wide (pre-scanned); carry them so
            // single-`#` reads inside this function resolve to the shared slot.
            shared_writes: self.shared_writes.clone(),
            shared_scalars: BTreeSet::new(),
        };
        // Register params. A composite param flattens into member slots/params
        // (struct-of-arrays), matching how composite call-args are flattened so
        // the runtime binds member-for-member.
        let mut cps: Vec<CheckedParam> = Vec::new();
        for p in &f.params {
            if let Some(tn) = &p.type_name {
                if let Some(layout) = scoped.composites.get(tn).cloned() {
                    scoped.composite_vars.insert(p.name.clone(), tn.clone());
                    let mut leaves = Vec::new();
                    scoped.flatten_composite(&p.name, &layout, &mut leaves);
                    for (mname, mvt) in leaves {
                        scoped.symbols.insert(mname.clone(), mvt);
                        // A composite *array* param (`TYPE @p[]`) flattens each member
                        // into a member array (`p.member[]`), matching how a local
                        // composite array declares its members, so `p[i].member`
                        // lowers to array access instead of a scalar byte-index.
                        if p.is_array {
                            scoped.arrays.insert(mname.clone(), mvt);
                        }
                        cps.push(CheckedParam {
                            name: mname,
                            value_type: mvt,
                            is_array: p.is_array,
                        });
                    }
                    continue;
                }
            }
            let vt = ValueType::from_suffix(p.suffix);
            scoped.symbols.insert(p.name.clone(), vt);
            // An array param (`UBYTE gif[]`) registers as an array so body
            // subscripts/`UBOUND` resolve to array access, not a byte index.
            if p.is_array {
                scoped.arrays.insert(p.name.clone(), vt);
            }
            cps.push(CheckedParam::from_ast(p));
        }
        scoped.symbols.insert(f.name.clone(), ret);
        let body = scoped.blk(&inlined, Scope::Function)?;
        self.shared = scoped.shared;
        Ok(CheckedItem::Function {
            name: f.name.clone(),
            params: cps,
            return_type: ret,
            body,
        })
    }

    /// Rewrite `SUB name … END SUB` blocks reached by `GOSUB` into inline label
    /// routines — `Label(name)` + body + bare `RETURN` (which lowers to
    /// `GosubReturn`) — appended after a `RETURN` guard. Analyzed as ordinary
    /// statements in the enclosing scope, a `GOSUB` then runs them with the
    /// caller's shared variables (classic BASIC). Bodies with no gosub-targeted
    /// SUB are returned unchanged.
    ///
    /// `SUBADDRESS(Name)` / computed `GOSUB @arr.action` also target nested
    /// SUBs; those names are collected from expressions so the callee shares
    /// the caller's collision set (`imm$` vs `imm`).
    fn inline_gosub_subs(body: &[Statement]) -> Vec<Statement> {
        let mut targets: BTreeSet<String> = BTreeSet::new();
        for s in body {
            Self::collect_stmt_gosub_targets(s, &mut targets);
        }
        if targets.is_empty() {
            return body.to_vec();
        }
        // Local parameter-less SUBs in a GOSUB function share caller scope
        // (GOSUB-SCOPE), including those only reached via SUBADDRESS.
        for s in body {
            if let Statement::Function(f) = s {
                if f.params.is_empty() {
                    targets.insert(f.name.clone());
                }
            }
        }
        let mut main: Vec<Statement> = Vec::new();
        let mut subs: Vec<Statement> = Vec::new();
        for s in body {
            if let Statement::Function(f) = s {
                if targets.contains(&f.name) && f.params.is_empty() {
                    subs.push(Statement::Label(f.name.clone()));
                    subs.extend(f.body.iter().cloned());
                    subs.push(Statement::Return { value: None });
                    continue;
                }
            }
            main.push(s.clone());
        }
        if subs.is_empty() {
            return body.to_vec();
        }
        main.push(Statement::Return { value: None });
        main.extend(subs);
        main
    }

    fn collect_stmt_gosub_targets(s: &Statement, out: &mut BTreeSet<String>) {
        match s {
            Statement::Gosub(Expression::Identifier { name, .. }) => {
                out.insert(name.clone());
            }
            Statement::Gosub(e) | Statement::Goto(e) => {
                Self::collect_expr_gosub_targets(e, out);
            }
            Statement::Assignment { value, .. }
            | Statement::SharedAssignment { value, .. } => {
                Self::collect_expr_gosub_targets(value, out);
            }
            Statement::ArrayAssignment {
                index,
                extra_indices,
                value,
                ..
            } => {
                Self::collect_expr_gosub_targets(index, out);
                for e in extra_indices {
                    Self::collect_expr_gosub_targets(e, out);
                }
                Self::collect_expr_gosub_targets(value, out);
            }
            Statement::Call { args, .. } => {
                for a in args {
                    Self::collect_expr_gosub_targets(a, out);
                }
            }
            Statement::Print { items, .. } => {
                for e in items {
                    Self::collect_expr_gosub_targets(e, out);
                }
            }
            Statement::Return { value: Some(e) } => {
                Self::collect_expr_gosub_targets(e, out);
            }
            Statement::MidAssign {
                target,
                start,
                length,
                value,
            } => {
                Self::collect_expr_gosub_targets(target, out);
                Self::collect_expr_gosub_targets(start, out);
                if let Some(l) = length {
                    Self::collect_expr_gosub_targets(l, out);
                }
                Self::collect_expr_gosub_targets(value, out);
            }
            Statement::BuiltinAssign { args, value, .. } => {
                for a in args {
                    Self::collect_expr_gosub_targets(a, out);
                }
                Self::collect_expr_gosub_targets(value, out);
            }
            Statement::If {
                condition,
                then_body,
                else_body,
            } => {
                Self::collect_expr_gosub_targets(condition, out);
                for i in then_body {
                    Self::collect_stmt_gosub_targets(i, out);
                }
                if let Some(eb) = else_body {
                    for i in eb {
                        Self::collect_stmt_gosub_targets(i, out);
                    }
                }
            }
            Statement::While { condition, body } => {
                Self::collect_expr_gosub_targets(condition, out);
                for i in body {
                    Self::collect_stmt_gosub_targets(i, out);
                }
            }
            Statement::For {
                start,
                end,
                step,
                body,
                ..
            } => {
                Self::collect_expr_gosub_targets(start, out);
                Self::collect_expr_gosub_targets(end, out);
                if let Some(st) = step {
                    Self::collect_expr_gosub_targets(st, out);
                }
                for i in body {
                    Self::collect_stmt_gosub_targets(i, out);
                }
            }
            Statement::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => {
                if let Some((e, _)) = pre_condition {
                    Self::collect_expr_gosub_targets(e, out);
                }
                if let Some((e, _)) = post_condition {
                    Self::collect_expr_gosub_targets(e, out);
                }
                for i in body {
                    Self::collect_stmt_gosub_targets(i, out);
                }
            }
            Statement::SelectCase {
                selector,
                cases,
                default,
            } => {
                Self::collect_expr_gosub_targets(selector, out);
                for c in cases {
                    for cond in &c.conditions {
                        Self::collect_expr_gosub_targets(cond, out);
                    }
                    for i in &c.body {
                        Self::collect_stmt_gosub_targets(i, out);
                    }
                }
                if let Some(d) = default {
                    for i in d {
                        Self::collect_stmt_gosub_targets(i, out);
                    }
                }
            }
            Statement::Function(f) => {
                for i in &f.body {
                    Self::collect_stmt_gosub_targets(i, out);
                }
            }
            Statement::Compound(inner) => {
                for i in inner {
                    Self::collect_stmt_gosub_targets(i, out);
                }
            }
            Statement::Inc { indices, .. } | Statement::Dec { indices, .. } => {
                for e in indices {
                    Self::collect_expr_gosub_targets(e, out);
                }
            }
            Statement::Swap {
                left_indices,
                right_indices,
                ..
            } => {
                for e in left_indices.iter().chain(right_indices) {
                    Self::collect_expr_gosub_targets(e, out);
                }
            }
            _ => {}
        }
    }

    fn collect_expr_gosub_targets(e: &Expression, out: &mut BTreeSet<String>) {
        match e {
            Expression::FunctionCall { name, args } => {
                if name.eq_ignore_ascii_case("SUBADDRESS")
                    || name.eq_ignore_ascii_case("GOADDRESS")
                    || name.eq_ignore_ascii_case("SUBADDR")
                    || name.eq_ignore_ascii_case("GOADDR")
                {
                    if let Some(Expression::Identifier { name: label, .. }) = args.first() {
                        out.insert(label.clone());
                    }
                }
                for a in args {
                    Self::collect_expr_gosub_targets(a, out);
                }
            }
            Expression::ArrayAccess {
                index,
                extra_indices,
                ..
            } => {
                Self::collect_expr_gosub_targets(index, out);
                for x in extra_indices {
                    Self::collect_expr_gosub_targets(x, out);
                }
            }
            Expression::Comparison { left, right, .. }
            | Expression::Boolean { left, right, .. }
            | Expression::Logical { left, right, .. }
            | Expression::Arithmetic { left, right, .. } => {
                Self::collect_expr_gosub_targets(left, out);
                Self::collect_expr_gosub_targets(right, out);
            }
            Expression::Not(inner) | Expression::Unary { operand: inner, .. } => {
                Self::collect_expr_gosub_targets(inner, out);
            }
            _ => {}
        }
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

    /// Like checked_symbol but auto-declares unknown symbols, inferring the
    /// type from a trailing `$` (String), `!` (Float), or `#` (Float) suffix
    /// when the bare name is not in the symbol table. This matches how the
    /// interpreter's slot table distinguishes `field3` from `field3$`.
    pub(crate) fn auto_symbol(&self, name: &str) -> CheckedSymbol {
        // The parser strips the `$` suffix from non-array param names, storing
        // `display$` as `display` (String) in the symbol table. When auto_symbol
        // is called with the original `display$` name (e.g. from UBOUND), the
        // direct lookup fails. Try the base name (without `$`) so the symbol
        // resolves to the param's entry — keeping the C name consistent
        // (`xb_str_display` not `xb_str_display_s`).
        if let Some(&vt) = self.symbols.get(name) {
            return CheckedSymbol::new(name.to_owned(), vt);
        }
        if let Some(base) = name.strip_suffix('$') {
            // Only use the base name if it's registered as String — the parser
            // strips `$` from non-array param names, so `display$` param is
            // stored as `display` (String). But `window$` (String) must NOT
            // resolve to `window` (Integer) — different variables.
            if let Some(&vt) = self.symbols.get(base) {
                if vt == ValueType::String {
                    return CheckedSymbol::new(base.to_owned(), vt);
                }
            }
        }
        let vt = match name.chars().last() {
            Some('$') => ValueType::String,
            Some('!') | Some('#') => ValueType::Float,
            _ => ValueType::Integer,
        };
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
                // File open-mode constants (values from xst.dec).
                "RD" => "0".to_owned(),
                "WR" => "1".to_owned(),
                "RW" => "2".to_owned(),
                "WRNEW" => "3".to_owned(),
                "RWNEW" => "4".to_owned(),
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
