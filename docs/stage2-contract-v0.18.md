# Stage-2 Contract v0.18 — Runtime Input: READLINE$ and EOF

## Feature

Built-in functions for reading input lines from a runtime-provided input buffer.

## Functions

| Function | Parameters | Return | Description |
|---|---|---|---|
| `READLINE$()` | none | String | Returns next input line; empty string at EOF |
| `EOF()` | none | Integer | Returns 1 if input exhausted, 0 otherwise |

## Usage

```xbasic
WHILE EOF() = 0
  line$ = READLINE$()
  IF EOF() = 0 THEN
    PRINT line$
  END IF
WEND
```

## Semantics

- Input is provided via `Interpreter::execute_main_with_input(program, input, output)`.
- `READLINE$()` pops the next line from the input buffer. At EOF, returns `""`.
- `EOF()` returns 1 when `input_pos >= input.len()`, 0 otherwise.
- Input position is shared across function calls: when a user function reads
  input, the position is synced back to the caller's state after the call returns.
- Both functions require parentheses `()` to be recognized as function calls.

## Implementation

- **slot.rs**: Added `input: Vec<String>` and `input_pos: usize` to `ExecutionState`.
- **interpreter.rs**: Added `execute_main_with_input` method. Changed `eval` to
  take `&mut ExecutionState` for stateful builtin support.
- **eval.rs**: Changed `eval_expr` to take `&mut ExecutionState`.
- **call.rs**: Changed `call_function` to take `&mut ExecutionState`. READLINE$
  and EOF handled before `is_builtin` dispatch. Input position synced back from
  sub-state after user function calls.
- **compiler/builtin.rs**: Added READLINE$ and EOF to `sig()` for type checking.
- **corpus test**: `validate_layout` accepts optional `&["in"]` extensions.
  `compile_and_run` loads `.in` file if present and uses
  `execute_main_with_input`.

## Fixture

`fixtures/corpus/v0.1/positive/input.x` with `input.in` containing 3 lines.
Output: 2 lines printed (third line triggers EOF before printing), then count.

## Golden Evidence

- `input.ir`: `call READLINE$()` and `call EOF()` in text IR.
- `input.out`: `Hello\nWorld\n2\n`.
- `input.in`: `Hello\nWorld\nTest\n`.
