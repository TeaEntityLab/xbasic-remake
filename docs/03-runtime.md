# XBASIC 6.2.3 — Runtime and Standalone Executable Support

This chapter documents the runtime layer: how a compiled XBASIC program
starts, how it initializes its libraries, how OS signals/exceptions are
translated into XBASIC exceptions, and what the runtime symbol surface looks
like. Primary sources: `src/linux/xrun.x`, `src/win32/xrun.x`,
`src/linux/chkmem.c`, `src/win32/xb.def`, and the assembly startup files in
`src/*/lib/`.

## 1. The Two Runtime Modes

XBASIC programs execute in two modes, both served by the same compiled
runtime library (`libxb.a` on Linux, `xb.dll`/`xbrun.dll` on Windows):

1. **Inside the PDE** — the program is compiled and run within the IDE
   process. On Linux this is the single `xb` binary; on Windows the program
   runs against the IDE's `xb.dll`. The `##WHOMASK` mechanism segregates PDE
   memory from program memory in the shared heap.
2. **Standalone** — the program is linked into its own native executable
   against the runtime. On Linux this is `appstart.o + prog.o + libxb.a`;
   on Windows `xstart.o + prog.o + xb.lib` and the program must be run with
   `xbrun.dll` (renamed `xb.dll`) available.

## 2. Entry Sequence

### 2.1 OS-level entry (assembly)

The assembly startup in `src/win32/lib/xstart.s` (the Win32 variant, quoted
in `templates/win32/xstart.xxx`) shows the handoff precisely:

```asm
.globl  _main          ; C entry label
.globl  _WinMain       ; Windows entry label
.globl  _WinMain@16    ; Windows entry label ???

_main:                 ; <- all three labels alias the same code
_WinMain:
_WinMain@16:
    push  0x00000000   ; arg9 = reserved
    push  %_StartApplication ; arg8 = %_StartApplication (in the user program)
    push  [ebp+20]     ; arg7 = nCmdShow
    push  [ebp+16]     ; arg6 = lpszCmdLine
    push  [ebp+12]     ; arg5 = hPrevInstance
    push  [ebp+ 8]     ; arg4 = hInstance
    push  _WinMain     ; arg3 = &WinMain()  ===>>  ##CODE
    push  [ebp-16]     ; arg2 = *envp[]
    push  [ebp-20]     ; arg1 = **argv[]
    push  [ebp-24]     ; arg0 = argc
    call  _XxxMain     ; XxxMain() is in xlib.s in xb.dll
    ret
```

