use thiserror::Error;

use crate::{CheckedItem, CheckedProgram, IrItem, IrProgram};

#[derive(Debug, Error, PartialEq, Eq)]
pub enum EntryLookupError {
    #[error("function entry {name} not found")]
    Missing { name: String },
}

impl CheckedProgram {
    pub fn entry(&self, name: &str) -> Result<&[CheckedItem], EntryLookupError> {
        self.items
            .iter()
            .find_map(|item| match item {
                CheckedItem::Function {
                    name: candidate,
                    body,
                    ..
                } => (candidate == name).then_some(body.as_slice()),
                CheckedItem::Version(_)
                | CheckedItem::ProgramName(_)
                | CheckedItem::Print { .. }
                | CheckedItem::Dim { .. }
                | CheckedItem::Assignment { .. }
                | CheckedItem::ArrayAssignment { .. }
                | CheckedItem::MidAssign { .. }
                | CheckedItem::BuiltinAssign { .. }
                | CheckedItem::ConstantDefinition { .. }
                | CheckedItem::If { .. }
                | CheckedItem::While { .. }
                | CheckedItem::DoLoop { .. }
                | CheckedItem::For { .. }
                | CheckedItem::SharedAssignment { .. }
                | CheckedItem::Return { .. }
                | CheckedItem::Call { .. }
                | CheckedItem::ExitLoop
                | CheckedItem::ExitSelect
                | CheckedItem::Swap { .. }
                | CheckedItem::Nop
                | CheckedItem::SelectCase { .. }
                | CheckedItem::Compound(_)
                | CheckedItem::Read(_)
                | CheckedItem::Stop
                | CheckedItem::Restore(_)
                | CheckedItem::Gosub(_)
                | CheckedItem::Label(_)
                | CheckedItem::Goto(_)
                | CheckedItem::GosubReturn
                | CheckedItem::GosubExpr(_)
                | CheckedItem::GotoExpr(_) => None,
            })
            .ok_or_else(|| EntryLookupError::Missing {
                name: name.to_string(),
            })
    }
}

impl IrProgram {
    pub fn entry(&self, name: &str) -> Result<&[IrItem], EntryLookupError> {
        self.items
            .iter()
            .find_map(|item| match item {
                IrItem::Function {
                    name: candidate,
                    body,
                    ..
                } => (candidate == name).then_some(body.as_slice()),
                IrItem::Version(_)
                | IrItem::ProgramName(_)
                | IrItem::Print { .. }
                | IrItem::Dim { .. }
                | IrItem::ConstantDefinition { .. }
                | IrItem::Assignment { .. }
                | IrItem::ArrayAssignment { .. }
                | IrItem::MidAssign { .. }
                | IrItem::BuiltinAssign { .. }
                | IrItem::If { .. }
                | IrItem::While { .. }
                | IrItem::DoLoop { .. }
                | IrItem::For { .. }
                | IrItem::SharedAssignment { .. }
                | IrItem::Return { .. }
                | IrItem::Call { .. }
                | IrItem::ExitLoop
                | IrItem::ExitSelect
                | IrItem::Swap { .. }
                | IrItem::Nop
                | IrItem::SelectCase { .. }
                | IrItem::Compound(_)
                | IrItem::Read(_)
                | IrItem::Stop
                | IrItem::Restore(_)
                | IrItem::Gosub(_)
                | IrItem::Label(_)
                | IrItem::Goto(_)
                | IrItem::GosubReturn
                | IrItem::GosubExpr(_)
                | IrItem::GotoExpr(_) => None,
            })
            .ok_or_else(|| EntryLookupError::Missing {
                name: name.to_string(),
            })
    }
}

impl IrProgram {
    /// Resolve the program entry point: the function named `name` (the v0.1
    /// `Main` convention), or, when absent, the first defined function — legacy
    /// XBasic runs the first function (commonly `Entry`) as the entry point.
    pub fn entry_or_first(&self, name: &str) -> Option<&[IrItem]> {
        if let Ok(body) = self.entry(name) {
            return Some(body);
        }
        self.items.iter().find_map(|item| match item {
            IrItem::Function { body, .. } => Some(body.as_slice()),
            _ => None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::semantics::{Analyzer, CheckedExprKind, CheckedItem, CheckedProgram};
    use crate::{IrExprKind, IrItem, IrProgram};
    use xb_frontend::parse_program;

    fn analyze(source: &str) -> CheckedProgram {
        Analyzer::analyze(&parse_program(source).unwrap()).unwrap()
    }

    #[test]
    fn finds_exact_main_entry_in_checked_program() {
        // Given
        let checked = analyze(
            "FUNCTION Helper\nPRINT \"helper\"\nEND FUNCTION\nFUNCTION Main\nPRINT \"main\"\nEND FUNCTION\n",
        );

        // When
        let body = checked.entry("Main").unwrap();

        // Then
        assert!(matches!(
            body,
            [CheckedItem::Print { items, .. }]
                if matches!(&items[0].kind, CheckedExprKind::StringLiteral(value) if value == "main")
        ));
    }

    #[test]
    fn reports_typed_error_when_checked_main_is_missing() {
        // Given
        let checked = analyze("FUNCTION main\nPRINT \"wrong case\"\nEND FUNCTION\n");

        // When
        let result = checked.entry("Main");

        // Then
        assert_eq!(
            result,
            Err(EntryLookupError::Missing {
                name: "Main".to_string(),
            })
        );
    }

    #[test]
    fn finds_exact_main_entry_in_lowered_ir() {
        // Given
        let checked = analyze(
            "FUNCTION Helper\nPRINT \"helper\"\nEND FUNCTION\nFUNCTION Main\nPRINT \"main\"\nEND FUNCTION\n",
        );
        let ir = IrProgram::lower(&checked);

        // When
        let body = ir.entry("Main").unwrap();

        // Then
        assert!(matches!(
            body,
            [IrItem::Print { items, .. }]
                if matches!(&items[0].kind, IrExprKind::StringLiteral(value) if value == "main")
        ));
    }

    #[test]
    fn checked_entry_skips_constant_definitions() {
        // Given
        let checked = analyze("$$Answer = 1\nFUNCTION Main\nPRINT $$Answer\nEND FUNCTION\n");

        // When
        let body = checked.entry("Main").unwrap();

        // Then
        assert!(matches!(body, [CheckedItem::Print { .. }]));
    }

    #[test]
    fn ir_entry_skips_constant_definitions() {
        // Given
        let checked = analyze("$$Answer = 1\nFUNCTION Main\nPRINT $$Answer\nEND FUNCTION\n");
        let ir = IrProgram::lower(&checked);

        // When
        let body = ir.entry("Main").unwrap();

        // Then
        assert!(matches!(body, [IrItem::Print { .. }]));
    }
}
