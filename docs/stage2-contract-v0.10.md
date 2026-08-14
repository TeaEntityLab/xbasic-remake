# Stage-2 Contract v0.10: String Concatenation

> Status: Freezes string concatenation via `+` operator. One historical
> feature increment on top of v0.1 through v0.8.

## 1. Scope

The `+` operator, when applied to two String operands, performs string
concatenation. Other arithmetic operators (`-`, `*`, `/`) on String operands
remain a semantic error (XB-S016).

## 2. Semantics

- `string + string` → String (concatenation)
- `string - string`, `string * string`, `string / string` → ArithmeticStringOperand (XB-S016)
- `string + integer` (mixed types) → ArithmeticStringOperand (XB-S016)
- Numeric `+` behavior unchanged from v0.7

## 3. Runtime

String concatenation uses Rust `format!("{a}{b}")`. The result is a new
`RuntimeValue::String`.

## 4. Text IR

```
arith(symbol(a:string) + symbol(b:string))
arith(arith(string("foo") + string("bar")) + string("baz"))
```

## 5. Compatibility

All prior contracts remain frozen. The negative fixture for XB-S016
(`arithmetic_string_operand.x`) still triggers because it mixes String and
Integer operands.
