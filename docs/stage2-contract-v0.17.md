# Stage-2 Contract v0.17 — String Functions INSTR, VAL, STR$

## Feature

Three new built-in string functions for parsing and conversion.

## Functions

| Function | Parameters | Return | Description |
|---|---|---|---|
| `INSTR(s$, sub$)` | String, String | Integer | 1-based position of first occurrence of `sub$` in `s$`; 0 if not found |
| `VAL(s$)` | String | Integer | Parses `s$` as integer; 0 on parse failure |
| `STR$(n)` | Integer | String | Converts integer to decimal string |

## Semantics

- `INSTR` is 1-based for consistency with `MID$`. Returns 0 when the substring
  is not found.
- `VAL` trims whitespace before parsing. Non-numeric input returns 0.
- `STR$` produces the same decimal representation as Rust's `i32::to_string`.

## Implementation

- **compiler/builtin.rs**: Added to `sig()` match for type checking.
- **runtime/builtin.rs**: Added to `eval_builtin()` match for execution.
- **runtime/call.rs**: Added to `is_builtin()` match for dispatch.

## Fixture

`fixtures/corpus/v0.1/positive/strfuncs2.x` — tests INSTR (found and not-found),
VAL, and STR$ round-trip.

## Golden Evidence

- `strfuncs2.ir`: `call INSTR(...)`, `call VAL(...)`, `call STR$(...)` in text IR.
- `strfuncs2.out`: `6\n42\n42\n0\n`.
