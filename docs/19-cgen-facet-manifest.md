# 19 — CGEN-FACET-MANIFEST: Frontend-Emitted Symbol Facets for cgen.x

> Status: draft spec (2026-08-27). Panel review 2026-08-27 identified this as the sanctioned
> route for any future DEMO-BYTES or storage work. It replaces cgen.x's ad-hoc text-IR scanning
> with a single source of truth emitted by the Rust frontend.

## 1. Why this exists

`selfhost/cgen.x` (6608 lines) currently reconstructs symbol storage decisions
by scanning `src$` with ~30 global `##`-prefixed string sets (`##dynNames$`,
`##strDual$`, `##gosubDyn$`, ...) and 72 multi-set predicates. Three
consecutive `gosubDyn` attempts regressed demo compilation 114→89 and were
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

- One text-IR header block that makes `cgen.x` byte-identical to the Rust
  CEmitter without heuristic string matching.
- Deterministic, per-symbol, per-scope facts: scope, element type, storage
  class, dual-use, rank, and descriptor forwarding.
- Backward-compatible with existing corpus goldens (the header is additive;
  old `cgen.x` ignores unknown header lines).

**Non-goals**

- Changing the Rust CEmitter's emission logic.
- Optimizing runtime performance.
- MSVC portability of emitted C (tracked separately as `C-BACKEND-PORTABILITY`).

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

- The header is **optional**. If absent, `cgen.x` falls back to the existing
  scanner path (the 114/114 baseline). This keeps old goldens valid.
- The Rust `TextIrEmitter` emits the header when a new flag or version bump is
  present; `TextIrParser` ignores unknown header lines in older builds.
- `fixtures/corpus/v0.1/positive/*.ir` goldens gain the header on next
  regeneration; the change is additive and does not affect interpreter execution.

## 6. Verification

## 9. Implementation progress

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
  still `emit_program` goldens (80/80 byte-identical, `ok` 77s). Next: composite
  member facets (`squareInfo.grid` rank 2) and `byref`/`descriptor`.


- `cgen_cemitter_sync::cemitter_and_cgen_agree_on_positive_corpus` already
  asserts per-program byte-identical emitted C — the header must not break this.
- New: `cgen_x_compiles_all_demos_cc_clean` must stay green.
- Full suite `checks/validate-all.sh` remains the gate (276/0 at `fe67141`).

## 7. Open decisions

- Exact header keyword: `facet` vs `symbol` vs `storage`.
- Whether `byref` needs a separate descriptor-forward set or can be folded into `dual`.
- Minimum header emission: only `dyn`/`dual`/`shared` vs all symbols.

## 8. References

- `crates/xb-compiler/src/c_emit_hoist.rs:1272` `collect_dyn_names`
- `crates/xb-compiler/src/c_emit.rs:961` `is_dyn_array`
- `docs/16-cgen-cemitter-sync-roadmap.md` CG-BYTES
- `docs/17-open-work-roadmap.md` DEMO-BYTES DE-SCOPED, CGEN-FACET-MANIFEST
