# 06 — The Cross-Platform Architecture

XBASIC 6.2.3 is one source tree that builds the same language, compiler, IDE, and
libraries for **Linux** and **Windows (Win32)**. This chapter documents exactly how
that portability is achieved.

## 1. The correspondence table

The tree is split into per-platform source pairs plus a shared core:

| Shared (compiles on both) | Linux-only | Win32-only | Role |
|---|---|---|---|
| `src/shared/xui.x` | `src/linux/xgr.x` | `src/win32/xgr.x` | GUI toolkit / graphics |
| `src/shared/xma.x` | `src/linux/xst.x` | `src/win32/xst.x` | math / standard functions |
| `src/shared/xcm.x` | `src/linux/xin.x` | — | complex numbers / sockets |
| `src/shared/xdis.x` | `src/linux/xit.x` | `src/win32/xit.x` | disassembler / IDE (PDE) |
| `src/shared/xut.x` | `src/linux/xcol.x` | `src/win32/xcow.x` | utilities / compiler |
| `src/shared/xutpde.x` | `src/linux/xrun.x` | `src/win32/xrun.x` | PDE support / runtime entry |
| `src/linux/xbiface.c` | `src/linux/chkmem.c` | — | C glue (see §7) |

The platform pairs are 80–90% identical. Quantified diff sizes (byte-level, from
`diff src/linux/X src/win32/X`):

- `xcol.x`/`xcow.x`: ~88.5% identical
- `xgr.x`: 94 diff hunks (X11 vs GDI backend)
- `xst.x`: Linux 10,523 lines vs Win32 11,096 lines
- `xit.x`: Linux vs Win32 (different entry points, see §6 of 07-build-system)
- `xrun.x`: Linux 346 lines vs Win32 255 lines (signals vs SEH)

## 2. The portability contract: stable API over swappable backends

The libraries present **identical XBASIC-callable APIs** on both platforms. The pairs
differ only where the OS differs:

| Layer | Linux | Windows |
|---|---|---|
| Graphics (`xgr`) | X11/Xlib | GDI (Win32) |
| Sockets (`xin`) | libc sockets (`clib.dec`) | Winsock (`wsock32.dec`) |
| Exception handling | signals (`xb_sigaction`) | SEH (`xexcept.c`/`XxxStartExceptionHandler`) |
| Dynamic loading | `dlopen` (`clib.dec`) | `LoadLibraryA`/`GetProcAddress` (`kernel32.dec`) |
| Binary format | ELF | PE/COFF |

The strongest evidence that this contract is real: the **identical dual-OS block**
appears in both IDE files:

```
linux/xit.x:6983:  IF ##XBSystem = $$XBSysLinux THEN
                       XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/README.Linux:*")
                   ELSE
                       XuiSendMessage (grid, #SetHelp, 0, 0, 0, 0, 0, "$XBDIR/README.Win32:*")
                   END IF
win32/xit.x:7044:  IF ##XBSystem = $$XBSysLinux THEN   (identical text)
```

More instances: `linux/xst.x:1414` `SELECT CASE ##XBSystem ... CASE $$XBSysLinux:
name$ = "linux unix"`; `shared/xdis.x:2283` `IF ##XBOS=$$XBSysLinux` (note: a
*second* constant `##XBOS`); `shared/xutpde.x:62` `IF ##XBSystem == $$XBSysWin32 THEN
##XBDir$ = "c:\xb" ELSE ##XBDir$ = "/usr/xb"`.

## 3. Conditional compilation — constants instead of a preprocessor

**There is no C-style `#ifdef` preprocessor.** A tree-wide search for
`IFDEF`/`#ifdef` finds only one comment in `include/winmm.dec:1146`. Instead, XBASIC
uses **compile-time constants + constant folding**:

1. `##`-prefixed names are compile-time constants AND runtime system variables (their
   addresses are fixed in `xlib.s`).
2. `$$`-prefixed names are compile-time constants. The platform selector is defined in
   `src/shared/xut.x:25-26`:
