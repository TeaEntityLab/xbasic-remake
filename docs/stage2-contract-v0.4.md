# Stage-2 Contract v0.4: IF/THEN/ELSE/END IF Control Flow

> Status: Freezes the implemented `IF`/`THEN`/`ELSE`/`END IF` control-flow feature of the
> Rust workspace as of 2026-08-14. This is one historical feature increment on top of the
> frozen v0.1, v0.2, and v0.3 contracts. It does not reopen them and does not claim full
> xut, comparison operators, or compiler self-hosting.

## 1. Scope

This contract adds exactly one feature to the accepted subset: conditional branching with
`IF`/`THEN`/`ELSE`/`END IF`, as used historically by the XBasic 6.2.3 compiler, IDE, and
runtime sources. Everything else in v0.1, v0.2, and v0.3 remains in force.

v0.3 §10 listed `IF` and control flow of any kind as a deferral. This contract supersedes
that deferral: `IF`/`THEN`/`ELSE`/`END IF` now has parser, semantic, IR, and runtime
support as a conditional branch on an integer-valued expression.

## 2. Historical authority

The `IF`/`THEN`/`ELSE`/`END IF` syntax is taken directly from the XBasic 6.2.3 source tree:

- `src/shared/xut.x` uses `IF ##XBSystem = $$XBSysLinux THEN` to conditionally select
  platform-specific paths.
- `src/linux/xrun.x` and `src/win32/xrun.x` use `IF`/`ELSE`/`END IF` blocks to branch on
  the system variable and select initialization code.
- `src/shared/xutpde.x` uses `IF` to guard editor operations and `ELSE` to provide
  fallback paths.
- The XBasic language reference describes `IF` as requiring an integer condition where
  nonzero is true and zero is false, matching the XLONG `TRUE`/`FALSE` convention.

These anchors are the authority for the form: `IF <expression> THEN <body> [ELSE <body>]
END IF`, where the expression is evaluated as an integer.

## 3. Accepted syntax

The parser accepts:

```
IF <expression> THEN
  <statements>
[ELSE
  <statements>]
END IF
```

Rules:

- The `IF` statement may appear inside a `FUNCTION` body or at top level, exactly as
  `PRINT` and `DIM` can.
- The condition is any expression the subset already accepts: integer literals, float
  literals, string literals, symbol references, constant references, and shared variable
  references. The analyzer enforces that the condition is `Integer` type (see §5).
- `THEN` is required after the condition. The keyword `THEN` terminates the condition
  expression.
- `ELSE` is optional. When present, it introduces the false-branch body.
- `END IF` is required to close the block. The two keywords `END` and `IF` must both
  appear, matching the historical syntax.
- The statement bodies are sequences of zero or more statements accepted by the subset,
  including nested `IF` blocks.

## 4. Semantics

- `IF` blocks do not create a new scope. Variables `DIM`med inside an `IF` block are
  visible after the `END IF` in the same function or top-level scope, matching XBasic
  semantics. The analyzer processes `IF` bodies in the same scope as the enclosing
  context.
- The condition expression is analyzed for type correctness. It must resolve to
  `ValueType::Integer`. A float or string condition is a semantic error (see §5).
- Both the `then_body` and `else_body` (if present) are analyzed recursively. Each
  statement inside the body is subject to the same rules as if it appeared outside the
  `IF`.
- Constants and shared variables referenced in the condition follow the same resolution
  rules as elsewhere: a `$$` constant must be defined before the `IF`, and a `##` shared
  variable must be assigned before the `IF` in execution order.

## 5. Diagnostics

One new analyzer diagnostic joins the source diagnostic corpus, bringing it to twelve:

| ID | Error | Trigger |
|---|---|---|
| XB-S009 | IfConditionNotInteger | the `IF` condition expression does not resolve to `Integer` |

The negative fixture `semantic_if_condition_not_integer` covers it. A float-typed
condition such as `IF 1.5 THEN` triggers `XB-S009`. A string-typed condition such as
`IF "x" THEN` also triggers it.

