use xb_compiler::{
    EntryLookupError, FrontendUnit, IrExpr, IrExprKind, IrItem, IrProgram, IrSymbol, ValueType,
};
use xb_runtime::{Interpreter, RuntimeError, RuntimeValue};

fn lower(source: &str) -> IrProgram {
    FrontendUnit::parse(source).unwrap().lower_ir().unwrap()
}

fn symbol(name: &str, value_type: ValueType) -> IrSymbol {
    IrSymbol {
        name: name.to_string(),
        value_type,
    }
}

fn expression(kind: IrExprKind, value_type: ValueType) -> IrExpr {
    IrExpr { kind, value_type }
}

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
    assert_eq!(s.value(), &RuntimeValue::String(String::new()));
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
        &RuntimeValue::String("hello".to_string())
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
fn rejects_unknown_runtime_slot() {
    // Given
    let program = IrProgram {
        items: vec![IrItem::Print(expression(
            IrExprKind::Symbol(symbol("missing", ValueType::Integer)),
            ValueType::Integer,
        ))],
    };
    let mut output = Vec::new();

    // When
    let result = Interpreter::new().execute(&program, &mut output);

    // Then
    assert_eq!(
        result,
        Err(RuntimeError::UnknownSlot {
            name: "missing".to_string()
        })
    );
}

#[test]
fn rejects_duplicate_runtime_slot() {
    // Given
    let repeated = symbol("count", ValueType::Integer);
    let program = IrProgram {
        items: vec![
            IrItem::Dim {
                symbol: repeated.clone(),
            },
            IrItem::Dim { symbol: repeated },
        ],
    };
    let mut output = Vec::new();

    // When
    let result = Interpreter::new().execute(&program, &mut output);

    // Then
    assert_eq!(
        result,
        Err(RuntimeError::DuplicateSlot {
            name: "count".to_string()
        })
    );
}

#[test]
fn rejects_invalid_integer_literal() {
    // Given
    let program = IrProgram {
        items: vec![IrItem::Print(expression(
            IrExprKind::IntegerLiteral("0x".to_string()),
            ValueType::Integer,
        ))],
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
fn rejects_runtime_type_mismatch() {
    let count = symbol("count", ValueType::Integer);
    let program = IrProgram {
        items: vec![
            IrItem::Dim {
                symbol: count.clone(),
            },
            IrItem::Assignment {
                target: count,
                value: expression(
                    IrExprKind::StringLiteral("wrong".to_string()),
                    ValueType::String,
                ),
            },
        ],
    };
    let mut output = Vec::new();
    let result = Interpreter::new().execute(&program, &mut output);
    assert_eq!(
        result,
        Err(RuntimeError::TypeMismatch {
            expected: ValueType::Integer,
            actual: ValueType::String
        })
    );
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
    assert_eq!(g.value(), &RuntimeValue::String("global".to_string()));
    let l = state.slot("local").unwrap();
    assert_eq!(l.value(), &RuntimeValue::String("main".to_string()));
}

#[test]
fn execute_main_reports_typed_error_when_main_is_missing() {
    // Given
    let program =
        lower("PRINT \"top\"\nFUNCTION Helper\nPRINT \"helper-must-not-run\"\nEND FUNCTION\n");
    let mut output = Vec::new();

    // When
    let result = Interpreter::new().execute_main(&program, &mut output);

    // Then
    assert_eq!(output, ["top"]);
    assert_eq!(
        result,
        Err(RuntimeError::EntryLookup(EntryLookupError::Missing {
            name: "Main".to_string(),
        }))
    );
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
