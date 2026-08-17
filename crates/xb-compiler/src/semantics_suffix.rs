//! Collision-aware slot naming for suffixed variables (VAR-SUFFIX-COLLISION).
//!
//! The symbol table is keyed by base name, so a numeric `x` and a string `x$`
//! in the same function would otherwise fight over slot `x` (declaration order
//! deciding the winner). A per-function pre-scan finds base names used with both
//! a string and a non-string type; for those, string references keep their `$`
//! suffix in the slot name while numeric references keep the bare base, so reads
//! and writes always address distinct slots.

use std::collections::{BTreeMap, BTreeSet};

use xb_frontend::{full_name, Expression, Statement, TypeSuffix};

use crate::checked::ValueType;
use crate::semantics::Analyzer;

impl Analyzer {
    /// Collision-aware slot name for a scalar variable reference. Non-colliding
    /// bases (the usual case) strip the suffix, preserving existing IR/goldens;
    /// a colliding string keeps its suffix (`c$`), numeric keeps the base (`c`).
    pub(crate) fn slot_name(&self, base: &str, suffix: Option<TypeSuffix>) -> String {
        let is_string = ValueType::from_suffix(suffix) == ValueType::String;
        if base.contains('.') || !is_string || !self.collisions.contains(base) {
            base.to_owned()
        } else {
            full_name(base.to_owned(), suffix)
        }
    }

    /// Pre-scan a function body: a base name referenced with BOTH a string and a
    /// non-string type collides on its (base-name-keyed) slot.
    pub(crate) fn scan_body_collisions(body: &[Statement]) -> BTreeSet<String> {
        // base -> (seen as string, seen as non-string)
        let mut kinds: BTreeMap<String, (bool, bool)> = BTreeMap::new();
        for s in body {
            Self::scan_stmt(s, &mut kinds);
        }
        kinds
            .into_iter()
            .filter(|(_, (s, n))| *s && *n)
            .map(|(k, _)| k)
            .collect()
    }

    fn note_var(base: &str, suffix: Option<TypeSuffix>, kinds: &mut BTreeMap<String, (bool, bool)>) {
        if base.contains('.') {
            return;
        }
        let entry = kinds.entry(base.to_owned()).or_insert((false, false));
        if ValueType::from_suffix(suffix) == ValueType::String {
            entry.0 = true;
        } else {
            entry.1 = true;
        }
    }

    fn scan_stmt(s: &Statement, kinds: &mut BTreeMap<String, (bool, bool)>) {
        match s {
            Statement::Print { items, .. } => {
                for e in items {
                    Self::scan_expr(e, kinds);
                }
            }
            Statement::Dim { name, suffix, size } => {
                if size.is_none() {
                    Self::note_var(name, *suffix, kinds);
                }
                if let Some(e) = size {
                    Self::scan_expr(e, kinds);
                }
            }
            Statement::Assignment { target, suffix, value } => {
                Self::note_var(target, *suffix, kinds);
                Self::scan_expr(value, kinds);
            }
            Statement::ArrayAssignment { index, value, .. } => {
                Self::scan_expr(index, kinds);
                Self::scan_expr(value, kinds);
            }
            Statement::MidAssign { target, start, length, value } => {
                Self::scan_expr(target, kinds);
                Self::scan_expr(start, kinds);
                if let Some(l) = length {
                    Self::scan_expr(l, kinds);
                }
                Self::scan_expr(value, kinds);
            }
            Statement::BuiltinAssign { args, value, .. } => {
                for a in args {
                    Self::scan_expr(a, kinds);
                }
                Self::scan_expr(value, kinds);
            }
            Statement::SharedAssignment { value, .. } => Self::scan_expr(value, kinds),
            Statement::If { condition, then_body, else_body } => {
                Self::scan_expr(condition, kinds);
                for st in then_body {
                    Self::scan_stmt(st, kinds);
                }
                if let Some(eb) = else_body {
                    for st in eb {
                        Self::scan_stmt(st, kinds);
                    }
                }
            }
            Statement::While { condition, body } => {
                Self::scan_expr(condition, kinds);
                for st in body {
                    Self::scan_stmt(st, kinds);
                }
            }
            Statement::DoLoop { pre_condition, post_condition, body } => {
                if let Some((e, _)) = pre_condition {
                    Self::scan_expr(e, kinds);
                }
                if let Some((e, _)) = post_condition {
                    Self::scan_expr(e, kinds);
                }
                for st in body {
                    Self::scan_stmt(st, kinds);
                }
            }
            Statement::For { var, start, end, step, body } => {
                Self::note_var(var, None, kinds);
                Self::scan_expr(start, kinds);
                Self::scan_expr(end, kinds);
                if let Some(sp) = step {
                    Self::scan_expr(sp, kinds);
                }
                for st in body {
                    Self::scan_stmt(st, kinds);
                }
            }
            Statement::Return { value } => {
                if let Some(e) = value {
                    Self::scan_expr(e, kinds);
                }
            }
            Statement::Call { args, .. } => {
                for a in args {
                    Self::scan_expr(a, kinds);
                }
            }
            Statement::Inc { target, suffix } | Statement::Dec { target, suffix } => {
                Self::note_var(target, *suffix, kinds);
            }
            Statement::Swap { left, left_suffix, right, right_suffix } => {
                Self::note_var(left, *left_suffix, kinds);
                Self::note_var(right, *right_suffix, kinds);
            }
            Statement::Function(f) => {
                for st in &f.body {
                    Self::scan_stmt(st, kinds);
                }
            }
            Statement::SelectCase { selector, cases, default } => {
                Self::scan_expr(selector, kinds);
                for c in cases {
                    for cond in &c.conditions {
                        Self::scan_expr(cond, kinds);
                    }
                    for st in &c.body {
                        Self::scan_stmt(st, kinds);
                    }
                }
                if let Some(d) = default {
                    for st in d {
                        Self::scan_stmt(st, kinds);
                    }
                }
            }
            Statement::Goto(e) | Statement::Gosub(e) => Self::scan_expr(e, kinds),
            Statement::Read(vars) => {
                for (name, suffix) in vars {
                    Self::note_var(name, *suffix, kinds);
                }
            }
            Statement::Compound(inner) => {
                for st in inner {
                    Self::scan_stmt(st, kinds);
                }
            }
            _ => {}
        }
    }

    fn scan_expr(e: &Expression, kinds: &mut BTreeMap<String, (bool, bool)>) {
        match e {
            Expression::Identifier { name, suffix }
            | Expression::ByRefIdentifier { name, suffix } => {
                Self::note_var(name, *suffix, kinds);
            }
            Expression::Comparison { left, right, .. }
            | Expression::Boolean { left, right, .. }
            | Expression::Logical { left, right, .. }
            | Expression::Arithmetic { left, right, .. } => {
                Self::scan_expr(left, kinds);
                Self::scan_expr(right, kinds);
            }
            Expression::Not(inner) => Self::scan_expr(inner, kinds),
            Expression::Unary { operand, .. } => Self::scan_expr(operand, kinds),
            Expression::FunctionCall { args, .. } => {
                for a in args {
                    Self::scan_expr(a, kinds);
                }
            }
            Expression::ArrayAccess { index, .. } => Self::scan_expr(index, kinds),
            _ => {}
        }
    }
}
