# 10 — Unification Plan: merging 6.3.26-D + 6.4.5 back into one tree

> **Lifecycle: historical proposal / superseded architecture.**
> This August 2026 pre-Rust fork-unification plan is preserved as design
> provenance. The implemented bootstrap architecture is documented in docs 13
> and 14; current contracts and open work are governed by docs 16–19, with
> docs/17 as the umbrella authority.


This chapter is a **proposal**, not an implemented change. It describes how to
recombine the two post-6.2.3 forks — `xbasic-6.3.26-D` (Win32) and `xbasic-6.4.5`
(Linux 64-bit) — into a single cross-platform tree that restores the 6.2.3
architecture documented in chapters 06 and 07: one compiler with two backends,
platform twins over shared code, `.dec`-driven FFI, and constant-folding
conditionals.

The goal mirrors what 6.2.3 achieved, but with the 21 years of fork improvements
merged instead of discarded:

- Win32 fork's contributions: `xcow.x` TOKEN-type compiler refactor, 16 years of
  Win32 PDE/GUI fixes, the PDE/standalone `xstart.s`/`appstart.s` split, the
  win32api databases, Inno Setup packaging.
- Linux fork's contributions: the 64-bit port (`xb64`), SysV AMD64 runtime, GIANT
  file times, GTK2/sqlite/ssh `.dec` bindings, `demo/gtk/`, Linux build fixes.

## 1. Current-state summary (what must be reconciled)

| Dimension | 6.3.26-D (Win32) | 6.4.5 (Linux64) |
|---|---|---|
| Compiler | `xcow.x` (TOKEN refactor, 32-bit) | `xcol.x` (64-bit emitter) |
| `xst.x` | XLONG→ULONG mem map; deletes `XstGetTypedArray`; +~40 fns | GIANT file times/sizes; +~40 fns (overlapping but not identical) |
| `xgr.x` | 32-bit WINGRID; deletes `XgrSetMouseFocus` | SLONG WINGRID + scaled coords |
| `xui.x` | deletes `XuiDirectoryBox`/`XuiFileBox` | keeps them (6.2.3-era) |
| `xit.x` | `XitMain`, no xutpde import | CPUCONTEXT r8-r15, ptregs |
| runtime | 32-bit `xlib.s`; `xstart.s`=PDE, `appstart.s`=standalone | 64-bit `xlib.s` (SysV AMD64); crtl/ abandoned |
| `xdis.x` | 32-bit disasm fixes | `XxxDisassemble64$`, REX |
| `.dec` | 10 + win32 subdir | 21 (GTK2, sqlite3, ssh, elf64) |
| `xb.def` | VERSION 6.0024, 1,291 exports | (Linux has no .def — exports are in xit.x/symbol table) |
| build | nmake + spasm + link.exe | gcc + `-m64` |

The unification strategy is **"6.2.3 structure, fork contents, new version"**:
restore the `src/{shared,linux,win32}` twin layout, then merge each module's two
versions into one source that compiles on both platforms using the existing
`##XBSystem`/`$$XBSysLinux`/`$$XBSysWin32` constant-folding mechanism.

## 2. Guiding constraints

1. **Do not rewrite the runtime in C.** crtl/ is a 2013 abandoned skeleton that
   cannot compile. The unification should either delete it or move it to a
   `research/` directory. The assembly runtime is the only real runtime.
2. **Keep the 64-bit compiler as the single compiler.** The TOKEN refactor
   (xcow.x) and the 64-bit emitter (xcol.x) must be merged into one `xcol.x`
   (Linux twin) / `xcow.x` (Win32 twin) pair — or, better, one shared compiler
   core with `##XBSystem` conditionals (see §4.1).
3. **Binary compatibility is not a goal.** `xb.def` VERSION can change; the export
   list will change. Source compatibility for user programs IS a goal — but the
   four Win32-deleted exports (`XuiDirectoryBox`, `XuiFileBox`,
   `XgrSetMouseFocus`, `XstGetTypedArray`) must be decided on, not silently dropped
   from one platform.
4. **Produce the tree, not the binaries.** The plan ends at a unified source tree
   that builds on both platforms from a single Makefile. Shipping binaries is
   out of scope.
5. **Everything is verifiable.** Each phase ends with a build + smoke test on both
   platforms (or, when the platform is unavailable, a compile-only check via the
   other twin).

