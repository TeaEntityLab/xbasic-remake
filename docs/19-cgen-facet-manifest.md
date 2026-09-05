# 19 — CGEN-FACET-MANIFEST: Frontend-Emitted Symbol Facets for cgen.x

> Status: substantially implemented. Scope-qualified lookup
> `dyn`/`dual`/`arr2d` production and lookup are implemented. Remaining
> `strDual`, `allStrArr`, `sharedArrays`, and `xstArrays` inference must move to
> frontend-owned facts before the generator's physical module boundaries are
> finalized.
>
> Historical 2026-08-30 evidence recorded 15/15 core libraries and 114/114
> demos compiling through the facet path (both locked by named cargo tests
> since 2026-08-30). This document owns the facet migration regardless of
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

- **2026-09-02 (unsized-DIM fidelity and retirement measurement):**
  `TextIrEmitter` now retains `[]` for every unsized array DIM instead of
  serializing it indistinguishably from a scalar DIM. cgen.x mirrors the Rust
  storage contract: empty-bracket arrays classify as dynamic, `DIM a[]`
  resets pointer/UBOUND state to empty, indexed writes auto-grow with
  zero-filled intermediate elements, and numeric dyn names no longer suppress
  a same-named string scalar declaration. The named three-engine lock
  `cemitter_and_cgen_agree_on_unsized_array_growth_and_reset` covers UBOUND
  `-1`, growth, zero-fill, and reset. The 234-program
  `facet_header_covers_cgen_scanner_facts_ratchet` now measures:
  `allStrArr` scanner-only/facet-only **0/0** (an exact facet replacement and
  the next safe one-classifier retirement); `strDual` **0/153** scanner-only/
  facet-only *names* across 234 programs (2026-09-05; not equivalent—facet
  `dual=1` is use-based while the scanner is DIM-based; only scanner-only is ratcheted);
  `xstArrays` **unclassified 0/0** under the refined invariant (every Xst
  array has a facet with an owning storage — dyn, shared, or param — in some
  scope; the 4 former `not facet-dyn` names are shared globals / array params
  that never needed dyn membership). No scanner is
  deleted in this measurement slice. Verified 2026-09-02:
  `checks/validate-all.sh` **310/310 across 40 binaries**,
  `checks/verify-bootstrap.sh` `ok` including `cgen_cemitter_sync` **65/65**,
  and the LLVM feature gate **144 passed, 1 documented ignore**.

- **2026-09-02 (allStrArr facet-driven consumption):** cgen.x now parses
  `##facetTab$` for string-array facets (`type=string`, `rank>=1`,
  `storage!=shared`, `storage!=param`, `byref!=1`) and assigns
  `##allStrArr$ = fAllStrArr$` when facets are present. The scanner
  `scan_all_strarr$` is retained as the fallback for headerless producers
  (historical/self-hosted IR without facet headers). Three naming fixes
  accompany the migration: (1) `arr_acc_name$` returns direct `c_var_name$`
  for non-strDual allStrArr members (not the `_arr` dual facet); (2) `ub_ref$`
  returns direct `xb_ub_<name>` for non-strDual allStrArr members; (3) the
  `used$` hoist path gains an `allStrArr+strDual` branch that emits both the
  scalar `char*` facet and the `char** _arr` heap pointer for dual-use string
  arrays in functions that use the name without a local DIM. The scanner-hostile
  three-engine lock `cemitter_and_cgen_agree_on_all_strarr_facet_without_dim_shape`
  proves the facet path works when DIM brackets are hidden from the scanner.
  Verified 2026-09-02: `checks/validate-all.sh` **311/311 across 40 binaries**,
  `checks/verify-bootstrap.sh` `ok` including `cgen_cemitter_sync` **66/66**,
  15/15 core libs, 114/114 demos.

