use crate::checked::{CheckedExpr, CheckedExprKind, ValueType};
use crate::semantics::{Analyzer, ExprResult};
use xb_frontend::Expression;

impl Analyzer {
    pub(crate) fn type_conversion(&self, name: &str, args: &[Expression]) -> Option<ExprResult> {
        if ((name == "ABS"
            || name == "STR$"
            || name == "DOUBLE"
            || name == "SINGLE"
            || name == "XLONG"
            || name == "SBYTE"
            || name == "UBYTE"
            || name == "SSHORT"
            || name == "USHORT"
            || name == "SLONG"
            || name == "ULONG"
            || name == "GIANT"
            || name == "GOADDR"
            || name == "SUBADDR")
            && !args.is_empty())
        {
            let arg = self.expr(&args[0]).ok()?;
            let rt = match name {
                "ABS" => arg.value_type,
                "STR$" => ValueType::String,
                "XLONG" | "SBYTE" | "UBYTE" | "SSHORT" | "USHORT" | "SLONG" | "ULONG" | "GIANT"
                | "GOADDR" | "SUBADDR" => {
                    ValueType::Integer
                }
                "DOUBLE" | "SINGLE" => ValueType::Float,
                _ => unreachable!(),
            };
            return Some(Ok(CheckedExpr::new(
                CheckedExprKind::FunctionCall {
                    name: name.to_owned(),
                    args: vec![arg.clone()],
                },
                rt,
            )));
        }
        None
    }
}
