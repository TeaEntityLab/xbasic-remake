# Panel Consensus — Legacy XBasic Library Port Readiness (2026-08-28)

**Packet:** `review-packet-legacy-lib-port-2026-08-28.md` (absolute `/Users/teee/dev/xbasic-remake/...`)  
**HEAD:** `413feba` (2026-08-28) + uncommitted `M selfhost/cgen.x`, `M crates/xb-runtime/tests/cgen_cemitter_sync.rs` (Kittedy/QtboXb post-emit patches)  
**Background re-verification:** `cgen_cemitter_sync` 60/60 ok (106.62s, includes `cgen_x_compiles_all_demos_cc_clean` + `cemitter_and_cgen_agree_on_positive_corpus` + 58 corpus agree tests) — *with* dirty patches; link-core-libs 15/15 cc-clean via Rust CEmitter (1690 symbols, 8.28s) — observed.

## Panel Membership & Provenance
- **Delivered independently (full 8-shape, markdown):** StrategicSynthesis-2, UsabilityActionability, CorrectnessReviewer-3, ProvenanceSecurity — 4/7
- **Schema-coerced / salvaged raw evidence (no independent verdict):** EvidenceAuditor-4, ArchitectureReviewer-2, ReproducibilityEngineer-2 — 3/7
  - These three completed exploration (packet reads, globs, grep ATTACH/ARGV/OSERROR/SHELL, reads of docs/17/18/19, checks/link-core-libs.sh, cgen_cemitter_sync.rs) but their final markdown was swallowed by scout schema coercion. Tier-1 DM-wake (`hub send`) reported "woken" but no new assistant turn recorded — hard-quota silent wake failure (observed 2026-08-07 pattern). Per skill recovery order, coordinator salvaged their raw session JSONL (t: 75–150 KB each) and re-ran deterministic checks: `git log --oneline -5`, `git status --short`, `grep -c ATTACH` (1007 hits in src), `grep -c ARGV|OSERROR` (335 hits), `cat checks/link-core-libs.sh` weak-symbol path, `cargo test --release` counts.
  - **Disclosure:** Panel degrades from independent judgment to structured self-review for these 3 slices. Verdicts for those slices are **merge-owner synthesis over salvaged raw evidence**, explicitly labeled.

## Decision
**AGREE WITH CHANGES — 4/4 independent lenses, 7/7 with salvage**

No lens returned `AGREE` clean. No lens returned `DISAGREE` (hard block). Unanimous `AGREE WITH CHANGES` conditional on wording + test-guard changes below. Readiness tier is **reproduce (Rust CEmitter compile+link) = achieved; adopt/deploy = blocked**.

- Strategic: AGREE WITH CHANGES (reproduce tier achieved, ATTACH + cgen.x lib gap block adopt)
- Usability: AGREE WITH CHANGES (no falsifiable port-completion definition, no single guard, L11-L14 partial lacks criteria)
- Correctness: AGREE WITH CHANGES (ATTACH is Nop in all backends, smoke is 7 version strings, Kittedy/QtboXb test patches mask cgen.x bugs)
- Provenance/Security: AGREE WITH CHANGES (license boundary deferred but not test-locked, weak-symbol glob non-determinism, xb_shell/Xin surfaces undocumented)
- Evidence (salvaged): AGREE WITH CHANGES (packet overstates HEAD reproducibility due to dirty patches; 28-error memory stale)
- Architecture (salvaged): AGREE WITH CHANGES (weak symbols hide ATTACH, cgen.x heuristic scanners fragile → facet manifest prerequisite)
- Reproducibility (salvaged): AGREE WITH CHANGES (link-core-libs not wired into validate-all, -Wno flags suppress type errors, OUT not cleaned)

## Use-Case Recommendation
| Use case | Verdict | Falsifiable gate |
|---|---|---|
| **Study** (read ported libs as modern C, inspect without running) | ✅ Ready | `cargo build --release && checks/link-core-libs.sh /tmp/xblib` passes (observed) |
| **Reproduce** (compile+link legacy libs as inert objects via Rust CEmitter) | ✅ Ready | 15/15 link-clean + 7 Version$ smoke (observed) |
| **Adopt** (call library functions that touch arrays, ATTACH, SHELL, GUI, ARGV$) | ⛔ Not ready | Requires ATTACH impl, cgen.x lib compile guard, Xin/shell capability model, GUI runtime — all deferred/open |
| **Deploy** (distribute combined binary) | ⛔ Blocked | Requires L15 license-boundary resolution + L16 link-order determinism + packaging story |

## Required Wording Changes (consolidated, deduplicated — 12 changes)

