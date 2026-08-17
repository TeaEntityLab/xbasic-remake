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

### LB-TOOLCHAIN — LLVM feature builds nowhere; concrete unblock path `[verified]`
`cargo check -p xb-compiler --features llvm` fails: *"No suitable version of LLVM
… LLVM_SYS_221_PREFIX"*. The workspace pins `inkwell` to `llvm22-1`, but only
Homebrew `llvm@21` (21.1.8, working `llvm-config` at `/opt/homebrew/opt/llvm@21`)
is installed — so the `llvm` feature compiles nowhere and is untested.

Two unblock paths (a **decision** — it sets the supported LLVM version):
- **Retarget to 21** — change the workspace `inkwell` feature `llvm22-1` →
  `llvm21-1` (inkwell 0.10 supports `llvm12-0`…`llvm22-1`, verified) and export
  `LLVM_SYS_211_PREFIX=/opt/homebrew/opt/llvm@21`. Backend builds + is locally
  verifiable **today**, but reverses the documented LLVM-22 target (docs/13, 14).
- **Install 22** — `brew install llvm@22` (or set `LLVM_SYS_221_PREFIX`) and add
  a CI job carrying LLVM 22; keeps the documented target.

Until one is chosen, LLVM stays deferred and the C code generator remains the
working AOT backend (the deliberate decision in docs/13 §Stage 3).

### JIT-X87 — FPU-intrinsic JIT not implemented `[verified]`
No JIT crate is present (`iced-x86` / `dynasm` absent from `Cargo.lock`). The
x87 FPU-intrinsic JIT (old `xlib.s` FSIN/FCOS/FPREM/…) is deferred; runtime math
uses plain `f64`. Only pursue if exact x87 compat semantics are ever required
(`docs/12 §3.2`).

## 2. Runtime semantics

### RT-BYTESTRING — strings are Rust UTF-8, not bytes `[verified repro]`
`RuntimeValue::String` (slot.rs) is a Rust `String`; `CHR$(>127)`, byte-level
`MID$`, brace `{}` byte access, and binary record I/O on non-ASCII data are
imperfect (guarded against panics, not correct). **Live repro**: running
`XBSourceLib/msc/msc.x`, the MscEncrypt/MscDecrypt round-trip of
`robin@example.com` decodes to a corrupted string full of stray back-tick
(0x60) bytes — the XOR/char arithmetic produces bytes UTF-8 `String` mangles.
Full fix = `Vec<u8>` strings, but scope exceeds the ~85 value sites: the
interpreter's **I/O channels are also `String`-based** — `execute_main*` take
`output: &mut Vec<String>` and `input: Vec<String>` (interpreter.rs), used by
~10 test files + the sync tests — so faithful high-byte PRINT/INPUT also needs
byte-capable channels (else high bytes are lossy at the boundary and the
interpreter diverges from the byte-faithful C backend). Interacts with
CG-BODY-COVER.

### RT-KERNEL32 — kernel32/stdio stubs for `acgibin` `[carried]`
`acgibin.x` needs `GetStdHandle`/`ReadFile`/`WriteFile` and the handle constants
`$$STD_INPUT_HANDLE=-10` / `$$STD_OUTPUT_HANDLE=-11`. Not implemented in the
interpreter runtime.

### RT-FUNCPTR — function-pointer calls (`afuntype`) `[carried]`
`afuntype.x` exercises calling through function pointers (`FUNCADDR` values used
as call targets). Parsing/lowering exist; runtime dispatch through a
function-pointer value does not.

### RT-NESTED-COMPOSITE — nested composite TYPEs: local vars ✅ done; params pending
A TYPE member whose type is itself a composite (e.g. `GEO_BINODE` holds two
`GEO_BICOORD`s) now flattens **recursively** into leaf struct-of-arrays slots
(`L1.a.x`) — fixed in `register_type` / `composite_decl` / `dim` (semantics*.rs),
plus a pre-existing bug where suffix-less non-Integer slots (incl. flat *float*
composite members) were overridden to Integer: dotted member slots now trust
their declared type (`symbol` / `assignment`). Locked by
`interpreter.rs::nested_composite_members_resolve_to_declared_float_type`.
**Remaining**: composite **parameters** by reference. `XBSourceLib/geo/geo.x`
still fails (`expected Integer, got String`) because `GeoPerpendicularLine
(GEO_BINODE @L2, ...)` accesses members of a composite *param* (not a local
`CompositeDecl`), so the member slots are never registered in the callee. Needs
composite-typed params to register their flattened member slots + by-ref aliasing.

## 3. Frontend / migration coverage

### MIG-CORPUS-GATE — legacy parse coverage gated by a test ✅ done
Combined parse coverage is **204/204** (151 `xbasic-6.4.5/*.x` + 13
`XBSourceLib/*.x` + 40 `XBSourceLib` source `.txt`). Now gated by
`crates/xb-compiler/tests/legacy_corpus.rs`
(`legacy_corpus_lowers_to_ir_without_swallow`): it walks both trees, requires
every file to parse+lower (the honest `rc == 0` metric — not "non-empty output",
not a min-IR-line threshold), and flags swallow regressions (a `>20`-source-line
file collapsing to `<=2` IR lines). Floors pin current counts (≥151 / ≥13 / ≥40,
≥204 total); additions must still lower, removals fail the gate.

### MIG-SEMANTICS — run-level coverage started `[verified]`
204/204 is *lowering to IR*, not full analyze/run. First run-level pass over the
core libs: `msc.x` runs (but corrupts high bytes — RT-BYTESTRING), `ary.x` and
`utils/mergeTest01`/`mergeTest02` run clean, `geo.x` is blocked on
RT-NESTED-COMPOSITE params. Next: add golden run fixtures for the clean ones and
expand as blockers clear.

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
