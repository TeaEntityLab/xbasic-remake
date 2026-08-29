# XBASIC 6.2.3 — Project Overview

> Source tree analyzed: `xbasic-6.2.3/` (read-only reference distribution, ~8.6 MB, 106 files).
> This document records the design of XBASIC 6.2.3 as principally shipped by Max Reason (copyright 1988–2000); `xut` and `xutpde` credit Eddie Penninkhof (copyright 2000).

## What XBASIC Is

XBASIC is an **integrated software development environment** built around a
self-hosted BASIC compiler and runtime:

- A **compiler** for the XBASIC language (sources: `xcol.x` on Linux, `xcow.x` on Win32).
- A **Program Development Environment / PDE** — an edit/run/debug GUI
  (source: `xit.x`), built with XBASIC's own GUI toolkit.
- An interactive **GuiDesigner** form-builder (source: `xui.x`), used to lay
  out GUI windows graphically and generate the code that creates them.
- A set of **function libraries** — standard (`xst`), math (`xma`), complex
  numbers (`xcm`), sockets/network (`xin`), graphics (`xgr`), grids
  (`xgrids`), and an i486 disassembler (`xdis`) used by the debugger.
- A **standalone executable/runtime layer** (`xrun.x`) that lets compiled
  XBASIC programs link into native executables.

The defining property of XBASIC is **self-hosting**: the compiler, the IDE,
the GUI toolkit and nearly every library are *written in XBASIC itself*.
Only a thin layer of native code (a few hundred lines of C, some i386
assembly startup files, and — on Windows — a resource/export shim) sits
between XBASIC code and the operating system.

## Platform Support

XBASIC 6.2.3 targets **two platforms from one source tree**:

| Platform | Compiler source | IDE source | Deliverables |
|---|---|---|---|
| Linux (i386) | `src/linux/xcol.x` | `src/linux/xit.x` | `bin/xb` executable + `bin/libxb.a` static library |
| Windows (Win32) | `src/win32/xcow.x` | `src/win32/xit.x` | `bin/xb.exe` (PDE), `bin/xb.dll` (PDE runtime), `bin/xbrun.dll` (standalone runtime), `bin/xb.lib` (import library) |

The READMEs state the compatibility goal explicitly:

> "Windows XBasic and Linux XBasic are compatible implementations — even
> applications containing extensive graphics and GUI functionality will run
> **unmodified on both operating systems without any source-code changes**."
> — `README.Linux`, lines 16–21

How that compatibility is achieved (separate per-platform source files with a
common API, a runtime OS-switch variable `##XBSystem`, a foreign-function
declaration mechanism via `.dec` files, template-generated makefiles, and a
shared cross-platform GUI toolkit) is the subject of
[`06-cross-platform.md`](./06-cross-platform.md).

## Licensing Model

The historical source uses two declared license families on files that carry
license headers:

- **GPL** — the compiler and the edit/run/debug environment (`COPYING`).
- **LGPL** — general-purpose function libraries including `xst`, `xma`, `xcm`,
  `xui`, `xgr`, `xin`, `xut`, and related files (`COPYING_LIB`).

Not every source has such a header. Three Win32 compatibility shims —
`gdi32.x`, `kernel32.x`, and `user32.x` — carry no copyright notice or license
statement in either the 6.2.3 or 6.4.5 tree. No redistribution grant for those
files is established by repository evidence.

The current remake's 15-library link harness combines GPL-header,
LGPL-header, and no-notice inputs. It is strictly an internal test artifact,
not a redistribution-ready library bundle; see docs/17 L15. Sample programs
are public domain only where their own source or distribution documentation
says so.

## Distribution Forms

The top-level `Makefile` builds six distribution shapes:

| Target | Shape | Platform |
|---|---|---|
| `dist-bin` | `.tar.gz` binary install | Linux |
| `dist-bin-rpm` | `.rpm` (Red Hat, via `xbasic.spec.sed`) | Linux |
| `dist-bin-zip` | `.zip` binary | both |
| `dist-bin-exe` | self-installing `.exe` (Inno Setup, `compil32`) | Windows |
| `dist-src` | `.tar.gz` source | both |
| `dist-src-zip` | `.zip` source | Windows |

## Installation Model

- **Linux**: everything installs under `/usr/xb-$(VERSION)`; symlinks are
  created: `/usr/xb -> /usr/xb-6.2.3`, `/usr/bin/xb -> /usr/xb/bin/xb`,
  `/usr/lib/libxb.a -> /usr/xb/lib/libxb.a`. `make install` installs into
  `/usr/xb-$(VER)` so a faulty build never destroys the working install.
- **Windows**: no registry changes; install anywhere (`C:\Program
  Files\XBasic` is suggested). `xbvars.bat` sets `PATH`/`LIB`/`INCLUDE` for
  command-line builds. A historical Windows 95 loader bug requires a
  duplicate copy of `xb.dll` named `xb.dup` (see `README.Win32` and
  `help/notes.hlp`).