### Banner / README (applies to docs/17 banner, README.md)
**RC-B1** (Strategic #3 + Correctness #1 + Usability RC6): Change banner from “all 15 core libraries compile and link through the Rust CEmitter” to:
> “all 15 core libraries compile and link through the Rust CEmitter **(compile-only; `-Wno-incompatible-pointer-types -Wno-int-conversion` + `XB_WEAK_SYMBOLS=1`; ATTACH is parser-discarded, cgen.x lib path untested, runtime behavioral parity unverified beyond 7 Version$ strings)**”

**RC-B2** (Provenance RC3): Add `## License` to README.md (GPL for 6.2.3 compiler/IDE, LGPL for func libs, 3 shim libs unspecified; combined `link-core-libs.sh` output is GPL-covered; see docs/17 LICENSE-BOUNDARY).

### docs/17 rows
**RC-R1** (Strategic #1): `CORE-LIBS-CC` → append: “ATTACH is parser-discarded — emitted C contains no array-aliasing impl. Libs using ATTACH (xcol, xst, xgr, xui, xit) compile but will produce silently wrong results on any path executing ATTACH. Tier: reproduce, not adopt.”

**RC-R2** (Strategic #2): `CORE-LIBS-LINK` → append: “Smoke covers Version$ strings only — no ATTACH/ARGV$/OSERROR$/GUI function has been runtime-verified against xbasic-6.4.5 binary. Link success ≠ behavioral fidelity.”

**RC-R3** (Strategic #6 + Correctness #5): Split ATCH into standalone row `ATTACH-IMPL`: parser-discarded Nop in all backends (parser.rs:718-724 → `Compound(vec![])`), counts xcol~20, xst~20, xgr~10, xui~15, xit~15, blocks tier (c) for 5/15 libs. Remove burial inside ARY-STATUS-RECONCILIATION.

**RC-R4** (Strategic #4): Self-hosting claim → append: “Verified on demos (114/114) + bootstrap (cgen.x emits cgen.x). Self-hosted cgen.x has **not** been run against 15 core libs — no `cgen_x_compiles_all_core_libs` test exists.”

**RC-R5** (Strategic #5): Add new row `CGEN-X-LIB-COMPILE` (open, blocked by CGEN-FACET-MANIFEST).

**RC-R6** (Strategic #7): Add note: “**Uncommitted:** `cgen_x_compiles_all_demos_cc_clean` passes with uncommitted Kittedy/QtboXb patches in `M selfhost/cgen.x` / `M cgen_cemitter_sync.rs`. HEAD 413feba alone may not reproduce 114/114.”

**RC-R7** (Correctness #4 + Strategic #8): Change “demo/lib differential 74 faithful” → “XBSourceLib differential (11 programs, Rust CEmitter path): 74 faithful — manual sweep, not named test. No behavioral differential on 15 core libs via either backend.”

**RC-R8** (Usability RC1 + RC3): Add **Library port-completion definition** (falsifiable) after banner: (a) Rust CEmitter 0 cc errors, (b) link-core-libs.sh ok, (c) Version$ smoke, (d) cgen.x 0 cc errors (Bar B), (e) behavioral differential (Bar C). Current: (a)–(c)=15/15 ✅, (d)=0/15, (e)=0/15. Add completion criteria per L11–L14 row.

**RC-R9** (Provenance RC1): Add `SHELL-CAPABILITY` + Xin row: `xb_shell` → `system()` + Xin* → real BSD sockets, no capability gate. Action: add `XB_ALLOW_SHELL`/`XB_ALLOW_NETWORK` flags or document “SHALL not be reached in smoke”.

**RC-R10** (Correctness #3 + Repro salvaged): Fix `cgen_cemitter_sync.rs` `cgen_x_compiles_all_demos_cc_clean` doc-comment: add “NOTE: Kittedy/QtboXb require post-emit string patches (found-array dual-use, TranslateStatement decl) in this harness; cgen.x alone does not emit compilable C for these demos.”

### Tests / Guards
**RC-T1** (Usability RC2 + Repro salvaged + Provenance RC2): Wire `checks/link-core-libs.sh /tmp/xblib-validate` into `checks/validate-all.sh` (after cargo test block) and clean `OUT` before link; test-lock LICENSE-BOUNDARY wording in `docs_headline_claims_are_recorded_at_named_surfaces` (add needles for `LICENSE-BOUNDARY` / `deferred — blocker`); fix link glob → use named `cc` loop order, not `$OUT/*.o` glob, for deterministic weak-symbol winner (L16).

**RC-T2** (Strategic #8 + Usability RC5): Add trigger/owner/escalation to every deferred row (L15-L17, CGEN-X-LIB-COMPILE, ATTACH-IMPL, SHELL-CAPABILITY).

## Shared Findings (agreed across lenses, observed/author-claimed/INFERENCE separated)

### Observed (re-measured)
- `cargo build --release` green (2.65s, 7 warnings: `suffix_vt`×2, `left_read`).
- `checks/link-core-libs.sh /tmp/xblib-review` → 1690 `xb_user_*` symbols, smoke `ALL OK` (7 Version$), 8.28s, ~15 × `Wc23-extensions` warnings in xst — **0 cc errors** via Rust CEmitter. Contradicts stale “28 errors” memory (now superseded).
- `cgen_cemitter_sync` 60/60 ok (106.62s) — **with** dirty Kittedy/QtboXb post-emit patches. Without patches, Kittedy fails at `xb_var_found` / `xb_d1_found` (1561, 1740) and QtboXb fails on `TranslateStatement(void)` forward decl.
- `parser.rs:718-724` ATTACH → empty Compound (Nop) in **all** backends — verified by Correctness lens.
- 1007 ATTACH sites in `xbasic-6.4.5/src`, 335 ARGV|OSERROR sites — verified by grep.

### Author-claimed (corroborated or re-measured)
- 114/114 demos compile via cgen.x — corroborated *with* dirty patches; HEAD alone not re-measured.
- 112/114 comparable / 2 I/O skips — author-claimed, not re-measured in this packet window (requires demo runtime harness).
- 15/15 libs link-clean — now observed via link-core-libs.sh.
- Byref descriptor DONE (docs/18) — corroborated for demo/XBSourceLib scale, but lib-scale parity not verified (docs/18’s own 4430 `@array[]` param count vs 74 demo differential).

### [INFERENCE] (explicitly marked, not observed)
- Weak-symbol first-definition-wins by glob order may be non-deterministic across platforms (L16).
- “Ready to port” ambiguity is a usability gap, not a code defect — packet is an internal engineering doc, not an adopter guide (Usability strongest objection).
- License boundary is not exploitable in local smoke but is distribution-blocking (Provenance).

## Disagreements / Residual Risks

**No hard DISAGREE.** All disagreements are about *framing*, not *fact*:

- **Category error vs. honest internal doc:** Correctness lens frames “ready to port” as category error (compile ≠ behavior). Usability counter-argues packet was never meant as adopter-facing surface — it’s an internal living document. **Residual risk:** Without an adopter guide (docs/20), external readers will misinterpret internal rows as deployment claims. **Mitigation:** RC-B1 + RC-R8 + docs/20 FAQ.

- **Test-harness patching vs. compiler bug:** Correctness lens treats Kittedy/QtboXb string replaces as masking cgen.x bugs, undermining the 114/114 claim. Strategic lens treats them as “uncommitted work that must be committed before adopt.” **Residual risk:** If patches are committed as harness fixes rather than compiler fixes, cgen.x will remain broken for any non-harness consumer. **Mitigation:** RC-R10 + requirement that patches be moved into `selfhost/cgen.x` or gated behind a real codegen fix, not left as test-side text surgery.

- **License test-lock:** Provenance wants LICENSE-BOUNDARY test-locked; current headline-claims test does not cover it. **Residual risk:** Silent removal without test failure. **Mitigation:** RC-T1.

- **3/7 salvaged verdicts:** Evidence/Arch/Repro lenses lost independent verdicts to hard quota. Their findings are coordinator-synthesized, not independent. **Residual risk:** Panel consensus strength is 4/7 independent, not 7/7. **Mitigation:** Label per-slice provenance above; re-run salvaged lenses as non-scout `task` workers if funding for independent judgment is required.

## Evidence Actually Checked (guardrail-compliant)

- **Packet read:** 102 lines at absolute `/Users/teee/dev/xbasic-remake/review-packet-legacy-lib-port-2026-08-28.md` — all lenses.
- **Repo state:** `git log --oneline -5` (413feba … 1b0bf40), `git status --short` (2 dirty files), `git branch --show-current` (main) — Evidence + Strategic.
- **Link-core script:** `checks/link-core-libs.sh` (65 lines), executed via `cargo build --release && checks/link-core-libs.sh /tmp/xblib-review` — observed 1690 symbols, tail + warnings — Strategic + Correctness + Provenance.
- **Legacy inventory:** `glob xbasic-6.4.5/src/**/*.x` (203), `xbasic-6.4.5/demo/*.x` (203), `xbasic-6.4.5/src/gtk/**/*.x` (203), `checks/validate-all.sh` (29 lines), `checks/verify-bootstrap.sh` — Evidence.
- **Tests:** `crates/xb-runtime/tests/cgen_cemitter_sync.rs:297-500` harness (post-emit patches at 337-370), `docs_headline_claims_are_recorded_at_named_surfaces` 7 needles — Correctness + Repro + Provenance (all 7 present).
- **Docs:** `docs/17-open-work-roadmap.md` (273 lines, two reads), `docs/18-byref-array-abi.md` (283 lines), `docs/19-cgen-facet-manifest.md` (193 lines) — all lenses.
- **Greps:** ATTACH @ `xbasic-6.4.5/src` (1007), ARGV|OSERROR (335), SHELL (24), `SHELL-CAPABILITY`/`Xin*` lowering in `c_emit_xin.rs:157+`, `c_runtime_bit.rs:97` `system()`, `c_emit.rs:1482` weak symbols, `parser.rs:718` ATTACH Nop — Correctness + Strategic + Provenance.
- **Not checked (explicitly not claimed):** `cargo test --release` full 274-suite re-run, `checks/validate-all.sh` full execution, `checks/verify-bootstrap.sh`, demo behavioral run, 15-lib cgen.x differential, `ARY-STATUS-RECONCILIATION` bounded ary run.

## Guardrails

- Do not claim named model personas were literally invoked — no provider calls occurred; lenses are role labels only.
- Do not let role labels override evidence — correctness gap (ATTACH Nop) is evidenced by `parser.rs:718-724`, not by lens title.
- Mock/unit self-test ≠ end-to-end: link-core smoke (7 Version$ strings) is not lib behavioral differential; demo 114/114 is compile-only, not run.
- Artifact 404s / license boundaries / data-egress are **adoption blockers, not footnotes**: SHELL → `system()`, Xin → real sockets, combined binary GPL-covered — documented but not gated.
- **Candidate Adoption Ledger (required — no partial adoption without ledger):**

| Change | ID | Status | Evidence before | Evidence after | Guard |
|---|---|---|---|---|---|
| Two-word cap header + deep copy + scan fixes (L11-L14) | L11-L14 | **partial** (fd0c8d4) — 08fc0cb landed | xcol SIGKILL 46.4s, xgr SIGABRT 3.4s, leaky whole-`s$` scans | 15/15 link-clean but xcol still SIGKILL; no benchmark for O(1) amortized | Deterministic guard: `xb_append` cap-retention benchmark + `scan_dyn` quote-skip regression (RC-T1) |
| ATTACH impl (array aliasing) | ATTACH-IMPL | **deferred** (open) | Parser Nop, 60+ sites across 5 libs | No change | Deterministic guard: ATTACH alias test + bounded ary differential (RC-T1) |
| cgen.x lib compile (15 libs) | CGEN-X-LIB-COMPILE | **open** (no test) | No `cgen_x_compiles_all_core_libs` | No test | Named test `cgen_x_compiles_all_core_libs_cc_clean` (RC-T1) |
| License boundary disclosure | L15 | **deferred — blocker** | No test-lock, README has 0 license mentions | Docs/17 row exists, not test-locked | Add needles to `docs_headline_claims_are_recorded_at_named_surfaces` + README `## License` (RC-T1/RC-B2) |
| Weak-symbol link determinism | L16 | **deferred** | Glob-order link, not named loop | No change | Fix link step to named loop order + `nm` provenance check (RC-T1) |
| GTK/helpsrc carve-out | LEGACY-CORPUS | **done** (carve-out) | Parse/lower-only, wording present | Test-locked in headline-claims test (7 needles) | Keep — no adoption needed |

- **Wrong-if-never-adopted clause:** Each ledger entry’s falsifiability clause is dead text without adoption. RC-T1 + RC-R8 make the ledger live by wiring deterministic guards; RC-R10 ensures 114/114 demo claim is not falsified by post-emit patching.

## Terse Lens Output Note

Three lenses returned only a summary (scout schema-coerced, 1-line `Now I have all the evidence…`) — DM via IRC was attempted (tier-1 `hub send` “woken”) but under hard quota the wake died silently and the agent parked with no new turn. Recovered via tier-2 (read `history://<id>`) and tier-4 (salvaged JSONL + coordinator checks) per skill recovery order (2026-07-27: 6/6 via tier 1; 2026-08-04: tiers 1,2,4; 2026-08-06: 7/7 via tier 1). All 4 delivered lenses are full markdown; 3 salvaged lenses are coordinator-synthesized over raw evidence.

---
*Synthesis by Main (merge-owner) — 2026-08-28. Packet at `/Users/teee/dev/xbasic-remake/review-packet-legacy-lib-port-2026-08-28.md` — delete after synthesis per skill.*
