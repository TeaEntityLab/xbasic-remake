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
double xb_user_ASIN(double v);
double xb_user_ASINH(double v);
double xb_user_ATANH(double v);
double xb_user_LOG10(double v);
double xb_user_ACOSH(double v);
double xb_user_ACOT(double v);
double xb_user_ACOTH(double v);
double xb_user_ACSC(double v);
double xb_user_ACSCH(double v);
double xb_user_ASEC(double v);
double xb_user_ASECH(double v);
double xb_user_COTH(double v);
double xb_user_CSC(double a);
double xb_user_CSCH(double v);
double xb_user_SEC(double a);
double xb_user_SECH(double v);
double xb_user_LOG(double v);
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
    check_d("ACOS(-1.0)", xb_user_ACOS(-1.0), M_PI);
    /* XmaVersion$ = "6.4.5" */
    check_s("XmaVersion$", xb_user_XmaVersion(), "6.4.5");
    /* ASIN(0) = 0 — xma's SELECT CASE returns a*(1+a*a/6) for |a|<1e-5, so 0 → 0 */
    check_d("ASIN(0.0)", xb_user_ASIN(0.0), 0.0);
    /* ASIN(1) = PI/2 — full computation path: undeclared locals now inferred
       as DOUBLE from DOUBLE parameter `a` (CEmitter type inference fix).
       Previously blocked by intptr_t truncation; now works. */
    check_d("ASIN(1.0)", xb_user_ASIN(1.0), M_PI_2);
    /* ATANH(0) = 0 — xma's SELECT CASE returns v*(1+v*v/3) for |v|<1e-5, so 0 → 0 */
    check_d("ATANH(0.0)", xb_user_ATANH(0.0), 0.0);
    /* LOG10(1) = 0 — xma's LOG returns 0 for v=1, LOG10 returns LOG(1)*LOG10E = 0 */
    check_d("LOG10(1.0)", xb_user_LOG10(1.0), 0.0);
    /* LOG10(10) = 1 — LOG's full path uses bit-field extraction (`upper {11, 20}`)
       to get the IEEE 754 exponent. The CEmitter now lowers this to
       `xb_extu(upper, 11, 20)` (previously emitted as `exp = 0`). */
    check_d("LOG10(10.0)", xb_user_LOG10(10.0), 1.0);
    /* SINH(1) = 1.175... — full path via Expmo (Hart approximation), not the v=0 shortcut.
       Previously returned 0 because EXP was a zero-stub; now EXP maps to C's exp(). */
    check_d("SINH(1.0)", xb_user_SINH(1.0), 1.1752011936438014);
    /* COSH(1) = 1.543... — full path: (EXP(1)+EXP(-1))*0.5, now EXP works. */
    check_d("COSH(1.0)", xb_user_COSH(1.0), 1.5430806348152437);
    /* TANH(1) = 0.761... — full path: (EXP(1)-EXP(-1))/(EXP(1)+EXP(-1)), now EXP works. */
    check_d("TANH(1.0)", xb_user_TANH(1.0), 0.7615941559557649);
    /* ACOSH(1) = 0 — SELECT CASE: v=1 → RETURN 0 */
    check_d("ACOSH(1.0)", xb_user_ACOSH(1.0), 0.0);
    /* ACOSH(2) = 1.316... — full path: LOG(v + SQRT(v*v-1)), now SQRT/LOG work */
    check_d("ACOSH(2.0)", xb_user_ACOSH(2.0), 1.3169578969248166);
    /* ACOT(1) = PI/4 — full path: ATAN(1/v), now ATAN maps to C's atan() */
    check_d("ACOT(1.0)", xb_user_ACOT(1.0), M_PI_4);
    /* ACOTH(2) = 0.549... — full path: 0.5*LOG((v+1)/(v-1)), now LOG works */
    check_d("ACOTH(2.0)", xb_user_ACOTH(2.0), 0.5493061443340549);
    /* ACSC(2) = PI/6 — full path: ASIN(1/v), now ASIN works */
    check_d("ACSC(2.0)", xb_user_ACSC(2.0), M_PI / 6.0);
    /* ACSCH(1) = 0.881... — full path: ASINH(1/v), now ASINH works via SQRT/LOG */
    check_d("ACSCH(1.0)", xb_user_ACSCH(1.0), 0.8813735870195430);
    /* ASEC(2) = PI/3 — full path: PIDIV2 - ASIN(1/v), now ASIN works */
    check_d("ASEC(2.0)", xb_user_ASEC(2.0), M_PI / 3.0);
    /* ASECH(0.5) = 1.316... — full path: ACOSH(1/v), now ACOSH works via SQRT/LOG */
    check_d("ASECH(0.5)", xb_user_ASECH(0.5), 1.3169578969248166);
    /* COTH(2) = 1.037... — full path: (EXP(2)+EXP(-2))/(EXP(2)-EXP(-2)), now EXP works */
    check_d("COTH(2.0)", xb_user_COTH(2.0), 1.0373147207275482);
    /* CSC(PI/2) = 1 — full path: 1/SIN(PI/2), now SIN maps to C's sin() */
    check_d("CSC(PI/2)", xb_user_CSC(M_PI_2), 1.0);
    /* CSCH(1) = 0.850... — full path: 1/SINH(1), now SINH works */
    check_d("CSCH(1.0)", xb_user_CSCH(1.0), 0.8509181282393216);
    /* SEC(0) = 1 — full path: 1/COS(0), now COS maps to C's cos() */
    check_d("SEC(0.0)", xb_user_SEC(0.0), 1.0);
    /* SECH(0) = 1 — full path: 1/COSH(0), now COSH works */
    check_d("SECH(0.0)", xb_user_SECH(0.0), 1.0);
    /* LOG(1) = 0 — xma's LOG returns 0 for v=1 */
    check_d("LOG(1.0)", xb_user_LOG(1.0), 0.0);
    /* LOG(e) = 1 — xma's LOG full path: bit-field extraction + Log0 Hart approximation */
    check_d("LOG(M_E)", xb_user_LOG(M_E), 1.0);
    /* Non-trivial inputs exercising full EXP/SQRT/LOG paths */
    /* SINH(2) = 3.626... — (EXP(2)-EXP(-2))*0.5, full EXP path */
    check_d("SINH(2.0)", xb_user_SINH(2.0), 3.626860407847019);
    /* COSH(2) = 3.762... — (EXP(2)+EXP(-2))*0.5, full EXP path */
    check_d("COSH(2.0)", xb_user_COSH(2.0), 3.762195691083631);
    /* TANH(2) = 0.964... — (EXP(2)-EXP(-2))/(EXP(2)+EXP(-2)), full EXP path */
    check_d("TANH(2.0)", xb_user_TANH(2.0), 0.964027580075817);
    /* LOG(2) = 0.693... — xma's bit-field extraction + Log0 Hart approximation */
    check_d("LOG(2.0)", xb_user_LOG(2.0), 0.6931471805599453);
    /* LOG10(100) = 2 — LOG(100)*LOG10E, full LOG path */
    check_d("LOG10(100.0)", xb_user_LOG10(100.0), 2.0);
    /* ACOSH(3) = 1.762... — LOG(3+SQRT(3*3-1)), full LOG+SQRT path */
    check_d("ACOSH(3.0)", xb_user_ACOSH(3.0), 1.762747174039086);
    /* ASINH(2) = 1.443... — SIGN(2)*LOG(2+SQRT(4+1)), full LOG+SQRT path */
    check_d("ASINH(2.0)", xb_user_ASINH(2.0), 1.443635475178810);
    /* ATANH(0.5) = 0.549... — LOG((1+0.5)/(1-0.5))*0.5, full LOG path */
    check_d("ATANH(0.5)", xb_user_ATANH(0.5), 0.549306144334055);
    /* ASIN(0.5) = PI/6 — full ASIN computation path */
    check_d("ASIN(0.5)", xb_user_ASIN(0.5), M_PI / 6.0);
    /* ACOS(0.5) = PI/3 — PIDIV2 - ASIN(0.5) */
    check_d("ACOS(0.5)", xb_user_ACOS(0.5), M_PI / 3.0);

    printf("\n%d checks, %d failures\n", 40, fails);
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
    assert!(stdout.contains("ASIN(1.0)"), "missing ASIN(1.0) check in output");
    assert!(stdout.contains("ATANH(0.0)"), "missing ATANH check in output");
    assert!(stdout.contains("LOG10(10.0)"), "missing LOG10(10.0) check in output");
    assert!(stdout.contains("SINH(1.0)"), "missing SINH(1.0) check in output");
    assert!(stdout.contains("COSH(1.0)"), "missing COSH(1.0) check in output");
    assert!(stdout.contains("TANH(1.0)"), "missing TANH(1.0) check in output");
    assert!(stdout.contains("ACOSH(2.0)"), "missing ACOSH(2.0) check in output");
    assert!(stdout.contains("ACOT(1.0)"), "missing ACOT(1.0) check in output");
    assert!(stdout.contains("ACSCH(1.0)"), "missing ACSCH(1.0) check in output");
    assert!(stdout.contains("COTH(2.0)"), "missing COTH(2.0) check in output");
    assert!(stdout.contains("CSC(PI/2)"), "missing CSC(PI/2) check in output");
    assert!(stdout.contains("SEC(0.0)"), "missing SEC(0.0) check in output");
    assert!(stdout.contains("LOG(M_E)"), "missing LOG(M_E) check in output");
    assert!(stdout.contains("SINH(2.0)"), "missing SINH(2.0) check in output");
    assert!(stdout.contains("LOG(2.0)"), "missing LOG(2.0) check in output");
    assert!(stdout.contains("LOG10(100.0)"), "missing LOG10(100.0) check in output");
    assert!(stdout.contains("ACOSH(3.0)"), "missing ACOSH(3.0) check in output");
    assert!(stdout.contains("ASINH(2.0)"), "missing ASINH(2.0) check in output");
    assert!(stdout.contains("ATANH(0.5)"), "missing ATANH(0.5) check in output");
    assert!(stdout.contains("ASIN(0.5)"), "missing ASIN(0.5) check in output");
    assert!(stdout.contains("ACOS(0.5)"), "missing ACOS(0.5) check in output");
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

