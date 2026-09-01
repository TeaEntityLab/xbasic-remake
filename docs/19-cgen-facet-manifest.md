# 19 — CGEN-FACET-MANIFEST: Frontend-Emitted Symbol Facets for cgen.x

> Status: substantially implemented. Scope-qualified lookup
> `dyn`/`dual`/`arr2d` production and lookup are implemented. Remaining
> `strDual`, `allStrArr`, `sharedArrays`, and `xstArrays` inference must move to
> frontend-owned facts before the generator's physical module boundaries are
> finalized.
>
> Historical 2026-08-30 evidence recorded 15/15 core libraries and 114/114
> demos compiling through the facet path. The current active tree has a
> separate 21-demo label-emission regression, so those totals are not a
> current-green claim. This document owns the facet migration regardless of
> transient generator defects.
>
> Single-letter identifier dual-use (`a` vs `align`/`array`, `k` vs `kid`)
> cannot be fixed reliably with substring replacement. Scope-qualified facets,
> not more exclusions, are the accepted mechanism.

## 1. Why this exists

`selfhost/cgen.x` is currently 8,674 lines across 72 functions. It still
reconstructs some symbol-storage decisions by scanning `src$` into global
`##`-prefixed string sets (`##dynNames$`, `##strDual$`, `##gosubDyn$`, ...).
Three consecutive `gosubDyn` attempts regressed demo compilation 114→89 and were
reverted because:

- Scans are program-wide, not per-function scoped, causing cross-function leakage.
- `:name:type:` delimiter strings collide when a variable is named like a type (`integer`).
- `emit_hoists$` and `emit_ubound` rely on 12- and 9-level `IF/ELSEIF` cascades with
  negative exclusions; ordering fixes one demo breaks another.

The Rust frontend already computes all facets correctly in
`crates/xb-compiler/src/c_emit_hoist.rs` (`collect_dyn_names`,
`collect_descriptor_params`, `FN_DYN`, `FN_DUAL_USE`, `is_shared_array`).
Emitting those facts into the Text IR lets `cgen.x` consume them deterministically
instead of re-inferring them.

This document defines the smallest IR extension that unblocks `cgen.x`.

## 2. Goals / Non-goals

**Goals**

- One frontend-owned Text IR facet block that lets both C generators implement
  the same storage and ABI decisions without heuristic string matching.
- Deterministic, per-symbol, per-scope facts: scope, element type, storage
  class, dual-use, rank, descriptor forwarding, and other facts proven
  necessary by behavior.
- A clean cutover: once the named migration gates pass, delete each replaced
  scanner and its fallback rather than keeping two classifiers.
- Preserve the deliberately narrow positive-corpus C-identity diagnostic
  during migration; broader correctness is behavioral and ABI conformance.

**Non-goals**

- Changing the Rust CEmitter's emission logic.
- Optimizing runtime performance.
- MSVC portability of emitted C (tracked separately as `C-BACKEND-PORTABILITY`).
- Choosing physical `cgen.x` fragment boundaries before scanner retirement.
- Adding a general multi-version IR compatibility framework.

## 3. Proposed Text IR extension

Add an optional header block immediately after `version` and before the first
`function` or `dim`:

```
version 0.1
facet user:integer scope=Entry storage=dyn rank=1 dual=0
facet code$:string scope=Greeter storage=dyn rank=1 dual=1
facet grid:integer scope=Main storage=param rank=0
...
function Main() -> integer
```

### 3.1 `facet` line syntax

```
facet <name>:<type> scope=<func|*> storage=<fixed|dyn|param|shared> rank=<n> dual=<0|1> [byref=<0|1>]
```

- `<name>`: raw XBasic name including suffix (`foo$`, `value@`, `PM.pm[]` leaf).
- `<type>`: `integer | float | string | giant | double` (matches `ValueType`).
- `scope`: function name or `*` for module-shared.
- `storage`: frontend's final storage decision (`is_dyn_array` / `is_shared_array` / param).
- `rank`: 0 = scalar, 1 = 1-D, 2 = 2-D, ...
- `dual`: 1 if scalar+array facets must both be emitted (`_arr` split).
- `byref`: 1 if the symbol is ever passed `byref(symbol(...))` to a descriptor param.