- **2026-09-05 (slice 5: strDual use-based union):** cgen.x unions owned
  string-dual facets (`type=string`, `rank>=1`, `dual=1`, `storage!=shared`,
  `storage!=param`) into `##strDual$` after both scan passes — the pass-2
  rescan near the forward-decl block rebuilds scanner-only sets and would
  otherwise clobber the pass-1 facet values (same for `##dualUse$`/`##arr2d$`;
  only `##allStrArr$` has no pass-2 rescan). Settles the slice-4.1 open
  question: use-based facet dual is the correct semantics (the reference
  emitter splits scalar+`_arr` for use-duals such as arecurse `file$`, which
  has only `DIM file$[]`); DIM-duality is neither necessary nor sufficient
  (param/shared duals such as xit `symbol$[]` must not split caller-owned
  storage — verified once by probe: unguarded union split it, guards fixed
  it). Measured over the 17 programs holding all 153 facet-only names:
  declaration-shape agreement vs the reference emitter 89/153 (baseline) ->
  113/153 (union), 24 fixed, 0 caused divergences; the 25 remaining under
  (param/shared/dotted/descriptor architecture) and 15 pre-existing over
  (`scan_dual_use$`, already use-based) are union-untouched. Locked by
  `cgen_strdual_union::cgen_strdual_facet_union_decl_shape` (ubound `s$`,
  arecurse `file$`, xgrids `list$`). `scan_str_dual$` stays as the headerless
  fallback; deletion still blocked on compiler.x emitting facets. Adjudicated 2026-09-06 (throwaway decl-shape probe, removed after): all 16 sampled under-names are architecturally correct non-splits, not missed splits — 10× shared file-scope globals (`errSymbol$`, `ufont$`, `variableSaved$`, `errorNature$`, `errorObject$`, `exception$`, `fileInfo.fileName`, `export$`, `import$`, `helpText$`; Rust splits locally, cgen.x uses globals), 4× descriptor-forwarded caller-owned cells (`backupList$`, `dir$`, xcol `file$`, `start$`: `storage=dyn ... byref=1`, array-only is correct), 1× dotted member under a different lowering, 1× param; 2 sampled names (`copy.name`, xit `symbol$`) already agree post-union. Per-scope `facets_in_scope$` migration would change no correct output: residual closed as irreducible.

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

## 9. Compiler.x facet emission plan (PROPOSED 2026-09-06 — not reviewed, no code)

Covers the last AC2 blocker (docs/17 CGEN-FACET-RETIREMENT: scanners cannot be
deleted until a non-Rust producer emits facets). Design-only session: no
compiler.x/cgen.x/Rust changes, no gate changes. Target state: `selfhost/
compiler.x` emits complete, accurate facet headers itself, proven by
native-vs-Rust facet-set equality; cgen.x consumes them with zero code
changes (it already scans `facet ` position-independently).

**Decision required (maintainer, before any phase):** docs/20 M1 work package 2
and the M1 exit gate place facet-manifest completion (incl. scanner deletion)
in M1; review guidance places compiler.x expansion in M5 and defers AC2
deletion. This plan is milestone-neutral: phases P1–P6 build and prove emission
(zero behavior change, safe under either milestone); P7 flips emission on;
P8 (scanner deletion, AC2 proper) is explicitly OUT of scope here either way.

### 9.1 Enabling facts (all verified this session, with evidence)

1. **cgen.x needs no changes.** It buffers all of stdin into `src$`
   (`selfhost/cgen.x`, input loop) and collects every `facet ` line anywhere
   in the stream into `##facetTab$` (facet scan loop). Trailing (or
   interleaved) facet emission works unmodified.
2. **Native emission order must be discovery (source) order, never sorted.**
   Rust facet order is nondeterministic across runs (proven 2026-09-06: same
   sorted set `8d41…`, differing raw orders `a0c7…` vs `3b17…` on xcol.x —
   `HashMap` iteration in `collect_facets_accurate`). All comparisons
   therefore normalize (sort facet lines); cgen.x is order-insensitive
   already (`:name:` probes). XBasic has no hash maps; linear scans preserve
   insertion order, which keeps interp-vs-native output byte-exact.
