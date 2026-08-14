# 14 — Self-Hosting Progress

> Status: Stage-0-to-Stage-1 bootstrap backlog completed and verified on 2026-08-14.
> This closes the current Stage-0-to-Stage-1 backlog; it does not equal full compiler self-hosting.

## 1. Scope and status

Stage 0 is the Rust-hosted frontend, semantic analyzer, typed IR, deterministic text IR emitter, runtime substrate, ABI scaffold, and verification suite. Stage 1 currently consists of a minimal XBasic utility artifact accepted by the Rust-hosted parse, analyze, and lower pipeline.

Backlog items 1 through 14 provide the implementation and executable evidence. Item 15 records that evidence and its boundary. Completion does not prove compiler self-hosting, native object emission, linked executable production, platform parity, or production readiness.

## 2. Resolved architecture decisions

| Topic | Decision |
|---|---|
| Floating point | Plain Rust `f64` and libm-style behavior are the default. Exact x87/JIT compatibility remains deferred until compatibility tests require it. |
| Initial Windows target | Win64 first. Linux and macOS remain first-class intended targets. |
| Self-host path | Rust is Stage 0. Utility and library surfaces move to XBasic before the compiler does. |
| LLVM | LLVM remains the intended AOT backend, but its feature is default-off. |
| Runtime ABI | Preserve the `XxxMain(argc, argv, envp, envx, main_fn, start_app)` contract rather than the unfinished historical C implementation. |
| GUI | Start with a typed GDI-shim surface and deterministic framebuffer; exact Win32 parity remains future work. |
| Historical home path | The hard-coded `/home/cw` behavior is not preserved. |

These decisions originate in [the rewrite survey](12-rust-llvm-rewrite-survey.md) and [the bootstrap scaffold](13-bootstrap-scaffold.md).

## 3. Exact Stage-0 pipeline

The CLI/compiler path is:

```text
.x source
→ std::fs::read_to_string
→ FrontendUnit::parse
→ xb_frontend::parse_program
→ Analyzer::analyze
→ IrProgram::lower
→ TextIrEmitter
→ deterministic textual IR summary
```

The implementation is in `crates/xb-cli/src/lib.rs`, `crates/xb-compiler/src/lib.rs`, `crates/xb-compiler/src/ir.rs`, and `crates/xb-compiler/src/text_ir.rs`.

The separate runtime path is:

```text
IrProgram
→ Interpreter::execute or Interpreter::execute_main
→ metadata plus typed slots
→ assignment evaluation
→ PRINT output sink
```

The runtime path is implemented in `crates/xb-runtime/src/interpreter.rs`. The current CLI prints IR; it does not invoke the interpreter, emit an object, or link an executable.

## 4. Implemented typed IR, interpreter, and Main capabilities

The implemented typed IR supports `Version`, `Print`, typed `Dim`, typed `Assignment`, and `Function` items. Expressions support string, integer, and float literals plus typed symbol references. The text emitter records symbol and expression types deterministically.

The interpreter:

- retains version metadata and typed slots;
- initializes integer slots to `0`, float slots to `0.0`, and string slots to an empty string;
- validates assignment target and value types;
- renders supported values into a caller-supplied output vector;
- reports duplicate slots, unknown slots, type mismatches, invalid literals, and missing entries as typed errors;
- resolves function entries with exact case, so `Main` succeeds while `main` does not; and
- executes top-level non-function items before the exact `Main` body in the same state, while leaving other function bodies unentered.

The relevant implementations are `crates/xb-compiler/src/ir.rs`, `crates/xb-compiler/src/entry_lookup.rs`, and `crates/xb-runtime/src/interpreter.rs`. The safe exported `XxxMain` callback scaffold exists in `crates/xb-runtime/src/entry.rs`, but it is not yet a generated-program execution pipeline.

## 5. Stage-1 xut manifest provenance and limitations

`selfhost/xut_bootstrap_manifest.x` is a static historical manifest. The historical `xut.x` utility declares the `xut` identity, version `0.0001`, Linux system ID `1`, and Win32 system ID `2`; the Stage-1 source preserves those values within the currently supported syntax.

The exact IR proof is `cli_prints_stable_ir_for_static_xut_bootstrap_manifest`. The recursive corpus proof is `cli_accepts_every_selfhost_source`.

