//! RR-08b: Behavior gates for stateful libraries.
//!
//! Compiles xst.x (standard library) through the Rust CEmitter and verifies
//! that user-defined function bodies execute correctly — not just compile,
//! but produce correct deterministic results. This extends RR-08a (pure
//! library behavior) to stateful libraries that use SHARED variables,
//! SELECT CASE on system variables, and byref output parameters.
//!
//! Test functions from xst.x with known deterministic outputs:
//!   XstGetOSName(@name$)  → "unix"      (SELECT CASE: ##XBSystem=0 ≠ $$XBSysLinux=1)
//!   XstGetConsoleGrid(@grid) → 0        (reads xb_shared_CONGRID, init 0)
//!   XstVersion$()         → "6.4.5"     (calls VERSION$(0) → xb_version(0))
//!   XstGetEndianName(name$) → ret 0     (byval: string lost, return proves body ran)
//!   XstGetCPUName(name$)    → ret 0     (byval: string lost, return proves body ran)
//!   XstExceptionToSystemException(exc, @sig) → maps exception→signal
//!     (e.g. ExceptionSegmentViolation(1)→SIGSEGV(11), ExceptionBreakKey(4)→SIGINT(2))
//!
//! The byref detection is callsite-driven: XstGetOSName, XstGetConsoleGrid,
//! and XstVersion$ are called with `@` at least once inside xst.x, so the C
//! emitter gives them `char**` / `intptr_t*` signatures with copy-in/copy-out.
//! XstGetEndianName and XstGetCPUName are never called with `@` inside xst.x,
//! so they get byval `char*` signatures — the string output is lost (local
//! copy), but the return value 0 proves the function body executed. This tests:
//!   - SELECT CASE lowering on SHARED system variables
//!   - String assignment to byref output parameters
//!   - Integer byref output parameters
//!   - SHARED variable reads (xb_shared_CONGRID, xb_shared_XBSystem)
//!   - RETURN value path for string functions (XstVersion$)
//!   - Byval string function body execution (return value only)

use std::fs;
use std::path::PathBuf;
use std::process::Command;

fn repo_root() -> PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

fn xb_bin() -> PathBuf {
    if let Ok(p) = std::env::var("XB_BIN") {
        return PathBuf::from(p);
    }
    if let Ok(p) = std::env::var("CARGO_BIN_EXE_xb") {
        return PathBuf::from(p);
    }
    let candidate = repo_root().join("target/release/xb");
    if candidate.exists() {
        return candidate;
    }
    repo_root().join("target/debug/xb")
}

fn cc() -> &'static str {
    std::env::var("CC")
        .unwrap_or_else(|_| "cc".to_string())
        .leak()
}

