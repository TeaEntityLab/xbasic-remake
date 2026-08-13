# 09 — Version History and Fork Lineage

This chapter documents what happened to XBASIC **after** 6.2.3. It compares the
three source trees now present in the workspace:

| Tree | Nature | Binary | Architecture |
|---|---|---|---|
| `xbasic-6.2.3/` | official 6.2.3 release (2002-10-26) | `xb` / `libxb.a` | 32-bit i486, Linux + Win32 |
| `xbasic-6.3.26-D/` | unofficial Win32 continuation | `xb.exe` / `xb.dll` | 32-bit PE, Win32 only |
| `xbasic-6.4.5/` | Linux 64-bit port | `xb64` / `libxb64.a` | 64-bit x86-64 ELF, Linux only |

The short version: **6.2.3 is the last release where Linux and Windows lived in one
tree.** After that the project forked along platform lines. 6.3.26-D dropped Linux
support and grew for two decades as the Win32 "unofficial" series (v6.3.1 →
v6.3.26-C, 2011–2022). 6.4.5 dropped Win32 support and became the Linux 64-bit
port (`xb64`), hand-converting the compiler and the assembly runtime to x86-64.

## 1. Provenance

### 1.1 The official era (from `help/changelog.hlp`)

The changelog file (kept in the 6.3.26-D tree, 900 lines) documents the official
history up to 6.2.3:

- **v6.0000 (2000-01-15)** — Linux XBasic brought into sync with Windows XBasic;
  both released under GPL/LGPL. This is the baseline "one codebase, two OSes".
- **v6.0012 (2000-05-28)** — "Linux XBasic and Windows XBasic v6.0012 are in-sync."
- **v6.1.0 (2000-05-14)** — "Reorganized directory structure. **Merged windows and
  linux source.**" This created the `src/{shared,linux,win32}` layout that 6.2.3
  still has.
- **v6.2.x (2000–2002)** — Eddie Penninkhof maintenance series. **v6.2.3
  (2002-10-26)** is the last official release.
- The "Unofficial" label first appears at v6.3.0/v6.3.1 — the changelog's `v6.3.0`
  header literally says "to be released", and from v6.3.13 onward every entry is
  marked `(Unofficial)` with dates in 2011–2022.

### 1.2 The `src/CHANGES` file — the shared fork point

Both newer trees contain an **identical** `src/CHANGES` file, dated April 2000 and
signed by Eddie Penninkhof. It records:

- `mkxbvars` utility created (generates `xbvars.bat`).
- `xapp.xxx` adapted for the multi-directory structure.
- `xut.x` split into `xut.x` + `xutpde.x` (`xutpde.x` used ONLY by the PDE).
- XBasic base-directory retrieved from the executable's full path (overridable via
  the `XBDIR` environment variable).
- Inno Setup script created (win32).
- Command-line parsing now handles quotes (`"c:\Program Files\XBasic\bin\xb.exe"` is
  one argument).
- File Load/Save default to the current directory; `XuiFile` no longer skips
  archive-bit directories.

This file is the **fork point**: both 6.3.26-D and 6.4.5 descend from the same CVS
trunk of ~April 2000 and then diverged.

### 1.3 File-date evidence

`find` + `ls -lT` across the three trees:

- 6.2.3 — every file dated 2002-10-27 (a clean release snapshot).
- 6.3.26-D — files span 2008 → 2023. `src/Makefile` 2022-05-13, `README.Win32`
  2022-05-16, `PreCompileXB.bat` 2022-05-16 (v6.3.26-C era), `demo/` refreshed
  2023-12-13. The `-D` suffix in the directory name is a local snapshot marker.
- 6.4.5 — files span 2013 → 2023. `src/bin/xb64` 2023-08-28, `README.Linux`
  2023-04-08, `Makefile` 2023-08-24. The `crtl/` C-runtime sources are dated
  2013-11-26 (abandoned experiment, see §4).

## 2. The three trees at a glance

