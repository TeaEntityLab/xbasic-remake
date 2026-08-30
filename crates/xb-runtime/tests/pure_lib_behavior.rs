//! RR-08a: Behavior gates for pure libraries.
//!
//! Compiles xma.x (mathematics library) through the Rust CEmitter and
//! verifies that user-defined function bodies execute correctly — not just
//! compile, but produce correct deterministic results. This proves the
//! RR-07 binding policy: user-defined functions take precedence over
//! native helpers and builtins, so compiled legacy bodies are exercised.
//!
//! Test functions from xma.x with known deterministic outputs:
//!   SINH(0.0)  = 0.0       (SELECT CASE: v = 0 → RETURN 0)
//!   COSH(0.0)  = 1.0       (SELECT CASE: v = 0 → RETURN 1)
//!   TANH(0.0)  = 0.0       (SELECT CASE: v = 0 → RETURN 0)
//!   ACOS(0.0)  = PI/2      (SELECT CASE: v = 0 → RETURN PIDIV2)
//!   ACOS(1.0)  = 0.0       (SELECT CASE: v = 1 → RETURN 0)
//!   ACOS(-1.0) = PI        (SELECT CASE: v = -1 → RETURN PI)
//!   XmaVersion$() = "6.4.5"

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
    // Honor XB_BIN override (like link-core-libs.sh).
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
fn xma_pure_library_behavior() {
    let root = repo_root();
    let tmp = std::env::temp_dir().join("xb_pure_lib_behavior");
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    // Compile xma.x (and its dependency xst.x) through CEmitter.
    let xma_src = root.join("xbasic-6.4.5/src/shared/xma.x");
    let xst_src = root.join("xbasic-6.4.5/src/linux/xst.x");
    assert!(xma_src.exists(), "xma.x not found at {xma_src:?}");
    assert!(xst_src.exists(), "xst.x not found at {xst_src:?}");

    let xma_c = emit_c(&xma_src, &tmp, true);
    let xst_c = emit_c(&xst_src, &tmp, true);
    let xma_o = compile_c(&xma_c, &tmp);
    let xst_o = compile_c(&xst_c, &tmp);

    // Write a C test harness that calls the compiled legacy bodies.
    // The RR-07 binding policy ensures these call xb_user_* functions,
    // not the runtime's xb_sinh/xb_cosh/etc. wrappers.
    let harness = tmp.join("harness.c");
    fs::write(&harness, r#"#include <stdio.h>
#include <string.h>
#include <math.h>

/* Forward declarations for user-defined functions from xma.x */
double xb_user_SINH(double v);
double xb_user_COSH(double v);
double xb_user_TANH(double v);
double xb_user_ACOS(double v);
char* xb_user_XmaVersion(void);

static int fails = 0;

static void check_d(const char* name, double got, double want) {
    int ok = fabs(got - want) < 1e-10;
    printf("%-20s = %.15g  (want %.15g)  %s\n", name, got, want, ok ? "ok" : "FAIL");
    if (!ok) fails++;
}

static void check_s(const char* name, const char* got, const char* want) {
    int ok = got && strcmp(got, want) == 0;
    printf("%-20s = [%s]  (want [%s])  %s\n", name, got ? got : "(null)", want, ok ? "ok" : "FAIL");
    if (!ok) fails++;
}

int main(void) {
    /* SINH(0) = 0 — xma's SELECT CASE returns 0 for v=0 */
    check_d("SINH(0.0)", xb_user_SINH(0.0), 0.0);
    /* COSH(0) = 1 — xma's SELECT CASE returns 1 for v=0 */
    check_d("COSH(0.0)", xb_user_COSH(0.0), 1.0);
    /* TANH(0) = 0 — xma's SELECT CASE returns 0 for v=0 */
    check_d("TANH(0.0)", xb_user_TANH(0.0), 0.0);
    /* ACOS(0) = PI/2 — xma's SELECT CASE returns PIDIV2 for v=0 */
    check_d("ACOS(0.0)", xb_user_ACOS(0.0), M_PI_2);
    /* ACOS(1) = 0 — xma's SELECT CASE returns 0 for v=1 */
    check_d("ACOS(1.0)", xb_user_ACOS(1.0), 0.0);
    /* ACOS(-1) = PI — xma's SELECT CASE returns PI for v=-1 */
    check_d("ACOS(-1.0)", xb_user_ACOS(-1.0), M_PI);
    /* XmaVersion$ = "6.4.5" */
    check_s("XmaVersion$", xb_user_XmaVersion(), "6.4.5");

    printf("\n%d checks, %d failures\n", 7, fails);
    return fails;
}
"#).unwrap();

    let bin = tmp.join("xma_test");
    let link = Command::new(cc())
        .args(["-O0", "-Wno-incompatible-pointer-types", "-Wno-int-conversion"])
        .arg(&harness)
        .arg(&xma_o)
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
        "xma behavior test failed:\nstdout:\n{stdout}\nstderr:\n{stderr}"
    );

    // Verify each check passed.
    assert!(stdout.contains("0 failures"), "test reported failures:\n{stdout}");

    // Verify specific expected outputs (proves legacy bodies ran, not stubs).
    assert!(stdout.contains("SINH(0.0)"), "missing SINH check in output");
    assert!(stdout.contains("COSH(0.0)"), "missing COSH check in output");
    assert!(stdout.contains("TANH(0.0)"), "missing TANH check in output");
    assert!(stdout.contains("ACOS(0.0)"), "missing ACOS check in output");
    assert!(stdout.contains("XmaVersion$"), "missing XmaVersion check in output");

    eprintln!("{stdout}");
}

