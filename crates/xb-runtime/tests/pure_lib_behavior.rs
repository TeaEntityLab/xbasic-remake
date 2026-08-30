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
double xb_user_ATANH(double v);
double xb_user_LOG10(double v);
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

    printf("\n%d checks, %d failures\n", 12, fails);
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

        printf("\n%d checks, %d failures\n", 31, fails);
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
}