| Aspect | 6.2.3 (official) | 6.3.26-D (Win32 fork) | 6.4.5 (Linux 64 fork) |
|---|---|---|---|
| Top-level `src/` dirs | `shared/ linux/ win32/ lib/` | `shared/ win32/ bin/` | `linux/ shared/ crtl/ util/ bin/` |
| Compiler source | `linux/xcol.x` + `win32/xcow.x` (twins) | `win32/xcow.x` only | `linux/xcol.x` only |
| Prebuilt binaries in tree | none | `src/bin/xb.exe, xb.dll, xbrun.dll` + MS toolchain | `src/bin/xb64, libxb64.a` |
| Runtime | assembly `lib/xlib.s` etc. | assembly `win32/lib/xlib.s` etc. | assembly `linux/lib/xlib.s` (hand-converted to 64-bit) + **experimental C rewrite `crtl/`** |
| `include/` `.dec` files | 10 | 10 + `win32/` subdir | **21** (adds GTK2, sqlite3, ssh, elf64) |
| `templates/` | `linux/` + `win32/` | `win32/` only (linux/ removed) | `linux/` only (win32/ removed) + new top-level `fonts.xxx`, `xapp.xxx` |
| `help/` files | 9 | 16 (adds changelog, index, lang, xgr/xst/xui...) | 16 (same set) |
| `demo/` | absent | 109 `.x` files | 114 `.x` files + `demo/gtk/` |
| Packaging | — | Inno Setup (`XBasic.iss`), `xbasic.spec`, `xbinstall.bat` | `xbasic.spec` |
| Line endings | CRLF | LF | LF |

**Structural headline**: neither fork kept the 6.2.3 pattern of *platform twins in
one tree*. 6.3.26-D deleted `src/linux/`, `templates/linux/`, and `README.Linux`;
6.4.5 deleted `src/win32/` and `templates/win32/`. Cross-platform portability — the
core architectural property documented in chapter 06 — exists in **no** post-6.2.3
tree as shipped.

## 3. What changed between 6.2.3 and 6.3.26-D (Win32 fork)

All diffs below were computed with `diff --strip-trailing-cr` (6.2.3 is CRLF, so a
raw `diff` overstates changes). Line counts are normalized.

### 3.1 Version-header table

| File | 6.2.3 VERSION | 6.3.26-D VERSION | Diff | Verdict |
|---|---|---|---|---|
| `shared/xcm.x` | 0.0007 | 0.0007 | 16 | minor |
| `shared/xdis.x` | 0.0017 | 0.0017 | 47 | bug fixes |
| `shared/xma.x` | 0.0019 | 0.0019 | 65 | bug fix + comments |
| `shared/xui.x` | 0.1176 | **6.3.26** | 12,238 | major rewrite |
| `shared/xut.x` | 0.0001 | 0.0001 | 52 | env-var logic |
| `shared/xutpde.x` | 0.0001 | 0.0001 | 12 | cosmetic |
| `win32/xbasic.x` | (none) | 0.0000 | 0 | byte-identical |
| `win32/xcow.x` | 0.0342 | **6.3.26** | 18,777 | major rewrite |
| `win32/xgr.x` | 0.0442 | **6.3.26** | 6,842 | major rewrite |
| `win32/xin.x` | 0.0030 | 0.0031 | 10 | minor |
| `win32/xit.x` | 0.0370 | **6.3.26** | 9,435 | major rewrite |
| `win32/xrun.x` | 0.0038 | 0.0038 | 52 | moderate |
| `win32/xst.x` | 0.0333 | **6.3.26** | 6,838 | major rewrite |

Pattern: the five "core" modules (`xui`, `xcow`, `xit`, `xst`, `xgr`) were
re-versioned to the release string **"6.3.26"**; the utility modules (`xcm`, `xdis`,
`xma`, `xut`, `xutpde`, `xin`, `xrun`) kept their independent micro-versions.

### 3.2 Nature of the changes

- **`xcow.x` (compiler, 18,777 lines)** — the deepest structural change. New
  `TYPE TOKIX` / `TYPE TAKS` / `TYPE TOKEN` (union of ULONG + byte fields) replaces
  bare `XLONG .token`; dozens of signatures changed (`AddLabel`, `AddSymbol`,
  `AlloToken`, `AssignAddress`, `CheckState`, `CloneArrayTOKEN`, ...). `.def`
  generation now uses `"EXPORTS  " + $$ulpc4$ + "blowback_"` instead of a literal
  `%%%%blowback_`. `IMPORT "user32"` added.
