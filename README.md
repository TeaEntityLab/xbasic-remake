# XBasic 6.5.0 remake and self-hosting toolchain

A modern, portable remake of the XBasic language, runtime, libraries, and
development environment. The project preserves legacy behavior where it is
observable while providing a maintainable toolchain for current platforms.

## Project charter

1. **Real self-hosting:** keep the Rust frontend and `CEmitter` as the
   reference/bootstrap implementation, and keep `selfhost/compiler.x` plus
   `selfhost/cgen.x` as the XBasic-native compiler path. Neither implementation
   is throwaway scaffolding.
2. **One contract, independent implementations:** both C generators implement
   the shared typed-IR and runtime ABI contract. Behavioral and ABI
   differential checks govern correctness; line-by-line textual mirroring is
   not the contract.
3. **Single-source semantic facts:** the frontend emits scope-qualified symbol
   facets for storage, rank, dual-use, and by-ref behavior. Generators consume
   those facts instead of reconstructing them with source-text heuristics.
4. **Compatibility and modern correctness:** tests cover observable original
   XBasic behavior, portable C execution, bootstrap closure, runtime safety,
   capability boundaries, and supported platforms. Test count is not a goal;
   each test must defend a named contract.
5. **Portable backend:** standard C and the system toolchain replace the
   original compiler's machine-code encoder, assembler, and object/link logic.
   Linux, macOS, and Win64 are the target platform families.

Explicit non-goals: demo-wide byte-identical generated C, re-creating the
legacy i486/ELF assembly backend, 32-bit binary compatibility with historical
runtime archives, and bit-exact x87 behavior unless compatibility evidence
requires it. Emitted-C identity remains a deliberately narrow diagnostic lock
for the positive corpus; bootstrap stages retain their separate fixed-point
identity requirements.

## Repository components

| Component | Role |
|---|---|
| `xb-frontend` | Lexer, parser, and XBasic syntax surface |
| `xb-compiler` | Semantic analysis, typed IR, Rust reference `CEmitter`, and optional LLVM backend (`llvm` feature; default off) |
| `xb-runtime` | Interpreter, runtime contracts, capability gates, and behavioral integration tests |
| `xb-link` | Object-link command construction for Unix and Win64 drivers |
| `xb-cli` | `xb` command for analysis, IR/C emission, execution, and native compilation |
| `xb-gui` | GDI-spirit drawing trait and deterministic framebuffer backend |
| `xb-ide` | eframe/egui IDE shell, feature-gated behind `eframe-app` |
| `selfhost/` | XBasic-native compiler and C generator used to prove and ship self-hosting |
| `xbasic/` | Ported upstream source corpus and compatibility reference, under its original licenses |

## Local verification

Core check, no LLVM required:

```sh
cargo check --workspace --exclude xb-ide
cargo test --workspace --exclude xb-ide
```

Note: several integration suites (demo parity, multi-lib link, sockets) invoke a
prebuilt `target/release/xb`; run `cargo build --release` first, or use
`./checks/validate-all.sh`, which builds and runs the whole release suite.

IDE stack check, requires Rust compatible with egui/eframe 0.36.1:

```sh
cargo check -p xb-ide --features eframe-app
```

LLVM backend check, requires LLVM 22 in `PATH` or `LLVM_SYS_221_PREFIX`:

```sh
cargo check -p xb-compiler --features llvm
```

On this machine, `rustc` in `PATH` is Homebrew Rust 1.94, while `rustup stable` is 1.97.1 after update. The IDE feature requires Rust ≥1.95 and was checked with explicit rustup cargo/rustc. Homebrew `llvm` is **22.1.8** (`/opt/homebrew/opt/llvm`); the LLVM backend builds and tests with `LLVM_SYS_221_PREFIX=/opt/homebrew/opt/llvm` but stays feature-gated off by default — `./checks/validate-all.sh` covers default features only (the CI LLVM job `llvm-build` in `bootstrap-verify.yml` covers `--features llvm` in CI).

## Verification status

> **Active development notice (2026-09-01):** the latest targeted run passed
> `cemitter_compiles_gtk_and_helpsrc_clean` but
> `cgen_x_compiles_all_demos_cc_clean` failed for 21 demos because generated C
> referenced undeclared `xb_label_Create`-class labels. The positive-corpus
> `fileio_test` golden mismatch is also under investigation. The dated results
> below are historical evidence, not a claim that the current working tree is
> green. Current defects and exit gates live in
> [docs/17-open-work-roadmap.md](docs/17-open-work-roadmap.md).

### Historical verification snapshot (2026-08-29)

- **All 15 core libraries compile cc-clean through the Rust CEmitter and via self-hosted cgen.x facet harness** (`xbasic/{lib,include}/*.x`) with `-O0 -Wno-incompatible-pointer-types -Wno-int-conversion` (cgen.x standalone script compiles 13/15; xcol/xui require facet manifest ingestion). This is compile-only; `ATTACH` has copy-semantics runtime in interpreter and Rust CEmitter (5 cases, `c_emit_attach.rs`/`interpreter_attach.rs`), but dynamic 2nd-dim arrays still no-op.
- **All 15 link in the internal test harness** — `checks/link-core-libs.sh` records 1979 `xb_user_*` symbols and seven `Version$` smoke checks, not compiled-body behavior.
- **The all-demo cgen guard reports 114/114** (`cgen_x_compiles_all_demos_cc_clean`) as a raw-generator contract — no post-emission C rewrites. Rust CEmitter `demo_parity` records 112 matches and two real-I/O skips.
- **81/81 positive-corpus programs** emit byte-identical C (locked by `cgen_cemitter_sync`).
- **Byte access `{}`** works on string scalars and array elements.
- **Historical full workspace (2026-08-31):** 308 passed / 0 failed across 33 binaries at that snapshot. `xbsourcelib_interp_matches_compiled` locks runtime parity for 11 non-ARY programs; the separate compile-only guard `xbsourcelib_ary_compiles_clean` compiles `ary` and `ary1.0001` cc-clean via shared `ARY_VAR_DATA` forwarding. ARY runtime behavior remains unproven and blocked on `ATTACH`.
- Self-hosting: compiler.x → cgen.x → native C generator; bootstrap fixed point and native/Rust IR parity remain locked.
- **SHELL/network capability gates (RR-09):** `SHELL` and `Xin*` socket builtins are denied by default; set `XB_ALLOW_SHELL=1` or `XB_ALLOW_NETWORK=1` to opt in. Applies to both interpreter and compiled C runtime.

## License

The remake's own code — all `crates/`, `selfhost/`, fixtures, checks,
scripts, and docs — is **MIT licensed** (`LICENSE`). The ported upstream
source material in `xbasic/` remains **GPL-2.0 / LGPL-2.1** (canonical
texts at `xbasic/COPYING` and `xbasic/COPYING_LIB`; per-file audit in
`xbasic/LICENSES.md`). `LICENSING.md` maps every directory and the
provenance rules.

The upstream library sources carry a mixture of GPL and LGPL headers.
Three Win32 compatibility shims (`gdi32`, `kernel32`, `user32`) carry no
copyright notice or license statement — they ship only as part of the
upstream release's tree-level distribution and must not be redistributed
separately.

`checks/link-core-libs.sh` combines GPL-header, LGPL-header, and no-notice
inputs into one `xblibs` artifact. Repository evidence is insufficient to
clear that artifact for redistribution; this is a provenance/compliance risk,
not a legal determination. The harness is strictly internal-test-only and
must not be packaged or redistributed without resolving shim provenance and
distribution obligations. See docs/17 L15/RR-11 and `LICENSING.md`.