- Since 6.1.0 there is **only a "master directory"** — the old `~/xb`
  "working directory" concept was dropped; any directory can be the working
  directory.

## Self-Hosting and the Bootstrap Problem

Because XBASIC is written in XBASIC, **you need a working XBASIC compiler to
rebuild XBASIC** (the READMEs state this explicitly). The build works by
feeding each `.x` source file through the already-installed `xb` compiler:

```
prog.x  --xb-->  prog.s   --gcc/as-->  prog.o   --link-->  executable/library
```

The `src/Makefile` encodes this with the pattern rule `%.s: %.x` → `xb $< -lib`.
Details in [`07-build-system.md`](./07-build-system.md).

## Source Tree Layout

```
xbasic-6.2.3/
├── Makefile            # top-level build / install / dist
├── README.Linux        # Linux install & rebuild instructions (XBASIC source)
├── README.Win32        # Windows install & rebuild instructions
├── COPYING             # GPL
├── COPYING_LIB         # LGPL
├── src/
│   ├── Makefile        # the actual build: .x -> .s -> .o -> xb / libxb.a
│   ├── xexcept.obj     # precompiled Windows exception-handling object
│   ├── shared/         # platform-independent XBASIC sources
│   │   ├── xui.x       #   GuiDesigner function library (37,974 lines)
│   │   ├── xma.x       #   mathematics library (1,987)
│   │   ├── xcm.x       #   complex-number library (996)
│   │   ├── xdis.x      #   i486+ disassembler (2,301)
│   │   ├── xut.x       #   platform-independent utilities (44)
│   │   └── xutpde.x    #   PDE utilities / XBDir$ resolution (82)
│   ├── linux/          # Linux platform layer
│   │   ├── xcol.x      #   the compiler (28,155)
│   │   ├── xit.x       #   the PDE/IDE (22,290)
│   │   ├── xst.x       #   standard library (10,523)
│   │   ├── xgr.x       #   graphics library (21,883)
│   │   ├── xin.x       #   sockets/network (2,819)
│   │   ├── xgrids.x    #   grid controls (5,424)
│   │   ├── xrun.x      #   standalone executable support (346)
│   │   ├── kernel32.x / gdi32.x / user32.x  # Linux .dec wrappers
│   │   ├── xbiface.c   #   C glue to the OS (273 lines)
│   │   ├── chkmem.c    #   heap consistency checker (50)
│   │   └── lib/        # i386 assembly startup: xstart.s, appstart.s,
│   │                   #   xlib.s, xzzz.s
│   └── win32/          # Windows platform layer
│       ├── xcow.x      #   the compiler (27,553)
│       ├── xit.x       #   the PDE/IDE (22,347)
│       ├── xst.x       #   standard library (11,096)
│       ├── xgr.x       #   graphics library (22,688)
│       ├── xin.x       #   sockets/network (2,972)
│       ├── xrun.x      #   standalone executable support (255)
│       ├── xbasic.x    #   (28-byte data file, see 06-cross-platform.md)
│       ├── xb.def      #   export list for xb.dll (1,187 lines)
│       ├── xb.rc       #   icon/cursor resources
│       └── lib/        # i386 assembly startup: xstart.s, xzzz.s
├── include/            # .dec foreign-function declaration files
│   ├── kernel32.dec user32.dec gdi32.dec wsock32.dec shell32.dec winmm.dec
│   └── clib.dec elf32.dec xlib.dec xwin.dec
├── templates/          # .xxx generation templates (per-platform subdirs)
│   ├── *.xxx           #   shared program skeletons
│   ├── linux/          #   Linux makefile/skeleton templates
│   └── win32/          #   Windows makefile/skeleton templates
├── help/               # .hlp help databases (language, PDE, messages, notes)
└── images/win32/       # .ico/.cur resources
```

## Version History Context

`help/new.hlp` carries a feature/bugfix changelog for 6.2.1 → 6.2.3 (and
beyond). Notable items that illuminate the design:

- 6.2.1: "Removed 64KB limit of structures", "Implemented READ/WRITE for
  string arrays", "Fixed a bug in linux/xit.x function SharedMemory",
  "Removed dependency on the OSTYPE environment-variable on Linux" (startup
  fix for Red Hat 7.3 / bash 2.05).
- 6.2.2: "Fixed SWAP for strings", "Corrected expression evaluation in DIM
  and REDIM".
- 6.2.3: "SIGALRM wasn't handled outside of the PDE on Linux", "Fixed
  winmm.dec", "Moved code to create Toolkit and related windows to
  XxxGuiDesignerOnOff".

The changelog shows the two platforms were maintained in lockstep from one
tree, with platform-specific fixes (e.g. `XgrDrawPoints (Win32)`) applied
independently per platform file.