## 3. Target tree layout

```
<repo root>/                      (6.5.0; historical C-tree layout — superseded by the Rust workspace, see docs/13)
├── Makefile                       top-level driver (OS autodetect, as 6.2.3)
├── src/
│   ├── Makefile
│   ├── shared/                    merged xui, xma, xcm, xdis, xut, xutpde
│   ├── linux/                     merged xcol, xit, xst, xgr, xin, xrun,
│   │                              xbiface.c, chkmem.c, xgrids.x (restored)
│   ├── win32/                     merged xcow, xit, xst, xgr, xin, xrun,
│   │                              xbasic.x, xb.def, xb.rc, xexcept.c
│   └── lib/                       assembly runtime — linux/lib and win32/lib
├── include/                       merged .dec (the 21 from 6.4.5 + win32 extras)
├── templates/                     linux/ + win32/ restored
├── help/                          16-file set
├── demo/                          merged demos (114 + 109, dedup)
├── research/crtl/                 (moved abandoned C-runtime experiment)
└── doc/, lib/ (win32 import libs), xbasic.spec, README.{Linux,Win32}
```

## 4. Phase-by-phase plan

### Phase 0 — Rebase and baseline (verify assumptions)

1. Historical tree-merge option: copy `xbasic-6.4.5` into a new 6.5.0 tree as the base (it is the newer, 64-bit, actively-built tree). **Superseded for the Rust bootstrap:** this repository root is now the 6.5.0 Rust workspace, while `xbasic-6.4.5/` remains a read-only reference tree.
2. Re-apply the 6.2.3 directory structure: recreate `src/win32/`, `templates/win32/`,
   `src/lib/win32/`, `README.Win32`.
3. From `xbasic-6.3.26-D`, copy the Win32-specific sources into the new
   `src/win32/`: `xcow.x`, `xbasic.x`, `xgr.x`, `xit.x`, `xst.x`, `xrun.x`,
   `xin.x`, `xb.def`, `xb.rc`, `xexcept.c`, `xbasic.mak`, `xrun.mak`, and the
   `win32/lib/*.s` runtime.
4. From 6.3.26-D, copy `lib/*.lib`, `include/win32/*.mak`, `XBasic.iss`,
   `xbinstall.bat`, `MakeInstall630.rtf`.
5. **Verify the fork point**: confirm both `src/CHANGES` files are identical
   (they are, per chapter 09 §1.2) so no history is lost.

**Exit criterion**: the new tree has both `src/linux/` and `src/win32/` populated,
and `make` on Linux still produces a working `xb64`.

### Phase 1 — Unify the compiler (the hardest step)

The single biggest decision. Options:

**Option A (recommended): one compiler core with `##XBSystem` conditionals.**
Merge `xcol.x` (64-bit) and `xcow.x` (TOKEN refactor) into a single source where
the platform-specific parts are gated by `IF ##XBSystem = $$XBSysLinux THEN ...`.
This is what 6.2.3 did for `xst.x`/`xgr.x`/`xin.x` — the twins were ~88.5%
identical. The compiler's two big deltas are:

- **TOKEN type** (from xcow.x): adopt `TYPE TOKEN`/`TOKIX`/`TAKS` in the shared
  core. It is type-safety work, not platform work — it should be identical on both
  platforms. Port it into the merged compiler first.
- **64-bit emitter** (from xcol.x): the `op$` table (`movq/leaq/pushq/subq`), the
  `$$rax/$$rdx/...` register equivalences, REX-prefix emission (`0x48`), and the
  SysV AMD64 argument convention are Linux-64 specific. Gate them:
  `IF ##XBSystem = $$XBSysLinux AND 64-bit THEN` — or introduce a new folded
  constant `##XB64` (see Phase 4).

**Option B: keep two twin compilers** (`xcol.x` Linux-64, `xcow.x` Win32-32),
synchronized by hand — the 6.2.3 model exactly. Less invasive, but every fix has
to be applied twice and the TOKEN/64-bit divergence will keep growing.

> Decision needed from maintainers. This plan proceeds with **Option A** as the
> default because it is the only option that converges rather than re-forks.

**Steps:**
1. Diff `xcow.x` (6.3.26-D) against `xcol.x` (6.4.5) with
   `diff --strip-trailing-cr` to enumerate every divergence.
