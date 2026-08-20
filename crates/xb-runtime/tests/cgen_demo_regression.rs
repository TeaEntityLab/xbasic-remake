//! CGEN-DEMO-REGRESSION (docs/17): a curated byte-faithfulness gate on the C
//! generator over legacy demo programs, locking the fixes that took the demo
//! sweep from 3 → 113/114 compiled and 36 → 70 byte-faithful.
//!
//! For each demo: lower via the Rust frontend, run the interpreter (the
//! reference), emit C via `CEmitter`, compile it with the same flags the CLI
//! uses, run the native binary on the same (empty) stdin, and require the
//! binary's stdout to equal the interpreter's byte-for-byte. This is the
//! automated form of the manual interp-vs-cgen differential sweep — without it,
//! a future emitter change could silently regress these demos.
//!
//! The list is curated for the cargo suite: every entry terminates quickly on
//! empty stdin (no GUI loop, no network wait) and is deterministic. Each demo
//! is annotated with the emitter feature it guards. `gif`/`Kittedy` produce no
//! output on empty stdin but still lock the *scalar/array dual-use* codegen
//! (a dual-use regression would fail to compile them).

mod common;

use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::{Command, Stdio};
use xb_compiler::{CEmitter, FrontendUnit};
use xb_runtime::Interpreter;

/// (demo stem, guarded feature) — see docs/17 §0 for the gap ids.
const DEMOS: &[(&str, &str)] = &[
    ("arotate", "unsigned-shift BIN$ helpers (CGEN-AROTATE)"),
    ("aback", "string-scalar UBOUND + NUL-safe literals"),
    ("atrim", "leading-zero decimal + NUL literals"),
    ("asystem", "$$ GIANT suffix + *AT memory stubs"),
    ("arecord", "composite member arrays (single hoist)"),
    ("atimer", "synthetic &Func ids"),
    ("gif", "scalar/array dual-use (local hash)"),
    ("Kittedy", "scalar/array dual-use (found)"),
];

/// Interpreter reference output for `source` on empty stdin.
fn interp_output(source: &str) -> String {
    let prog = FrontendUnit::parse(source)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let mut lines = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut lines)
        .expect("interp execute");
    lines.into_iter().map(|l| format!("{l}\n")).collect()
}

/// Compile `source` via `CEmitter` + cc (CLI flags) and run the binary on empty
/// stdin, returning its raw stdout. Panics with cc stderr on a compile failure.
fn cgen_output(source: &str, stem: &str, tmp: &Path) -> String {
    let prog = FrontendUnit::parse(source)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let c_src = CEmitter::new().emit_program(&prog);
    let c_path = tmp.join(format!("{stem}.c"));
    let exe = tmp.join(stem);
    fs::write(&c_path, &c_src).expect("write C");
    let cc = Command::new(common::cc::cc())
        .args([
            "-O0",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
            "-o",
            exe.to_str().unwrap(),
            c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc spawn");
    assert!(
        cc.status.success(),
        "cc failed for {stem}: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    let mut child = Command::new(common::exe_path(&exe))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .expect("spawn binary");
    // Empty stdin, closed immediately (matches the differential's `</dev/null`).
    drop(child.stdin.take());
    let out = child.wait_with_output().expect("wait binary");
    let _ = fs::remove_file(&c_path);
    let _ = fs::remove_file(&exe);
    out.stdout.iter().map(|&b| b as char).collect()
}

#[test]
fn cgen_matches_interpreter_on_curated_demos() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_cgen_demo_regression");
    fs::create_dir_all(&tmp).expect("mkdir");

    let mut failures = Vec::new();
    for (stem, feature) in DEMOS {
        let src_path = root.join(format!("xbasic-6.4.5/demo/{stem}.x"));
        let source = fs::read_to_string(&src_path)
            .unwrap_or_else(|e| panic!("read {}: {e}", src_path.display()));
        let interp = interp_output(&source);
        let native = cgen_output(&source, stem, &tmp);
        if native != interp {
            failures.push(format!(
                "{stem} ({feature}): cgen output differs from interpreter\n  \
                 interp={interp:?}\n  cgen  ={native:?}"
            ));
        }
    }
    assert!(
        failures.is_empty(),
        "cgen demo regression:\n{}",
        failures.join("\n")
    );
}
