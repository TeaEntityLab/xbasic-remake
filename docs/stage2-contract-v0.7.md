# Stage-2 Contract v0.7: Arithmetic Operators

> Status: Freezes the implemented arithmetic operators feature of the Rust
> workspace as of 2026-08-14. One historical feature increment on top of
> v0.1 through v0.6.

## 1. Scope

Adds arithmetic operators `+`, `-`, `*`, `/` with standard precedence to
expression contexts. Result type promotion: if either operand is Float, the
result is Float; otherwise Integer. String operands are rejected.

## 2. Syntax

```
expr := additive
additive := multiplicative (('+' | '-') multiplicative)*
multiplicative := primary (('*' | '/') primary)*
```

Comparison operators sit above `additive` in the precedence chain, preserving
the existing `comparison := additive (op additive)?` structure.

## 3. Semantics

- Both operands must be Integer or Float. String operands produce
  `ArithmeticStringOperand` (XB-S016).
- Result type: Float if either operand is Float, else Integer.
- Integer division truncates toward zero (Rust `i32` semantics).
- Division by zero is a runtime error (`RuntimeError::DivisionByZero`).

## 4. Diagnostics

| ID | Error | Trigger |
|---|---|---|
| XB-S016 | ArithmeticStringOperand | arithmetic operator applied to a String operand |

## 5. Text IR

```
arith(integer(2) * integer(3))
arith(arith(integer(2) * integer(3)) + integer(1))
arith(symbol(a:integer) + symbol(b:integer))
```

## 6. Runtime

The `arith` module evaluates arithmetic with wrapping integer arithmetic and
f64 float arithmetic. Mixed Integer/Float operands promote to Float.
Division by zero returns `RuntimeError::DivisionByZero`.

## 7. Compatibility

All prior contracts remain frozen. Golden IR files regenerated for
`all_constructs.x` and `xut_bootstrap_manifest.x` to include arithmetic
expressions.
