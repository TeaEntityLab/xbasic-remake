mod common;
use common::compile_and_run;
use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::Command;
use xb_compiler::{CEmitter, FrontendUnit, TextIrEmitter, TextIrParser};
use xb_runtime::Interpreter;

/// Compile a small XBasic program to C, compile the C with cc, run it,
/// and verify the output matches the interpreter's output.
#[test]
fn c_emit_produces_compilable_and_runnable_native_artifact() {
    let source = r#"VERSION "0.1"
FUNCTION Main
DIM i
DIM sum
sum = 0
FOR i = 1 TO 10
  sum = sum + i
NEXT i
PRINT sum
PRINT "hello world"
PRINT 42
END FUNCTION
"#;

    // Interpreter reference output
    let unit = FrontendUnit::parse(source).expect("parse");
    let program = unit.lower_ir().expect("lower");
    let mut interp_out = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut interp_out)
        .expect("execute");
    let interp_output: String = interp_out.into_iter().map(|l| format!("{l}\n")).collect();

    // C emission
    let c_source = CEmitter::new().emit_program(&program);
    assert!(!c_source.is_empty());
    assert!(c_source.contains("int main(void)"));
    assert!(c_source.contains("xb_user_Main"));

    // Write C to temp file, compile, run
    let tmp = std::env::temp_dir().join("xb_c_emit_test");
    fs::create_dir_all(&tmp).expect("mkdir");
    let c_path = tmp.join("test.c");
    let exe_path = tmp.join("test_exe");

    fs::write(&c_path, &c_source).expect("write C");
    let compile = Command::new(common::cc::cc())
        .args(["-o", exe_path.to_str().unwrap(), c_path.to_str().unwrap()])
        .output()
        .expect("cc");
    assert!(
        compile.status.success(),
        "cc failed:\n{}",
        String::from_utf8_lossy(&compile.stderr)
    );

    let run = Command::new(common::exe_path(&exe_path))
        .output()
        .expect("run");
    assert!(
        run.status.success(),
        "native exe failed: {}",
        String::from_utf8_lossy(&run.stderr)
    );
    let native_output = String::from_utf8_lossy(&run.stdout).to_string();

    // Clean up
    let _ = fs::remove_file(&c_path);
    let _ = fs::remove_file(&exe_path);

    assert_eq!(
        interp_output, native_output,
        "interpreter and native output differ\ninterpreter:\n{interp_output}\nnative:\n{native_output}"
    );
}

