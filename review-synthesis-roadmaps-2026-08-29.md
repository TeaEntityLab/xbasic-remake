# Panel Synthesis — All Roadmaps — 2026-08-29

**Packet:** `review-packet-roadmaps-2026-08-29.md` (repo root + /tmp) at commit `54db874` (found `tool`/`window` with `windowInfo`/`window_s`/`tool$` + `ac8ea35` Kittedy/qbtoxb `found`/`Translate` + `fd78073` ARY) — 7 lenses recovered via tier-1 DM-wake (scout schema-coerced).

## Panel Consensus
- **Decision:** **AGREE WITH CHANGES** (7/7 unanimous: Architecture, Reproducibility, Strategic, Evidence, CodeCorrectness, Provenance, Usability — all `AGREE WITH CHANGES`, 0 `AGREE`, 0 `DISAGREE`)
- **Use-case recommendation:** `study` + `reproduce` now; `adopt` for demo/compiler work after RR-03/RR-13 wording + harness cleanup; `deploy` for `xui`/`xcol` etc. blocked until RR-03 (13/15) + RR-05 (15/15) + RR-06 `ATTACH` + RR-09 capability gates + RR-10/11 licensing/harness hardening. Do not claim 15/15 link or 114/114 raw as production-ready.

## Required Wording Changes (mandatory, 7 lenses)

### L16 (cgen ↔ CEmitter Sync) — CG-BYTES / CG-BODY-COVER / helper signatures
- **CG-BYTES demo text identity de-scoped:** Keep `80/80` positive-corpus byte-identical as locked contract; demo text identity is explicitly de-scoped, `80/80` + helper signatures + behavioral parity are the contracts. Add note: `cgen.x` streams via `PRINT` without whole-file `cOut$` buffering — dual-use resolution via `fullBody$`/`mainBody$` + `fwdDeclsBuf$`, not `cOut$`. Prohibit post-emission C text `replace$` on `fullBody$` as interim scaffold — future `_arr` vs scalar must be at `c_var_name$`/`arr_acc_name$` via facet tables.
- **CG-BODY-COVER:** Computed GOTO + AT-write lvalue closed; AT-deref reads + file-mode-2 remain low-priority (documented).

### L17 (Open-Work) — Banner + §0 Queue + L15
- **Banner:** `114/114` via `cgen_x_compiles_all_demos_cc_clean` is harness-assisted (retains `found`/`TranslateStatement` `replace$` rewrites); raw `cgen.x` 114/114 verified in standalone `tmp_check3`/`raw_demo_verify` (`PASS 114 FAIL 0` with `-O0 -Wno-int-conversion -Wno-incompatible-pointer-types`), not yet locked in CI. Change to: `The all-demo guard reports **114/114**; raw cgen.x output compiles 114/114 clean in standalone verification, while CI retains transitional post-emission rewrites scheduled for removal under RR-13.`
- **RR-03 + RR-13 now:** Change `| now | **RR-03 scoped facets** and **RR-13 raw demo guard** | scope/name/type collision fixtures; remove Kittedy/qbtoxb post-emit rewrites; raw demos 114/114; sync/bootstrap unchanged |` → `| now | **RR-13 raw demo guard & RR-03 scoped facets** | Strip test-local harness rewrites in cgen_x_compiles_all_demos_cc_clean (raw 114/114 already verified); implement scope-qualified facet lookup (scope+name+type) to advance selfhost core libs 9/15 → 13/15 |` and note: **RR-03 prerequisite before extending `strDual`/`allStrArr` or single-letter `a`/`k` (global `:name:` sets strip `scope=Func` and cause `line` in `qbtoxb` collisions).**
- **Heuristic falsifiability clause (insert after §0 line 163):** `> **Heuristic Patch Falsifiability Clause:** Any candidate regex/substring patch in selfhost/cgen.x (e.g. single-letter dual-use fixes for a/k/array) must pass four gates: (1) zero demo/corpus/lib regressions, (2) bit-for-bit IR_IDENTICAL bootstrap fixed point, (3) automated negative collision tests, and (4) permanent retirement once RR-03 lands. If heuristic fails Gates 1–3, it is permanently closed without re-litigation.`
- **RR-05 / CGEN-LIB-SCALE:** Distinguish `xcol` 2.6M IR quadratic `fullBody$` OOM (`Killed:9`) vs lexical `xui`/`xin`/`xit`/`xst` single-letter `a` vs `array`/`align`, `k` vs `kid_s` scope errors. Add `xui` note: `Single-letter and prefix collisions (a vs array/align, k vs kid_s) in xui must be resolved via scope-qualified facet emission, explicitly prohibiting ad-hoc replace$ masking with sentinels.`
- **L15 license/provenance:** The 15 inputs mix GPL/LGPL source headers with three no-notice shims. Preserve the internal-test-only prohibition, inventory all inputs, and report notice/provenance facts separately from legal inference. The comprehensive second pass below supersedes the first panel's categorical `GPL-2.0-infected` wording.
- **Harness hardening (L16/RR-10):** Link harness must emit duplicate weak symbol manifest (`nm -g` collision scan) for first-definition-wins across 15 libs.