#[test]
fn xit_pure_library_behavior() {
    let root = repo_root();
    let tmp = std::env::temp_dir().join("xb_pure_lib_behavior_xit");
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    // Compile xit.x (and its dependency xst.x) through CEmitter.
    let xit_src = root.join("xbasic-6.4.5/src/linux/xit.x");
    let xst_src = root.join("xbasic-6.4.5/src/linux/xst.x");
    assert!(xit_src.exists(), "xit.x not found at {xit_src:?}");
    assert!(xst_src.exists(), "xst.x not found at {xst_src:?}");

    let xit_c = emit_c(&xit_src, &tmp, true);
    let xst_c = emit_c(&xst_src, &tmp, true);
    let xit_o = compile_c(&xit_c, &tmp);
    let xst_o = compile_c(&xst_c, &tmp);

    // XitVersion$() calls VERSION$(0) and returns "6.4.5".
    // Welcome() returns $$FALSE (0).
    let harness = tmp.join("harness.c");
    fs::write(&harness, r#"#include <stdio.h>
#include <string.h>

/* Forward declarations for user-defined functions from xit.x */
char* xb_user_XitVersion(void);
long xb_user_Welcome(void);

static int fails = 0;

static void check_s(const char* name, const char* got, const char* want) {
    int ok = got && strcmp(got, want) == 0;
    printf("%-20s = [%s]  (want [%s])  %s\n", name, got ? got : "(null)", want, ok ? "ok" : "FAIL");
    if (!ok) fails++;
}

int main(void) {
    /* XitVersion$() = "6.4.5" — calls VERSION$(0) */
    check_s("XitVersion$", xb_user_XitVersion(), "6.4.5");
    /* Welcome() = 0 — returns $$FALSE */
    long ret = xb_user_Welcome();
    int ok = (ret == 0);
    printf("%-20s = %ld  (want 0)  %s\n", "Welcome()", ret, ok ? "ok" : "FAIL");
    if (!ok) fails++;

    printf("\n%d checks, %d failures\n", 2, fails);
    return fails;
}
"#).unwrap();

    let bin = tmp.join("xit_test");
    let link = Command::new(cc())
        .args(["-O0", "-Wno-incompatible-pointer-types", "-Wno-int-conversion"])
        .arg(&harness)
        .arg(&xit_o)
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
        "xit behavior test failed:\nstdout:\n{stdout}\nstderr:\n{stderr}"
    );

    assert!(stdout.contains("0 failures"), "test reported failures:\n{stdout}");
    assert!(stdout.contains("XitVersion$"), "missing XitVersion$ check in output");
    assert!(stdout.contains("Welcome()"), "missing Welcome() check in output");
}

