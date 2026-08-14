# 11 — .s Runtime & Platform Syscall Surface Survey

> Status: Survey complete — input for the 6.5.0 Rust+LLVM rewrite planning (see `12-rust-llvm-rewrite-survey.md`).
> Scope: raw OS syscalls and platform API touchpoints across `xbasic-6.2.3` (baseline), `xbasic-6.3.26-D` (Win32 fork), `xbasic-6.4.5` (Linux 64-bit port).

## 1. Headline findings

1. **Zero raw assembly syscalls in any tree.** Greps for `int $0x80`, `sysenter`, `lcall`, `int 0x2E`, `INT 21h` across every `*.s` file return nothing. All "syscall" grep hits are comments (e.g. "save it where read/write syscall can't get to it"). All OS access is via **libc calls** (from assembly or via CFUNCTION declarations in `.x` sources) or **Win32 API imports**.
2. **Only 6 hand-written `.s` files exist** — exactly `src/linux/lib/` in 6.4.5:
   - `xlib.s` — 14,772 lines, 463 `.globl` exports, `VERSION "6.4.2"` (fake statement)
   - `xstart.s` — 42 lines, 0 exports
   - `appstart.s` — 67 lines, `VERSION "0.0002"`, 4 exports
   - `xzzz.s` — 25 lines, 2 exports
   - `xlib230325.s` / `xlib230803.s` — dated backups (why kept? → see §5)
3. **Everything else is compiler-generated** via the `%.s: %.x` rule (`.PRECIOUS: %.s`): `xcol.s` (206,767 lines), `xui.s` (298,334), `xit.s` (180,740), `xrun.s` (2,113), `user32.s` (2,210), `gdi32.s` (1,796), `kernel32.s` (3,821). These are **codegen output, not hand-written GAS** — irrelevant to toolchain migration except as a build-artifact concern.
4. **The hand-written runtime is legacy-dated**: copyright 1988–2000 Max Reason (LGPL), x87 FPU intrinsics, `*cw*` markers showing 2023 patches for Debian 10 ABI (`__rsp_odd/even`, REX-prefix 64-bit idioms).

## 2. Per-tree inventory

| Tree | Raw Linux syscalls | Windows API | libc | Xxx intrinsics | Signals | Mechanism |
|---|---|---|---|---|---|---|
| 6.2.3 (baseline) | 0 | 229 | 2,043 | 103 | 64 | Linux: libc via CFUNCTION in `.x`; Win32: direct API calls in asm |
| 6.3.26-D (Win32 fork) | 0 | 2,114 | 1,933 | 580 | 2 (comments) | Win32 API via `.def` IMPORTS + direct asm calls; SEH in C |
| 6.4.5 (Linux 64-bit) | 0 | 512 | 3,373 | 849 | 360 | Direct libc calls from asm + C ports in `src/crtl/` |

Counts are per src tree (files matched, not raw lines); all verified with targeted greps.

## 3. Classification per the modernization report taxonomy

### Category 1 — math/vector (FPU intrinsics)

- **6.2.3** `src/win32/lib/xlib.s`: `_XxxFCOS@8` L1288, `_XxxFPREM@16` L1320, `_XxxFPREM1@16` L1339, `_XxxFSIN@8` L1407, `_XxxFSINCOS@16` L1417, `_XxxFSQRT@8` L1429; globals at L179–217. Full FP set exported via `src/win32/xb.def` L7–47: `XxxFCOS, XxxFPREM, XxxFPREM1, XxxFSIN, XxxFSINCOS, XxxFSQRT, XxxF2XM1, XxxFABS, XxxFCHS, XxxFPATAN, XxxFPTAN, XxxFRNDINT, XxxFSCALE, XxxFXTRACT, XxxFYL2X, XxxFYL2XP1, XxxFLDZ/FLD1/FLDPI/FLDL2E/FLDL2T/FLDLG2/FLDLN2, XxxFSTCW, XxxFSTSW, XxxFCLEX, XxxFINIT, XxxFPUstatus`. Declared in `src/shared/xma.x:23`.
- **6.2.3 Linux** `src/linux/lib/xlib.s`: `COS_8` L1776, `ATAN_8` L1787, `TAN_8` L1858, `SIN_8` L1898, `SQRT_8` L1920, `EXP_8` L1965, `EXPE_8` L1966, `EXP2_8` L1980, `EXP10_8` L1991, `EXPX_16` L2030, `POWER_16` L2031.
- **6.4.5**: FP moved to **C** — `src/crtl/xlib.c` is the C port of the FP-heavy xlib.s. Asm retains `XxxFSIN`…`XxxFSTCW` in `lib/xlib*.s` (18 each).
- **6.3.26-D / 6.4.5 caveat**: most `xgr.*` `XxxLog` matches are `XxxLog2`/`XxxLog10` — XBasic *logging* functions, NOT FP intrinsics (pattern false positive).

