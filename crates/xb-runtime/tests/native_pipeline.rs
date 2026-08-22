mod common;

use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::Command;
use xb_compiler::{CEmitter, FrontendUnit, TextIrEmitter};

/// Full native pipeline: native compiler emits cgen.x IR → native cgen compiles it.
/// No Rust in the cgen IR → cgen compilation step.
///
/// Currently ignored: `selfhost/compiler.x` (1272-line native IR emitter) is too
/// slow to process the now-5430-line `cgen.x` — OOM-killed (exit 137) after ~118s
/// with only 728 lines of IR output. This is a `compiler.x` performance issue
/// (per-character `MID$`/`ASC` tokenization on 5430 lines), not a cgen.x issue.
/// Fixing requires optimizing `compiler.x`'s tokenizer to avoid per-char string
/// allocation, or rewriting it to process the input in larger chunks.
#[test]
#[ignore = "compiler.x too slow for 5430-line cgen.x (OOM killed after 118s)"]
fn native_compiler_emits_cgen_ir_for_cgen() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_native_pipeline");
    fs::create_dir_all(&tmp).expect("mkdir");

    // Build native compiler (compA) and native cgen (cgen1) via Rust
    let comp_src = fs::read_to_string(root.join("selfhost/compiler.x")).expect("read");
    let comp_prog = FrontendUnit::parse(&comp_src)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let comp_c = CEmitter::new().emit_program(&comp_prog);
    let comp_exe = tmp.join("compA");
    let comp_c_path = tmp.join("compA.c");
    fs::write(&comp_c_path, &comp_c).expect("write");
    let cc0 = Command::new(common::cc::cc())
        .args([
            "-o",
            comp_exe.to_str().unwrap(),
            comp_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(cc0.status.success(), "cc compA failed");

    let cgen_src = fs::read_to_string(root.join("selfhost/cgen.x")).expect("read");
    let cgen_prog = FrontendUnit::parse(&cgen_src)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let cgen_c = CEmitter::new().emit_program(&cgen_prog);
    let cgen_exe = tmp.join("cgen1");
    let cgen_c_path = tmp.join("cgen1.c");
    fs::write(&cgen_c_path, &cgen_c).expect("write");
    let cc1 = Command::new(common::cc::cc())
        .args([
            "-o",
            cgen_exe.to_str().unwrap(),
            cgen_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(cc1.status.success(), "cc cgen1 failed");

    // Native compiler emits cgen.x IR (no Rust)
    let mut comp_child = Command::new(common::exe_path(&comp_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn compA");
    if let Some(mut stdin) = comp_child.stdin.take() {
        stdin.write_all(cgen_src.as_bytes()).expect("write cgen.x");
    }
    let comp_out = comp_child.wait_with_output().expect("wait");
    assert!(comp_out.status.success(), "compA failed on cgen.x");
    let native_cgen_ir: String = comp_out.stdout.iter().map(|&b| b as char).collect();

    // Compare with Rust-hosted IR
    let rust_cgen_ir = TextIrEmitter::new().emit_program(&cgen_prog);
    assert_eq!(
        native_cgen_ir, rust_cgen_ir,
        "native compiler IR for cgen.x differs from Rust host"
    );

    // Native cgen compiles native IR → C → cgen3 (no Rust in this step)
    let mut cgen1_child = Command::new(common::exe_path(&cgen_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn cgen1");
    if let Some(mut stdin) = cgen1_child.stdin.take() {
        stdin
            .write_all(native_cgen_ir.as_bytes())
            .expect("write IR");
    }
    let cgen1_out = cgen1_child.wait_with_output().expect("wait");
    assert!(cgen1_out.status.success(), "cgen1 failed on native IR");

    let cgen3_exe = tmp.join("cgen3");
    let cgen3_c_path = tmp.join("cgen3.c");
    fs::write(&cgen3_c_path, &cgen1_out.stdout).expect("write");
    let cc3 = Command::new(common::cc::cc())
        .args([
            "-o",
            cgen3_exe.to_str().unwrap(),
            cgen3_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(
        cc3.status.success(),
        "cc cgen3 failed: {}",
        String::from_utf8_lossy(&cc3.stderr)
    );

    // cgen3 produces identical output to cgen1
    let test_ir =
        "version 0.1\nfunction Main() -> integer\n  print string(\"hello\")\nend function\n";
    let mut c1 = Command::new(common::exe_path(&cgen_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .spawn()
        .expect("spawn");
    if let Some(mut stdin) = c1.stdin.take() {
        stdin.write_all(test_ir.as_bytes()).expect("w");
    }
    let c1_out = c1.wait_with_output().expect("wait");
    let mut c3 = Command::new(common::exe_path(&cgen3_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .spawn()
        .expect("spawn");
    if let Some(mut stdin) = c3.stdin.take() {
        stdin.write_all(test_ir.as_bytes()).expect("w");
    }
    let c3_out = c3.wait_with_output().expect("wait");
    assert_eq!(
        c1_out.stdout, c3_out.stdout,
        "cgen3 output differs from cgen1"
    );

    let _ = fs::remove_dir_all(&tmp);
}
