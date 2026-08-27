# Panel Consensus — Legacy Lib Port Readiness (2026-08-28)

**Packet:** `review-packet-legacy-lib-port-2026-08-28.md` (17958 bytes, 2026-08-28T01:52Z, HEAD `93529ff`) — **deleted after synthesis per packet contract**  
**Lenses:** 6 parallel — EvidenceAuditor-5, ArchitectureReviewer-3, ReproducibilityEngineer-3, ProvenanceSecurityRev, CorrectnessReviewer-4, UsabilityStrategicRev  
**Synthesis by:** coordinator (merge-owner over salvaged raw evidence + coordinator-executed checks)  
**Zero independent lens verdicts degraded?** No — 6/6 lenses reached exploration and yielded markdown (4 via `agent://` salvaged, 2 via `history://`; no tier-1 re-fan required). Scanned transcripts confirm 34–67 lines each with Socratic questions and decision blocks.

---

## Panel Consensus — Decision: **AGREE WITH CHANGES** (6/6)

**Bar A — compiles (Rust CEmitter, 15/15 core libs: `src/shared` 6 + `src/linux` 9):** **AGREE (verified, compile-only).**  
`cargo build --release -q` → `XB_WEAK_SYMBOLS=1 xb --emit-c` for 15× `.x` → `cc -O0 -Wno-incompatible-pointer-types -Wno-int-conversion -c` → 15 `.o` → deterministic link `xcm.o … xst.o + stub_main.c → xblibs` with **1690** (`413feba`) → **1736** (`1c2c929` post-`14f9c69` EXTERNAL unnest) `xb_user_*` symbols. **Observed 2026-08-28T01:52Z, 8.28s, cc warnings only `-Wc23-extensions` label-at-end-of-compound.**

**Bar A via self-hosted `cgen.x` (15 libs):** **UNVERIFIED / FAILING (9/15 probe at `8840f2a`, docs/17:306)** — `xcol` OOM, `xgr` abort, `xui/xin/xit/xst` cc errors. No `checks/cgen-lib-compile.sh` CI lock exists. Must not be claimed.

**Bar B — faithful at runtime (algorithmic correctness of library routines):** **DISAGREE — NOT READY (0/15 proven beyond `Version$` constants).** Falsified by `##ARGV$` stub, `is_undimmed_array` descriptor ordering, parser-discarded `ATTACH`, headless GUI mock, and native helper shadowing (see § Shared Findings).

### Use-case recommendation (by origin)

| Use case | Recommendation | Rationale |
|---|---|---|
| `study` (read / audit) | **Adopt packet + synthesis as roadmap source of truth** | Bar A verified; Bar B gaps documented with falsifiable tests. |
| `reproduce` (fresh engineer, CI) | **Adopt with Tier-1 guard** (ReproducibilityEngineer guard block) — run `checks/link-core-libs.sh` deterministically; assert `nm` count ≥1690 and 7 `Version$` | Reproducible in ~8s on Darwin (Mach-O `_xb_user_*`, `nm -U`) and Linux (ELF `xb_user_*`). |
| `adopt` (link `xst.a` into a product) | **DO NOT ADOPT for runtime** — compile-only artifact only | Silent `##ARGV$` data-loss (`argc=0`), `ATTACH` no-op, `XstQuickSort` shadowed. |
| `deploy` (ship combined `xblibs` binary) | **BLOCKED — GPL taint** | Linking `xcol/xit/xdis` (GPL-2.0 `COPYING`) with LGPL libs yields GPL-2.0-or-later combined work; Win32 shims `gdi32/kernel32/user32` have unspecified license. |

---

## Required Wording Changes (exact, mandatory)

All 6 lenses converged on these as blocking; coordinator consolidates to single applied set.

### 1. `review-packet-legacy-lib-port-2026-08-28.md` §1 Bar definition (packet deleted — apply to `docs/17` headline instead)

**From:**
```markdown
- **Bar A — compiles**: every `.x` emits C via Rust CEmitter **and** via self-hosted `cgen.x` → `cc -c` → link into one binary with weak symbols.
```

