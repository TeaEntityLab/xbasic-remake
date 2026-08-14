use crate::checked::ValueType;
use crate::ir::{IrExpr, IrExprKind, IrItem, IrProgram};
use crate::semantics::Analyzer;
use xb_frontend::parse_program;

#[test]
fn lowers_version_function_and_print_into_ir() {
    let program =
        parse_program("VERSION \"6.5.0\"\nFUNCTION Main\nPRINT \"hello\"\nEND FUNCTION\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    let ir = IrProgram::lower(&checked);
    assert_eq!(ir.items.len(), 2);
    assert!(matches!(ir.items[0], IrItem::Version(ref version) if version == "6.5.0"));
    assert!(matches!(
        ir.items[1],
        IrItem::Function { ref name, ref body, .. }
            if name == "Main" && matches!(body.first(), Some(IrItem::Print(IrExpr { value_type: ValueType::String, .. })))
    ));
}

#[test]
fn lowers_assignment_into_typed_ir() {
    let program = parse_program("DIM name$\nname$ = \"hello\"\nPRINT name$\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    let ir = IrProgram::lower(&checked);
    assert!(matches!(
        ir.items[1],
        IrItem::Assignment { ref target, ref value }
            if target.name == "name" && target.value_type == ValueType::String && value.value_type == ValueType::String
    ));
}

#[test]
fn lowers_constant_definition_and_reference_into_typed_ir() {
    let program = parse_program("$$Answer = 42\nPRINT $$Answer\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    let ir = IrProgram::lower(&checked);
    assert!(matches!(
        &ir.items[..],
        [
            IrItem::ConstantDefinition { name, value, value_type: ValueType::Integer },
            IrItem::Print(IrExpr { kind: IrExprKind::Constant { name: reference, value: resolved }, value_type: ValueType::Integer })
        ] if name == "Answer" && value == "42" && reference == "Answer" && resolved == "42"
    ));
}
