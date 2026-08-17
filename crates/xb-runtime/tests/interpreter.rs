mod common;
use common::{expression, lower, symbol};
use xb_compiler::{IrExprKind, IrItem, IrProgram, ValueType};
use xb_runtime::{Interpreter, RuntimeError, RuntimeValue};

#[test]
fn executes_top_level_items_without_entering_functions() {
    // Given
    let program = lower(
        "VERSION \"old\"\nVERSION \"6.5.0\"\nPRINT \"top\"\nFUNCTION Main\nPRINT \"deferred\"\nEND FUNCTION\n",
    );
    let mut output = vec!["existing".to_string()];

    // When
    let state = Interpreter::new().execute(&program, &mut output).unwrap();

    // Then
    assert_eq!(state.metadata().version(), Some("6.5.0"));
    assert_eq!(output, ["existing", "top"]);
}

#[test]
fn allocates_default_values_for_each_typed_slot() {
    // Given
    let program = lower("DIM count%\nDIM ratio#\nDIM name$\n");
    let mut output = Vec::new();

    // When
    let state = Interpreter::new().execute(&program, &mut output).unwrap();

    // Then
    let s = state.slot("count").unwrap();
    assert_eq!(s.value_type(), ValueType::Integer);
    assert_eq!(s.value(), &RuntimeValue::Integer(0));
    let s = state.slot("ratio").unwrap();
    assert_eq!(s.value_type(), ValueType::Float);
    assert_eq!(s.value(), &RuntimeValue::Float(0.0));
    let s = state.slot("name").unwrap();
    assert_eq!(s.value_type(), ValueType::String);
    assert_eq!(s.value(), &RuntimeValue::String(Vec::new()));
}

#[test]
fn stores_and_prints_each_supported_value_type() {
    // Given
    let program = lower(
        "DIM count%\ncount% = 42\nPRINT count%\nDIM ratio#\nratio# = 1.5\nPRINT ratio#\nDIM name$\nname$ = \"hello\"\nPRINT name$\n",
    );
    let mut output = Vec::new();

    // When
    let state = Interpreter::new().execute(&program, &mut output).unwrap();

    // Then
    assert_eq!(output, ["42", "1.5", "hello"]);
    assert_eq!(
        state.slot("count").unwrap().value(),
        &RuntimeValue::Integer(42)
    );
    assert_eq!(
        state.slot("ratio").unwrap().value(),
        &RuntimeValue::Float(1.5)
    );
    assert_eq!(
        state.slot("name").unwrap().value(),
        &RuntimeValue::String(b"hello".to_vec())
    );
}

#[test]
fn prints_hexadecimal_integer_literal() {
    let program = lower("PRINT 0x2A\n");
    let mut output = Vec::new();
    Interpreter::new().execute(&program, &mut output).unwrap();
    assert_eq!(output, ["42"]);
}

#[test]
fn prints_system_constant_without_allocating_runtime_slot() {
    let program = lower("$$XBSysLinux = 1\nFUNCTION Main\nPRINT $$XBSysLinux\nEND FUNCTION\n");
    let mut output = Vec::new();
    let state = Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["1"]);
    assert!(state.slot("XBSysLinux").is_none());
}

#[test]
fn mutates_shared_slot_across_reassignment() {
    let program = lower(
        "FUNCTION Main\n##XBSystem = 1\nPRINT ##XBSystem\n##XBSystem = 2\nPRINT ##XBSystem\nEND FUNCTION\n",
    );
    let mut output = Vec::new();
    let state = Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["1", "2"]);
    assert_eq!(
        state.shared_slot("XBSystem").unwrap().value(),
        &RuntimeValue::Integer(2)
    );
}

#[test]
fn keeps_shared_slot_separate_from_the_dimmed_variable_of_the_same_name() {
    let program = lower(
        "DIM Value\nValue = 1\nPRINT Value\nFUNCTION Main\n##Value = 2\nPRINT ##Value\nEND FUNCTION\n",
    );
    let mut output = Vec::new();
    let state = Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["1", "2"]);
    assert_eq!(
        state.slot("Value").unwrap().value(),
        &RuntimeValue::Integer(1)
    );
    assert_eq!(
        state.shared_slot("Value").unwrap().value(),
        &RuntimeValue::Integer(2)
    );
}

#[test]
fn reads_unassigned_variable_as_default() {
    // Given: XBasic auto-declares locals on first use; an unassigned
    // Integer variable reads as its default (0).
    let program = IrProgram {
        items: vec![IrItem::Print {
            items: vec![expression(
                IrExprKind::Symbol(symbol("missing", ValueType::Integer)),
                ValueType::Integer,
            )],
            separators: vec![],
        }],
        data_values: Vec::new(),
    };
    let mut output = Vec::new();

    // When
    Interpreter::new().execute(&program, &mut output).unwrap();

    // Then
    assert_eq!(output, ["0"]);
}

