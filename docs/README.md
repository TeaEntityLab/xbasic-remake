# XBASIC 6.2.3 — Design Documentation

This directory documents the XBASIC 6.2.3 source tree (`../xbasic-6.2.3/`), a
self-hosted BASIC compiler, IDE, and runtime for Linux and Windows (Win32) written by
Max Reason (copyright 1988–2000). The documentation captures how the system is built
and how it achieves cross-platform portability.

## Chapter index

| # | Chapter | What it covers |
|---|---|---|
| 00 | [Overview](00-overview.md) | What XBASIC is, target platforms, licensing, distributions, install model, source tree layout, version history |
| 01 | [Architecture](01-architecture.md) | Program model, module system, compile pipeline, memory model, exception model, runtime architectures |
| 02 | [The Compiler](02-compiler.md) | `xcol.x`/`xcow.x`: tokenizer, two-pass pipeline, code emitters (asm/bin), the `Xxx*` PDE API, function map |
| 03 | [Runtime](03-runtime.md) | `xrun.x` entry sequence, exception loops, `xb.def` symbol surface, heap (`chkmem.c`), platform divergence |
| 04 | [Libraries](04-libraries.md) | Per-library API maps: `xst`, `xgr`, `xma`, `xcm`, `xin`, `xgrids`, `xdis` |
| 05 | [IDE / GUI Toolkit](05-ide.md) | The PDE (`xit.x`) and the GuiDesigner toolkit (`xui.x`): grids, messages, redraw, form-builder |
| 06 | [Cross-Platform Architecture](06-cross-platform.md) | Source correspondence, FFI via `.dec` files, constant-folding conditionals, assembly startup, `xbiface.c` |
| 07 | [Build System](07-build-system.md) | Toolchains, OS autodetection, Makefiles, template system, bootstrap order |
| 08 | [Language Reference](08-language-reference.md) | Types, scoping, statements, operator table, intrinsics, dot commands, grid messages |
| 09 | [Version History](09-version-history.md) | The post-6.2.3 forks: 6.3.26-D (Win32 unofficial) and 6.4.5 (Linux xb64 64-bit), per-file version tables, the crtl/ C-runtime experiment |
| 10 | [Unification Plan](10-unification-plan.md) | Proposal for merging 6.3.26-D + 6.4.5 back into one cross-platform tree (6.5.0) |
| 11 | [Syscall Surface Survey](11-syscall-surface-survey.md) | Every `.s`/syscall in the three trees: zero raw syscalls, 6 hand-written `.s` files, FPU-intrinsic / libc / frame-helper classification, signal & exception model |
| 12 | [Rust + LLVM Rewrite Survey](12-rust-llvm-rewrite-survey.md) | Crates for the 6.5.0 rewrite: inkwell/LLVM pipeline, iced-x86 FPU JIT, rustix/windows-sys FFI, egui+winit GUI, plus what to preserve from 6.3.26-D and 6.4.5 |
| 13 | [6.5.0 Bootstrap Scaffold](13-bootstrap-scaffold.md) | Resolved decisions (f64/libm, Win64 first, staged self-hosting), stage plan, and the repo-root Rust workspace layout |
| 14 | [Self-Hosting Progress](14-self-hosting-progress.md) | Completed Stage-0-to-Stage-1 bootstrap path, verifier evidence, current limitations, and falsifiable Stage-2 compiler-self-host tasks |
| 15 | [Stage-2 Contract v0.1](stage2-contract-v0.1.md) | Baseline accepted subset: VERSION, PRINT, DIM, assignment, FUNCTION/END FUNCTION, integer/float/string literals |
| 16 | [Stage-2 Contract v0.2](stage2-contract-v0.2.md) | $$ constants and ## shared variable tokenization: lexer support, constant definitions, constant references |
| 17 | [Stage-2 Contract v0.3](stage2-contract-v0.3.md) | ## shared system variables: parser, semantic, IR, and runtime support as mutable typed storage |
| 18 | [Stage-2 Contract v0.4](stage2-contract-v0.4.md) | IF/THEN/ELSE/END IF conditional branching: integer-valued condition, no new scope, XB-S009 diagnostic, runtime branch selection |
| 19 | [Stage-2 Contract v0.5](stage2-contract-v0.5.md) | Comparison operators (=, <>, <, >, <=, >=): expression-level binary operators returning Integer TRUE/FALSE, XB-S010 diagnostic, runtime ordering |
| 20 | [Stage-2 Contract v0.6](stage2-contract-v0.6.md) | Function calls with typed parameters, RETURN statements, function call expressions, XB-S011 through XB-S015 diagnostics |
| 21 | [Stage-2 Contract v0.7](stage2-contract-v0.7.md) | Arithmetic operators (+, -, *, /) with precedence, Integer/Float type promotion, XB-S016 diagnostic, runtime division-by-zero error |
| 22 | [Stage-2 Contract v0.8](stage2-contract-v0.8.md) | WHILE/WEND loops: integer-valued condition, body iteration, RETURN propagation through Flow |
| 23 | [Stage-2 Contract v0.10](stage2-contract-v0.10.md) | String concatenation via + operator on two String operands |

