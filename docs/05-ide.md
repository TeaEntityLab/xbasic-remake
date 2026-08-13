# 05 — The IDE (PDE) and the GuiDesigner GUI Toolkit

This chapter documents the two programs that make up the XBASIC development
environment: **xit.x** — the "PDE" (Program Development Environment), a complete
IDE with an embedded compiler and debugger — and **xui.x** — the "GuiDesigner"
widget toolkit (grids) that the PDE is itself built on, and which is shipped to
every XBASIC program for GUI construction.

---

## Part 1 — The PDE: `src/linux/xit.x` (22,290 lines)

### 1.1 Header and build identity

```
PROGRAM  "xit"
VERSION  "0.0419"
' Max Reason, copyright 1988-2000
' Linux XBasic development environment
' subject to GPL license - see COPYING
```

**Imports:** `xst, xin, xma, xcm, xgr, xui, clib, xut, xutpde` — the full standard
library stack. The Windows twin (`src/win32/xit.x`) differs only in the entry point
and OS-specific calls.

### 1.2 Composite types (lines 32–75)

| Type | Purpose |
|---|---|
| `MEMORY` | `.id/.addr/.size/.state` — shared-memory segment for user code space |
| `FRAMEINFO` | `.frameAddr/.funcAddr/.funcNumber/.funcLine` — one stack frame record |
| `SIGFRAME` | `.retaddr/.signo/.reg[18]/.sigmask` — captured signal context |
| `CPUCONTEXT` | Full i486 register set (`.gs/.fs/.es/.ds/.edi/.esi/.ebp/.esp/.ebx/.edx/.ecx/.eax/.trap/.err/.eip/.cs/.efl/.uesp/.ss/.addrFPU/.sigmask`) — the debugger's register view |

### 1.3 Entry point `XxxXit()` (line 684)

The PDE entry (called by `XxxMain` in `lib/xlib.s` via `call XxxXit_12`). Sequence:

1. **Identity & platform**: sets `##XBSystem = $$XBSysLinux` (line 719);
   `EstablishSignals()` registers the signal handlers once (`STATIC entry` guard).
   `XxxXitMain` (line 86) is declared `CFUNCTION` — *"it's the signal handler
   function, which the system expects is a C function."*
2. **Library initialization order** (lines 737–763): `Xst()` → `XutInit()` →
   `XutPDEInit()` → `Xio()` → `Xin()` → `Xma()` → `Xcm()` → `Xnt()` → `Xdis()` →
   `InitGui()` → `InitProgram()`. Notably `Xgr()` and `Xui()` are **not** called
   directly — they initialize lazily. Xin is force-initialized: *"Xin() must be
   initialized in the PDE, even if it's not used. Otherwise its shared variables
   can be initialized in 'user mode' which causes all kinds of horrors."*
3. **User code space** (lines 787–804): allocates a `0x40000` (256 KB) anonymous
   shared-memory segment at `0x10000000` via `SharedMemory($$MemoryCreate, @addr,
   @size, $$OwnerReadWriteExecute)`, zeroes it, and establishes the `##UCODE`
   globals: `##UCODE0 = addr`, `##UCODE = addr+0x100`, `##UCODEX = addr+0x100`,
   `##UCODEZ = addr+size`. **The debugger compiles user code into this segment
   and executes it in place** — no child process, no separate executable.
4. **Fonts** (lines 808–813): creates the PDE's base fonts (`roman`, `utopia`,
   `courier`, ...) via `XgrCreateFont`.
5. Then command-line args are captured and `MainLoop()` runs the GUI.

### 1.4 `MainLoop()` (line 4645)

The PDE's GUI event loop:

```
DO
	compute status: Editing / Paused / Compiled (lines 4741-4749)
	SetCurrentStatus (status, 0)                    ' status bar
	IF dispatchCount THEN Dispatch()                ' dispatch stranded actions
	XgrProcessMessages (1)                          ' process X11 message queue
	IF XLONGAT(exitFlagAddr) THEN EXIT DO           ' exit flag from XxxXitQuit()
LOOP
```

