use crate::text_ir::TextIrEmitter;
use crate::{Analyzer, IrProgram};
use xb_frontend::parse_program;

#[test]
fn emits_structural_text_ir_for_fixture_subset() {
    let program =
        parse_program("VERSION \"6.5.0\"\nDIM name$\nname$ = \"hello\"\nPRINT name$\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    let ir = IrProgram::lower(&checked);
    assert_eq!(
        TextIrEmitter::new().emit_program(&ir),
        "version 6.5.0\ndim name:string\nassign name:string = string(\"hello\")\nprint symbol(name:string)\n"
    );
}

#[test]
fn emits_constant_definition_and_reference_exactly() {
    let program = parse_program("$$Answer = 1\nPRINT $$Answer\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    let ir = IrProgram::lower(&checked);
    let text = TextIrEmitter::new().emit_program(&ir);
    assert_eq!(
        text,
        "const $$Answer:integer = integer(1)\nprint constant($$Answer:integer = integer(1))\n"
    );
}

#[test]
fn emits_shared_assignment_and_reference_exactly() {
    let program =
        parse_program("FUNCTION Main\n##XBSystem = 1\nPRINT ##XBSystem\nEND FUNCTION\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    let ir = IrProgram::lower(&checked);
    let text = TextIrEmitter::new().emit_program(&ir);
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
    let program = parse_program("$$Answer = 0X2A\nPRINT $$Answer\n").unwrap();
    let checked = Analyzer::analyze(&program).unwrap();
    let ir = IrProgram::lower(&checked);
    let text = TextIrEmitter::new().emit_program(&ir);
    assert_eq!(
        text,
        "const $$Answer:integer = integer(0X2A)\nprint constant($$Answer:integer = integer(0X2A))\n"
    );
}
