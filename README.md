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

IDE stack check, requires Rust compatible with egui/eframe 0.36.1:

```sh
cargo check -p xb-ide --features eframe-app
```

LLVM backend check, requires LLVM 22 in `PATH` or `LLVM_SYS_221_PREFIX`:

```sh
cargo check -p xb-compiler --features llvm
```

On this machine, `rustc` in `PATH` is Homebrew Rust 1.94, while `rustup stable` is 1.97.1 after update. The IDE feature requires Rust ≥1.95 and was checked with explicit rustup cargo/rustc. LLVM 22 is not installed (`llvm@21` is present), so the LLVM backend is intentionally feature-gated off by default.

## Verified capabilities (2026-08-26)

- **All 15 core libraries compile cc-clean** (`xbasic-6.4.5/src/{shared,linux}/*.x`)
- **All 15 link into one working binary** — `checks/link-core-libs.sh`
- **114/114 demo programs** emit + compile through both the Rust CEmitter and self-hosted `cgen.x`
- **80/80 positive-corpus programs** emit byte-identical C from both C generators
- **Byte access `{}`** on string scalars and array elements
- **INC/DEC + SWAP subscripts** on indexed/composite targets
- **274 tests across 33 binaries**, 0 failures (`./checks/validate-all.sh`)
- Self-hosting: compiler.x → cgen.x → native C generator (bootstrap fixed point held)
