# Stage-2 Contract v0.6: Function Calls & RETURN

> Status: Freezes the implemented function call and RETURN feature of the Rust
> workspace as of 2026-08-14. This is one historical feature increment on top of
> the frozen v0.1 through v0.5 contracts. It does not reopen them and does not
> claim full xut, arithmetic operators, or compiler self-hosting.

## 1. Scope

This contract adds exactly one feature to the accepted subset: function calls
with parameters and `RETURN` statements. Functions can now declare typed
parameters, be called as expressions, and return values via `RETURN`. Everything
else in v0.1 through v0.5 remains in force.

Prior to this contract, `FUNCTION`/`END FUNCTION` defined a function with a body
but no parameters and no return mechanism. The only entry point was `Main`,
called by `execute_main`. This contract adds:

- Typed parameters in function declarations: `FUNCTION Add(a, b)`.
- Return type inference from the function name suffix: `FUNCTION GetName$`
  returns `String`, `FUNCTION Count` returns `Integer`.
- `RETURN` statement with optional expression: `RETURN value` or bare `RETURN`.
- Function calls as expressions: `result = Add(3, 4)`, `PRINT Identity(42)`.
- Semantic checking of argument count, argument types, and return type.

## 2. Historical authority

XBasic 6.2.3 functions are declared with `FUNCTION name(params)` and return via
`RETURN value`. The function name suffix determines the return type. Parameters
are typed by their suffix. Examples from the historical source:

- `src/shared/xut.x` declares `FUNCTION XutInit(...)` with multiple parameters.
- `src/linux/xcol.x` declares `FUNCTION XcolMain(...)` as the compiler entry.
- Functions are called as expressions: `result = XcolCompile(source)`.

## 3. Accepted syntax

### Function declaration with parameters

```
FUNCTION name[(param[, param...])]
  body
END FUNCTION
```

Each `param` is an identifier with an optional type suffix. The function name
also has an optional type suffix that determines the return type:

- No suffix → `Integer` (default).
- `$` → `String`.
- `#` or `!` → `Float`.

### RETURN statement

```
RETURN [expression]
```

- `RETURN value` returns `value` from the current function. The expression's
  type must match the function's return type.
- Bare `RETURN` returns `Integer(0)` (default value for the return type).
- `RETURN` outside a function is a semantic error (XB-S014).

### Function call expression

```
name([arg[, arg...]])
```

Each `arg` is any expression (literal, identifier, constant, shared variable,
comparison, or nested function call). The call produces a value of the
function's return type.

## 4. Semantics

- Function signatures are registered as the analyzer encounters `FUNCTION`
  declarations. A function must be declared before it is called (top-to-bottom
  processing).
- Parameters are typed by their suffix and bound as local symbols in the
  function's scope. They shadow any top-level symbols of the same name.
- Argument count must match parameter count exactly (XB-S012).
- Each argument's type must match the corresponding parameter's type (XB-S013).
- `RETURN` with an expression checks that the expression type matches the
  function's return type (XB-S015).
- Calling an unknown function is a semantic error (XB-S011).
- Constants and shared variables are inherited by function scopes. Constants
  must be defined before the function declaration that references them.
- Shared variable mutations inside a function propagate to the outer scope.

## 5. Diagnostics

Five new analyzer diagnostics join the source diagnostic corpus, bringing it to
eighteen:

| ID | Error | Trigger |
|---|---|---|
| XB-S011 | UnknownFunction | calling a function name that has no `FUNCTION` declaration |
| XB-S012 | FunctionArgCount | calling a function with the wrong number of arguments |
| XB-S013 | FunctionArgType | an argument's type does not match the parameter's type |
| XB-S014 | ReturnOutsideFunction | `RETURN` appears at top level, not inside a function |
| XB-S015 | ReturnTypeMismatch | `RETURN` expression type does not match the function return type |

Each has a negative fixture under `fixtures/corpus/v0.1/negative/`.

## 6. Checked IR and text IR

The analyzer records function parameters and return type in `CheckedItem::Function
{ name, params, return_type, body }`. Each parameter is a `CheckedParam` with
name and value type.

`RETURN` is recorded as `CheckedItem::Return { value: Option<CheckedExpr> }`.

Function calls are recorded as `CheckedExprKind::FunctionCall { name, args }`
with the return type as the expression's value type.

The text IR renders:

```text
function First(a:integer, b:integer) -> integer
  if compare(symbol(a:integer) = symbol(b:integer))
    return symbol(a:integer)
  end if
  return symbol(b:integer)
end function
function Main() -> integer
  dim result:integer
  assign result:integer = call First(integer(3), integer(3))
  print symbol(result:integer)
end function
```

## 7. Runtime behavior

The interpreter evaluates function calls by:

1. Finding the `IrItem::Function` with the matching name in the program.
2. Evaluating each argument expression in the caller's state.
3. Creating a new `ExecutionState` with local slots for each parameter, bound
   to the argument values. Shared variables are inherited from the caller.
4. Executing the function body via `exec_items`.
5. If a `RETURN` statement is reached, `exec_items` returns `Flow::Return(value)`.
6. The returned value becomes the call expression's result.
7. If the function ends without `RETURN`, `Integer(0)` is returned as default.

The `Flow` enum (`Continue` | `Return(Option<RuntimeValue>)`) propagates through
nested `IF` blocks to allow early return from any depth within a function.

## 8. Selfhost manifest

`selfhost/xut_bootstrap_manifest.x` now declares `FUNCTION PlatformName$` which
returns `"linux"` when `$$XBSysLinux` is true, and `"unknown"` otherwise. The
`Main` function calls `PlatformName()` and prints the result. The interpreter
output grows from seven lines to eight:

```text
xut
0.0001
1
2
1
linux
match
linux
```

The trailing `linux` is printed by `PRINT PlatformName()`, demonstrating that
the function call evaluates correctly and returns the string `"linux"`.

## 9. Compatibility with v0.1 through v0.5

All prior contracts remain frozen. The only change to existing behavior is the
text IR format for function declarations: `function Main` becomes
`function Main() -> integer`. All golden files have been regenerated.

## 10. Deferrals and non-goals

- **No forward references**: Functions must be declared before they are called.
  A pre-pass to collect all function signatures first is deferred.
- **No recursion**: The interpreter does not prevent recursion, but it has not
  been tested and the lack of arithmetic operators makes most recursive
  patterns impossible.
- **No DECLARE/EXTERNAL**: External function declarations are not supported.
- **No overloading**: Function names are unique; there is no parameter-based
  dispatch.
- **No default arguments**: All parameters must be provided.
- **No arithmetic operators**: `RETURN a + b` is not supported. Use comparison
  and conditional logic instead.
- **No local variable declarations inside functions beyond DIM**: Local arrays,
  types, and nested functions are not supported.

This document records one historical feature increment: function calls with
parameters and RETURN. It is not arithmetic evaluation and not compiler
self-hosting.