#[test]
fn xcm_pure_library_behavior() {
    let root = repo_root();
    let tmp = std::env::temp_dir().join("xb_pure_lib_behavior_xcm");
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    // Compile xcm.x (and its dependency xst.x) through CEmitter.
    // xcm has DCOMPLEX/SCOMPLEX composite-type functions that are blocked
    // (CEmitter emits composite params as intptr_t, not struct pointers).
    // Atan2 is a pure DOUBLE function that uses $$PIDIV2/$$PI constants from
    // xma.x — cross-file $$ constant resolution now works via import resolution
    // in the CLI. Atan2(0,1)=0, Atan2(1,1)=PI/4, Atan2(1,0)=PI/2.
    let xcm_src = root.join("xbasic-6.4.5/src/shared/xcm.x");
    let xst_src = root.join("xbasic-6.4.5/src/linux/xst.x");
    assert!(xcm_src.exists(), "xcm.x not found at {xcm_src:?}");
    assert!(xst_src.exists(), "xst.x not found at {xst_src:?}");

    let xcm_c = emit_c(&xcm_src, &tmp, true);
    let xst_c = emit_c(&xst_src, &tmp, true);
    let xcm_o = compile_c(&xcm_c, &tmp);
    let xst_o = compile_c(&xst_c, &tmp);

    let harness = tmp.join("harness.c");
    fs::write(&harness, r#"#include <stdio.h>
    #include <string.h>
    #include <math.h>

    /* Forward declarations for user-defined functions from xcm.x */
    char* xb_user_XcmVersion(void);
    double xb_user_Atan2(double y, double x);
    /* DCOMPLEX params are flattened to .R, .I member slots */
    double xb_user_DCABS(double z_R, double z_I);
    double xb_user_DCARG(double z_R, double z_I);
double xb_user_DCNORM(double z_R, double z_I);
/* DCOMPLEX return type — struct typedef matches CEmitter output */
typedef struct { double R; double I; } xb_dcomplex;
xb_dcomplex xb_user_DCCONJ(double z_R, double z_I);
xb_dcomplex xb_user_DCSIN(double z_R, double z_I);
xb_dcomplex xb_user_DCCOS(double z_R, double z_I);
xb_dcomplex xb_user_DCCOSH(double z_R, double z_I);
xb_dcomplex xb_user_DCSINH(double z_R, double z_I);
xb_dcomplex xb_user_DCEXP(double z_R, double z_I);
xb_dcomplex xb_user_DCLOG(double z_R, double z_I);
xb_dcomplex xb_user_DCSQRT(double z_R, double z_I);
xb_dcomplex xb_user_DCRMUL(double x_R, double x_I, double y);
xb_dcomplex xb_user_DCPOLAR(double mag, double angle);
xb_dcomplex xb_user_DCLOG10(double z_R, double z_I);
xb_dcomplex xb_user_DCTAN(double z_R, double z_I);
xb_dcomplex xb_user_DCTANH(double z_R, double z_I);
xb_dcomplex xb_user_DCPOWERCR(double z_R, double z_I, double n);
/* SCOMPLEX return type — float members, but params flatten to double */
typedef struct { float R; float I; } xb_scomplex;
xb_scomplex xb_user_SCCONJ(double z_R, double z_I);
xb_scomplex xb_user_SCSIN(double z_R, double z_I);
xb_scomplex xb_user_SCCOS(double z_R, double z_I);
xb_dcomplex xb_user_DCACOS(double z_R, double z_I);
xb_dcomplex xb_user_DCASIN(double z_R, double z_I);
xb_dcomplex xb_user_DCATAN(double z_R, double z_I);
xb_dcomplex xb_user_DCPOWERCC(double z_R, double z_I, double n_R, double n_I);
xb_dcomplex xb_user_DCPOWERRC(double z, double n_R, double n_I);
xb_scomplex xb_user_SCCOSH(double z_R, double z_I);
xb_scomplex xb_user_SCSINH(double z_R, double z_I);
xb_scomplex xb_user_SCEXP(double z_R, double z_I);
xb_scomplex xb_user_SCLOG(double z_R, double z_I);
xb_scomplex xb_user_SCSQRT(double z_R, double z_I);
xb_scomplex xb_user_SCRMUL(double x_R, double x_I, double y);
xb_scomplex xb_user_SCACOS(double z_R, double z_I);
xb_scomplex xb_user_SCASIN(double z_R, double z_I);
xb_scomplex xb_user_SCATAN(double z_R, double z_I);
xb_scomplex xb_user_SCLOG10(double z_R, double z_I);
xb_scomplex xb_user_SCPOLAR(double mag, double angle);
xb_scomplex xb_user_SCTAN(double z_R, double z_I);
xb_scomplex xb_user_SCTANH(double z_R, double z_I);
xb_scomplex xb_user_SCPOWERCC(double z_R, double z_I, double n_R, double n_I);
xb_scomplex xb_user_SCPOWERCR(double z_R, double z_I, double n);
xb_scomplex xb_user_SCPOWERRC(double z, double n_R, double n_I);
    static int fails = 0;

    static void check_s(const char* name, const char* got, const char* want) {
        int ok = got && strcmp(got, want) == 0;
        printf("%-20s = [%s]  (want [%s])  %s\n", name, got ? got : "(null)", want, ok ? "ok" : "FAIL");
        if (!ok) fails++;
    }

    static void check_d(const char* name, double got, double want) {
        double diff = got - want;
        if (diff < 0) diff = -diff;
        int ok = diff < 1e-10;
        printf("%-20s = %.15g  (want %.15g)  %s\n", name, got, want, ok ? "ok" : "FAIL");
        if (!ok) fails++;
    }

    int main(void) {
        /* XcmVersion$ = "0.0007" — xcm.x has VERSION "0.0007", not "6.4.5" */
        check_s("XcmVersion$", xb_user_XcmVersion(), "0.0007");
        /* Atan2(0, 1) = 0 — y=0, x>0 → atan(0/1) = 0 */
        check_d("Atan2(0,1)", xb_user_Atan2(0.0, 1.0), 0.0);
        /* Atan2(1, 1) = PI/4 — y=x → atan(1) = PI/4 */
        check_d("Atan2(1,1)", xb_user_Atan2(1.0, 1.0), M_PI_4);
        /* Atan2(1, 0) = PI/2 — x=0, y>0 → inv path: PI/2 - atan(0) = PI/2 */
        check_d("Atan2(1,0)", xb_user_Atan2(1.0, 0.0), M_PI_2);
        /* DCABS(3,4) = 5 — |z| = sqrt(R^2 + I^2) = sqrt(9+16) = 5 */
        check_d("DCABS(3,4)", xb_user_DCABS(3.0, 4.0), 5.0);
        /* DCABS(0,0) = 0 */
        check_d("DCABS(0,0)", xb_user_DCABS(0.0, 0.0), 0.0);
        /* DCARG(1,0) = 0 — atan2(0,1) = 0 */
        check_d("DCARG(1,0)", xb_user_DCARG(1.0, 0.0), 0.0);
        /* DCARG(0,1) = PI/2 — atan2(1,0) = PI/2 */
        check_d("DCARG(0,1)", xb_user_DCARG(0.0, 1.0), M_PI_2);
        /* DCNORM(3,4) = 25 — R^2 + I^2 = 9+16 = 25 */
        check_d("DCNORM(3,4)", xb_user_DCNORM(3.0, 4.0), 25.0);
        /* DCCONJ(3,4) = (3,-4) — conjugate: R unchanged, I negated */
        { xb_dcomplex _r = xb_user_DCCONJ(3.0, 4.0);
          check_d("DCCONJ(3,4).R", _r.R, 3.0);
          check_d("DCCONJ(3,4).I", _r.I, -4.0); }
        /* DCCONJ(0,0) = (0,0) */
        { xb_dcomplex _r = xb_user_DCCONJ(0.0, 0.0);
          check_d("DCCONJ(0,0).R", _r.R, 0.0);
          check_d("DCCONJ(0,0).I", _r.I, 0.0); }
        /* DCSIN(0,0) = (0,0) — sin(0)*cosh(0)=0, cos(0)*sinh(0)=0 */
        { xb_dcomplex _r = xb_user_DCSIN(0.0, 0.0);
          check_d("DCSIN(0,0).R", _r.R, 0.0);
          check_d("DCSIN(0,0).I", _r.I, 0.0); }
        /* DCCOS(0,0) = (1,0) — cos(0)*cosh(0)=1, -sin(0)*sinh(0)=0 */
        { xb_dcomplex _r = xb_user_DCCOS(0.0, 0.0);
          check_d("DCCOS(0,0).R", _r.R, 1.0);
          check_d("DCCOS(0,0).I", _r.I, 0.0); }
        /* DCCOSH(0,0) = (1,0) — cosh(0)*cos(0)=1, sinh(0)*sin(0)=0 */
        { xb_dcomplex _r = xb_user_DCCOSH(0.0, 0.0);
          check_d("DCCOSH(0,0).R", _r.R, 1.0);
          check_d("DCCOSH(0,0).I", _r.I, 0.0); }
        /* DCSINH(0,0) = (0,0) — sinh(0)*cos(0)=0, cosh(0)*sin(0)=0 */
        { xb_dcomplex _r = xb_user_DCSINH(0.0, 0.0);
          check_d("DCSINH(0,0).R", _r.R, 0.0);
          check_d("DCSINH(0,0).I", _r.I, 0.0); }
        /* DCEXP(0,0) = (1,0) — exp(0)*cos(0)=1, exp(0)*sin(0)=0 */
        { xb_dcomplex _r = xb_user_DCEXP(0.0, 0.0);
          check_d("DCEXP(0,0).R", _r.R, 1.0);
          check_d("DCEXP(0,0).I", _r.I, 0.0); }
        /* DCLOG(1,0) = (0,0) — log(DCNORM(1,0))*0.5=log(1)*0.5=0, Atan2(0,1)=0 */
        { xb_dcomplex _r = xb_user_DCLOG(1.0, 0.0);
          check_d("DCLOG(1,0).R", _r.R, 0.0);
          check_d("DCLOG(1,0).I", _r.I, 0.0); }
        /* DCSQRT(4,0) = (2,0) — sqrt((4+4)*0.5)=sqrt(4)=2, sqrt((4-4)*0.5)*sign(0)=0 */
        { xb_dcomplex _r = xb_user_DCSQRT(4.0, 0.0);
          check_d("DCSQRT(4,0).R", _r.R, 2.0);
          check_d("DCSQRT(4,0).I", _r.I, 0.0); }
        /* DCRMUL(3,4,2) = (6,8) — complex * real: (3*2, 4*2) */
        { xb_dcomplex _r = xb_user_DCRMUL(3.0, 4.0, 2.0);
          check_d("DCRMUL(3,4,2).R", _r.R, 6.0);
          check_d("DCRMUL(3,4,2).I", _r.I, 8.0); }
        /* DCPOLAR(1,0) = (1,0) — mag*cos(angle)=1*1=1, mag*sin(angle)=1*0=0 */
        { xb_dcomplex _r = xb_user_DCPOLAR(1.0, 0.0);
          check_d("DCPOLAR(1,0).R", _r.R, 1.0);
          check_d("DCPOLAR(1,0).I", _r.I, 0.0); }
        /* DCLOG10(1,0) = (0,0) — DCLOG(1,0)*LOG10E = 0*LOG10E = 0 */
        { xb_dcomplex _r = xb_user_DCLOG10(1.0, 0.0);
          check_d("DCLOG10(1,0).R", _r.R, 0.0);
          check_d("DCLOG10(1,0).I", _r.I, 0.0); }
        /* DCTAN(0,0) = (0,0) — sin(0)/(cos(0)+cosh(0))=0, sinh(0)/(...)=0 */
        { xb_dcomplex _r = xb_user_DCTAN(0.0, 0.0);
          check_d("DCTAN(0,0).R", _r.R, 0.0);
          check_d("DCTAN(0,0).I", _r.I, 0.0); }
        /* DCTANH(0,0) = (0,0) — sinh(0)/(cosh(0)+cos(0))=0, sin(0)/(...)=0 */
        { xb_dcomplex _r = xb_user_DCTANH(0.0, 0.0);
          check_d("DCTANH(0,0).R", _r.R, 0.0);
          check_d("DCTANH(0,0).I", _r.I, 0.0); }
        /* DCPOWERCR(1,0,2) = (1,0) — exp(2*log(1))=exp(0)=1, imag=0 */
        { xb_dcomplex _r = xb_user_DCPOWERCR(1.0, 0.0, 2.0);
          check_d("DCPOWERCR(1,0,2).R", _r.R, 1.0);
          check_d("DCPOWERCR(1,0,2).I", _r.I, 0.0); }
        /* SCCONJ(3,4) = (3,-4) — SCOMPLEX conjugate: float R/I members */
        { xb_scomplex _s = xb_user_SCCONJ(3.0, 4.0);
          check_d("SCCONJ(3,4).R", (double)_s.R, 3.0);
          check_d("SCCONJ(3,4).I", (double)_s.I, -4.0); }
        /* SCSIN(0,0) = (0,0) — SCOMPLEX sin */
        { xb_scomplex _s = xb_user_SCSIN(0.0, 0.0);
          check_d("SCSIN(0,0).R", (double)_s.R, 0.0);
          check_d("SCSIN(0,0).I", (double)_s.I, 0.0); }
        /* SCCOS(0,0) = (1,0) — SCOMPLEX cos: cos(0)*cosh(0)=1, -sin(0)*sinh(0)=0 */
        { xb_scomplex _s = xb_user_SCCOS(0.0, 0.0);
          check_d("SCCOS(0,0).R", (double)_s.R, 1.0);
          check_d("SCCOS(0,0).I", (double)_s.I, 0.0); }
        /* DCACOS(0,0) = (PI/2, 0) — ACOS(XdcGetBeta(0,0))=ACOS(0)=PI/2, -alpha=0 */
        { xb_dcomplex _r = xb_user_DCACOS(0.0, 0.0);
          check_d("DCACOS(0,0).R", _r.R, M_PI_2);
          check_d("DCACOS(0,0).I", _r.I, 0.0); }
        /* DCASIN(0,0) = (0, 0) — ASIN(XdcGetBeta(0,0))=ASIN(0)=0, alpha=0 */
        { xb_dcomplex _r = xb_user_DCASIN(0.0, 0.0);
          check_d("DCASIN(0,0).R", _r.R, 0.0);
          check_d("DCASIN(0,0).I", _r.I, 0.0); }
        /* DCATAN(0,0) = (0, 0) — ATAN(0/(1-0-0))*0.5=0, LOG((0+1)/(0+1))*0.25=0 */
        { xb_dcomplex _r = xb_user_DCATAN(0.0, 0.0);
          check_d("DCATAN(0,0).R", _r.R, 0.0);
          check_d("DCATAN(0,0).I", _r.I, 0.0); }
        /* DCPOWERCC(1,0, 2,0) = (1,0) — DCEXP(2*DCLOG(1,0))=DCEXP(2*(0,0))=DCEXP(0,0)=(1,0).
           Tests composite return → complex multiply → composite param chain. */
        { xb_dcomplex _r = xb_user_DCPOWERCC(1.0, 0.0, 2.0, 0.0);
          check_d("DCPOWERCC(1,0,2,0).R", _r.R, 1.0);
          check_d("DCPOWERCC(1,0,2,0).I", _r.I, 0.0); }
        /* DCPOWERRC(1, 2,0) = (1,0) — DCEXP(DCRMUL((2,0), LOG(1)))=DCEXP(DCRMUL((2,0),0))=DCEXP(0,0)=(1,0).
           Tests DOUBLE param + DCOMPLEX param → DCRMUL → DCEXP chain. */
        { xb_dcomplex _r = xb_user_DCPOWERRC(1.0, 2.0, 0.0);
          check_d("DCPOWERRC(1,2,0).R", _r.R, 1.0);
          check_d("DCPOWERRC(1,2,0).I", _r.I, 0.0); }
        /* SCCOSH(0,0) = (1,0) — SCOMPLEX cosh: cosh(0)*cos(0)=1, sinh(0)*sin(0)=0 */
        { xb_scomplex _s = xb_user_SCCOSH(0.0, 0.0);
          check_d("SCCOSH(0,0).R", (double)_s.R, 1.0);
          check_d("SCCOSH(0,0).I", (double)_s.I, 0.0); }
        /* SCSINH(0,0) = (0,0) — SCOMPLEX sinh: sinh(0)*cos(0)=0, cosh(0)*sin(0)=0 */
        { xb_scomplex _s = xb_user_SCSINH(0.0, 0.0);
          check_d("SCSINH(0,0).R", (double)_s.R, 0.0);
          check_d("SCSINH(0,0).I", (double)_s.I, 0.0); }
        /* SCEXP(0,0) = (1,0) — SCOMPLEX exp: exp(0)*cos(0)=1, exp(0)*sin(0)=0 */
        { xb_scomplex _s = xb_user_SCEXP(0.0, 0.0);
          check_d("SCEXP(0,0).R", (double)_s.R, 1.0);
          check_d("SCEXP(0,0).I", (double)_s.I, 0.0); }
        /* SCLOG(1,0) = (0,0) — SCOMPLEX log: log(SCNORM(1,0))*0.5=0, Atan2(0,1)=0 */
        { xb_scomplex _s = xb_user_SCLOG(1.0, 0.0);
          check_d("SCLOG(1,0).R", (double)_s.R, 0.0);
          check_d("SCLOG(1,0).I", (double)_s.I, 0.0); }
        /* SCSQRT(4,0) = (2,0) — SCOMPLEX sqrt: sqrt((4+4)*0.5)=2, sqrt((4-4)*0.5)*sign(0)=0 */
        { xb_scomplex _s = xb_user_SCSQRT(4.0, 0.0);
          check_d("SCSQRT(4,0).R", (double)_s.R, 2.0);
          check_d("SCSQRT(4,0).I", (double)_s.I, 0.0); }
        /* SCRMUL(3,4,2) = (6,8) — SCOMPLEX * real: (3*2, 4*2) */
        { xb_scomplex _s = xb_user_SCRMUL(3.0, 4.0, 2.0);
          check_d("SCRMUL(3,4,2).R", (double)_s.R, 6.0);
          check_d("SCRMUL(3,4,2).I", (double)_s.I, 8.0); }
        /* SCACOS(0,0) = (PI/2, 0) — SCOMPLEX arccos: ACOS(0)=PI/2, -alpha=0.
           Expected value cast to float to match SCOMPLEX's float member precision. */
        { xb_scomplex _s = xb_user_SCACOS(0.0, 0.0);
          check_d("SCACOS(0,0).R", (double)_s.R, (double)(float)M_PI_2);
          check_d("SCACOS(0,0).I", (double)_s.I, 0.0); }
        /* SCASIN(0,0) = (0, 0) — SCOMPLEX arcsin: ASIN(0)=0, alpha=0 */
        { xb_scomplex _s = xb_user_SCASIN(0.0, 0.0);
          check_d("SCASIN(0,0).R", (double)_s.R, 0.0);
          check_d("SCASIN(0,0).I", (double)_s.I, 0.0); }
        /* SCATAN(0,0) = (0, 0) — SCOMPLEX arctan: ATAN(0)=0, LOG(1)*0.25=0 */
        { xb_scomplex _s = xb_user_SCATAN(0.0, 0.0);
          check_d("SCATAN(0,0).R", (double)_s.R, 0.0);
          check_d("SCATAN(0,0).I", (double)_s.I, 0.0); }
        /* SCLOG10(1,0) = (0,0) — SCOMPLEX log10: SCLOG(1,0)*LOG10E=0 */
        { xb_scomplex _s = xb_user_SCLOG10(1.0, 0.0);
          check_d("SCLOG10(1,0).R", (double)_s.R, 0.0);
          check_d("SCLOG10(1,0).I", (double)_s.I, 0.0); }
        /* SCPOLAR(1,0) = (1,0) — SCOMPLEX polar: mag*cos(angle)=1, mag*sin(angle)=0 */
        { xb_scomplex _s = xb_user_SCPOLAR(1.0, 0.0);
          check_d("SCPOLAR(1,0).R", (double)_s.R, 1.0);
          check_d("SCPOLAR(1,0).I", (double)_s.I, 0.0); }
        /* SCTAN(0,0) = (0,0) — SCOMPLEX tan: SIN(0,0)/COS(0,0)=(0,0)/(1,0)=(0,0) */
        { xb_scomplex _s = xb_user_SCTAN(0.0, 0.0);
          check_d("SCTAN(0,0).R", (double)_s.R, 0.0);
          check_d("SCTAN(0,0).I", (double)_s.I, 0.0); }
        /* SCTANH(0,0) = (0,0) — SCOMPLEX tanh: SINH(0,0)/COSH(0,0)=(0,0)/(1,0)=(0,0) */
        { xb_scomplex _s = xb_user_SCTANH(0.0, 0.0);
          check_d("SCTANH(0,0).R", (double)_s.R, 0.0);
          check_d("SCTANH(0,0).I", (double)_s.I, 0.0); }
        /* SCPOWERCC(1,0, 2,0) = (1,0) — SCEXP(2*SCLOG(1,0))=SCEXP(0,0)=(1,0) */
        { xb_scomplex _s = xb_user_SCPOWERCC(1.0, 0.0, 2.0, 0.0);
          check_d("SCPOWERCC(1,0,2,0).R", (double)_s.R, 1.0);
          check_d("SCPOWERCC(1,0,2,0).I", (double)_s.I, 0.0); }
        /* SCPOWERCR(1,0, 2) = (1,0) — SCEXP(SCRMUL(SCLOG(1,0),2))=SCEXP(0,0)=(1,0) */
        { xb_scomplex _s = xb_user_SCPOWERCR(1.0, 0.0, 2.0);
          check_d("SCPOWERCR(1,0,2).R", (double)_s.R, 1.0);
          check_d("SCPOWERCR(1,0,2).I", (double)_s.I, 0.0); }
        /* SCPOWERRC(1, 2,0) = (1,0) — SCEXP(SCRMUL((2,0), LOG(1)))=SCEXP(0,0)=(1,0) */
        { xb_scomplex _s = xb_user_SCPOWERRC(1.0, 2.0, 0.0);
          check_d("SCPOWERRC(1,2,0).R", (double)_s.R, 1.0);
          check_d("SCPOWERRC(1,2,0).I", (double)_s.I, 0.0); }

        printf("\n%d checks, %d failures\n", 87, fails);
        return fails;
    }
    "#).unwrap();

    let bin = tmp.join("xcm_test");
    let link = Command::new(cc())
        .args(["-O0", "-Wno-incompatible-pointer-types", "-Wno-int-conversion"])
        .arg(&harness)
        .arg(&xcm_o)
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
        "xcm behavior test failed:\nstdout:\n{stdout}\nstderr:\n{stderr}"
    );

    assert!(stdout.contains("0 failures"), "test reported failures:\n{stdout}");
    assert!(stdout.contains("Atan2(1,1)"), "missing Atan2(1,1) check in output");
    assert!(stdout.contains("DCABS(3,4)"), "missing DCABS(3,4) check in output");
    assert!(stdout.contains("DCARG(0,1)"), "missing DCARG(0,1) check in output");
    assert!(stdout.contains("DCNORM(3,4)"), "missing DCNORM(3,4) check in output");
    assert!(stdout.contains("DCCONJ(3,4).R"), "missing DCCONJ(3,4).R check in output");
    assert!(stdout.contains("DCCONJ(3,4).I"), "missing DCCONJ(3,4).I check in output");
    assert!(stdout.contains("DCSIN(0,0).R"), "missing DCSIN(0,0).R check in output");
    assert!(stdout.contains("DCCOS(0,0).R"), "missing DCCOS(0,0).R check in output");
    assert!(stdout.contains("DCEXP(0,0).R"), "missing DCEXP(0,0).R check in output");
    assert!(stdout.contains("DCSQRT(4,0).R"), "missing DCSQRT(4,0).R check in output");
    assert!(stdout.contains("DCRMUL(3,4,2).R"), "missing DCRMUL(3,4,2).R check in output");
    assert!(stdout.contains("DCPOLAR(1,0).R"), "missing DCPOLAR(1,0).R check in output");
    assert!(stdout.contains("DCLOG10(1,0).R"), "missing DCLOG10(1,0).R check in output");
    assert!(stdout.contains("DCTAN(0,0).R"), "missing DCTAN(0,0).R check in output");
    assert!(stdout.contains("DCPOWERCR(1,0,2).R"), "missing DCPOWERCR(1,0,2).R check in output");
    assert!(stdout.contains("SCCONJ(3,4).R"), "missing SCCONJ(3,4).R check in output");
    assert!(stdout.contains("SCCOS(0,0).R"), "missing SCCOS(0,0).R check in output");
    assert!(stdout.contains("DCACOS(0,0).R"), "missing DCACOS(0,0).R check in output");
    assert!(stdout.contains("DCASIN(0,0).R"), "missing DCASIN(0,0).R check in output");
    assert!(stdout.contains("DCATAN(0,0).R"), "missing DCATAN(0,0).R check in output");
    assert!(stdout.contains("DCPOWERCC(1,0,2,0).R"), "missing DCPOWERCC(1,0,2,0).R check in output");
    assert!(stdout.contains("DCPOWERRC(1,2,0).R"), "missing DCPOWERRC(1,2,0).R check in output");
    assert!(stdout.contains("SCCOSH(0,0).R"), "missing SCCOSH(0,0).R check in output");
    assert!(stdout.contains("SCEXP(0,0).R"), "missing SCEXP(0,0).R check in output");
    assert!(stdout.contains("SCSQRT(4,0).R"), "missing SCSQRT(4,0).R check in output");
    assert!(stdout.contains("SCRMUL(3,4,2).R"), "missing SCRMUL(3,4,2).R check in output");
    assert!(stdout.contains("SCACOS(0,0).R"), "missing SCACOS(0,0).R check in output");
    assert!(stdout.contains("SCASIN(0,0).R"), "missing SCASIN(0,0).R check in output");
    assert!(stdout.contains("SCATAN(0,0).R"), "missing SCATAN(0,0).R check in output");
    assert!(stdout.contains("SCLOG10(1,0).R"), "missing SCLOG10(1,0).R check in output");
    assert!(stdout.contains("SCPOLAR(1,0).R"), "missing SCPOLAR(1,0).R check in output");
    assert!(stdout.contains("SCTAN(0,0).R"), "missing SCTAN(0,0).R check in output");
    assert!(stdout.contains("SCTANH(0,0).R"), "missing SCTANH(0,0).R check in output");
    assert!(stdout.contains("SCPOWERCC(1,0,2,0).R"), "missing SCPOWERCC(1,0,2,0).R check in output");
    assert!(stdout.contains("SCPOWERCR(1,0,2).R"), "missing SCPOWERCR(1,0,2).R check in output");
    assert!(stdout.contains("SCPOWERRC(1,2,0).R"), "missing SCPOWERRC(1,2,0).R check in output");
}
