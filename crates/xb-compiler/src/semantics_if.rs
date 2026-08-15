use xb_frontend::Expression;

use crate::semantics::{
    Analyzer, CheckedItem, ExprResult, ItemResult, Scope, SemanticError, ValueType,
};

impl Analyzer {
    pub(crate) fn check_integer(&mut self, expr: &Expression) -> ExprResult {
        let cond = self.expr(expr)?;
        if cond.value_type != ValueType::Integer {
            return Err(SemanticError::IfConditionNotInteger {
                actual: cond.value_type,
            });
        }
        Ok(cond)
    }
    pub(crate) fn if_stmt(
        &mut self,
        condition: &Expression,
        then_body: &[xb_frontend::Statement],
        else_body: Option<&[xb_frontend::Statement]>,
        scope: Scope,
    ) -> ItemResult {
        let cond = self.check_integer(condition)?;
        let then_body = self.blk(then_body, scope)?;
        let eb = else_body.map(|b| self.blk(b, scope)).transpose()?;
        Ok(CheckedItem::If {
            condition: cond,
            then_body,
            else_body: eb,
        })
    }
    pub(crate) fn do_loop_stmt(
        &mut self,
        pre_condition: &Option<(Expression, bool)>,
        post_condition: &Option<(Expression, bool)>,
        body: &[xb_frontend::Statement],
        scope: Scope,
    ) -> ItemResult {
        let pre = pre_condition
            .as_ref()
            .map(|(e, is_while)| self.check_integer(e).map(|c| (c, *is_while)))
            .transpose()?;
        let post = post_condition
            .as_ref()
            .map(|(e, is_while)| self.check_integer(e).map(|c| (c, *is_while)))
            .transpose()?;
        let body = self.blk(body, scope)?;
        Ok(CheckedItem::DoLoop {
            pre_condition: pre,
            post_condition: post,
            body,
        })
    }
}