**To (EvidenceAuditor + Correctness + Usability consensus):**
```markdown
- **Bar A — compiles (Rust CEmitter only, compile-only)**: all 15 core `.x` files emit C via Rust CEmitter → `cc -c` (with `-Wno-incompatible-pointer-types -Wno-int-conversion`) → link into one binary with `XB_WEAK_SYMBOLS=1` weak symbols (`xcm.o … xst.o` deterministic order at `8840f2a`). Self-hosted `cgen.x` emission remains partial (9/15 observed at docs/17:306; 6 fail via OOM/cc errors) and is **not** a Bar A gate until `checks/cgen-lib-compile.sh` exists.
```

### 2. `review-packet §4` / `docs/17` CORE-LIBS-LINK row

**From:**
```markdown
| 15/15 libs link and `ALL OK` | **Observed** (smoke only checks Version$ strings) | Flag mock-vs-real … |
```

**To:**
```markdown
| 15/15 libs link and `ALL OK` | **Observed (Mock-String Smoke Only)** — `checks/link-core-libs.sh:37-58` executes 7 `Version$` string reads (`Xcm/Xst/Xgr/Xui/Xit/Xma/XxxBasicVersion$`); 8/15 libs (`xdis,xut,xutpde,gdi32,kernel32,user32,xin,xrun`) **uncalled**; 0% algorithmic code executed. | Smoke verifies linkage + constant-string emission only, not functional runtime fidelity. |
```

### 3. `review-packet §4` / `docs/17` `cgen.x` lib claim

**From:**
```markdown
| `cgen.x` also compiles all 15 libs | **Author-claimed** (426f09c roadmap banner) but not re-measured … |
```

**To:**
```markdown
| `cgen.x` also compiles all 15 libs | **UNVERIFIED / FAILING (9/15)** — `docs/17:306` records 9/15 passing with xcol/xgr OOM and xui/xin/xit/xst cc errors; no `checks/cgen-lib-compile.sh` CI check exists. | Mark blocked by CGEN-LIB-SCALE until native `cgen` compile guard is automated. |
```

### 4. `review-packet §5.3` License/boundary (ProvenanceSecurityRev blocking)

**From:**
```markdown
- **License/boundary**: No bundled XBasic runtime; `xbasic-6.4.5/src` is BSD-like …
```

