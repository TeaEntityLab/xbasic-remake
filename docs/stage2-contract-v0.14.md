# Stage-2 Contract v0.14: Standalone Function Call Statements

> Status: Freezes standalone function call statements. One historical feature
> increment on top of v0.1 through v0.13.

## 1. Scope

Allows calling a function as a statement, discarding the return value. This
enables procedure-style calls without needing to assign the result.

## 2. Syntax

```
PrintSum(5, 10)
```

The parser recognizes an identifier followed by `(` as a call statement when
it appears in statement position (not after `=` in an assignment).

## 3. Semantics

- The function must be declared (user-defined or built-in)
- Arguments are type-checked against the function signature
- The return value is discarded
- The function name suffix is preserved (e.g., `Foo$(x)` calls `Foo$`)

## 4. Runtime

The `call_function` runtime now receives the caller's output buffer, so
`PRINT` statements inside called functions produce output visible to the
caller. Previously, function calls in expressions used a local output buffer
(which discarded PRINT output); standalone calls now correctly propagate.

## 5. Text IR

```
call PrintSum(symbol(n:integer), integer(10))
```

## 6. Compatibility

All prior contracts remain frozen. The `call_function` signature changed to
accept `&mut Vec<String>` for output propagation. Expression-level function
calls (in assignments, PRINT, conditions) still use a local buffer to avoid
side effects in expression context.
