use xb_frontend::{Expression, LogicalOp};

use crate::checked::{CheckedExpr, CheckedExprKind};
use crate::semantics::{Analyzer, ExprResult, SemanticError, ValueType};

impl Analyzer {
    pub(crate) fn logical(&self, op: LogicalOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        // Allow any type in logical ops (XBasic treats strings as boolean)
        Ok(CheckedExpr::new(
            CheckedExprKind::Logical {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            ValueType::Integer,
        ))
    }
}
