//! Computed-`GOTO` prologue for the C generator.
//!
//! Several IR items lower to a C computed goto (`goto *expr`): `GotoExpr`,
//! `GosubExpr`, and `GosubReturn` (`goto *xb_gosub_stack[..]`). C only accepts an
//! indirect goto in a function that also contains an address-of-label expression
//! (`&&label`). `Gosub`/`GosubExpr` emit one (`&&xb_gosub_ret_*`); a bare
//! `GotoExpr`/`GosubReturn` in a function without them (e.g. an `Entry` that starts
//! with `IF … gosub_return`) had none, so `cc` rejected it.
//!
//! When a body needs an indirect goto but has no `&&label`, we emit an unreachable
//! block that defines a dummy label and takes its address, enabling the feature
//! without changing behavior. The trigger excludes any function that already emits
//! an `&&label` (`Gosub`/`GosubExpr`), so this adds nothing to code that already
//! compiles — including the self-host `cgen.x` (whose lone `GosubReturn` sits in a
//! `Gosub` function) and the v0.1 `GOSUB` goldens — keeping CEmitter byte-identical
//! to `cgen.x`.

use crate::ir::IrItem;

/// `true` if any item in `items` matches `pred` (recursing control-flow bodies,
/// not nested `Function` items).
fn any(items: &[IrItem], pred: &impl Fn(&IrItem) -> bool) -> bool {
    items.iter().any(|it| {
        pred(it)
            || match it {
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => any(then_body, pred) || else_body.as_deref().is_some_and(|b| any(b, pred)),
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. } => any(body, pred),
                IrItem::SelectCase { cases, default, .. } => {
                    cases.iter().any(|c| any(&c.body, pred))
                        || default.as_deref().is_some_and(|b| any(b, pred))
                }
                IrItem::Compound(items) => any(items, pred),
                _ => false,
            }
    })
}

/// A computed goto that does not itself provide an `&&label`.
fn is_bare_indirect(it: &IrItem) -> bool {
    matches!(it, IrItem::GotoExpr(_) | IrItem::GosubReturn)
}

/// A construct that emits an `&&label` (`Gosub` -> `&&xb_gosub_ret_<name>`,
/// `GosubExpr` -> `&&xb_gosub_ret_expr`), satisfying C's requirement on its own.
fn provides_label_addr(it: &IrItem) -> bool {
    matches!(it, IrItem::Gosub(_) | IrItem::GosubExpr(_))
}

/// Emit an unreachable dummy-label block when `body` performs a computed goto but
/// provides no address-of-label of its own. No-op otherwise.
pub(crate) fn emit_computed_goto_prologue(body: &[IrItem], out: &mut String, indent: usize) {
    if !any(body, &is_bare_indirect) || any(body, &provides_label_addr) {
        return;
    }
    let ind = "    ".repeat(indent);
    // Unreachable: defining and taking the address of a dummy label is enough for C
    // to accept the function's `goto *expr`; the target address is supplied at run
    // time by the program (GOADDR / the gosub stack).
    out.push_str(&ind);
    out.push_str(
        "if (0) { void* _xb_la = &&_xb_cg_dummy; (void)_xb_la; _xb_cg_dummy: (void)0; }\n",
    );
}
