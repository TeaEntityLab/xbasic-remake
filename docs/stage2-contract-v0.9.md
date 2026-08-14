# Stage-2 Contract v0.9: Arrays

> Status: Freezes one-dimensional arrays. One historical feature increment on
> top of v0.1 through v0.8 and v0.10 through v0.14.

## 1. Scope

Adds one-dimensional arrays with `DIM a(n)` declaration, `a(i)` element
access in expressions, and `a(i) = value` element assignment. Arrays are
typed by the variable's type suffix (Integer by default, String with `$`).

## 2. Syntax

```
DIM a(5)
a(0) = 42
PRINT a(0)
```

- `DIM a(5)` declares an array of 5 elements (indices 0–4)
- `a(i) = value` assigns to element `i`
- `a(i)` in an expression reads element `i`
- Array access uses `()` notation, consistent with BASIC tradition

## 3. Semantics

- The size expression in `DIM a(n)` must be Integer
- Array assignment requires the value type to match the array's element type
- Array access in expressions is resolved when the name matches a declared
  array symbol and there is exactly one argument; otherwise the name is
  treated as a function call
- Array symbols are tracked separately from scalar symbols in the analyzer

## 4. Runtime

- `TypedSlot` gains an `array: Option<Vec<RuntimeValue>>` field
- `DIM a(n)` allocates `n` default-initialized elements
- Array access reads `slot.array_get(index)`
- Array assignment writes `slot.array_set(index, value)`
- Out-of-range indices produce `RuntimeError::ArrayIndexOutOfRange`
- Operating on a non-array slot produces `RuntimeError::NotAnArray`

## 5. Text IR

```
dim a:integer[integer(5)]
array_assign a:integer[symbol(i:integer)] = arith(symbol(i:integer) * integer(2))
print array_access(a:integer[symbol(i:integer)])
```

## 6. Module Restructuring

To stay within the 250-LOC file limit, the following modules were extracted:

- `xb-runtime/src/slot.rs` — `RuntimeValue`, `TypedSlot`, `ExecutionState`,
  `ProgramMetadata`, `RuntimeError` (extracted from `interpreter.rs`)
- `xb-compiler/src/ir_lower.rs` — `IrExpr::lower` (extracted from `ir.rs`)
- `xb-compiler/src/text_ir_expr.rs` — `TextIrEmitter::emit_expr` (extracted
  from `text_ir.rs`)
- `xb-compiler/src/semantics_stmts.rs` — `Analyzer::dim`, `assignment`,
  `array_assignment` (extracted from `semantics.rs`)
- `xb-runtime/tests/common/mod.rs` — shared test helpers

## 7. Compatibility

All prior contracts remain frozen. The `CheckedItem::Dim` variant changed
from tuple `Dim(CheckedSymbol)` to struct `Dim { symbol, size }`. The
`IrItem::Dim` variant gained a `size: Option<IrExpr>` field. These are
internal compiler representations not exposed to user code.
