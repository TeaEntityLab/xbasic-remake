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

On this machine, `rustc` in `PATH` is Homebrew Rust 1.94, while `rustup stable` is 1.97.1 after update. The IDE feature requires Rust ≥1.95 and was checked with explicit rustup cargo/rustc. Homebrew `llvm` is **22.1.8** (`/opt/homebrew/opt/llvm`); the LLVM backend builds and tests with `LLVM_SYS_221_PREFIX=/opt/homebrew/opt/llvm` but stays feature-gated off by default — `./checks/validate-all.sh` covers default features only (no `--features llvm`, no CI LLVM job yet; see docs/17 LLVM-CI-BITROT).

## Recorded verification state (2026-08-29)

- **All 15 core libraries compile cc-clean through the Rust CEmitter** (`xbasic-6.4.5/src/{shared,linux}/*.x`) with `XB_WEAK_SYMBOLS=1 -O0 -Wno-incompatible-pointer-types -Wno-int-conversion`. This is compile-only; `ATTACH` is parser-discarded in xcol/xst/xgr/xui/xit.
- **All 15 link in the internal test harness** — `checks/link-core-libs.sh` records 1736 `xb_user_*` symbols and seven `Version$` smoke checks, not compiled-body behavior. Self-hosted cgen.x has a test-locked 9/15 floor; 15/15 remains open.
- **The all-demo cgen guard reports 114/114** (`cgen_x_compiles_all_demos_cc_clean`), but currently applies test-local post-emission C rewrites for Kittedy and qbtoxb. Raw self-hosted cgen.x 114/114 is RR-13 in docs/17. Rust CEmitter `demo_parity` records 112 matches and two real-I/O skips.
- **80/80 positive-corpus programs** emit byte-identical C (locked by `cgen_cemitter_sync`).
- **Byte access `{}`** works on string scalars and array elements.
- **INC/DEC + SWAP subscripts** work on indexed/composite targets.
- **Full workspace:** 282 passed / 0 failed across 33 binaries. `xbsourcelib_parity` now passes for `ary`/`ary1.0001` (shared `ARY_VAR_DATA` forwarding via `is_shared_array` → `emit_raw_array_name`); both remain compile-only and not runtime proof.
- Self-hosting: compiler.x → cgen.x → native C generator; bootstrap fixed point and native/Rust IR parity remain locked.

## License

The original XBasic source tree (`xbasic-6.4.5/`) is dual-licensed: GPL for the
compiler/IDE (`COPYING`), LGPL for the function libraries (`COPYING_LIB`).
Three Win32 shim libraries (`gdi32`, `kernel32`, `user32`) carry no license
notice. The remake crates split `GPL-2.0-or-later` (compiler/IDE/linker) vs
`LGPL-2.1-or-later` (runtime/GUI). `checks/link-core-libs.sh` links all 15
libraries into one binary; the combined work is GPL-covered. See docs/17
LICENSE-BOUNDARY row for the full disclosure. Local `link-core-libs.sh` runs
are run-only; distribution without GPL notices is not allowed.