/// Compile a .c file to a .o object file.
fn compile_c(c_file: &std::path::Path, out: &std::path::Path) -> PathBuf {
    let stem = c_file.file_stem().unwrap().to_str().unwrap();
    let o_file = out.join(format!("{stem}.o"));
    let output = Command::new(cc())
        .args([
            "-O0",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
        ])
        .arg("-c")
        .arg(c_file)
        .arg("-o")
        .arg(&o_file)
        .output()
        .expect("cc");
    assert!(
        output.status.success(),
        "cc failed for {c_file:?}:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    o_file
}

#[test]
fn xst_stateful_library_behavior() {
    let root = repo_root();
    let tmp = std::env::temp_dir().join("xb_stateful_lib_behavior");
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    // Compile xst.x through CEmitter.
    let xst_src = root.join("xbasic/lib/xst.x");
    assert!(xst_src.exists(), "xst.x not found at {xst_src:?}");

    let xst_c = {
        let stem = xst_src.file_stem().unwrap().to_str().unwrap();
        let c_file = tmp.join(format!("{stem}.c"));
        let output = Command::new(xb_bin())
            .arg("--emit-c")
            .arg(&xst_src)
            .env("XB_WEAK_SYMBOLS", "1")
            .output()
            .expect("emit-c");
        assert!(
            output.status.success(),
            "emit-c failed for xst.x:\n{}",
            String::from_utf8_lossy(&output.stderr)
        );
        fs::write(&c_file, &output.stdout).unwrap();
        c_file
    };
    let xst_o = compile_c(&xst_c, &tmp);

    // Write a C test harness that calls the compiled legacy bodies.
    //
    // XstGetOSName: byref string output (char**). SELECT CASE on ##XBSystem
    //   (xb_shared_XBSystem, init 0). $$XBSysLinux resolves to 0 (undefined
    //   in xst.x, defaults to 0). So _sel == 0 → "linux unix".
    //
    // XstGetConsoleGrid: byref integer output (intptr_t*). Reads
    //   xb_shared_CONGRID (init 0). Output should be 0.
    //
    // XstVersion$: return value (char*). Calls VERSION$(0) → xb_version(0)
    //   which returns xb_version_str = "6.4.5".
    let harness = tmp.join("harness.c");
    fs::write(&harness, r#"#include <stdio.h>
#include <stdlib.h>
#include <string.h>
/* XBasic strings are managed (length stored before data pointer). xb_str()
   is static in the runtime, so we define a local wrapper that allocates
   via the same protocol: [size_t len, size_t cap, char data[]]. */
static char* xb_str(const char* s) {
    size_t n = strlen(s);
    size_t* p = (size_t*)malloc(2 * sizeof(size_t) + n + 1);
    p[0] = n; p[1] = n;
    char* d = (char*)(p + 2);
    memcpy(d, s, n);
    d[n] = 0;
    return d;
}
intptr_t xb_user_XstGetOSName(char* *xb_str_name_ref);
intptr_t xb_user_XstGetConsoleGrid(intptr_t *xb_var_grid_ref);
char* xb_user_XstVersion(void);
intptr_t xb_user_XstGetEndianName(char* *xb_str_name_ref);
intptr_t xb_user_XstGetCPUName(char* *xb_str_name_ref);
intptr_t xb_user_XstGetApplicationEnvironment(intptr_t *xb_var_standalone_ref, intptr_t *xb_var_reserved_ref);
/* XstExceptionToSystemException: byref int — maps exception→signal.
   Called with @sysException inside XstCauseException. */
intptr_t xb_user_XstExceptionToSystemException(intptr_t xb_var_exception, intptr_t *xb_var_sysException_ref);
/* XstSystemExceptionToException: byref int — maps POSIX signal→XBasic exception.
   Never called inside xst.x; DECLARE @ markers mark exception as byref.
   Constants: $$SIGNONE=0,$$SIGHUP=1,$$SIGINT=2,$$SIGILL=4,$$SIGTRAP=5,
   $$SIGABRT=6,$$SIGBUS=7,$$SIGFPE=8,$$SIGSEGV=11,$$SIGSTKFLT=16,$$SIGVTALRM=26.
   Exceptions: None=0,SegViol=1,Breakpoint=3,BreakKey=4,Alignment=5,
   InvalidOp=8,InvalidInstr=12,StackOverflow=14,Timer=16,Unknown=17. */
intptr_t xb_user_XstSystemExceptionToException(intptr_t xb_var_signal, intptr_t *xb_var_exception_ref);
/* XstSystemErrorToError: byref int — maps system error number to XBasic error.
   UBOUND(#OSERROR$[]) returns -1 (uninitialized SHARED array), so upper=-1.
   Any sysError >= 0 triggers sysError > upper → error = (24<<8)|3 = 6147. */
intptr_t xb_user_XstSystemErrorToError(intptr_t xb_var_sysError, intptr_t *xb_var_error_ref);
/* XstGetSystemTime: byref int — returns elapsed msec. All time fields init 0,
   so msec = (0-0)*1000 + (0-0) = 0. */
intptr_t xb_user_XstGetSystemTime(intptr_t *xb_var_msec_ref);
/* DeltaTimeZone: byref int — returns timezone delta seconds.
   gtime=ltime=0 → delta = 0-0 = 0. */
intptr_t xb_user_DeltaTimeZone(intptr_t *xb_var_delta_ref);
/* XstGetDateAndTime: 8 byref ints — all time_tm fields init 0.
   year=1900, month=1, day=0, weekDay=0, hour=0, min=0, sec=0, nanos=0. */
intptr_t xb_user_XstGetDateAndTime(intptr_t *xb_var_year_ref, intptr_t *xb_var_month_ref,
    intptr_t *xb_var_day_ref, intptr_t *xb_var_weekDay_ref, intptr_t *xb_var_hour_ref,
    intptr_t *xb_var_minute_ref, intptr_t *xb_var_second_ref, intptr_t *xb_var_nanos_ref);
/* XstGetOSVersionName: byref string (DECLARE @name$) — return 0 proves body ran.
   Would produce "4.0" if output read (xb_extu(0x0400,8,8)=4, xb_extu(0x0400,8,0)=0). */
intptr_t xb_user_XstGetOSVersionName(char* *xb_str_name_ref);
/* String functions: return char* — deterministic output for known inputs.
   index/done params are byref (DECLARE @index,@done), but the
   return value is the extracted/merged string. */
char* xb_user_XstNextField(char* xb_str_source, intptr_t *xb_var_index_ref, intptr_t *xb_var_done_ref);
char* xb_user_XstNextLine(char* xb_str_source, intptr_t *xb_var_index_ref, intptr_t *xb_var_done_ref);
char* xb_user_XstMergeStrings(char* xb_str_string, char* xb_str_add, intptr_t xb_var_start, intptr_t xb_var_replace);
/* XstParse: returns n-th field from delimited string. Pure string ops, no InitProgram().
   XstTally: counts delimiter occurrences in source. Returns -1 for empty source.
   XxxPathString: converts path separators (\ → / on Linux). Returns NULL for empty path. */
char* xb_user_XstParse(char* xb_str_source, char* xb_str_delimiter, intptr_t xb_var_n);
intptr_t xb_user_XstTally(char* xb_str_source, char* xb_str_find);
/* XstParseWhitespace$: returns the wordNumber-th word from a string.
   Calls InitProgram() to populate charsetNotWhiteSpace[] SHARED array.
   Handles quoted strings as single words. */
char* xb_user_XstParseWhitespace(char* xb_str_string, intptr_t xb_var_wordNumber);
/* XstBackStringToBinString$: converts backslash escape sequences (\xHH, \n, \t, etc.)
   to binary characters. Calls InitProgram() to populate charset arrays. */
char* xb_user_XstBackStringToBinString(char* xb_str_backString);
/* XxxPathString: converts path separators (\ → / on Linux). Returns NULL for empty path. */
char* xb_user_XxxPathString(char* xb_str_path);
/* XstErrorNumberToName: byref string output — with InitProgram called,
   errorObject$[]/errorNature$[] arrays are populated. error=0 → "NoError",
   error=(1<<8)|0=256 → "Data". CEMITTER-S-SUFFIX-BYREF fix verified:
   copy-out reads from xb_str_error_s (body local), not copy-in. */
intptr_t xb_user_XstErrorNumberToName(intptr_t xb_var_error, char* *xb_str_error_ref);
/* Setter functions: modify SHARED/SharedName variables. */
void xb_user_XstSetException(intptr_t xb_var_exception);
void xb_user_XstSetPrintTab(intptr_t xb_var_pixels);
void xb_user_XstSetExceptionFunction(intptr_t xb_var_function);
void xb_user_XstSetNewline(intptr_t xb_var_save, intptr_t xb_var_paste);
/* Byval functions with RETURN values — deterministic short-circuit paths. */
intptr_t xb_user_XstRandomRange(intptr_t xb_var_n1, intptr_t xb_var_n2);
intptr_t xb_user_XstBinWrite(intptr_t xb_var_fileNumber, intptr_t xb_var_bufferAddr, intptr_t xb_var_numBytes);
intptr_t xb_user_XstKillTask(intptr_t xb_var_taskNum);
intptr_t xb_user_XstGetTaskInfo(intptr_t xb_var_taskNum, intptr_t *xb_var_count_ref, intptr_t *xb_var_msec_ref, intptr_t *xb_var_func_ref, intptr_t *xb_var_timer_ref, intptr_t *xb_var_skips_ref);
intptr_t xb_user_XstSetProgramName(char* *xb_str_prog_ref);
intptr_t xb_user_XstSetSystemError(intptr_t xb_var_sysError);
/* XstMatchWild: pure function — wildcard pattern matching.
   Returns match position (1-based) or 0 for no match. */
intptr_t xb_user_XstMatchWild(char* xb_str_searchMe, char* xb_str_searchFor, intptr_t xb_var_start, intptr_t xb_var_matchCase);
/* XstGetOSVersion: byref int+int (DECLARE @major,@minor). version=0x0400,
   major=extu(0x0400,8,8)=4, minor=extu(0x0400,8,0)=0. */
void xb_user_XstGetOSVersion(intptr_t *xb_var_major_ref, intptr_t *xb_var_minor_ref);
/* XstGetPrintTab: byref int (DECLARE @pixels). Reads ##TABSAT (init 0). */
void xb_user_XstGetPrintTab(intptr_t *xb_var_pixels_ref);
/* XstGetSystemError: byref int (DECLARE @sysError). Reads xb_geterrno(). */
void xb_user_XstGetSystemError(intptr_t *xb_var_error_ref);
/* XstGetNewline: byref int+int — reads sysSaveNewline/sysPasteNewline SHARED.
   Never called inside xst.x; DECLARE @ markers mark save,paste as byref.
   With ##WHOMASK=0, reads sys* vars; if 0, returns $$NewlineDefault=1. */
void xb_user_XstGetNewline(intptr_t *xb_var_save_ref, intptr_t *xb_var_paste_ref);
/* XstGetException: byref int — reads ##EXCEPTION SharedName.
   XstGetExceptionFunction: byref int — reads SHARED exceptionFunction.
   XstGetProgramName: byref string — reads sysProgram$ (##WHOMASK=0).
   All never called inside xst.x; DECLARE @ markers mark output as byref. */
void xb_user_XstGetException(intptr_t *xb_var_exception_ref);
void xb_user_XstGetExceptionFunction(intptr_t *xb_var_function_ref);
void xb_user_XstGetProgramName(char* *xb_str_prog_ref);
/* XstDecomposePathname: 1 byval string input + 5 byref string outputs.
   Decomposes a pathname into path/parent/fileName/file/extent components.
   Uses $$PathSlash$ which is now properly emitted as xb_const_PathSlash$
   by the CEmitter (initialized via constructor). */
intptr_t xb_user_XstDecomposePathname(char* xb_str_pathname, char* *xb_str_path_ref, char* *xb_str_parent_ref,
    char* *xb_str_fileName_ref, char* *xb_str_file_ref, char* *xb_str_extent_ref);
/* InitProgram: populates SHARED arrays (exception$[], sysException$[], etc).
   Calling it from the harness unblocks shared-array-dependent functions:
   XstExceptionNumberToName, XstSystemExceptionNumberToName,
   XstExceptionToSystemException, XstSystemExceptionToException. */
void xb_user_InitProgram(void);
/* XstExceptionNumberToName: byref string — reads SHARED exception$[] array
   populated by InitProgram. Returns $$TRUE (1) on out-of-range, else 0. */
intptr_t xb_user_XstExceptionNumberToName(intptr_t xb_var_exception, char* *xb_str_exception_ref);
/* XstSystemExceptionNumberToName: byref string — reads SHARED sysException$[]
   array populated by InitProgram. Returns $$TRUE (1) on out-of-range, else 0. */
intptr_t xb_user_XstSystemExceptionNumberToName(intptr_t xb_var_exception, char* *xb_str_exception_ref);
/* XstSystemErrorNumberToName: byref string — reads #OSERROR$[] SHARED array
   populated by InitProgram. Returns 0 on success. */
intptr_t xb_user_XstSystemErrorNumberToName(intptr_t xb_var_sysError, char* *xb_str_sysError_ref);
/* XstSystemErrorToError: byref int — reads #OSTOXERROR[] SHARED array.
   With InitProgram, maps errno to (object<<8)|nature. Without, returns 6147. */
intptr_t xb_user_XstSystemErrorToError(intptr_t xb_var_sysError, intptr_t *xb_var_error_ref);
/* XstFileTimeToDateAndTime: 1 byval int64 input + 8 byref int outputs.
   Converts Windows filetime (100ns units since 1601) to date/time.
   gmtime() call is emitted as 0 (CEmitter doesn't handle composite-returning
   external functions), so time fields stay 0 — but int64 arithmetic
   (subtraction, division, nanos calculation) is testable. */
intptr_t xb_user_XstFileTimeToDateAndTime(int64_t xb_var_filetime, intptr_t *xb_var_year_ref, intptr_t *xb_var_month_ref,
    intptr_t *xb_var_day_ref, intptr_t *xb_var_weekDay_ref, intptr_t *xb_var_hour_ref,
    intptr_t *xb_var_minute_ref, intptr_t *xb_var_second_ref, intptr_t *xb_var_nanos_ref);
/* Weak globals set by the setter functions, readable from the harness. */
extern __attribute__((weak)) intptr_t xb_shared_EXCEPTION;
extern __attribute__((weak)) intptr_t xb_shared_TABSAT;
extern __attribute__((weak)) intptr_t xb_shared_exceptionFunction;
extern __attribute__((weak)) intptr_t xb_shared_sysSaveNewline;
extern __attribute__((weak)) intptr_t xb_shared_sysPasteNewline;
extern __attribute__((weak)) char* xb_shared_sysProgram;
/* Strong errno implementations override the weak stubs in xst.o.
   XstSetSystemError calls xb_user_xb_seterrno; we verify via xb_user_xb_geterrno. */
static int s_errno = 0;
intptr_t xb_user_xb_seterrno(intptr_t value) { s_errno = (int)value; return 0; }
intptr_t xb_user_xb_geterrno(void) { return s_errno; }
static int fails = 0;

static void check_s(const char* name, const char* got, const char* want) {
    int ok = got && strcmp(got, want) == 0;
    printf("%-25s = [%s]  (want [%s])  %s\n", name, got ? got : "(null)", want, ok ? "ok" : "FAIL");
    if (!ok) fails++;
}

static void check_i(const char* name, long got, long want) {
    int ok = got == want;
    printf("%-25s = %ld  (want %ld)  %s\n", name, got, want, ok ? "ok" : "FAIL");
    if (!ok) fails++;
}

int main(void) {
    /* XstGetOSName: byref string — SELECT CASE on ##XBSystem (init 0).
       $$XBSysLinux=1 (from xut.dec, now correctly resolved). Since
       ##XBSystem=0 ≠ $$XBSysLinux=1, CASE ELSE → "unix". This proves
       constant resolution works: the case label is 1, not 0. */
    char* os_name = (char*)0;
    xb_user_XstGetOSName(&os_name);
    check_s("XstGetOSName", os_name, "unix");

    /* XstGetConsoleGrid: byref integer — reads xb_shared_CONGRID (init 0) */
    long grid = -1;
    xb_user_XstGetConsoleGrid(&grid);
    check_i("XstGetConsoleGrid", grid, 0);

    /* XstVersion$: return value — calls VERSION$(0) → "6.4.5" */
    char* ver = xb_user_XstVersion();
    check_s("XstVersion$", ver, "6.4.5");

    /* XstGetEndianName: byref string (DECLARE @endian$). Return 0 proves body ran.
       The string output is written via pointer, but we only check the return. */
    { char* endian_buf = xb_str(""); intptr_t endian_ret = xb_user_XstGetEndianName(&endian_buf); check_i("XstGetEndianName(ret)", endian_ret, 0); }

    /* XstGetCPUName: byref string (DECLARE @cpu$). Returns 0. */
    { char* cpu_buf = xb_str(""); intptr_t cpu_ret = xb_user_XstGetCPUName(&cpu_buf); check_i("XstGetCPUName(ret)", cpu_ret, 0); }
    /* XstGetApplicationEnvironment: byref int+int — reads ##STANDALONE (init 0),
       sets reserved=$$FALSE (0). Called with @ inside XstGetProgramFileName$. */
    long standalone = -1, reserved = -1;
    intptr_t env_ret = xb_user_XstGetApplicationEnvironment(&standalone, &reserved);
    check_i("XstGetAppEnv(ret)", env_ret, 0);
    check_i("XstGetAppEnv(standalone)", standalone, 0);
    check_i("XstGetAppEnv(reserved)", reserved, 0);
    /* XstExceptionToSystemException: byref int — maps XBasic exceptions to
       POSIX signals. Constants now resolved from xst.x ($$Exception*) and
       clib.dec ($$SIG*). Tests SELECT CASE with correctly resolved labels
       and assignments. */
    long sig;
    xb_user_XstExceptionToSystemException(1, &sig);  /* ExceptionSegmentViolation → SIGSEGV(11) */
    check_i("ExcToSys(SegViol)", sig, 11);
    xb_user_XstExceptionToSystemException(4, &sig);  /* ExceptionBreakKey → SIGINT(2) */
    check_i("ExcToSys(BreakKey)", sig, 2);
    xb_user_XstExceptionToSystemException(7, &sig);  /* ExceptionDivideByZero → SIGFPE(8) */
    check_i("ExcToSys(DivByZero)", sig, 8);
    xb_user_XstExceptionToSystemException(12, &sig); /* ExceptionInvalidInstruction → SIGILL(4) */
    check_i("ExcToSys(InvalidInstr)", sig, 4);
    xb_user_XstExceptionToSystemException(14, &sig); /* ExceptionStackOverflow → SIGSEGV(11) */
    check_i("ExcToSys(StackOverflow)", sig, 11);
    xb_user_XstExceptionToSystemException(99, &sig); /* CASE ELSE → SIGSEGV(11) */
    check_i("ExcToSys(unknown)", sig, 11);
    /* XstSystemExceptionToException: byref int — maps POSIX signals to
       XBasic exceptions (reverse of XstExceptionToSystemException).
       Never called inside xst.x; DECLARE @ markers mark exception as byref. */
    long exc;
    xb_user_XstSystemExceptionToException(0, &exc);   /* SIGNONE → ExceptionNone(0) */
    check_i("SysExcToExc(SIGNONE)", exc, 0);
    xb_user_XstSystemExceptionToException(1, &exc);   /* SIGHUP → ExceptionUnknown(17) */
    check_i("SysExcToExc(SIGHUP)", exc, 17);
    xb_user_XstSystemExceptionToException(2, &exc);   /* SIGINT → ExceptionBreakKey(4) */
    check_i("SysExcToExc(SIGINT)", exc, 4);
    xb_user_XstSystemExceptionToException(4, &exc);   /* SIGILL → ExceptionInvalidInstruction(12) */
    check_i("SysExcToExc(SIGILL)", exc, 12);
    xb_user_XstSystemExceptionToException(5, &exc);   /* SIGTRAP → ExceptionBreakpoint(3) */
    check_i("SysExcToExc(SIGTRAP)", exc, 3);
    xb_user_XstSystemExceptionToException(6, &exc);   /* SIGABRT → ExceptionBreakKey(4) */
    check_i("SysExcToExc(SIGABRT)", exc, 4);
    xb_user_XstSystemExceptionToException(7, &exc);   /* SIGBUS → ExceptionAlignment(5) */
    check_i("SysExcToExc(SIGBUS)", exc, 5);
    xb_user_XstSystemExceptionToException(8, &exc);   /* SIGFPE → ExceptionInvalidOperation(8) */
    check_i("SysExcToExc(SIGFPE)", exc, 8);
    xb_user_XstSystemExceptionToException(11, &exc);  /* SIGSEGV → ExceptionSegmentViolation(1) */
    check_i("SysExcToExc(SIGSEGV)", exc, 1);
    xb_user_XstSystemExceptionToException(14, &exc);  /* SIGALRM → ExceptionTimer(16) */
    check_i("SysExcToExc(SIGALRM)", exc, 16);
    xb_user_XstSystemExceptionToException(16, &exc);  /* SIGSTKFLT → ExceptionStackOverflow(14) */
    check_i("SysExcToExc(SIGSTKFLT)", exc, 14);
    xb_user_XstSystemExceptionToException(26, &exc);  /* SIGVTALRM → ExceptionTimer(16) */
    check_i("SysExcToExc(SIGVTALRM)", exc, 16);
    xb_user_XstSystemExceptionToException(99, &exc);  /* CASE ELSE → ExceptionUnknown(17) */
    check_i("SysExcToExc(unknown)", exc, 17);
    /* XstSystemErrorToError: byref int — upper=UBOUND(#OSERROR$[])=-1.
       sysError=0: 0 > -1 → error = (24<<8)|3 = 6147.
       sysError=5: 5 > -1 → error = 6147. */
    long xerr;
    xb_user_XstSystemErrorToError(0, &xerr);
    check_i("SysErrToErr(0)", xerr, 6147);
    xb_user_XstSystemErrorToError(5, &xerr);
    check_i("SysErrToErr(5)", xerr, 6147);
    /* XstGetSystemTime: byref int — all time fields init 0 → msec=0. */
    long msec = -1;
    xb_user_XstGetSystemTime(&msec);
    check_i("XstGetSystemTime", msec, 0);
    /* DeltaTimeZone: byref int — gtime=ltime=0 → delta=0. */
    long tz_delta = -999;
    xb_user_DeltaTimeZone(&tz_delta);
    check_i("DeltaTimeZone", tz_delta, 0);
    /* XstGetDateAndTime: 8 byref ints — all time_tm fields init 0.
       year=0+1900=1900, month=0+1=1, rest=0. */
    long year=-1, month=-1, day=-1, weekDay=-1, hour=-1, minute=-1, second=-1, nanos=-1;
    xb_user_XstGetDateAndTime(&year, &month, &day, &weekDay, &hour, &minute, &second, &nanos);
    check_i("XstGetDateAndTime(year)", year, 1900);
    check_i("XstGetDateAndTime(month)", month, 1);
    check_i("XstGetDateAndTime(day)", day, 0);
    check_i("XstGetDateAndTime(nanos)", nanos, 0);
    /* XstFileTimeToDateAndTime: int64 arithmetic path test.
       gmtime() not called (emitted as 0), so time fields stay 0.
       filetime=0: time<0 → time=0, secs=0, nanos=0.
       filetime=Windows epoch: time=0, secs=0, nanos=0.
       filetime=epoch+10000500: time=10000500, secs=1, year=1900 (gmtime not called). */
    {
        long ft_y=-1, ft_mo=-1, ft_d=-1, ft_wd=-1, ft_h=-1, ft_mi=-1, ft_s=-1, ft_ns=-1;
        xb_user_XstFileTimeToDateAndTime(0, &ft_y, &ft_mo, &ft_d, &ft_wd, &ft_h, &ft_mi, &ft_s, &ft_ns);
        check_i("FileTimeToDate(0) year", ft_y, 1900);
        check_i("FileTimeToDate(0) nanos", ft_ns, 0);
    }
    {
        long ft_y=-1, ft_mo=-1, ft_d=-1, ft_wd=-1, ft_h=-1, ft_mi=-1, ft_s=-1, ft_ns=-1;
        xb_user_XstFileTimeToDateAndTime(116444736000000000LL, &ft_y, &ft_mo, &ft_d, &ft_wd, &ft_h, &ft_mi, &ft_s, &ft_ns);
        check_i("FileTimeToDate(epoch) year", ft_y, 1900);
        check_i("FileTimeToDate(epoch) nanos", ft_ns, 0);
    }
    {
        long ft_y=-1, ft_mo=-1, ft_d=-1, ft_wd=-1, ft_h=-1, ft_mi=-1, ft_s=-1, ft_ns=-1;
        xb_user_XstFileTimeToDateAndTime(11644473601000500LL, &ft_y, &ft_mo, &ft_d, &ft_wd, &ft_h, &ft_mi, &ft_s, &ft_ns);
        check_i("FileTimeToDate(epoch+1s) year", ft_y, 1900);
    }
    /* XstGetOSVersionName: byref string (DECLARE @name$) — return 0 proves body ran. */
    { char* osver_buf = xb_str(""); intptr_t osver_ret = xb_user_XstGetOSVersionName(&osver_buf); check_i("XstGetOSVersionName(ret)", osver_ret, 0); }
    /* XstNextField: extracts next whitespace-delimited field from source.
       index/done are byref (DECLARE @index,@done). Must use xb_str() for C literals. */
    { intptr_t idx=1, done=0; char* nf1 = xb_user_XstNextField(xb_str("hello world"), &idx, &done); check_s("XstNextField(hello world,1)", nf1, "hello"); }
    { intptr_t idx=7, done=0; char* nf2 = xb_user_XstNextField(xb_str("hello world"), &idx, &done); check_s("XstNextField(hello world,7)", nf2, "world"); }
    { intptr_t idx=1, done=0; char* nf3 = xb_user_XstNextField(xb_str("  hello  "), &idx, &done); check_s("XstNextField(spaces,1)", nf3, "hello"); }
    { intptr_t idx=1, done=0; char* nf4 = xb_user_XstNextField(xb_str(""), &idx, &done); check_s("XstNextField(empty,1)", nf4, ""); }
    /* XstNextLine: extracts next line from newline-delimited string.
       index/done are byref (DECLARE @index,@done). */
    { intptr_t idx=1, done=0; char* nl1 = xb_user_XstNextLine(xb_str("line1\nline2\n"), &idx, &done); check_s("XstNextLine(2lines,1)", nl1, "line1"); }
    { intptr_t idx=7, done=0; char* nl2 = xb_user_XstNextLine(xb_str("line1\nline2\n"), &idx, &done); check_s("XstNextLine(2lines,7)", nl2, "line2"); }
    { intptr_t idx=1, done=0; char* nl3 = xb_user_XstNextLine(xb_str("hello"), &idx, &done); check_s("XstNextLine(noNL,1)", nl3, "hello"); }
    { intptr_t idx=1, done=0; char* nl4 = xb_user_XstNextLine(xb_str(""), &idx, &done); check_s("XstNextLine(empty,1)", nl4, ""); }
    /* XstMergeStrings: insert/replace in string.
       MID$(string,1,start-1) + add + MID$(string,start+replace) */
    char* ms1 = xb_user_XstMergeStrings(xb_str("hello"), xb_str("XYZ"), 2, 2);
    check_s("XstMergeStrings(hello,XYZ,2,2)", ms1, "hXYZlo");
    char* ms2 = xb_user_XstMergeStrings(xb_str("abc"), xb_str("D"), 1, 0);
    check_s("XstMergeStrings(abc,D,1,0)", ms2, "Dabc");
    char* ms3 = xb_user_XstMergeStrings(xb_str("abc"), xb_str("D"), 4, 0);
    check_s("XstMergeStrings(abc,D,4,0)", ms3, "abcD");
    /* XstParse: extracts n-th field from delimited string.
       Uses XstTally to count delimiters, then instr3 to find positions.
       Empty delimiter defaults to " ". n=0 defaults to 1. */
    char* xp1 = xb_user_XstParse(xb_str("a,b,c"), xb_str(","), 1);
    check_s("XstParse(a,b,c /, 1)", xp1, "a");
    char* xp2 = xb_user_XstParse(xb_str("a,b,c"), xb_str(","), 2);
    check_s("XstParse(a,b,c /, 2)", xp2, "b");
    char* xp3 = xb_user_XstParse(xb_str("a,b,c"), xb_str(","), 3);
    check_s("XstParse(a,b,c /, 3)", xp3, "c");
    char* xp4 = xb_user_XstParse(xb_str("a,b,c"), xb_str(","), 4);
    check_s("XstParse(a,b,c /, 4)", xp4, "");
    char* xp5 = xb_user_XstParse(xb_str("hello world"), xb_str(" "), 1);
    check_s("XstParse(hello world sp,1)", xp5, "hello");
    char* xp6 = xb_user_XstParse(xb_str("hello world"), xb_str(" "), 2);
    check_s("XstParse(hello world sp,2)", xp6, "world");
    char* xp7 = xb_user_XstParse(xb_str("hello"), xb_str(","), 1);
    check_s("XstParse(hello /, 1)", xp7, "hello");
    char* xp8 = xb_user_XstParse(xb_str("hello"), xb_str(","), 2);
    check_s("XstParse(hello /, 2)", xp8, "");
    /* XstTally: counts occurrences of find$ in source$. Returns -1 for empty source. */
    check_i("XstTally(a,b,c /,)", xb_user_XstTally(xb_str("a,b,c"), xb_str(",")), 2);
    check_i("XstTally(hello sp)", xb_user_XstTally(xb_str("hello world"), xb_str(" ")), 1);
    check_i("XstTally(hello /,)", xb_user_XstTally(xb_str("hello"), xb_str(",")), 0);
    check_i("XstTally(empty /,)", xb_user_XstTally(xb_str(""), xb_str(",")), -1);
    check_i("XstTally(aaa a)", xb_user_XstTally(xb_str("aaa"), xb_str("a")), 3);
    /* XstParseWhitespace$: returns the wordNumber-th word. Calls InitProgram()
       to populate charsetNotWhiteSpace[]. Handles quoted strings as single words. */
    check_s("ParseWS(hello world,1)", xb_user_XstParseWhitespace(xb_str("hello world"), 1), "hello");
    check_s("ParseWS(hello world,2)", xb_user_XstParseWhitespace(xb_str("hello world"), 2), "world");
    check_s("ParseWS(hello world,3)", xb_user_XstParseWhitespace(xb_str("hello world"), 3), "");
    check_s("ParseWS(empty,1)", xb_user_XstParseWhitespace(xb_str(""), 1), "");
    check_s("ParseWS(word0=word1)", xb_user_XstParseWhitespace(xb_str("hello world"), 0), "hello");
    check_s("ParseWS(3words,2)", xb_user_XstParseWhitespace(xb_str("one two three"), 2), "two");
    /* XstBackStringToBinString$: converts \xHH, \n, \t escape sequences to binary.
       Calls InitProgram() to populate charset arrays. */
    check_s("Back2Bin(noplain)", xb_user_XstBackStringToBinString(xb_str("hello")), "hello");
    check_s("Back2Bin(\\x41)", xb_user_XstBackStringToBinString(xb_str("\\x41")), "A");
    check_s("Back2Bin(\\n)", xb_user_XstBackStringToBinString(xb_str("\\n")), "\n");
    check_s("Back2Bin(\\t)", xb_user_XstBackStringToBinString(xb_str("\\t")), "\t");
    check_s("Back2Bin(empty)", xb_user_XstBackStringToBinString(xb_str("")), "");
    check_s("Back2Bin(mixed)", xb_user_XstBackStringToBinString(xb_str("a\\x42c")), "aBc");
    /* XxxPathString: converts path separators. On Linux: \ (92) → / (47).
       Returns NULL for empty path (return 0), so skip that case. */
    char* ps1 = xb_user_XxxPathString(xb_str("a\\b\\c"));
    check_s("XxxPathString(a\\b\\c)", ps1, "a/b/c");
    char* ps2 = xb_user_XxxPathString(xb_str("a/b/c"));
    check_s("XxxPathString(a/b/c)", ps2, "a/b/c");
    char* ps3 = xb_user_XxxPathString(xb_str("C:\\dir\\file"));
    check_s("XxxPathString(C:\\dir\\file)", ps3, "C:/dir/file");
    /* XstDecomposePathname: decomposes a pathname into components.
       $$PathSlash$ is now properly emitted as xb_const_PathSlash$ by the
       CEmitter (initialized via constructor). No manual init needed.
       "/dir/file.txt" → path="/dir", parent="dir", fileName="file.txt",
       file="file", extent=".txt" */
    {
        char* path = xb_str(""); char* parent = xb_str("");
        char* fileName = xb_str(""); char* file = xb_str(""); char* extent = xb_str("");
        xb_user_XstDecomposePathname(xb_str("/dir/file.txt"), &path, &parent, &fileName, &file, &extent);
        check_s("DecomposePath(/dir/file.txt) path", path, "/dir");
        check_s("DecomposePath(/dir/file.txt) parent", parent, "dir");
        check_s("DecomposePath(/dir/file.txt) fileName", fileName, "file.txt");
        check_s("DecomposePath(/dir/file.txt) file", file, "file");
        check_s("DecomposePath(/dir/file.txt) extent", extent, ".txt");
    }
    {
        char* path = xb_str(""); char* parent = xb_str("");
        char* fileName = xb_str(""); char* file = xb_str(""); char* extent = xb_str("");
        xb_user_XstDecomposePathname(xb_str("file.txt"), &path, &parent, &fileName, &file, &extent);
        check_s("DecomposePath(file.txt) path", path, "");
        check_s("DecomposePath(file.txt) fileName", fileName, "file.txt");
        check_s("DecomposePath(file.txt) file", file, "file");
        check_s("DecomposePath(file.txt) extent", extent, ".txt");
    }
    {
        char* path = xb_str(""); char* parent = xb_str("");
        char* fileName = xb_str(""); char* file = xb_str(""); char* extent = xb_str("");
        xb_user_XstDecomposePathname(xb_str("/a/b/c"), &path, &parent, &fileName, &file, &extent);
        check_s("DecomposePath(/a/b/c) path", path, "/a/b");
        check_s("DecomposePath(/a/b/c) parent", parent, "b");
        check_s("DecomposePath(/a/b/c) fileName", fileName, "c");
        check_s("DecomposePath(/a/b/c) file", file, "c");
        check_s("DecomposePath(/a/b/c) extent", extent, "");
    }
    /* XstMatchWild: pure wildcard matching function. Returns 1-based match
       position or 0 for no match. * matches any chars, ? matches one char.
       Case-insensitive when matchCase=0.
       NOTE: Avoid patterns where * matches a char that later fails to match
       the next filter char — XBasic source has a `DO LOOP` (infinite loop)
       bug in that branch (xst.x XstMatchWild CASE ELSE with match!=0). */
    check_i("XstMatchWild(hello,*,1,0)", xb_user_XstMatchWild(xb_str("hello"), xb_str("*"), 1, 0), 1);
    check_i("XstMatchWild(hello,h?llo,1,1)", xb_user_XstMatchWild(xb_str("hello"), xb_str("h?llo"), 1, 1), 1);
    check_i("XstMatchWild(hello,h*l,1,1)", xb_user_XstMatchWild(xb_str("hello"), xb_str("h*l"), 1, 1), 1);
    check_i("XstMatchWild(hello,world,1,1)", xb_user_XstMatchWild(xb_str("hello"), xb_str("world"), 1, 1), 0);
    check_i("XstMatchWild(HELLO,hello,1,0)", xb_user_XstMatchWild(xb_str("HELLO"), xb_str("hello"), 1, 0), 1);
    check_i("XstMatchWild(HELLO,hello,1,1)", xb_user_XstMatchWild(xb_str("HELLO"), xb_str("hello"), 1, 1), 0);
    check_i("XstMatchWild(hello,h*o,1,1)", xb_user_XstMatchWild(xb_str("hello"), xb_str("h*o"), 1, 1), 1);
    check_i("XstMatchWild(hello,*x,1,1)", xb_user_XstMatchWild(xb_str("hello"), xb_str("*x"), 1, 1), 0);
    check_i("XstMatchWild(abc,?b?,1,1)", xb_user_XstMatchWild(xb_str("abc"), xb_str("?b?"), 1, 1), 2);
    check_i("XstMatchWild(ab,?b?,1,1)", xb_user_XstMatchWild(xb_str("ab"), xb_str("?b?"), 1, 1), 0);
    /* XstErrorNumberToName: byref string output. With InitProgram called above,
       errorObject$[]/errorNature$[] arrays are populated. error=0 → "NoError",
       error=(1<<8)|0=256 → "Data". This tests the CEMITTER-S-SUFFIX-BYREF fix:
       copy-out now reads from xb_str_error_s (the body's local), not xb_str_error
       (the copy-in local). Enhanced checks at ErrName(0)/ErrName(769) below test
       the same function with different error codes. */
    {
        char* err_name = xb_str("");
        intptr_t err_ret = xb_user_XstErrorNumberToName(0, &err_name);
        check_s("XstErrorNumberToName(0)", err_name, "NoError");
        check_i("XstErrorNumberToName(0,ret)", err_ret, 0);
    }
    {
        char* err_name = xb_str("");
        intptr_t err_ret = xb_user_XstErrorNumberToName(0x0100, &err_name);
        check_s("XstErrorNumberToName(256)", err_name, "Data");
        check_i("XstErrorNumberToName(256,ret)", err_ret, 0);
    }
    /* XstSetException: sets ##EXCEPTION SharedName. Verify the weak global
       xb_shared_EXCEPTION is updated from the function body. */
    xb_user_XstSetException(42);
    check_i("XstSetException(42)", xb_shared_EXCEPTION, 42);
    xb_user_XstSetException(0);
    check_i("XstSetException(0)", xb_shared_EXCEPTION, 0);
    /* XstGetException: byref int — reads ##EXCEPTION set by XstSetException.
       Round-trip: set 99, get 99, set 0, get 0. */
    xb_user_XstSetException(99);
    { long exc_val = -1; xb_user_XstGetException(&exc_val); check_i("XstGetException(99)", exc_val, 99); }
    xb_user_XstSetException(0);
    { long exc_val = -1; xb_user_XstGetException(&exc_val); check_i("XstGetException(0)", exc_val, 0); }
    /* XstSetPrintTab: sets ##TABSAT SharedName, clamped to >= 0. */
    xb_user_XstSetPrintTab(80);
    check_i("XstSetPrintTab(80)", xb_shared_TABSAT, 80);
    xb_user_XstSetPrintTab(-5);
    check_i("XstSetPrintTab(-5)", xb_shared_TABSAT, 0);
    /* XstSetExceptionFunction: sets SHARED exceptionFunction.
       Requires the SHARED comma fix (SHARED exceptionFunction is a
       single-var declaration, but the fix ensures it's registered). */
    xb_user_XstSetExceptionFunction(1234);
    check_i("XstSetExceptionFunction(1234)", xb_shared_exceptionFunction, 1234);
    /* XstGetExceptionFunction: byref int — reads SHARED exceptionFunction
       set by XstSetExceptionFunction. Round-trip verification. */
    { long func_val = -1; xb_user_XstGetExceptionFunction(&func_val); check_i("XstGetExceptionFunction", func_val, 1234); }
    /* XstSetNewline: sets sysSaveNewline/sysPasteNewline via SHARED comma
       declaration (SHARED sysSaveNewline, sysPasteNewline). ##WHOMASK=0
       by default, so the sys path is taken. $$NewlineDefault = 1. */
    xb_user_XstSetNewline(1, 2);
    check_i("XstSetNewline(1,2) save", xb_shared_sysSaveNewline, 1);
    check_i("XstSetNewline(1,2) paste", xb_shared_sysPasteNewline, 2);
    xb_user_XstSetNewline(0, 0);
    check_i("XstSetNewline(0,0) save", xb_shared_sysSaveNewline, 1);
    check_i("XstSetNewline(0,0) paste", xb_shared_sysPasteNewline, 1);
    xb_user_XstSetNewline(2, 1);
    check_i("XstSetNewline(2,1) save", xb_shared_sysSaveNewline, 2);
    check_i("XstSetNewline(2,1) paste", xb_shared_sysPasteNewline, 1);
    /* XstGetNewline: byref int+int — reads back the SHARED state set by
       XstSetNewline. Verifies SHARED state is shared between functions.
       After XstSetNewline(2,1) above, sysSaveNewline=2, sysPasteNewline=1. */
    {
        long g_save = -1, g_paste = -1;
        xb_user_XstGetNewline(&g_save, &g_paste);
        check_i("XstGetNewline save", g_save, 2);
        check_i("XstGetNewline paste", g_paste, 1);
    }
    /* Reset to defaults and verify default behavior */
    xb_user_XstSetNewline(0, 0);
    {
        long g_save = -1, g_paste = -1;
        xb_user_XstGetNewline(&g_save, &g_paste);
        check_i("XstGetNewline default save", g_save, 1);
        check_i("XstGetNewline default paste", g_paste, 1);
    }
    /* XstRandomRange: byval, RETURN. n1=n2 short-circuits before XstRandom()
       (which uses GOSUB + SHARED). Tests IF n1=n2 THEN RETURN n1 path. */
    check_i("XstRandomRange(5,5)", xb_user_XstRandomRange(5, 5), 5);
    check_i("XstRandomRange(100,100)", xb_user_XstRandomRange(100, 100), 100);
    /* XstBinWrite: byval, RETURN. fileNumber<1 or ==2 returns -1 before
       XxxWriteFile. Tests || short-circuit in IF condition. */
    check_i("XstBinWrite(0,0,0)", xb_user_XstBinWrite(0, 0, 0), -1);
    check_i("XstBinWrite(2,0,0)", xb_user_XstBinWrite(2, 0, 0), -1);
    /* XstKillTask: byval, RETURN. taskNum<1 returns -1 before GOSUB. */
    check_i("XstKillTask(0)", xb_user_XstKillTask(0), -1);
    /* XstGetTaskInfo: byref outputs (DECLARE @count,@msec,@func,@timer,@skips).
       UBOUND(task[])= -1 (uninit SHARED array), so taskNum=999 > -1 → returns 0.
       Tests SHARED array UBOUND read. Pass dummy vars for byref outputs. */
    { intptr_t c=0,m=0,f=0,t=0,s=0; check_i("XstGetTaskInfo(999)", xb_user_XstGetTaskInfo(999, &c, &m, &f, &t, &s), 0); }
    /* XstSetSystemError: byval, no RETURN. Calls xb_user_xb_seterrno (strong
       impl in harness overrides weak stub). Verify via xb_user_xb_geterrno. */
    xb_user_XstSetSystemError(42);
    check_i("XstSetSystemError(42)", xb_user_xb_geterrno(), 42);
    /* XstGetOSVersion: byref int+int (DECLARE @major,@minor).
       version=0x0400 → major=4, minor=0. */
    { intptr_t major=-1, minor=-1; xb_user_XstGetOSVersion(&major, &minor); check_i("XstGetOSVersion(major)", major, 4); check_i("XstGetOSVersion(minor)", minor, 0); }
    /* XstGetPrintTab: byref int (DECLARE @pixels). ##TABSAT init 0. */
    { intptr_t pixels=-1; xb_user_XstGetPrintTab(&pixels); check_i("XstGetPrintTab", pixels, 0); }
    /* XstGetSystemError: byref int (DECLARE @sysError). Reads xb_geterrno().
       After XstSetSystemError(42), errno should be 42. */
    { intptr_t err=-1; xb_user_XstGetSystemError(&err); check_i("XstGetSystemError", err, 42); }
    /* XstSetProgramName: byref string (DECLARE @program$). ##WHOMASK=0 → sys path.
       Writes xb_strdup(prog$) to xb_shared_sysProgram. */
    { char* prog = xb_str("MyApp"); xb_user_XstSetProgramName(&prog); }
    check_s("XstSetProgramName(MyApp)", xb_shared_sysProgram, "MyApp");
    /* XstGetProgramName: byref string — reads sysProgram$ set by
       XstSetProgramName. ##WHOMASK=0 → sys path. Round-trip verification. */
    { char* prog = (char*)0; xb_user_XstGetProgramName(&prog); check_s("XstGetProgramName", prog, "MyApp"); }
    /* --- InitProgram-dependent tests (SHARED array reads) --- */
    /* InitProgram populates exception$[] and sysException$[] SHARED arrays.
       After calling it, XstExceptionNumberToName and friends can read the
       populated arrays. This unblocks functions previously blocked by
       "SHARED array init" — the arrays are now DIM'd and filled by
       InitProgram's function body (not GOSUB). */
    xb_user_InitProgram();
    /* XstExceptionNumberToName: reads exception$[exception] from SHARED array.
       Values from xst.x InitProgram: ExceptionNone=0→"$$ExceptionNone",
       ExceptionSegmentViolation=1→"$$ExceptionSegmentViolation",
       ExceptionBreakpoint=3→"$$ExceptionBreakpoint",
       ExceptionInvalidOperation=8→"$$ExceptionInvalidOperation",
       ExceptionUnknown=17→"$$ExceptionUnknown". */
    { char* name=(char*)0; xb_user_XstExceptionNumberToName(0, &name); check_s("ExcName(0)", name, "$$ExceptionNone"); }
    { char* name=(char*)0; xb_user_XstExceptionNumberToName(1, &name); check_s("ExcName(1)", name, "$$ExceptionSegmentViolation"); }
    { char* name=(char*)0; xb_user_XstExceptionNumberToName(3, &name); check_s("ExcName(3)", name, "$$ExceptionBreakpoint"); }
    { char* name=(char*)0; xb_user_XstExceptionNumberToName(8, &name); check_s("ExcName(8)", name, "$$ExceptionInvalidOperation"); }
    { char* name=(char*)0; xb_user_XstExceptionNumberToName(17, &name); check_s("ExcName(17)", name, "$$ExceptionUnknown"); }
    /* XstErrorNumberToName (enhanced with InitProgram): now reads populated
       errorObject$[]/errorNature$[] arrays. error=(object<<8)|nature.
       error=0 → "NoError", error=(3<<8)|1=769 → "File Busy",
       error=(24<<8)|3=6147 → "System Error". */
    { char* name=(char*)0; xb_user_XstErrorNumberToName(0, &name); check_s("ErrName(0)", name, "NoError"); }
    { char* name=(char*)0; xb_user_XstErrorNumberToName(769, &name); check_s("ErrName(769)", name, "File Busy"); }
    /* XstSystemErrorNumberToName: reads #OSERROR$[sysError] SHARED array
       populated by InitProgram. errno 2=ENOENT, 13=EACCES, 22=EINVAL. */
    { char* name=(char*)0; xb_user_XstSystemErrorNumberToName(2, &name); check_s("SysErrName(2)", name, "ENOENT"); }
    { char* name=(char*)0; xb_user_XstSystemErrorNumberToName(13, &name); check_s("SysErrName(13)", name, "EACCES"); }
    { char* name=(char*)0; xb_user_XstSystemErrorNumberToName(22, &name); check_s("SysErrName(22)", name, "EINVAL"); }
    /* XstSystemErrorToError: reads #OSTOXERROR[sysError] SHARED array.
       errno 2 (ENOENT) → (3<<8)|40 = 808 (File Nonexistent).
       errno 13 (EACCES) → (0<<8)|33 = 33 (Permission).
       errno 999 (out of range) → (24<<8)|3 = 6147 (System Error). */
    { intptr_t e=-1; xb_user_XstSystemErrorToError(2, &e); check_i("SysErrToErr(2)", e, 808); }
    { intptr_t e=-1; xb_user_XstSystemErrorToError(13, &e); check_i("SysErrToErr(13)", e, 33); }
    { intptr_t e=-1; xb_user_XstSystemErrorToError(999, &e); check_i("SysErrToErr(999)", e, 6147); }
    /* XstSystemExceptionNumberToName: reads sysException$[exception] from SHARED array.
       Values from xst.x InitProgram: SIGNONE=0→"$$SIGNONE",
       SIGHUP=1→"$$SIGHUP", SIGSEGV=11→"$$SIGSEGV". */
    { char* name=(char*)0; xb_user_XstSystemExceptionNumberToName(0, &name); check_s("SysExcName(0)", name, "$$SIGNONE"); }
    { char* name=(char*)0; xb_user_XstSystemExceptionNumberToName(1, &name); check_s("SysExcName(1)", name, "$$SIGHUP"); }
    { char* name=(char*)0; xb_user_XstSystemExceptionNumberToName(11, &name); check_s("SysExcName(11)", name, "$$SIGSEGV"); }
    /* XstExceptionToSystemException and XstSystemExceptionToException already
       tested above (SELECT CASE, no SHARED array needed). */
    printf("\n%d checks, %d failures\n", 157, fails);
    return fails;
}
"#).unwrap();

    let bin = tmp.join("xst_test");
    let link = Command::new(cc())
        .args([
            "-O0",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
        ])
        .arg(&harness)
        .arg(&xst_o)
        .arg("-lm")
        .arg("-o")
        .arg(&bin)
        .output()
        .expect("link");
    assert!(
        link.status.success(),
        "link failed:\n{}",
        String::from_utf8_lossy(&link.stderr)
    );

    let run = Command::new(&bin).output().expect("run");
    let stdout = String::from_utf8_lossy(&run.stdout);
    let stderr = String::from_utf8_lossy(&run.stderr);

    assert!(
        run.status.success(),
        "xst behavior test failed:\nstdout:\n{stdout}\nstderr:\n{stderr}"
    );

    // Verify each check passed.
    assert!(
        stdout.contains("0 failures"),
        "test reported failures:\n{stdout}"
    );

    // Verify specific expected outputs (proves legacy bodies ran, not stubs).
    assert!(
        stdout.contains("XstGetOSName"),
        "missing XstGetOSName check in output"
    );
    assert!(
        stdout.contains("XstGetConsoleGrid"),
        "missing XstGetConsoleGrid check in output"
    );
    assert!(
        stdout.contains("XstVersion$"),
        "missing XstVersion$ check in output"
    );
    assert!(
        stdout.contains("XstGetEndianName"),
        "missing XstGetEndianName check in output"
    );
    assert!(
        stdout.contains("XstGetCPUName"),
        "missing XstGetCPUName check in output"
    );
    assert!(
        stdout.contains("XstGetAppEnv"),
        "missing XstGetAppEnv check in output"
    );
    assert!(
        stdout.contains("ExcToSys(SegViol)"),
        "missing ExcToSys(SegViol) check in output"
    );
    assert!(
        stdout.contains("ExcToSys(DivByZero)"),
        "missing ExcToSys(DivByZero) check in output"
    );
    assert!(
        stdout.contains("ExcToSys(unknown)"),
        "missing ExcToSys(unknown) check in output"
    );
    assert!(
        stdout.contains("SysErrToErr(0)"),
        "missing SysErrToErr(0) check in output"
    );
    assert!(
        stdout.contains("XstGetSystemTime"),
        "missing XstGetSystemTime check in output"
    );
    assert!(
        stdout.contains("DeltaTimeZone"),
        "missing DeltaTimeZone check in output"
    );
    assert!(
        stdout.contains("XstGetDateAndTime(year)"),
        "missing XstGetDateAndTime(year) check in output"
    );
    assert!(
        stdout.contains("XstGetOSVersionName(ret)"),
        "missing XstGetOSVersionName(ret) check in output"
    );
    assert!(
        stdout.contains("XstNextField(hello world,1)"),
        "missing XstNextField check in output"
    );
    assert!(
        stdout.contains("XstSetException(42)"),
        "missing XstSetException check in output"
    );
    assert!(
        stdout.contains("XstSetPrintTab(80)"),
        "missing XstSetPrintTab check in output"
    );
    assert!(
        stdout.contains("XstSetExceptionFunction(1234)"),
        "missing XstSetExceptionFunction check in output"
    );
    assert!(
        stdout.contains("XstSetNewline(1,2)"),
        "missing XstSetNewline check in output"
    );
    assert!(
        stdout.contains("XstMergeStrings(hello,XYZ,2,2)"),
        "missing XstMergeStrings check in output"
    );
    assert!(
        stdout.contains("XstParse(a,b,c /, 1)"),
        "missing XstParse check in output"
    );
    assert!(
        stdout.contains("XstTally(a,b,c /,)"),
        "missing XstTally check in output"
    );
    assert!(
        stdout.contains("XstErrorNumberToName(0)"),
        "missing XstErrorNumberToName(0) check in output"
    );
    assert!(
        stdout.contains("XxxPathString(a\\b\\c)"),
        "missing XxxPathString check in output"
    );
    assert!(
        stdout.contains("XstMatchWild(hello,*,1,0)"),
        "missing XstMatchWild check in output"
    );
    assert!(
        stdout.contains("XstRandomRange(5,5)"),
        "missing XstRandomRange check in output"
    );
    assert!(
        stdout.contains("XstBinWrite(0,0,0)"),
        "missing XstBinWrite check in output"
    );
    assert!(
        stdout.contains("XstKillTask(0)"),
        "missing XstKillTask check in output"
    );
    assert!(
        stdout.contains("XstSetSystemError(42)"),
        "missing XstSetSystemError check in output"
    );
    assert!(
        stdout.contains("XstSetProgramName(MyApp)"),
        "missing XstSetProgramName check in output"
    );
    assert!(
        stdout.contains("ExcName(0)"),
        "missing ExcName(0) check in output"
    );
    assert!(
        stdout.contains("ExcName(1)"),
        "missing ExcName(1) check in output"
    );
    assert!(
        stdout.contains("SysExcName(0)"),
        "missing SysExcName(0) check in output"
    );
    assert!(
        stdout.contains("SysExcName(11)"),
        "missing SysExcName(11) check in output"
    );
    assert!(
        stdout.contains("ErrName(0)"),
        "missing ErrName(0) check in output"
    );
    assert!(
        stdout.contains("ErrName(769)"),
        "missing ErrName(769) check in output"
    );
    assert!(
        stdout.contains("SysErrName(2)"),
        "missing SysErrName(2) check in output"
    );
    assert!(
        stdout.contains("SysErrToErr(2)"),
        "missing SysErrToErr(2) check in output"
    );
    assert!(
        stdout.contains("ParseWS(hello world,1)"),
        "missing ParseWS(hello world,1) check in output"
    );
    assert!(
        stdout.contains("Back2Bin(\\x41)"),
        "missing Back2Bin(\\x41) check in output"
    );
}