- **`xui.x` (GUI library, 12,238)** — new exports `XuiEditCopy/Cut/Paste`,
  `XuiGetKidGridNumber`, `XuiMessageRetry`, `XuiRestoreWindow`, `XuiTextArea2B`,
  `XuiGetTextArrayBounds`, `XuiGetTextFlag`, `XuiSetTextFlag`, `XuiFindFiles`,
  `XuiGetFiles`; `XuiPlaceWindow` signature changed (`mode` → `windowType`);
  `DECLARE` → `INTERNAL` conversions; **`XuiDirectoryBox` and `XuiFileBox`
  deleted** (46 refs → 2 comments).
- **`xit.x` (PDE, 9,435)** — `EXCEPTION_RECORD`/`FLOATING_SAVE_AREA` types
  commented out (moved to xst/xcow); TOKEN types added; `IMPORT "user32"` added,
  **`IMPORT "xutpde"` removed**; `XxxXitMain` renamed `XitMain`; new
  `SUB XrunXitMain`.
- **`xst.x` (standard library, 6,838)** — memory-map type fields `XLONG` → `ULONG`;
  `IMPORT "shell32"`; **`XstGetTypedArray` deleted**; ~40 new functions (console,
  preferences, file-select, parse, random, task, recycle-bin, SaveArray/LoadArray).
- **`xgr.x` (graphics, 6,842)** — new `MINMAXINFO`/`SIZEMOVE`/`TRACKMOUSEEVENT`
  types; `IMPORT "xui"`; new curve/ellipse/circle drawing functions.
- **`xdis.x` (disassembler)** — new `SUB Fwait`; `INT 0xCD` fix (`ReadImm16` →
  `ReadImm8`); `##WHOMASK` save/restore.
- **`xut.x`** — `XutInit()` now sets `XBDIR`/`INCLUDE`/`LIB`/`PATH` if `XBDIR` is
  undefined (new `SUB CheckEnvVar`), defaulting to `C:\xb`.
- **`xrun.x`** — `XxxGetLabelGivenAddress` relocated; new `XxxXstLog` external;
  standalone error path (message box + `RETURN (199)`); `$$ExceptionTerminate`
  → `ExitProcess(0)`.

### 3.3 Assembly runtime (`win32/lib/`)

| File | Diff | Change |
|---|---|---|
| `xlib.s` | 210 | new `%_ArrayInvalidType`, `%_ArrayInvalidDimension`; giant↔single/double conversions commented out; `XxxFPREM1@16` removed |
| `xstart.s` | 51 | **repurposed from standalone-startup to PDE `xb.exe` startup**; `arg5 = %_StartApplication` now pushed as `0x00000000` ("zero for PDE") |
| `xzzz.s` | 0 | identical |
| `appstart.s` | **NEW** | standalone-program startup stub (VERSION 0.0001); pushes `%_StartApplication` and calls `_XxxMain` |

This is the **PDE/standalone split**: `xstart.s` bootstraps the PDE, `appstart.s`
bootstraps user standalone programs — mirroring the 6.2.3 `xrun.x`/`appstart.s`
division but now explicit at the assembly level.

### 3.4 `xb.def` export list

- 6.2.3: 1,187 lines, `VERSION 6.0022`, 1,178 EXPORTS (360 `%_`).
- 6.3.26-D: 1,302 lines, `VERSION 6.0024`, 1,291 EXPORTS (378 `%_`).

**Truly deleted exports (4):** `XstGetTypedArray`, `XgrSetMouseFocus`,
`XuiDirectoryBox`, `XuiFileBox`. Anything in 6.4.5 or user code referencing these
four will not link on the Win32 fork.

**Notable additions:** exception/memory helpers (`XxxGetExceptions`,
`XxxSetExceptions`, `XxxZeroMemory`), `%_ArrayInvalidType/Dimension`, `%_high0/1`,
`%_signed.*`, `%_string.*`; math intrinsics `EXPE`, `EXPX`, `EXP2`; ~40 `Xst*`
(console, prefs, file-select, parse, random, tasks); ~20 `Xgr*` (curve, ellipse,
circle, fill); ~12 `Xui*` (edit, menu, text, window); `XxxFormat$`,
`XxxXstBlowback`, `XxxXstLoadLibrary`, `XxxXinBlowback`.

