# 13 — 6.5.0 Bootstrap Scaffold

> Status: Stage-0 scaffold created at the repository root (`../`).
> Decisions recorded from the maintainer on 2026-08-14.

## Resolved decisions

| Topic | Decision | Consequence |
|---|---|---|
| FP intrinsics | Plain `f64` / libm-style operations by default | x87 exactness and `iced-x86` JIT are deferred until compatibility tests prove they matter |
| Windows target | Win64 first | Compiler/runtime work targets `x86_64-pc-windows-msvc`; i686 remains a future option, not stage-0 scope |
| Self-hosting | Rust stage-0, then staged XBasic self-host | Keep lexer/parser/runtime/library contracts simple enough to port to XBasic later |

## Stage plan

1. **Stage 0 — Rust host:** Rust owns lexer, parser, codegen boundary, runtime ABI, exception maps, linker driver, GUI shell, and deterministic tests. ✅ Complete.
2. **Stage 1 — utility self-hosting:** XBasic compiler sources (compiler.x, cgen.x, lexer.x, parser.x) are written in XBasic and compiled to native executables via the Rust C code generator. ✅ Complete.
3. **Stage 2 — compiler self-hosting:** The native compiler (compiler.x → C → cc) rebuilds itself without the Rust host, producing byte-identical IR (SHA-256 fixed point `f6e21a03…`). The C generator (cgen.x) self-compiles. ✅ Complete.
4. **Stage 3 — optional backend split:** LLVM remains the primary AOT backend; Cranelift can be revisited as a Win64/Linux/macOS debug backend only after the language semantics are stable. (Deferred — LLVM 22 not available locally; C code generator serves as the working native backend.)

## Workspace layout

```text
../
├── Cargo.toml
├── README.md
├── docs/
├── xbasic-6.2.3/     historical baseline tree
├── xbasic-6.3.26-D/  historical Win32 fork
├── xbasic-6.4.5/     historical Linux 64-bit fork
└── crates/
    ├── xb-frontend/   tokens + lexer
    ├── xb-compiler/   codegen trait + optional inkwell LLVM backend
    ├── xb-runtime/    XxxMain ABI, exception maps, f64 math defaults
    ├── xb-link/       linker command construction
    ├── xb-cli/        `xb` parser/analyzer/lowerer CLI
    ├── xb-gui/        GDI-shim trait + software framebuffer
    └── xb-ide/        feature-gated eframe/egui shell
```

## Verification target

The first scaffold must pass without LLVM installed:

```sh
cargo check --workspace --exclude xb-ide
cargo test --workspace --exclude xb-ide
```

Optional checks:

```sh
cargo check -p xb-compiler --features llvm
cargo check -p xb-ide --features eframe-app
```

On the current machine, `rustc` in `PATH` is Homebrew Rust 1.94, while `rustup stable` is 1.97.1 after update. The IDE feature requires Rust ≥1.95 and checks with explicit rustup cargo/rustc. LLVM 22 is not installed (`llvm@21` is present), so LLVM is intentionally default-off.