The boundary is intentionally narrow:

- IDs `1` and `2` are historical constants, not runtime platform detection.
- The manifest does not implement `XutInit`, imports, exports, library behavior, or OS selection.
- It is currently the only `.x` file under `selfhost/`.
- The smoke test proves every current selfhost source is accepted by the CLI pipeline, not that each source executes correctly.
- No test feeds this committed manifest to `Interpreter::execute_main`.
- No compiler component is written in XBasic.
- No LLVM object or executable is produced.

## 6. Verifier evidence

A fresh `./checks/verify-bootstrap.sh` run on 2026-08-14 passed with this nonzero-test distribution:

| Crate or target | Passing tests |
|---|---:|
| `xb-cli` unit | 2 |
| `xb-cli` `tests/cli.rs` | 2 |
| `xb-cli` `tests/selfhost.rs` | 1 |
| `xb-compiler` unit | 16 |
| `xb-frontend` unit | 13 |
| `xb-gui` unit | 1 |
| `xb-link` unit | 2 |
| `xb-runtime` unit | 6 |
| `xb-runtime` `tests/interpreter.rs` | 10 |
| **Total** | **53** |

Zero-test binaries and doctest targets do not increase this total.

The verifier runs:

```sh
cargo fmt --all -- --check
cargo check --workspace
cargo test --workspace
cargo clippy --workspace --all-targets
```

It additionally enforces:

- no obsolete nested workspace directory or stale nested-tree documentation references;
- no real `unsafe {}`, `unsafe fn`, or `unsafe impl` in Rust crates;
- at most 250 nonblank, non-comment pure LOC per Rust source file; and
- presence of required parser, semantic, typed-IR, fixture, CLI, manifest, and recursive selfhost-test milestones.

## 7. Platform and toolchain limitations

- Workspace MSRV is Rust 1.94.
- The current environment records Homebrew Rust 1.94 and rustup stable 1.97.1.
- The IDE feature needs Rust 1.95 or newer.
- LLVM 22 is absent locally; LLVM 21 is installed.
- `xb-compiler` uses `default = []`, so LLVM is opt-in.
- The feature-gated LLVM implementation currently returns an empty `ObjectFile`; real object emission is not implemented.
- `cargo check -p xb-compiler --features llvm` is outside the successful default verifier and cannot be claimed locally without LLVM 22.
- Rust LSP diagnostics repeatedly timed out. Compiler, Clippy, and verifier results are the authoritative local evidence.
- Verification is local only. Linux, macOS, and Win64 cross-platform bootstrap evidence does not yet exist.

## 8. Remaining Stage-2 compiler-self-host tasks

| Stage-2 task | Falsifiable completion criterion |
|---|---|
| Freeze the compiler subset | A versioned language/IR contract and corpus define accepted syntax, semantic errors, deterministic IR, and runtime behavior. |
| Implement real Stage-0 artifact production | The Rust host emits a nonempty target-native object, links a runnable compiler artifact, and passes object-format and execution tests. |
| Write compiler components in XBasic | XBasic sources implement the frozen parser, analyzer, typed lowering, and backend boundary and pass positive and negative corpus tests. |
| Rust-hosted stage build | The Rust Stage-0 toolchain compiles the XBasic compiler sources into a runnable Stage-1 compiler artifact. |
| Self-rebuild | The Stage-1 compiler consumes the same compiler sources and produces a runnable Stage-2 compiler artifact. |
| Artifact equivalence | Stage-1 and Stage-2 pre-link artifacts have identical SHA-256 hashes. If linker metadata is nondeterministic, byte equality is required before linking and executable behavior is compared separately. |
| Behavioral equivalence | Rust-hosted and self-rebuilt compilers produce identical output, diagnostics, exit status, and generated-program behavior over the frozen corpus. |
| Cross-platform evidence | Linux, macOS, and Win64 CI independently complete stage build, self-rebuild, and equivalence checks and archive commands, versions, hashes, and test output. |

Stage 2 is incomplete until every row passes. These criteria do not imply production readiness or full language, runtime, IDE, or library parity.

## 9. Completion boundary

This closes the current Stage-0-to-Stage-1 backlog; it does not equal full compiler self-hosting.