### L18 (Byref Array ABI)
- Change banner `Status: LANDED for primitive/flat arrays and for shared composite ARY_VAR_DATA member arrays.` → `Status: LANDED for primitive/flat arrays and shared composite ARY_VAR_DATA member arrays (compile-only). General composite-array by-ref (PM pm[]) remains open. Runtime behavior for ARY remains blocked on ATTACH alias semantics (RR-06).`

### L19 (Facet Manifest)
- Change `cgen.x now parses the manifest header and uses it to narrowly consume dyn/dual/arr2d facets...` → `cgen.x now parses the manifest header and narrowly consumes dyn/dual/arr2d facets for 1-D/2-D dynamic and dual-use arrays. strDual and allStrArr remain on heuristic scans; scope-qualified lookup is open under RR-03 to resolve xui/xin/xit/xst without string-replacement placeholders.` Add note: `Single-letter identifier dual-use (e.g. a vs align/array and k vs kid in xui.x) cannot be reliably fixed via heuristic string replacements due to substring collisions with align, array, kid_s; scoped facet ingestion is the required mechanism.`

### Test harness `cgen_cemitter_sync.rs:340`
- Change `// Idempotent: cgen.x now buffers cOut$ and applies these same patches internally (raw 114/114). The harness keeps them for older cgen binaries but must not double-patch found_arr -> found_arr_arr.` → `// Idempotent: cgen.x applies these patches internally via per-function fullBody$ and forward-decl fwdDeclsBuf$ passes (cgen.x streams via PRINT without a global cOut$ buffer). The harness keeps them for older cgen binaries but must not double-patch found_arr -> found_arr_arr.` RR-13 change: `// Idempotent: cgen.x applies these replacements internally in fullBody$ (raw 114/114 verified). RR-13 removes these harness workarounds so the test strictly verifies raw compiler output.`

## Shared Findings (7 lenses)