Command-line options are handled on first entry: `-fl <file>` runs `.fl file` and
`-ft <file>` runs `.ft file` through the ImmediateMode dot-command interpreter
(lines 4696–4734). Status is derived: program loaded & altered → Editing;
`##USERRUNNING AND ##SIGNALACTIVE` → Paused; else Compiled.

### 1.5 The main window (grid layout, lines 6067–6658)

`Environment()` is a **Xui grid type** (`XuiRegisterGridType`) with 36 child grids
(`$UpperKid = 35`), laid out at creation (lines 6130+):

| Kid | Grid type | Role |
|---|---|---|
| 0 | Environment | the window itself |
| 1 | XuiMenu | menu bar: `_file _edit _view _option _run _debug _status _help` (line 6147) |
| 2 | XuiPushButton | HotProlog |
| 3–4 | XuiLabel | FileLabel, StatusLabel |
| 5–18 | XuiPushButton | HotNew, HotLoad, HotSave, HotSavePlus, HotCut, HotCopy, HotPaste, HotGui, HotAbort, HotFind, HotReplace, HotBack, HotNext, HotPrevious |
| 19 | XuiListButton | Function list (all functions of current file) |
| 20–28 | XuiPushButton | HotStart, HotContinue, HotPause, HotKill, HotToCursor, HotStepLocal, HotStepGlobal, HotToggleBreakpoint, HotClearBreakpoints |
| 29–33 | XuiPushButton | HotVariables, HotFrames, HotAssembly, HotRegisters, HotMemory |
| 34 | XuiDropBox | Command line (the `.cmd` dot-command input) |
| 35 | XuiTextArea | TextLower — the source editor |

**Menu structure** (text$[0..68], lines 6149+): File (new, text-load, load, save,
mode, rename, quit); Edit (cut, grab, paste, delete, buffer, insert, erase, find,
read, write, abandon); View (function, prior function, new function, delete
function, rename function, clone function, load function, save function, merge
PROLOG, import function from *.x); Option (misc, color of text-cursor, tab width);
Run (start, continue, jump, pause, kill, erase output, recompile, assembly,
library); Debug (toggle breakpoint, clear all breakpoints, erase, memory,
assembly, registers); Status; Help.

### 1.6 The dot-command interpreter — `ImmediateMode()` (line 10097)

The command line (`$Command` kid, `$$xitCommand` grid) is a full interactive CLI.
Leading digit or `*` prefixes repeat the command; the dispatcher (lines 10172–10318)
routes by 1- or 2-letter codes:

- **Run**: `.rs` Start, `.rc` Continue, `.rj` Jump-to-cursor, `.rp` Pause,
  `.rk` Kill, `.rr` Recompile, `.ra` Assembly, `.rl` Library
- **Debug**: `.dt` Toggle breakpoint, `.dc` Clear breakpoints, `.de` Erase,
  `.dm` Memory box, `.da` Assembly box, `.dr` Registers box
- **File**: `.fn` New, `.ft/.fl/.ls/.sr` TextLoad/Load/Save/Rename, `.fm` Mode,
  `.fq` Quit; `.fn`/`.fm` take a letter argument (`t` text, `p` program, `g` gui)
- **Edit**: `.ec/.eg/.ep` Cut/Grab/Paste (buffer 0), `.ed/.eb/.ei` (buffer 1),
  `.ee` (delete line), `.ef` Find, `.er/.ew` Read/Write, `.ea` Abandon
- **View**: `.vm` misc, `.v` view
- **Option**: `.om` Misc box, `.oc` text-cursor color, `.ot` tab width
- **Errors**: `.sc` compile errors box, `.sr` runtime errors box
- **Help**: `.hh` README, `.h!` new.hlp, `.hn` notes.hlp, `.hs` support.hlp,
  `.hm` message.hlp, `.hl` language.hlp, `.ho` operator.hlp, `.hd` command.hlp
