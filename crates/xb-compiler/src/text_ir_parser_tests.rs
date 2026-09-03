use crate::text_ir::TextIrEmitter;
use crate::text_ir_parser::TextIrParser;
use crate::{Analyzer, IrProgram};
use xb_frontend::parse_program;

fn round_trip(source: &str) {
    let program = parse_program(source).expect("parse");
    let checked = Analyzer::analyze(&program).expect("analyze");
    let ir = IrProgram::lower(&checked);
    let text = TextIrEmitter::new().emit_program(&ir);
    let parsed = TextIrParser::parse(&text).expect("parse text IR");
    let re_emitted = TextIrEmitter::new().emit_program(&parsed);
    assert_eq!(
        ir, parsed,
        "IrProgram mismatch:\n--- original IR ---\n{text}\n--- re-emitted ---\n{re_emitted}"
    );
    assert_eq!(
        text, re_emitted,
        "text mismatch:\n--- original ---\n{text}\n--- re-emitted ---\n{re_emitted}"
    );
}

#[test]
fn round_trip_version_print_dim() {
    round_trip(
        r#"VERSION "0.1"
DIM x
DIM s$
x = 42
s$ = "hello"
PRINT x
PRINT s$
"#,
    );
}

#[test]
fn round_trip_if_else() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM x
x = 1
IF x = 1 THEN
  PRINT "one"
ELSE
  PRINT "not one"
END IF
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_while_loop() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM i
i = 0
WHILE i < 10
  i = i + 1
WEND
PRINT i
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_for_next() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM i
DIM sum
sum = 0
FOR i = 1 TO 10
  sum = sum + i
NEXT i
PRINT sum
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_function_call_and_return() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Add(a, b)
RETURN a + b
END FUNCTION
FUNCTION Main
DIM r
r = Add(3, 4)
PRINT r
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_arithmetic_precedence() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM x
x = 1 + 2 * 3 - 4 / 2
PRINT x
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_boolean_and_not() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM x
x = NOT (1 AND 0)
PRINT x
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_string_concat() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM s$
s$ = "hello" + " " + "world"
PRINT s$
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_array_dim_and_access() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM a(10)
DIM i
FOR i = 0 TO 9
  a(i) = i * 2
NEXT i
PRINT a(5)
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_exit_loop() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM i
FOR i = 1 TO 100
  IF i > 5 THEN
    EXIT FOR
  END IF
NEXT i
PRINT i
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_elseif_chain() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM x
x = 2
IF x = 1 THEN
  PRINT "one"
ELSEIF x = 2 THEN
  PRINT "two"
ELSEIF x = 3 THEN
  PRINT "three"
ELSE
  PRINT "other"
END IF
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_standalone_call() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Foo
PRINT "foo"
END FUNCTION
FUNCTION Main
Foo()
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_builtin_string_functions() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM s$
DIM n
s$ = "hello world"
n = LEN(s$)
PRINT n
PRINT LEFT$(s$, 5)
PRINT RIGHT$(s$, 5)
PRINT MID$(s$, 7, 5)
PRINT CHR$(65)
PRINT ASC("A")
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_shared_variables() {
    round_trip(
        r#"VERSION "0.1"
$$PI = 3
FUNCTION Main
##counter = 0
##counter = ##counter + 1
PRINT ##counter
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_comparison_operators() {
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM a
DIM b
a = 5
b = 3
PRINT a = b
PRINT a <> b
PRINT a < b
PRINT a > b
PRINT a <= b
PRINT a >= b
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_attach_five_cases() {
    // All five ATTACH copy-semantics shapes must survive text IR emission
    // and parsing (the self-hosted cgen.x consumes this text): whole-array,
    // scalar/element both directions, and 2-D row extract/restore.
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM src[3]
DIM dst[3]
dst[0] = 10
dst[1] = 20
dst[2] = 30
ATTACH src[] TO dst[]
DIM val
ATTACH val TO dst[1]
val = 99
ATTACH dst[2] TO val
DIM src2[3]
DIM dst2[2,3]
dst2[0,0] = 100
ATTACH src2[] TO dst2[0,]
src2[0] = 999
ATTACH dst2[1,] TO src2[]
END FUNCTION
"#,
    );
}

#[test]
fn round_trip_redim_preserves_flag() {
    // REDIM must survive text IR emission/parsing as `redim` (not `dim`):
    // the flag separates content-preserving resize from zeroing DIM.
    round_trip(
        r#"VERSION "0.1"
FUNCTION Main
DIM a[2]
a[0] = 10
REDIM a[4]
PRINT a[0]
END FUNCTION
"#,
    );
}
