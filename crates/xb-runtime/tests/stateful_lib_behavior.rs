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

use std::process::Command;
use std::fs;
use std::path::PathBuf;

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
    std::env::var("CC").unwrap_or_else(|_| "cc".to_string()).leak()
}

/// Compile a single .x library through the Rust CEmitter into a .c file.
fn emit_c(lib_path: &std::path::Path, out: &std::path::Path, weak: bool) -> PathBuf {
    let stem = lib_path.file_stem().unwrap().to_str().unwrap();
    let c_file = out.join(format!("{stem}.c"));
    let mut cmd = Command::new(xb_bin());
    cmd.arg("--emit-c").arg(lib_path);
    if weak {
        cmd.env("XB_WEAK_SYMBOLS", "1");
    }
    let output = cmd.output().expect("emit-c");
    assert!(
        output.status.success(),
        "emit-c failed for {lib_path:?}:\n{}",
        String::from_utf8_lossy(&output.stderr)
    );
    fs::write(&c_file, &output.stdout).unwrap();
    c_file
}

/// Compile a .c file to a .o object file.
fn compile_c(c_file: &std::path::Path, out: &std::path::Path) -> PathBuf {
    let stem = c_file.file_stem().unwrap().to_str().unwrap();
    let o_file = out.join(format!("{stem}.o"));
    let output = Command::new(cc())
        .args(["-O0", "-Wno-incompatible-pointer-types", "-Wno-int-conversion"])
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
    let xst_src = root.join("xbasic-6.4.5/src/linux/xst.x");
    assert!(xst_src.exists(), "xst.x not found at {xst_src:?}");

    let xst_c = emit_c(&xst_src, &tmp, true);
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
intptr_t xb_user_XstGetEndianName(char* xb_str_name);
intptr_t xb_user_XstGetCPUName(char* xb_str_name);
intptr_t xb_user_XstGetApplicationEnvironment(intptr_t *xb_var_standalone_ref, intptr_t *xb_var_reserved_ref);
/* XstExceptionToSystemException: byref int — maps exception→signal.
   Called with @sysException inside XstCauseException. */
intptr_t xb_user_XstExceptionToSystemException(intptr_t xb_var_exception, intptr_t *xb_var_sysException_ref);
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
/* XstGetOSVersionName: byval string — return 0 proves body ran.
   Would produce "4.0" if byref (xb_extu(0x0400,8,8)=4, xb_extu(0x0400,8,0)=0). */
intptr_t xb_user_XstGetOSVersionName(char* xb_str_name);
/* String functions: return char* — deterministic output for known inputs.
   index/done params are byval (never called with @ in xst.x), but the
   return value is the extracted/merged string. */
char* xb_user_XstNextField(char* xb_str_source, intptr_t xb_var_index, intptr_t xb_var_done);
char* xb_user_XstNextLine(char* xb_str_source, intptr_t xb_var_index, intptr_t xb_var_done);
char* xb_user_XstMergeStrings(char* xb_str_string, char* xb_str_add, intptr_t xb_var_start, intptr_t xb_var_replace);
/* XstParse: returns n-th field from delimited string. Pure string ops, no InitProgram().
   XstTally: counts delimiter occurrences in source. Returns -1 for empty source.
   XxxPathString: converts path separators (\ → / on Linux). Returns NULL for empty path. */
char* xb_user_XstParse(char* xb_str_source, char* xb_str_delimiter, intptr_t xb_var_n);
intptr_t xb_user_XstTally(char* xb_str_source, char* xb_str_find);
char* xb_user_XxxPathString(char* xb_str_path);
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

    /* XstGetEndianName: byval string (never called with @ in xst.x, so byval).
       The string output is lost (local copy), but the return value 0 proves
       the function body executed (sets name$ = "LittleEndian", returns 0). */
    char endian_buf[64] = {0};
    intptr_t endian_ret = xb_user_XstGetEndianName(endian_buf);
    check_i("XstGetEndianName(ret)", endian_ret, 0);

    /* XstGetCPUName: byval string. Returns 0. Body sets name$ = "80386". */
    char cpu_buf[64] = {0};
    intptr_t cpu_ret = xb_user_XstGetCPUName(cpu_buf);
    check_i("XstGetCPUName(ret)", cpu_ret, 0);
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
    /* XstGetOSVersionName: byval string — return 0 proves body ran. */
    char osver_buf[64] = {0};
    intptr_t osver_ret = xb_user_XstGetOSVersionName(osver_buf);
    check_i("XstGetOSVersionName(ret)", osver_ret, 0);
    /* XstNextField: extracts next whitespace-delimited field from source.
       Skips leading whitespace, extracts non-whitespace chars.
       Must use xb_str() to convert C literals to XBasic managed strings. */
    char* nf1 = xb_user_XstNextField(xb_str("hello world"), 1, 0);
    check_s("XstNextField(hello world,1)", nf1, "hello");
    char* nf2 = xb_user_XstNextField(xb_str("hello world"), 7, 0);
    check_s("XstNextField(hello world,7)", nf2, "world");
    char* nf3 = xb_user_XstNextField(xb_str("  hello  "), 1, 0);
    check_s("XstNextField(spaces,1)", nf3, "hello");
    char* nf4 = xb_user_XstNextField(xb_str(""), 1, 0);
    check_s("XstNextField(empty,1)", nf4, "");
    /* XstNextLine: extracts next line from newline-delimited string. */
    char* nl1 = xb_user_XstNextLine(xb_str("line1\nline2\n"), 1, 0);
    check_s("XstNextLine(2lines,1)", nl1, "line1");
    char* nl2 = xb_user_XstNextLine(xb_str("line1\nline2\n"), 7, 0);
    check_s("XstNextLine(2lines,7)", nl2, "line2");
    char* nl3 = xb_user_XstNextLine(xb_str("hello"), 1, 0);
    check_s("XstNextLine(noNL,1)", nl3, "hello");
    char* nl4 = xb_user_XstNextLine(xb_str(""), 1, 0);
    check_s("XstNextLine(empty,1)", nl4, "");
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
    /* XxxPathString: converts path separators. On Linux: \ (92) → / (47).
       Returns NULL for empty path (return 0), so skip that case. */
    char* ps1 = xb_user_XxxPathString(xb_str("a\\b\\c"));
    check_s("XxxPathString(a\\b\\c)", ps1, "a/b/c");
    char* ps2 = xb_user_XxxPathString(xb_str("a/b/c"));
    check_s("XxxPathString(a/b/c)", ps2, "a/b/c");
    char* ps3 = xb_user_XxxPathString(xb_str("C:\\dir\\file"));
    check_s("XxxPathString(C:\\dir\\file)", ps3, "C:/dir/file");
    printf("\n%d checks, %d failures\n", 51, fails);
    return fails;
}
"#).unwrap();

    let bin = tmp.join("xst_test");
    let link = Command::new(cc())
        .args(["-O0", "-Wno-incompatible-pointer-types", "-Wno-int-conversion"])
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
    assert!(stdout.contains("0 failures"), "test reported failures:\n{stdout}");

    // Verify specific expected outputs (proves legacy bodies ran, not stubs).
    assert!(stdout.contains("XstGetOSName"), "missing XstGetOSName check in output");
    assert!(stdout.contains("XstGetConsoleGrid"), "missing XstGetConsoleGrid check in output");
    assert!(stdout.contains("XstVersion$"), "missing XstVersion$ check in output");
    assert!(stdout.contains("XstGetEndianName"), "missing XstGetEndianName check in output");
    assert!(stdout.contains("XstGetCPUName"), "missing XstGetCPUName check in output");
    assert!(stdout.contains("XstGetAppEnv"), "missing XstGetAppEnv check in output");
    assert!(stdout.contains("ExcToSys(SegViol)"), "missing ExcToSys(SegViol) check in output");
    assert!(stdout.contains("ExcToSys(DivByZero)"), "missing ExcToSys(DivByZero) check in output");
    assert!(stdout.contains("ExcToSys(unknown)"), "missing ExcToSys(unknown) check in output");
    assert!(stdout.contains("SysErrToErr(0)"), "missing SysErrToErr(0) check in output");
    assert!(stdout.contains("XstGetSystemTime"), "missing XstGetSystemTime check in output");
    assert!(stdout.contains("DeltaTimeZone"), "missing DeltaTimeZone check in output");
    assert!(stdout.contains("XstGetDateAndTime(year)"), "missing XstGetDateAndTime(year) check in output");
    assert!(stdout.contains("XstGetOSVersionName(ret)"), "missing XstGetOSVersionName(ret) check in output");
    assert!(stdout.contains("XstNextField(hello world,1)"), "missing XstNextField check in output");
    assert!(stdout.contains("XstNextLine(2lines,1)"), "missing XstNextLine check in output");
    assert!(stdout.contains("XstMergeStrings(hello,XYZ,2,2)"), "missing XstMergeStrings check in output");
    assert!(stdout.contains("XstParse(a,b,c /, 1)"), "missing XstParse check in output");
    assert!(stdout.contains("XstTally(a,b,c /,)"), "missing XstTally check in output");
    assert!(stdout.contains("XxxPathString(a\\b\\c)"), "missing XxxPathString check in output");
}