- **Tags**: `.st` set tag, `.jt` jump tag, `.xi` index, `.xc` contents,
  `.xh` highlight, `.xx` toggle huh-log, `.xy` toggle Xgr debug, `.xz` toggle Xgr
  huh-log; bare `xit` exits; `.`/`..` re-runs the last command (`.` + SHIFT).

`-fl`/`-ft` command-line options feed lines directly into this interpreter.

### 1.7 The compile-drive flow (the PDE ↔ compiler API)

The PDE drives the compiler **in-process** through the `Xxx*` EXTERNAL functions
(declared at lines 396–422 — the compiler's exported C-ABI surface):

```
XxxInitAll()                (line 21326, InitializeCompiler)
XxxInitVariablesPass1()     (line 14342)  initialize variables for compilation
XxxCompilePrep()            (line 14343)  clear DECLARE/DEFINED bits in tokens
XxxCreateCompileFiles()     (line 14745)  create output .s/.o streams
XxxParseSourceLine(@token$, @tok[])       tokenize one source line
XxxCheckLine(lineNumber, @tok[])          (lines 20333/20355)
XxxDeparser(@tok[], @asm$)                deparse a token array to assembly
XxxDeparseFunction(@text$, @func[], lastLine, flags)
XxxErrorInfo(xerror, @rawPtr, @srcPtr, @srcLine$)
XxxGetXerror$(error)                      error → text
XxxGetPatchErrors(@symbol$[], @token[], @addr[])
XxxInitParse()                            reset parser state
XxxGetLabelGivenAddress / XxxGetAddressGivenLabel
XxxPassFunctionArrays / XxxPassTypeArrays (type/function table queries)
XxxGetFunctionVariables(showFuncNumber, @kinds[], @varTok[], @varSymbol$[], @varReg[], @varAddr[])
XxxGetUserTypes(varTypes$[])
XxxFunctionName(command, @funcName$, editFunction)
XxxDeleteFunction(funcNumber)
XxxSetProgramName / XxxGetProgramName
XxxXBasicVersion$ / XxxXBasic ()
```

**`CompileProgram()`** (line 14241) is the main entry the PDE calls to build user
code. Full sequence:

1. Validate state: file is a `.x` program, an entry function is declared and
   defined, program has been altered or checkBounds changed (lines 14260–14279).
2. **Size code space**: `bytesPerLine = 25` (65 with checkBounds); total =
   `Σ lines × bytesPerLine`, rounded up to the 0x80000 (512 KB) boundary
   (lines 14287–14302). Reallocates the UCODE shared-memory segment if the current
   segment is too small or oversized (lines 14309–14317).
3. Set emitter flags: `i486asm = $$FALSE, i486bin = $$TRUE` (lines 14339–14340) —
   the PDE always uses the in-memory binary emitter (the debugger needs code
   addresses, not text).
4. Reset: `XxxInitVariablesPass1()`, `XxxCompilePrep()`, `BreakClearArrays()`,
   `ClearForCompile()` (lines 14342–14345).
5. **Pass 1** — compile the PROLOG (func 0) line by line via `CompileLine(0, line,
   @tok[])` (lines 14347–14379). Every 1024 lines update the status bar; every 256
   lines `ClearMessageQueue()` (so the UI stays live); checks `softInterrupt` for
   Abort.
6. **Pass 2** — the entry function is made **first in memory** ("Make entry function
   first in memory", line 14381), then compiled (14381–14412).
7. **Pass 3** — all remaining functions in `func` order (14414–14452).
8. **Terminator**: `XxxParseSourceLine("END PROGRAM", @tok[])` then
   `CompileLine(maxFuncNumber + 1, 0, @tok[])` (14453–14458).
9. `LoadLineCodeArray()` (line 14459) — records the first opcode of each line for
   the debugger; `ResetDataDisplays($$ResetAssembly)` refreshes the views.
10. On error: `ShowFirstError` (14487) deparses the offending function back to text
    (`TokenArrayToText`), positions the editor cursor at the error token, and
    raises the compile-errors wizard (`WizardCompErrors`).

Any `codeSpaceResized` during compilation restarts the whole pass
(`GOTO startCompilation`, status `$$StatusRecompiling`).

### 1.8 Run control

| Function | Line | Action |
|---|---|---|
| `RunStart()` | 14166 | Sets `##SOFTBREAK`/`blowback`, `userRun=TRUE`, `exitMainLoop=TRUE`, turns off GuiDesigner mode, then falls into the user code |
| `RunContinue()` | 14531 | Resume from breakpoint |
| `RunJump()` | 14559 | Jump to cursor |
| `RunPause()` | 14603 | Pause execution |
| `RunKill()` | 14619 | Kill running program |
| `RunRecompile()` | 14647 | Recompile + restart |
| `RunAssembly()` / `RunLibrary()` | ~14680 | Compile-and-link to .s / static lib |
| `CompileAssembly()` | 14671 | The file-mode compiler path (`XxxCreateCompileFiles`, external assembler+link) |
| `HotStepLocal()` / `HotStepGlobal()` | 16162/16190 | Single-step (local = one line; global = into next CALL) |

### 1.9 The debugger

**Breakpoint machinery** (lines 3885–5354):

- `Break` (3885), `SetBreakpoint` (3911), `ClearBreakpoint` (3936),
  `BreakContinuePrep` (4001), `BreakPatch` (4068), `BreakPatchAll` (4101) —
  **the debugger implements breakpoints by patching the first opcode byte of a
  line with `0xCC` (INT 3)** and remembering the original byte in
  `breakAddr[]`/`breakCode[]` so it can be restored for stepping.
- `BreakInternal` (4911), `InstallAllProgramLineBreakpoints` (4928),
  `InstallOneFunctionLineBreakpoint` (4956), `InstallAllFunctionLineBreakpoints`
  (4988), `RemoveAllProgramLineBreakpoints` (5011) — install/remove patches.
- `BreakProgrammer` (5057), `SetOneProgrammerBreakpoint` (5165),
  `InstallAllProgrammerBreakpoints` (5219), `RemoveAllProgrammerBreakpoints`
  (5281) — "programmer breakpoints" are user-visible breakpoints (from the editor),
  vs. the internal ones the debugger uses for single-stepping.
- `GetFuncAndLineNumberAtThisAddress` (5319) — maps a patched address back to
  function+line for display.
- `XitExecute` (5354) — entry point of the running user program in the PDE
  (called after RunStart); sets up the exception frame that the signal handler
  unwinds into.

**Display functions:** `DisplayAssembly` (2858) renders disassembly (uses
`XxxDisassemble$` / xdis.x); `AssemblyString$` (4484) and `XxxAsm$` (20088) /
`XxxAnyAsm$` (20131) are the PDE-side assembly viewers. `Dump$`, `Fill`,
`Substitute`, `G` (peek), `DisplayRegisters(CPUCONTEXT cpu)`, `MemoryMap$`,
`Frames$`, `Locate`, `DisplayLocate`, `Asm` are low-level debugger commands
(lines 118–131) — the PDE literally has a **built-in command-line debugger**
activated when argv[1] is missing (line 783: `IFZ argv$[1] THEN PRINT " *****
Low Level Debugger *****"`).

**Watch/variables** (lines 16331–18668): `UpdateVariables` (16331),
`VariablesFind` (16801), `VariablesNewValue` (16847 — lets you edit values),
`VariablesDetail` (17115), `VariablesArrayDisplay` (17313),
`VariablesCompositeDisplay` (18194), `VariableSort` (18668). The variables box
lists function locals via `XxxGetFunctionVariables`, with composite and array
drill-down display.

**Runtime errors:** `GetRuntimeError` (4222), `ClearErrors` (15613),
`UpdateErrors` (15669), `WizardCompErrors` (15749), `WizardRunErrors` (15940),
`ClearRuntimeError` (15979), `UpdateRuntimeError` (15995).

**Crash/exception handling:** `CaptureExceptionContext`, `ReplaceExceptionContext`,
`PrintExceptionContext` (lines 91–93) plus `XitCrash` (4379) and the signal handler
`XxxXitMain`. `SIGFRAME`/`CPUCONTEXT` capture the full register set at the fault.

### 1.10 Xxx\* PDE EXTERNAL functions (xlib.s interface)

`XxxGetEbpEsp`, `XxxSetEbpEsp`, `XxxSetFrameAddr`, `XxxG` (lines 389–392) — the
debugger manipulates the live register context directly through the runtime.
`XxxXstBlowback`, `XxxXstLog`, `XxxXstTimer`, `XxxXinBlowback`, `XxxXgrBlowback`,
`XxxXuiBlowback`, `XxxXgrSetHuh`, `XxxDispatchEvents`, `XxxGuiDesignerOnOff`
(lines 426–453) are the library blowback hooks that route timer/message events
back into the PDE while user code is running.

### 1.11 Popup boxes (all Xui grid types)

`CreateWindows` (5387) / `InitWindows` (5999) build the auxiliary windows:
`XitFile`/`fileBox`, `renameBox`, `readBox`, `writeBox`, `findBox`, `funcBox`,
`viewNewBox`, `deleteFuncBox`, `viewRenameBox`, `viewCloneBox`, `viewLoadBox`,
`viewSaveBox`, `viewMergeBox`, `memoryBox`, `assemblyBox`, `registerBox`,
`errorBox`, `runtimeErrorBox`, `optionMiscBox` — each with Create/CreateWindow/
GetSmallestSize/Resize/Initialize handlers: `XitArray` (7189), `XitComposite`
(7635), `Xit2LineDialog` (7888), `XitErrorCompile` (8082), `XitErrorRuntime`
(8256), `XitFind` (8409), `XitFrames` (8659), `XitMemory` (8833), `XitOptionMisc`
(9002), `XitRegisters` (9233), `XitString` (9429), `XitTextCursor` (9620),
`XitVariables` (9775), `XitAssembly` (7451), `XitCEO` (7151).

### 1.12 Win32 entry point

The Windows twin uses `FUNCTION Xit (uargc, uargv, uenvp)` at `win32/xit.x:913`
inside xb.dll (see 06-cross-platform §4).

---

## Part 2 — The GuiDesigner toolkit: `src/shared/xui.x` (37,974 lines)

### 2.1 Header and build identity

```
PROGRAM  "xui"
VERSION  "0.1176"
' Max Reason, copyright 1988-2000
' subject to LGPL license - see COPYING_LIB
```

**Imports:** `xma, xst, xgr, xlib, kernel32, xut`. Shared — compiles on both
platforms.

### 2.2 The central object: `GRID` (lines 25–108)

Everything in XBASIC's GUI is a **grid** — a 256-byte struct whose first field is
a grid-type id. Grids are created by a `XuiCreateGrid`-style factory, communicate
by **messages** (`XuiSendMessage(grid, #Message, ...)`), and are organized in a
parent/kid tree. Each grid type is a **grid function**:

```
FUNCTION XuiPushButton (grid, message, v0, v1, v2, v3, r0, (r1, r1$, r1[], r1$[]))
	IF XuiProcessMessage (grid, message, @v0, @v1, @v2, @v3, @r0, @r1, XuiPushButton) THEN RETURN
	...
	SELECT CASE message
		CASE #Create        : ...   ' build kid grids, register sub-handlers
		CASE #GetSmallestSize: ...
		CASE #RedrawGrid    : ...   ' paint the control
		CASE #KeyDown       : ...
		CASE #MouseDown     : ...
		CASE #Selected      : ...
	END SELECT
```

The `#message` constants are exported as `Xui*` EXPORTs; user programs import xui
and use `XuiSendMessage(grid, #PushButton,...)`.

**Redraw flags** (lines 599–614): `$$RedrawClip = 0x80000000` — the "dirty" bit;
`$$RedrawClip0 = 0x80000000 + 0x400` (text moved), `$$RedrawClip1` (font
changed), `$$RedrawClip2` (position/size changed), `$$RedrawClip3` (kid z-order
changed), `$$RedrawDefault = 0x800006FC` (clip + all text/font/pos flags).

**Example — checkbox redraw** (lines 11695–11740): `#SetValue` stores the state
then computes the clipping rect: on checking, it marks the text and box regions
dirty; on value change it also unclips the old text region so the previous glyph
is erased; finally `RedrawGrid` clips the union and paints only the dirty region
(see also `XgrRedrawWindow` usage).

**Grid types registered** (48 total): Environment, MenuBar, PushButton, CheckBox,
Label, TextLine, TextArea, ListButton, List, DropBox, Range, Progress, ToggleButton,
RadioButton, RadioBox, ScrollBarH/V, ComboBox, File, Color, Font, Dialog2B/3B/4B,
Message1B/2B/3B/4B, ListDialog2B/3B/4B, Window, Grid (composite), Array, plus the
PDE's own Xit types. Each is built from a small set of **primitive grid types**
(`XuiCreateGrid` with a factory id), and user programs can `XuiRegisterGridType`
to add new ones.

### 2.3 The GuiDesigner form-builder

`xui.x` contains the **form designer** itself: while a program runs, pressing the
designer hot-key enters design mode (`XxxGuiDesignerOnOff(1)`); grids can then be
dragged/resized, properties edited, and new grids dropped from a palette. Design
state is kept in grid properties (`.designed` flags, design coordinates), and the
form layout is serialized into the `#SetValues` message stream. The PDE uses
`XxxGuiDesignerOnOff(0)` to leave design mode before running user code
(RunStart, 14189).

### 2.4 The Xui message model (summary)

- `XuiSendMessage (grid, #Message, v0, v1, v2, v3, r0, r1)` — synchronous message
  delivery; `r0` is a *kid* selector (-1 = all kids, 0 = self), `r1` is extra data
  (may be `@array` for text arrays).
- `XuiProcessMessage` — default handler: routes `#Callback`/`#SetFontNumber`/
  `#SetGridName` etc., then invokes the grid's `sub[]` dispatch table.
- `XuiReportMessage` / `XuiCallback` — logging and user-callback plumbing.
- Text grids (`#SetTextArray`, `#PokeTextArray`, `#GrabTextArray`, `#GetTextString`,
  `#SetTextCursor`, `#GetTextCursor`, `#RedrawText`, `#TextInsert`, `#GetTextArray`)
  back the PDE editor and command line.
- Every message constant and `Xui*` EXPORT is available to user programs after
  `IMPORT "xui"`; this is the API surface documented in 04-libraries (xui.x is
  the toolkit, xgr.x is the graphics backend).

### 2.5 How the PDE and toolkit fit together

```
xstart.s main() → XxxMain (xlib.s) → XxxXit() [xit.x]
   ├── library init: Xst/Xut/Xio/Xin/Xma/Xcm/Xnt/Xdis
   ├── InitGui(): Xui() + Xgr() lazy init, register PDE grid types
   ├── InitProgram(): build Environment window (36 kids) + popups
   ├── MainLoop(): XgrProcessMessages → Xui dispatch to Environment()
   │        └── ImmediateMode() dot-command interpreter
   ├── CompileProgram(): Xxx* compiler API → i486bin machine code into ##UCODE
   ├── RunStart() → XitExecute() → user code runs in-process
   │        └── debugger: INT 3 patch, signal handler, CPUCONTEXT, variables/watch
   └── XxxXitQuit() → exit
```

The same xui.x toolkit that builds the PDE's own UI is the toolkit every XBASIC
program imports — the IDE is *dogfooding* the GUI library it ships.