## The big picture

XBASIC is **self-hosted**: the compiler, IDE, and libraries are all written in XBASIC.
A `.x` source file is compiled to i486 assembly, then assembled and linked by the
platform toolchain (GNU as + gcc on Linux; `spasm` + MS `link.exe` on Windows).
Portability comes from:

1. **One compiler with two backends** — `xcol.x` (Linux) and `xcow.x` (Win32) are
   ~88.5% identical; both emit i486 assembly.
2. **Stable library APIs over swappable OS backends** — `xst`/`xgr`/`xin` have
   platform twins that differ only in the OS-specific layer (X11 vs GDI, libc vs
   Winsock, signals vs SEH).
3. **Compile-time constant folding instead of a preprocessor** — `##XBSystem` +
   `$$XBSysLinux`/`$$XBSysWin32` + `IF ##CONST THEN/ELSE/END IF`.
4. **FFI via `.dec` files** — `EXTERNAL FUNCTION` declarations read by the compiler
   at `IMPORT` time; Win32 API functions are reimplemented in XBASIC on Linux
   (`kernel32.x`/`user32.x`/`gdi32.x`), so the same source compiles on both platforms.
5. **A shared assembly runtime** (`xlib.s`, `xstart.s`, `xzzz.s`) with per-OS
   bootstrap for entry points and section boundaries.

## Reading order

For a quick overview: `00 → 01 → 06`. For implementation depth: add `02` (compiler),
`03` (runtime), and `07` (build). For API-level detail: `04` (libraries), `05` (IDE/GUI),
`08` (language reference).

## Source tree map

```
xbasic-6.2.3/
├── Makefile                  top-level driver (OS autodetect)
├── src/
│   ├── Makefile              the real build
│   ├── shared/               platform-neutral XBASIC sources (xui, xma, xcm, xdis, xut, xutpde)
│   ├── linux/                Linux twins (xcol, xit, xst, xgr, xin, xrun, xbiface.c, chkmem.c)
│   ├── win32/                Win32 twins (xcow, xit, xst, xgr, xrun, xbasic.x, xb.def, xb.rc)
│   └── lib/                  assembly runtime (xlib.s, xstart.s, xzzz.s, appstart.s)
├── include/                  .dec FFI files (kernel32, user32, gdi32, wsock32, shell32,
│                             winmm, clib, elf32, xlib, xwin)
├── templates/                linux/ and win32/ template sets (xapp, xdll, syslib, win32api...)
├── help/                     .hlp documentation files
├── samples/                  example programs
└── COPYING, COPYING_LIB      GPL (compiler/IDE) and LGPL (libraries)
```