### Category 2 — syscall / context switch (OS interface)

- **6.2.3 Linux** — libc via CFUNCTION declarations in `.x` (no asm libc calls except `exit`):
  - `src/linux/kernel32.x`: `dlopen` L707, `dlsym` L555, `dlclose` L363/722
  - `src/linux/xin.x`: `socket` L811, `bind` L913, `listen` L993, `select` L1111/1450/1842, `accept` L1155, `connect` L1290, `recv` L1882, `send` L2070, `getsockopt` L1684–1726, `getsockname` L1594, `getpeername` L1605, `close` L2796, `ioctl` L2814
  - `src/linux/xrun.x`: `getpid` L293
  - `src/linux/lib/xlib.s`: `call exit` L1325
  - C glue `src/linux/xbiface.c`: `xb_stat` wraps `stat()` L98–151, `xb_sigaction` wraps `sigaction()` L165–186, `xb_readdir` wraps `readdir()` L208–213 — libc5/libc6 struct-layout compatibility shim
- **6.2.3 Win32** — direct API calls in asm `src/win32/lib/xlib.s`: `_VirtualAlloc@16` L978/993/1007/1023/2441, `_WriteFile@20` L2077/2115, `_CreateFileA@28` L2098, `_ExitProcess@4` L1142, `_GetVersion@0` L961, `_VirtualFree@12` L1140, `_PeekMessageA@20` L1867. Plus `.x` calls: `src/win32/xst.x` `LoadLibraryA` L7173, `ReadFile` L9777/9906/10257, `CreateFileA` L10087, `WriteFile` L10492; wrappers `XxxXstLoadLibrary` L292/7139, `XxxReadFile` L322/10220, `XxxWriteFile` L326/10463.
- **6.3.26-D** — Win32 API via `.def` IMPORT tables + direct `call _Foo@N` from asm:
  - `xst.s` is densest (500+ calls): `_VirtualAlloc@16` L3525/79456, `_VirtualQuery@12` L3547/3681/3903/4033/79421, `_CreateProcessA@40` L10246/79087, `_ReadFile@20` L10341/76299/76952/78524, `_WriteFile@20` L56239/79763/79877, `_CreateFileA@28` L77696, `_GetProcAddress@8` L48/72/96, `_LoadLibraryA@4` L52753, `_FreeLibrary@4` L52455, `_GetModuleFileNameA@12` L52021, `_ExitProcess@4` L51865/78203, `_MessageBoxA@16` L51858/51926, `_RaiseException@16` L3187, `_SetTimer@16` L11277/11439/11774, `_KillTimer@8` L8488/8689/11237, `_GetCommandLineA@0` L5526/5793, `_GetEnvironmentStrings@0` L6876, `_GetEnvironmentVariableA@12` L6764, `_SetEnvironmentVariableA@8` L9434, `_GetSystemInfo@4` L6258, `_GetSystemTime@4` L6365, `_GetLocalTime@4` L6473, `_SetSystemTime@4` L9335, `_GetTickCount@0` L8129/8146/10600/10630/10701, `_Sleep@4` L10627/10698/79156, `_CreatePipe@16` L10166, `_GetStdHandle@4` L10210/56284/56331/76865/79342–79352/79929, `_GetExitCodeProcess@8` L10414/79162, `_OpenProcess@12` L79140, `_CloseHandle@4` L10288/10435–10465/74857/75583/79105–79111/79220, `_SetFilePointer@16` L75940–76664/77270–77338/78071/78696, `_GetFileAttributesA@4` L21046, `_FindFirstFileA@8` L21520/22658, `_FindNextFileA@8` L21723/22930, `_FindClose@4` L21746/22980, `_CopyFileA@12` L16497, `_MoveFileA@8` L27714, `_DeleteFileA@4` L17069, `_RemoveDirectoryA@4` L17032, `_CreateDirectoryA@8` L25743, `_SetCurrentDirectoryA@4` L15358/28312, `_GetCurrentDirectoryA@8` L19739/19791, `_GetFullPathNameA@16` L27151, `_GetLogicalDriveStringsA@8` L20094, `_GetLogicalDrives@0` L20129, `_GetDriveTypeA@4` L20330, `_LockFile@20` L25449, `_UnlockFile@20` L29003, `_SHFileOperationA@4` L26012, `_GetVersionExA@4` L75122, `_WriteConsoleA@20` L56193/79844, `_AttachConsole@4` L56305/79947, `_GetFileType@4` L56368/76879/79991, `_GetKeyState@4` L55812, `_SystemTimeToFileTime@8` (line truncated in source survey).
  - `.def` IMPORT tables: `xgr.def` (102), `xst.def` (59), `xit.def` (14), `xcow.def` (3), `xrun.def` (2), `xut.def` (2), `xui.def` (2)
  - Winsock `src/win32/xin.def` L25–47: IMPORTS `wsock32.WSACleanup, WSAGetLastError, WSAStartup, accept, bind, closesocket, connect, gethostbyaddr, gethostbyname, gethostname, getpeername, getprotobyname, getsockname, getsockopt, htons, inet_addr, inet_ntoa, ioctlsocket, listen, recv, select, send, socket`
  - `.x` usage `src/win32/xin.x`: WSAStartup L687, gethostname L706, inet_addr L807, socket L963, htons L1059, bind L1065, listen L1145, select L1263
