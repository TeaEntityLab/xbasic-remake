use crate::eval::eval;
use crate::interpreter::{Flow, RuntimeError};
use crate::slot::ExecutionState;
use xb_compiler::{IrExpr, IrProgram};

pub(crate) fn exec_return(
    program: &IrProgram,
    value: &Option<IrExpr>,
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<Flow, RuntimeError> {
    let v = value
        .as_ref()
        .map(|e| eval(program, e, state, output))
        .transpose()?;
    Ok(Flow::Return(v))
}