### 3.5 New in the 6.3.26-D tree

- **`src/win32/`**: `win32.api` + `win32api.csv` + `win32api.xxx` (MSDN-style API
  databases; `.api`/`.xxx` are byte-identical), `xbasic.mak`, `xrun.mak`,
  `xexcept.c` (`XxxStartExceptionHandler()` wrapping `Xit()` in `_try/_except`),
  `xbvars.bat`, `grep.exe.stackdump` (Cygwin crash artifact).
- **`src/bin/`**: prebuilt `xb.exe`, `xb.dll`, `xbrun.dll`, import libs, plus a
  full Win32 toolchain (`link.exe`, `lib.exe`, `rc.exe`, `cvtres.exe`, `nmake.exe`,
  `spasm.exe`).
- **`src/`**: `xb.rbj` (COFF resource object), `xb.res`, `XBasic.iss` (Inno Setup),
  `helpsrc/` (help builder + text sources), `CHANGES`.
- **top-level**: `lib/*.lib` (11 import libs), `include/win32/` (`xbasic.mak`,
  `xrun.mak` nmake includes), `demo/` (109 programs), `CHANGES` ("See:
  help/changelog.hlp"), expanded `README.Win32`, `xbinstall.bat`,
  `PreCompileXB.bat`, `MakeInstall630.rtf`, `xbasic.spec`, `XBasic.iss.sed`,
  `xbdelay.iss`.
- **Deleted**: `src/linux/` entirely, `templates/linux/`, `templates/win32/xstart.xxx`,
  `README.Linux`.

### 3.6 Win32 build flow

`xb (compiler) → .s → spasm (assembler) → .o → link (linker) → .exe/.dll`, with
`xb.rbj` as the resource object and `appstart.o`/`xstart.o` as entry stubs. Shared
toolchain settings live in `include/win32/xbasic.mak`
(`LD=link`, `AS=spasm`, `XB=xb`, `STDLIBS=msvcrt kernel32 advapi32 user32 gdi32
comdlg32 winspool`); per-app drivers are `src/win32/xbasic.mak` and
`src/win32/xrun.mak`.

## 4. What changed between 6.2.3 and 6.4.5 (Linux 64-bit fork)

### 4.1 Version-header table

| File | 6.2.3 VERSION | 6.4.5 VERSION | Diff | Verdict |
|---|---|---|---|---|
| `linux/xcol.x` | 0.0211 | **6.4.5** `'64-bit version` | 36,607 | the 64-bit rewrite |
| `linux/xit.x` | 0.0419 | **6.4.5** | 15,538 | CPUCONTEXT 64-bit |
| `linux/xst.x` | 0.0228 | **6.4.5** | 8,872 | GIANT file times |
| `linux/xgr.x` | 0.0515 | **6.4.5** | 16,338 | SLONG + scaled coords |
| `linux/xin.x` | 0.0100 | **6.4.5** | 1,639 | SLONG sockets |
| `linux/xrun.x` | 0.0047 | **6.4.5** | 191 | ptregs |
| `linux/gdi32.x` / `user32.x` | 0.0000 | 0.0000 | 0 | byte-identical |
| `linux/kernel32.x` | 0.0001 | 0.0001 | 50 | dlopen soname |
| `linux/xgrids.x` | (no header) | — | moved | **deleted → `demo/xgrids.x`** |
| `shared/xui.x` | 0.1176 | **6.4.5** | 15,781 | rbp frame-walk |
| `shared/xma.x` | 0.0019 | **6.4.5** | 201 | ASINH rewrite |
| `shared/xcm.x` | 0.0007 | 0.0007 | 91 | cosmetic |
| `shared/xdis.x` | 0.0017 | **6.4.5** | 832 | REX / 64-bit disasm |
| `shared/xut.x` | 0.0001 | 0.0001 | 12 | whitespace |
| `shared/xutpde.x` | 0.0001 | 0.0001 | 14 | whitespace |
| `src/win32/*` | — | — | — | **entire win32/ tree removed** |

### 4.2 The 64-bit conversion — how it was actually done

The 64-bit port was **two parallel hand-edited tracks** — *not* a rewrite and *not*
the crtl/ C project:

1. **Compiler (`xcol.x`)** — retitled `VERSION "6.4.5" '64-bit version`; the
   instruction-name table (`op$`) changed `movl/leal/pushl/subl/addl/popl` →
   `movq/leaq/pushq/subq/addq/popq`; register equivalences gained 64-bit names
   (`$$rax=$$R14`, `$$rdx=$$R15`, `$$rbx=$$R16`, `$$rcx=$$R17`, `$$r8=$$R18`,
   `$$r9=$$R19`, keeping 32-bit names as distinct abstract registers);
   `reg86$` gained `%rax/%rsp/%rbp/%r8/%r9`; the accumulator moved from
   `acc = $$R10` (eax) to `acc = $$R14` (rax); a REX prefix `0x48` is emitted for
   8-byte immediates (line 8367). Generated `.s` files are confirmed 64-bit
   (`subq $0x100,%rsp` prologues).
2. **Runtime (`xlib.s`)** — hand-converted `pushl/movl` → `pushq/movq`,
   `.long` → `.quad` for argc/argv/envp globals, calling convention switched from
   32-bit stack args to **SysV AMD64 registers** (rdi/rsi/rdx/rcx/r8/r9);
   `XxxMain` now calls `XxxXit_24` (was `XxxXit_12`). Backups
   `xlib230325.s` / `xlib230803.s` document the conversion timeline (2023).

Build logic: `AS=gcc`, `AFLAGS = $(CFLAGS) -c -m64`, `CFLAGS += -no-pie -Wall`;
pattern rules `%.s: %.x` → `xb64 $< -lib`, `%.o: %.s` → `gcc -m64 -c`,
`%.o: %.c` → `gcc -c -g -m64`. Outputs renamed `bin/xb64` + `bin/libxb64.a`.

### 4.3 Data-model fallout (64-bit types)

- **`xit.x`** — `CPUCONTEXT` rewritten: `.edi/.esi/.ebp/.esp/.ebx/.edx/.ecx/.eax/.eip`
  → `.r8..r15/.rdi/.rsi/.rbp/.rbx/.rdx/.rax/.rcx/.rsp/.rip`; exception-context
  functions take `rbp`.
- **`xst.x`** — `FILEINFO` now uses `GIANT` (64-bit) for create/access/modify times
  and size; 64-bit file-pointer comments.
- **`xgr.x`** — `WINGRID` `XLONG` → `SLONG`; new `gridBox*`/`xPixelsPerScaled`
  scaled-coordinate fields; "On 64-bit software 32-bit data is padded with zeros to
  64-bits" (line 18315).
- **`xin.x`** — `SOCKET`/`HOST` `XLONG` → `SLONG`; new `getifaddrs`/`getnameinfo`
  FFI (`XxxXinGetIfaddrs`, `XxxXinGetNameInfo`, ...).
- **`xdis.x`** — `XxxDisassemble$` → `XxxDisassemble64$`, `GetAddrLabel$` →
  `GetAddrLabel64$`, `SetRexW`/`SetRex`, `opsiz` 8/16/32/64, `$MOVABS=257`,
  `ReadImm64`.
- **`xrun.x`** — `XxxXitMain(sigNumber, ptregs)` (ptregs = 64-bit signal context);
  new `XxxXitSigAlrm`.
- **`xbiface.c`** — `_LARGEFILE_SOURCE`/`_LARGEFILE64_SOURCE`/
  `_FILE_OFFSET_BITS 64`; `xst_size` → `long long`; dirent `d_ino/d_off` →
  `long long` + `d_type`.
- **`kernel32.x`** — `LoadLibraryA` now does Linux soname resolution (`lib`+name+
  `.so`, `libc.so → libc.so.6` special case, `dlopen(&soname$, 2)`).
- **`xui.x`** — frame walking `xebp → xrbp`; new `IMPORT "user32"` and ~15 new
  Xui* functions.

### 4.4 The `crtl/` C runtime — an abandoned experiment

`src/crtl/` contains `README`, `xbxtrns.c`, `xconst.h`, `xlib.c`, `xstart.c`,
`Xzzz.c` (~940 lines total). The README says:

> "These files are the beginning of the conversion of the XBasic runtime library
> from Assembly to C. These sources are highly experimental and not yet working."

Findings:

- **Not built.** Zero references in `src/Makefile` or `src/util/Makefile`; only the
  top-level `Makefile` ships them in the dist tarball. `libxb64.a` contains only
  assembly-derived objects.
- **Cannot compile.** `xstart.c` includes `"xlib.h"` and `"xbconst.h"`, neither of
  which exists anywhere in the tree. `xlib.c`'s `XxxMain` calls `initmem` and
  references `xb_dbase` — undefined.
- **No intrinsics.** `xbxtrns.c` declares data globals plus a `stub()` function
  "to make this a compilable file". No `XxxFSIN`/`XxxG`/`XxxGetEbpEsp`.
- Dated 2013-11-26. It predates the 2023 64-bit conversion and was written against
  the 32-bit assembly (stack-based `XxxMain` args).

**Conclusion**: crtl/ is a 2013 abandoned skeleton, distribution-only. The real
runtime in 6.4.5 is still the hand-converted 64-bit assembly.

### 4.5 New .dec bindings and demo content

- `include/` grew 10 → **21** `.dec` files: **GTK2 family** (`gtk-x11-2.0.dec`
  9,683 lines, `gdk-x11-2.0.dec`, `glib-2.0.dec`, `gio-2.0.dec`, `gobject-2.0.dec`,
  `gdk_pixbuf-2.0.dec`, `gmodule-2.0.dec` — by Liviu Armeanu, 2009), `sqlite3.dec`,
  `ssh.dec`, `ssh2.dec`, `elf64.dec` (Elf64 types for 64-bit ELF reading),
  `xbasic.dec`, `xin.dec`, `xma_old.dec`.
- `src/linux/` and `src/shared/` now carry **generated artifacts** next to sources:
  compiled `.s` (e.g. `xui.s` 298,334 lines) and `.dec` declaration files
  (`gdi32.dec`, `xgr.dec`, `xst.dec`, `xui.dec`, ...). 6.2.3 kept `.dec` in
  `include/` and produced `.s` on demand.
- `demo/` has 114 programs plus a new `demo/gtk/` set (helloworld, buttons, menu,
  notebook, ...).
- `templates/` gained top-level `fonts.xxx` and `xapp.xxx`; `property.xxx` changed
  the most (856 diff lines).
- `src/util/mkxbvar.c` — Win32-only utility (windows.h, MSVC) carried into the
  Linux tree; unrelated to the port.
- `src/bin/readelf_xb.txt` — **stale ELF32 dump (2018)**; do not use it as evidence
  about `xb64` (which is ELF64, 2023).

## 5. The shared library surface — three-way reconciliation

The four deleted exports on the Win32 fork (`XuiDirectoryBox`, `XuiFileBox`,
`XgrSetMouseFocus`, `XstGetTypedArray`) are still present on the Linux fork
(6.4.5 kept the 6.2.3-era xui.x grid-file dialogs). Conversely, the Win32 fork's
TOKEN-type compiler refactor (`xcow.x`) has no counterpart in 6.4.5's `xcol.x`,
and the 64-bit data-model changes (SLONG/GIANT/CPUCONTEXT) have no counterpart in
6.3.26-D. Any unification must merge these divergent surfaces (see chapter 10).

## 6. Timeline summary

```
2000-01-15  v6.0000   Linux/Windows in sync, GPL/LGPL
2000-05-14  v6.1.0    "Merged windows and linux source" → shared/{linux,win32} layout
2000-04     src/CHANGES fork point (Eddie Penninkhof)
2002-10-26  v6.2.3    last official release (this repo's baseline)
2008-2023   6.3.x     "Unofficial" Win32 continuation (v6.3.1 → v6.3.26-C 2022-05-20)
2013-11-26  crtl/     C-runtime rewrite started, abandoned ("not yet working")
2018-06-08  v6.3.26   (Unofficial) — core modules re-versioned to "6.3.26"
2022-05-20  v6.3.26-C last Win32 changelog entry
2023        xb64      Linux 64-bit port: xcol.x emitter + xlib.s hand-converted
2023-08-28  6.4.5     xb64 built, libxb64.a
```
