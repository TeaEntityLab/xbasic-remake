mod common;

use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::Command;
use xb_compiler::{CEmitter, FrontendUnit, TextIrEmitter};
use xb_runtime::Interpreter;

/// Self-hosting C generator: cgen.x → C → cc → native cgen
/// Then: compiler.x text IR → native cgen → C → cc → native compiler
/// Verify: native compiler < compiler.in → output identical to Rust-hosted interpreter
#[test]
fn cgen_x_self_hosting_pipeline() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_cgen_selfhost");
    fs::create_dir_all(&tmp).expect("mkdir");

    // Step 1: Compile cgen.x to native executable using Rust C emitter
    let cgen_source = fs::read_to_string(root.join("selfhost/cgen.x")).expect("read cgen.x");
    let cgen_unit = FrontendUnit::parse(&cgen_source).expect("parse cgen.x");
    let cgen_program = cgen_unit.lower_ir().expect("lower cgen.x");
    let cgen_c = CEmitter::new().emit_program(&cgen_program);
    let cgen_c_path = tmp.join("cgen.c");
    let cgen_exe = tmp.join("cgen_native");
    fs::write(&cgen_c_path, &cgen_c).expect("write cgen.c");
    let cc1 = Command::new(common::cc::cc())
        .args([
            "-o",
            cgen_exe.to_str().unwrap(),
            cgen_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc cgen");
    assert!(
        cc1.status.success(),
        "cc failed for cgen.x: {}",
        String::from_utf8_lossy(&cc1.stderr)
    );

    // Step 2: Generate text IR for compiler.x
    let compiler_source =
        fs::read_to_string(root.join("selfhost/compiler.x")).expect("read compiler.x");
    let compiler_unit = FrontendUnit::parse(&compiler_source).expect("parse compiler.x");
    let compiler_program = compiler_unit.lower_ir().expect("lower compiler.x");
    let compiler_ir = TextIrEmitter::new().emit_program(&compiler_program);

    // Step 3: Feed text IR to native cgen → C source
    let cgen_run = Command::new(common::exe_path(&cgen_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn cgen");
    let mut cgen_child = cgen_run;
    if let Some(mut stdin) = cgen_child.stdin.take() {
        stdin.write_all(compiler_ir.as_bytes()).expect("write IR");
    }
    let cgen_out = cgen_child.wait_with_output().expect("wait cgen");
    assert!(cgen_out.status.success(), "cgen native failed");
    let compiler_c = String::from_utf8(cgen_out.stdout).expect("cgen output");
    assert!(
        compiler_c.contains("int main(void)"),
        "cgen output missing main"
    );

    // Step 4: Compile generated C → native compiler
    let compiler_c_path = tmp.join("compiler_from_cgen.c");
    let compiler_exe = tmp.join("compiler_from_cgen");
    fs::write(&compiler_c_path, &compiler_c).expect("write compiler.c");
    let cc2 = Command::new(common::cc::cc())
        .args([
            "-o",
            compiler_exe.to_str().unwrap(),
            compiler_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc compiler");
    assert!(
        cc2.status.success(),
        "cc failed for generated compiler: {}",
        String::from_utf8_lossy(&cc2.stderr)
    );

    // Step 5: Run native compiler on compiler.in
    let compiler_in =
        fs::read_to_string(root.join("selfhost/compiler.in")).expect("read compiler.in");
    let native_run = Command::new(common::exe_path(&compiler_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn native compiler");
    let mut native_child = native_run;
    if let Some(mut stdin) = native_child.stdin.take() {
        stdin
            .write_all(compiler_in.as_bytes())
            .expect("write compiler.in");
    }
    let native_out = native_child
        .wait_with_output()
        .expect("wait native compiler");
    assert!(native_out.status.success(), "native compiler failed");
    let native_output = String::from_utf8(native_out.stdout).expect("native output");

    // Step 6: Compare with Rust-hosted interpreter output
    let mut interp_out = Vec::new();
    let input_lines: Vec<Vec<u8>> = common::byte_lines(compiler_in.as_bytes());
    Interpreter::new()
        .execute_main_with_input(&compiler_program, input_lines, &mut interp_out)
        .expect("execute");
    let interp_output: String = interp_out.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        native_output, interp_output,
        "cgen-compiled compiler output differs from interpreter"
    );

    // Cleanup
    let _ = fs::remove_file(&cgen_c_path);
    let _ = fs::remove_file(&cgen_exe);
    let _ = fs::remove_file(&compiler_c_path);
    let _ = fs::remove_file(&compiler_exe);
}

/// True self-hosting bootstrap: once Rust bootstraps the native tools,
/// the native compiler + native cgen rebuild the compiler WITHOUT Rust.
///
/// 1. Rust bootstraps cgen.x → native cgen (one-time)
/// 2. Rust bootstraps compiler.x → native compiler A (one-time)
/// 3. Native compiler A < compiler.x → text IR A (no Rust)
/// 4. Native cgen < text IR A → C → cc → native compiler B (no Rust)
/// 5. Native compiler B < compiler.x → text IR B (no Rust)
/// 6. Assert text IR A == text IR B (self-rebuild without Rust)
/// 7. Assert text IR A == Rust-hosted output (behavioral equivalence)
#[test]
fn true_bootstrap_without_rust_host() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_true_bootstrap");
    fs::create_dir_all(&tmp).expect("mkdir");

    // Step 1: Rust bootstraps cgen.x → native cgen
    let cgen_src = fs::read_to_string(root.join("selfhost/cgen.x")).expect("read cgen.x");
    let cgen_prog = FrontendUnit::parse(&cgen_src)
        .expect("parse cgen")
        .lower_ir()
        .expect("lower");
    let cgen_c = CEmitter::new().emit_program(&cgen_prog);
    let cgen_exe = tmp.join("cgen");
    let cgen_c_path = tmp.join("cgen.c");
    fs::write(&cgen_c_path, &cgen_c).expect("write");
    let cc0 = Command::new(common::cc::cc())
        .args([
            "-o",
            cgen_exe.to_str().unwrap(),
            cgen_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(
        cc0.status.success(),
        "cc cgen failed: {}",
        String::from_utf8_lossy(&cc0.stderr)
    );

    // Step 2: Rust bootstraps compiler.x → native compiler A
    let comp_src = fs::read_to_string(root.join("selfhost/compiler.x")).expect("read compiler.x");
    let comp_prog = FrontendUnit::parse(&comp_src)
        .expect("parse compiler")
        .lower_ir()
        .expect("lower");
    let comp_a_c = CEmitter::new().emit_program(&comp_prog);
    let comp_a_exe = tmp.join("compilerA");
    let comp_a_c_path = tmp.join("compilerA.c");
    fs::write(&comp_a_c_path, &comp_a_c).expect("write");
    let cc1 = Command::new(common::cc::cc())
        .args([
            "-o",
            comp_a_exe.to_str().unwrap(),
            comp_a_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(
        cc1.status.success(),
        "cc compilerA failed: {}",
        String::from_utf8_lossy(&cc1.stderr)
    );

    // Step 3: Native compiler A reads compiler.x source → text IR A (no Rust)
    let run_a = Command::new(common::exe_path(&comp_a_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn A");
    let mut child_a = run_a;
    if let Some(mut stdin) = child_a.stdin.take() {
        stdin
            .write_all(comp_src.as_bytes())
            .expect("write compiler.x");
    }
    let out_a = child_a.wait_with_output().expect("wait A");
    assert!(
        out_a.status.success(),
        "compiler A failed: {}",
        String::from_utf8_lossy(&out_a.stderr)
    );
    let ir_a = String::from_utf8(out_a.stdout).expect("IR A");

    // Step 4: Native cgen reads text IR A → C → cc → native compiler B (no Rust)
    let run_cgen = Command::new(common::exe_path(&cgen_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn cgen");
    let mut cgen_child = run_cgen;
    if let Some(mut stdin) = cgen_child.stdin.take() {
        stdin.write_all(ir_a.as_bytes()).expect("write IR A");
    }
    let cgen_out = cgen_child.wait_with_output().expect("wait cgen");
    assert!(
        cgen_out.status.success(),
        "cgen failed: {}",
        String::from_utf8_lossy(&cgen_out.stderr)
    );
    let comp_b_c = String::from_utf8(cgen_out.stdout).expect("C from cgen");
    let comp_b_exe = tmp.join("compilerB");
    let comp_b_c_path = tmp.join("compilerB.c");
    fs::write(&comp_b_c_path, &comp_b_c).expect("write");
    let cc2 = Command::new(common::cc::cc())
        .args([
            "-o",
            comp_b_exe.to_str().unwrap(),
            comp_b_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(
        cc2.status.success(),
        "cc compilerB failed: {}",
        String::from_utf8_lossy(&cc2.stderr)
    );

    // Step 5: Native compiler B reads compiler.x source → text IR B (no Rust)
    let run_b = Command::new(common::exe_path(&comp_b_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn B");
    let mut child_b = run_b;
    if let Some(mut stdin) = child_b.stdin.take() {
        stdin
            .write_all(comp_src.as_bytes())
            .expect("write compiler.x");
    }
    let out_b = child_b.wait_with_output().expect("wait B");
    assert!(
        out_b.status.success(),
        "compiler B failed: {}",
        String::from_utf8_lossy(&out_b.stderr)
    );
    let ir_b = String::from_utf8(out_b.stdout).expect("IR B");

    // Step 6: Self-rebuild without Rust — A == B
    assert_eq!(
        ir_a, ir_b,
        "true bootstrap: native compiler A and B produce different IR"
    );

    // Step 7: Behavioral equivalence with Rust host
    let rust_ir = TextIrEmitter::new().emit_program(&comp_prog);
    assert_eq!(
        ir_a, rust_ir,
        "true bootstrap: native compiler output differs from Rust host"
    );

    // Cleanup
    for f in [
        &cgen_c_path,
        &cgen_exe,
        &comp_a_c_path,
        &comp_a_exe,
        &comp_b_c_path,
        &comp_b_exe,
    ] {
        let _ = fs::remove_file(f);
    }
}
