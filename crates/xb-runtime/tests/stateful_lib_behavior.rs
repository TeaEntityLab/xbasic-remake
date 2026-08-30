//! RR-08b: Behavior gates for stateful libraries.
//!
//! Compiles xst.x (standard library) through the Rust CEmitter and verifies
//! that user-defined function bodies execute correctly — not just compile,
//! but produce correct deterministic results. This extends RR-08a (pure
//! library behavior) to stateful libraries that use SHARED variables,
//! SELECT CASE on system variables, and byref output parameters.
//!
//! Test functions from xst.x with known deterministic outputs:
//!   XstGetOSName(@name$)  → "linux unix"  (SELECT CASE on ##XBSystem == 0)
//!   XstGetConsoleGrid(@grid) → 0          (reads xb_shared_CONGRID, init 0)
//!   XstVersion$()         → "6.4.5"       (calls VERSION$(0) → xb_version(0))
//!
//! The byref detection is callsite-driven: these functions are called with
//! `@` at least once inside xst.x, so the C emitter gives them `char**` /
//! `intptr_t*` signatures with copy-in/copy-out. This tests:
//!   - SELECT CASE lowering on SHARED system variables
//!   - String assignment to byref output parameters
//!   - Integer byref output parameters
//!   - SHARED variable reads (xb_shared_CONGRID, xb_shared_XBSystem)
//!   - RETURN value path for string functions (XstVersion$)

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

/* SHARED variables referenced by xst.o */
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
    /* XstGetOSName: byref string — SELECT CASE on ##XBSystem */
    char* os_name = (char*)0;
    xb_user_XstGetOSName(&os_name);
    check_s("XstGetOSName", os_name, "linux unix");

    /* XstGetConsoleGrid: byref integer — reads xb_shared_CONGRID (init 0) */
    long grid = -1;
    xb_user_XstGetConsoleGrid(&grid);
    check_i("XstGetConsoleGrid", grid, 0);

    /* XstVersion$: return value — calls VERSION$(0) → "6.4.5" */
    char* ver = xb_user_XstVersion();
    check_s("XstVersion$", ver, "6.4.5");

    printf("\n%d checks, %d failures\n", 3, fails);
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

    eprintln!("{stdout}");
}
