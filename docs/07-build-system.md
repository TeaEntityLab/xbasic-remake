# XBASIC 6.2.3 — Build, Install, and Distribution System

This chapter documents the build machinery: the two Makefiles, the template
system that generates per-program makefiles, the installation layout, and the
distribution targets.

## 1. Toolchain Overview

Building XBASIC requires a **working XBASIC compiler** (self-hosting). The
native tools used:

| Role | Linux | Win32 |
|---|---|---|
| XBASIC compiler | `xb` (pre-installed) | `xb` (pre-installed) |
| Assembler | `gcc -c` (gas via gcc) | `spasm` (SPASM assembler) |
| C compiler | `gcc -g -Wall -ggdb` | (Cygwin `gcc` for tooling) |
| Linker | `gcc ... -rdynamic -L/usr/X11R6/lib -lX11 -lm -ldl` | MS `link.exe` |
| Archiver | `ar rvs` | `lib -machine:i386` |
| Resource compiler | — | `rc` + `cvtres` |
| Environment | make + uname | make under **Cygwin** |

On Win32 the whole build runs under Cygwin; the top Makefile notes that
Cygwin's `/usr` maps to `%SystemDrive%\usr`.

## 2. Operating-System Autodetection

Both Makefiles detect the platform by probing `$OSTYPE` and falling back to
`uname`:

```make
SYSTEM=win32                      # default
ifeq '$(OSTYPE)' ''
  OSTYPE = $(shell uname)
endif
ifneq '$(findstring Linux,$(OSTYPE))' ''   # also LINUX / linux
  SYSTEM = linux
endif
```

Everything downstream branches on `$(SYSTEM)`: tool names, file extensions
(`.exe`), zip tool (`zip` vs `pkzip`), install layout, and which source
subdirectory (`src/$(SYSTEM)`) is compiled.

## 3. Top-Level Makefile (`Makefile`)

Version is defined as three parts and composed: `VERSION=6`, `PATCHLEVEL=2`,
`SUBLEVEL=3` → `VER=6.2.3`; `RELEASE=1` (RPM packaging).

### Targets

| Target | Action |
|---|---|
| `make` | `(cd src; make mkdir; make all)` — build everything |
| `make install` / `inst-bin` | Install binary tree (see §4) |
| `make clean` | Remove build artifacts and `dist/` |
| `make dist-bin` | Binary `.tar.gz` (Linux) |
| `make dist-bin-rpm` | Red Hat `.rpm` via `xbasic.spec.sed` |
| `make dist-bin-zip` | Binary `.zip` (both platforms) |
| `make dist-bin-exe` | Self-installing `.exe` via Inno Setup (`compil32 /cc XBasic.iss`) |
| `make dist-src` / `dist-src-zip` | Source distributions |
| `make dist` | Platform-appropriate default set |

`dist-*` only works from a CVS source tree, not from a source distribution.

### Installation directory (`XBDIR`)

- `XBDIR` environment variable overrides the install target.
- Linux default: `/usr/xb-$(VER)` (versioned, so a bad build never clobbers
  the working install).
