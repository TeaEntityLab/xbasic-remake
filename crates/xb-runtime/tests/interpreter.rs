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
                extra_dims: Vec::new(),
                is_array: false,
                redim: false,
                shared: false,
            },
            IrItem::Dim {
                symbol: repeated,
                size: None,
                extra_dims: Vec::new(),
                is_array: false,
                redim: false,
                shared: false,
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
                extra_dims: Vec::new(),
                is_array: false,
                redim: false,
                shared: false,
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
fn array_by_ref_parameter_is_readable_in_callee() {
    // `@a[]` passes an array by reference; the callee can read its elements and
    // UBOUND (the caller's storage + shape are threaded into the param slot).
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Show (@a[])\n\
         PRINT a[0]\nPRINT a[1]\nPRINT UBOUND(a[])\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         DIM a[3]\n\
         a[0] = 11\n\
         a[1] = 22\n\
         Show(@a[])\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["11", "22", "3"]);
}

#[test]
fn array_by_ref_parameter_writes_elements_back() {
    // A callee's element writes through `@a[]` propagate to the caller's array.
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Fill (@a[])\n\
         a[0] = 7\n\
         a[1] = 8\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         DIM a[3]\n\
         Fill(@a[])\n\
         PRINT a[0]\nPRINT a[1]\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["7", "8"]);
}

#[test]
fn redim_through_by_ref_resizes_callers_array() {
    // The callee `REDIM`s a by-ref array; the resize + fills must be written back
    // into the caller's storage (REDIM-through-by-ref).
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Fill (@a[])\n\
         REDIM a[3]\n\
         a[0] = 42\n\
         a[3] = 99\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         DIM a[]\n\
         Fill(@a[])\n\
         PRINT UBOUND(a[])\nPRINT a[0]\nPRINT a[3]\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["3", "42", "99"]);
}

#[test]
fn string_array_by_ref_keeps_suffix_naming() {
    // A string array `@a$[]` must keep its `$` in the by-ref symbol and the param
    // slot (matching DIM / element access), so the callee binds to the passed-in
    // array instead of a scalar named `a`.
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Fill (@a$[])\n\
         a$[0] = \"hi\"\n\
         a$[1] = \"yo\"\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         DIM a$[3]\n\
         Fill(@a$[])\n\
         PRINT a$[0]\nPRINT a$[1]\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["hi", "yo"]);
}

#[test]
fn shared_keyword_array_persists_across_functions() {
    // A `SHARED x[]` array lives in the module-shared store: one function sizes +
    // fills it, another reads it back after the call. (Only arrays route to the
    // shared store; scalar `SHARED` keeps its per-function behavior.)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Init ()\n\
         SHARED g$[3]\n\
         g$[0] = \"hello\"\n\
         g$[1] = \"world\"\n\
         END FUNCTION\n\
         FUNCTION Use ()\n\
         SHARED g$[]\n\
         PRINT g$[0]\nPRINT g$[1]\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         Init ()\n\
         Use ()\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["hello", "world"]);
}

#[test]
fn composite_array_by_ref_param_member_assignment() {
    // A composite *array* passed `@p[]` by reference: `p[i].member = v` in the
    // callee must bind to the per-member array (`p.member[i]`) and write back to
    // the caller — not misfire as a scalar byte-index. (No REDIM in the callee;
    // it relies on the passed-in array's shape.)
    let program = lower(
        "VERSION \"0.1\"\n\
         TYPE PT\nINT .n\nEND TYPE\n\
         FUNCTION Fill (PT @p[])\n\
         i = 0\n\
         p[i].n = 10\n\
         p[1].n = 20\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         PT arr[3]\n\
         DIM arr[3]\n\
         Fill(@arr[])\n\
         PRINT arr[0].n\nPRINT arr[1].n\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["10", "20"]);
}

#[test]
fn composite_shared_array_persists_across_functions() {
    // A composite `SHARED` array (`SHARED VD v[n]`) sizes its flattened member
    // arrays in the module-shared store; another function's `SHARED VD v[]` reads
    // them back — `v[i].member` binds to the shared per-member array.
    let program = lower(
        "VERSION \"0.1\"\n\
         TYPE VD\nINT .numElements\nEND TYPE\n\
         FUNCTION Init ()\n\
         SHARED VD v[3]\n\
         v[0].numElements = 42\n\
         v[1].numElements = 7\n\
         END FUNCTION\n\
         FUNCTION Use ()\n\
         SHARED VD v[]\n\
         PRINT v[0].numElements\nPRINT v[1].numElements\n\
         END FUNCTION\n\
         FUNCTION Main\n\
         Init ()\n\
         Use ()\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["42", "7"]);
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

#[test]
fn numeric_then_string_same_base_name_are_distinct_slots() {
    // A numeric `c` and a string `c$` sharing a base name must be distinct slots:
    // assigning `c$` must not clobber `c`, and reads of each see their own value.
    // (VAR-SUFFIX-COLLISION: assignment target now names the slot like reads do.)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         c = 5\n\
         c$ = \"F\"\n\
         PRINT c\n\
         PRINT c$\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["5", "F"]);
}

#[test]
fn string_then_numeric_same_base_name_are_distinct_slots() {
    // The string `c$` used BEFORE the numeric `c` must still keep distinct slots:
    // the per-function collision pre-scan is order-independent. (VAR-SUFFIX-COLLISION)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         c$ = \"F\"\n\
         c = 5\n\
         PRINT c$\n\
         PRINT c\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["F", "5"]);
}

#[test]
fn gosub_to_local_sub_shares_caller_scope() {
    // A local SUB reached by GOSUB runs in the caller's variable scope, so its
    // mutations are visible after it returns. (GOSUB-SCOPE)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM x\n\
         x = 5\n\
         GOSUB Bump\n\
         PRINT x\n\
         SUB Bump\n\
         x = x + 10\n\
         END SUB\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["15"]);
}

#[test]
fn redim_grows_preserving_contents_from_empty_dim() {
    // `DIM a$[]` is an empty (growable) array: UBOUND = -1. `REDIM a$[n]` resizes
    // preserving existing elements, so values survive successive grows via the
    // `REDIM a$[UBOUND(a$[]) + N]` idiom pervasive in the legacy corpus. (MIG-ARY-PERF)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM a$[]\n\
         PRINT UBOUND(a$[])\n\
         REDIM a$[UBOUND(a$[]) + 3]\n\
         a$[0] = \"x\"\n\
         a$[2] = \"z\"\n\
         REDIM a$[UBOUND(a$[]) + 2]\n\
         PRINT UBOUND(a$[])\n\
         PRINT a$[0]\n\
         PRINT a$[2]\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["-1", "4", "x", "z"]);
}

#[test]
fn redim_shrink_truncates_and_preserves_low_indices() {
    // REDIM to a smaller inclusive bound truncates; surviving indices keep values.
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM a[5]\n\
         a[0] = 10\n\
         a[1] = 20\n\
         REDIM a[1]\n\
         PRINT UBOUND(a[])\n\
         PRINT a[0]\n\
         PRINT a[1]\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["1", "10", "20"]);
}