- **Evidence:** 61/61 sync, 80/80 byte-identical, 114/114 raw `PASS 114 FAIL 0` via `xb --emit-c selfhost/cgen.x > cgen.c; cc -O0 -Wno-int-conversion -Wno-incompatible-pointer-types cgen.c -o cgen; xb --emit-ir demo.x | cgen | cc -c` observed (packet), but CI `cgen_x_compiles_all_demos_cc_clean` still retains `self_c.replace(...)` for `found`/`TranslateStatement` (60 lines, author-claimed 114/114). 282/0 workspace carried, not re-executed in this session (read-only). 1736 `xb_user_*` via `XB_WEAK_SYMBOLS=1` first-definition-wins observed, smoke 7 `Version$` only. 9/15 selfhost floor observed: `xcol` 2.6M IR `Killed:9` (quadratic `fullBody$` string buffering), `xgr` abort, `xui` 4→20→4 errors (`a` at 4659 `xb_str_a_s[xb_var_a]`, `k` at 5272 `xb_str_k`, `array` at 6024, `tool`/`window` at 3489/3599) after `54db874` tool/window with `windowInfo`/`window_s`/`tool$` placeholders. No `cOut$` in `cgen.x` (`grep -n cOut` 0); file-scope `PRINT` + `fullBody$`/`mainBody$` + `fwdDeclsBuf$` only.
- **Architecture:** Facet pipeline remains additive/opt-in, narrow `dyn/dual/arr2d` stable, `strDual`/`allStrArr` heuristic (correct, per Slice 4.1). Global `:name:` flattening strips `scope=Func` → `line` in `qbtoxb` collisions. Placeholder masking (`##STR_TOOL_S##` etc.) for `tool`/`window` does not scale to single-letter `a`/`k` vs `array`/`align`/`kid_s` — needs scope-qualified `(scope,name,type)` facet lookup at `c_var_name$`/`arr_acc_name$` emission time, not post-emission `replace$` on `fullBody$`.
- **Reproducibility:** Raw 114/114 reproducible with `-O0` (200k-line `cgen.c` memory) + warning suppressions, but CI harness-assisted until RR-13. `XB_WEAK_SYMBOLS=1` determinism depends on fixed link order `xcm xdis xma xui xut xutpde gdi32 kernel32 user32 xcol xgr xin xit xrun xst`; weak-symbol shadowing silent. `ARY_VAR_DATA` 2/2 compile-only, runtime blocked on `ATTACH` (`parser.rs:718-724` `Compound(vec![])` no-op).
- **Provenance/Security:** GPL/LGPL-header inputs plus no-notice `gdi32`/`kernel32`/`user32` are linked into one internal-test artifact; repository evidence does not establish redistribution clearance. Weak-symbol shadowing lacks a collision manifest. `SHELL` (`system()`/`sh -c`) and compiled `Xin*` sockets are ungated host effects; the interpreter stubs `Xin*`.
- **Code Correctness:** `found` file-scope `_arr` after `WEND` (1118) + per-function `fullBody$` (`xb_str_found`→`xb_var_found`, `intptr_t* xb_var_found`→`*_arr`, `= calloc`/`[`, `xb_ub/d1_found`→`_arr`, scalar injection for `CheckAdjacent` at 1406) and `TranslateStatement` `fwdDeclsBuf$` `line:integer[],ntoken:integer -> integer` (1039, inside `IF fwdEmpty=0` for non-empty `qbtoxb`) correctly handle `Selection`/`Redo`/`TumbleColumn`/`CheckAdjacent` without `cOut$`. Single-letter `a`/`k` via `replace$` on `fullBody$` is architectural dead-end (substring `xb_var_a` vs `xb_var_align`/`array`, `xb_str_a` vs `xb_str_align`).
- **Usability:** Roadmap TODOs for `a`/`k`/`array` at 4659/5272/5545/6024 must forbid raw `replace$` and require RR-03 scoped facets. RR-03 before RR-13 and RR-05 parallel with Track A correctly ordered. Raw 114/114 flags and `XB_WEAK_SYMBOLS` first-definition-wins must be explicitly documented. `ATTACH` no-op (`parser.rs:718-724` `ATTACH var$ TO display$` → `Compound(vec![])`) silently fails aliasing for `xcol`/`xst`/`xgr`/`xui`/`xit`.

## Disagreements / Residual Risks

- **No DISAGREE** — 7/7 `AGREE WITH CHANGES`. Residual risks:
  - Single-letter `a`/`k`/`array` in `xui` (4 cc-errors) will regress if `replace$` on `fullBody$` is extended without RR-03; heuristic 4-gate falsifiability clause must be enforced.
  - `xcol` 2.6M IR `fullBody$` quadratic `Killed:9` and `xgr` abort remain resource bottlenecks, not lexical.
  - `ATTACH` alias semantics (RR-06) block all stateful lib runtime behavior even after 15/15 compile-clean.
  - `cOut$` vs `fullBody$` vs `mainBody$` documentation drift in `cgen_cemitter_sync.rs:340` must be fixed to prevent whole-file `cOut$` buffering attempts.

## Evidence Actually Checked