/// Full bootstrap: compiler.x → C → compile → run → verify output
/// matches the interpreter's output.
#[test]
fn full_bootstrap_compiler_x_to_native_executable() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let compiler_x = root.join("selfhost/compiler.x");
    let compiler_in = root.join("selfhost/compiler.in");

    // Interpreter reference
    let (_ir_text, interp_output, _) = compile_and_run(&compiler_x).expect("interpreter reference");

    // C emission from the IrProgram
    let source = fs::read_to_string(&compiler_x).expect("read compiler.x");
    let unit = FrontendUnit::parse(&source).expect("parse compiler.x");
    let program = unit.lower_ir().expect("lower compiler.x");
    let c_source = CEmitter::new().emit_program(&program);

    // Write, compile, run
    let tmp = std::env::temp_dir().join("xb_bootstrap_native");
    fs::create_dir_all(&tmp).expect("mkdir");
    let c_path = tmp.join("compiler.c");
    let exe_path = tmp.join("compiler_exe");

    fs::write(&c_path, &c_source).expect("write C");
    let compile = Command::new(common::cc::cc())
        .args([
            "-O0",
            "-o",
            exe_path.to_str().unwrap(),
            c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc");
    assert!(
        compile.status.success(),
        "cc failed:\n{}",
        String::from_utf8_lossy(&compile.stderr)
    );

    // Feed compiler.x as stdin to the native executable
    let input = if compiler_in.exists() {
        fs::read_to_string(&compiler_in).expect("read compiler.in")
    } else {
        fs::read_to_string(&compiler_x).expect("read compiler.x as input")
    };

    let run = Command::new(common::exe_path(&exe_path))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn");

    let mut child = run;
    if let Some(mut stdin) = child.stdin.take() {
        stdin.write_all(input.as_bytes()).expect("write stdin");
    }
    let output = child.wait_with_output().expect("wait");
    assert!(
        output.status.success(),
        "native compiler.x failed with exit code {:?}: {}",
        output.status.code(),
        String::from_utf8_lossy(&output.stderr)
    );
    let native_output = String::from_utf8_lossy(&output.stdout).to_string();

    // Clean up
    let _ = fs::remove_file(&c_path);
    let _ = fs::remove_file(&exe_path);

    // The native executable should produce the same text IR as the interpreter
    assert_eq!(
        interp_output, native_output,
        "interpreter and native compiler.x output differ\ninterpreter (first 500 chars):\n{}\nnative (first 500 chars):\n{}",
        &interp_output[..interp_output.len().min(500)],
        &native_output[..native_output.len().min(500)],
    );
}

/// Stage-2 native bootstrap: the native compiler executable rebuilds itself.
///
/// Stage-0 (Rust host): compiler.x → IR → C → cc → stage1_native_exe
/// Stage-1 (native):    stage1_native_exe < compiler.in → text IR output
/// Stage-2 (Rust host): parse text IR → IrProgram → C → cc → stage2_native_exe
/// Verify: stage2_native_exe < compiler.in → output identical to stage1_native_exe
#[test]
fn stage2_native_bootstrap_rebuilds_itself() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let compiler_x = root.join("selfhost/compiler.x");
    let compiler_in = root.join("selfhost/compiler.in");
    let input = if compiler_in.exists() {
        fs::read_to_string(&compiler_in).expect("read compiler.in")
    } else {
        fs::read_to_string(&compiler_x).expect("read compiler.x as input")
    };

    let tmp = std::env::temp_dir().join("xb_stage2_bootstrap");
    fs::create_dir_all(&tmp).expect("mkdir");

    // Stage-0: Rust host builds Stage-1 native executable
    let source = fs::read_to_string(&compiler_x).expect("read compiler.x");
    let unit = FrontendUnit::parse(&source).expect("parse");
    let program = unit.lower_ir().expect("lower");
    let c1 = CEmitter::new().emit_program(&program);
    let c1_path = tmp.join("stage1.c");
    let exe1_path = tmp.join("stage1_exe");
    fs::write(&c1_path, &c1).expect("write stage1.c");
    let cc1 = Command::new(common::cc::cc())
        .args([
            "-O0",
            "-o",
            exe1_path.to_str().unwrap(),
            c1_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc stage1");
    assert!(
        cc1.status.success(),
        "cc stage1 failed: {}",
        String::from_utf8_lossy(&cc1.stderr)
    );

    // Stage-1: native exe produces text IR
    let run1 = Command::new(common::exe_path(&exe1_path))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn stage1");
    let mut child1 = run1;
    if let Some(mut stdin) = child1.stdin.take() {
        stdin
            .write_all(input.as_bytes())
            .expect("write stdin stage1");
    }
    let out1 = child1.wait_with_output().expect("wait stage1");
    assert!(
        out1.status.success(),
        "stage1 native failed: {}",
        String::from_utf8_lossy(&out1.stderr)
    );
    let stage1_ir = String::from_utf8_lossy(&out1.stdout).to_string();
    assert!(!stage1_ir.is_empty(), "stage1 produced empty output");

    // Stage-2: parse stage1 text IR → IrProgram → C → cc → stage2 native exe
    let parsed = TextIrParser::parse(&stage1_ir).expect("parse stage1 IR");
    let c2 = CEmitter::new().emit_program(&parsed);
    let c2_path = tmp.join("stage2.c");
    let exe2_path = tmp.join("stage2_exe");
    fs::write(&c2_path, &c2).expect("write stage2.c");
    let cc2 = Command::new(common::cc::cc())
        .args([
            "-O0",
            "-o",
            exe2_path.to_str().unwrap(),
            c2_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc stage2");
    assert!(
        cc2.status.success(),
        "cc stage2 failed: {}",
        String::from_utf8_lossy(&cc2.stderr)
    );

    // Stage-2: native exe produces text IR
    let run2 = Command::new(common::exe_path(&exe2_path))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn stage2");
    let mut child2 = run2;
    if let Some(mut stdin) = child2.stdin.take() {
        stdin
            .write_all(input.as_bytes())
            .expect("write stdin stage2");
    }
    let out2 = child2.wait_with_output().expect("wait stage2");
    assert!(
        out2.status.success(),
        "stage2 native failed: {}",
        String::from_utf8_lossy(&out2.stderr)
    );
    let stage2_ir = String::from_utf8_lossy(&out2.stdout).to_string();

    // Clean up
    let _ = fs::remove_file(&c1_path);
    let _ = fs::remove_file(&exe1_path);
    let _ = fs::remove_file(&c2_path);
    let _ = fs::remove_file(&exe2_path);

    // Stage-2 output must match Stage-1 output (behavioral equivalence)
    assert_eq!(
        stage1_ir, stage2_ir,
        "Stage-1 and Stage-2 native output differ\nStage-1 (first 300):\n{}\nStage-2 (first 300):\n{}",
        &stage1_ir[..stage1_ir.len().min(300)],
        &stage2_ir[..stage2_ir.len().min(300)],
    );
}

/// Verify C emission round-trips through the text IR parser:
/// IrProgram → C (not round-tripped, but verify the IrProgram
/// that produced the C is identical to the parsed text IR).
#[test]
fn c_emit_preserves_ir_semantics() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let positive = root.join("fixtures/corpus/v0.1/positive");

    let entries = fs::read_dir(&positive).expect("read positive corpus");
    for entry in entries {
        let path = entry.expect("dir entry").path();
        if path.extension().is_some_and(|e| e == "x") {
            let source = fs::read_to_string(&path).expect("read source");
            let unit = FrontendUnit::parse(&source).expect("parse");
            let program = unit.lower_ir().expect("lower");
            let ir_text = TextIrEmitter::new().emit_program(&program);
            let parsed = TextIrParser::parse(&ir_text).expect("parse text IR");
            let c1 = CEmitter::new().emit_program(&program);
            let c2 = CEmitter::new().emit_program(&parsed);
            assert_eq!(c1, c2, "C mismatch for {}", path.display());
        }
    }
}