#[test]
fn func_addr_yields_stable_function_id() {
    // `&Func()` is address-of a function: it lowers to a FUNCADDR value = the
    // function's 1-based id (NOT a call), and is stable across evaluations.
    // (RT-FUNCPTR sub-step 1: address-of; indirect dispatch is a follow-on.)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         a = &Helper()\n\
         b = &Helper()\n\
         c = &Other()\n\
         PRINT a\n\
         PRINT c\n\
         IF a = b THEN PRINT \"stable\"\n\
         END FUNCTION\n\
         FUNCTION Helper ()\n\
         END FUNCTION\n\
         FUNCTION Other ()\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["2", "3", "stable"]);
}

#[test]
fn funcaddr_member_indirect_call_dispatches_and_writes_back() {
    // `&Func` stored in a FUNCADDR composite member, then called through it
    // (`@dog.setName(@dog, ...)`), dispatches to the target and writes the
    // composite-by-ref members back into the caller. (RT-FUNCPTR sub-step 2)
    let program = lower(
        "VERSION \"0.1\"\n\
         TYPE DOG\n\
         STRING*32 .name\n\
         FUNCADDR .setName (DOG, STRING)\n\
         END TYPE\n\
         FUNCTION Main\n\
         DOG dog\n\
         dog.setName = &NameDog()\n\
         @dog.setName (@dog, \"Rex\")\n\
         PRINT dog.name\n\
         END FUNCTION\n\
         FUNCTION NameDog (DOG dog, answer$)\n\
         dog.name = answer$\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["Rex"]);
}

#[test]
fn two_dim_array_cells_are_distinct() {
    // 2-D arrays index distinct cells row-major: `a[1,0]` and `a[1,1]` are
    // separate (the extra subscript was previously dropped, aliasing them to
    // `a[1]`). (MIG-ARY-MULTIDIM)
    let program = lower(
        "VERSION \"0.1\"\n\
         FUNCTION Main\n\
         DIM a[2,2]\n\
         a[1,0] = 7\n\
         a[1,1] = 9\n\
         PRINT a[1,0]\n\
         PRINT a[1,1]\n\
         END FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["7", "9"]);
}

#[test]
fn print_output_is_byte_faithful_for_high_bytes() {
    // High bytes (0x80–0xFF) must survive PRINT byte-for-byte — one `char` (0–255) per
    // source byte — instead of a UTF-8-lossy decode that maps them to U+FFFD. The CLI
    // writes each such char back as a raw byte, so `--run` output matches the compiled
    // backends. Regression guard for RT-BYTESTRING (fixes `aback`/`acharmap` output).
    let program = lower("VERSION \"1\"\nFUNCTION Main\nPRINT CHR$(200) + CHR$(255)\nEND FUNCTION\n");
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["\u{c8}\u{ff}"]);
}

#[test]
fn ifz_on_string_tests_emptiness() {
    // `IFZ s$` lowers to `s$ == 0`; a string compared against a number uses its length, so an
    // empty string is "zero" (IFZ true) and a non-empty one is not. Regression guard for the
    // String-vs-number comparison that unblocked `qbtoxb` (`IFZ qfile$`).
    let program = lower(
        "VERSION \"1\"\nFUNCTION Main\ns$ = \"\"\nIFZ s$ THEN PRINT \"empty\"\nt$ = \"x\"\nIFZ t$ THEN PRINT \"t\"\nPRINT \"done\"\nEND FUNCTION\n",
    );
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap();
    assert_eq!(output, ["empty", "done"]);
}