3. **Emission must be complete when on (no partial headers).** cgen.x
   REPLACES `##dynNames$`/`##dualUse$`/`##arr2d$`/`##allStrArr$` from facets
   whenever `##facetTab$` is non-empty (facet block). A partial header (e.g.
   only allStrArr facts) would narrow the other sets catastrophically. This
   clarifies §3.1 ("a producer may emit facets only for names that need
   non-default handling"): sparse is fine, PARTIAL-by-classifier is not —
   every classifier cgen.x consumes must be fully covered. (Follows: phases
   compare per-classifier subsets but only ever SWITCH ON complete emission.)
4. **Only Rust-vs-native comparisons need normalization.** Native-vs-native
   and interp-vs-native stay byte-exact (same program, deterministic order):
   `verify-bootstrap.sh` STAGE1==STAGE2, `bootstrap.rs` stage0==stage1,
   `cgen_selfhost.rs` interp==native output. Normalization is required at
   exactly three spots: `verify-bootstrap.sh` RUST_IR==STAGE1_IR and the
   per-tool loop (both compare against `xb --emit-ir`), and
   `native_pipeline.rs` native-vs-`emit_program`. (`self_rebuild.rs`/
   `cgen_corpus.rs` must be audited in P7 for Rust-parse paths over native IR.)
5. **Rust `TextIrParser` needs a `facet ` skip rule** wherever native-faceted
   IR may flow into Rust parsing (one-line pre-pass + test; it currently has
   zero facet handling and would fail on header lines).
6. **Spec §3.1 is stale** and must be updated in P1: it omits fields Rust
   actually emits and cgen.x consumes — trailing `shared` flag,
   `descriptor=1`, `position=N`, and the `byref=1` gating semantics. Field
   inventory (producer analysis → cgen.x consumers):
   `name:type` (identity everywhere); `scope=` (per-function filtering,
   RR-03); `storage=dyn` (##dynNames$ rebuild); `dual=1` (##dualUse$ rebuild);
   `rank>=2` (##arr2d$ rebuild); `string`+`rank>=1`+absent shared/param/byref
   (##allStrArr$ rebuild); `storage=shared`+rank (##sharedArrays$ union);
   string+rank+`dual=1` (##strDual$ union, slice 5); `storage=param`+rank+scope
   +`position=` (##arrayPositions$, param decls); `descriptor=1`+`position=`
   (##descParams$/Positions/Ranks); `byref=1` (##curDescLocals$ exclusion).
7. **No composite-TYPE parsing is required in compiler.x.** Text IR carries
   flattened member DIMs (`dim p.x:integer[1]`) and accesses; member facts
   (incl. the rank-2 member special case) derive from those, exactly as
   `collect_member_2d` does on the Rust side. compiler.x has no `TYPE`
   handling today (verified: zero matches) and needs none for facets.
8. **Facts are available in compiler.x's existing flow.** It buffers all
   source lines, lexes to token tables (`tt$`/`tv$`, 131072 slots), tracks
   function nesting (`funcName$` stack) and parses typed params (`pname:vt`
   pairs at function emission). DIMs, calls (callee + arg shapes), `GOSUB`,
   and scopes all flow past the parse-emit pass — accumulation is new
   tables, not new parsing.

### 9.2 Accumulation architecture (constraints, not code)

- New `##`-style globals (XBasic convention) + append-only table updates
  during the existing parse-emit pass. READ-ONLY wrt emit state: accumulation
  must never mutate what's printed (normal-path output stays byte-identical
  through P1–P6; enforced by gates running green throughout).
- Per-function tables reset at each `function ` line; program tables (call
  graph edges, shared names) accumulate monotonically.
- Budgets: tables are small delimited strings (facets for xst ≈ tens of KB;
  bounded by symbol count, not source size). No sorting anywhere (discovery
  order = determinism). No new per-statement scans over the whole source
  inside hot paths (amortized appends only; the descriptor fixpoint in P5
  iterates tables, not source).
- Port from Rust ANALYSIS SEMANTICS (`text_ir.rs` collection fns +
  `c_emit_hoist.rs` classifiers), not by transliterating AST walks: operate
  on XBasic text facts with cgen.x-scanner idioms (bounded `INSTR`/`MID$`
  loops). Independent implementation + set-equality gates = true differential
  (shared bug-for-bug inheritance would defeat the purpose). Cite exact Rust
  sources per analysis in each phase.

### 9.3 Analysis port catalog (calibration)

- Trivial (one XBasic scan each, straight from emit-time facts): array DIMs
  with rank/scope/type (`collect_array_dimmed_names`, hoist:916);
  `has_gosub` (hoist:1545); params with array-ness/position (parse-time);
  shared (`dim shared`); member-2D access shapes (`collect_member_2d`,
  text_ir:408 + `walk_expr_2d`:479).
- Medium: dual-use (`collect_dual_use`, hoist:1002 + `walk_expr` divert rules
  incl. byref-divert, UBOUND-string notes, SWAP arms, array-DIM-as-context):
  needs nested-block use classification over buffered function bodies.
  dyn storage (`collect_dyn_names`, hoist:1564: DIM counts, late detection,
  nested/unsized/GOSUB/descriptor forces + dual injection): needs per-function
  DIM-order records. DIM info incl. composite flattening
  (`collect_dims_recursive`, text_ir:328).
- Hard (long pole, may split): descriptors (`collect_descriptor_params`,
  hoist:1809: whole-program call graph, seeding (DIM/REDIM vs bare UBOUND),
  propagation fixpoint, byref/descriptor locals + types). Pure table
  fixpoint post-parse (no source re-scan); unbounded iterations must carry a
  proven bound (edges shrink monotonically — state the invariant in review).

### 9.4 Dump hook (phase-gate visibility without output change)

compiler.x: if the first input line is exactly `##FACETS##`, skip normal
emission and print ONLY computed facet lines (trailing position), then stop.
Zero impact on every existing path (all gates feed real sources; the hook
fires solely for the new facet test's synthetic inputs). Test
(`native_facet_gap`, new file): build native compA per existing harness,
feed corpus programs (selfhost tools + positive corpus + selected libs/demos
— start small, expand per phase), run with hook, parse facet sets, compare
against Rust-computed sets per classifier with per-phase allowlists that only
shrink. Corpus programs must all be inside compiler.x's language coverage
(it compiles cgen.x + selfhost tools today; goldens stay headerless —
CG-BYTES untouched).

### 9.5 Phases (each: scope, gate, rollback = delete code, output unchanged)

- P1 — Scaffold + schema: tables, dump hook, `native_facet_gap` harness,
  §3.1 spec update, DIM/rank/scope/params/shared/member emission +
  allStrArr-field equality. (S)
- P2 — Dual: use-walk + divert rules → `dual=` equality. (M)
- P3 — Dyn: DIM-order/counts + force rules → `storage=` equality. (M)
- P4 — Descriptors/positions/byref: call-graph fixpoint → remaining-field
  equality. (L; split allowed)
- P5 — Member-2D + full-set equality over the expanded corpus; behavior
  parity of cgen.x on native-faceted IR (named matrix: arrays, descriptors,
  composites, duals). (M)
- P6 — Flip: print trailing facets in normal emission (one gate) +
  §9.4-normalization of the three Rust-vs-native spots + parser skip rule
  + full gates. (M; revert = unflip)
- P7 — OUT OF SCOPE HERE (scanner deletion = AC2 proper, separate decision).

### 9.6 Risks

- Triple-implementation window (P1–P6: Rust analysis, cgen.x scanners,
  compiler.x tables): honest debt with a payoff date (P5 proof, P7 flip);
  mitigated by read-only accumulation (normal path provably untouched —
  gates green every phase).
- Descriptor fixpoint divergence (the long pole): mitigated by seeding-rule
  unit probes before the fixpoint, and by P4's field gate preceding any flip.
- Silent-miscompile class (wrong facet → wrong storage, no error): mitigated
  by exact-set equality (not sampling) over a growing corpus + behavior
  parity in P5; never by reasoning alone.
- XBasic performance: native compiler runs hot paths in gates (bootstrap
  builds); per-phase wall-clock comparison against baseline required if any
  phase adds >10% to `native_compiler_emits_cgen_ir_for_cgen`.
- Over-scoping into cgen.x changes: FORBIDDEN in P1–P6 (consumer already
  correct); any cgen.x touch restarts its own gate proof.

### 9.7 Open questions (maintainer)

1. Milestone: M1-track (docs/20 work package 2 + exit gate) or M5-track
   (compiler.x expansion guidance)? P1–P6 are safe under either; P7/flip
   timing follows the answer.
2. If AC2 deletion stays deferred regardless: is P1–P6 emission+proof work
   worth doing for evidence/optionality, or parked until M5?
3. Corpus for P1: selfhost tools + positive corpus sufficient to start, or
   include libs/demos from day one (slower gates, wider net)?
