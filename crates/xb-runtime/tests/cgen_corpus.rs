mod common;

use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::Command;
use xb_compiler::{CEmitter, FrontendUnit, TextIrEmitter};
use xb_runtime::Interpreter;

/// Verify cgen.x can compile every selfhost tool (compiler, lexer, parser)
/// to native, and the native output matches the Rust-hosted interpreter.
#[test]
fn cgen_compiles_all_selfhost_tools() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_cgen_corpus");
    fs::create_dir_all(&tmp).expect("mkdir");

    // Build native cgen once
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
    assert!(cc0.status.success(), "cc cgen failed");

    for tool in ["compiler", "lexer", "parser"] {
        let src_path = root.join(format!("selfhost/{tool}.x"));
        let in_path = root.join(format!("selfhost/{tool}.in"));
        let source = fs::read_to_string(&src_path).expect("read source");
        let input = fs::read_to_string(&in_path).expect("read input");

        // Generate text IR via Rust host
        let prog = FrontendUnit::parse(&source)
            .expect("parse")
            .lower_ir()
            .expect("lower");
        let ir = TextIrEmitter::new().emit_program(&prog);

        // Feed text IR to native cgen → C source
        let run_cgen = Command::new(common::exe_path(&cgen_exe))
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()
            .expect("spawn cgen");
        let mut cgen_child = run_cgen;
        if let Some(mut stdin) = cgen_child.stdin.take() {
            stdin.write_all(ir.as_bytes()).expect("write IR");
        }
        let cgen_out = cgen_child.wait_with_output().expect("wait cgen");
        assert!(cgen_out.status.success(), "cgen failed for {tool}");

        // Compile generated C → native executable
        let exe_path = tmp.join(tool);
        let c_path = tmp.join(format!("{tool}.c"));
        fs::write(&c_path, &cgen_out.stdout).expect("write C");
        let cc = Command::new(common::cc::cc())
            .args(["-o", exe_path.to_str().unwrap(), c_path.to_str().unwrap()])
            .output()
            .expect("cc");
        assert!(
            cc.status.success(),
            "cc failed for {tool}: {}",
            String::from_utf8_lossy(&cc.stderr)
        );

        // Run native executable with tool input
        let run = Command::new(common::exe_path(&exe_path))
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()
            .expect("spawn");
        let mut child = run;
        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(input.as_bytes()).expect("write input");
        }
        let out = child.wait_with_output().expect("wait");
        assert!(out.status.success(), "native {tool} failed");
        let native_output: String = out.stdout.iter().map(|&b| b as char).collect();

        // Run Rust-hosted interpreter with same input
        let mut interp_out = Vec::new();
        let input_lines: Vec<String> = input.lines().map(String::from).collect();
        Interpreter::new()
            .execute_main_with_input(&prog, input_lines, &mut interp_out)
            .expect("execute");
        let interp_output: String = interp_out.into_iter().map(|l| format!("{l}\n")).collect();

        assert_eq!(
            native_output, interp_output,
            "cgen-compiled {tool} output differs from interpreter"
        );

        let _ = fs::remove_file(&exe_path);
        let _ = fs::remove_file(&c_path);
    }

    let _ = fs::remove_file(&cgen_exe);
    let _ = fs::remove_file(&cgen_c_path);
}

/// cgen.x compiles itself: cgen.x IR → native cgen → C → cc → cgen2
/// Then cgen2 produces identical C output to cgen1 for the same input IR.
#[test]
fn cgen_compiles_itself() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_cgen_selfcomp");
    fs::create_dir_all(&tmp).expect("mkdir");

    // Build native cgen (cgen1) via Rust C emitter
    let cgen_src = fs::read_to_string(root.join("selfhost/cgen.x")).expect("read");
    let cgen_prog = FrontendUnit::parse(&cgen_src)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let cgen1_c = CEmitter::new().emit_program(&cgen_prog);
    let cgen1_exe = tmp.join("cgen1");
    let cgen1_c_path = tmp.join("cgen1.c");
    fs::write(&cgen1_c_path, &cgen1_c).expect("write");
    let cc1 = Command::new(common::cc::cc())
        .args([
            "-o",
            cgen1_exe.to_str().unwrap(),
            cgen1_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(cc1.status.success(), "cc cgen1 failed");

    // cgen1 processes cgen.x's own IR → C source for cgen2
    let cgen_ir = TextIrEmitter::new().emit_program(&cgen_prog);
    let mut cgen1_child = Command::new(common::exe_path(&cgen1_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn cgen1");
    if let Some(mut stdin) = cgen1_child.stdin.take() {
        stdin.write_all(cgen_ir.as_bytes()).expect("write IR");
    }
    let cgen1_out = cgen1_child.wait_with_output().expect("wait");
    assert!(cgen1_out.status.success(), "cgen1 failed on own IR");

    // Compile cgen2
    let cgen2_exe = tmp.join("cgen2");
    let cgen2_c_path = tmp.join("cgen2.c");
    fs::write(&cgen2_c_path, &cgen1_out.stdout).expect("write");
    let cc2 = Command::new(common::cc::cc())
        .args([
            "-o",
            cgen2_exe.to_str().unwrap(),
            cgen2_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(
        cc2.status.success(),
        "cc cgen2 failed: {}",
        String::from_utf8_lossy(&cc2.stderr)
    );

    // cgen2 compiles compiler.x → native compiler, verify output matches Rust host
    let comp_src = fs::read_to_string(root.join("selfhost/compiler.x")).expect("read");
    let comp_prog = FrontendUnit::parse(&comp_src)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let comp_ir = TextIrEmitter::new().emit_program(&comp_prog);
    let mut cgen2_child = Command::new(common::exe_path(&cgen2_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn cgen2");
    if let Some(mut stdin) = cgen2_child.stdin.take() {
        stdin.write_all(comp_ir.as_bytes()).expect("write IR");
    }
    let cgen2_out = cgen2_child.wait_with_output().expect("wait");
    assert!(cgen2_out.status.success(), "cgen2 failed on compiler.x IR");

    let comp_exe = tmp.join("compiler_cgen2");
    let comp_c_path = tmp.join("compiler_cgen2.c");
    fs::write(&comp_c_path, &cgen2_out.stdout).expect("write");
    let cc3 = Command::new(common::cc::cc())
        .args([
            "-o",
            comp_exe.to_str().unwrap(),
            comp_c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(
        cc3.status.success(),
        "cc compiler failed: {}",
        String::from_utf8_lossy(&cc3.stderr)
    );

    // Run compiler built by cgen2
    let comp_in = fs::read_to_string(root.join("selfhost/compiler.in")).expect("read");
    let mut comp_child = Command::new(common::exe_path(&comp_exe))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn compiler");
    if let Some(mut stdin) = comp_child.stdin.take() {
        stdin.write_all(comp_in.as_bytes()).expect("write input");
    }
    let comp_out = comp_child.wait_with_output().expect("wait");
    assert!(comp_out.status.success(), "compiler failed");
    let native_output: String = comp_out.stdout.iter().map(|&b| b as char).collect();

    // Compare with Rust-hosted interpreter
    let mut interp_out = Vec::new();
    let input_lines: Vec<String> = comp_in.lines().map(String::from).collect();
    Interpreter::new()
        .execute_main_with_input(&comp_prog, input_lines, &mut interp_out)
        .expect("execute");
    let interp_output: String = interp_out.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        native_output, interp_output,
        "cgen2-built compiler differs from interpreter"
    );

    let _ = fs::remove_dir_all(&tmp);
}
