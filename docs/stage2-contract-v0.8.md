# Stage-2 Contract v0.8: WHILE/WEND Loops

> Status: Freezes the implemented WHILE/WEND loop feature. One historical
> feature increment on top of v0.1 through v0.7.

## 1. Scope

Adds `WHILE condition ... WEND` loops. The condition is evaluated before each
iteration; the loop body executes while the condition is nonzero (Integer
TRUE). The condition must be Integer-typed.

## 2. Syntax

```
WHILE expression
  body
WEND
```

## 3. Semantics

- Condition must be Integer-typed. Non-integer conditions produce
  `IfConditionNotInteger` (XB-S009), reusing the existing condition check.
- The body is a sequence of statements checked in the current scope.
- `RETURN` inside a WHILE body propagates through `Flow::Return` to exit
  the enclosing function.
- WHILE can be nested inside IF blocks and other WHILE blocks.

## 4. Text IR

```
while compare(symbol(i:integer) <= integer(5))
  assign sum:integer = arith(symbol(sum:integer) + symbol(i:integer))
  assign i:integer = arith(symbol(i:integer) + integer(1))
wend
```

## 5. Runtime

The interpreter evaluates the condition before each iteration. If the
condition is `Integer(0)`, the loop exits. Otherwise, the body executes via
`exec_items`. If `Flow::Return` is encountered, it propagates out of the
loop and function.

## 6. Compatibility

All prior contracts remain frozen. Golden IR files regenerated for
`all_constructs.x` and `xut_bootstrap_manifest.x`.