- **Executed (observed):** `git branch --show-current` → `main`, `git log --oneline -3` → `54db874`/`ac8ea35`/`fd78073`, `wc -l selfhost/cgen.x` → 7189, `grep -n cOut` → 0, `grep -n found`/`TranslateStatement` (1039/1117/1381/1657), `cargo run --bin xb -- --emit-ir selfhost/cgen.x` → `exit 0`, manual `xb --emit-c selfhost/cgen.x > cgen.c; cc -O0 -o cgen; xb --emit-ir demo.x | cgen | cc -c` → `PASS 114 FAIL 0`, `cargo test -p xb-runtime --test xbsourcelib_parity` → `ok` (2), `cgen_x_compiles_all_demos_cc_clean` → `ok` (1, 60 filtered), `cgen_selfhost` → `2 passed`, `native_emit` → `5 passed`, `checks/link-core-libs.sh` → `1736`, `checks/cgen-lib-compile.sh` → `ok xut` etc. + `xcol` `Killed:9` + `xui` 20→4 errors (tool/window → a/k/array) — all coordinator-executed or packet-observed.
- **Read (not executed):** `docs/16` §4, `docs/17` banner + §0 queue + L15, `docs/18` `ARY_VAR_DATA`, `docs/19` `strDual`/`allStrArr`, `docs/00`/`04` Win32 shims, both vendor notice bodies, the demo harness rewrites, `selfhost/cgen.x` body buffers, the parser `ATTACH` no-op, `system()` lowering, and compiled BSD sockets. The later provenance lens established that both notice bodies are numbered through their final sections but omit GNU front matter.
- **Inferred / Not Checked:** Full `cargo test --release --workspace` 282/0 not re-run in this session (carried); stage2 contracts `v0.1`–`v0.18` immutability; `gdi32`/`kernel32`/`user32` provenance beyond header absence.

## Candidate Adoption Ledger

| ID | Candidate | Status | Evidence | Next Action / Trigger |
|---|---|---|---|---|
| C1 | L16/L17/L18/L19 + harness-comment wording (scoped facets, raw vs harness, `cOut$` vs `fullBody$`, runtime/capability boundaries) | **Adopted for wording 2026-08-29; implementation portions deferred** | Named surfaces updated and guarded; harness rewrites, RR-03, RR-09, and RR-10 remain open | Keep wording guards green; implementation exits remain under C2/C3 and RR-09/RR-10 |
| C2 | RR-03 scoped facets (scope+name+type) to replace `replace$` for single-letter `a`/`k`/`array` in `xui`/`xin`/`xit`/`xst` | **Deferred** | `xui` 4 cc-errors at 4659/5272/5545/6024 after `54db874` tool/window; `a` vs `array`/`align` placeholder explosion risk | Land RR-03 facet emission/consumption for `strDual`/`allStrArr` with scope-qualified lookup; falsifiable via `xui` cc-clean and `cOut$` 0 checks |
| C3 | RR-13 raw demo guard (strip harness `replace$` in `cgen_x_compiles_all_demos_cc_clean` so CI gates raw 114/114) | **Deferred** | Manual raw 114/114 `PASS 114` observed, CI still harness-assisted | Delete `self_c.replace(...)` blocks in `cgen_cemitter_sync.rs` after `cgen.x` internal `fullBody$`/`fwdDeclsBuf$` fixes verified; guard with raw `cc -c` without harness |

*Falsifiability clause:* C1 wording is adopted and deterministically guarded. Its compiler/runtime/harness implementations remain open only under their named ledger rows; removing those rows or guards without replacement would falsify this record.

*Provenance labels:* `Architecture`/`Reproducibility`/`Strategic`/`Evidence`/`CodeCorrectness`/`Provenance`/`Usability` lenses recovered via tier-1 DM-wake (scout schema-coerced); no lens crushed without yield; `Evidence Actually Checked` distinguishes coordinator-executed vs packet-observed vs read-only.


## Comprehensive Roadmap and Known-Issues Second Pass — 2026-08-29

### Panel Consensus

- **Decision:** **AGREE WITH CHANGES** — 7/7 independent read-only lenses:
  Evidence, RoadmapLifecycle, CompilerDefects, Reproducibility, RuntimeSecurity,
  Provenance, and StrategicMerge. No `AGREE`; no `DISAGREE`.