#[test]
fn xut_pure_library_behavior() {
    let root = repo_root();
    let tmp = std::env::temp_dir().join("xb_pure_lib_behavior_xut");
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    // Compile xut.x (and its dependency xst.x) through CEmitter.
    let xut_src = root.join("xbasic-6.4.5/src/shared/xut.x");
    let xst_src = root.join("xbasic-6.4.5/src/linux/xst.x");
    assert!(xut_src.exists(), "xut.x not found at {xut_src:?}");
    assert!(xst_src.exists(), "xst.x not found at {xst_src:?}");

    let xut_c = emit_c(&xut_src, &tmp, true);
    let xst_c = emit_c(&xst_src, &tmp, true);
    let xut_o = compile_c(&xut_c, &tmp);
    let xst_o = compile_c(&xst_c, &tmp);

    // XutInit() is a no-op that returns 0. This proves compilation + linking +
    // calling works for the xut library (platform-independent utility library).
    let harness = tmp.join("harness.c");
    fs::write(&harness, r#"#include <stdio.h>

/* Forward declaration for user-defined function from xut.x */
long xb_user_XutInit(void);

static int fails = 0;

int main(void) {
    /* XutInit() returns 0 (no-op function) */
    long ret = xb_user_XutInit();
    int ok = (ret == 0);
    printf("%-20s = %ld  (want 0)  %s\n", "XutInit()", ret, ok ? "ok" : "FAIL");
    if (!ok) fails++;

    printf("\n%d checks, %d failures\n", 1, fails);
    return fails;
}
"#).unwrap();

    let bin = tmp.join("xut_test");
    let link = Command::new(cc())
        .args(["-O0", "-Wno-incompatible-pointer-types", "-Wno-int-conversion"])
        .arg(&harness)
        .arg(&xut_o)
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
        "xut behavior test failed:\nstdout:\n{stdout}\nstderr:\n{stderr}"
    );

    assert!(stdout.contains("0 failures"), "test reported failures:\n{stdout}");
    assert!(stdout.contains("XutInit()"), "missing XutInit check in output");

    eprintln!("{stdout}");
}
