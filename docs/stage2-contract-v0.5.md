# Stage-2 Contract v0.5: Comparison Operators

> Status: Freezes the implemented comparison operator feature of the Rust
> workspace as of 2026-08-14. This is one historical feature increment on top of
> the frozen v0.1, v0.2, v0.3, and v0.4 contracts. It does not reopen them and
> does not claim full xut, logical operators, or compiler self-hosting.

## 1. Scope

This contract adds exactly one feature to the accepted subset: comparison
operators (`=`, `<>`, `<`, `>`, `<=`, `>=`) as expression-level binary operators
that produce an `Integer` result (XLONG TRUE/FALSE), as used historically by the
XBasic 6.2.3 compiler, IDE, and runtime sources. Everything else in v0.1, v0.2,
v0.3, and v0.4 remains in force.

v0.4 §10 listed comparison operators as a deferral. This contract supersedes
that deferral: comparison operators now have parser, semantic, IR, and runtime
support as binary expressions returning `Integer`.

## 2. Historical authority

The comparison operators and their semantics are taken directly from the
XBasic 6.2.3 source tree and the shipped operator table (`help/operator.hlp`):

- `src/shared/xut.x` uses `IF ##XBSystem = $$XBSysLinux THEN` to conditionally
  select platform-specific paths — a comparison of a shared variable against a
  constant.
- `src/shared/xutpde.x` compares `##XBSystem` against `$$` constants and uses
  string comparisons for path matching.
- The operator table documents `=` / `==` (equal), `<>` / `!=` (not equal),
  `<` (less), `<=` (less-or-equal), `>` (greater), `>=` (greater-or-equal) as
  comparison operators operating on numbers and strings, with results always
  XLONG TRUE/FALSE.
- The precedence table places equality (`=`, `<>`) at level 4 and ordering
  (`<`, `>`, `<=`, `>=`) at level 5.

These anchors are the authority for the form: `<expression> <op> <expression>`,
where both operands must have the same type and the result is `Integer` (1 for
true, 0 for false).

## 3. Accepted syntax

The parser accepts comparison operators between any two primary expressions:

```
<expression> = <expression>
<expression> <> <expression>
<expression> < <expression>
<expression> > <expression>
<expression> <= <expression>
<expression> >= <expression>
```

Rules:

- A comparison expression may appear anywhere an expression is accepted: `PRINT`
  arguments, assignment right-hand sides, `IF` conditions, and shared variable
  assignments.
- The comparison binds looser than primary expressions (literals, identifiers,
  constants, shared variables) and tighter than statement-level constructs. The
  parser parses `left primary`, then checks for a comparison operator, then
  parses `right primary`.
- Only one comparison operator per expression is accepted. Chained comparisons
  like `1 < 2 < 3` are not supported in this increment.
- The lexer already tokenized `<`, `>`, `<=`, `>=`, `<>` as distinct token kinds
  since v0.1. The `=` symbol is shared with assignment but is recognized as a
  comparison operator when it appears in expression context (after a primary
  expression).

## 4. Semantics

- Both operands are analyzed recursively. They must resolve to the same
  `ValueType`. A type mismatch (e.g., comparing an `Integer` to a `Float`) is a
  semantic error (see §5).
- The result type is always `ValueType::Integer`. The value is 1 (TRUE) when the
  comparison holds and 0 (FALSE) when it does not, matching the XBasic XLONG
  convention.
- All three value types support all six comparison operators:
  - `Integer` comparisons use signed 32-bit ordering.
  - `Float` comparisons use IEEE 754 double-precision ordering. NaN comparisons
    return FALSE for all operators (matching `partial_cmp` fallback to `Equal`).
  - `String` comparisons use lexicographic byte ordering.
- Constants and shared variables referenced in comparisons follow the same
  resolution rules as elsewhere.

## 5. Diagnostics

One new analyzer diagnostic joins the source diagnostic corpus, bringing it to
fourteen:

| ID | Error | Trigger |
|---|---|---|
| XB-S010 | ComparisonTypeMismatch | the left and right operands of a comparison resolve to different `ValueType`s |

The negative fixture `semantic_comparison_type_mismatch` covers it. Comparing
an `Integer` variable to a `Float` literal triggers `XB-S010`.

## 6. Checked IR and text IR