- **Use-case recommendation:** `study` and reproduce the named compiler
  contracts now. Adopt the compiler/demo path only after RR-13 removes harness
  rewrites and RR-03 replaces flattened facet lookup. Legacy-library adoption
  remains blocked on RR-06/RR-07/RR-08. Deployment and untrusted execution
  remain blocked on RR-09 and RR-11.
- **Authority decision:** `README.md` is the headline; `docs/17` is the sole
  living umbrella for open work; `docs/16`, `docs/18`, and `docs/19` are scoped
  living contracts. Docs 10 and 12 are historical proposals/surveys; docs 13
  and 14 are milestone records. Closed `TASKS.bootstrap.md` and
  `TASKS.stage2.md` remain immutable.

### Required Wording Changes

1. Repair `docs/17:11-38` atomically. Keep one re-verification banner and one
   evidence hierarchy: 11-program runtime parity, two-source ARY compile-only,
   114/114 harness-assisted CI plus a standalone raw sweep, Rust-CEmitter
   15/15 link plus selfhost 9/15 floor.
2. Correct `README.md`: `xbsourcelib_interp_matches_compiled` does not execute
   `ary` or `ary1.0001`; `xbsourcelib_ary_compiles_clean` covers those two
   sources at compile-only tier.
3. Add lifecycle banners to docs 10, 12, 13, and 14; add an authority hierarchy
   to `docs/README.md`; preserve historical bodies while updating explicit
   current-status/toolchain sections.
4. Update docs 13/14 LLVM statements: LLVM 22.1.8 is locally available,
   `LlvmBackend` emits a real native object for its supported subset, remains
   opt-in, and has no default-suite/CI coverage.
5. Update `docs/16` to 2026-08-29 and disclose that its named all-demo test
   still rewrites generated C. Keep positive-corpus 80/80 as the emitted-C byte
   lock; demo text identity remains de-scoped.
6. Update `docs/17`/`docs/19` current selfhost status to HEAD `54db874`:
   RR-03 classification closure (9/15 to 13/15) and RR-05 resource closure
   (`xcol`/`xgr`, 13/15 to 15/15) are independent; RR-13 removes harness
   mutations. Single-letter fixes require scoped facets, not substring masks.
7. Add a runtime-faithfulness boundary to `docs/04`: `ATTACH` is discarded,
   GUI behavior is headless/synthetic, compiled `Xin*` performs live socket
   I/O while the interpreter stubs it, and `SHELL` has live host effects.
8. Correct provenance wording in `docs/00`, `docs/04`, `README`, and docs/17
   L15. Three shims lack copyright/license statements; both vendor notice files
   contain their numbered bodies but omit GNU title/version/Preamble. Keep the
   internal-test-only prohibition, but label combined-work conclusions as
   inference rather than legal determination.
9. Synchronize both deterministic wording guards. Assert the canonical
   sentences, historical lifecycle banners, runtime/provenance boundaries, and
   exactly one `Last full re-verification` banner; reject stale contradictory
   wording.

### Shared Findings

- **Evidence tiers:** parse/lower, compile-only, static link, synthetic smoke,
  and behavioral parity are distinct. The current docs crossed those tiers in
  the ARY, core-library, demo, and GUI headlines.
- **Current compiler facts:** the named all-demo test is 114/114 only after
  Kittedy/qbtoxb mutations; raw 114/114 is standalone evidence. The selfhost
  library floor remains 9/15. RR-03 owns four classification failures; RR-05
  owns two resource/signal failures.
- **Runtime facts:** `ATTACH` becomes an empty compound; compiled `SHELL` and
  `Xin*` have live host effects; GUI success is a headless exit/synthetic
  callback contract; native helper shadowing prevents compiled-body claims.
- **Reproducibility facts:** the 15-library harness fixes weak-symbol object
  order but emits no duplicate manifest. `cgen-lib-compile.sh` exits zero
  unconditionally and both library scripts ignore an incoming `XB_BIN`.
- **Provenance facts:** `gdi32.x`, `kernel32.x`, and `user32.x` have no
  copyright or license statements; `xut.x` and `xutpde.x` credit Eddie
  Penninkhof. `COPYING` has body §§0–12 and `COPYING_LIB` body §§0–16, but both
  omit GNU title/version/Preamble.

### Disagreements / Residual Risks

