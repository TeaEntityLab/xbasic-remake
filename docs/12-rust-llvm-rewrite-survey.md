# 12 — Rust + LLVM Rewrite Survey: bootstrapping XBASIC 6.5.0

> Status: Research survey (Aug 2026) — recommendations only, not yet implemented.
> Inputs: `11-syscall-surface-survey.md` (the `.s`/syscall inventory), `09-version-history.md` + `10-unification-plan.md` (fork lineage), and three live surveys of the current Rust ecosystem (crates.io + GitHub API + official docs, all verified Aug 2026): Rust FFI/syscall crates, Rust GUI frameworks, Rust+LLVM compiler toolchains, plus a feature-mining pass over the 6.3.26-D and 6.4.5 trees.
>
> **User goals for 6.5.0:**
> 1. Keep cross-platform: **Linux + Win32/64 + macOS**, preserving the core spirit of 6.2.3 (one codebase, platform twins, `.dec`-driven FFI, constant-folding conditionals).
> 2. Learn the newest features and bug fixes from the newest two versions (6.3.26-D Win32 fork, 6.4.5 Linux 64-bit port).
> 3. **Bootstrap XBASIC 6.5.0 from scratch in Rust + LLVM** — low-level system calls and GUI included — instead of hand-porting the 1990s GAS.

---

## 1. Executive summary

| Decision | Recommendation | Why |
|---|---|---|
| AOT compiler codegen | **LLVM via `inkwell` 0.10.0 (LLVM 22)** | Only stack covering all four targets incl. Win32 x86; Apache-2.0; active (Aug 2026) |
| FPU-intrinsic JIT | **`iced-x86` 1.21.0 CodeAssembler** (alt: `dynasmrt` 5.1.0) | Complete x87 encoding incl. 32-bit; MIT; fuzz-tested |
| Raw syscalls (Linux/macOS) | **`rustix` 1.1.4** + `libc` 0.2.189 | `linux_raw` backend = direct syscalls, no libc; same source, three OSes |
| Win32 API surface | **`windows-sys` 0.61.2** (raw) — `windows` crate only if COM needed | Raw declarations, `no_std`, per-namespace features |
| Fault handling (XxxXitMain) | **raw `libc::sigaction`** (Unix) + **`AddVectoredExceptionHandler`** (Windows) | `signal-hook` **panics on SIGSEGV**; production runtimes (rust-lang/std, wasmtime, uv) use raw handlers |
| Dynamic loading | **`libloading` 0.9.0** | dlopen/LoadLibrary+GetProcAddress equivalent; borrow-safe `Symbol` |
| Memory mapping | **`memmap2` 0.9.11** (≥0.9.11 — RUSTSEC fix) | mmap/VirtualAlloc equivalent; 300M+ downloads |
| Sockets | **`std::net`** + **`socket2` 0.6.5** + `getifaddrs` 0.6.2 | raw socket/bind/listen/select surface; `rustix::io::poll` for Windows-safe multiplex |
| Object emission | **LLVM `TargetMachine::write_to_file`** (not the `object` crate) | LLVM emits correct ELF/COFF/Mach-O for all targets incl. i686 COFF |
| Linking | **`cc` crate 1.4.2** → system linker (link.exe / ld.lld / ld64 / gcc) | standard, least code |
| IDE GUI | **egui/eframe 0.36.1** + `egui_code_editor` 0.3.8 + `egui_dock` 0.21.1 | most complete IDE-shaped widget story; HWND access; embeddable in own loop |
| Runtime graphics (GDI spirit) | **winit 0.30.13 + softbuffer 0.4.8** with a thin GDI-shim; `windows` crate for faithful Win32 GDI | winit windows *are* HWNDs on Windows → real GDI; softbuffer on Linux/macOS |
| Runtime startup | **std CRT startup** (skip `no_std` unless size is a hard requirement) | even ChrisDenton says keep the CRT |

---

## 2. What to preserve from the forks (learn from the newest two versions)

Source: mining of `6.3.26-D` and `6.4.5` trees + `docs/09`/`docs/10`. Feature lists verified against `help/changelog.hlp` and code markers (`*cw*` date-stamps; 6.2.3 has **zero** `*cw*` markers, everything is post-6.2.3 work).

### 2.1 From 6.3.26-D (Win32 fork, 2009–2022)