2. Adopt the TOKEN refactor into the shared compiler core (verify it does not
   depend on 32-bit assumptions).
3. Gate the 64-bit emitter + register set behind `##XBSystem`/`##XB64`.
4. Port the `.def`-generation change (`$$ulpc4$ + "blowback_"`) and the `EXPE/
   EXPX/EXP2` intrinsics into the shared core.
5. `xb.def` (Win32): bump `VERSION` to the new release string; add the 64-bit-era
   exports that the Linux twin exposes via its symbol table.

**Exit criterion**: one compiler source compiles to a working 64-bit Linux `xb64`
and a working 32-bit Win32 `xb.exe` from the same file (via the two twins or the
conditional core).

### Phase 2 — Unify the runtime (assembly only)

1. Keep **both** `xlib.s` versions: `linux/lib/xlib.s` (64-bit SysV AMD64) and
   `win32/lib/xlib.s` (32-bit, with the `%_ArrayInvalidType/Dimension` additions).
   These are platform assembly; they are not mergeable and should not be.
2. Adopt the 6.3.26-D **PDE/standalone split** everywhere: `xstart.s` = PDE
   bootstrap (arg5 = 0), `appstart.s` = standalone bootstrap (arg5 =
   `%_StartApplication`). 6.4.5 already has both in `linux/lib/`; verify they match
   the 6.3.26-D semantics.
3. Carry over the `xlib.s` micro-fixes from each fork (giant↔single/double
   conversions commented out; `__rsp_odd/__rsp_even` stack alignment on Linux;
   `XxxFPREM1@16` removal) into each platform's copy.
4. Move `src/crtl/` to `research/crtl/` with a README pointing at this chapter.
   Delete the broken `xlib.h`/`xbconst.h` includes; keep the globals in
   `xbxtrns.c` only as a reference for a future real C runtime.

**Exit criterion**: `xb64` and `xb.exe` both boot the PDE and run a trivial
standalone (e.g. `demo/ahello.x` → `.exe`/ELF).

### Phase 3 — Unify the libraries (merge per module)

For each `shared/` and platform module, take the newer of the two forks and port
the other fork's deltas behind conditionals. Prioritized order:

1. **`xst.x`** (biggest API surface delta):
   - Adopt 6.4.5's `FILEINFO` GIANT times/sizes (64-bit) — on Win32, 32-bit
     FILETIME fields already exist; gate by `##XB64`.
   - Adopt 6.3.26-D's new functions (console, prefs, file-select, parse, random,
     tasks, recycle-bin, SaveArray/LoadArray) — these are platform-neutral.
   - **Decide** `XstGetTypedArray`: 6.3.26-D deleted it, 6.4.5 kept it. Recommend
     keeping it (deprecated) for source compat.
2. **`xui.x`**:
   - Adopt 6.3.26-D's new functions (EditCopy/Cut/Paste, GetKidGridNumber,
     MessageRetry, RestoreWindow, TextArea2B, Get/SetTextFlag, FindFiles, GetFiles).
   - **Decide** `XuiDirectoryBox`/`XuiFileBox`: 6.3.26-D deleted them, 6.4.5 kept
     them. Recommend restoring them as thin wrappers over `XuiFile` (they were
     removed because `XuiFile` superseded them) to keep both forks' user code
     compiling.
   - Adopt 6.4.5's `rbp` frame-walk (gate by `##XB64`) and the `xebp→xrbp` change.
   - Keep `XuiPlaceWindow(mode→windowType)` signature from 6.3.26-D.
3. **`xgr.x`**:
   - Adopt 6.4.5's scaled-coordinate fields (`gridBox*`, `xPixelsPerScaled`, ...)
     and new curve/circle/ellipse functions (platform-neutral drawing math).
   - Adopt 6.3.26-D's `MINMAXINFO`/`SIZEMOVE`/`TRACKMOUSEEVENT` (Win32-specific,
     gate by platform).
   - **Decide** `XgrSetMouseFocus`: recommend keeping.
4. **`xit.x`**:
   - Adopt 6.4.5's `CPUCONTEXT` (r8-r15, rip) gated by `##XB64`; keep 6.3.26-D's
     `XitMain`/`XrunXitMain` naming and the removed-`xutpde`-import behavior
     (matches the 6.2.3-era split where xutpde is PDE-only).
   - Keep 6.3.26-D's `XxxStartExceptionHandler` (`xexcept.c`) for Win32.