- **6.4.5** — direct libc from asm:
  - `src/linux/xin.s`: `call socket` L5750/15342, `call bind` L6415, `call listen` L6904, `call select` L7615/9599/11714/13576, `call accept` L7852, `call connect` L8697/15875, `call close` L14312/17024/20169, `call getifaddrs` L15258, `call getnameinfo` L16399, `call ioctl` L20251
  - `src/linux/xst.s`: `call getpid` L2465/7736, `call chdir` L13799/25851, `call rmdir` L15377, `call unlink` L15416, `call getcwd` L18552, `call opendir` L19999, `call fcntl` L23417/27163, `call mkdir` L23713, `call rename` L25313, `call readlink` L26189/26297, `call mmap` L77356
  - `src/linux/lib/xlib.s`: `call exit` L1428, `call mmap` L1571/2880; `xlib230803.s`: `call exit` L1422, `call mmap` L1565/2831; `xlib230325.s` same pattern
  - `src/linux/xrun.s`: `call exit` L411/682/713/1907, `call getpid` L1680
  - `src/linux/xit.s`: `call exit` L5416/152651
  - `src/linux/kernel32.s`: `call dlclose` L1238/2772, `call dlsym` L1913, `call dlopen` L2638
  - C glue `src/linux/xbiface.c`: `_LARGEFILE_SOURCE`/`_LARGEFILE64_SOURCE` L25–26, `long long xst_size` L55, `xb_stat` L96–112, `xb_lstat` L136–151, `xb_sigaction` L170–191, `xb_readdir` L213–218, `xb_geterrno` L256–259, `xb_seterrno` L264–267
  - CFUNCTION bridge in `.x` `src/linux/xst.x` L458–461: `EXTERNAL CFUNCTION xb_geterrno()`, `xb_seterrno(value)`, `xb_lstat(addrFile, addrUstat)`, `xb_readdir(idir, addrDirent)`; used at L1975/2287/2516/4679/4902…

### Category 3 — hardware register ops (frame/stack)

- **6.2.3** `src/win32/lib/xlib.s`: `_XxxGetEbpEsp@8` L1743, `_XxxSetEbpEsp@8` L1753 (EIP/EBP/ESP read-write intrinsics); `src/shared/xma.x` declares them.
- **6.4.5** `src/linux/lib/xlib.s` (64-bit, REX-prefix): `XxxMain` L1205 (`pushq %rbp; movq %rsp,%rbp`, SysV args rdi/rsi/rdx/rcx/r8/r9 → `_argc/_argv/_envp`), `XxxStartApplication_0` L1618, `XxxRspOdd_0`/`XxxRspEven_0`/`XxxRestoreRsp_0` L1720–1750 (`*cw* 230108 for Debian 10`), `XxxGetRbpRsp_16` L1758, `XxxSetRbpRsp_16` L1769, `XxxGetFrameAddr_0` L1790, `XxxSetFrameAddr_8` L1799, `__rsp_odd`/`__rsp_even`/`__rsp_restore` (`*cw* 230819+`).