Language/compiler features (must exist in the Rust rewrite):
- `PACKED`/`END PACKED` (1-byte alignment vs TYPE's 4-byte) — v6.3.13
- `MID$()=` intrinsic, `ISDATA()`/`ISNODE()` intrinsics, `::` logical-compare operator — v6.3.25
- String constants must end in `$`; `IF ("a" < "")` string-compare fix — v6.3.25/v6.3.19
- >65536 labels/variables (16→32-bit index) — v6.3.23
- All 16 function args 64-bit in `AssignAddress()` — v6.3.21
- `##WHOMASK` set in standalone programs — v6.3.13
- `STOP` as permanent breakpoint; nesting-level error messages — v6.3.24/25
- `DIM a[5,)` / `a[1,] = b[2,]` now syntax errors; array bounds+type check — v6.3.26/25
- AltGr keyboard support — v6.3.24

Runtime/library API additions:
- Task API: `XstStartTask`/`XstKillTask`/`XstGetTaskInfo` (v6.3.13)
- `XstInKey$`/`XstWaitKey$`, `XstRandom*` family, `XstParse$`, `XstTally`, `XstMatchWild` (v6.3.13)
- `XstLoadArray`/`XstSaveArray`, `XstCompareArray`/`XstCompareArry` (v6.3.26)
- File-select API `XstFileSelect*` (v6.3.21), `XstMoveToRecycleBin` (v6.3.26)
- Full preferences API (`XstOpenPref`/`XstSetPref*`/`XstDeletePrefKey`/…) 
- Console API: `XstGetConsoleFont`/`XstSetConsoleFont`/`XstGetConsoleStyleAndColors`/`XstGetConsolePositionAndSize`
- Bezier curves `XgrDrawCurve/Grid/Scaled` + `XgrFillCircle*`/`XgrFillEllipse*` (v6.3.23/13)
- `XstDyno*` dynamic-memory queries, `XstZeroFreeMemory`, `XstShellEx`, `XstSymbolicPathToPath$`
- `XstFileTimeToLocalDateAndTime`, `XstCreateConsole`

Robustness fixes:
- Segfault writes `x.log` with call stack (v6.3.20) → keep as a crash-report feature
- EAGAIN/EWOULDBLOCK unified (v6.3.20)
- Dynamic-memory limit ×4 + fill-detection; call-stack overflow detection (v6.3.24/16)
- Window "smearing" fix, console redraw every 100ms (v6.3.1)
- cwd set to program's directory (v6.3.16); `XBASICBACKUPDIR` + Edit>Load/Clean Backup (v6.3.21); `XBUSERCODE` env var (v6.3.24)
- v6.3.26-C: `QUIT` removed for keys ≥ `$$KeyF4` in standalone (`xgr.x:17826-17831`)

Architecture notes:
- Exception model is **NT SEH** (`xexcept.c`: `XxxStartExceptionHandler()` wraps `Xit()` in `_try/_except`, `XitMain(GetExceptionCode(), GetExceptionInformation())`) — a different design from both Linux trees. In Rust: `AddVectoredExceptionHandler`/`SetUnhandledExceptionFilter`.
- Win32 API import tables `win32api.csv` (5786 lines) — useful as an FFI surface spec.
- PDE/standalone split: `xstart.s`=PDE bootstrap (arg5=0), `appstart.s`=standalone.

### 2.2 From 6.4.5 (Linux 64-bit port, 2021–2023)

The 64-bit bring-up — all of this is what "64-bit correctness" means and must be preserved:
- **Signal handler**: `XxxXitMain(sigNumber, ptregs)` (xrun.x:30/107) / `XxxXitMain(signal, siginfo, ucontext)` (xit.x:150) with `CaptureExceptionContext`/`ReplaceExceptionContext` translating ucontext ↔ CPU registers (xit.x:1239-1249).
- **REX.W prefix emission** — `0x4C` (not `0x49`) for R8–R15 in modrm reg field (xcol.x:8152-8161, 230821); `rexW` back-patching (8223/8247/8340/8468-8471).
- **movabsq** for 64-bit immediates (xcol.x:9169).
- **r8/r9 register-arg codegen** — CFUNCTION prolog passes rdx/rcx/r8/r9 via `$$st` (xcol.x:5288-5297, 230822).
- 64-bit `inarg_base` mask `0xFFFFFFFFFFFFFFF0` (xcol.x:5187, 230302).
- RIP-relative 64-bit disassembly (xdis.x:391/459-480, 230315).
- Address displays widened `HEX$(,8)→HEX$(,9)/HEX$(,16)` (xit.x, 230306); `"0x"`-prefixed hex parsing (xit.x:24668, 230824).
- **Debian 10 stack alignment protocol** (the most instructive bugfix): even/odd stack-arg counts → `XxxRspEven_0`/`XxxRspOdd_0`/`XxxRestoreRsp_0` (xlib.s:537-539, 230108) evolved into lower-level `__rsp_odd`/`__rsp_even`/`__rsp_restore` (xlib.s:616-618/1665-1750, 230819) with `__RSPMOD`/`__RSPRIP` (230729); generated CFUNCTION call sites emit `_rsp_even`/`_rsp_odd` before pushing args and `_rsp_restore` after (xcol.x:18181-18270, 230730). **In Rust this is just "align the stack before FFI calls" — LLVM does it for you.**
- EXTERNAL CFUNCTION: `_zero_whomask` → `movabsq <addr>,%rax` → `call *%rax` → `_set_whomask` (xcol.x:18224-18228, v6.4.4).
- **xbiface.c additions**: `xb_lstat` (090411), `xb_geterrno`/`xb_seterrno` (errno is a macro — thread-safety), `xb_gethomepath` (**stub: hardcodes `/home/cw`, getpwuid commented out** — do not inherit; use std::env::home_dir / dirs crate), `struct` fields renamed `xst_*`, `xst_size` now `long long`; stat/lstat memset buffer on error.
- **New library functions**: `XstOpenLibrary`/`XstCloseLibrary`/`XstGetLibraryAddress` (dlopen/LoadLibrary wrappers), `XstGetHomePath$`.
- **FILEINFO**: split 32-bit fields → `GIANT` (64-bit) create/access/modify times + size.
- **`src/crtl/`** — the abandoned 2013 C-port of the runtime (`xlib.c`/`xstart.c`/`Xzzz.c`/`xbxtrns.c`; README: "highly experimental and not yet working") — **the direct ancestor of this Rust rewrite's runtime**. Its `XxxMain(argc, argv, envp, envx, main_foo, StartApp)` signature is the entry-point contract to reproduce.
- Exception mapping is **not expanded**: the 36-case signal→exception map in 6.4.5 (`xst.x:2914-2955`) matches 6.2.3 (`xst.x:1977-2018`) except one entry — `SIGSTKFLT` now maps to `$$ExceptionStackOverflow` (was `$$ExceptionUnknown`) (see corrections below).
- Known leftover: Makefile `PLATFORM = i386`, `DISTOS = linux-i386` despite 64-bit — do not copy.

### 2.3 Corrections to prior assumptions (verified in trees)

1. **"6.4.5 maps 12 exception types vs 6.2.3 fewer"** — not supported. 6.2.3 and 6.4.5 have the same 36-signal map (single diff: `SIGSTKFLT` → `$$ExceptionStackOverflow`, was `$$ExceptionUnknown`); the **Win32 fork maps fewer (21 exception cases + CASE ELSE)** (`xst.x:3549-3576`). The real change is the handler signature (ptregs/ucontext).
2. **`xb_readdir` already existed in 6.2.3** (`xbiface.c:208`); the new functions are `xb_lstat`, `xb_geterrno`, `xb_seterrno`, `xb_gethomepath`.
3. **xlib backups** (`xlib230325.s` = v6.4.3, `xlib230803.s` = v6.4.4) bracket the 230819 `__rsp_*` rewrite — regression snapshots; no in-tree comment names a specific breakage.

---

## 3. Rust + LLVM compiler toolchain (verified Aug 2026)

### 3.1 AOT pipeline — inkwell

| Item | Value |
|---|---|
| `inkwell` crates.io | **0.10.0** (2026-08-06); GitHub latest tag 0.9.0 (2026-04-12) |
| LLVM versions | 0.10.0: **LLVM 12–22** (`llvm12-0`…`llvm22-1`); 0.9.0 covered 11–22 (11 dropped) |
| MSRV | Rust 1.85+ |
| License | **Apache-2.0** |
| Maintenance | active; 110 contributors; ~3.0k stars |
| Pain point #1 | LLVM version pinning: one feature flag + system LLVM via `LLVM_SYS_221_PREFIX` |
| Pain point #2 | Thread model: `Context` `Send` but `!Sync`; `ExecutionEngine` not thread-safe (issue #242); ORC quirks (issue #603). Use one Context per compilation unit / scoped threads |
| Pain point #3 | Pre-1.0 breaking changes between minors (0.8→0.9→0.10) |

```toml
[dependencies]
inkwell = { version = "0.10.0", features = ["llvm22-1"] }
```
```rust
// emit object file directly (ELF/COFF/Mach-O)
let tm = target.create_target_machine(
    &TargetTriple::create("x86_64-pc-linux-gnu"), "x86-64", "+avx2",
    OptimizationLevel::Default, RelocMode::Default, CodeModel::Default).unwrap();
tm.write_to_file(&module, FileType::Object, Path::new("main.o")).unwrap();
```

**Alternatives and why not:**
- **Cranelift** (`cranelift-codegen` 0.134.3): **DISQUALIFIED — no 32-bit x86 backend** (deleted; Wasmtime uses the Pulley interpreter for i686). Only x86_64/aarch64/s390x/riscv64. Fast compile (10–100×), but fails the Win32 requirement.
- **gccjit.rs** (6.0.0, 2026-08-09): **DISQUALIFIED — GPL-3.0** (both crate and libgccjit). Used by rustc_codegen_gcc, but licensing blocks a proprietary XBasic.
- **llvm-sys** (221.0.1): raw FFI foundation that inkwell wraps; use only for C-API surfaces inkwell lacks.
- **Direct asm emission** (the old GAS path): fallback only, not the plan.

### 3.2 FPU-intrinsic JIT — iced-x86

Old `xlib.s` x87 ops (FSIN/FCOS/FPREM/FPREM1/FPTAN/FPATAN/FYL2X/FYL2XP1/F2XM1/FRNDINT/FSCALE/FXTRACT/FABS/FCHS/FLD*) need a 2026 home. **Note: on x86-64, SSE2 is the baseline** — runtime math should use plain `f64`/SSE intrinsics; x87 only if 32-bit-compat semantics (FPREM partial remainder) must be preserved exactly.

| Crate | Version | License | 32-bit x86 | x87 | Role |
|---|---|---|---|---|---|
| **iced-x86** | 1.21.0 (crates.io; repo active) | **MIT** | ✅ 16/32/64 | ✅ `AsmRegisterSt` | Encoder + CodeAssembler + BlockEncoder (relocation) — **primary** |
| **dynasmrt** | 5.1.0 (2026-07-22) | MPL-2.0 | ✅ long + protected mode | ✅ | `dynasm!` macro assembler — ergonomic alternative |
| yaxpeax-x86 | 2.2.0 (2026-07-05) | 0BSD | ✅ | decode-only | verification/disassembly only |

```rust
// iced-x86 CodeAssembler (code_asm feature)
let mut a = CodeAssembler::new(64)?;
a.fsin()?; a.fprem()?; a.ret()?;
let bytes = a.assemble(0x1000)?;  // Vec<u8> → mmap W^X → call
```
Keep W^X discipline: write into RW map, `mprotect`/`VirtualProtect` to RX, never RWX simultaneously (dynasmrt's `finalize()` enforces this).

### 3.3 Reference architectures (real-world Rust compilers)

| Project | What it is | Why it matters |
|---|---|---|
| **cocode/BasicRS** (+ TrekBASIC/TrekBasicJ siblings) | BASIC interpreter + compiler in Rust, LLVM-IR + clang | **Closest analog to XBasic** — a full BASIC dialect targeting LLVM |
| **endbasic/endbasic** (371★, v0.13.0 2026-05-29) | BASIC interpreter (REPL/web/RPi), AGPL-3.0 | interpreter architecture reference |
| yiransheng/basic_rs | Dartmouth BASIC + basic2rs transpiler | front-end structure |
| ngraf3255/bcomp | BASIC compiler on **cranelift** | proves cranelift works for BASIC on 64-bit — and fails win32 |
| acolite-d/llvm-tutorial-in-rust-using-inkwell | Kaleidoscope ch1–7, Rust+inkwell | canonical inkwell front-end |
| princemuel/kaleidoscope | Kaleidoscope on LLVM 22.x + inkwell | matches current inkwell version |
| truelossless/crocolang | C compiler in Rust via inkwell, full AOT: IR→.o→link | **the exact pipeline shape needed** |
| johannst/llvm-kaleidoscope-rs | hand-written safe LLVM C-API wrapper | the "llvm-sys without inkwell" path |
| rust-lang/rustc_codegen_cranelift (2,115★) | cranelift backend for rustc | cranelift reference |
| rust-lang/rustc_codegen_gcc (1,155★) | gccjit backend for rustc | gccjit reference |

---

## 4. Low-level system surface (FFI / syscalls)

All versions verified against crates.io API Aug 2026.

### 4.1 The matrix

| Facility | Recommendation | Version | API example | Gotcha |
|---|---|---|---|---|
| Linux raw syscalls | **`rustix`** | 1.1.4 | `rustix::mm::mmap(addr, len, ProtFlags::READ\|WRITE, MapFlags::PRIVATE\|ANONYMOUS, fd, 0)` | `linux_raw` backend = direct asm! syscalls (no libc); same source works on macOS/Win via libc/Winsock backends |
| libc bindings | `libc` | 0.2.189 | `unsafe { libc::sigaction(...) }` | still needed for sigaction/sockaddr |
| Win32 raw | **`windows-sys`** | 0.61.2 | feature `Win32_System_Diagnostics_Debug` etc. | **breaks semver on every minor** (0.48→0.52→0.59→0.61); pin exactly |
| Win32 safe | `windows` | 0.62.2 | COM/WinRT wrappers | only if COM needed — GDI-only plans don't |
| Fault handling | **raw `libc::sigaction` + `AddVectoredExceptionHandler`/`SetUnhandledExceptionFilter`** | — | see §4.2 | **`signal-hook` 0.4.4 PANICS on SIGSEGV** (FORBIDDEN list) |
| SIGINT/TERM | `signal-hook` | 0.4.4 | `signal_hook::flag::register(SIGINT, Arc::new(AtomicBool))` | fine for non-fault signals only |
| dlopen/LoadLibrary | **`libloading`** | **0.9.0** (0.8.9 for 0.8 line) | `lib.get::<Symbol<unsafe extern "C" fn(i32)->i32>>(c"name".as_ref())` | 0.9: MSRV 1.88, `AsFilename`, `no_std` feature; macOS needs `os::unix::Library::open` for framework paths |
| mmap/VirtualAlloc | **`memmap2`** | **0.9.11** (≥0.9.11) | `MmapOptions::new().len(n).map_anon()` | **RUSTSEC-2026-0186 unchecked pointer offset fixed only in 0.9.11** |
| Sockets high-level | `std::net` | std | `TcpListener::bind(...)` | covers 95% of XBasic networking |
| Sockets low-level | **`socket2`** | 0.6.5 | `Socket::new(Domain::IPV4, Type::STREAM, None)` | the raw socket/bind/listen/accept layer; `Into<OwnedFd>` for Read/Write |
| select/poll | `rustix::io::poll` | 1.1.4 | `poll(&fds, timeout)` | **Windows has no poll(2)** — rustix uses WSAPoll transparently; or threads per connection |
| Interface enum | `getifaddrs` | 0.6.2 | `getifaddrs::getifaddrs()` | README still says "0.4"; 0.6.x is current |
| Process/threads | `std::process`/`std::thread`; raw: `rustix::process` / `Win32_System_Threading` | std / 1.1.4 / 0.61 | `Command::new("x").spawn()` | keep std startup; custom entry only for GUI-subsystem |
| Time | `std::time::{Instant, SystemTime}`; raw: `rustix::time` (vDSO) / QPC | std / 1.1.4 | `Instant::now()` | don't mix Instant/SystemTime for monotonic intervals |
| Console | `std::io`; CRT-free: `WriteConsoleW` via windows-sys | std / 0.61 | `GetStdHandle(STD_OUTPUT_HANDLE)` | UTF-8→UTF-16 conversion on you |
| x86-64 code emit | **iced-x86** / dynasmrt | 1.21.0 / 5.1.0 | §3.2 | keep W^X |

### 4.2 Fault handling — the XxxXitMain case (most important gotcha)

`signal-hook` docs: *"the crate will panic in case registering of these is attempted"* (SIGSEGV in its FORBIDDEN list). Production runtimes do it raw:
- rust-lang/std installs SIGSEGV/SIGBUS stack-overflow handler via raw `libc::sigaction` with SA_ONSTACK (unix/stack_overflow.rs), and `AddVectoredExceptionHandler` on Windows (windows/stack_overflow.rs).
- mirrord, uv, wasmtime, RustPython all use `SetUnhandledExceptionFilter` + `AddVectoredExceptionHandler` for crash capture/traps.
- Handler must be async-signal-safe: atomics, raw pointer reads, `write(2)` only — no allocation/locks.

**Mapping to XBasic semantics:** 6.2.3 `XxxXitMain(signal)` → 6.4.5 `XxxXitMain(signal, siginfo, ucontext)`/ptregs → Rust: a `#[no_mangle] extern "C"` handler receiving siginfo/ucontext; on Windows VEH receives `EXCEPTION_POINTERS`. The 36-case signal→exception map (6.2.3 `xst.x:1977-2018`; 6.4.5 `xst.x:2914-2955` identical except `SIGSTKFLT`→`$$ExceptionStackOverflow`) becomes a Rust match table. Save raw register context → `CPUCONTEXT` equivalent (r8–r15/rip/rsp/rbp) for the debugger.

### 4.3 CRT-free / no_std startup — recommendation: DON'T

- **Keep std CRT startup.** ChrisDenton/nostd-msvc: *"even in a `no_std` application you'd usually want the CRT."*
- Path A (normal): std binary + windows-sys; `/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup` only if GUI-subsystem needed.
- Path B (genuinely CRT-free): `#![no_std] #![no_main]` + `mainCRTStartup`/`WinMain` entry + your own `GlobalAlloc` + `panic_handler` (min32 crate does this) + `#[link(name="kernel32")]`. Requires `panic=abort`.
- Gotcha: Windows `abort()` does NOT route through `SetUnhandledExceptionFilter` (documented in xai-org/grok-build) — keep `TerminateProcess` for abort capture.

---

## 5. GUI: IDE + runtime graphics (verified Aug 2026)

### 5.1 Comparative table

| Framework | License | Backend | Version | Widgets | IDE score | HWND/native | Embedding |
|---|---|---|---|---|---|---|---|
| **egui/eframe** | MIT OR Apache-2.0 | winit 0.30.13 + wgpu 30 (or glow) | 0.36.1 | high: `egui_code_editor` 0.3.8 + `egui_dock` 0.21.1 + menus built-in | **8/10** | ✅ `Frame::winit_window()`, `CreationContext::raw_window_handle` | ✅ library; `create_native()` returns winit `ApplicationHandler` for your own loop |
| iced | MIT | wgpu 26 + tiny-skia | 0.14.0 (experimental label) | med-high: built-in `text_editor`+`highlighter`; `iced_code_editor` 0.3 (LSP, multi-cursor) | **7/10** | ✅ via winit integration path | ✅ official `examples/integration` |
| slint | ⚠️ Royalty-free/GPLv3/Commercial | winit (X11+Wayland) | 1.17 | **no code editor** (maintainer-confirmed #2723) | **4/10** | ✅ `WindowAdapter::window_handle_06()`, `WinitWindowAccessor` | ⚠️ custom `Platform` trait; wants own loop |
| tauri v2 | MIT OR Apache-2.0 | tao + wry (WebView2/WKWebView/WebKitGTK) | v2 (2.12 drops Win7) | high for text (Monaco) but webview variance | **7/10 but spirit conflict** | ✅ `hwnd()`, `ns_window()`, `gtk_window()` | ❌ owns `main()` — not embeddable |
| **winit + softbuffer** | Apache-2.0 / MIT-Apache | winit 0.30.13; CPU framebuffer | winit 0.30.13, softbuffer 0.4.8 | none — build everything | 2/10 IDE, **10/10 runtime layer** | ✅ **winit windows ARE HWNDs on Windows** | ✅ best-in-class: `pump_app_events()` |
| druid / xilem | Apache-2.0 | winit + Vello | druid **UNMAINTAINED**; xilem experimental | low | 3/10 | ✅ via winit | ✅ goal, not shipping |
| windows crate | MIT OR Apache-2.0 | native GDI/user32/gdi32/kernel32 | 0.62.2 | full native Win32 | n/a (Win-only) | ✅ it IS the API | ✅ loop is yours |

### 5.2 Recommendation — two paths

**Path A — IDE GUI: egui/eframe** (primary; iced as runner-up).
- Matches all 5 criteria: cross-platform (Linux x86_64/ARM64, Win32/64, macOS), IDE-shaped widgets (`egui_code_editor` + `egui_dock`), native interop (`Frame::winit_window()` → HWND), embedding (`create_native()` in your own loop, timers via `request_repaint_after`), performance (immediate mode, GPU).
- Why not others: tauri fails embedding + webview sandbox hides native APIs (violates the "expose OS API" spirit); slint has no code editor + license baggage; xilem too early; raw winit means rebuilding an IDE.

**Path B — runtime program-facing graphics API: winit + softbuffer with a thin GDI-shim; `windows` crate for faithful Win32.**
- The runtime owns **one** winit event loop (`pump_app_events` from the IDE's loop). Program windows are winit windows.
- **On Windows, a winit window *is* an HWND** (`RawWindowHandle::Win32`) → pass to real GDI (`CreateWindow`, `GetDC`, `TextOut`, `LineTo`, `BitBlt`, `SetTimer`, `GetMessage`/`DispatchMessage`) via the windows crate. 1:1 fidelity with the original XBasic Win32 surface.
- On Linux/macOS, the same GDI-call surface maps to softbuffer/pixels: `TextOut`→text into buffer, `LineTo`→line rasterization, `BitBlt`→blit, `SetTimer`→`ControlFlow::WaitUntil`/timer wheel.
- The IDE (egui via `create_native`) and program windows share that one loop — an XBasic `CreateWindow` opens a real window next to the IDE without nested loops.
- Start with the core ~20 GDI functions (window classes, message pump, text, lines/rects, blits, timers, menus); GDI text metrics/DC semantics are subtle — budget for behavioral drift on non-Windows.

---

## 6. Proposed 6.5.0 bootstrap architecture

```
┌─────────────────────────────────────────────────────────────┐
│  xbasic-6.5.0 (Rust workspace, cargo)                       │
│                                                             │
│  crates:                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │ xb-frontend   │  │ xb-compiler   │  │ xb-runtime      │  │
│  │ lexer/parser/ │→│ typechecker/  │→│ entry (XxxMain)  │  │
│  │ AST (own)     │  │ inkwell IR    │  │ fault handler   │  │
│  └───────────────┘  │ builder       │  │ (sigaction/VEH) │  │
│                     │ LLVM 22       │  │ libloading      │  │
│                     │ + passes      │  │ memmap2/socket2 │  │
│                     └──────┬────────┘  │ rustix/libc    │  │
│                     TargetMachine::    │ FPU-JIT iced-  │  │
│                     write_to_file(.o)  │ x86/dynasmrt   │  │
│                             │          └────────┬────────┘  │
│                             ▼                    ▼          │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │ xb-ide        │  │ xb-gui        │  │ xb-link (cc)    │  │
│  │ egui/eframe   │  │ winit+soft-   │  │ .o + system     │  │
│  │ code_editor/  │  │ buffer GDI-   │  │ linker → exe    │  │
│  │ dock          │  │ shim / win32  │  │ (link.exe/ld64/ │  │
│  │               │  │ GDI           │  │  gcc/lld)       │  │
│  └───────────────┘  └───────────────┘  └─────────────────┘  │
│  shared one winit event loop (pump_app_events)              │
│                                                             │
│  xb-lib (the 6.2.3 spirit): platform twins via cfg()        │
│  + .dec FFI equivalents as a single Rust trait surface      │
│  (kernel32/user32/gdi32/wsock32/shell32/clib)               │
└─────────────────────────────────────────────────────────────┘
```

**Key design decisions:**
1. **One codebase, cfg-based twins** — the 6.2.3 spirit (`src/{shared,linux,win32}` + `##XBSystem`) becomes Rust `#[cfg(target_os)]`/`cfg!(...)`. The `.dec` FFI files become a Rust trait/type surface (one trait per library, per-OS impls).
2. **AOT pipeline**: frontend (Rust, ported from `xcow.x`/`xcol.x` logic) → inkwell IR → LLVM optimize → `write_to_file(.o)` → `cc`-driven link. **No GAS anywhere.**
3. **Runtime**: Rust port of the `xlib.s`/`xstart.s`/`appstart.s`/`xzzz.s`/`xbiface.c` surface, using the crates in §4. Entry-point contract from crtl/ `XxxMain(argc, argv, envp, envx, main_foo, StartApp)`.
4. **FPU intrinsics**: iced-x86 JIT (W^X) or LLVM intrinsics; plain `f64` on 64-bit.
5. **GUI**: egui IDE + winit/softbuffer GDI-shim runtime layer, one shared event loop.
6. **Fault handling**: raw sigaction (Unix) + VEH (Windows), 36-case map, CPUCONTEXT save/restore — preserving 6.4.5's ptregs model.
7. **Windows 32-bit**: LLVM emits COFF for i686; `windows-sys` supports i686 targets; iced-x86 supports 32-bit. **This is the constraint that rules out Cranelift.**
8. **Feature preservation**: the §2 feature lists (PACKED, MID$()=, task API, prefs API, Bezier, GIANT FILEINFO, >65536 symbols, 16×64-bit args, x.log crash reports, backup/prefs env vars) are the acceptance checklist for the rewrite.

**Deployment risks to budget for:**
- LLVM 22 must be installed on every dev/CI machine (`LLVM_SYS_221_PREFIX`); pin via CI containers.
- inkwell pre-1.0 breaking changes on minor bumps.
- `windows-sys` semver-breaking minors — pin 0.61.
- `memmap2` must be ≥0.9.11 (security advisory).
- egui fast API-churn; winit 0.31 is coming (0.30→0.31 will ripple through egui/iced/slint).
- GDI-shim behavioral drift on non-Windows text metrics.

---

## 7. Open questions for maintainers

1. **x87 vs SSE2 for FP intrinsics**: preserve exact FPREM partial-remainder semantics (x87) or accept SSE2/libm equivalence? (Affects the JIT scope.)
2. **Win32 target width**: 32-bit AND 64-bit Windows, or 64-bit only (plus 32-bit for legacy)? The report's plan assumed Win32 stays 32-bit; the crates support both. (Affects Cranelift eligibility — moot if inkwell.)
3. **`xb_gethomepath` stub** (`/home/cw` hardcoded) — replace with `dirs` crate or `std::env`? (Recommend yes.)
4. **GUI spirit**: how faithful must the GDI-shim be? (Option: exact-API-parity trait vs "best-effort 20 core functions" first cut.)
5. **crtl/ C-port**: treat as dead reference (recommended) or as a migration template to port from? (It cannot compile — recommend reference-only.)
6. **Self-hosting**: 6.2.3's compiler was written in XBasic itself. Does 6.5.0 stay self-hosted (the Rust compiler compiles `.x` sources that re-implement the compiler)? (This changes frontend scope massively.)

---

## 8. Sources

- Surveys (this session, Aug 2026): FFI/syscall crates, GUI frameworks, LLVM toolchains — versions verified against crates.io API + GitHub API + official docs.
- Feature mining: `6.3.26-D/help/changelog.hlp:21-346`, `6.4.5/help/changelog.hlp:24-67`, `*cw*` markers, `xcol.x`/`xlib.s`/`xbiface.c`/`xst.x`/`xit.x`/`xrun.x` line citations (see §2).
- Prior chapters: `docs/09-version-history.md`, `docs/10-unification-plan.md`, `docs/11-syscall-surface-survey.md`.
- Key external refs: [inkwell](https://github.com/TheDan64/inkwell) · [llvm-sys](https://github.com/tari/llvm-sys.rs) · [cranelift target support](https://docs.wasmtime.dev/stability-platform-support.html) · [gccjit.rs](https://github.com/rust-lang/gccjit.rs) · [rustix](https://github.com/bytecodealliance/rustix) · [windows-sys FAQ](https://github.com/microsoft/windows-rs/blob/8f4f65ee6f4ebdd6826cdf5aa8ff0a7db4316972/docs/FAQ.md) · [signal-hook limitations](https://docs.rs/signal-hook/latest/signal_hook/) · [rust std stack_overflow (unix)](https://github.com/rust-lang/rust/blob/main/library/std/src/sys/pal/unix/stack_overflow.rs) / [(windows)](https://github.com/rust-lang/rust/blob/main/library/std/src/sys/pal/windows/stack_overflow.rs) · [nostd-msvc](https://github.com/ChrisDenton/nostd-msvc) · [memmap2](https://github.com/RazrFalcon/memmap2-rs) · [socket2](https://github.com/rust-lang/socket2) · [libloading](https://github.com/nagisa/rust_libloading) · [iced-x86](https://github.com/icedland/iced) · [dynasm-rs](https://github.com/CensoredUsername/dynasm-rs) · [egui](https://github.com/emilk/egui) · [iced](https://github.com/iced-rs/iced) · [slint](https://github.com/slint-ui/slint) · [tauri](https://github.com/tauri-apps/tauri) · [winit](https://github.com/rust-windowing/winit) · [softbuffer](https://github.com/rust-windowing/softbuffer) · [BasicRS](https://github.com/cocode/BasicRS) · [endbasic](https://github.com/endbasic/endbasic) · [crocolang](https://github.com/truelossless/crocolang) · [cc-rs](https://github.com/rust-lang/cc-rs) · [object](https://github.com/gimli-rs/object)