The analyzer records the operator and both operands in `CheckedExprKind::Comparison
{ op, left, right }`. The result type is always `ValueType::Integer`.

The IR keeps the same shape: `IrExprKind::Comparison { op, left, right }`, where
`op` is a `ComparisonOp` enum and the operands are `Box<IrExpr>`.

`TextIrEmitter` renders the comparison as:

```text
compare(integer(1) = integer(1))
```

With a shared variable and constant:

```text
compare(shared(##XBSystem:integer) = constant($$XBSysLinux:integer = integer(1)))
```

## 7. Runtime behavior

In `Interpreter::evaluate`, the `Comparison` arm:

- Evaluates both operands recursively via `evaluate`.
- Delegates to `compare()` in `crate::compare`, which:
  - Matches the operand `RuntimeValue` variants (`Integer`/`Integer`,
    `Float`/`Float`, `String`/`String`).
  - Computes `std::cmp::Ordering` via `cmp` (integers, strings) or
    `partial_cmp` with `Equal` fallback (floats).
  - Maps the ordering to a boolean using the `ComparisonOp`:
    `Equal` → `is_eq`, `NotEqual` → `!is_eq`, `Less` → `is_lt`,
    `Greater` → `is_gt`, `LessEqual` → `!is_gt`, `GreaterEqual` → `!is_lt`.
  - Returns `Integer(1)` for true, `Integer(0)` for false.
- Mismatched operand types (e.g., `Integer` vs `Float`) produce a runtime
  `TypeMismatch` error, though the semantic analyzer catches these before
  runtime.

The test `executes_comparison_branches` proves true-branch and false-branch
selection with `=` and `<>` operators respectively.

## 8. Selfhost manifest

`selfhost/xut_bootstrap_manifest.x` now performs an
`IF ##XBSystem = $$XBSysLinux THEN` block inside `FUNCTION Main`, printing
`"match"` when the shared variable equals the constant. The committed goldens
under `fixtures/corpus/v0.1/selfhost/` show the
`if compare(shared(...) = constant(...))` block in the IR. The interpreter
output grows from six lines to seven:

```text
xut
0.0001
1
2
1
linux
match
```

The trailing `match` is printed by the comparison's true branch, demonstrating
that `##XBSystem` (value 1) equals `$$XBSysLinux` (value 1).

## 9. Compatibility with v0.1 through v0.4

`docs/stage2-contract-v0.1.md` through `docs/stage2-contract-v0.4.md` remain
frozen records of their increments and are not amended by this document, with
the single exception noted in §1: the v0.4 §10 deferral of comparison operators
is superseded here. The corpus harness path is unchanged: fixtures live under
`fixtures/corpus/v0.1`, the live selfhost source is
`selfhost/xut_bootstrap_manifest.x`, and the harness is
`crates/xb-runtime/tests/corpus.rs`.

## 10. Deferrals and non-goals

Historically XBasic comparison operators participate in chained expressions with
arithmetic and logical operators. **This increment implements only bare
comparison between two primary expressions.** No arithmetic operators, logical
operators, or operator chaining are added. A program that needs
`IF (a > 0) AND (b > 0) THEN` must compute each comparison into a variable and
test the variables with nested `IF` blocks.

Also explicitly outside this contract:

- arithmetic operators (`+`, `-`, `*`, `/`, `\`, `MOD`, `**`);
- logical operators (`AND`, `OR`, `NOT`, `XOR`, `!!`, `!`, `&&`, `^^`, `||`);
- bitwise operators (`~`, `&`, `^`, `|`, `<<`, `>>`, `<<<`, `>>>`);
- chained comparisons (`1 < 2 < 3`);
- operator precedence parsing (only one operator per expression);
- `ELSE IF` / `ELSEIF` chaining (use nested `IF` blocks instead);
- single-line `IF ... THEN <stmt>` without `END IF`;
- `SELECT CASE` and other control-flow constructs;
- function calls and returns;
- arrays and loops (`DO`/`LOOP`, `FOR`/`NEXT`, `WHILE`/`WEND`);
- LLVM and native codegen.

This document records one historical feature increment: comparison operators as
expression-level binary operators returning `Integer` TRUE/FALSE. It is not
arithmetic evaluation and not compiler self-hosting.
