# 17 — Open-Work Roadmap (everything not done yet)

> Status: living umbrella roadmap. Consolidates known-but-undocumented gaps from
> working notes into one tracked place. Each item marks **provenance**:
> `[verified <session>]` = re-measured with a command shown; `[carried]` =
> from prior working notes, not re-measured here.
>
> Scoped sibling: [16-cgen-cemitter-sync-roadmap.md](16-cgen-cemitter-sync-roadmap.md)
> (the two C generators). Progress narrative: [14-self-hosting-progress.md](14-self-hosting-progress.md).

## 1. Backends

### LB-STUB — LLVM backend emits an empty object `[verified]`
`crates/xb-compiler/src/lib.rs` `llvm_backend::LlvmBackend::compile` lowers the
IR then returns `ObjectFile::from_bytes(Vec::new())` — no real object emission.
Default backend is `DisabledLlvmBackend` → `CompileError::LlvmDisabled`
(`XB-B001`). Work: implement inkwell IR → `TargetMachine::write_to_file`
(ELF/COFF/Mach-O). Reference: `docs/12-rust-llvm-rewrite-survey.md §3.1`.

### LB-TOOLCHAIN — LLVM 22 absent locally `[verified]`
`cargo check -p xb-compiler --features llvm` fails: *"No suitable version of LLVM
… LLVM_SYS_221_PREFIX"*. Only Homebrew `llvm@21` (21.1.8) is installed; the
`inkwell` feature is pinned to `llvm22-1`. Work: install LLVM 22 (or set
`LLVM_SYS_221_PREFIX`) locally, and add a CI job that has LLVM 22 so the `llvm`
feature is actually built/tested (today it is compiled nowhere).

### JIT-X87 — FPU-intrinsic JIT not implemented `[verified]`
No JIT crate is present (`iced-x86` / `dynasm` absent from `Cargo.lock`). The
x87 FPU-intrinsic JIT (old `xlib.s` FSIN/FCOS/FPREM/…) is deferred; runtime math
uses plain `f64`. Only pursue if exact x87 compat semantics are ever required
(`docs/12 §3.2`).

## 2. Runtime semantics

### RT-BYTESTRING — strings are Rust UTF-8, not bytes `[carried]`
`RuntimeValue::String` is a Rust `String`; `CHR$(>127)`, byte-level `MID$`,
brace `{}` byte access, and binary record I/O on non-ASCII data are imperfect
(guarded against panics, not correct). Full fix = represent strings as `Vec<u8>`
(~85 `RuntimeValue::String` sites to migrate). Blocks faithful `acharmap.x` and
high-byte legacy data. Interacts with CG-COVER (high-byte C codegen).

### RT-KERNEL32 — kernel32/stdio stubs for `acgibin` `[carried]`
`acgibin.x` needs `GetStdHandle`/`ReadFile`/`WriteFile` and the handle constants
`$$STD_INPUT_HANDLE=-10` / `$$STD_OUTPUT_HANDLE=-11`. Not implemented in the
interpreter runtime.

### RT-FUNCPTR — function-pointer calls (`afuntype`) `[carried]`
`afuntype.x` exercises calling through function pointers (`FUNCADDR` values used
as call targets). Parsing/lowering exist; runtime dispatch through a
function-pointer value does not.

## 3. Frontend / migration coverage

### MIG-CORPUS-GATE — legacy parse coverage is not a test `[carried]`
Combined parse coverage is **204/204** (151 `xbasic-6.4.5/*.x` + 13
`XBSourceLib/*.x` + 40 `XBSourceLib` source `.txt`), measured on demand, but **no
test gates it** — it is a manual metric. Honest metric = `rc == 0` from
`xb --emit-ir <file>` (a real parse error → non-zero exit); never "non-empty
output" and never a min-IR-line threshold (false-fails tiny files). Work: add a
corpus regression test that walks both trees and asserts `rc == 0` + non-swallow
(a `>20`-source-line file must emit `>2` IR lines).

### MIG-SEMANTICS — coverage is parse/IR only `[carried]`
204/204 is *lowering to IR*, not full analyze/run. Many legacy files are not yet
exercised through the interpreter or C backend. Next: pick core-lib entry points
(e.g. `MscRandom`, `GeoArcTan`) and add run-level fixtures.

## 4. Demos / GUI

### DEMO-RUNTIME — ~69/114 demos run clean `[carried]`
Last measured (prior session): ~69 of ~114 `xbasic-6.4.5/demo/*.x` reach a clean
exit; ~38–40 are GUI message-loop timeouts (out of scope until a GUI runtime
exists); the rest are diverse (network `aclient`/`aserver`; `DrawScaled`
div-by-zero; `acgibin` → RT-KERNEL32; a few GUI stack overflows). Re-measure
before trusting these counts. GUI runtime (winit + softbuffer GDI-shim, per
`docs/12`) is a large separate effort, intentionally deferred.

## 5. Cross-references

- Two-C-generator drift and byte-identity: **16-cgen-cemitter-sync-roadmap.md**.
- Backend rationale / crate survey: **12-rust-llvm-rewrite-survey.md**.
- Stage status and decisions: **13-bootstrap-scaffold.md**, **14-self-hosting-progress.md**.