```
$$XBSysLinux		= 1
$$XBSysWin32		= 2
```
3. Each platform's entry module **assigns** the constant once:
```
linux/xrun.x:79:   ##XBSystem = $$XBSysLinux
win32/xrun.x:66:   ##XBSystem = $$XBSysWin32
linux/xit.x:719:   ##XBSystem = $$XBSysLinux
win32/xit.x:933:   ##XBSystem = $$XBSysWin32
```
4. The compiler **folds `IF ##CONST ... THEN ... ELSE ... END IF` and
   `SELECT CASE ##CONST` at compile time**, eliminating the dead branch.

The `##` constants also serve as the runtime's memory-mapped globals —
`win32/lib/xlib.s:55-100` declares them all as `.comm` symbols (`_##CODE`, `_##DATA`,
`_##APP`, `_##HINSTANCE`, `_##WHOMASK`, ...), and `linux/lib/xlib.s` declares the same
set with `__` prefixes (`__CODE`, `__DATA`, `__APP`, ...). So `##XBSystem` is both a
compile-time switch and a runtime variable.

## 4. What is `win32/xbasic.x`?

A 28-line CRLF text file (the `file` command mislabels it "data" because of Windows
line endings). Decoded, it is a minimal XBASIC program:

```
PROGRAM "xbasic"
VERSION "0.0000"
EXPORT
	DECLARE  FUNCTION  XBasic ()
END EXPORT
'EXTERNAL FUNCTION  XxxXBasic ()
FUNCTION  XBasic ()
'	XxxXBasic ()
END FUNCTION
END PROGRAM
```

It is the **Win32 PDE's main program module**. The build (`src/Makefile:83-86,142`)
makes `xb.exe` from just `xbasic.o + xstart.o` linked against `xb.dll` — everything
else (IDE, compiler, libraries) lives in the DLL. `xbasic.x` provides the exported
`XBasic()` entry symbol for the .exe. The call to the compiler's `XxxXBasic()` is
commented out because on Win32 the real PDE entry is `Xit()` in `win32/xit.x:913`
(inside xb.dll). Linux needs no such module: its PDE executable is built directly
from `xstart.o + xit.o + xcol.o + ...` (`src/Makefile:104-111`), so `XxxXit()` in
`linux/xit.x:684` is the entry.

## 5. The `.dec` files — the Foreign-Function Interface

`include/*.dec` are **XBASIC source files that declare foreign functions and C
structs** — the FFI. The compiler reads them at `IMPORT` time. Evidence in the
compiler itself (`linux/xcol.x:27527-27558`):

```
library$ = libname$ + ".dec"
...
ifile = OPEN (library$, $$RD)
IF (ifile <= 0) THEN
    ' Retry in XBasic system directory.
    library$ = ##XBDir$ + "/include/" + libname$ + ".dec"
```

The pattern in every `.dec` file is: (a) `TYPE` declarations mirroring the C structs,
then (b) `EXTERNAL FUNCTION` declarations mirroring the C prototypes:

- `include/kernel32.dec:68-109` — `EXTERNAL FUNCTION CreateFileA (addrFilename, mode,
  azero, bzero, attr, type, czero)`, `EXTERNAL FUNCTION GetProcAddress (hinst,
  funcNameAddr)`, etc. (Win32 kernel32.dll)
- `include/user32.dec:21-32` — `TYPE WNDCLASS` + `EXTERNAL FUNCTION` list (user32.dll)
- `include/gdi32.dec:21-49` — `TYPE DOCINFO/POINTAPI/RECT/BITMAP` + functions (gdi32.dll)
- `include/wsock32.dec:6-50` — `PROGRAM "wsock32"`, `TYPE WSADATA/FD_SET/SOCKADDR_IN`
  (Winsock)
- `include/shell32.dec`, `include/winmm.dec` — shell32.dll, multimedia
- `include/clib.dec:24` — *"this file includes 'sockets' definitions equivalent of
  'wsock32' in Windows"* — the **Linux counterpart**: `TYPE OLDUSTAT` (SCO) vs
  `TYPE NEWUSTAT` (Linux), `TYPE UDIRENT`, `TYPE USIGACTION`, plus libc functions