5. **`xin.x`**, **`xma.x`**, **`xcm.x`**, **`xdis.x`**: apply both forks' fixes;
   `xdis.x` needs both the 6.3.26-D `Fwait`/`INT 0xCD`/`WHOMASK` fixes and the
   6.4.5 64-bit disassembler (`XxxDisassemble64$`, REX) — gate by `##XB64`.
6. **`kernel32.x`/`user32.x`/`gdi32.x`** (Linux FFI reimplementations): take 6.4.5
   (with the dlopen soname fix); 6.3.26-D has no Linux counterparts.

**Exit criterion**: `demo/` programs from BOTH forks compile and run on both
platforms (or fail identically, with a documented list of platform-only demos).

### Phase 4 — Build system, `.dec`, templates, packaging

1. **Makefile**: merge the 6.2.3 OS-autodetect driver with 6.4.5's build logic.
   Introduce a `64BIT` flag (default on for Linux, off for Win32) that drives the
   `-m64`/`-m32` choices and the `##XB64` folded constant. `src/Makefile` gains
   both `linux/lib/*.o` and `win32/lib/*.o` object lists, `shell32.lib` on Win32.
2. **`.dec` files**: union of both trees — 6.4.5's 21 (GTK2/sqlite3/ssh/elf64) plus
   the Win32-only ones (win32 subdir). Restore `include/gdi32.dec` etc. so the
   `include/` layout matches 6.2.3 (they were moved into `src/linux/` as generated
   artifacts in 6.4.5 — keep the generated copies in `src/` and the canonical
   versions in `include/`).
3. **Templates**: restore `templates/win32/` (from 6.3.26-D) + keep 6.4.5's
   `templates/linux/` and new `fonts.xxx`/`xapp.xxx`.
4. **Packaging**: keep Inno Setup (`XBasic.iss`) for Win32, `xbasic.spec` for RPM,
   and the `dist-*` Makefile targets from 6.4.5 (now building `xb64` on Linux and
   `xb.exe` on Win32).
5. **`demo/`**: merge 6.4.5 (114) + 6.3.26-D (109), dedup by filename, keep both
   `demo/gtk/` and the Win32-specific demos.

### Phase 5 — Versioning, docs, and release

1. Choose a unified version. `6.5.0` is proposed (next after 6.4.x and 6.3.x).
   All `VERSION` strings, `xb.def` VERSION, `xbasic.spec`, README headers, and the
   `Makefile` `VERSION/PATCHLEVEL/SUBLEVEL` must agree.
2. Update `help/changelog.hlp` with a new section documenting the unification.
3. Keep both `README.Linux` (64-bit install: "XBasic is a 64-bit program...") and
   `README.Win32`.
4. This chapter (09/10) becomes the source-of-truth record of why the tree looks
   the way it does.

## 5. Open decisions (need maintainer input)

| # | Decision | Options | Recommendation |
|---|---|---|---|
| 1 | Compiler unification | A: one core + conditionals; B: two twins | **A** |
| 2 | `XstGetTypedArray` | delete (6.3.26-D) / keep deprecated | **keep** |
| 3 | `XuiDirectoryBox`/`XuiFileBox` | delete / re-add as `XuiFile` wrappers | **re-add wrappers** |
| 4 | `XgrSetMouseFocus` | delete / keep | **keep** |
| 5 | `crtl/` | delete / move to research/ | **move to `research/`** |
| 6 | `##XB64` folded constant | add for 64-bit gating | **add** |
| 7 | Unified version | 6.5.0 | **6.5.0** |

## 6. Risks

- **TOKEN refactor × 64-bit emitter interaction**: both changed `AssignAddress`
  and the token/register tables. Merging them is the highest-risk step; do it
  first, in isolation, with the `xcol.x`/`xcow.x` diffs in hand.
- **`xb.def` export drift**: the Win32 export list must be regenerated from the
  merged sources, not copied. Expect ~1,300+ exports after the merge.
- **64-bit Win32**: the plan assumes Win32 stays 32-bit (`-m32`). A 64-bit Win32
  port would be a separate project; the `##XB64` constant leaves that door open.
- **Untestable platform**: if no Win32 build environment is available, Phase 1-3
  Win32 verification reduces to compile-only via `spasm`/`link` availability
  checks, and the Win32 twin is shipped "best effort".