- Win32: no default — `XBDIR` must be set; paths are normalized
  (`\` → `/`) and quoted if they contain spaces (e.g. `C:\Program Files\XBasic`).

### Linux install layout

```
/usr/xb-6.2.3/{bin,lib,include,templates,help,images}
/usr/xb            -> /usr/xb-6.2.3          (symlink)
/usr/bin/xb        -> /usr/xb-6.2.3/bin/xb   (symlink)
/usr/lib/libxb.a   -> /usr/xb-6.2.3/lib/libxb.a
```

### Win32 install layout

```
$(XBDIR)/bin/xb.exe  $(XBDIR)/bin/xb.dll   (PDE runtime)
$(XBDIR)/bin/xbrun.dll                    (standalone runtime)
$(XBDIR)/lib/xb.lib                       (import library)
$(XBDIR)/lib/xstart.o                     (startup object)
$(XBDIR)/lib/xb.rbj                       (compiled resources)
$(XBDIR)/include, templates, help, src
```

Both layouts receive `include/*.dec`, `src/$(SYSTEM)/*.dec`,
`src/shared/*.dec`, all `templates/*.xxx`, `templates/$(SYSTEM)/*.xxx`, and
`help/*.hlp`. Note the per-platform template and `.dec` selection:
`templates/$(SYSTEM)/*.xxx` — the system-conditional pieces of the
distribution.

## 4. The `src/Makefile` — Building the Compiler + Runtime

This is the heart of the build. Object sets are assembled per platform:

### Win32 object sets

```make
XBRTLOBJS = win32/lib/xlib.o xexcept.obj win32/xst.o win32/xin.o \
            shared/xma.o shared/xcm.o win32/xgr.o shared/xui.o \
            shared/xut.o win32/lib/xzzz.o
XBRUNOBJS = $(XBRTLOBJS) win32/xrun.o
XBLIBOBJS = $(XBRTLOBJS) win32/xit.o win32/xcow.o shared/xdis.o shared/xutpde.o
XBOBJS    = win32/xbasic.o win32/lib/xstart.o
```

Products:

- `bin/xb.lib` — import library built with `-def:win32/xb.def`.
- `bin/xb.exe` — `$(XBOBJS) + xb.rbj + xb.lib` linked with
  `kernel32.lib user32.lib gdi32.lib wsock32.lib msvcrt.lib`.
- `bin/xb.dll` — the PDE runtime: `XBLIBOBJS` (includes the IDE `xit.o`,
  compiler `xcow.o`, disassembler `xdis.o`).
- `bin/xbrun.dll` — standalone runtime: `XBRUNOBJS` (includes `xrun.o`, no
  IDE/compiler).

Resources: `win32/xb.rc` (one icon + four cursors) → `xb.res` (via `rc
-i../images/win32`) → `xb.rbj` (via `cvtres -i386`).

### Linux object sets

```make
OBJS   = linux/lib/xlib.o linux/xin.o shared/xcm.o shared/xma.o linux/xst.o \
          linux/xgr.o linux/kernel32.o linux/gdi32.o linux/user32.o \
          linux/xbiface.o linux/chkmem.o shared/xui.o shared/xut.o
XBOBJS = linux/lib/xstart.o $(OBJS) linux/xit.o linux/xcol.o \
          shared/xdis.o shared/xutpde.o linux/lib/xzzz.o
XBLIBOBJS = linux/lib/appstart.o linux/xrun.o $(OBJS) linux/lib/xzzz.o
```

Products:

- `bin/xb` — the full PDE binary: `gcc ... -rdynamic -lX11 -lm -ldl`.
  `-rdynamic` exports the binary's symbols (`nm -g bin/xb > xlabs`) so the
  dynamic loader can resolve symbols in the standalone-link model.
- `bin/libxb.a` — static library for standalone programs, `ar rvs`.

### The key pattern rules

```make
%.o: %.c            # C glue (xbiface.c, chkmem.c)
	$(CC) -c -g -ggdb $< -o $@

%.s: %.x            # XBASIC source -> assembly, using the installed compiler
	xb $< -lib

# Win32: %.o: %.s   ->  spasm  (assembler output naming differs)
# Linux: %.o: %.s   ->  gcc -c -g -ggdb $< -o $@
```

So every `.x` file becomes `.s` (via `xb`), then `.o` (via gcc/spasm), then
is linked. The **entire IDE, compiler, and libraries are compiled XBASIC**.

### The Linux platform `.dec` files

`linux/kernel32.x`, `linux/gdi32.x`, `linux/user32.x` are compiled as `.dec`
declaration files (the pattern rule `%.s: %.x` produces them; the clean rule
removes `linux/*.dec`). This is the Linux side of the FFI story — see
[`06-cross-platform.md`](./06-cross-platform.md).

## 5. The Template System (`.xxx` files)

The PDE generates new programs, makefiles, and DLL stubs from **templates**
in `templates/`. When you compile `prog.x`, the PDE copies the appropriate
template and substitutes the program name to produce `prog.mak` (the
makefile that builds the standalone executable).

> "This xapp.xxx file is a template file XBasic modifies to create makefiles
> for programs when it compiles them. When XBasic compiles program prog.x it
> creates makefile prog.mak based on this xapp.xxx file."
> — `templates/linux/xapp.xxx`

### Template inventory

| Template | Purpose |
|---|---|
| `prolog.xxx` | PROLOG skeleton (PROGRAM/VERSION/IMPORT/declarations) inserted into new programs |
| `entry.xxx` | `Entry()` function skeleton — execution start |
| `code.xxx` | `Code()` grid callback skeleton generated by GuiDesigner (with `#Callback`, `#Selection`, `#TextEvent`, `#CloseWindow` message handling) |
| `create.xxx` | `CreateWindows()` — GuiDesigner writes window-creation code here; guarded with `IF LIBRARY(0) THEN RETURN` |
| `gentry.xxx`, `gprolog.xxx` | Grid/GuiDesigner variants |
| `initgui.xxx` | GuiDesigner initialization skeleton |
| `initprog.xxx`, `initwins.xxx` | Program/window init skeletons |
| `message.xxx` | Message-callback documentation block |
| `property.xxx` | Property/defaults for new programs |
| `intro.xxx`, `start.xxx`, `first.xxx`, `title.xxx` | Startup banners / "automatic installation in progress" text (per platform) |
| `xtool0/1/2.xxx`, `xtoolkit.xxx` | Toolkit windows templates |
| `version.xxx`, `expire.xxx`, `name.xxx` | Version/expiry/name fragments |
| `linux/xapp.xxx` | **Linux program makefile generator** |
| `linux/xdll.xxx` / `linux/xlib.xxx` | **Linux library makefile generator** |
| `win32/xapp.xxx` | **Win32 program makefile generator** (`!include <xbasic.mak>`) |
| `win32/xdll.xxx` | **Win32 DLL makefile generator** |
| `win32/xstart.xxx` | Win32 startup assembly fragment (pushed into generated `.s`) |
| `win32/syslib.xxx` | List of importable Windows system libraries (DLLs) |
| `win32/win32api.xxx` | 2,144-line database mapping Win32 API functions → classification + `.lib` |
| `linux/font.xxx` / `fonts.xxx`, `win32/font.xxx` / `fonts.xxx` | Font registration lists |
| `copx.bin`, `zcharmap.bin` | Binary data (copx: copy/paste helper data; zcharmap: character map) |

### Linux program makefile template (`linux/xapp.xxx`)

```make
APP      = xapp
XB       = .
XBLIB    = $(XB)/lib
STDLIBS  = -L/usr/X11R6/lib -lxb -lX11 -ldl

$(APP): $(APP).mak $(APP).x $(APP).o
	$(CC) $(CFLAGS) $(APP).o $(LIBS) -rdynamic $(STDLIBS) -o $(APP)

%.o: %.s
	gcc -c -g -ggdb $< -o $@

%.s: %.x
	xb $< -lib
```

### Win32 program makefile template (`win32/xapp.xxx`)

```make
APP   = xapp
LIBS  = xb.lib
START =

!include <xbasic.mak>

$(APP).exe: $(APP).o
	$(LD) $(LDFLAGS) -out:$(APP).exe xstart.o $(APP).o $(RESOURCES) $(LIBS) $(STDLIBS)

$(APP).s: $(APP).x
	$(START) xb $(APP).x
```

Note the platform differences: Linux links `libxb.a` + X11 + dl; Win32 links
`xstart.o` + `xb.lib` (import lib for `xb.dll`/`xbrun.dll`).

### DLL vs static-library capability — an explicit limitation

Both Linux templates carry the same warning:

> "Currently XBasic cannot create dynamic linked DLL 'shared libraries'
> because XBasic does not generate 'position independent code' ALA -PIC. But
> XBasic can create object file libraries you can statically link to
> programs, however. This requires you compile with a -lib switch, as in
> 'xb prog.x -lib'."

So on Linux, XBASIC produces only static `.a` archives; on Win32, DLLs work
(because the linker + `.def` files handle fixups). The `-lib` compiler switch
selects library compilation. `win32/xdll.xxx` shows the DLL path: link with
`$(LDFLAGS_DLL) -def:$(APP).def`.

### The Win32 API database (`win32api.xxx`)

A flat table, one Win32 API per line:

```
FunctionName,classification,AnsiAndUnicode?,widened?,library
_hread,widened,,Y,kernel32.lib
AbortDoc,widened,,Y,gdi32.lib
AddAtom,widened,Ansi and Unicode,Y,kernel32.lib
accept,new,,Y,wsock32.lib
AdjustTokenPrivileges,new,,N,advapi32.lib
```

Each API is classified (`widened` / `new` / `dropped` / `changed` /
`macro`), flagged for Ansi/Unicode variants, and mapped to its import
library. This drives the Win32 FFI so XBASIC can `DECLARE FUNCTION` nearly
any Win32 API and import it. `syslib.xxx` lists the importable DLLs
(kernel32, user32, gdi32, wsock32, winmm, shell32, comctl32, msvcrt,
opengl32, ...).

## 6. Build Order and Bootstrap

```
make                      (top-level)
  └─ src/make mkdir
  └─ src/make all
       ├─ (existing xb compiles each .x -> .s -> .o)
       ├─ Linux: link bin/xb   + bin/libxb.a
       └─ Win32: rc -> cvtres; lib -> xb.lib; link xb.exe, xb.dll, xbrun.dll
```

Because the compiler is self-hosted, a *new* compiler cannot be produced from
scratch — the installed `xb` compiles the sources into the new binary. The
README notes that even the compiler `xcol.x` can be run inside the
development environment if you respect the `/xxx/` path conventions noted at
the top of its source, and warns that forgetting them causes "endless and
unexplainable troubles".

## 7. Runtime Linkage Details

- **Linux `-rdynamic`**: makes all global symbols of `xb` available to
  `dlopen`/dynamic resolution — needed because compiled user programs call
  back into runtime symbols (`%_concat...`, `Xxx*`, etc.).
- **`nm -g bin/xb > xlabs`**: dumps the symbol table to `xlabs` after
  linking — used by the IDE's symbol/debug facilities.
- **Win32 `/NODEFAULTLIB`** with explicit `LIBS` line: the runtime supplies
  its own memory management and imports only `kernel32 user32 gdi32
  wsock32 msvcrt` — keeping the DLL surface minimal and controlled.
