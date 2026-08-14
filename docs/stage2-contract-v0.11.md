# Stage-2 Contract v0.11: Built-in String Functions

> Status: Freezes built-in string functions. One historical feature increment
> on top of v0.1 through v0.10.

## 1. Scope

Adds six built-in string functions that can be called without a `FUNCTION`
declaration: `LEN`, `ASC`, `CHR$`, `LEFT$`, `RIGHT$`, `MID$`.

## 2. Functions

| Name | Params | Return | Behavior |
|---|---|---|---|
| `LEN(s$)` | String | Integer | Length of string in bytes |
| `ASC(s$)` | String | Integer | ASCII value of first character |
| `CHR$(n)` | Integer | String | Single character from code point |
| `LEFT$(s$, n)` | String, Integer | String | First `n` characters |
| `RIGHT$(s$, n)` | String, Integer | String | Last `n` characters |
| `MID$(s$, start, len)` | String, Integer, Integer | String | Substring from 1-based `start`, length `len` |

## 3. Semantics

Built-in functions are recognized by name before user-defined function lookup.
Argument count and types are checked against the built-in signature. The
function name suffix (`$`) is preserved in the function call name — the parser
appends the suffix character to the identifier name when forming a function
call expression.

## 4. Runtime

Built-in calls are intercepted in `call_function` before user-defined function
lookup. Arguments are evaluated in the caller's state, then the built-in
implementation produces the result directly.

## 5. Text IR

```
call LEN(symbol(s:string))
call LEFT$(symbol(s:string), integer(5))
call MID$(symbol(s:string), integer(7), integer(5))
call CHR$(integer(65))
call ASC(string("A"))
```

## 6. Compatibility

All prior contracts remain frozen. The parser now includes the type suffix
in function call names, so `LEFT$(s, 5)` produces `FunctionCall { name: "LEFT$" }`
rather than `FunctionCall { name: "LEFT" }`. User-defined functions with
suffixes (e.g. `FUNCTION Foo$`) are also affected — the call `Foo$(x)` now
correctly matches the declaration name `Foo$`.