So the native entry (WinMain/main aliases) pushes `argc, argv, envp`,
`##CODE` (the program's own code address), the user program's
`%_StartApplication`, and calls the runtime's `XxxMain`. The Linux startup
(`src/linux/lib/xstart.s`, `appstart.s`) performs the same role with the
ELF/`_start` conventions, and `xlib.s` supplies `XxxMain` and the core
runtime (heap anchors `__DYNO`/`__DYNOX`, exception machinery, FPU wrapper
`Xxx*` functions). `xzzz.s` is the terminal/closure segment of the runtime.

### 2.2 Runtime-level entry (XBASIC)

`xrun.x` defines `XxxXit` (Linux) / `Xit` (Win32) — the entry function
called by the runtime on startup:

```basic
PROGRAM "xrun"
VERSION "0.0047"          ' Linux (win32: "0.0038")

IMPORT "xst"  "xin"  "xma"  "xcm"  "xgr"  "xui"
IMPORT "clib" "kernel32" "xut"       ' Linux also imports clib + kernel32

FUNCTION XxxXit (argc, argv, envp)
    STATIC firstEntry
    IFZ firstEntry THEN
        firstEntry = $$TRUE
        ##XBSystem = $$XBSysLinux      ' <- platform identification
        InitProgram ()
        Xst ()                         ' standard library init
        XutInit ()
        Xio ()                         ' I/O layer init
        Xin ()                         ' sockets init
        Xma ()                         ' math init
        Xcm ()                         ' complex init
        Xgr ()                         ' graphics init
        Xui ()                         ' GuiDesigner init
    END IF
    error = XxxXitMain (0)             ' Linux
    ' error = XitMain (0, 0)           ' Win32
    RETURN (error)
END FUNCTION
```

Library initialization is a fixed, ordered protocol — each library's init
registers its functions in the runtime so later code can resolve imports.

## 3. Exception Handling — The Core Loop

All OS signals / structured exceptions funnel into one function:
`XxxXitMain(sigNumber)` on Linux, `XitMain(sigNumber, sigSource)` on Win32.

### Linux: signal-driven

`EstablishSignals()` installs `XxxXitMain` as the handler for a long list of
signals via `xb_sigaction` (a declared foreign function from `clib`/`xlib`):

```basic
sig.sa_handler = &XxxXitMain()   ' signal catching function
sig.sa_mask = mask               ' block all signals upon signal catch
sig.sa_flags = 0
e = xb_sigaction ($$SIGINT,  &sig, 0)
e = xb_sigaction ($$SIGQUIT, &sig, 0)
...                              ' SIGILL TRAP ABRT FPE BUS SEGV ALRM TERM VTALRM
```

The mask constant ORs together every `$$SIGMASK_*` constant — a documented
set of `sigset` bit values — so no signal can nest inside the handler
(complementing the `##LOCKOUT` re-entrancy guard).

### Win32: structured exceptions

`XitMain(sigNumber, sigSource)` is invoked by SEH; `XitSoftBreak()`
synthesizes a break by calling `RaiseException($$EXCEPTION_CONTROL_C_EXIT,
0, 0, 0)`.

### The dispatch loop (both platforms)

```
XstSystemExceptionToException (sigNumber, @exception)   ' OS → XBASIC mapping
SELECT CASE exception
    CASE $$ExceptionTimer:
        XxxXstTimer ($$TimerExpire, 0, 0, 0, 0)         ' timer event
        RETURN false
END SELECT
XstExceptionNumberToName (exception, @exception$)
XstGetExceptionFunction (@response)                     ' user handler address?
XxxSetExceptions (exception, sigNumber)                 ' publish current state
XstLog (@log$)                                          ' (Linux) log line

DO
    SELECT CASE response
        CASE $$ExceptionContinue  : RETURN false        ' swallow and continue
        CASE $$ExceptionTerminate : RETURN true         ' terminate program
        CASE ELSE : func = response                     ' call user handler
                    response = @func()                  '   FUNCADDR invocation
    END SELECT
LOOP
```

Key design points:

- **Exceptions are extensible**: a user program can install an exception
  function (`XstGetExceptionFunction`); the runtime calls it *inside the
  signal/SEH context* and obeys its verdict.
- **The timer is an exception**: `$$ExceptionTimer` events are delivered
  through the same mechanism — `XxxXstTimer($$TimerStart/Expire/Kill, ...)`
  commands drive the timer machinery declared in `xrun.x`.
- **`##INEXIT`** guards double-exit: `IF ##INEXIT THEN exit(0)` before
  processing, and `XxxXitExit()` sets `##INEXIT = $$TRUE` then calls the
  native `exit()`.

## 4. Host-Service Contract

`xrun.x` contains stubs for every IDE service that libraries (especially
`xui.x`) may call — so the *same* libraries link into both the PDE and
standalone programs. Each stub is annotated with its caller:

```basic
DECLARE FUNCTION XitGetDECLARE           (func$, declare$)   ' called by xui.x
DECLARE FUNCTION XitGetDisplayedFunction (func$)            ' called by xui.x
DECLARE FUNCTION XitGetFunction          (func$, text$[])   ' called by xui.x
DECLARE FUNCTION XitQueryFunction        (func$, exists)    ' called by xui.x
DECLARE FUNCTION XitSetDECLARE           (func$, declare$)  ' called by xui.x
DECLARE FUNCTION XitSetDisplayedFunction (func$)            ' called by xui.x
DECLARE FUNCTION XitSetFunction          (func$, text$[])   ' called by xui.x
DECLARE FUNCTION XitSoftBreak            ()                 ' called by xui.x
DECLARE FUNCTION XxxGetLabelGivenAddress (address, label$[])' called by xui.x
DECLARE FUNCTION XxxXitGetUserProgramName (file$)           ' called by xui.x
DECLARE FUNCTION XxxSetBlowback          ()                 ' called by xst.x
DECLARE FUNCTION XxxXitExit              (status)           ' called by xst.x
```

- In the **PDE build** (`xit.x` linked), the real implementations are used
  (the IDE's source/function database).
- In the **standalone build** (`xrun.x` linked), they are empty (or
  minimal, e.g. `XitSoftBreak`, `XxxXitGetUserProgramName` which recovers
  the program name from `argv[0]`).

This is how one GUI toolkit and one standard library serve both a full IDE
and a bare standalone executable.

## 5. The Runtime Symbol Surface (`xb.def`)

`src/win32/xb.def` exports the runtime ABI that compiled XBASIC code
references. Grouped:

### 5.1 Main entry and control

`XxxMain`, `XxxG`, `XxxGuessWho`, `XxxGetEbpEsp`/`XxxSetEbpEsp`,
`XxxGetFrameAddr`/`XxxSetFrameAddr` — frame/stack manipulation used by the
debugger and by function-pointer invocation.

### 5.2 FPU control (x87 wrappers)

The runtime wraps the entire x87 FPU instruction set so floating point is
mediated: `XxxFPUstatus`, `XxxFCLEX`, `XxxFINIT`, `XxxFSTCW`, `XxxFSTSW`,
`XxxF2XM1`, `XxxFABS`, `XxxFCHS`, `XxxFCOS`, `XxxFLDZ/FLD1/FLDPI/FLDL2E/
FLDL2T/FLDLG2/FLDLN2`, `XxxFPATAN`, `XxxFPREM(1)`, `XxxFPTAN`,
`XxxFRNDINT`, `XxxFSCALE`, `XxxFSIN`, `XxxFSINCOS`, `XxxFSQRT`,
`XxxFXTRACT`, `XxxFYL2X`, `XxxFYL2XP1`, plus `XxxGetFPEnvironment`,
`XxxClearFPException`.

### 5.3 Runtime error entry points

`%_eeeAllocation`, `%_eeeOverflow`, `%_eeeErrorNT`, `%_OutOfBounds`,
`%_NeedNullNode`, `%_UnexpectedLowestDim`, `%_UnexpectedHigherDim`,
`%_error.d`, `%_error`, `XxxRuntimeError(2)`, `XxxTerminate`,
`XxxCheckMessages` (message pump hook).

### 5.4 Array & composite support

`%_DimArray`, `%_RedimArray`, `%_FreeArray`, `%_assignComposite`,
`%_clone.a0/a1`, `XxxSwapMemory`.

### 5.5 String/expression helpers (mangled)

The mangle encodes operation, type, and operand kinds:

```
%_concat.string.a0.eq.a0.plus.a1.ss   ; a0 = a0 + a1  (string, source-sink)
%_concat.string.a0.eq.a0.plus.a1.sv   ; ... mixed string/variable forms
%_concat.ubyte.a0.eq.a0.plus.a1.vv    ; ubyte concatenation forms
```

(`v` = variable, `s` = string-typed source; `a0`/`a1` = operands.)

### 5.6 Memory management (aliased malloc family)

`malloc/_malloc/__malloc/Xmalloc/%____malloc/%_____malloc` (same for
`realloc/free/calloc/recalloc`) — all heap entry points converge on the
XBASIC allocator so that `##WHOMASK` heap segregation and `chkmem`
verification apply uniformly.

### 5.7 Other runtime

`XxxStartApplication` (the user program's entry, pushed by the assembly
startup), `XxxWriteWin32s`, `%_ZeroMemory`, `%_beginAlloCode`, and — near the
end of the file — the exports of the library layer (`Xst*`, `Xin*`, `Xma*`,
`Xcm*`, `Xgr*`, `Xui*`, `Xut*` init and API functions).

## 6. The Heap (`chkmem.c`)

The XBasic heap is a **singly-linked chain of memory blocks** bounded by two
assembly symbols, `__DYNO` and `__DYNOX`:

```c
/* The XBasic dynamic memory ('heap') is a linked list, beginning
 * with __DYNO and ending with __DYNOX. */
extern unsigned char *__DYNO;
extern unsigned char *__DYNOX;

struct TMemBlock {
    unsigned long lAddrUp;    /* distance to next block; 0 for last (__DYNOX) */
    unsigned long lAddrDown;  /* back pointer */
    unsigned long lSizeUp;    /* size bookkeeping */
    unsigned long lSizeDown;
};
```

`xb_checkmem()` walks `__DYNO → ... → __DYNOX`, returns 0 if the chain ends
exactly on `__DYNOX`, -1 if corrupted. Its header notes it should eventually
also validate the *contents* of blocks (strings, arrays). This file is Linux-
specific debug support (compiled into the Linux build only).

## 7. Command-Line / Program Identity

`XxxXitGetUserProgramName(file$)` recovers the invoked program name from
`argv[0]` via `XstGetCommandLineArguments(@argc, @argv$[])` — used by the
runtime and by `xutpde.x`'s `InitDirectories()` to locate the installation
when `XBDIR` is not set (see [`01-architecture.md`](./01-architecture.md)
§7).

## 8. Platform Divergence Summary (runtime layer)

| Concern | Linux | Win32 |
|---|---|---|
| Entry symbol | `_start` → `XxxMain` (xstart.s/appstart.s) | `WinMain` aliases → `XxxMain` (xstart.s) |
| Traps | POSIX signals via `xb_sigaction` | Structured exceptions (`RaiseException`, SEH) |
| Break | `kill(getpid(), $$ExceptionBreakKey)` | `RaiseException($$EXCEPTION_CONTROL_C_EXIT,...)` |
| Library init import | also `IMPORT "clib"` | — |
| Return codes | `XxxXitMain` error int | `$$EXCEPTION_CONTINUE_EXECUTION` / `..._SEARCH` |
| Runtime shape | static `libxb.a` in every binary | `xb.dll` (PDE) vs `xbrun.dll` (standalone) |

Everything else — the init protocol, the exception dispatch loop, the
FUNCADDR handler invocation, the heap, the host-service stubs — is shared
logic written once in XBASIC.