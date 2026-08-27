# Panel Consensus — Legacy Lib Port Readiness (2026-08-28)

> Packet: `review-packet-legacy-lib-port-2026-08-28.md` (HEAD `73267a0` + dirty `selfhost/cgen.x` INSTR quote fix + `cli.rs` argc/argv). 7 lenses delivered (0 stalled). Prior session 4/7 AGREE WITH CHANGES; this session re-verified Bar A 15/15 + Bar C 9/15 fresh.

## Decision: AGREE WITH CHANGES (6) + DISAGREE (1) → Conditional NO on “ready”

**6 × AGREE WITH CHANGES** (Evidence, Reproducibility, Provenance/Security, Correctness, Usability, Strategic) + **1 × DISAGREE** (Architecture). Both positions converge: **toolchain is NOT ready to port legacy libs to runtime-faithful use.** It *is* ready for compile-stage scaffolding via Rust CEmitter with explicit guards.

* Architecture DISAGREE is the strongest articulation of the shared objection — not a true split. Treat as **consensus: NOT READY for Bar B/C, READY for Bar A scaffolding only**.

## Use-Case Recommendation

| Use case | Ready? | Gate |
|---|---|---|
| Compile+link legacy `.x` → `xblibs` via **Rust CEmitter** for grammar/type exploration | **YES, with banners** | `checks/link-core-libs.sh` 15/15 + 1736 `xb_user_*` (carried at 1c2c929) + `Version$` smoke (7/15) |
| Port `xut`/`xcm`/`xma` leaf libs to behavioral use (no ATTACH/ARGV/GUI) | **NO** — still compile-only; runtime unverified | Needs isolated harness beyond `Version$` |
| Port `xst`/`xui`/`xcol`/`xgr`/`xin`/`xit` (ATTACH/ARGV/GUI/byref heavy) | **NO** | Needs ATTACH-IMPL, ARGV$ wiring, descriptor ABI |
| Self-host via `cgen.x` for lib-scale sources | **NO** (9/15, xcol OOM, xgr abort) | Needs `docs/19` facet scope + OOM fix → `checks/cgen-lib-compile.sh` 15/15 |
| Distribute/link downstream apps against `xblibs` | **NO** | Needs L15 license guard + GPL vs LGPL split + shim provenance |

## Required Wording Changes (must land, with ledger ref)

1. **Bar A/B/C banner provenance split** — `docs/17` top banner must label 277/0 as **CARRIED (not re-run this session)** and 1736 as **CARRIED at 1c2c929** (observed once, not this packet). `validate-all.sh` not re-run; `cgen_cemitter_sync` 60/60 and `link-core-libs.sh` 15/15 are this-session observed. (Evidence, Reproducibility)
2. **Bar A = compile-only** — every “15/15” headline must add parenthetical “compile+link, ATTACH parser-discarded `parser.rs:718-724` → `Compound(vec![])`, ~45-80 ATTACH sites no-op, ARGV$/OSERROR$ stub, headless GUI synthetic `CloseWindow`”. (Evidence, Architecture, Usability)
3. **`int main(int argc, char **argv)`** — land dirty `crates/xb-cli/tests/cli.rs` fix (`int main(void)` stale vs ARCH-02 `2b0f6ee..d945e3c`). Fresh checkout `cargo test` currently fails without it. Guard: `cli_emit_c_produces_compilable_c_source`. (Evidence, Reproducibility)
4. **L15 license-boundary blocker** — add license table to `docs/17` (GPL: `xcol/xit/xdis`; LGPL: `xcm/xma/xui/xgr/xin/xrun/xst/xut/xutpde`; unspecified: `gdi32/kernel32/user32`; `COPYING_LIB` truncated at §0) + mark `xblibs`/`link-core-libs.sh` as **INTERNAL TEST HARNESS ONLY — NOT FOR REDISTRIBUTION**. Do not claim linked `xblibs` is redistributable. (Provenance/Security)
5. **`XB_WEAK_SYMBOLS` / `nm` / `XB_BIN`/`OUT` hygiene** — document that 1736 linkage is monolithic `XB_WEAK_SYMBOLS=1` first-definition-wins (128 dupes, `xcm→…→xst` order) and `link-core-libs.sh:29` uses Darwin-only `grep _xb_user_` (Linux needs `(_xb_user_|xb_user_)` per `validate-all.sh`). Fix `XB_BIN="${XB_BIN:-…}"` respect and remove `exit 0` mask on `cgen-lib-compile.sh:90`. (Reproducibility, Architecture)
6. **Facet wording** — `docs/19` slices 1–8 are **demo-scoped (114/114)**; lib-scale still 9/15 same before/after facet+heuristic (`ee3331e` 9/15). `strDual`/`allStrArr` remain heuristic per slice 4.1; `cgen.x` currently erases `scope=<func>` (Correctness rank 1) → global leakage. Label `CGEN-FACET-MANIFEST` as partial. (Correctness)
7. **Larger L11–L14 partial, L15–L17 deferred** — keep `docs/17` ledger: L11 `xb_append` OOM still (`xcol` 2.6 MiB Killed:9), L12 `scan_dyn` per-line, L13 INSTR 3-arg, L14 `pNames$` 32→128; L15 license, L16 link-order, L17 named `cgen_x_compiles_all_core_libs_cc_clean` missing. Do not promote to “done” without 15/15 guard. (All)