- `include/elf32.dec:6-50` — `TYPE Elf32_Ehdr/Shdr/Phdr/Sym` — ELF binary format
  structs (Linux-only, used by the compiler's linker)
- `include/xlib.dec:1-41` — `EXTERNAL FUNCTION XxxMain ()`, `XxxSetExceptions`, the
  FPU intrinsics (`XxxFSIN`, `XxxFSQRT`, ...) — the runtime core's C-callable surface
- `include/xwin.dec:18-50` — `TYPE XKeyboardControl/XWindowAttributes` — X11 structs
  (Linux-only)

**The `.x` counterparts** (`src/linux/kernel32.x`, `user32.x`, `gdi32.x`) are the
*implementations* of the Win32 API on UNIX. Their PROLOG (identical in all three,
e.g. `kernel32.x:13-41`) states the portability strategy explicitly:

> "This program implements part of the kernel32 portion of the Microsoft Windows
> Win32 API for UNIX programs... When a program running on Windows/WindowsNT calls a
> Windows API function, the Windows API function is directly invoked. When the same
> program running on UNIX calls a Windows API function, the Windows API function does
> not exist, but a function in this library with the same name does, and is thus
> invoked in the same manner as the Windows function."

So a program that calls `CreateFileA`/`GetProcAddress`/`BitBlt` compiles unchanged on
both platforms: on Windows the call binds to the real DLL (via the `.dec`
declarations), on Linux it binds to the XBASIC reimplementation in
`kernel32.x`/`user32.x`/`gdi32.x` (which in turn call X11/libc through `clib` and
`xwin`).

## 6. Assembly startup files

**`xzzz.s`** (both platforms) defines the section-end markers the runtime needs to
compute memory boundaries:
- Linux (`xzzz.s:7-25`): `_etext` (end of .text), `_edata` (end of .data),
  `_ebss` (end of .bss)
- Win32 (`xzzz.s:3-26`): `%etext`/`_XxxEndText`, `%edata`/`_XxxEndData`,
  `%ebss`/`_XxxEndBss`

**`xstart.s`** (both) is the C entry point that hands the OS arguments to the runtime:
- Linux (`xstart.s:35-52`): `main:` pushes `argc, argv, envp, envx, &main, ebp, esp,
  arg7` (arg7 = 0 for PDE, `&__StartApplication` for standalone) then `call XxxMain`.
  `appstart.s` is the standalone variant with `arg7 = &__StartApplication` hardcoded.
- Win32 (`xstart.s:22-38`): `_main/_WinMain/_WinMain@16` pushes `hInstance,
  hPrevInstance, lpszCmdLine, nCmdShow, &_WinMain, %_StartApplication, reserved,
  reserved` then `call _XxxMain`.

**`xlib.s`** contains `XxxMain` — the runtime bootstrap:
- Linux (`xlib.s:1106-1314`): stores all args, calls `initmem` (allocates the dyno
  heap), then initializes the `##` system variables: `##CODE/##CODE0/##CODEX/##CODEZ`
  from `&main` and `_etext`; `##DATA/##DATA0/##DATAX/##DATAZ` from `_dbase`/`_edata`;
  `##BSS` from `_ebss`. Finally:
```
1314: call	XxxXit_12	# start debugger or user program
```
i.e. it calls the XBASIC entry function directly — `XxxXit()` from `xit.x` (PDE) or
`xrun.x` (standalone).
- Win32 (`xlib.s:770-916`): same job with Win32 args; sets `##HINSTANCE`, `##CODE`
  from `%etext`, `##BSS` from `%ebss`, `##STACK` from `esp`; then `fnclex` +
  `call _XxxEnableFPExceptions@0`, `call _Xst@0` (initialize standard library), and
  `call _XxxStartExceptionHandler@12` (SEH exception handler from `xexcept.c`, which
  is not in this source tree — only its object file is referenced by the Makefile).

**How the interpreter runtime is linked** (`src/Makefile`):
- Linux: `%.s: %.x` → `xb $< -lib` (the XBASIC compiler emits assembly), `%.o: %.s`
  → `gcc -c`. The PDE `bin/xb` is one static executable:
  `xstart.o + xlib.o + xin.o + xcm.o + xma.o + xst.o + xgr.o + kernel32.o + gdi32.o +
  user32.o + xbiface.o + chkmem.o + xui.o + xut.o + xit.o + xcol.o + xdis.o +
  xutpde.o + xzzz.o`, linked with `-lX11 -lm -ldl` (`Makefile:161-162`). Standalone
  programs link against `libxb.a` (`appstart.o + xrun.o + runtime`).
- Win32: same `xb $< -lib` compile step, but assembly via `spasm` and linking via MS
  `link.exe`. The runtime is a **DLL**: `xb.dll` = runtime + `xit.o + xcow.o +
  xdis.o + xutpde.o` (the PDE), `xbrun.dll` = runtime + `xrun.o` (standalone), and
  `xb.exe` = `xbasic.o + xstart.o` only. `xb.def` (1,187 lines) is the export list
  that makes every `Xst*`, `Xgr*`, `Xui*`, `Xma*`, `Xcm*`, `Xin*` function and every
  `%_` intrinsic callable across the DLL boundary.

## 7. `xbiface.c` — the Linux C Glue

`src/linux/xbiface.c` (273 lines) exists because **Linux libc changed its ABI between
libc5 and libc6 (glibc)**, and XBASIC's `.dec` declarations hard-code the old struct
layouts. Its header comment (`xbiface.c:7-19`):

> "This interface tries to be compatible with different versions of libc (libc5 and
> glibc AKA libc6)... Functions xb_stat(), xb_sigaction(), xb_readdr() in this file
> provide the same function-interface and behavior as functions stat(), sigaction(),
> readdr() in libc5."

