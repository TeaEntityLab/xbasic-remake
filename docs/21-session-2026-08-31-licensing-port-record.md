# 21 — Session record 2026-08-31: licensing, tracked `xbasic/` port, MIT split

> Purpose: full knowledge capture of the 2026-08-31 session (license
> boundary → tracked corpus port → MIT relicense → milestone plan) so a
> fresh session can resume without re-deriving anything. Companion to the
> docs/17 ledger rows (SOURCE-COVERAGE, DEC-FILE-PROCESSING,
> TRACKED-CORPUS-PORT, RR-11) and docs/20 (milestone plan).

## 1. Commits landed (chronological)

| Commit | What |
|---|---|
| `39cd037` | Full `.dec` processing (parser `is_forward` `$$`-constant fix gated on `is_external`; CLI `resolve_import_decls()` TYPE+EXTERNAL injection via `FrontendUnit::with_extra_statements`) + `.s`/`.a` source-coverage guards |
| `0e3a0e6` | License boundary: canonical GNU texts at root (later moved), `LICENSING.md`, LGPL isolation in the local 6.4.5 tree, `source_coverage.rs` skip-if-absent |
| `a0eb09a` | **Tracked `xbasic/` port** — 276 files, 259-file tree (9.4M), all test/check paths repointed, XBSourceLib skip-if-absent, composite-decl injection filter |
| `62c617b` | **MIT relicense** of all original code; root `LICENSE`; GNU texts scoped into `xbasic/` |
| `c921b86` | docs/20 port-completion milestone roadmap (M1–M6) |

## 2. User intent evolution (why things are the way they are)

1. Legacy trees were gitignored **deliberately**: plan was "finish compiler
   first, then handle licensed XBasic & C99 codes".
2. That point arrived → "check all licenses and port everything into 6.5.0
   version DIRs; reconsider the DIR structures".
3. Mid-port: versioned dir name rejected ("what if 6.5.1 or 6.6.0?") →
   renamed to version-neutral **`xbasic/`**. Frozen upstream snapshots keep
   versioned names and stay gitignored local-only.
4. "Make all of new rewritten parts be MIT licensed as possible" → MIT for
   everything original; upstream material stays GPL-2/LGPL-2.1.

## 3. The tracked `xbasic/` tree

Layout (reorganized from upstream; shared/linux split dropped because the
Rust backend is cross-platform):

```
xbasic/
  COPYING (GPL-2.0), COPYING_LIB (LGPL-2.1)   canonical GNU texts (fetched
                                              from gnu.org — upstream's own
                                              copies lack title/Preamble)
  LICENSES.md      generated per-file header audit + provenance caveats
  lib/             15 core .x + 11 same-dir .dec  (from src/{shared,linux})
  include/         32 .dec (clib, xlib, xwin, elf*, gtk/glib API decs)
  demo/            133 .x + small data (incl. demo/gtk/)
  crtl/            upstream LGPL C ports (Wade Maxfield 2000) — the ONLY
                   canonical location for LGPL-derived C code
  helpsrc/  help/  templates/  tools/  doc/{CHANGES,README.Linux}
```

- **Verbatim port — do not edit ported files.** Two load-bearing reasons:
  GPL §2(a) change notices would be required for modified files, and
  behavior tests assert upstream values (e.g. `XstVersion$()="6.4.5"`).
  The tree already includes the one legitimate source fix (`xst.x`
  XstDecomposePathname DECLARE `@` markers) because the port copied the
  locally-fixed file — commit `e7591f8` had claimed that fix but could not
  actually track it (tree was gitignored); the port rescued it.
- **Excluded and why**: generated `.s` assembly (36M compiler output —
  replaced by Rust backends), `src/bin` (16M binaries), `.o`/`.a`, legacy
  Makefiles/`xbasic.spec` (build system is cargo), `images/` (artwork,
  non-source), XBSourceLib (**no license statement anywhere** → cannot be
  redistributed; stays gitignored local-only).
- `.x` count conservation: 18 src (15 libs + 3 helpsrc) + 133 demo = **151**,
  same as the legacy floor in `legacy_corpus.rs`.
