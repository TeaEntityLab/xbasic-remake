//! Cross-generator sync between the Rust reference C emitter (`CEmitter`) and
//! the self-hosted C generator (`selfhost/cgen.x`).
//!
//! There are two independent implementations of the same IR -> C contract:
//!   * `CEmitter` (Rust, in `xb-compiler`) — the reference.
//!   * `cgen.x` (XBasic, in `selfhost/`) — the self-hosted generator that the
//!     native bootstrap actually ships.
//!
//! Every other cgen/bootstrap test checks ONE generator against the interpreter
//! or the golden output. Nothing pins the two generators to EACH OTHER, so they
//! can silently drift: a codegen rule fixed in one but not the other only breaks
//! a test if some corpus program happens to exercise it. These tests close that
//! gap by requiring both generators to agree, program-for-program.
//!
//! Sync is asserted on OBSERVABLE BEHAVIOR (native run output), not on the
//! emitted C text: the two generators' fixed runtime *preludes* are not yet
//! byte-identical (helper ordering/formatting and a few semantic helper diffs —
//! tracked in `docs/16-cgen-cemitter-sync-roadmap.md`, item CG-PRELUDE). Output
//! equivalence is the contract that actually governs a correct bootstrap.

mod common;

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use xb_compiler::{CEmitter, FrontendUnit, TextIrEmitter, TextIrParser};
use xb_runtime::Interpreter;

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

