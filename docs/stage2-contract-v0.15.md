# Stage-2 Contract v0.15 — ELSEIF Chains

## Feature

ELSEIF keyword for multi-branch conditional chains.

## Syntax

```xbasic
IF condition1 THEN
  body1
ELSEIF condition2 THEN
  body2
ELSEIF condition3 THEN
  body3
ELSE
  body4
END IF
```

## Semantics

ELSEIF desugars to nested IF in the else_body. No AST, IR, or runtime changes —
the existing `Statement::If` with `else_body: Option<Vec<Statement>>` represents
the chain as right-nested conditionals.

## Parser

- `Keyword::ElseIf` added to `token.rs` enum and lookup.
- `starts_elseif()` and `starts_if_boundary()` added to `parser_cursor.rs`.
- `if_stmt()` in `parser.rs` delegates to `parse_if_chain()` in `parser_if.rs`.
- `parse_if_chain()` recursively handles ELSEIF by consuming the keyword and
  building a nested `Statement::If` in the else_body.

## Fixture

`fixtures/corpus/v0.1/positive/elseif.x` — x=2 triggers the second ELSEIF branch,
printing "two".

## Golden Evidence

- `elseif.ir`: right-nested if/else chain in text IR.
- `elseif.out`: `two\n`.

## Module Extraction

`parser_if.rs` (37 LOC) extracted from `parser.rs` to stay under 250 LOC limit.