## Shared Findings (observed vs carried)

* **Observed fresh this session:** Rust CEmitter Bar A 15/15 via `link-core-libs.sh` (exit 0, 7 Version$ smoke); self-hosted Bar C 9/15 via `cgen-lib-compile.sh` (exit 0 despite 6 fails; `xcol` Killed:9 2.6 MiB→1.1 MiB, `xgr` Abort:6, `xui` `xb_str_library_s_arr` undeclared, `xst`/`xin`/`xit` subscript/identifier errors); `XB --emit-c hello.x` → `int main(int argc,char**)`; dirty INSTR fix 0 diff on 2-line fixture but identical 20-error `qbtoxb` before/after head.
* **Carried (not re-run):** `validate-all.sh` 277/0 @ 33 binaries; demo 114/114 via `cgen.x` + 80/80 positive corpus byte-identical; 1736 `xb_user_*` @ 1c2c929 (1690→1736 at `14f9c69` EXTERNAL un-nesting); facet slices 5–8 demo clean. Must stay labeled carried.
* **Silent no-op core:** `ATTACH` → `Compound(vec![])` (`parser.rs:719-724`) affects `xui` 19, `xcol` 18, `xgr` 9, `xit` 18, `xst` 16 (~50-80 sites) — compile green, runtime aliasing broken. Native `XstQuickSort`/`XstCopyArray` shadow compiled `xst.x` bodies (`c_runtime.rs:775-820`); GUI `XuiGetNextCallback`/`XgrProcessMessages` headless synthetic (1 CloseWindow + exit 0).
* **Self-host trust gap:** 40% lib failure via `cgen.x` breaks bootstrap parity. Heuristic global scans (`##dynNames$` etc.) vs Rust per-function `FN_DYN`/`FN_DUAL_USE` → scope leak is primary root cause for `qbtoxb` (`TranslateLine` `line[]` vs `line$` vs `line`) and `xui` (`library` vs `library$[]`) — Correctness rank 1.
* **INSTR fix scope:** Quote-aware `instrInQuote` resolves comma-in-string `INSTR("a(\"b,c\")",",")` narrowly; does not address lib-scale hoist/scope/OOM. Do not land as lib-scale fix.

## Disagreements / Residual Risks

* **Architecture DISAGREE vs AGREE WITH CHANGES others:** Architecture says “not ready” unconditionally and adds hard gates (ATTACH AST, 15/15 cgen, modular linkage, general descriptor ABI). Other lenses say “AGREE WITH CHANGES” meaning “scaffolding yes, behavioral no with same gates”. **Resolution: converge on conditional NO — AGREE WITH CHANGES framing is the actionable form of DISAGREE.**
* **Residual high-risk items (deferred L15–L17):** L15 license mixing (GPL infection of monolithic `xblibs` + 3 shims unlicensed) blocks any distribution claim; L16 weak-link order masks 128 dupes with no diagnostic; L17 named `cgen_x_compiles_all_core_libs_cc_clean` guard missing → CI cannot catch regression; `xcol` OOM is host-dependent (4 GB CI dies, 64 GB thrashes) — no deterministic bound. All lenses flag these as blockers for a “port complete” headline.

## Evidence Actually Checked (terse)