- `.gitignore` patterns are `xbasic-6.2.*/`, `xbasic-6.3.*/`, `xbasic-6.4.*/`,
  `XBSourceLib` — `xbasic/` matches none, hence tracked automatically.
- `.gitattributes` forces eol only on specific listed paths — ported files
  are byte-identical through git (verified reasoning, no normalization).

### License scan results (in `xbasic/LICENSES.md`)

Per-dir class counts: lib = 9 LGPL + 3 GPL (`xit.x`,`xdis.x`,`xcol.x`) +
14 NO-NOTICE (the 3 shims + most `.dec`); demo = 130 NO-NOTICE + 2 LGPL
(`Kittedy`,`CursorEdit`) + 1 GPL (`qbtoxb`); include = 5 LGPL + 16
NO-NOTICE; crtl = 5 LGPL. NO-NOTICE files ship solely under the upstream
release's tree-level distribution. The 3 shims (`gdi32.x`/`kernel32.x`/
`user32.x`) are the RR-11 legal residue — never redistribute separately.

## 4. Path repoint map (applied via sed; for repeat/revert)

| Old | New |
|---|---|
| `xbasic-6.4.5/src/shared` | `xbasic/lib` |
| `xbasic-6.4.5/src/linux` | `xbasic/lib` |
| `xbasic-6.4.5/src/helpsrc` | `xbasic/helpsrc` |
| `xbasic-6.4.5/demo` | `xbasic/demo` |
| `xbasic-6.4.5/include` | `xbasic/include` |
| bare `xbasic-6.4.5` (corpus root, cli.rs) | `xbasic` |
| `["src/shared", "src/linux"]` list in `cgen_cemitter_sync.rs` | `["lib"]` |