#[test]
fn allows_redimension_of_slot() {
    // Given: XBasic permits re-dimensioning — a repeated DIM replaces the slot.
    let repeated = symbol("count", ValueType::Integer);
    let program = IrProgram {
        items: vec![
            IrItem::Dim {
                symbol: repeated.clone(),
                size: None,
            },
            IrItem::Dim {
                symbol: repeated,
                size: None,
            },
        ],
        data_values: Vec::new(),
    };
    let mut output = Vec::new();

    // When
    let state = Interpreter::new().execute(&program, &mut output).unwrap();

    // Then
    assert!(state.slot("count").is_some());
}

#[test]
fn rejects_invalid_integer_literal() {
    // Given
    let program = IrProgram {
        items: vec![IrItem::Print {
            items: vec![expression(
                IrExprKind::IntegerLiteral("0x".to_string()),
                ValueType::Integer,
            )],
            separators: vec![],
        }],
        data_values: Vec::new(),
    };
    let mut output = Vec::new();

    // When
    let result = Interpreter::new().execute(&program, &mut output);

    // Then
    assert_eq!(
        result,
        Err(RuntimeError::InvalidLiteral {
            literal: "0x".to_string(),
            value_type: ValueType::Integer,
        })
    );
}

#[test]
fn coerces_string_value_to_integer_target() {
    // XBasic implicitly coerces on assignment: "42" -> 42 for an Integer target.
    let count = symbol("count", ValueType::Integer);
    let program = IrProgram {
        items: vec![
            IrItem::Dim {
                symbol: count.clone(),
                size: None,
            },
            IrItem::Assignment {
                target: count.clone(),
                value: expression(
                    IrExprKind::StringLiteral("42".to_string()),
                    ValueType::String,
                ),
            },
            IrItem::Print {
                items: vec![expression(IrExprKind::Symbol(count), ValueType::Integer)],
                separators: vec![],
            },
        ],
        data_values: Vec::new(),
    };
    let mut output = Vec::new();
    Interpreter::new().execute(&program, &mut output).unwrap();
    assert_eq!(output, ["42"]);
}

#[test]
fn execute_main_runs_top_level_then_main_in_same_state() {
    // Given
    let program = lower(
        "VERSION \"6.5.0\"\nDIM global$\nglobal$ = \"global\"\nPRINT \"top\"\nFUNCTION Helper\nPRINT \"helper-must-not-run\"\nEND FUNCTION\nFUNCTION Main\nDIM local$\nlocal$ = \"main\"\nPRINT local$\nEND FUNCTION\nFUNCTION Other\nPRINT \"other-must-not-run\"\nEND FUNCTION\n",
    );
    let mut output = Vec::new();

    // When
    let state = Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();

    // Then
    assert_eq!(output, ["top", "main"]);
    assert_eq!(state.metadata().version(), Some("6.5.0"));
    let g = state.slot("global").unwrap();
    assert_eq!(g.value(), &RuntimeValue::String(b"global".to_vec()));
    let l = state.slot("local").unwrap();
    assert_eq!(l.value(), &RuntimeValue::String(b"main".to_vec()));
}

#[test]
fn execute_main_falls_back_to_first_function_when_main_absent() {
    // Given: no `Main`, so the first defined function is the entry point
    // (legacy XBasic runs the first function, commonly named `Entry`).
    let program = lower("PRINT \"top\"\nFUNCTION Entry\nPRINT \"entry-ran\"\nEND FUNCTION\n");
    let mut output = Vec::new();

    // When
    let result = Interpreter::new().execute_main(&program, &mut output);

    // Then
    assert!(result.is_ok());
    assert_eq!(output, ["top", "entry-ran"]);
}

#[test]
fn executes_if_branches() {
    let prog = lower("IF 1 THEN\nPRINT 42\nEND IF\n");
    let mut out = Vec::new();
    Interpreter::new().execute(&prog, &mut out).unwrap();
    assert_eq!(out, ["42"]);
    let prog = lower("IF 0 THEN\nPRINT 1\nELSE\nPRINT 0\nEND IF\n");
    out.clear();
    Interpreter::new().execute(&prog, &mut out).unwrap();
    assert_eq!(out, ["0"]);
}

#[test]
fn executes_comparison_branches() {
    let prog = lower("IF 1 = 1 THEN\nPRINT 1\nEND IF\n");
    let mut out = Vec::new();
    Interpreter::new().execute(&prog, &mut out).unwrap();
    assert_eq!(out, ["1"]);
    let prog = lower("IF 1 <> 1 THEN\nPRINT 1\nELSE\nPRINT 0\nEND IF\n");
    out.clear();
    Interpreter::new().execute(&prog, &mut out).unwrap();
    assert_eq!(out, ["0"]);
}

