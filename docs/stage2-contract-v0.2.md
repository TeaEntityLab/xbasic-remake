# Stage-2 Contract v0.2: Shared Integer Constant Increment

> Status: Freezes the implemented `$$` shared integer constant feature of the Rust
> workspace as of 2026-08-14. This is one historical feature increment on top of the
> frozen v0.1 contract. It does not reopen v0.1 and does not claim full xut or compiler
> self-hosting.

## 1. Scope

This contract adds exactly one feature to the v0.1 subset: shared integer constants
written with the `$$` prefix, as used historically by the XBasic 6.2.3 compiler and
runtime sources. Everything else in v0.1 remains in force.

## 2. Historical authority

The `$$` constant syntax is taken directly from the XBasic 6.2.3 source tree:

- `src/shared/xut.x:25-26` defines `$$XBSysLinux = 1` and `$$XBSysWin32 = 2` inside the
  `EXPORT` block, documenting the XBasic system selector values.
- `src/linux/xrun.x:58-60` defines the top-level constants `$$TimerStart = 1`,
  `$$TimerExpire = 2`, and `$$TimerKill = 3` for `XxxXstTimer` command arguments.
- `src/linux/xcol.x:750+` opens the compiler constants section with definitions such as
  `$$VALUEABS = 0`, `$$VALUEDISP = 1`, and the `$$XGET`/`$$XSET` addressing and symbol
  mode constants.

These anchors are the authority for the form: a `$$`-prefixed name, `=`, and an integer
literal.

## 3. Accepted syntax

The parser accepts only this form, one per line:

```
$$Name = <integer literal>
```

Rules:

- The definition must be at top level. A `$$Name = ...` line inside a `FUNCTION` body is
  rejected.
- The right-hand side must be an existing integer literal (decimal or `0x`/`0X` hex).
  Any other RHS is a parse error.
- References to a defined constant are accepted wherever an expression is accepted,
  for example `PRINT $$Name` or `Mode% = $$Mode`.
- A constant must be declared before it is referenced. A forward reference at top level
  and a reference from a function defined before the definition both fail.
- Constants and variables live in separate namespaces: `DIM Value` and `$$Value = 1`
  coexist, and `$$Value` references resolve to the constant while `Value` resolves to
  the variable.

`$$Name = ...` is always a definition. The parser classifies any `$$Name =` line as a
constant definition, so a second `$$Name = ...` is a duplicate definition, not an
assignment to an existing constant.

## 4. `##` lexing status

The lexer tokenizes `##Name` as its own token kind (a system variable, distinct from
the `$$` system constant). This separation is implemented and tested, but `##` has no
parser or semantic support beyond lexing. Any `##` construct remains an error at parse
time.

## 5. Diagnostics

Three new analyzer diagnostics join the v0.1 source diagnostic corpus:

| ID | Error | Trigger |
|---|---|---|
| XB-S004 | DuplicateConstant | a second `$$Name = ...` definition |
| XB-S005 | UnknownConstant | a reference to an undefined constant |
| XB-S006 | ConstantDefinitionNotTopLevel | a `$$Name = ...` inside a function body |

Negative fixtures cover all three: `semantic_constant_redefinition` (XB-S004),
`semantic_unknown_constant` (XB-S005), and `semantic_nested_constant_definition`
(XB-S006).

## 6. Checked IR and text IR

The analyzer preserves the bare constant name and the raw integer value text, and
assigns `Integer` type, in both the definition and the reference. The IR keeps the same
shape: `IrItem::ConstantDefinition { name, value, value_type }` and
`IrExprKind::Constant { name, value }`. No folding or evaluation happens at analysis
time; the value string is carried through unchanged.

`TextIrEmitter` renders the two forms exactly:

```text
const $$Name:integer = integer(1)
print constant($$Name:integer = integer(1))
```

## 7. Runtime behavior

In `Interpreter::execute_main`:

- a `$$Name` definition is inert: it records nothing at runtime and allocates no slot;
- a `$$Name` reference evaluates the embedded integer value and renders it like any
  integer literal;
- no mutable slot or table is created for a constant, so no duplicate-slot or
  unknown-slot error can arise from constants.

The test `prints_system_constant_without_allocating_runtime_slot` confirms a
`$$XBSysLinux` reference prints `1` and that `state.slot("XBSysLinux")` is absent
after execution.

## 8. Selfhost manifest

The live source `selfhost/xut_bootstrap_manifest.x` now defines `$$XBSysLinux = 1` and
`$$XBSysWin32 = 2` as real historical constants, replacing the earlier fake DIM and
assignment identities for these values. The committed goldens under
`fixtures/corpus/v0.1/selfhost/` show the two `const $$...:integer = integer(...)`
definitions and the two `constant($$...:integer = integer(...))` references in the IR,
with the interpreter output unchanged at four lines:

```text
xut
0.0001
1
2
```

## 9. Compatibility with v0.1

`docs/stage2-contract-v0.1.md` remains a frozen record of the M1 subset and is not
amended by this document. The corpus harness path is unchanged: fixtures live under
`fixtures/corpus/v0.1` (positive, negative, and selfhost), the live selfhost source is
`selfhost/xut_bootstrap_manifest.x`, and the harness is
`crates/xb-runtime/tests/corpus.rs`.

## 10. Deferrals and non-goals

Explicitly outside this contract:

- `##` semantics beyond lexing;
- string or float constants;
- constant expressions or general constant folding;
- unary minus on constants;
- `PROGRAM`, `EXPORT`, `IMPORT`, and `DECLARE`;
- function calls and returns;
- `IF` and control flow;
- arrays and loops;
- LLVM and native codegen.

This document records one historical feature increment: shared integer constants. It is
not full xut support and not compiler self-hosting.
