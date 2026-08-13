# 04 — Runtime and Standard Function Libraries

XBASIC's functionality is split into libraries, each a separately-compiled XBASIC
program with its own `PROGRAM`/`VERSION` header and an `EXPORT` block. They are
imported with `IMPORT "xma"` etc. and their public functions become globally
callable. The libraries live either in `src/shared/` (platform-neutral) or
`src/linux/` / `src/win32/` (platform twins).

## 1. xst.x — Standard Function Library

**File:** `src/linux/xst.x` (10,523 lines); Windows twin at `src/win32/xst.x` (11,096 lines).
**Header:** `PROGRAM "xst"`, `VERSION "0.0228"`, LGPL (`COPYING_LIB`),
"Linux XBasic standard function library", Max Reason, copyright 1988–2000.
**Imports:** xma, xgr, xui, clib, xlib, kernel32, xut.

**Data types:** `FILEINFO` (attributes + 64-bit times + name), `MEMORYMAP`
(code/data/bss/dyno/ucode/stack ranges), `TIMER` (timer#, count, func, msec, whomask),
`FILE` (fileName, fileHandle, consoleGrid), `LOCK` (file, offset, length).
`FILEINFO`/`MEMORYMAP` are exported; `TIMER`/`FILE`/`LOCK` are internal.
**Constants:** `$$NOTERM=0`, `$$LF=1`, `$$NL=1`, `$$CRLF=2`.

### Public API (EXPORT, lines 109–249)

**System functions (Xst\*):**
`Xst`, `XstVersion$`, `XstCauseException`, `XstCloseLibrary`, `XstDateAndTimeToFileTime`,
`XstErrorNameToNumber`, `XstErrorNumberToName`, `XstExceptionNumberToName`,
`XstExceptionToSystemException`, `XstFileTimeToDateAndTime`, `XstFileToSystemFile`,
`XstGetApplicationEnvironment`, `XstGetCommandLine`, `XstGetCommandLineArguments`,
`XstGetConsoleGrid`, `XstGetCPUName`, `XstGetDateAndTime`, `XstGetLocalDateAndTime`,
`XstGetEndian`, `XstGetEndianName`, `XstGetEnvironmentVariable`, `XstGetEnvironmentVariables`,
`XstGetException`, `XstGetExceptionFunction`, `XstGetImplementation`, `XstGetLibraryAddress`,
`XstGetMemoryMap`, `XstGetNewline`, `XstGetOSName`, `XstGetOSVersion`, `XstGetOSVersionName`,
`XstGetPrintTab`, `XstGetProgramName`, `XstGetSystemError`, `XstGetSystemTime`, `XstKillTimer`,
`XstLog`, `XstOpenLibrary`, `XstSetCommandLineArguments`, `XstSetDateAndTime`,
`XstSetEnvironmentVariable`, `XstSetException`, `XstSetExceptionFunction`, `XstSetNewline`,
`XstSetPrintTab`, `XstSetProgramName`, `XstSetSystemError`, `XstSleep`, `XstStartTimer`,
`XstSystemErrorToError`, `XstSystemErrorNumberToName`, `XstSystemExceptionNumberToName`,
`XstSystemExceptionToException`

**Console functions:** `XstClearConsole`, `XstDisplayConsole`, `XstHideConsole`, `XstShowConsole`

**File functions:** `XstBinRead`, `XstBinWrite`, `XstChangeDirectory`, `XstCopyDirectory`,
`XstCopyFile`, `XstDecomposePathname`, `XstDeleteFile`, `XstFindFile`, `XstFindFiles`,
`XstGetCurrentDirectory`, `XstGetDrives`, `XstGetExecutionPathArray`, `XstGetFileAttributes`,
`XstGetFiles`, `XstGetFilesAndAttributes`, `XstGetPathComponents`, `XstGuessFilename`,
`XstLoadString`, `XstLoadStringArray`, `XstLockFileSection`, `XstMakeDirectory`,
`XstPathString$`, `XstPathToAbsolutePath`, `XstReadString`, `XstRenameFile`, `XstSaveString`,
`XstSaveStringArray`, `XstSaveStringArrayCRLF`, `XstSetCurrentDirectory`,
`XstUnlockFileSection`, `XstWriteString`

**String/string-array functions:** `XstBackArrayToBinArray`, `XstBackStringToBinString$`,
`XstBinArrayToBackArray`, `XstBinStringToBackString$`, `XstBinStringToBackStringNL$`,
`XstBinStringToBackStringThese$`, `XstCopyArray`, `XstCopyMemory`, `XstDeleteLines`,
`XstFindArray`, `XstIsDataDimension`, `XstMergeStrings$`, `XstMultiStringToStringArray`,
`XstNextCField$`, `XstNextCLine$`, `XstNextField$`, `XstNextItem$`, `XstNextLine$`,
`XstReplaceArray`, `XstReplaceLines`, `XstStringArraySectionToString`,
`XstStringArraySectionToStringArray`, `XstStringArrayToString`, `XstStringArrayToStringCRLF`,
`XstStringToStringArray`, `XstLTRIM`, `XstRTRIM`, `XstTRIM`

**Sorting functions:** `XstCompareStrings`, `XstQuickSort` (with internal typed variants
`XstQuickSort_XLONG/_GIANT/_DOUBLE/_STRING/_STRING_nocase/_NumericSTRING`)

**Misc:** `XstAbend`, `XstAlert`, `XstGetProgramFileName$`

**EXTERNAL (implemented elsewhere):** `XstFindMemoryMatch`, `XstStringToNumber`

### Xio() runtime I/O section (lines 272–288)

`Xio`, `XxxClose`, `XxxCloseAllUser`, `XxxEof`, `XxxInfile$`, `XxxInline$`, `XxxLof`,
`XxxOpen`, `XxxPof`, `XxxQuit`, `XxxReadFile`, `XxxSeek`, `XxxShell`, `XxxStdio`,
`XxxWriteFile`, `XxxFormat$`, `CreateConsole` — the low-level file/console primitives
the compiled runtime calls.

### PDE/IDE hooks

`XxxXstBlowback`, `XxxXstFreeLibrary`, `XxxXstLoadLibrary`, `XxxXstTimer`, `XxxXstLog`;
EXTERNAL `XxxCheckMessages`, `XxxXgrQuit` (GraphicsDesigner), `XxxSetBlowback`,
`XxxXitExit` (Xit IDE), `XxxGetImplementation` (compiler).

---

## 2. xgr.x — Graphics Function Library

**File:** `src/linux/xgr.x` (21,883 lines); Windows twin `src/win32/xgr.x` (22,688 lines).
**Header:** `PROGRAM "xgr"`, `VERSION "0.0515"`, LGPL, "GraphicsDesigner" graphics library.
**Imports:** xma, xst, clib, xwin.

**Data types:** `MESSAGE`, `BitmapFileHeader`, `BitmapInfoHeader`, `RGBQUAD`, `DISPLAY`,
`FONT`, `POINT`, `DPOINT`, `BOX`, `DBOX`, `LINE=BOX`, `DLINE=DBOX`, `WINDOW` (512 bytes,
line 193), `MOUSESTATE`. X11 opaque handles (Display, Screen, Visual, Pixmap, GC, Font)
are aliased to XLONG (lines 331–337); X11 event/GC types come from `include/xwin.dec`.

**Public API (EXPORT, lines 346–613): ~245 functions.**

- **Miscellaneous:** `Xgr`, `XgrVersion$`, `XgrBorderNameToNumber/NumberToName/NumberToWidth`,
  `XgrColorNameToNumber/NumberToName`, `XgrCursorNameToNumber/NumberToName`,
  `XgrGetClipboard`, `XgrGetCursor`, `XgrGetCursorOverride`, `XgrGetDisplaySize`,
  `XgrGetKeystateModify`, `XgrIconNameToNumber/NumberToName`, `XgrRegisterCursor`,
  `XgrRegisterIcon`, `XgrSetClipboard`, `XgrSetCursor`, `XgrSetCursorOverride`,
  `XgrSetDebug`, `XgrSystemWindowToWindow`, `XgrWindowToSystemWindow`, `XgrResetUserMode`
- **Font functions:** `XgrCreateFont`, `XgrDestroyFont`, `XgrGetFontInfo`,
  `XgrGetFontMetrics`, `XgrGetFontNames`, `XgrGetTextArrayImageSize`, `XgrGetTextImageSize`
- **Color functions:** `XgrConvertColorToRGB`, `XgrConvertRGBToColor`,
  `XgrGetBackgroundColor/RGB`, `XgrGetDefaultColors`, `XgrGetDrawingColor/RGB`,
  `XgrGetGridColors`, `XgrSetBackgroundColor/RGB`, `XgrSetDefaultColors`,
  `XgrSetDrawingColor/RGB`, `XgrSetGridColors`
- **Window functions:** `XgrCreateWindow`, `XgrDestroyWindow`, `XgrDisplayWindow`,
  `XgrGetModalWindow`, `XgrGetWindowDisplay/Function/Icon/Grid/PositionAndSize/State/Title/Visibility`,
  `XgrHideWindow`, `XgrMaximizeWindow`, `XgrMinimizeWindow`, `XgrRestoreWindow`,
  `XgrSetModalWindow`, `XgrSetWindowFunction/Icon/PositionAndSize/State/Title/Visibility`,
  `XgrShowWindow`
- **Coordinate functions (4 coordinate systems: Display/Local/Grid/Scaled/Window):**
  `XgrConvertDisplayToGrid/Local/Scaled/Window`, `XgrConvertGridToDisplay/Local/Scaled/Window`,
  `XgrConvertLocalToDisplay/Grid/Scaled/Window`, `XgrConvertScaledToDisplay/Grid/Local/Window`,
  `XgrConvertWindowToDisplay/Grid/Local/Scaled`, `XgrGetGridBox(Display/Grid/Local/Scaled/Window)`,
  `XgrGetGridCoordinates`, `XgrGetGridPositionAndSize`, `XgrSetGridBox(Grid/Scaled/ScaledAt)`,
  `XgrSetGridPositionAndSize`
- **Grid functions:** `XgrCreateGrid`, `XgrDestroyGrid`,
  `XgrGetGridBorder/BorderOffset/Buffer/CharacterMapArray/DrawingMode/Font/Function/Parent/State/Type/Window`,
  `XgrGridTypeNameToNumber/NumberToName`, `XgrRegisterGridType`,
  `XgrSetGridBorder/BorderOffset/Buffer/DrawingMode/Font/Function/Parent/State/Timer/Type/CharacterMapArray`
- **Drawing functions (each in Grid/Scaled variants):** `XgrClearGrid`, `XgrClearWindow`,
  `XgrDrawArc`, `XgrDrawBorder`, `XgrDrawBox`, `XgrDrawCircle`, `XgrDrawEllipse`,
  `XgrDrawGridBorder`, `XgrDrawLine`, `XgrDrawLineTo`, `XgrDrawLineToDelta`, `XgrDrawLines`,
  `XgrDrawLinesTo`, `XgrDrawPoint`, `XgrDrawPoints`, `XgrDrawText`, `XgrDrawTextFill`,
  `XgrFillBox`, `XgrFillTriangle`, `XgrGetDrawpoint`, `XgrGrabPoint`, `XgrMoveDelta`,
  `XgrMoveTo`, `XgrRedrawWindow`, `XgrSetDrawpoint`
- **Image functions:** `XgrCopyImage`, `XgrDrawImage`, `XgrGetImage`, `XgrGetImage32`,
  `XgrGetImageArrayInfo`, `XgrLoadImage`, `XgrRefreshGrid`, `XgrSaveImage`, `XgrSetImage`
- **Focus functions:** `XgrGetMouseInfo`, `XgrGetSelectedWindow`, `XgrGetTextSelectionGrid`,
  `XgrSetSelectedWindow`, `XgrSetTextSelectionGrid`
- **Message functions:** `XgrAddMessage`, `XgrDeleteMessages`, `XgrGetCEO`, `XgrGetMessages`,
  `XgrGetMessageType`, `XgrGetMonitors`, `XgrJamMessage`, `XgrMessageNameToNumber`,
  `XgrMessageNames`, `XgrMessageNumberToName`, `XgrMessagesPending`, `XgrMonitor`,
  `XgrPeekMessage`, `XgrProcessMessages`, `XgrRegisterMessage`, `XgrSendMessage`,
  `XgrSendStringMessage`, `XgrSetCEO`
- **Old-name stubs (GuiDesigner link compatibility):** `XgrGetColors`, `XgrGetGridClip`,
  `XgrRegisterIconColor`, `XgrSetColors`, `XgrSetGridClip`, `XgrGetSystemDisplay`
- **Private/IDE hooks:** `XxxCheckMessages`, `XxxDispatchEvents`, `XxxXgrBlowback`,
  `XxxXgrGridTimer`, `XxxXgrQuit`, `XxxXgrSetHelpWindow`, `XxxXgrSetHuh`,
  `XxxXgrWindowToSystemDisplayAndWindow`, `XxxDIBToDIB24`, `XxxDIBToDIB32`

**Notable implementation details:** Drawing is direct X11 Xlib calls (`XDrawLine`,
`XDrawArc`, `XFillRectangle`, `XDrawPoint(s)`, `XDrawLines`, `XDrawImageString`,
`XGetImage`, `XCopyArea`) on `swindow` plus an optional `sbuffer` for double buffering
(every draw call is mirrored to the buffer via `LocalToBufferCoords`).
`GraphicsContext()` wraps `XCreateGC`; `##WHOMASK`/`##LOCKOUT` guard reentrancy.
Event loop is `DispatchEvents`/`XxxDispatchEvents` with a message queue
(`MESSAGE` type, `CreateQueue`).

---

## 3. xma.x — Mathematics Library

**File:** `src/shared/xma.x` (1,987 lines) — **shared**, compiles on both platforms.
**Header:** `PROGRAM "xma"`, `VERSION "0.0019"`, LGPL. "Angles are always in RADIANS."
**Imports:** xst.

**Public API (EXPORT, lines 30–62):** All `DOUBLE` in/out.

- **Implemented in xma.x:** `ACOS`, `ACOSH`, `ACOT`, `ACOTH`, `ACSC`, `ACSCH`, `ASEC`,
  `ASECH`, `ASIN`, `ASINH`, `ATANH`, `COSH`, `COT`, `COTH`, `CSC`, `CSCH`, `LOG`, `LOG10`,
  `SEC`, `SECH`, `SINH`, `TANH`
- **EXTERNAL (from clib):** `ATAN`, `COS`, `EXP`, `EXP2`, `EXP10`, `POWER`, `SIN`, `SQRT`, `TAN`
- **Internal helpers:** `Asin0`, `Expmo`, `Log0`
- **x87 FPU EXTERNAL wrappers (lines 77–102):** `XxxFSTCW`, `XxxFSTSW`, `XxxF2XM1`,
  `XxxFABS`, `XxxFCHS`, `XxxFCOS`, `XxxFLDZ`, `XxxFLD1`, `XxxFLDPI`, `XxxFLDL2E`,
  `XxxFLDL2T`, `XxxFLDLG2`, `XxxFLDLN2`, `XxxFPATAN`, `XxxFPREM`, `XxxFPREM1`,
  `XxxFPTAN`, `XxxFRNDINT`, `XxxFSCALE`, `XxxFSIN`, `XxxFSINCOS`, `XxxFSQRT`,
  `XxxFXTRACT`, `XxxFYL2X`, `XxxFYL2XP1`

**Constants (EXPORT, lines 110–136):** `$$NNAN`, `$$PNAN`, `$$NINF`, `$$PINF`, `$$RADIANS`,
`$$DEGREES`, `$$DEGTORAD`, `$$RADTODEG`, `$$PI`, `$$TWOPI`, `$$PI3DIV2`, `$$PIDIV2`,
`$$PIDIV4`, `$$INVPI`, `$$SQRT2`, `$$SQRT2DIV2`, `$$INVSQRT2`, `$$E`, `$$LOG2E`,
`$$LOG210`, `$$LOGE2`, `$$LOGE10`, `$$LOGESQRT2`, `$$LOG102`, `$$LOG10E`, `$$PIDIV8`,
`$$PI3DIV8` (stored as raw IEEE-754 hex bit patterns via `0d` literals).

---

## 4. xcm.x — Complex Number Library

**File:** `src/shared/xcm.x` (996 lines) — **shared**.
**Header:** `PROGRAM "xcm"`, `VERSION "0.0007"`, LGPL.
**Imports:** xst, xma.

**Data types:** `DCOMPLEX` (double-precision .R/.I) and `SCOMPLEX` (single-precision .R/.I)
— these are **built-in XBASIC types** (`$$SCOMPLEX=32`, `$$DCOMPLEX=33` in xst.x),
not user types.

**Public API (EXPORT, lines 27–78):**

- **DCOMPLEX functions:** `Xcm`, `XcmVersion$`, `DCABS`, `DCACOS`, `DCARG`, `DCASIN`,
  `DCATAN`, `DCCONJ`, `DCCOS`, `DCCOSH`, `DCEXP`, `DCLOG`, `DCLOG10`, `DCNORM`, `DCPOLAR`,
  `DCPOWERCC`, `DCPOWERCR`, `DCPOWERRC`, `DCRMUL`, `DCSIN`, `DCSINH`, `DCSQRT`, `DCTAN`,
  `DCTANH`
- **SCOMPLEX functions (mirror set):** `SCABS`, `SCACOS`, `SCARG`, `SCASIN`, `SCATAN`,
  `SCCONJ`, `SCCOS`, `SCCOSH`, `SCEXP`, `SCLOG`, `SCLOG10`, `SCNORM`, `SCPOLAR`,
  `SCPOWERCC`, `SCPOWERCR`, `SCPOWERRC`, `SCRMUL`, `SCSIN`, `SCSINH`, `SCSQRT`, `SCTAN`,
  `SCTANH`
- **Internal helpers:** `XdcGetAlpha`, `XdcGetBeta` (used by DCASIN/DCACOS),
  `XscGetAlpha`, `XscGetBeta`, `Atan2`

---

## 5. xin.x — Sockets/Network Library

**File:** `src/linux/xin.x` (2,819 lines) — Linux-only (Windows uses Winsock via `wsock32.dec`).
**Header:** `PROGRAM "xin"`, `VERSION "0.0100"`, LGPL.
**Imports:** xst, xui, clib.

**Data types:** `SOCKET` (fields incl. `.status`, `.syssocket`, `.syserror`, `.address$$`,
`.port`, `.remote`, `.readbytes`, `.writebytes`), `HOST` (`.name`, `.alias[2]`, `.system`,
`.address` GIANT, `.addresses[7]`, `.hostnumber`, `.addressFamily`, `.protocolFamily`,
`.protocol`).

**Public API (EXPORT, lines 78–97):**

- **Init:** `Xin`, `XinInitialize`
- **Address/host:** `XinAddressNumberToString`, `XinAddressStringToNumber`,
  `XinHostNameToInfo`, `XinHostNumberToInfo`, `XinHostAddressToInfo`
- **Socket lifecycle:** `XinSocketOpen`, `XinSocketBind`, `XinSocketListen`,
  `XinSocketAccept`, `XinSocketConnectRequest`, `XinSocketConnectStatus`,
  `XinSocketGetAddress`, `XinSocketGetStatus`, `XinSocketRead`, `XinSocketWrite`,
  `XinSocketClose`
- **Debug:** `XinSetDebug`

**Internal:** `XxxXinBlowback`, `Blowback`, `GetLastError`, `AddHost`,
`SetSocketBlocking`, `SetSocketNonBlocking`, `SystemErrorToError`, FD_SET emulation
(`FDCLR`, `FDSET`, `FDISSET`, `FDZERO`, `FDCOUNT`), Windows emulation (`closesocket`,
`ioctlsocket`).

**Constants (EXPORT, lines 128–155):** `$$NETWORKVERSION=0x0101`,
`$$SocketStatusOpenSuccess=0x00000001`, `$$SocketStatusBindSuccess=0x00000002`,
`$$SocketStatusListenSuccess=0x00000004`, `$$SocketStatusAcceptSuccess=0x00000008`,
`$$SocketStatusConnectRequest=0x00000010`, `$$SocketStatusConnectSuccess=0x00000020`,
`$$SocketStatusConnected=0x00000040`, `$$SocketStatusRemote=0x00000080`,
`$$SocketStatusWaitingReadBuffer=0x00000100`, `$$SocketStatusWaitingWriteBuffer=0x00000200`,
`$$SocketReadPeekData=0x00000002`.

Socket protocol constants (`$$SOCK_STREAM=1`, `$$SOCK_DGRAM=2`, `$$SOCK_RAW=3`,
`$$AF_INET=2`, `$$PF_INET=$$AF_INET`, `$$IPPROTO_TCP=6`, `$$IPPROTO_UDP=17`) are
**not** in xin.x — they come from `include/clib.dec` (lines 736–840) and
`include/wsock32.dec` (Windows).

**Notable implementation details:** "Pseudo-non-blocking" design — the `block` argument
is in microseconds and any value above 20000 (20 ms) is clamped to 20000 before
`select()` is called. All I/O is `select()`-based polling with FD_SET bitmaps emulated
in XBASIC. Windows socket API names (`closesocket`, `ioctlsocket`) are emulated with
UNIX equivalents for source compatibility.

---

## 6. xgrids.x — Grid/Table Control Reference Collection

**File:** `src/linux/xgrids.x` (5,424 lines).
**Header:** explicitly states: "This is NOT a program. This file will not compile or
execute." It is a collection of grid functions meant to help design/modify your own
grid functions. "These functions work, but are not guaranteed to be bug-free" (not kept
up to date with GraphicsDesigner/GuiDesigner). "You cannot imbed these functions in
your programs without renaming the functions and grid types because the function and
grid type names are already defined in GuiDesigner."

**Public API (lines 20–43):** `XuiCheckBox`, `XuiColor`, `XuiDialog2B`, `XuiDialog3B`,
`XuiDialog4B`, `XuiDropBox`, `XuiDropButton`, `XuiLabel`, `XuiListBox`, `XuiListButton`,
`XuiListDialog2B`, `XuiMessage1B`, `XuiMessage2B`, `XuiMessage3B`, `XuiMessage4B`,
`XuiPressButton`, `XuiProgress`, `XuiPushButton`, `XuiRadioBox`, `XuiRadioButton`,
`XuiRange`, `XuiScrollBarH`, `XuiScrollBarV`, `XuiToggleButton`.

**Structure:** each control is a grid-function pair: a `FUNCTION Xui*` dispatcher
(message-driven, `GOSUB @sub[message]`) plus SUB handlers (`Create`, `CreateWindow`,
`KeyDown`, `MouseDown`, `Selected`, `RedrawGrid`, `Initialize`, etc.) — 278
FUNCTION/SUB matches total. All take the standard signature
`(grid, message, v0, v1, v2, v3, r0, ANY)`.

---

## 7. xdis.x — i486+ Disassembler

**File:** `src/shared/xdis.x` (2,301 lines) — **shared**.
**Header:** `PROGRAM "xdis"`, `VERSION "0.0017"`, **GPL** (`COPYING` — note: different
license from the LGPL libraries). "Windows XBasic i486+ disassembler function library" /
"Linux XBasic disassembler function library".
**Imports:** xut.

**Data types:** `D86REGOP` (`.action` SUBADDR, `.param`, `.opsiz` — one of a set of
opcodes for the REG field of MOD-REG-RM byte, stored in groups of 8), `D86BYTE`
(`.action`, `.param`, `.param2`, `.flags` — what to do in response to a given
instruction byte).

**Public API:** `Xdis()`, `XxxDisassemble$(pbyte, useLabel)` — disassembles one 486
instruction at `pbyte`, advances `pbyte` to the next instruction, returns opcode +
disassembled text; `useLabel` replaces branch offsets with compiler labels.

**Internal:** `GetAddrLabel$` plus ~50 decode SUBs: `Disp8`, `Disp32`,
`EffectiveAddress`, `GetByte`, `Offset8`, `Offset32`, `PeekByte`, `ReadImm`,
`ReadImm8`, `ReadImm16`, `ReadImm32`, `ReadSib`, `RegString`, `AccumEa`, `AccumImm`,
`AccumImm8`, `AccumOffset`, `Branch8`, `Branch32`, `EaImm`, `EaImm8`, `EaTwid1`,
`EaTwidCL`, etc.

**EXTERNAL (provided by the compiler):** `XxxGetLabelGivenAddress`, `XxxPassFunctionArrays`.

**Notable implementation details:** `Init` builds static decode tables
`d86[11,256]`, `regop[$RO_MAX,8]`, `opcode$[]`, `special$[]`, register-name arrays
(`reg8$`, `reg16$`, `reg32$`, `sreg$`, `segreg$`, `scaleFactor$`). Dispatch is
table-driven via `D86BYTE.action` (SUBADDR). **Cross-platform conditional:** Linux
symbol names have no leading underscore; Windows uses a `"_"` prefix (lines 2283–2287).
**Purpose:** consumed by the IDE `xit.x` for the debugger's disassembly view
(`DisplayAssembly`/`XxxAnyAsm$` at xit.x lines 2847, 2892, 4532, 4576, 20114, 20120).

---

## Cross-platform summary

| Library | Location | License | Platform |
|---|---|---|---|
| xst.x | src/linux | LGPL | Linux |
| xgr.x | src/linux | LGPL | Linux |
| xma.x | src/shared | LGPL | Windows + Linux |
| xcm.x | src/shared | LGPL | Windows + Linux |
| xin.x | src/linux | LGPL | Linux |
| xgrids.x | src/linux | (none) | Linux, reference only |
| xdis.x | src/shared | GPL | Windows + Linux |

Windows counterparts exist for the linux-only libs (e.g. `win32/xst.x`). The shared
libs (xma, xcm, xdis) compile on both platforms; xdis additionally has a symbol-naming
conditional (leading `_` on Windows).