## 6. Checked IR and text IR

The analyzer records the condition expression and both bodies in `CheckedItem::If
{ condition, then_body, else_body }`. The condition and body statements are carried
through unchanged; no folding happens at analysis time.

The IR keeps the same shape: `IrItem::If { condition, then_body, else_body }`, where
`condition` is an `IrExpr` and the bodies are `Vec<IrItem>`.

`TextIrEmitter` renders the block with one level of indentation per nesting depth:

```text
  if integer(1)
    print string("branch")
  end if
```

With an `ELSE`:

```text
  if integer(0)
    print integer(1)
  else
    print integer(0)
  end if
```

## 7. Runtime behavior

In `Interpreter::execute_items`:

- The condition expression is evaluated via `evaluate`. The result must be
  `RuntimeValue::Integer(n)`.
- If `n != 0` (nonzero = true, matching XBasic XLONG `TRUE`), the `then_body` items are
  executed by a recursive call to `execute_items`.
- If `n == 0` and an `else_body` is present, the `else_body` items are executed.
- If `n == 0` and no `else_body` is present, execution continues after the `END IF`
  without entering either body.
- Because `IF` blocks share the enclosing scope, variables `DIM`med inside a taken branch
  persist in the same `ExecutionState::slots` map after the block exits.

The tests `executes_if_then_when_condition_is_true` and
`executes_if_else_when_condition_is_false` prove true-branch and false-branch selection
respectively.

## 8. Selfhost manifest

`selfhost/xut_bootstrap_manifest.x` now performs an `IF $$XBSysLinux THEN` block inside
`FUNCTION Main`, printing `"linux"` when the condition is true. The committed goldens
under `fixtures/corpus/v0.1/selfhost/` show the `if constant(...)` block in the IR. The
interpreter output grows from five lines to six:

```text
xut
0.0001
1
2
1
linux
```

The trailing `linux` is printed by the `IF` block's true branch, demonstrating that the
condition (the `$$XBSysLinux` constant, value 1) is nonzero and the branch is taken.

## 9. Compatibility with v0.1, v0.2, and v0.3

`docs/stage2-contract-v0.1.md`, `docs/stage2-contract-v0.2.md`, and
`docs/stage2-contract-v0.3.md` remain frozen records of their increments and are not
amended by this document, with the single exception noted in §1: the v0.3 §10 deferral of
`IF` and control flow is superseded here. The corpus harness path is unchanged: fixtures
live under `fixtures/corpus/v0.1`, the live selfhost source is
`selfhost/xut_bootstrap_manifest.x`, and the harness is
`crates/xb-runtime/tests/corpus.rs`.

## 10. Deferrals and non-goals

Historically `IF` conditions often use comparison operators (`=`, `<>`, `<`, `>`, `<=`,
`>=`) and logical operators (`AND`, `OR`, `NOT`). **This increment implements only bare
expression conditions.** No comparison or logical operators are added; the condition is
any existing expression evaluated as an integer (nonzero = true). A program that needs a
comparison must compute the integer result into a variable and test that variable, or use
a constant or shared variable that already holds the desired integer.

Also explicitly outside this contract:

- comparison operators (`=`, `<>`, `<`, `>`, `<=`, `>=`) as expression-level operators;
- logical operators (`AND`, `OR`, `NOT`, `XOR`);
- `ELSE IF` / `ELSEIF` chaining (use nested `IF` blocks instead);
- single-line `IF ... THEN <stmt>` without `END IF`;
- `SELECT CASE` and other control-flow constructs;
- compile-time branch folding and conditional compilation (the `IF ##CONST` form runs at
  runtime only, not at compile time);
- function calls and returns;
- arrays and loops (`DO`/`LOOP`, `FOR`/`NEXT`, `WHILE`/`WEND`);
- LLVM and native codegen.

This document records one historical feature increment: `IF`/`THEN`/`ELSE`/`END IF` as
runtime conditional branching on an integer-valued expression. It is not conditional
compilation and not compiler self-hosting.