A producer may emit facets only for names that need non-default handling; missing
names default to `storage=fixed, rank=0, dual=0`.

### 3.2 Example (aback's `user`)

Current text IR:

```
function Entry() -> integer
  dim user:integer[symbol(upper:integer)]
  gosub Print
```

With header:

```
facet user:integer scope=Entry storage=dyn rank=1 dual=0
```

`cgen.x` then knows `user` is `dyn` without scanning for `gosub`.

## 4. cgen.x consumption (sketch)

- At startup, parse header lines into a small table `##facetTab$` (`:name:scope:type:storage:rank:dual:`)
  instead of populating 18 scanner sets.
- `bd$(n$)` → `dual=1` → `_arr`.
- `emit_hoists$` → table lookup for `storage=dyn` → `pointer + ub` decl.
- `array_access` / `array_assign` / `UBOUND` / `DIM` site → table lookup for storage+rank.
- No `INSTR(src$, "array_ubound(")` scans.

Header parsing is one pass, per-symbol, scope-qualified — no substring collisions.

## 5. Compatibility and migration

- During migration, an absent header may use the existing scanner path so
  historical Text IR inputs remain diagnosable. This fallback is temporary,
  not a second permanent contract.
- Remove a scanner and its fallback together when its complete facet
  replacement passes direct facet tests, raw demo compilation, 15-library
  compilation, the positive-corpus lock, and bootstrap parity.
- The default positive-corpus path remains unchanged until its goldens are
  deliberately regenerated and reviewed.

## 6. Implementation progress

- **2026-08-27:** `crates/xb-compiler/src/text_ir_parser_item.rs` now accepts
  `facet` header lines (`facet <name>:<type> ...`) as `IrItem::Nop` — the Text
  IR extension point is open and backward-compatible (old goldens still parse;
  `cgen.x` ignores the header until it consumes it). Verified:
  `cargo test -p xb-compiler --lib` (19/19) and manual `cgen` with a
  `facet user:integer ...` header still emits C.
- **2026-08-27:** `TextIrEmitter::emit_program_with_facets` now emits a `facet`
  header per array `Dim` (storage `dyn` vs `fixed` by size presence, rank from
  `extra_dims`). `cargo test -p xb-compiler --lib emits_facet_header_with_array_dim`
  verifies the header is emitted and round-trips as `Nop`. Default
  `emit_program` remains unchanged (backward-compatible with goldens).
- **2026-08-27 (slice 2):** `TextIrEmitter::emit_program_with_facets` now uses
  frontend-accurate classification — `collect_dyn_names` (gosub/nested/unsized/
  descriptor), `collect_dual_use`, `collect_descriptor_params` — so `storage`
  (`dyn`/`fixed`/`shared`/`param`), `rank`, and `dual` match the Rust CEmitter
  exactly (verified: `DIM arr[3]` → `fixed`, `DIM user[upper]`+GOSUB → `dyn`,
  `SHARED` → `shared`, array param → `param`, scalar+array → `dual=1`). Rank now
  `1` for unsized 1-D (`DIM a[]`). `selfhost/cgen.x` now parses the header at
  startup into `##facetTab$` (`CHR$(10)`-delimited `facet` bodies) — currently
  stored, not yet consumed (behavior unchanged, 114/114 demos still `cc` via
  `cgen_x_compiles_all_demos_cc_clean` `ok` 14s, positive corpus sync `ok` 62s).
- **2026-08-27 (slice 3):** `selfhost/cgen.x` now *consumes* `##facetTab$` for
  `##dynNames$` — when a `facet` header is present, `##dynNames$` is rebuilt
  from `storage=dyn` facets (`:name:` per dyn) overriding the heuristic
  `scan_dyn$`; empty `##facetTab$` falls back to scanning (114/114 demos still
  `cc`, `cgen_x_compiles_all_demos_cc_clean` `ok` 19s, `aback` with/without
  header diff 0 and `cc` clean).
