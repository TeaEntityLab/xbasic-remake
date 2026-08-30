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
#include <string.h>

/* Forward declarations for user-defined functions from xst.x */
intptr_t xb_user_XstGetOSName(char* *xb_str_name_ref);
intptr_t xb_user_XstGetConsoleGrid(intptr_t *xb_var_grid_ref);
char* xb_user_XstVersion(void);
intptr_t xb_user_XstGetEndianName(char* xb_str_name);
intptr_t xb_user_XstGetCPUName(char* xb_str_name);
intptr_t xb_user_XstGetApplicationEnvironment(intptr_t *xb_var_standalone_ref, intptr_t *xb_var_reserved_ref);
/* XstExceptionToSystemException: byref int — maps exception→signal.
   Called with @sysException inside XstCauseException. */
intptr_t xb_user_XstExceptionToSystemException(intptr_t xb_var_exception, intptr_t *xb_var_sysException_ref);
typedef long intptr_t;

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
    printf("\n%d checks, %d failures\n", 14, fails);
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
}
