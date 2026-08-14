# Stage-2 Contract v0.3: Shared System Variable Increment

> Status: Freezes the implemented `##` shared system variable feature of the Rust
> workspace as of 2026-08-14. This is one historical feature increment on top of the
> frozen v0.1 and v0.2 contracts. It does not reopen them and does not claim full xut,
> conditional compilation, or compiler self-hosting.

## 1. Scope

This contract adds exactly one feature to the accepted subset: shared system variables
written with the `##` prefix, as used historically by the XBasic 6.2.3 compiler, IDE, and
runtime sources. Everything else in v0.1 and v0.2 remains in force.

v0.2 §4 recorded that `##Name` tokenized as its own token kind but had no parser or
semantic support. This contract supersedes that status: `##` now has parser, semantic,
IR, and runtime support as a mutable typed variable.

## 2. Historical authority

The `##` shared-variable syntax and its pairing with `$$` constants are taken directly
from the XBasic 6.2.3 source tree:

- `src/shared/xut.x:28` declares `EXPORT XBSystem` and documents its legal values as
  `$$XBSysLinux` and `$$XBSysWin32`.
- `src/linux/xrun.x:79` assigns `##XBSystem = $$XBSysLinux` inside the `XxxXit` entry
  function; `src/win32/xrun.x:66` assigns `##XBSystem = $$XBSysWin32`.
- `src/linux/xit.x:719` and `src/win32/xit.x:933` perform the same assignment in the IDE
  entry path.
- `src/shared/xutpde.x:62` reads and writes the string-typed `##XBDir$` and compares
  `##XBSystem` against a `$$` constant.
- `src/linux/xst.x:1414` reads `##XBSystem` in a `SELECT CASE`.

These anchors are the authority for the form: a `##`-prefixed name with an optional type
suffix, assigned inside function bodies and read as an ordinary expression.

## 3. Accepted syntax

The lexer produces one token for `##Name` plus an optional trailing type suffix, so
`##XBDir$` is a single string-typed shared name whose bare name is `XBDir`. This mirrors
how the lexer already handles suffixed identifiers.

The parser accepts:

```
##Name = <expression>
```

Rules:

- The assignment must appear inside a `FUNCTION` body. A top-level `##Name = ...` line is
  rejected. This is the mirror image of the `$$` rule rather than a contradiction of it:
  each form is accepted only where the historical sources actually place it. Every `##`
  assignment surveyed in §2 sits inside a function, and every `$$` definition sits outside
  one. The parser itself stays scope-free and accepts both placements; placement is
  enforced by the analyzer, exactly as `XB-S006` enforces it for `$$`.
- The right-hand side is any expression the subset already accepts, including `$$`
  constants, so the historical `##XBSystem = $$XBSysLinux` form is accepted verbatim.
- References to an assigned shared variable are accepted wherever an expression is
  accepted, for example `PRINT ##XBSystem` or `Mode% = ##XBSystem`.
- A bare `##Name` line with no `=` is a parse error, exactly as a bare identifier is.

## 4. Semantics

- Shared variables occupy a third namespace, separate from both variables and constants.
  `DIM Value`, `$$Value = 1`, and `##Value = 2` coexist, and each reference form resolves
  to its own namespace.
- The first assignment declares the variable. Its type is taken from the type suffix, so
  `##XBDir$` is a string and `##XBSystem` is an integer. There is no separate declaration
  form in this increment; `EXPORT` remains unimplemented.
- Later assignments must agree with the declared type, and references must carry a
  suffix that agrees with it. Disagreement is the existing `XB-S003` type mismatch, where
  `expected` is the type requested at the reference or assignment site and `actual` is the
  declared type.
- A reference before any assignment is an error. As with constants, a function body sees
  only the shared variables assigned before that function.
- Assignments inside a function body persist after the function. A shared variable first
  assigned inside an earlier function resolves in later top-level statements and in later
  functions. Local `DIM` symbols remain function-scoped and are unaffected.

## 5. Diagnostics

Two new analyzer diagnostics join the source diagnostic corpus, bringing it to eleven:

| ID | Error | Trigger |
|---|---|---|
| XB-S007 | UnknownSharedVariable | a reference to a shared variable never assigned |
| XB-S008 | SharedAssignmentNotInFunction | a `##Name = ...` line outside a function body |

The negative fixtures `semantic_unknown_shared_variable` and
`semantic_top_level_shared_assignment` cover them. Type disagreements reuse `XB-S003`
rather than adding a code.

## 6. Checked IR and text IR

The analyzer records the bare name and the resolved type in both the assignment target
and the reference. The IR keeps the same shape:
`IrItem::SharedAssignment { target, value }` and `IrExprKind::SharedVariable(symbol)`.
The value expression is carried through unchanged; no folding happens at analysis time.

`TextIrEmitter` renders the two forms exactly:

```text
shared ##XBSystem:integer = integer(1)
print shared(##XBSystem:integer)
```

The `##` prefix is part of the emitted text, so the three namespaces stay distinguishable
in the IR: `name:type` for variables, `$$name:type` for constants, `##name:type` for
shared variables.

## 7. Runtime behavior

In `Interpreter::execute` and `Interpreter::execute_main`:

- shared variables live in their own slot map, separate from `DIM` slots, so a `DIM Value`
  slot and a `##Value` slot coexist with independent values;
- the first assignment creates the slot and later assignments mutate it, so no
  duplicate-slot error can arise from a reassignment;
- a reference reads the current value and renders it like any value of that type;
- `ExecutionState::shared_slot` exposes the shared slot for inspection, alongside the
  existing `slot` accessor.

The tests `mutates_shared_slot_across_reassignment` and
`keeps_shared_slot_separate_from_the_dimmed_variable_of_the_same_name` prove mutation and
namespace separation respectively.

Because §3 confines assignments to function bodies, `execute_main` is the path that runs
them in a well-formed program: `execute` alone never enters a function body, so a shared
reference it evaluates resolves only if the slot already exists.

## 8. Selfhost manifest

`selfhost/xut_bootstrap_manifest.x` now performs the historical
`##XBSystem = $$XBSysLinux` assignment inside `FUNCTION Main`, matching where
`src/linux/xrun.x:79` performs it, and prints the result. The committed goldens under
`fixtures/corpus/v0.1/selfhost/` show the `shared ##XBSystem:integer = constant(...)`
assignment and the `shared(##XBSystem:integer)` reference in the IR. The interpreter
output grows from four lines to five:

```text
xut
0.0001
1
2
1
```

The trailing `1` is the Linux system ID read back through the shared variable rather than
through the constant.

## 9. Compatibility with v0.1 and v0.2

`docs/stage2-contract-v0.1.md` and `docs/stage2-contract-v0.2.md` remain frozen records of
their increments and are not amended by this document, with the single exception noted in
§1: the v0.2 §4 statement that `##` is lex-only is superseded here. The corpus harness path
is unchanged: fixtures live under `fixtures/corpus/v0.1`, the live selfhost source is
`selfhost/xut_bootstrap_manifest.x`, and the harness is
`crates/xb-runtime/tests/corpus.rs`.

## 10. Deferrals and non-goals

Historically `##XBSystem` is both a runtime variable and a compile-time switch: the
compiler folds `IF ##CONST THEN ... ELSE ... END IF` and `SELECT CASE ##CONST` and
eliminates the dead branch, which is how the tree achieves conditional compilation without
a preprocessor. **This increment implements only the runtime-variable half.** No folding,
no branch elimination, and no compile-time evaluation of `##` names happens.

Also explicitly outside this contract:

- `EXPORT`, `IMPORT`, `PROGRAM`, and `DECLARE`, and therefore cross-module linkage of
  shared names;
- the fixed shared-variable addresses declared in `xlib.s`;
- float-typed shared variables beyond what the existing suffix rules already imply;
- `IF` and control flow of any kind;
- function calls and returns;
- arrays and loops;
- LLVM and native codegen.

This document records one historical feature increment: shared system variables as
mutable typed runtime storage. It is not conditional compilation and not compiler
self-hosting.