It exposes four C functions:
- `xb_stat()` (`:98`) — converts glibc's `struct stat` into the old
  `struct xb_oldustat` layout that `clib.dec:47-60` (`TYPE OLDUSTAT`) declares.
- `xb_sigaction()` (`:165`) — glibc extended the signal mask from 32 to 1024 bits, so
  `sa_mask` no longer fits in a `long`; this shim converts the XBASIC `USIGACTION`
  (a 3-long struct, `clib.dec:39-43`) to/from glibc's `sigset_t`.
- `xb_readdir()` (`:208`) — glibc's `struct dirent` has a 3-byte padding quirk
  ("PURE INSANITY" per the comment at `:226`); this shim copies fields into the
  XBASIC `UDIRENT` layout.
- `xb_getpfn()` (`:259`) — reads `/proc/<pid>/exe` to get the executable's full path
  (Linux-specific).

This is the *only* C code in the Linux tree (besides the 50-line `chkmem.c` heap
checker) — everything else is XBASIC or assembly. It is needed precisely because
XBASIC's FFI is struct-layout-exact, and glibc broke the layouts.

## 8. The portability architecture, summarized

1. **One language, one compiler, two backends.** `xcol.x`/`xcow.x` are 88.5%
   identical; the compiler emits i486 assembly for both platforms. The only compiler
   difference is the object-file/linker layer (ELF on Linux via `elf32.dec`, PE/COFF
   on Windows).
2. **A stable library API over swappable OS backends.** `xst`, `xgr`, `xin`, `xui`,
   `xma`, `xcm` present identical XBASIC-callable APIs. The platform pairs differ
   only where the OS differs (X11 vs GDI in `xgr`; libc vs Winsock in `xin`; signals
   vs SEH in `xit`/`xrun`).
3. **Win32-API-on-UNIX compatibility libraries.** `kernel32.x`/`user32.x`/`gdi32.x`
   reimplement the Windows API in XBASIC on Linux, so even programs that call Win32
   functions directly compile unchanged.
4. **Compile-time constant folding instead of a preprocessor.** `##XBSystem`/`##XBOS`
   + `$$XBSysLinux`/`$$XBSysWin32` + `IF ##CONST THEN/ELSE/END IF` gives conditional
   compilation without a separate preprocessor pass.
5. **`.dec` files as the FFI.** Every foreign function (DLL, libc, X11, ELF) is
   declared as `EXTERNAL FUNCTION` in a `.dec` file the compiler reads at `IMPORT`
   time; the same source compiles against real DLLs on Windows and XBASIC
   reimplementations on Linux.
6. **A shared assembly runtime with per-OS bootstrap.** `xlib.s` (XxxMain, memory
   model, intrinsics) is the same design on both platforms, differing only in
   assembler dialect and OS argument conventions; `xstart.s`/`appstart.s`/`xzzz.s`
   adapt entry and section boundaries.
7. **One Makefile, OS-autodetected** (`src/Makefile:19-33`), drives both trees;
   `xb $< -lib` compiles XBASIC→assembly on both platforms, then the platform
   toolchain (gcc vs spasm+link) takes over.