/// Build the native `cgen` executable from `selfhost/cgen.x` using the Rust
/// `CEmitter` (this is exactly how the native bootstrap seeds its C generator).
fn build_native_cgen(tmp: &Path) -> PathBuf {
    let cgen_src = fs::read_to_string(root().join("selfhost/cgen.x")).expect("read cgen.x");
    let cgen_prog = FrontendUnit::parse(&cgen_src)
        .expect("parse cgen.x")
        .lower_ir()
        .expect("lower cgen.x");
    let cgen_c = CEmitter::new().emit_program(&cgen_prog);
    let c_path = tmp.join("cgen.c");
    let exe = tmp.join("cgen");
    fs::write(&c_path, &cgen_c).expect("write cgen.c");
    let cc = Command::new(common::cc::cc())
        .args(["-o", exe.to_str().unwrap(), c_path.to_str().unwrap()])
        .output()
        .expect("run cc for cgen");
    assert!(
        cc.status.success(),
        "cc cgen failed: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    exe
}

/// Feed text IR to the native cgen on stdin; return the emitted C source bytes.
fn cgen_emit(cgen_exe: &Path, ir: &str) -> Vec<u8> {
    let mut child = Command::new(common::exe_path(cgen_exe))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("spawn cgen");
    child
        .stdin
        .take()
        .expect("cgen stdin")
        .write_all(ir.as_bytes())
        .expect("write IR to cgen");
    let out = child.wait_with_output().expect("wait cgen");
    assert!(
        out.status.success(),
        "cgen failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    out.stdout
}

/// Compile C source bytes to a native exe, run it with optional stdin, and
/// return stdout decoded byte-faithfully (matching how the goldens were made).
fn compile_and_exec(tmp: &Path, name: &str, c: &[u8], input: Option<&str>) -> String {
    let c_path = tmp.join(format!("{name}.c"));
    let exe = tmp.join(name);
    fs::write(&c_path, c).expect("write c");
    let cc = Command::new(common::cc::cc())
        .args(["-o", exe.to_str().unwrap(), c_path.to_str().unwrap()])
        .output()
        .expect("run cc");
    assert!(
        cc.status.success(),
        "cc {name} failed: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    let mut cmd = Command::new(common::exe_path(&exe));
    cmd.stdout(Stdio::piped()).stderr(Stdio::piped());
    cmd.stdin(if input.is_some() {
        Stdio::piped()
    } else {
        Stdio::null()
    });
    let mut child = cmd.spawn().expect("spawn native exe");
    if let Some(inp) = input {
        child
            .stdin
            .take()
            .expect("native stdin")
            .write_all(inp.as_bytes())
            .expect("write input");
    }
    let out = child.wait_with_output().expect("wait native exe");
    assert!(
        out.status.success(),
        "native {name} failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    out.stdout.iter().map(|&b| b as char).collect()
}

/// The Rust `CEmitter` and the self-hosted `cgen.x` must produce native
/// executables whose output is byte-identical to each other AND to the golden
/// `.out`, for every program in the positive corpus.
///
/// This simultaneously adds the previously-missing coverage of `CEmitter` over
/// the whole corpus (it was only ever run on one hand-written program) and the
/// direct cross-generator equality that locks the two backends together.
#[test]
fn cemitter_and_cgen_agree_on_positive_corpus() {
    let tmp = std::env::temp_dir().join("xb_sync_pos_corpus");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let corpus = root().join("fixtures/corpus/v0.1/positive");

    let mut cases: Vec<String> = Vec::new();
    for entry in fs::read_dir(&corpus).expect("read_dir positive corpus") {
        let path = entry.expect("dir entry").path();
        if path.extension().and_then(|e| e.to_str()) == Some("ir") {
            cases.push(
                path.file_stem()
                    .expect("stem")
                    .to_str()
                    .expect("utf8 stem")
                    .to_string(),
            );
        }
    }
    cases.sort();
    assert!(
        cases.len() >= 50,
        "expected the full positive corpus (>=50 cases), found {}",
        cases.len()
    );

    for stem in &cases {
        let ir = fs::read_to_string(corpus.join(format!("{stem}.ir"))).expect("read .ir");
        let golden = fs::read_to_string(corpus.join(format!("{stem}.out"))).expect("read .out");
        let in_path = corpus.join(format!("{stem}.in"));
        let input = if in_path.exists() {
            Some(fs::read_to_string(&in_path).expect("read .in"))
        } else {
            None
        };
        let input_ref = input.as_deref();

        // Rust CEmitter path: text IR -> IrProgram -> C -> native.
        let prog = TextIrParser::parse(&ir)
            .unwrap_or_else(|e| panic!("TextIrParser failed for {stem}: {e:?}"));
        let rust_c = CEmitter::new().emit_program(&prog);
        let rust_out = compile_and_exec(&tmp, &format!("{stem}_rust"), rust_c.as_bytes(), input_ref);

        // Self-hosted cgen.x path: text IR -> C (native cgen) -> native.
        let self_c = cgen_emit(&cgen_exe, &ir);
        let self_out = compile_and_exec(&tmp, &format!("{stem}_self"), &self_c, input_ref);

        assert_eq!(
            rust_out, golden,
            "CEmitter-built {stem} output differs from golden .out"
        );
        assert_eq!(
            self_out, golden,
            "cgen.x-built {stem} output differs from golden .out"
        );
        assert_eq!(
            rust_out, self_out,
            "SYNC BREAK: CEmitter and cgen.x disagree on {stem}"
        );
    }
    let _ = fs::remove_dir_all(&tmp);
}

/// The two generators must also agree on the self-hosting toolchain itself
/// (compiler, lexer, parser, cgen), and both must match the interpreter (the
/// semantic reference) on each tool's own input. This is the sync that directly
/// underwrites the bootstrap: whichever C backend seeds the native tools, the
/// tools behave identically.
#[test]
fn cemitter_and_cgen_agree_on_selfhost_tools() {
    let tmp = std::env::temp_dir().join("xb_sync_selfhost_tools");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    for tool in ["compiler", "lexer", "parser", "cgen"] {
        let src = fs::read_to_string(root().join(format!("selfhost/{tool}.x")))
            .unwrap_or_else(|e| panic!("read selfhost/{tool}.x: {e}"));
        let prog = FrontendUnit::parse(&src)
            .unwrap_or_else(|e| panic!("parse {tool}: {e:?}"))
            .lower_ir()
            .unwrap_or_else(|e| panic!("lower {tool}: {e:?}"));
        let ir = TextIrEmitter::new().emit_program(&prog);

        // Deterministic stdin: the tool's committed `.in` if present, else the
        // tool's own text IR (cgen consumes IR, so this is meaningful work).
        let in_path = root().join(format!("selfhost/{tool}.in"));
        let input = if in_path.exists() {
            fs::read_to_string(&in_path).expect("read .in")
        } else {
            ir.clone()
        };
        let input_lines: Vec<String> = input.lines().map(String::from).collect();

        let rust_c = CEmitter::new().emit_program(&prog);
        let rust_out =
            compile_and_exec(&tmp, &format!("{tool}_rust"), rust_c.as_bytes(), Some(&input));

        let self_c = cgen_emit(&cgen_exe, &ir);
        let self_out = compile_and_exec(&tmp, &format!("{tool}_self"), &self_c, Some(&input));

        let mut interp = Vec::new();
        Interpreter::new()
            .execute_main_with_input(&prog, input_lines, &mut interp)
            .unwrap_or_else(|e| panic!("interpret {tool}: {e:?}"));
        let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

        assert_eq!(
            rust_out, interp_out,
            "CEmitter-built {tool} differs from interpreter"
        );
        assert_eq!(
            self_out, interp_out,
            "cgen.x-built {tool} differs from interpreter"
        );
        assert_eq!(
            rust_out, self_out,
            "SYNC BREAK: CEmitter and cgen.x disagree on selfhost tool {tool}"
        );
    }
    let _ = fs::remove_dir_all(&tmp);
}
