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
                } => (candidate == name).then_some(body.as_slice()),
                CheckedItem::Version(_)
                | CheckedItem::Print(_)
                | CheckedItem::Dim(_)
                | CheckedItem::Assignment { .. } => None,
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
                } => (candidate == name).then_some(body.as_slice()),
                IrItem::Version(_)
                | IrItem::Print(_)
                | IrItem::Dim { .. }
                | IrItem::Assignment { .. } => None,
            })
            .ok_or_else(|| EntryLookupError::Missing {
                name: name.to_string(),
            })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        Analyzer, CheckedExprKind, CheckedItem, CheckedProgram, IrExprKind, IrItem, IrProgram,
    };
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
            [CheckedItem::Print(expr)]
                if matches!(&expr.kind, CheckedExprKind::StringLiteral(value) if value == "main")
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
            [IrItem::Print(expr)]
                if matches!(&expr.kind, IrExprKind::StringLiteral(value) if value == "main")
        ));
    }
}