Files touched: `legacy_corpus.rs`, `c_emit.rs` (xst path test),
`cgen_demo_regression.rs`, `pure_lib_behavior.rs`, `demo_parity.rs`,
`cgen_cemitter_sync.rs`, `xin_sockets.rs`, `stateful_lib_behavior.rs`,
`cli.rs`, `checks/{cgen-lib-compile,link-core-libs}.sh`, `xst.rs`
(help/*.hlp doc refs only).

**Deliberately NOT repointed**: `source_coverage.rs` (guards the local
6.4.5 `.s` tree — `xbasic/` has no `.s` by design; skips when tree absent,
skips `old-versions/`), and `xst.rs`'s `xlib.s` reference-asm doc pointer
(the `.s` was not ported).

## 5. Import resolution analysis (why the CLI resolver was NOT touched)

`resolve_import_constants`/`resolve_import_decls` candidate order: same-dir
`.x` → same-dir `.dec` → `../shared/*.x` → `../../include/*.dec` →
`../include/*.dec`. From `xbasic/lib/`: same-dir `.x` resolves all lib
imports (previously via `../shared`), `../include/*.dec` resolves `clib`
etc. **No code change needed.** From `demo/`: lib imports NEVER resolved
(old layout: `../shared` didn't exist from `demo/` either) — adding a
`../lib` candidate would let demos suddenly resolve lib constants/decls and
**change demo C emission**, breaking interp-vs-cgen parity goldens. Left
unchanged on purpose; revisit only with a full demo-parity re-measure.

## 6. Bug found by the port (and its temporary fix)

Flat `lib/` made `xcm.dec` a same-dir candidate for `xit.x` (previously
unreachable from `src/linux/`). `resolve_import_decls` then injected
`EXTERNAL FUNCTION DCOMPLEX DCACOS (DCOMPLEX z)` etc. → CEmitter emitted
composite-return handling for **import-only** functions: declared
`xb_dcomplex xb_var_DCACOS = {0}` then assigned from nonexistent flattened
`xb_var_DCACOS_R/_I` → cc errors. Root cause: composite call ABI does not
cover import-only functions (docs/18 / RR-08 territory).

Fix (in `crates/xb-cli/src/lib.rs`, `resolve_import_decls`): inject only
scalar-signature forward decls — guard
`f.return_type_name.is_none() && f.params.iter().all(|p| p.type_name.is_none())`,
with an RR-08 comment. **docs/20 M1 exit gate removes this filter** once the
composite ABI covers import-only functions.

## 7. MIT relicense — facts and reasoning

- Root `LICENSE`: MIT, Copyright (c) 2026 John <johnteee@gmail.com> (sole
  git author, 754 commits). Covers `crates/*`, `selfhost/`, `fixtures/`,
  `checks/`, `scripts/`, `docs/`.
- All 7 `Cargo.toml`: `license = "MIT"` (was GPL-2.0-or-later for
  compiler/frontend/cli/ide/link; LGPL-2.1-or-later for runtime/gui).
- Pre-flip audit: `grep -riE "max reason|maxfield|unspas"` over the new
  trees → zero hits (no copied/translated upstream code). Dep licenses all
  permissive: thiserror/libc/sha2 (MIT|Apache-2.0), inkwell (Apache-2.0),
  eframe/egui/egui_dock/egui_code_editor (MIT|Apache).
- Root `COPYING`/`COPYING_LIB` **removed** — GNU texts live only in
  `xbasic/` so license scanners see MIT root + GPL/LGPL subtree.
- Legal shape (recorded in LICENSING.md rules): copyright holder may
  relicense own original work; MIT→GPL combination direction is fine;
  derivative-of-upstream must stay upstream-licensed; compiling GPL sources
  with the MIT toolchain propagates nothing; programs linking ported
  `xbasic/lib`/`crtl` inherit GPL/LGPL for those parts only.
- Future rule: code translated from `xlib.s`/`crtl/*.c` can NEVER be MIT —
  GUI shim work (docs/20 M3) must implement from call signatures, not shim
  sources.

## 8. Local-only state (exists on THIS machine, not in git)

The gitignored `xbasic-6.4.5/` tree carries uncommittable hygiene from this
session: pure-reference `.c` stubs beside the 6 infrastructure `.s` files
(`appstart`, `xstart`, `xzzz`, `xlib` + dated pair) and
`src/linux/lib/old-versions/{xlib230325.s,xlib230803.s,README}` (superseded
snapshots isolated). Other machines won't have this; `source_coverage.rs`
skips when the tree is absent, so nothing breaks. Recreate from this doc +
docs/17 SOURCE-COVERAGE row if ever needed.

## 9. CI truth

- Before the port: `cargo test -p xb-compiler` in CI (bootstrap-verify LLVM
  job, line ~113) would have failed `legacy_corpus` (hard floor ≥151 on a
  gitignored tree; CI never downloads it). The port makes the corpus
  tracked → those tests now run for real in CI.
- XBSourceLib floors (≥13 `.x`, ≥40 source `.txt`) and the combined ≥204
  floor now apply only when `XBSourceLib/` exists; tracked-only floor is 151.

## 10. Verified state at session end (`c921b86`)

- compiler: lib 70, dec_processing 4, legacy_corpus 1, source_coverage 2
- runtime: pure 6 tests / 303 checks, stateful 1 / 128 checks,
  cgen_demo_regression 27/27, cgen_cemitter_sync 63/63 (incl. positive
  corpus 81/81 byte-identity, core libs 15/15 cc-clean)
- cli 7; clippy clean; fmt clean
- Suite timings (Apple M3, release): pure+stateful ~4s; demo regression
  16–40s; sync full ~128s (core-libs test alone ~110s — run with ≥300s
  timeout); positive corpus alone ~42s.

## 11. Open threads (ordered, see docs/20 for the full plan)

1. **M1 entry** (docs/20 §5): facet-manifest skeleton → SHARED-array
   globals → byref descriptor spike (`aarray_ISNODE` + `XstQuickSort`).
2. Remove the §6 composite-injection filter when M1's ABI lands.
3. RR-11 legal residue: 3 no-notice shims; `xblibs` internal-test-only.
   M3 stage 3 likely retires the question (shims' called subset becomes
   native builtins; shim sources then unnecessary for binaries).
4. Demo import resolution (§5) — only with a demo-parity re-measure.
5. RR-14 external tracker reconciliation still access-blocked.
