# Stage-2 Contract v0.1: Frozen Compiler Subset

> Status: Freezes the currently implemented source, typed-IR, diagnostic, and
> `Interpreter::execute_main` behavior as of 2026-08-14. This contract defines the
> Stage-2 M1 corpus. It does not claim compiler self-hosting.

## 1. Scope

This contract freezes only behavior that is implemented today in the Rust workspace:

- the source subset accepted by the lexer and parser (`xb-frontend`);
- the typed IR produced by the analyzer and lowerer (`xb-compiler`);
- the source diagnostics reported by the frontend and analyzer;
- the deterministic text IR emitted by `TextIrEmitter` and printed by the `xb` CLI;
- the `Interpreter::execute_main` execution semantics (`xb-runtime`).

The contract does not freeze LLVM codegen, linking, or any behavior that is not
implemented. It is the acceptance basis for the Stage-2 M1 corpus.

## 2. Source subset

Statements, one per line:

| Statement | Form |
|---|---|
| VERSION | `VERSION "string"` |
| PRINT | `PRINT expression` |
| DIM | `DIM name[suffix]` |
| Assignment | `name[suffix] = expression` |
| Function | `FUNCTION name` ... `END FUNCTION` |

Expressions:

- string literal `"..."` (no escapes; an unterminated string is an error);
- integer literal: decimal digits, or `0x`/`0X` hexadecimal;
- float literal: decimal digits with `.` and/or `e`/`E` exponent;
- identifier reference `name[suffix]`.

On `DIM`, `$` selects string, `%` selects integer, `!` and `#` select float, and no
suffix selects integer. Assignment-target and identifier-reference suffixes are parsed
but currently ignored during semantic lookup; the declared symbol controls the type.
`ValueType` is `Integer`, `Float`, or `String`.

Comments start with `'` and run to end of line. Keywords are case-insensitive;
identifiers keep their case, so entry lookup is exact-case.

Semantic rules:

- a symbol must be declared by `DIM` in the same scope before it is used;
- an assignment target must exist and its type must match the RHS type;
- a duplicate `DIM` in the same scope is an error;
- each function body has its own scope.

## 3. Typed IR and deterministic text IR

`IrProgram` items: `Version(String)`, `Print(IrExpr)`, `Dim { symbol }`,
`Assignment { target, value }`, `Function { name, body }`. `IrExpr` is a literal or
symbol reference plus a `ValueType`. `IrSymbol` is a name plus a `ValueType`.

`TextIrEmitter` serializes the IR deterministically, one item per line, with two-space
indent per function nesting:

```text
version 6.5.0
dim name:string
assign name:string = string("hello")
print symbol(name:string)
```

- `version <value>`, `dim <name>:<type>`, `assign <name>:<type> = <expr>`,
  `print <expr>`, `function <name>` ... `end function`;
- expressions: `string("...")` (Rust Debug quoting), `integer(<value>)`,
  `float(<value>)`, `symbol(<name>:<type>)`;
- types: `integer`, `float`, `string`.

## 4. Diagnostics

Source diagnostic corpus:

| ID | Error | Stage |
|---|---|---|
| XB-L001 | UnterminatedString | lexer |
| XB-L002 | UnexpectedChar | lexer |
| XB-P001 | Expected | parser |
| XB-S001 | DuplicateSymbol | analyzer |
| XB-S002 | UnknownSymbol | analyzer |
| XB-S003 | TypeMismatch | analyzer |
| XB-B001 | LlvmDisabled | backend |

Source diagnostics exclude XB-B001: it is a backend configuration error, not a source
diagnostic. Runtime errors (`DuplicateSlot`, `UnknownSlot`, `TypeMismatch`,
`InvalidLiteral`, `EntryLookup`) are outside this source diagnostic corpus.

## 5. Interpreter behavior

`Interpreter::execute_main(program, output)`:

- executes top-level items in order, then the first exact-case `Main` function body, in
  the same shared `ExecutionState`;
- never enters non-`Main` function bodies;
- `VERSION` sets metadata (last one wins);
- `DIM` allocates a typed slot with the default value: integer `0`, float `0.0`,
  string `""`;
- assignment evaluates the RHS, checks the target type, and stores the value;
- `PRINT` renders the value and appends one line to the output vector;
- rendering: integer decimal (hex literal `0x2A` renders `42`), float via Rust `f64`
  display, string raw;
- entry lookup is exact-case: `Main` succeeds, `main` does not.

Interpretation is LLVM-independent: the interpreter executes typed IR directly with no
LLVM involvement.

## 6. Fixture expectations

- Positive fixtures: `fixtures/corpus/v0.1/positive/<name>.x` with committed `<name>.ir`
  (CLI text IR summary) and `<name>.out` (interpreter output via `execute_main`, one
  line per `PRINT`).
- Negative fixtures: `fixtures/corpus/v0.1/negative/<name>.x` with committed `<name>.diag`
  containing the source diagnostic ID, for example `XB-S002`.
- Live selfhost source: `selfhost/xut_bootstrap_manifest.x` with committed IR and output
  goldens under `fixtures/corpus/v0.1/selfhost/`, executed through `FrontendUnit`
  lowering and `Interpreter::execute_main`.

The corpus harness is `crates/xb-runtime/tests/corpus.rs`. It uses existing public APIs
(`FrontendUnit`, `TextIrEmitter`, `Interpreter::execute_main`) and adds no new dependency.

## 7. Deferrals

Explicitly deferred and outside this contract:

- LLVM 22 and native object emission (`CompileError::LlvmDisabled` remains the default);
- linking and executable production;
- self-rebuild and artifact or behavioral equivalence;
- the CI matrix (Linux, macOS, Win64);
- VEH and signal FFI;
- new syntax, coercions, and compatibility beyond the frozen subset.
