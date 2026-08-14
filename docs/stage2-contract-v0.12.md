# Stage-2 Contract v0.12: Boolean Operators

> Status: Freezes AND, OR, NOT boolean operators. One historical feature
> increment on top of v0.1 through v0.11.

## 1. Scope

Adds three boolean operators: `AND` (bitwise), `OR` (bitwise), `NOT` (bitwise
negation). All operate on Integer operands and return Integer.

## 2. Semantics

- `NOT expr` — unary, requires Integer operand, returns Integer
- `expr AND expr` — binary, requires Integer operands, returns Integer
- `expr OR expr` — binary, requires Integer operands, returns Integer
- Non-Integer operands produce `IfConditionNotInteger` (XB-S014)

## 3. Precedence

Expression precedence (lowest to highest):
1. `OR` (lowest)
2. `AND`
3. `NOT` (unary)
4. Comparison (`=`, `<>`, `<`, `>`, `<=`, `>=`)
5. Additive (`+`, `-`)
6. Multiplicative (`*`, `/`)
7. Primary (literals, identifiers, function calls)

## 4. Runtime

Operations are bitwise on i32 values:
- `NOT x` → `!x` (bitwise complement)
- `x AND y` → `x & y` (bitwise and)
- `x OR y` → `x | y` (bitwise or)

For boolean conditions, nonzero = true, zero = false (classic BASIC semantics).

## 5. Text IR

```
not(symbol(a:integer))
and(symbol(a:integer) symbol(b:integer))
or(symbol(a:integer) symbol(b:integer))
```

## 6. Compatibility

All prior contracts remain frozen. The `Keyword::parse` table was restored to
include `PRINT` and `IMPORT` entries that were accidentally dropped during
keyword additions.