### Signals / exceptions

- **6.2.3** (sigaction-based): `src/linux/xrun.x` `DECLARE CFUNCTION XxxXitMain(sigNumber)` L29, `sig.sa_handler = &XxxXitMain()` L183, `getpid` L293; `src/linux/xst.x` exception→signal mapping L918–934 (SegmentViolation→SIGSEGV, DivideByZero→SIGFPE, InvalidInstruction→SIGILL), reverse mapping L1984–1995 (SIGILL/SIGFPE/SIGSEGV/SIGALRM), signal-name table L6884–6895. Win32 `xit.x` has 3 XxxXitMain references.
- **6.3.26-D** — **no signal machinery**; SEH instead: `src/win32/xexcept.c` L78 `_except( XitMain(GetExceptionCode(), GetExceptionInformation()) )`, `extern long PASCAL XitMain(DWORD code, LPEXCEPTION_POINTERS ep)` L24. `xit.x` L1351/1466 comments only.
- **6.4.5** — **ptregs-aware**: `src/linux/xrun.x` `DECLARE CFUNCTION XxxXitMain(sigNumber, ptregs)` L30 (old single-arg signature commented L29), `DECLARE CFUNCTION XxxXitSigAlrm(signal)` L31, CFUNCTION defs L107/L175, `sig.sa_handler = &XxxXitMain()` L235, `&XxxXitSigAlrm()` L255. Extended mapping in `xst.x` L1188–1204 (12 pairs: SegmentViolation→SIGSEGV, OutOfBounds→SIGBUS, Breakpoint→SIGTRAP, BreakKey→SIGINT, Alignment→SIGBUS, Denormal/DivideByZero/InvalidOperation/Overflow/Underflow→SIGFPE, StackCheck/Privilege/StackOverflow→SIGSEGV, InvalidInstruction→SIGILL); plus `xit.s` L136, `xit.x` L113, `xrun.s` L37, `xst.s` L26.

## 4. Raw-vs-libc verdict

- **6.2.3**: Linux side delegates 100% to libc via CFUNCTION declarations in `.x` (only `exit` is called from asm); Win32 side calls the API directly from asm. No raw syscalls.
- **6.3.26-D**: Pure Win32 — API accessed via `.def` IMPORT tables (wsock32, kernel32, …) and direct `call _Foo@N` from asm; exceptions via SEH (`xexcept.c`). No raw syscalls, no signals.
- **6.4.5**: Linux 64-bit — libc called directly from assembly (mmap, socket, bind, select, dlopen, getifaddrs, …), plus a parallel C port of the runtime in `src/crtl/`. Signal handling is ptregs-aware. No raw syscalls.

## 5. Notes for the Rust rewrite

1. **Compiler-generated `.s` (the 200k–300k-line files) are a non-issue** — build artifacts of `.x` codegen; only the hand-written runtime `.s` matters.
2. **The dated backups `xlib230325.s` / `xlib230803.s` likely record ABI-break incidents** (Debian 10 stack alignment, rsp odd/even) — worth mining for the version-diff feature list (see `12-rust-llvm-rewrite-survey.md`).
3. **The touchpoint surface to replace** (from highest to lowest priority):
   - 6.4.5 asm libc calls (`xin.s`, `xst.s`, `xlib.s`, `kernel32.s`, `xrun.s`, `xit.s`) → Rust `std`/`libc`/`nix` equivalents; `src/crtl/*.c` shows the intended migration path.
   - 6.2.3 CFUNCTION libc declarations (`kernel32.x`/`xin.x`/`xrun.x`) → Rust std equivalents.
   - Win32 API surface (6.3.26-D `xst.s`/`xcow.s`/`xit.s` + 6.2.3 win32 `xlib.s`) → `windows-sys`/`windows` crate; 6.4.5 `gdi32.s`/`kernel32.s`/`user32.s` stubs show how the API was emulated on Linux.
   - Signal machinery — 6.4.5's ptregs-aware `XxxXitMain` is the model; 6.2.3's sigaction-based is the simpler baseline.
   - FP intrinsics — 6.2.3 asm-defined; 6.4.5 moved to C (`crtl/xlib.c`); Rust rewrite should use LLVM intrinsics or `libm`.