- Historical-doc treatment split between rewriting stale bodies and freezing
  them. Decision: preserve dated bodies, add lifecycle banners, and update only
  sections that explicitly claim current status (`docs/13` toolchain note and
  `docs/14` §7/§21).
- One lens repeated the obsolete claim that LLVM still returns an empty object.
  Coordinator source inspection of `LlvmBackend::compile` and `object`
  (`crates/xb-compiler/src/lib.rs`) plus docs/17 LB-STUB rejects that claim:
  native object emission exists for a growing subset; it is not a full backend
  or default/CI gate.
- Vendor LGPL version and combined-work obligations are not resolved by source
  inspection. Documentation will report headers/notice contents and mark legal
  consequences as inference. RR-11 remains a distribution blocker.
- Reviewers proposed script fixes (`XB_BIN`, collision manifest, strict probe,
  in-script notice). Those are retained under RR-10/RR-11, not implemented in
  this documentation-only adoption pass.

### Evidence Actually Checked

- **Coordinator executed after adoption:** `docs_adopted_wording_guard` 1/1;
  `docs_headline_claims_are_recorded_at_named_surfaces` 1/1;
  `cgen_x_compiles_all_demos_cc_clean` 1/1 (60 filtered, 11.97s);
  `xbsourcelib_parity` 2/2 (5.86s); targeted `rustfmt --check` on both touched
  Rust test files passed. Workspace-wide `cargo fmt --all -- --check` remains
  non-green on pre-existing compiler/frontend formatting outside this docs pass.
- **Coordinator read:** all roadmap headers and authority surfaces; malformed
  docs/17 banner; harness `self_c.replace` blocks; 11-entry parity program set;
  two-source ARY compile test; LLVM object emission; library scripts and seven
  exact `Version$` smoke calls; both vendor notice files; 6.2.3/6.4.5 utility
  and shim headers.
- **Carried, not re-executed in this pass:** workspace 282/0,
  `cgen_cemitter_sync` 61/61, positive corpus 80/80, `IR_IDENTICAL`,
  Rust-CEmitter link 15/15 with 1736 symbols, selfhost floor 9/15, standalone
  raw demo 114/114.
- **Unavailable:** external issue reconciliation because GitHub CLI
  authentication is absent.

### Candidate Adoption Ledger — Second Pass

| ID | Candidate | Status | Evidence | Next action or trigger |
|---|---|---|---|---|
| C4 | Historical/living authority hierarchy and banners | **adopted** | docs 10/12/13/14 banners + docs index hierarchy | Guard lifecycle phrases |
| C5 | Canonical evidence banner and ARY denominator correction | **adopted** | one docs/17 banner; 11 non-ARY parity programs; two ARY compile-only sources | Singleton/presence/absence guards |
| C6 | Runtime-faithfulness and capability boundary | **wording adopted** / runtime implementation **deferred** | docs/04 and docs/14 now state `ATTACH`, effects, GUI, binding limits | RR-06/RR-09 implement behavior |
| C7 | Provenance/legal-evidence correction | **wording adopted** / clearance **deferred** | docs/00/04/L15/README report no-notice shims and incomplete front matter without legal overclaim | RR-11 resolves provenance |
| C8 | Current LLVM/toolchain statement | **wording adopted** / CI coverage **deferred** | docs 13/14 now record LLVM 22.1.8 and real supported-subset object output | Retain LLVM-CI-BITROT/RR-12 |
| C9 | RR-03/RR-05/RR-13 separation and heuristic falsifiability | **wording adopted** / implementation **deferred** | docs 17/19 separate classification, resource, and raw-guard exits | Implementation exits remain 13/15, 15/15, raw 114/114 |
| C10 | Deterministic guard synchronization | **adopted and verified** | canonical presence/absence plus singleton banner guards pass | Keep both documentation guards green |
| C11 | Script hardening (`XB_BIN`, duplicate manifest, strict probe, script notice) | **deferred under RR-10/RR-11** | directly read script behavior | Implement in a separate non-documentation change with script tests |

*Second-pass falsifiability:* C4–C10 are adopted at their named surfaces and
locked by deterministic tests. C11 remains intentionally deferred until a
script-hardening implementation pass.