#[test]
fn nested_composite_members_resolve_to_declared_float_type() {
    // A TYPE whose members are themselves composites (BINODE holds two BICOORDs).
    // Member access must recurse to the leaf float slots (`L1.a.x`), not collapse
    // the nested member to a scalar integer (which truncated 10.5 -> 10).
    let program = lower(
        "VERSION \"0.1\"\n\
         TYPE BICOORD\nSINGLE .x\nSINGLE .y\nEND TYPE\n\
         TYPE BINODE\nBICOORD .a\nBICOORD .b\nEND TYPE\n\
         FUNCTION Main\n\
         BINODE L1\n\
         L1.a.x = 10.5\n\
         L1.b.y = 20.25\n\
         PRINT L1.a.x\n\
         PRINT L1.b.y\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["10.5", "20.25"]);
}

#[test]
fn by_ref_parameter_writes_back_to_caller() {
    // `@x` passes x by reference; the callee's mutation must propagate back to
    // the caller's variable after the call returns.
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION DoubleIt (@n)\n\
         n = n * 2\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         DIM x\n\
         x = 21\n\
         DoubleIt(@x)\n\
         PRINT x\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["42"]);
}

#[test]
fn composite_by_ref_parameter_writes_members_back() {
    // A composite passed `@`-by-reference: the callee's member writes propagate
    // to the caller (flattened struct-of-arrays params + per-member by-ref).
    let program = lower(
        "VERSION \"0.1\"\n\
         TYPE BICOORD\nSINGLE .x\nSINGLE .y\nEND TYPE\n\
         FUNCTION SetPoint (BICOORD @p, v!)\n\
         p.x = v!\n\
         p.y = v! * 2\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         BICOORD q\n\
         SetPoint(@q, 5.5)\n\
         PRINT q.x\n\
         PRINT q.y\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["5.5", "11"]);
}

#[test]
fn compares_float_to_integer_literal() {
    // `a! = 0` compares a float to an integer literal; the runtime must promote
    // the integer, not raise a type mismatch.
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM a!\n\
         a! = 3\n\
         IF a! = 0 THEN\nPRINT 1\nELSE\nPRINT 2\nEND IF\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["2"]);
}

#[test]
fn fixed_length_string_composite_member_holds_string() {
    // A `STRING*N` (fixed-length) composite member must be a String slot, not an
    // Integer that renders as `0`. The parser previously dropped the member
    // entirely because the `*N` size spec sat between the type keyword and the
    // `.member` (RT-FIXEDSTR).
    let program = lower(
        "VERSION \"0.1\"\n\
         TYPE R\nSTRING*32 .s\nSTRING .t\nEND TYPE\n\
         FUNCTION Main\n\
         R r\n\
         r.s = \"hi\"\n\
         r.t = \"yo\"\n\
         PRINT r.s\n\
         PRINT r.t\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["hi", "yo"]);
}

#[test]
fn chr_above_127_is_a_single_byte() {
    // CHR$(n) for n>127 must be one raw byte, not a multi-byte UTF-8 char;
    // LEN counts bytes and ASC round-trips it. (RT-BYTESTRING)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM c$\n\
         c$ = CHR$(200)\n\
         PRINT LEN(c$)\n\
         PRINT ASC(c$)\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["1", "200"]);
}

#[test]
fn string_builtins_are_byte_accurate() {
    // Concat/LEN/MID$/RIGHT$ operate on raw bytes; high bytes survive intact.
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM s$\n\
         s$ = CHR$(200) + CHR$(65) + CHR$(255)\n\
         PRINT LEN(s$)\n\
         PRINT ASC(MID$(s$, 1, 1))\n\
         PRINT ASC(MID$(s$, 3, 1))\n\
         PRINT ASC(RIGHT$(s$, 1))\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["3", "200", "255", "255"]);
}

#[test]
fn select_case_true_matches_first_truthy_branch() {
    // `SELECT CASE TRUE` matches the first CASE whose condition is truthy
    // (non-zero), not one equal to a literal 1. (SEL-CASE-TRUE)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM x\n\
         x = 5\n\
         SELECT CASE TRUE\n\
         CASE x > 100 : PRINT \"big\"\n\
         CASE x > 3 : PRINT \"mid\"\n\
         CASE ELSE : PRINT \"small\"\n\
         END SELECT\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["mid"]);
}

#[test]
fn select_case_all_true_runs_every_truthy_branch() {
    // `SELECT CASE ALL TRUE` runs the body of EVERY truthy CASE, not just the
    // first. (SEL-CASE-TRUE)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM x\n\
         x = 5\n\
         SELECT CASE ALL TRUE\n\
         CASE x > 3 : PRINT \"a\"\n\
         CASE x > 4 : PRINT \"b\"\n\
         CASE x > 9 : PRINT \"c\"\n\
         END SELECT\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["a", "b"]);
}
