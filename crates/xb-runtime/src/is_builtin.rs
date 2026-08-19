//! Builtin-name predicate. The canonical list lives in `xb-compiler` (the
//! backend needs it to distinguish deferred builtins from unknown user
//! functions); the interpreter delegates so both stay in lockstep.
pub(crate) fn is_builtin(name: &str) -> bool {
    xb_compiler::is_builtin::is_builtin(name)
}
