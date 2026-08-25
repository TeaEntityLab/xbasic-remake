mod common;
use common::compile_and_run;
use sha2::{Digest, Sha256};
use std::fs;
use std::path::Path;
use xb_compiler::{TextIrEmitter, TextIrParser};
use xb_runtime::Interpreter;

/// Self-rebuild proof:
///
/// 1. Stage-1: Rust-hosted pipeline compiles compiler.x → text IR + runtime output
/// 2. Parse the Stage-1 text IR back into an IrProgram via TextIrParser
/// 3. Stage-2: Re-emit the parsed IrProgram → text IR
/// 4. Assert Stage-1 text IR == Stage-2 text IR (byte-exact)
/// 5. Assert SHA-256(Stage-1 IR) == SHA-256(Stage-2 IR)
/// 6. Execute the parsed IrProgram → runtime output
/// 7. Assert Stage-1 runtime output == Stage-2 runtime output (byte-exact)
#[test]
fn self_rebuild_compiler_x_produces_identical_ir_and_output() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let compiler_x = root.join("selfhost/compiler.x");
    let compiler_in = root.join("selfhost/compiler.in");

    // Stage-1: Rust-hosted pipeline
    let (stage1_ir, stage1_output, _) =
        compile_and_run(&compiler_x).expect("Stage-1 compile and run");

    // Stage-2: Parse text IR back into IrProgram
    let parsed_program =
        TextIrParser::parse(&stage1_ir).expect("parse Stage-1 text IR into IrProgram");

    // Re-emit parsed IrProgram as text IR
    let stage2_ir = TextIrEmitter::new().emit_program(&parsed_program);

    // Assert byte-exact IR equivalence
    assert_eq!(stage1_ir, stage2_ir, "Stage-1 and Stage-2 text IR differ");

    // Assert SHA-256 artifact equivalence
    let stage1_hash = {
        let mut h = Sha256::new();
        h.update(stage1_ir.as_bytes());
        h.finalize()
    };
    let stage2_hash = {
        let mut h = Sha256::new();
        h.update(stage2_ir.as_bytes());
        h.finalize()
    };
    assert_eq!(
        format!("{:x}", stage1_hash),
        format!("{:x}", stage2_hash),
        "SHA-256 hash mismatch between Stage-1 and Stage-2 IR"
    );

    // Stage-2 execution: run the parsed IrProgram through the interpreter
    let input = if compiler_in.exists() {
        common::byte_lines(&fs::read(&compiler_in).expect("read compiler.in"))
    } else {
        common::byte_lines(&fs::read(&compiler_x).expect("read compiler.x as input"))
    };
    let mut stage2_lines = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&parsed_program, input, &mut stage2_lines)
        .expect("Stage-2 execute");
    let stage2_output: String = stage2_lines
        .into_iter()
        .map(|line| format!("{line}\n"))
        .collect();

    // Assert byte-exact runtime output equivalence
    assert_eq!(
        stage1_output, stage2_output,
        "Stage-1 and Stage-2 runtime output differ"
    );
}

/// Behavioral equivalence over the frozen selfhost corpus.
/// Every selfhost .x file must produce identical IR and output
/// when compiled via Stage-1 (Rust pipeline) vs Stage-2 (parsed IR re-execution).
#[test]
fn self_rebuild_all_selfhost_corpus_identical() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let stems = ["compiler", "lexer", "parser", "xut_bootstrap_manifest"];

    for stem in &stems {
        let x_path = root.join(format!("selfhost/{stem}.x"));
        let in_path = root.join(format!("selfhost/{stem}.in"));

        // Stage-1
        let (stage1_ir, stage1_output, _) =
            compile_and_run(&x_path).unwrap_or_else(|e| panic!("{stem}: Stage-1 failed: {e}"));

        // Stage-2: parse + re-emit
        let parsed = TextIrParser::parse(&stage1_ir)
            .unwrap_or_else(|e| panic!("{stem}: parse IR failed: {e}"));
        let stage2_ir = TextIrEmitter::new().emit_program(&parsed);
        assert_eq!(stage1_ir, stage2_ir, "{stem}: IR mismatch");

        // Stage-2 execution
        let input: Vec<Vec<u8>> = if in_path.exists() {
            common::byte_lines(
                &fs::read(&in_path).unwrap_or_else(|e| panic!("{stem}: read .in failed: {e}")),
            )
        } else {
            common::byte_lines(
                &fs::read(&x_path).unwrap_or_else(|e| panic!("{stem}: read .x failed: {e}")),
            )
        };
        let mut stage2_lines = Vec::new();
        Interpreter::new()
            .execute_main_with_input(&parsed, input, &mut stage2_lines)
            .unwrap_or_else(|e| panic!("{stem}: Stage-2 execute failed: {e}"));
        let stage2_output: String = stage2_lines
            .into_iter()
            .map(|line| format!("{line}\n"))
            .collect();

        assert_eq!(stage1_output, stage2_output, "{stem}: output mismatch");
    }
}

/// Round-trip every positive corpus fixture through the text IR parser.
#[test]
fn self_rebuild_positive_corpus_round_trip() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let positive = root.join("fixtures/corpus/v0.1/positive");

    let entries = fs::read_dir(&positive).expect("read positive corpus");
    for entry in entries {
        let path = entry.expect("dir entry").path();
        if path.extension().is_some_and(|e| e == "x") {
            let source = fs::read_to_string(&path).expect("read source");
            let unit = xb_compiler::FrontendUnit::parse(&source).expect("parse");
            let program = unit.lower_ir().expect("lower");
            let stage1_ir = TextIrEmitter::new().emit_program(&program);
            let parsed = TextIrParser::parse(&stage1_ir).expect("parse text IR");
            let stage2_ir = TextIrEmitter::new().emit_program(&parsed);
            assert_eq!(stage1_ir, stage2_ir, "IR mismatch for {}", path.display());
        }
    }
}
