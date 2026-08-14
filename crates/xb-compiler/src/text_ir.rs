use crate::checked::{ArithmeticOp, ComparisonOp};
use crate::ir::{IrItem, IrProgram, IrSymbol};
use crate::ValueType;

#[derive(Debug, Clone, Copy, Default)]
pub struct TextIrEmitter;

impl TextIrEmitter {
    pub const fn new() -> Self {
        Self
    }

    pub fn emit_program(self, program: &IrProgram) -> String {
        let mut out = String::new();
        for item in &program.items {
            self.emit_item(item, &mut out, 0);
        }
        out
    }

    fn emit_item(self, item: &IrItem, out: &mut String, indent: usize) {
        let prefix = "  ".repeat(indent);
        match item {
            IrItem::Version(value) => out.push_str(&format!("{prefix}version {value}\n")),
            IrItem::Print(expr) => {
                out.push_str(&format!("{prefix}print {}\n", self.emit_expr(expr)))
            }
            IrItem::Dim { symbol, size } => match size {
                Some(sz) => out.push_str(&format!(
                    "{prefix}dim {}[{}]\n",
                    self.emit_symbol(symbol),
                    self.emit_expr(sz)
                )),
                None => out.push_str(&format!("{prefix}dim {}\n", self.emit_symbol(symbol))),
            },
            IrItem::Assignment { target, value } => {
                out.push_str(&format!(
                    "{prefix}assign {} = {}\n",
                    self.emit_symbol(target),
                    self.emit_expr(value)
                ));
            }
            IrItem::ArrayAssignment {
                target,
                index,
                value,
            } => {
                out.push_str(&format!(
                    "{prefix}array_assign {}[{}] = {}\n",
                    self.emit_symbol(target),
                    self.emit_expr(index),
                    self.emit_expr(value)
                ));
            }
            IrItem::ConstantDefinition {
                name,
                value,
                value_type,
            } => out.push_str(&format!(
                "{prefix}const $${name}:{} = integer({value})\n",
                self.emit_type(*value_type)
            )),
            IrItem::SharedAssignment { target, value } => {
                out.push_str(&format!(
                    "{prefix}shared ##{} = {}\n",
                    self.emit_symbol(target),
                    self.emit_expr(value)
                ));
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                out.push_str(&format!("{prefix}if {}\n", self.emit_expr(condition)));
                for item in then_body {
                    self.emit_item(item, out, indent + 1);
                }
                if let Some(else_body) = else_body {
                    out.push_str(&format!("{prefix}else\n"));
                    for item in else_body {
                        self.emit_item(item, out, indent + 1);
                    }
                }
                out.push_str(&format!("{prefix}end if\n"));
            }
            IrItem::While { condition, body } => {
                out.push_str(&format!("{prefix}while {}\n", self.emit_expr(condition)));
                for item in body {
                    self.emit_item(item, out, indent + 1);
                }
                out.push_str(&format!("{prefix}wend\n"));
            }
            IrItem::For {
                var,
                start,
                end,
                body,
            } => {
                out.push_str(&format!(
                    "{prefix}for {} = {} to {}\n",
                    self.emit_symbol(var),
                    self.emit_expr(start),
                    self.emit_expr(end)
                ));
                for item in body {
                    self.emit_item(item, out, indent + 1);
                }
                out.push_str(&format!("{prefix}next\n"));
            }
            IrItem::Function {
                name,
                params,
                return_type,
                body,
            } => {
                let ps: Vec<String> = params
                    .iter()
                    .map(|p| format!("{}:{}", p.name, self.emit_type(p.value_type)))
                    .collect();
                out.push_str(&format!(
                    "{prefix}function {}({}) -> {}\n",
                    name,
                    ps.join(", "),
                    self.emit_type(*return_type)
                ));
                for item in body {
                    self.emit_item(item, out, indent + 1);
                }
                out.push_str(&format!("{prefix}end function\n"));
            }
            IrItem::Return { value } => match value {
                Some(e) => out.push_str(&format!("{prefix}return {}\n", self.emit_expr(e))),
                None => out.push_str(&format!("{prefix}return\n")),
            },
            IrItem::Call { name, args } => {
                let as_str: Vec<String> = args.iter().map(|a| self.emit_expr(a)).collect();
                out.push_str(&format!("{prefix}call {}({})\n", name, as_str.join(", ")));
            }
            IrItem::ExitLoop => out.push_str(&format!("{prefix}exit_loop\n")),
        }
    }

    pub(crate) fn emit_symbol(self, symbol: &IrSymbol) -> String {
        format!("{}:{}", symbol.name, self.emit_type(symbol.value_type))
    }

    pub(crate) fn emit_op(self, op: ComparisonOp) -> &'static str {
        match op {
            ComparisonOp::Equal => "=",
            ComparisonOp::NotEqual => "<>",
            ComparisonOp::Less => "<",
            ComparisonOp::Greater => ">",
            ComparisonOp::LessEqual => "<=",
            ComparisonOp::GreaterEqual => ">=",
        }
    }

    pub(crate) fn emit_arith_op(self, op: ArithmeticOp) -> &'static str {
        match op {
            ArithmeticOp::Add => "+",
            ArithmeticOp::Sub => "-",
            ArithmeticOp::Mul => "*",
            ArithmeticOp::Div => "/",
        }
    }

    pub(crate) fn emit_type(self, value_type: ValueType) -> &'static str {
        match value_type {
            ValueType::Integer => "integer",
            ValueType::Float => "float",
            ValueType::String => "string",
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Analyzer, IrProgram};
    use xb_frontend::parse_program;

    #[test]
    fn emits_structural_text_ir_for_fixture_subset() {
        let program =
            parse_program("VERSION \"6.5.0\"\nDIM name$\nname$ = \"hello\"\nPRINT name$\n")
                .unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        let ir = IrProgram::lower(&checked);
        assert_eq!(
            TextIrEmitter::new().emit_program(&ir),
            "version 6.5.0\ndim name:string\nassign name:string = string(\"hello\")\nprint symbol(name:string)\n"
        );
    }

    #[test]
    fn emits_constant_definition_and_reference_exactly() {
        // Given
        let program = parse_program("$$Answer = 1\nPRINT $$Answer\n").unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        let ir = IrProgram::lower(&checked);

        // When
        let text = TextIrEmitter::new().emit_program(&ir);

        // Then
        assert_eq!(
            text,
            "const $$Answer:integer = integer(1)\nprint constant($$Answer:integer = integer(1))\n"
        );
    }

    #[test]
    fn emits_shared_assignment_and_reference_exactly() {
        // Given
        let program =
            parse_program("FUNCTION Main\n##XBSystem = 1\nPRINT ##XBSystem\nEND FUNCTION\n")
                .unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        let ir = IrProgram::lower(&checked);

        // When
        let text = TextIrEmitter::new().emit_program(&ir);

        // Then
        assert_eq!(
            text,
            concat!(
                "function Main() -> integer\n",
                "  shared ##XBSystem:integer = integer(1)\n",
                "  print shared(##XBSystem:integer)\n",
                "end function\n",
            )
        );
    }

    #[test]
    fn preserves_uppercase_hexadecimal_prefix() {
        // Given
        let program = parse_program("$$Answer = 0X2A\nPRINT $$Answer\n").unwrap();
        let checked = Analyzer::analyze(&program).unwrap();
        let ir = IrProgram::lower(&checked);

        // When
        let text = TextIrEmitter::new().emit_program(&ir);

        // Then
        assert_eq!(
            text,
            "const $$Answer:integer = integer(0X2A)\nprint constant($$Answer:integer = integer(0X2A))\n"
        );
    }
}