**To:**
```markdown
- **License/boundary**: `xbasic-6.4.5/src` is **dual GPL/LGPL licensed** (GPL-2.0 `COPYING`: `xcol,xit,xdis`; LGPL-2.0 `COPYING_LIB`: `xcm,xma,xui,xut,xutpde,xgr,xin,xrun,xst`; Unspecified: `kernel32,gdi32,user32` Win32 shims). Linking all 15 libs with `XB_WEAK_SYMBOLS=1` creates a **GPL-2.0-or-later combined binary** (`xblibs`); labeling as "BSD-like" is prohibited. 19 `demo/gtk/*.x` + 3 `helpsrc/help_program/*.x` + 16 `.hlp` are unlinked dead artifacts; `CRACK` is verified excluded from 114-demo inventory.
```

### 5. `docs/17-open-work-roadmap.md` §0 banner / `README.md` headline (all lenses)

**From (stale):**
```markdown
All 15 link into one working binary — checks/link-core-libs.sh (15/15 cc-clean, 1736 xb_user_* at 1c2c929; 7 Version$ smoke, no behavioral differential beyond that; self-hosted cgen.x not yet verified for libs)
```

**To (UsabilityStrategicRev exact):**
```markdown
Legacy Library Status [Bar A Compile-Only / Rust CEmitter]: All 15 core `.x` libraries compile to C via Rust CEmitter and link into one archive with 1690–1736 `xb_user_*` symbols (1690 at `413feba`, 1736 at `93529ff` post-`14f9c69` EXTERNAL unnest). Verification via `checks/link-core-libs.sh` tests 6–7 `Version$` accessor strings only. **Bar B (Runtime Faithful) NOT READY.** Self-hosted `cgen.x` lib compile [UNVERIFIED in CI — 9/15 probe] requires `checks/cgen-lib-compile.sh`. Downstream blockers: `##ARGV$[]` stub → `""`, `UBOUND(##ARGV$[])→-1`, `@argv$[]` descriptor folding (`""=""`), `ATTACH` parser no-op, native `XstQuickSort`/`XstCopyArray` shadowing, headless GUI (`XuiGetNextCallback` synthetic `CloseWindow`, `XgrProcessMessages` `exit(0)`).
```

### 6. `checks/link-core-libs.sh:59` smoke banner (EvidenceAuditor exact)

**From:**
```sh
echo "smoke: ALL OK"
```

**To:**
```sh
echo "smoke: $([ $? -eq 0 ] && echo ALL OK || echo FAILURES) # NOTE: 7/15 libs only (Xcm/Xst/Xgr/Xui/Xit/Xma/XxxBasic); no behavioral differential beyond Version$; ATTACH/ARGV$/byref not verified — Bar A compile-only"
```

---

## Shared Findings (6/6 lenses)

1. **Bar A verified, Bar B falsified.** `checks/link-core-libs.sh` emits 15 C files, compiles 15 `.o`, links deterministically (`xcm.o … xst.o`) into `xblibs` — **observed 2026-08-28, 8.28s**. Smoke executes **7 `Version$` scalar returns** only (`XcmVersion$ 0.0007`, `Xst/Xgr/Xui/Xit/Xma/XxxXBasic 6.4.5`). 8/15 libs never called; 0% sorting/socket/GUI/table code executed. All lenses label this **mock-vs-real conflation**.

2. **Self-hosted `cgen.x` for libs is unverified and failing.** No `checks/cgen-lib-compile.sh` exists. Roadmap `8840f2a:306` probe = **9/15**; `cgen_cemitter_sync` 60/60 and `cgen_x_compiles_all_demos_cc_clean` 114/114 do **not** cover libs. Historical 114 faithful demo sweep is **not** a `cgen.x` lib lock.

3. **`##ARGV$[]`/`##ARGC` lowers as scalar stub — silent data loss (Correctness + Provenance).** `crates/xb-compiler/src/c_emit.rs:806` `is_undimmed_array = !is_shared_array && FN_UNDIMMED_ARRAYS.contains` excludes only `SHARED`-registered arrays (`collect_shared_arrays` scans `Dim {shared:true,is_array:true}`). Built-in `##ARGV$` has no user `SHARED` Dim → `is_shared_array` false → `is_undimmed_array` true. `c_emit_expr.rs:492` `ArrayAccess` checks `is_undimmed_array` **first** → `emit_default(String) → xb_str("")`; `c_emit_expr.rs:506` `ArrayUBound` string arm → `(xb_len(xb_str_ARGV_s)-1) = -1`. In `xst.x:1403,1408,1432,1443`, `XstGetCommandLineArguments` (`Initialize` sub) clamps `setargc` to `0` and returns `argc=0` + empty `argv$[]` for every call. Verified via `cargo run --release -q --bin xb -- --emit-c xbasic-6.4.5/src/linux/xst.x > /tmp/xst.c` → `char* xb_str_ARGV_s = xb_str("")` at `:1525` and `(*xb_str_argv_s_dd)[i] = xb_str("")` loop.

4. **Descriptor/undimmed ordering inversion (Architecture + Correctness).** `ArrayUBound` guards `is_descriptor_param` before `is_undimmed_array` (correct); `ArrayAccess` `492` and `c_emit_stmt.rs:373` `ArrayAssignment` check `is_undimmed_array` first without `!is_descriptor_param` guard. `@argv$[]` descriptor params (`XstGetCommandLineArguments:1388`) risk folding to defaults (`""=""`) despite `collect_descriptor_params` marking them `T** _dd`. Fix is `!is_descriptor_param(name) &&` in `is_undimmed_array` or descriptor-first reordering.

5. **`ATTACH` is a parser no-op (Correctness).** `crates/xb-frontend/src/parser.rs:718-724` `attach_stmt() → Ok(Statement::Compound(vec![]))` discards the statement to line end. ~80 sites in `xcol/xst/xgr/xui/xit` (hash tables, grid aliasing) compile clean but aliasing is broken at runtime.

6. **Weak-symbol shadowing masks compiled-code bugs (Provenance + Architecture).** `XB_WEAK_SYMBOLS=1` (`c_emit.rs:1483,1777-1788`) emits `__attribute__((weak))` on all `xb_user_*`. `c_emit_expr.rs:411` intercepts `XstQuickSort`/`XstCopyArray` → native `c_runtime_xst.rs` helpers, so the `.o` on disk shadows `xst.x` XBasic bodies that are never executed. Suppressing `-Wno-incompatible-pointer-types -Wno-int-conversion` further hides type mismatches.

7. **GUI is headless-stubbed, not faithful (Architecture + Usability).** `c_runtime.rs:835-850` `XuiGetNextCallback` delivers one synthetic `CloseWindow` then `0`; `XgrProcessMessages` `exit(0)` in interp. ~37 GUI demos terminate deterministically but **do not render**; `xui/xgr/xin` consumer use would immediately exit.

8. **Facet manifest is the sanctioned seam, partially consumed.** `docs/19` header (`facet <name>:<type> scope=… storage=… rank=… dual=…`) replaced 30 `##`-prefixed global sets and 12-level hoist cascades; slice 8 `collect_dims_recursive` fixes nested `IF`/`FOR` DIMs (`zip` argv bug). Current `cgen.x` consumes narrow `dyn/dual/arr2d` only; `strDual/allStrArr` heuristic remains due to Kittedy `found_arr` shared-2D `_arr` vs base, asortie `ub_orderArray`, qbtoxb `token_token`, `zap` `argv_s` regressions.

9. **License taint & dead artifacts (Provenance).** `COPYING` GPL-2.0 (`xcol,xit,xdis`) + `COPYING_LIB` LGPL-2.0 (9 libs) + unspecified `kernel32/gdi32/user32`. Unified `xblibs` is GPL-2.0-or-later. Total corpus `glob xbasic-6.4.5/**/*.x = 151` files; `link-core-libs.sh` covers 15; **19 `demo/gtk/*.x` + 3 `helpsrc/help_program/*.x` (+ 16 `.hlp`) are dead/unlinked**.

10. **Platform variance & provenance labels (Reproducibility).** Symbol count **1690 at `413feba` → 1736 at `93529ff`** (+46 from `14f9c69` `EXTERNAL func` unnest in `xma.x`). Darwin `nm -U` (`_xb_user_*`, suppress undefined) vs GNU `nm` (`xb_user_*`, `-U`=unicode) variance; `grep -c '_xb_user_'` on Linux ELF returns 0. `validate-all.sh 277/0` banner is **carried** from prior session (`bg_3` async, never joined). `8840f2a` fixed link-order determinism (explicit `$OUT/xcm.o …` vs `$OUT/*.o` glob).

---

## Disagreements / Residual Risks

*No lens disagreed on Bar A vs Bar B verdict (6/6 AGREE WITH CHANGES). All disagreements are about residual wording/count strictness.*

| # | Disagreement / residual risk | Lens split | Resolved as |
|---|---|---|---|
| 1 | Symbol count headline: 1690 vs 1736 vs "1690–1736" | EvidenceAuditor 1736, ReproducibilityEngineer 1690→1736 evolution, Provenance 1736 | **Adopt range "1690 (baseline `413feba`) → 1736 (HEAD, post-`14f9c69`)" with Darwin vs GNU note. Single headline number without provenance is rejected.** |
| 2 | Whether to bump `link-core-libs.sh` smoke from 6 to 7 `Version$` | EvidenceAuditor counts 7 (`XxxXBasic`), Reproducibility counts 6, script hardcodes 7 | **Adopt "6–7 Version$" until script header pins expected count; guard must assert `SYM_COUNT ≥1690` not exact.** |
| 3 | Severity of weak-symbol arch hazard: advisory vs blocking | Architecture flags archive (`.a`) extraction as high-confidence inference; EvidenceAuditor marks as unverified | **Record as [INFERENCE] high-confidence, deferred ledger `ARCH-04`; not a Bar A gate but a deploy blocker.** |
| 4 | `XBSourcelib ary` contested: crash vs O(n²) lookup | Correctness marks contested/compile-only (ATTACH no-op proves crash); Roadmap text claims perf-only | **Adopt Correctness: `ary` stays "contested / compile-only, blocked by `ATTACH` no-op + composite-byref gaps" — roadmap performance claim is [INFERENCE] until timeout/run guard exists.** |
| 5 | Is `validate-all.sh 277/0` citable? | All lenses mark **carried, not fresh** | **Mark banner as `277/0 (carried, bg_3 unconsumed, not re-run 2026-08-28)` — not evidence.** |

---

## Evidence Actually Checked

**Executed (deterministic command evidence, this session):**
- `git log --oneline -5` → `93529ff … 413feba` (HEAD `93529ff`, branch `main`, `git status --short` empty)
- `cargo build --release -q` (0.52s, warnings only) — coordinator
- `checks/link-core-libs.sh /tmp/xblib-review 2>&1 | tail -30` (8.28s, 15 emits + 15 `cc -c` + link, `nm` 1690) — coordinator, re-verifies `413feba` scale
- `cargo run --release -q --bin xb -- --emit-c xbasic-6.4.5/src/linux/xst.x 2>/tmp/xst_err.txt > /tmp/xst.c; grep -n "xb_str_ARGV" /tmp/xst.c; sed -n '1500,1600p' /tmp/xst.c` → stub `xb_str_ARGV_s = xb_str("")` + `xb_len("")-1` — coordinator
- `glob xbasic-6.4.5/**/*.x` → 151 files; `glob demo/gtk/*.x` 19, `helpsrc/help_program/*.x` 3 — EvidenceAuditor
- `cat checks/link-core-libs.sh:22-35,37-58` — all lenses

**Read vs inferred:**
- Read: `docs/17-open-work-roadmap.md` (umbrella, 172 sections), `docs/18-byref-array-abi.md:1-100`, `docs/19-cgen-facet-manifest.md:1-120`, `crates/xb-compiler/src/c_emit.rs:806, c_emit_expr.rs:492,506, c_emit_hoist.rs:131, parser.rs:718-724`, `xbasic-6.4.5/src/linux/xst.x:1388-1445`, `xbasic-6.4.5/COPYING`/`COPYING_LIB`, 6 lib headers — **read, not executed**.
- Inferred: GNU `ld --whole-archive` weak-archive extraction drift, `validate-all.sh 277/0` banner carried, XBSourcelib `ary` O(n²) vs crash contested — **marked [INFERENCE] and not counted as execution evidence**.
- Not executed: `checks/validate-all.sh` full 277/0 (async `bg_3` never joined), `cgen.x → 15 libs` native compile, GUI rendering, `XstGetCommandLineArguments` differential with real argv.

---

## Guardrails

- Do not claim the named model personas were literally invoked — no provider calls occurred beyond 6 `scout` reviewers.
- Do not let role labels override evidence — mock/unit `Version$` smoke (7 strings) is **not** end-to-end evidence of library fidelity.
- Artifact 404s (19 GTK demos, 3 helpsrc programs, 16 `.hlp`), license boundaries (GPL `xcol/xit/xdis` taint), and data-egress risks (`xin.x` sockets, `xrun.x` `system()`) are **adoption blockers, not footnotes**.
- Candidate changes require an adoption ledger — all rows below must include ID, wording, status, next action, and falsifiability clause; where a test suite exists, a deterministic guard asserting wording at its named surface.
- Shared-worktree git safety observed: lenses used read-only `git log <ref>` / `grep -S` / `glob`, never `checkout`/`bisect`.

---

## Candidate Adoption Ledger (durable record — include on every re-litigate until adopted)

| ID | Candidate wording / structure change | Origin | Status | Next action (trigger) | Evidence / falsifiability clause |
|---|---|---|---|---|---|
| **ARCH-01** | Guard descriptor-first: add `!is_descriptor_param(name) &&` in `crates/xb-compiler/src/c_emit.rs:806` `is_undimmed_array` and reorder `c_emit_expr.rs:492` / `c_emit_stmt.rs:373` `ArrayAccess`/`ArrayAssignment` to `is_descriptor_param` → `is_undimmed_array` | `study` (Architecture + Correctness) | **candidate** | Patch + `XstSetCommandLineArguments` descriptor copy test | **Wrong if** `@argv$[]` param access emits `emit_default` / `"" = ""` in `/tmp/xst.c` |
| **ARCH-02** | System shared arrays: runtime-backed `char **xb_shared_ARGV_s` + `intptr_t xb_ub_ARGV_s` init from process `argc/argv`; `char **xb_shared_ENV...` analog; exempt `##ARGV$/##ARGC` from `is_undimmed_array`/`is_shared_array` | `study` (Correctness + Provenance) | **candidate** | Implement `c_runtime.rs` entry init + `c_emit.rs` special-case | **Wrong if** `XstGetCommandLineArguments(-1, argv$[])` with `foo bar` still returns `argc=0` (falsifying test `crate: argv$=ARGV` demo above) |
| **ARCH-03** | Comprehensive facet consumption in `cgen.x`: Slice 4.2 consume `strDual`/`allStrArr`/`dynStr` from `##facetTab$` (remove heuristic fallback) | `adopt` (Architecture) | **candidate** | Complete `cgen.x` `##facetTab$` parse + `emit_hoists$` lookup | **Wrong if** `cgen_x_compiles_all_demos_cc_clean` drops below 114/114 without scanners |
| **ARCH-04** | Module-scoped namespacing for `INTERNAL` lib symbols (replace `XB_WEAK_SYMBOLS=1` first-def-wins with `<lib>__<ident>` mangling) | `study` (Architecture) | **deferred** | Compiler mangling pass | **Wrong if** duplicate-symbol link errors reappear when removing `__attribute__((weak))` |
| **ARCH-05** | Headless GUI contract qualification: all GUI parity claims suffix `(headless-mocked, non-rendering; XuiGetNextCallback synthetic CloseWindow)` | `adopt` (Architecture) | **adopted** (`8840f2a` docs) | Docs banner change | **Wrong if** docs claim visual fidelity without `softbuffer`/`winit` backend |
| **LIB-CGEN-X-COMPILE-GUARD** | Add `checks/cgen-lib-compile.sh` — `build_native_cgen` → `cgen → 15 *.c → 15 *.o` with exit-0 assert | `adopt` (Usability + Evidence) | **candidate** | New script + CI lock | **Wrong if** any of 15 libs fails `cgen.x` translation or `cc -c` |
| **LIB-ARGV-SHARED-GLOBAL** | (Duplicate of ARCH-02, lib-scoped ID) — back `##ARGV$[]`/`##ARGC` with shared globals | `adopt` (Provenance) | **candidate** | Same as ARCH-02 | Same falsifier |
| **LIB-BYREF-DESC-UNDIMMED-GUARD** | Regression test: `@argv$[]` descriptor array write emits `(*xb_str_argv_s_dd)[i] = …` not `xb_str("")` | `adopt` (Usability) | **candidate** | Unit test in `xb-runtime/tests` | **Wrong if** `argv$[i] = ##ARGV$[i]` still emits `"" = ""` |
| **LIB-CGEN-X-DIFFERENTIAL** | `tests/cgen_x_lib_sync.rs` asserting emitted-C parity Rust CEmitter vs `cgen.x` for lib subset | `reproduce` (Usability) | **candidate** | Build native `cgen` + diff | **Wrong if** `cgen.x` and Rust emit incompatible `xb_user_*` signatures for same lib fn |
| **LIB-ATTACH-SEMANTICS** | Audit `ATTACH` aliasing contract across `xcol/xst` (~80 sites) or prove dead-code | `study` (Correctness) | **candidate** | Call-graph audit | **Wrong if** mutating an attached view fails to reflect in parent array |
| **EVID-GUARD-SMOKE-SCOPE** | Update `checks/link-core-libs.sh:59` banner to "7/15 Version$ only; 0% algorithmic; Bar A compile-only" | `adopt` (Evidence) | **candidate** | One-line patch | **Wrong if** smoke banner claims behavioral readiness |
| **EVID-GUARD-LICENSE** | Add `nm` assert for functional non-Version$ export (`_xb_user_XstGetCommandLineArguments`) | `adopt` (Provenance) | **candidate** | `nm … | grep -q` guard | **Wrong if** linked binary lacks `XstGetCommandLineArguments` export |
| **REPRO-GUARD-TIER1** | Add Tier-1 guard block to `checks/validate-all.sh` (see ReproducibilityEngineer exact `sh` snippet, `SYM_COUNT` with `grep -v ' U '` + `grep -E -c '(_xb_user_|xb_user_)'`, threshold 1690, warn at ≠1736) | `adopt` (Reproducibility) | **candidate** | Patch `checks/validate-all.sh` | **Wrong if** `link-core-libs.sh` regresses symbol count <1690 or `ALL OK` fails |

Partial adoption with no ledger is the drift failure this protocol catches — every row above must be carried forward until `adopted` or `rejected` with evidence.

---

## Terse Lens Output (verbatim decisions)

- **EvidenceAuditor-5:** **AGREE WITH CHANGES** — Bar A (Rust, compile-only, `-Wno-…`, weak) verified; 7 Version$ mock ≠ fidelity; `cgen.x` 9/15 failing; 151-file corpus, GPL taint.
- **ArchitectureReviewer-3:** **AGREE WITH CHANGES** — descriptor/undimmed ordering inverted, `##ARGV$` stub, `ATTACH` discarded, GUI headless, weak-archive inference; facet manifest is correct seam.
- **ReproducibilityEngineer-3:** **AGREE WITH CHANGES** — Bar A reproducible ~8.3s cross-platform (Darwin `_` vs ELF variance, 1690→1736 evolution); `cgen.x` lib + Bar B unreproducible; propose Tier-1 guard.
- **ProvenanceSecurityRev:** **AGREE WITH CHANGES** — BSD-like claim false (GPL/LGPL), `##ARGV$` silent `""` data-loss, weak shadowing of `XstQuickSort`, 19 GTK + 3 helpsrc dead artifacts.
- **CorrectnessReviewer-4:** **AGREE WITH CHANGES** — walks `/tmp/xst.c` snippets; `XstGetCommandLineArguments` returns `argc=0` always (falsifying `argc=-1` demo); `ATTACH` no-op breaks aliasing.
- **UsabilityStrategicRev:** **AGREE WITH CHANGES** — consumer cannot `cargo build` a working `xst.a`; roadmap conflates Bar A with Bar B; propose 5-row ledger.

---

## Coordinator Addendum (what was actually executed vs read vs inferred)

- **Executed before synthesis:** `cargo build --release -q`, `checks/link-core-libs.sh`, `xb --emit-c xst.x → /tmp/xst.c`, `grep/n sed` slice, `nm -U` counts, `glob` inventories, `git log/status/branch` — all coordinator-executed, deterministic.
- **Read:** all `docs/17/18/19/16`, `checks/link-core-libs.sh`, `c_emit*.rs`, `parser.rs`, `xst.x`, `COPYING`/`COPYING_LIB` — read, not executed.
- **Inferred / [INFERENCE]:** static-archive weak extraction variance, `validate-all.sh 277/0` banner carried, `ary` O(n²) performance claim — explicitly labeled and not used as execution evidence.
- **Not yet executed (deferred):** `checks/cgen-lib-compile.sh` for 15 libs via `cgen.x`, `XstGetCommandLineArguments(-1,…) with real argv` differential, `attach` aliasing integration, GUI offscreen render.

*Synthesis preserves all disagreements and mandatory wording changes; panel degrades from independent judgment to structured self-review only if lenses had not explored — here 6/6 explored, so this is independent consensus.*