- **2026-08-27 (slice 4):** `selfhost/cgen.x` now also rebuilds `##dualUse$`,
  `##strDual$`, `##allStrArr$`, `##arr2d$` from facets (`dual=1`, `type=string`,
  `rank>=1/2`) when `##facetTab$` present. Verified parse `ok`, 114/114 demos
  still `cc` (`cgen_x_compiles_all_demos_cc_clean` `ok` 31s), `aback` header
  still diff 0. Fixed `##xstArrays$` missing-line regression (parse `ok`).
- **2026-08-27 (slice 4.1):** Narrowed to `##dynNames$`/`##dualUse$`/`##arr2d$` only
  (`##strDual$`/`##allStrArr$` stay heuristic) to fix `arecurse` `file$` string
  redefinition (`char**` vs `char*`) and keep `Kittedy` composite `TYPE`
  `squareInfo[9,15]` on heuristic (no `Dim` facet for member `grid`).
- **2026-08-27 (slice 5):** `cgen_x_compiles_all_demos_cc_clean` now uses
  `emit_program_with_facets` (114/114 demos `cc` via facet-driven cgen,
  `ok` 41s; `arecurse`/`Kittedy` with facet header `cc` clean). Positive corpus
  still `emit_program` goldens (80/80 byte-identical, `ok` 77s).
- **2026-08-27 (slice 6):** `collect_facets_accurate` now emits member 2D facets
  for composite `TYPE` arrays (`squareInfo.grid:integer[9,15]` etc. via
  `array_access`/`array_assign` with `extra_indices` and `.` in name, rank 2,
  `storage=shared`). `cgen` `arr2d` facet handling re-enabled (`fArr2d` from
  `rank>=2`); `Kittedy` with facet header `cc` clean via `cgen_new` and via
  `cgen_x_compiles_all_demos_cc_clean` (still 114/114).
- **2026-08-27 (slice 7):** `collect_facets_accurate` now marks dual fixed
  arrays as `storage=dyn` (`b[3]`, `c[4,5]`, `d[5,6,7]` `fixed`+`dual1` → `dyn`),
  matching Rust's `dualUse` heap `_arr` path. Previously `b:fixed rank1 dual1`
  emitted `intptr_t b[4]` fixed but accessed `b_arr` → `adatadim` `intptr_t[4]`
  not assignable. Facet now `b:dyn rank1 dual1` → `xb_var_b_arr` heap, `cc` clean.
  `cgen_x_compiles_all_demos_cc_clean` 114/114 via facets (`ok` 13s) and `a`/`b`/`c`/`d`
  facets `dyn`.
- **2026-08-27 (slice 8):** `collect_facets_accurate` now walks `Dim` recursively
  (`Function`/`If`/`While`/`For`/`DoLoop`/`SelectCase`/`Compound`) so nested
  `dim argv$:string[3]` (zap) etc. get facets; previously non-top-level nested
  DIMs were missed and fell back to heuristic. `zap`'s `DIM argv$[3]` sits inside nested `IFZ standalone` THEN+ELSE (DIM twice per path) — `DynWalk` nested + `dim_count==2` ⇒ **`facet argv$:string scope=Entry storage=dyn rank1 dual0`** (not `fixed`; earlier draft said `fixed` — corrected per 2026-08-27 parallel-lens Correctness lens). Keeps
  114/114 via narrow facet (`dyn`/`dual`/`arr2d`). Residual gaps (L14): member 2D facets still hardcode `rank=2` + `storage=shared` (`scope=="*" ? "shared" : "shared"` no-op); array params hardcode `rank=1`; nested `Function` DIMs can leak into parent `dim_info` while `DynWalk` does not walk nested functions; `collect_member_2d_expr` misses `Print`/`For`-bounds/`SelectCase` selector.
