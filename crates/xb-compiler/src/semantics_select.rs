use xb_frontend::{CaseClause, Expression, Statement};

use crate::checked::CheckedCaseClause;
use crate::semantics::{Analyzer, CheckedItem, ItemResult, Scope};

impl Analyzer {
    pub(crate) fn select_case(
        &mut self,
        selector: &Expression,
        cases: &[CaseClause],
        default: Option<&[Statement]>,
        scope: Scope,
    ) -> ItemResult {
        let sel = self.expr(selector)?;
        let mut checked_cases = Vec::new();
        for case in cases {
            let mut conds = Vec::new();
            for cond in &case.conditions {
                let c = self.expr(cond)?;
                conds.push(c);
            }
            let body = self.blk(&case.body, scope)?;
            checked_cases.push(CheckedCaseClause {
                conditions: conds,
                body,
            });
        }
        let checked_default = match default {
            Some(stmts) => Some(self.blk(stmts, scope)?),
            None => None,
        };
        Ok(CheckedItem::SelectCase {
            selector: sel,
            cases: checked_cases,
            default: checked_default,
        })
    }
}