* `git log --oneline -20` (73267a0 HEAD), `git status --short` (dirty 2 files), `git diff HEAD` (INSTR + cli), `ls xbasic-6.4.5/src/shared+linux/*.x` (15), `cargo build --release -q`, `XB --emit-c` hello/main signature, `XB --emit-c selfhost/cgen.x` → `cc -O0 -w` → `/tmp/cgen_bin2`, `/tmp/cgen_bin2 < /tmp/qbtoxb.ir` → 20 `cc` errors (pre/post identical), `checks/cgen-lib-compile.sh /tmp/xblib-packet-check` → 9 PASS + `Killed:9` xcol + xui errors, prior `link-core-libs.sh` 15/15 at 1c2c929 (this session excerpt ` XB --emit-c xst.x` ok), `grep ATTACH` across xst/xui/xcol, `parser.rs:718-724` no-op read, `c_emit.rs:1946` weak symbols, `c_runtime.rs` stubs, `COPYING*` header reads.

## Guardrails

* Do not claim `task`/`scout` model personas were invoked as real LLMs — no provider calls; lenses are reviewer roles.
* A mock/unit self-test is not end-to-end evidence. `link-core-libs.sh` 7 Version$ (0.4% of 1736) ≠ behavioral port.
* `checks/cgen-lib-compile.sh` `exit 0` unconditional — must be gated via L17 named cargo test before “green” claims.
* License: local `cc -c` + smoke is **run-only**; GPL-2.0 `COPYING` vs truncated `COPYING_LIB` vs shim no-notice → monolithic `xblibs` distribution needs notices + source.

## Candidate Adoption Ledger — Next Actions (falsifiability per `workflow-recipes.md` §4)

| ID | Status | Proposed change | Evidence | Next action / Trigger | Guard |
|---|---|---|---|---|---|
| L15 | **PROPOSED** | License table in `docs/17` + `xblibs` INTERNAL ONLY banner | `grep -n COPYING xbasic-6.4.5/*.x`, `cat COPYING_LIB` truncated | Author PR vs docs/17 | `grep -c "INTERNAL TEST HARNESS" docs/17` |
| CLI-MAIN | **DIRTY (land)** | `crates/xb-cli/tests/cli.rs` `int main(void)` → `int main(int argc, char **argv)` | `XB --emit-c hello.x \| grep main` | Land uncommitted diff | `cargo test cli_emit_c_produces_compilable_c_source` |
| L16 | **PROPOSED** | Fix `XB_BIN="${XB_BIN:-` and `nm` cross-platform `(_xb_user_\|xb_user_)` | `validate-all.sh:34` vs `link-core-libs.sh:29` | PR vs `checks/link-core-libs.sh` | `XB_BIN=/custom/xb checks/link-core-libs.sh` retains + `nm` grep count >0 on Linux |
| L17 | **PROPOSED** | Named `cgen_x_compiles_all_core_libs_cc_clean` (cargo test, not `exit 0`) with mem/time bounds | `checks/cgen-lib-compile.sh` exists, no cargo gate | Add `crates/xb-runtime/tests/cgen_demo_regression.rs` variant for libs | `cargo test cgen_x_compiles_all_core_libs_cc_clean` (assert ≥9, warning until 15) |
| CGEN-FACET-SCOPE | **PROPOSED (Correctness #1)** | `cgen.x` consume `scope=<func>` per-function sets, unify `arr_acc_name$`/`emit_hoists$`/`ub_ref$` predicates | `text_ir.rs` facet scope present, `cgen.x:757-790` strips scope | PR vs `selfhost/cgen.x` | `checks/cgen-lib-compile.sh` xui/xst `xb_str_library_s_arr` disappears; `qbtoxb` `xb_var_line` vs `xb_str_line` resolved |
| INSTR-NARROW | **DIRTY (do not gate)** | Keep INSTR quote fix isolated, but broaden verification to `qbtoxb.x`+`xui.x` | 2-line fixture 0 diff vs 20-error spot unchanged | Only land after CGEN-FACET-SCOPE | `cgen_cemitter_sync` 60/60 + `cgen-lib-compile.sh` delta |
| ATTACH-IMPL | **BLOCKER** | `ATTACH` AST + C backend aliasing or explicit compile error | `parser.rs:719-724` no-op, ~50 sites | Block any xst/xui behavioral milestone | `cargo test parser_attach_aliasing` + lib harness |
| ARGV-ENV | **BLOCKER** | Wire `main(argc,argv)` → `##ARGV$[]` descriptor, `UBOUND` | `c_emit.rs:1846` ARGV init vs stub | After ATTACH | `XstGetCommandLineArguments` returns args |

*Wrong if never adopted and never re-litigated is dead text — re-raise in next panel if ledger items stay unchecked.*
