# Stage-2 Contract v0.16 — EXIT FOR / EXIT WHILE

## Feature

Early loop termination via `EXIT FOR` and `EXIT WHILE` statements.

## Syntax

```xbasic
FOR i = 1 TO 100
  IF condition THEN
    EXIT FOR
  END IF
  ...
NEXT i

WHILE pos <= LEN(src$)
  IF done THEN
    EXIT WHILE
  END IF
  ...
WEND
```

## Semantics

`EXIT FOR` and `EXIT WHILE` both produce `Statement::ExitLoop` in the AST.
At runtime, `IrItem::ExitLoop` returns `Flow::Break`, which propagates up
through IF bodies to the enclosing loop. The loop catches `Flow::Break` and
stops iterating. `Flow::Break` does not propagate through function call
boundaries — it only affects the innermost loop in the current function scope.

## AST

- `Statement::ExitLoop` — unit variant, no fields.

## Parser

- `Keyword::Exit` added to `token.rs` enum and lookup.
- `exit_stmt()` in `parser.rs` parses `EXIT FOR` or `EXIT WHILE`, consuming
  the loop-type keyword, and produces `Statement::ExitLoop`.

## IR

- `CheckedItem::ExitLoop` — unit variant.
- `IrItem::ExitLoop` — unit variant.
- Text IR: `exit_loop` on its own indented line.

## Runtime

- `Flow::Break` variant added to the `Flow` enum.
- `exec_items`: `IrItem::ExitLoop` returns `Ok(Flow::Break)`.
- IF bodies propagate `Flow::Break` upward via `return Ok(Flow::Break)`.
- WHILE loop catches `Flow::Break` via `break` (exits the `loop`).
- `exec_for` catches `Flow::Break` via `break` (exits the `while i <= ei`).
- Function calls swallow `Flow::Break` (contained in function scope).

## Fixture

`fixtures/corpus/v0.1/positive/exit.x` — sum of 1..100 with early exit when
sum exceeds 10. Output: `15` (1+2+3+4+5).

## Golden Evidence

- `exit.ir`: `exit_loop` within if/for structure.
- `exit.out`: `15\n`.
