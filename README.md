# XBasic 6.5.0 Rust bootstrap

This is the stage-0 Rust workspace for bootstrapping XBasic 6.5.0.

Resolved decisions:

1. **Floating point:** use plain `f64`/libm-style operations by default. Exact x87 JIT behavior is deferred unless compatibility tests prove it is required.
2. **Windows:** focus on **Win64** first. Linux and macOS remain first-class targets.
3. **Self-hosting:** use Rust as the stage-0 host, keep compiler layers clean enough to port back into XBasic later, and start self-hosting from low-level utility/library surfaces before attempting a compiler-in-XBasic stage.

## Workspace crates

| Crate | Role |
|---|---|
| `xb-frontend` | Tokens and lexer for the XBasic syntax surface |
| `xb-compiler` | Typed compiler boundary and optional LLVM backend (`llvm` feature; default off) |
| `xb-runtime` | `XxxMain` entry contract, exception mappings, f64 math defaults, fault-hook skeletons |
| `xb-link` | Object-link command construction for Unix and Win64 drivers |
| `xb-cli` | `xb` command that parses/analyzes/lowers `.x` files and prints stable IR summaries |
| `xb-gui` | GDI-spirit drawing trait and deterministic framebuffer backend |
| `xb-ide` | eframe/egui IDE shell, feature-gated behind `eframe-app` |

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

## Recorded verification state (2026-08-29)

- **All 15 core libraries compile cc-clean through the Rust CEmitter and via self-hosted cgen.x facet harness** (`xbasic/{lib,include}/*.x`) with `-O0 -Wno-incompatible-pointer-types -Wno-int-conversion` (cgen.x standalone script compiles 13/15; xcol/xui require facet manifest ingestion). This is compile-only; `ATTACH` has copy-semantics runtime in interpreter and Rust CEmitter (5 cases, `c_emit_attach.rs`/`interpreter_attach.rs`), but dynamic 2nd-dim arrays still no-op.
- **All 15 link in the internal test harness** — `checks/link-core-libs.sh` records 1736 `xb_user_*` symbols and seven `Version$` smoke checks, not compiled-body behavior.
- **The all-demo cgen guard reports 114/114** (`cgen_x_compiles_all_demos_cc_clean`) as a raw-generator contract — no post-emission C rewrites. Rust CEmitter `demo_parity` records 112 matches and two real-I/O skips.
- **81/81 positive-corpus programs** emit byte-identical C (locked by `cgen_cemitter_sync`).
- **Byte access `{}`** works on string scalars and array elements.
- **INC/DEC + SWAP subscripts** work on indexed/composite targets.
- **Full workspace:** 308 passed / 0 failed across 33 binaries. `xbsourcelib_interp_matches_compiled` locks runtime parity for 11 non-ARY programs; the separate compile-only guard `xbsourcelib_ary_compiles_clean` compiles `ary` and `ary1.0001` cc-clean via shared `ARY_VAR_DATA` forwarding. ARY runtime behavior remains unproven and blocked on `ATTACH`.
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
