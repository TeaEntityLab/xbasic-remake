mod common;

use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::Command;
use xb_compiler::{CEmitter, FrontendUnit};

/// cgen.x compiles every positive corpus program to native,
/// and the native output matches the golden .out file.
/// This catches cgen.x bugs that only manifest on specific IR constructs
/// (e.g. nested string concat, bitwise NOT, string literal parsing).
#[test]
fn cgen_compiles_all_positive_corpus() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let corpus = root.join("fixtures/corpus/v0.1/positive");
    let tmp = std::env::temp_dir().join("xb_cgen_pos_corpus");
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

    // Discover all positive corpus cases
    let mut cases: Vec<String> = Vec::new();
    for entry in fs::read_dir(&corpus).expect("read_dir") {
        let entry = entry.expect("entry");
        let path = entry.path();
        if path.extension().is_some_and(|e| e == "x") {
            let stem = path.file_stem().unwrap().to_str().unwrap().to_string();
            let ir_path = corpus.join(format!("{stem}.ir"));
            let out_path = corpus.join(format!("{stem}.out"));
            if ir_path.exists() && out_path.exists() {
                cases.push(stem);
            }
        }
    }
    cases.sort();
    assert!(
        cases.len() >= 15,
        "expected at least 15 positive corpus cases, got {}",
        cases.len()
    );

    for stem in &cases {
        let ir_path = corpus.join(format!("{stem}.ir"));
        let out_path = corpus.join(format!("{stem}.out"));
        let in_path = corpus.join(format!("{stem}.in"));
        let ir = fs::read_to_string(&ir_path).expect("read ir");
        let expected = fs::read_to_string(&out_path).expect("read out");

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
        assert!(cgen_out.status.success(), "cgen failed for {stem}");
        assert!(
            !cgen_out.stdout.is_empty(),
            "cgen produced empty C for {stem}"
        );

        // Compile generated C → native executable
        let exe_path = tmp.join(stem);
        let c_path = tmp.join(format!("{stem}.c"));
        fs::write(&c_path, &cgen_out.stdout).expect("write C");
        let cc = Command::new(common::cc::cc())
            .args(["-o", exe_path.to_str().unwrap(), c_path.to_str().unwrap()])
            .output()
            .expect("cc");
        assert!(
            cc.status.success(),
            "cc failed for {stem}: {}",
            String::from_utf8_lossy(&cc.stderr)
        );

        // Run native executable (with input if .in exists)
        let run = Command::new(common::exe_path(&exe_path))
            .stdin(if in_path.exists() {
                std::process::Stdio::piped()
            } else {
                std::process::Stdio::null()
            })
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()
            .expect("spawn");
        let mut child = run;
        if in_path.exists() {
            if let Some(mut stdin) = child.stdin.take() {
                let input = fs::read_to_string(&in_path).expect("read in");
                stdin.write_all(input.as_bytes()).expect("write input");
            }
        }
        let out = child.wait_with_output().expect("wait");
        assert!(out.status.success(), "native {stem} failed");
        let native_output: String = out.stdout.iter().map(|&b| b as char).collect();

        assert_eq!(
            native_output, expected,
            "cgen-compiled {stem} output differs from golden .out"
        );

        let _ = fs::remove_file(&exe_path);
        let _ = fs::remove_file(&c_path);
    }

    let _ = fs::remove_file(&cgen_exe);
    let _ = fs::remove_file(&cgen_c_path);
    let _ = fs::remove_dir_all(&tmp);
}