- **2026-08-29 follow-up (`ac8ea35`, `54db874`):** narrow Kittedy/qbtoxb `found`/`TranslateStatement` and xui `tool`/`window` repairs preserve the 114/114 harness-assisted demo guard, 61/61 sync, and `IR_IDENTICAL`. The selfhost core-library floor reached **15/15** on 2026-08-30 (`8fe02ce`) — all 15 core libs compile clean via `emit_program_with_facets`. `xui` moved past `tool`/`window`; remaining `a`/`k`/`array` prefix collisions, plus `xin`/`xit`/`xst` scope failures, belong to RR-03 (now done). `xcol`/`xgr` resource failures belong independently to RR-05 (now done). No further whole-body substring masks are admissible.
- **2026-08-29 (fix):** Single-line `IF..THEN..ELSE` in `selfhost/cgen.x` `host_address` hoist parsed differently by `selfhost/compiler.x` vs Rust `FrontendUnit` (ELSE attachment) — `native_pipeline` `native_compiler_emits_cgen_ir_for_cgen` diverged 6 lines. Fixed block-form `IF/ELSE/END IF` in `dedfe25`; `IR_IDENTICAL` restored. `ARCH-02` (`2b0f6ee`) `int main(int argc, char **argv)` stale asserts in `cgen_selfhost.rs:63` and `native_emit.rs:40` also fixed (`b60640a`).
- **2026-08-28 (deferred):** `crates/xb-frontend/src/parser.rs` `DIM #name` → `dim shared` (deec869) correctly marks `DIM #OSERROR$`, `#line[]`, `#token[]` etc. as `storage=shared` (xst 20→1 error) but regresses `qbtoxb` `cgen_x_compiles_all_demos_cc_clean` 60/60→59/60 (`qbtoxb.c:2670 array subscript is not an integer` for `line` in `LoadQBasicProgram`). Root cause: `cgen.x` flattens facets globally (`##dynNames$=":line:"` substring of `":ParseSourceLine:line:"`) and emits `dim shared line` forward-decl as global `intptr_t* xb_var_line` at `1118` that collides with scalar `line` in `LoadQBasicProgram` (`FOR line`). Attempted scope-aware `is_dyn_facet$(nm,sc)` + `is_shared_facet$` with `":scope:name:"` for `dyn`/`dual`/`arr2d`/`shared` (plus `LEN(##facetTab$)=0` heuristic fallback) still left `":line:"` substring match for forward-decl and missed `##curFnName$` wiring for shared. Reverted parser to `aea801b` (`shared` only via `DIM SHARED` keyword) to keep 60/60 and 9/15; `xst` returns to 20 errors. **Deferred:** `CGEN-FACET-SCOPE` must make `##sharedArrays$`/`##dynNames$` truly per-function (no `":name:"` substring fallback when `LEN(##facetTab$)>0`, and forward-decl for `dim shared` must check any-scope via separate helper, not `is_shared_facet$` with `##curFnName$`). Until then `xst` `#OSERROR` fix and `qbtoxb` `#line[]` remain via `scan_shared_arr$` heuristic (global), not facets.

- `cgen_cemitter_sync::cemitter_and_cgen_agree_on_positive_corpus` asserts
  per-program byte-identical emitted C; the header must not break this.
- `cgen_x_compiles_all_demos_cc_clean` is the RR-13 raw-output compile gate;
  the current label-emission regression must be fixed in the generator, not in
  a post-emission rewrite.
- `checks/validate-all.sh` remains the full default-feature gate. The 308/0
  workspace result is a dated historical snapshot; current status lives in
  docs/17.

## 7. Adopted sequencing and open decisions

- The header keyword is adopted as `facet`.
- Define whether composite-array by-ref needs per-leaf descriptor facts or a
  distinct structured descriptor fact.
- Define the minimum comprehensive emission set after scope-qualified lookup:
  only non-default storage facets or every symbol.
- Retire `strDual`, `allStrArr`, `sharedArrays`, and `xstArrays` inference
  before choosing physical generator modules.
- **Scanner retirement precedes physical modularization.** The later mechanism
  (deterministic fragments, native multi-unit support, or retaining one source
  file) is intentionally deferred until the reduced dependency graph is
  measured. No concatenation build step is authorized by this document.

## 8. References

- `crates/xb-compiler/src/c_emit_hoist.rs:1272` `collect_dyn_names`
- `crates/xb-compiler/src/c_emit.rs:961` `is_dyn_array`
- `docs/16-cgen-cemitter-sync-roadmap.md` CG-BYTES
- `docs/17-open-work-roadmap.md` DEMO-BYTES DE-SCOPED, CGEN-FACET-MANIFEST
