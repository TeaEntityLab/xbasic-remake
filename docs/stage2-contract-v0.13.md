# Stage-2 Contract v0.13: FOR/NEXT Loops

> Status: Freezes FOR/NEXT loop construct. One historical feature increment
> on top of v0.1 through v0.12.

## 1. Scope

Adds `FOR var = start TO end ... NEXT [var]` loop construct. The loop variable
must be a declared Integer. The loop iterates from `start` to `end` inclusive,
incrementing by 1 each iteration.

## 2. Syntax

```
FOR i = 1 TO 10
  PRINT i
NEXT i
```

The variable name after `NEXT` is optional (classic BASIC compatibility).

## 3. Semantics

- `var` must be a declared Integer symbol
- `start` and `end` must be Integer expressions
- Non-Integer types produce `IfConditionNotInteger` (XB-S014)
- `STEP` is not supported in this version

## 4. Runtime

The loop variable is set to `start`, then incremented by 1 each iteration
until it exceeds `end`. The body executes with the current value of the
loop variable. `Flow::Return` propagates out of the loop immediately.

## 5. Text IR

```
for i:integer = integer(1) to integer(10)
  assign sum:integer = arith(symbol(sum:integer) + symbol(i:integer))
next
```

## 6. Compatibility

All prior contracts remain frozen. `TO` keyword added to the keyword table.
FOR/NEXT can be used wherever statements are valid (top level or function body).
