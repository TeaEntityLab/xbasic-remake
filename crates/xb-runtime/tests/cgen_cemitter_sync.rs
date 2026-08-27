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
//! Sync is asserted on OBSERVABLE BEHAVIOR (native run output) for every test,
//! and — since CG-BYTES completed (docs/16) — the positive corpus additionally
//! asserts the two generators' emitted C is BYTE-IDENTICAL per program
//! (`cemitter_and_cgen_agree_on_positive_corpus`). Demo-scale C-text identity
//! is intentionally NOT asserted (de-scoped 2026-08-27; docs/17
//! CGEN-FACET-MANIFEST tracks the architectural route).

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

/// Compile C source bytes to a native exe, run it with optional raw stdin,
/// and return stdout bytes verbatim (no char-decode round trip).
fn compile_and_exec_bytes(tmp: &Path, name: &str, c: &[u8], input: Option<&[u8]>) -> Vec<u8> {
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
            .write_all(inp)
            .expect("write input");
    }
    let out = child.wait_with_output().expect("wait native exe");
    assert!(
        out.status.success(),
        "native {name} failed: {}",
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

/// Compile under `tmp`, then execute from an isolated working directory.
/// File-I/O programs must not see or mutate files from other test runs.
fn compile_and_exec_in(
    tmp: &Path,
    run_dir: &Path,
    name: &str,
    c: &[u8],
    input: Option<&str>,
) -> String {
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
    cmd.current_dir(run_dir)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .stdin(if input.is_some() {
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
        let rust_out =
            compile_and_exec(&tmp, &format!("{stem}_rust"), rust_c.as_bytes(), input_ref);

        // Self-hosted cgen.x path: text IR -> C (native cgen) -> native.
        let self_c = cgen_emit(&cgen_exe, &ir);
        let self_out = compile_and_exec(&tmp, &format!("{stem}_self"), &self_c, input_ref);

        // CG-BYTES (docs/16): the two generators emit byte-identical C for the
        // whole positive corpus — lock the text itself, not just the behavior.
        assert_eq!(
            rust_c.as_bytes(),
            &self_c[..],
            "CG-BYTES BREAK: emitted C text differs for {stem}"
        );

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

/// CGEN-DEMO-CC (docs/17): every demo compiles clean through the TRUE
/// self-hosted cgen.x (not the Rust CEmitter — `demo_parity` covers that).
/// This was previously verified only by manual session sweeps; a cgen.x
/// regression could drop demos without failing any test (panel 2026-08-27).
/// Compile-only: runnable parity for the curated subset lives in
/// `cgen_demo_regression`, and full runnable parity vs the interpreter is
/// `demo_parity`'s job on the CEmitter side.
#[test]
fn cgen_x_compiles_all_demos_cc_clean() {
    let tmp = std::env::temp_dir().join("xb_sync_cgen_demo_cc");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let demo_dir = root().join("xbasic-6.4.5/demo");

    let mut stems: Vec<String> = Vec::new();
    for entry in fs::read_dir(&demo_dir).expect("read_dir demos") {
        let path = entry.expect("dir entry").path();
        if path.extension().and_then(|e| e.to_str()) == Some("x") {
            stems.push(path.file_stem().unwrap().to_str().unwrap().to_string());
        }
    }
    stems.sort();
    assert!(
        stems.len() >= 100,
        "expected the full demo corpus (>=100), found {}",
        stems.len()
    );

    let mut failures: Vec<String> = Vec::new();
    for stem in &stems {
        let src = fs::read_to_string(demo_dir.join(format!("{stem}.x"))).expect("read demo");
        let prog = match FrontendUnit::parse(&src) {
            Ok(u) => match u.lower_ir() {
                Ok(p) => p,
                Err(e) => {
                    failures.push(format!("{stem}: lower failed: {e:?}"));
                    continue;
                }
            },
            Err(e) => {
                failures.push(format!("{stem}: parse failed: {e:?}"));
                continue;
            }
        };
        let ir = TextIrEmitter::new().emit_program_with_facets(&prog);
        let self_c = cgen_emit(&cgen_exe, &ir);
        let c_path = tmp.join(format!("{stem}.c"));
        let exe = tmp.join(stem.as_str());
        fs::write(&c_path, &self_c).expect("write c");
        let cc = Command::new(common::cc::cc())
            .args([
                "-O0",
                "-w",
                "-Werror=implicit-function-declaration",
                "-Wno-incompatible-pointer-types",
                "-Wno-int-conversion",
                "-o",
                exe.to_str().unwrap(),
                c_path.to_str().unwrap(),
            ])
            .output()
            .expect("run cc");
        if !cc.status.success() {
            let err = String::from_utf8_lossy(&cc.stderr);
            let first = err.lines().next().unwrap_or("");
            failures.push(format!("{stem}: cc failed: {first}"));
        }
    }
    assert!(
        failures.is_empty(),
        "cgen.x demo cc regression ({}): {:?}",
        failures.len(),
        failures
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Panel 2026-08-27 adoption guard: the load-bearing verification claims must
/// stay recorded at their named doc surfaces in the adopted wording, so a doc
/// edit cannot silently reintroduce the locked-vs-manual ambiguity this suite
/// resolves. (Candidate Adoption Ledger: docs/17.)
#[test]
fn docs_headline_claims_are_recorded_at_named_surfaces() {
    let readme = fs::read_to_string(root().join("README.md")).expect("read README");
    let d16 = fs::read_to_string(root().join("docs/16-cgen-cemitter-sync-roadmap.md"))
        .expect("read docs/16");
    let d17 =
        fs::read_to_string(root().join("docs/17-open-work-roadmap.md")).expect("read docs/17");
    for (surface, text, needle) in [
        (
            "README.md",
            &readme,
            "emit byte-identical C (locked by `cgen_cemitter_sync`)",
        ),
        (
            "README.md",
            &readme,
            "self-hosted `cgen.x` (`cgen_x_compiles_all_demos_cc_clean`)",
        ),
        ("docs/16", &d16, "identity are **locked by tests**"),
        ("docs/17", &d17, "Candidate Adoption Ledger"),
        (
            "docs/17",
            &d17,
            "The Rust CEmitter is class **(b) link-ready** for all 15 core libraries",
        ),
        (
            "docs/17",
            &d17,
            "compiled legacy-library bodies remain below class **(c) behavior-ready**",
        ),
        (
            "docs/17",
            &d17,
            "**GTK/helpsrc remain\n> parse/lower-only.**",
        ),
    ] {
        assert!(
            text.contains(needle),
            "{surface} lost the adopted wording: {needle:?}"
        );
    }
}

/// CGEN-NDIM: rank-3 *flat-storage* array access/assignment must flatten
/// row-major through both generators. cgen.x historically passed the third
/// index through to C's comma operator because `emit_flat2d$` consumed only
/// two indices. A 1-D DIM plus a multi-dimensional DIM forces the same flat
/// representation as adatadim's dual-use arrays.
#[test]
fn cemitter_and_cgen_agree_on_rank_three_flat_array() {
    let tmp = std::env::temp_dir().join("xb_sync_rank3_flat");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               AUTO cube[]\n\
               DIM cube[5]\n\
               DIM cube[1,2,3]\n\
               cube[1,2,3] = 123\n\
               cube[0,1,2] = 12\n\
               PRINT cube[1,2,3]\n\
               PRINT cube[0,1,2]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse rank-3 flat program")
        .lower_ir()
        .expect("lower rank-3 flat program");
    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("run interp rank-3 flat");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();
    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "rank3_flat_rust", rust_c.as_bytes(), None);
    let ir = TextIrEmitter::new().emit_program(&prog);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "rank3_flat_self", &self_c, None);
    assert_eq!(interp_out, "123\n12\n", "interpreter reference");
    assert_eq!(rust_out, interp_out, "Rust CEmitter rank-3 flat output");
    assert_eq!(self_out, interp_out, "cgen.x rank-3 flat output");
    let _ = fs::remove_dir_all(&tmp);
}

/// MODULE-DIM-SCOPE function-less corner: with zero functions, emit_module_dims
/// early-returns, so the module DIM must stay in main()'s body. The unconditional
/// emit_main filter dropped it (undeclared xb_var_a, cc failure).
#[test]
fn cemitter_and_cgen_agree_on_functionless_module_dim() {
    let tmp = std::env::temp_dir().join("xb_sync_nofn_moddim");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "VERSION \"0.1\"\n\
               DIM a[9]\n\
               PRINT a[0]\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse function-less program")
        .lower_ir()
        .expect("lower function-less program");
    let ir = TextIrEmitter::new().emit_program(&prog);
    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret function-less program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();
    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "nofn_rust", rust_c.as_bytes(), None);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "nofn_self", &self_c, None);
    assert_eq!(interp_out, "0\n", "interpreter reference");
    assert_eq!(
        rust_out, interp_out,
        "Rust CEmitter function-less module DIM"
    );
    assert_eq!(self_out, interp_out, "cgen.x function-less module DIM");
    let _ = fs::remove_dir_all(&tmp);
}

/// Fixed local arrays are zero-filled (interp slot semantics); the C emitters
/// declared them uninitialized, so reads-before-write returned stack garbage.
#[test]
fn cemitter_and_cgen_agree_on_fixed_array_zero_init() {
    let tmp = std::env::temp_dir().join("xb_sync_arrzero");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM a[9]\n\
               DIM m[3,4]\n\
               DIM i\n\
               FOR i = 0 TO 3\n\
               m[1,i] = i * 10\n\
               NEXT i\n\
               PRINT a[0]; \" \"; a[2]; \" \"; UBOUND(a[])\n\
               PRINT m[1,0]; \" \"; m[1,3]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse zero-init program")
        .lower_ir()
        .expect("lower zero-init program");
    let ir = TextIrEmitter::new().emit_program(&prog);
    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret zero-init program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();
    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "arrzero_rust", rust_c.as_bytes(), None);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "arrzero_self", &self_c, None);
    assert_eq!(interp_out, "0 0 9\n0 30\n", "interpreter reference");
    assert_eq!(rust_out, interp_out, "Rust CEmitter fixed-array zero-init");
    assert_eq!(self_out, interp_out, "cgen.x fixed-array zero-init");
    let _ = fs::remove_dir_all(&tmp);
}

/// SHARED-SCALAR: keyword `SHARED y` scalars share module-level storage — a
/// write in Main is visible in a callee that also declares `SHARED counter`,
/// and vice versa (classic BASIC). Previously the shared flag was discarded
/// for scalars, giving each function a fresh local.
#[test]
fn cemitter_and_cgen_agree_on_shared_scalar_keyword() {
    let tmp = std::env::temp_dir().join("xb_sync_shared_scalar");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "VERSION \"0.1\"\n\
               FUNCTION Show\n\
               SHARED counter\n\
               counter = counter + 5\n\
               RETURN counter\n\
               END FUNCTION\n\
               FUNCTION Main\n\
               SHARED counter\n\
               counter = 12\n\
               PRINT Show()\n\
               PRINT counter\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse shared-scalar program")
        .lower_ir()
        .expect("lower shared-scalar program");
    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("run interp shared-scalar");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();
    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "shsc_rust", rust_c.as_bytes(), None);
    let ir = TextIrEmitter::new().emit_program(&prog);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "shsc_self", &self_c, None);
    assert_eq!(interp_out, "17\n17\n", "interpreter reference");
    assert_eq!(rust_out, interp_out, "Rust CEmitter shared-scalar output");
    assert_eq!(self_out, interp_out, "cgen.x shared-scalar output");
    let _ = fs::remove_dir_all(&tmp);
}

/// RT-KERNEL32 (CGEN-KERNEL32): `GetStdHandle`/`WriteFile`/`ReadFile` — the
/// Win32-CGI stdio subset — must behave identically through the interpreter
/// and BOTH C generators. The legacy `&x` argument prefix lowers to a plain
/// symbol, so out-params take addresses positionally. (Trailing partial
/// writes are covered by `cemitter_and_cgen_agree_on_kernel32_partial_write`.)
#[test]
fn cemitter_and_cgen_agree_on_kernel32_stdio() {
    let tmp = std::env::temp_dir().join("xb_sync_kernel32");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "PROGRAM \"k32\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               ##h = GetStdHandle (-11)\n\
               out$ = \"hello-k32\" + CHR$ (10)\n\
               n = LEN (out$)\n\
               sent = 0\n\
               WriteFile (##h, &out$, n, &sent, 0)\n\
               PRINT sent\n\
               ##hin = GetStdHandle (-10)\n\
               buf$ = CHR$ (0, 32)\n\
               got = 0\n\
               ReadFile (##hin, &buf$, 32, &got, 0)\n\
               PRINT got\n\
               PRINT LEFT$ (buf$, got)\n\
               bad = GetStdHandle (7)\n\
               PRINT bad\n\
               END FUNCTION\n\
               END PROGRAM\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse kernel32 program")
        .lower_ir()
        .expect("lower kernel32 program");
    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, vec![b"POSTDATA-123".to_vec()], &mut interp)
        .expect("run interp kernel32");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();
    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "k32_rust", rust_c.as_bytes(), Some("POSTDATA-123"));
    let ir = TextIrEmitter::new().emit_program(&prog);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "k32_self", &self_c, Some("POSTDATA-123"));
    let expected = "hello-k32\n10\n12\nPOSTDATA-123\n-1\n";
    assert_eq!(interp_out, expected, "interpreter reference");
    assert_eq!(rust_out, expected, "Rust CEmitter kernel32 output");
    assert_eq!(self_out, expected, "cgen.x kernel32 output");
    let _ = fs::remove_dir_all(&tmp);
}

/// RT-IO-BYTES closed: (1) a kernel32 WriteFile WITHOUT a trailing LF must
/// splice into the output stream so a following PRINT continues the same C
/// output line; (2) high-byte stdin must reach INLINE$ byte-faithfully
/// (LEN counts raw bytes, first byte accessible via `{}` byte access).
#[test]
fn cemitter_and_cgen_agree_on_kernel32_partial_write() {
    let tmp = std::env::temp_dir().join("xb_sync_k32_partial");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "PROGRAM \"pw\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               ##h = GetStdHandle (-11)\n\
               part$ = \"AB\" + CHR$ (255) + \"C\"\n\
               sent = 0\n\
               WriteFile (##h, &part$, LEN (part$), &sent, 0)\n\
               PRINT \"X\"\n\
               PRINT sent\n\
               ##hin = GetStdHandle (-10)\n\
               buf$ = CHR$ (0, 32)\n\
               got = 0\n\
               ReadFile (##hin, &buf$, 32, &got, 0)\n\
               PRINT got\n\
               PRINT buf${0}\n\
               END FUNCTION\n\
               END PROGRAM\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse partial-write program")
        .lower_ir()
        .expect("lower partial-write program");
    let stdin_bytes: Vec<Vec<u8>> = vec![vec![b'A', 0xff, b'B']];
    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, stdin_bytes, &mut interp)
        .expect("run interp partial write");
    let interp_out: Vec<u8> = interp
        .into_iter()
        .flat_map(|l| {
            // Output entries are byte-faithful: chars 0-255 map 1:1 to bytes.
            let mut b = l.chars().map(|c| c as u8).collect::<Vec<u8>>();
            b.push(b'\n');
            b
        })
        .collect();
    let rust_c = CEmitter::new().emit_program(&prog);
    // LF-free stdin: the interp input channel is line-based (a trailing LF
    // is not representable — the one remaining RT-IO-BYTES boundary).
    let raw_stdin: &[u8] = &[b'A', 0xff, b'B'];
    let rust_out = compile_and_exec_bytes(&tmp, "pw_rust", rust_c.as_bytes(), Some(raw_stdin));
    let ir = TextIrEmitter::new().emit_program(&prog);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec_bytes(&tmp, "pw_self", &self_c, Some(raw_stdin));
    let expected = b"AB\xffCX\n4\n3\n65\n".to_vec();
    assert_eq!(interp_out, expected, "interpreter reference (bytes)");
    assert_eq!(rust_out, expected, "Rust CEmitter partial-write output");
    assert_eq!(self_out, expected, "cgen.x partial-write output");
    let _ = fs::remove_dir_all(&tmp);
}

/// CGEN-DIM-DEDUP: an identical repeated native array DIM is one C
/// declaration (Kittedy's duplicate `shuffle[uBlocks]`), but repeated DIM of
/// a heap-backed/dynamic array is executable and resets/re-sizes the slot.
#[test]
fn cemitter_and_cgen_agree_on_array_dim_dedup_boundary() {
    let tmp = std::env::temp_dir().join("xb_sync_dim_dedup_boundary");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM fixed[2]\n\
               DIM fixed[2]\n\
               fixed[1] = 9\n\
               DIM dyn\n\
               DIM dyn[0]\n\
               dyn[0] = 7\n\
               DIM dyn[2]\n\
               PRINT fixed[1]\n\
               PRINT dyn[0]\n\
               PRINT UBOUND(dyn[])\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse DIM dedup boundary program")
        .lower_ir()
        .expect("lower DIM dedup boundary program");
    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("run interp DIM dedup boundary");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();
    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "dim_dedup_rust", rust_c.as_bytes(), None);
    let ir = TextIrEmitter::new().emit_program(&prog);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "dim_dedup_self", &self_c, None);
    assert_eq!(interp_out, "9\n0\n2\n", "interpreter reference");
    assert_eq!(rust_out, interp_out, "Rust CEmitter DIM lifecycle");
    assert_eq!(self_out, interp_out, "cgen.x DIM dedup/lifecycle boundary");
    let _ = fs::remove_dir_all(&tmp);
}

/// Record file I/O: WRITE/READ `[handle], record[]` lower to the internal
/// `__WRITE_RECORD` / `__READ_RECORD` calls. Both C generators must preserve
/// their side effects: WR creates/truncates the file, write appends the logical
/// record byte count and flushes, read advances by that count, and LOF/POF
/// expose the resulting size/position. Payload bytes are intentionally zeroed
/// and discarded, matching the interpreter's bounded placeholder semantics.
#[test]
fn cemitter_and_cgen_agree_on_record_file_io() {
    let tmp = std::env::temp_dir().join("xb_sync_record_io");
    let rust_dir = tmp.join("rust");
    let self_dir = tmp.join("self");
    fs::create_dir_all(&rust_dir).expect("mkdir rust record dir");
    fs::create_dir_all(&self_dir).expect("mkdir self record dir");
    let cgen_exe = build_native_cgen(&tmp);
    let src = "VERSION \"1\"\n\
               TYPE REC\n\
               INT .x\n\
               END TYPE\n\
               FUNCTION Main\n\
               REC r[]\n\
               DIM r[0]\n\
               f = OPEN(\"record.dat\", $$WR)\n\
               IF f > 2 THEN WRITE [f], r[]\n\
               CLOSE(f)\n\
               g = OPEN(\"record.dat\", $$RD)\n\
               PRINT LOF(g)\n\
               IF g > 2 THEN READ [g], r[]\n\
               PRINT POF(g)\n\
               CLOSE(g)\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse record I/O program")
        .lower_ir()
        .expect("lower record I/O program");
    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec_in(&tmp, &rust_dir, "record_rust", rust_c.as_bytes(), None);
    let ir = TextIrEmitter::new().emit_program(&prog);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec_in(&tmp, &self_dir, "record_self", &self_c, None);
    assert_eq!(rust_out, "4\n4\n", "Rust record I/O reference");
    assert_eq!(self_out, rust_out, "cgen.x record I/O side effects");
    assert_eq!(fs::metadata(rust_dir.join("record.dat")).unwrap().len(), 4);
    assert_eq!(fs::metadata(self_dir.join("record.dat")).unwrap().len(), 4);
    let _ = fs::remove_dir_all(&tmp);
}

/// OPEN mode decoding: the documented base values (0..4, 0x10/0x20/0x30)
/// select access/create/truncate semantics, while 0x800 NONBLOCK is orthogonal.
/// Unsupported bases fall back to read-only existing-file behavior. Each path
/// uses absolute backend-private files so execution is isolated without chdir.
#[test]
fn cemitter_and_cgen_agree_on_open_mode_matrix() {
    let tmp = std::env::temp_dir().join("xb_sync_open_modes");
    let interp_dir = tmp.join("interp");
    let rust_dir = tmp.join("rust");
    let self_dir = tmp.join("self");
    for dir in [&interp_dir, &rust_dir, &self_dir] {
        fs::create_dir_all(dir).expect("mkdir OPEN mode dir");
    }
    let cgen_exe = build_native_cgen(&tmp);
    let run = |dir: &Path, tag: &str, cgen: Option<&Path>| -> String {
        let p = |name: &str| dir.join(format!("{tag}_{name}"));
        for name in [
            "rd", "wr", "rw", "wrnew", "rwnew", "rdshare", "wrshare", "rwshare", "nbwr", "nbrw",
            "invalid",
        ] {
            fs::write(p(name), b"abc").expect("seed OPEN mode file");
        }
        let q = |path: &Path| path.to_string_lossy().replace('\\', "\\\\");
        let src = format!(
            "VERSION \"1\"\nFUNCTION Main\n\
             f = OPEN(\"{}\", 0) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 1) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 2) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 3) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 4) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x10) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x20) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x30) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x801) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x802) : PRINT LOF(f) : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x123) : PRINT LOF(f) : CLOSE(f)\n\
             PRINT OPEN(\"{}\", 0)\n\
             PRINT OPEN(\"{}\", 0x10)\n\
             f = OPEN(\"{}\", 0x20) : PRINT f : CLOSE(f)\n\
             f = OPEN(\"{}\", 0x30) : PRINT f : CLOSE(f)\n\
             END FUNCTION\n",
            q(&p("rd")),
            q(&p("wr")),
            q(&p("rw")),
            q(&p("wrnew")),
            q(&p("rwnew")),
            q(&p("rdshare")),
            q(&p("wrshare")),
            q(&p("rwshare")),
            q(&p("nbwr")),
            q(&p("nbrw")),
            q(&p("invalid")),
            q(&p("missing_rd")),
            q(&p("missing_rdshare")),
            q(&p("create_wrshare")),
            q(&p("create_rwshare")),
        );
        let prog = FrontendUnit::parse(&src)
            .expect("parse OPEN mode matrix")
            .lower_ir()
            .expect("lower OPEN mode matrix");
        if let Some(cgen_exe) = cgen {
            let ir = TextIrEmitter::new().emit_program(&prog);
            let c = cgen_emit(cgen_exe, &ir);
            compile_and_exec(&tmp, &format!("open_{tag}"), &c, None)
        } else if tag == "rust" {
            let c = CEmitter::new().emit_program(&prog);
            compile_and_exec(&tmp, "open_rust", c.as_bytes(), None)
        } else {
            let mut output = Vec::new();
            Interpreter::new()
                .execute_main_with_input(&prog, Vec::new(), &mut output)
                .expect("interpret OPEN mode matrix");
            output.into_iter().map(|line| format!("{line}\n")).collect()
        }
    };
    let interp_out = run(&interp_dir, "interp", None);
    let rust_out = run(&rust_dir, "rust", None);
    let self_out = run(&self_dir, "self", Some(&cgen_exe));
    // Handles are monotonic; missing read-only opens do not consume handles.
    let expected = "3\n0\n3\n0\n0\n3\n3\n3\n0\n3\n3\n-1\n-1\n14\n15\n";
    assert_eq!(interp_out, expected, "interpreter OPEN matrix reference");
    assert_eq!(rust_out, interp_out, "Rust CEmitter OPEN mode matrix");
    assert_eq!(self_out, interp_out, "cgen.x OPEN mode matrix");
    assert!(!interp_dir.join("interp_missing_rd").exists());
    assert!(!rust_dir.join("rust_missing_rd").exists());
    assert!(!self_dir.join("self_missing_rd").exists());
    assert!(interp_dir.join("interp_create_wrshare").exists());
    assert!(rust_dir.join("rust_create_wrshare").exists());
    assert!(self_dir.join("self_create_wrshare").exists());
    let _ = fs::remove_dir_all(&tmp);
}

#[cfg(unix)]
fn run_c_with_timeout(tmp: &Path, name: &str, c: &[u8], timeout: std::time::Duration) -> String {
    let c_path = tmp.join(format!("{name}.c"));
    let exe = tmp.join(name);
    fs::write(&c_path, c).expect("write C");
    let cc = Command::new(common::cc::cc())
        .args(["-o", exe.to_str().unwrap(), c_path.to_str().unwrap()])
        .output()
        .expect("cc");
    assert!(
        cc.status.success(),
        "cc {name}: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    let mut child = Command::new(common::exe_path(&exe))
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("spawn");
    let deadline = std::time::Instant::now() + timeout;
    loop {
        if child.try_wait().expect("try_wait").is_some() {
            let out = child.wait_with_output().expect("collect output");
            assert!(
                out.status.success(),
                "{name}: {}",
                String::from_utf8_lossy(&out.stderr)
            );
            return out.stdout.iter().map(|&b| b as char).collect();
        }
        if std::time::Instant::now() >= deadline {
            let _ = child.kill();
            let _ = child.wait();
            panic!("{name} blocked opening a FIFO with $$NONBLOCK");
        }
        std::thread::sleep(std::time::Duration::from_millis(20));
    }
}

/// NONBLOCK must reach Unix `open(2)`, not merely be stripped before mode
/// decoding. Opening a FIFO for read with no writer would block forever without
/// O_NONBLOCK; both generated-C runtimes must return immediately.
#[cfg(unix)]
#[test]
fn cemitter_and_cgen_apply_nonblock_to_fifo() {
    use std::ffi::CString;
    use std::os::unix::ffi::OsStrExt;
    let tmp = std::env::temp_dir().join("xb_sync_open_nonblock_fifo");
    fs::create_dir_all(&tmp).expect("mkdir fifo test");
    let cgen_exe = build_native_cgen(&tmp);
    let check = |tag: &str, cgen: Option<&Path>| {
        let fifo = tmp.join(format!("{tag}.fifo"));
        let c_fifo = CString::new(fifo.as_os_str().as_bytes()).unwrap();
        // A prior crashed run can leave the FIFO behind - remove stale first.
        let _ = std::fs::remove_file(&fifo);
        let rc = unsafe { libc::mkfifo(c_fifo.as_ptr(), 0o600) };
        assert_eq!(rc, 0, "mkfifo {tag}: {}", std::io::Error::last_os_error());
        let path = fifo.to_string_lossy().replace('\\', "\\\\");
        let src = format!("VERSION \"1\"\nFUNCTION Main\nf = OPEN(\"{path}\", 0x800)\nPRINT f\nCLOSE(f)\nEND FUNCTION\n");
        let prog = FrontendUnit::parse(&src)
            .expect("parse FIFO OPEN")
            .lower_ir()
            .expect("lower FIFO OPEN");
        let c = if let Some(cgen_exe) = cgen {
            cgen_emit(cgen_exe, &TextIrEmitter::new().emit_program(&prog))
        } else {
            CEmitter::new().emit_program(&prog).into_bytes()
        };
        let out = run_c_with_timeout(
            &tmp,
            &format!("fifo_{tag}"),
            &c,
            std::time::Duration::from_secs(3),
        );
        assert_eq!(out, "3\n");
        let _ = fs::remove_file(fifo);
    };
    check("rust", None);
    check("self", Some(&cgen_exe));
    let _ = fs::remove_dir_all(&tmp);
}

/// CG-BYTESTRING: `CHR$(0)`, embedded, and high bytes must survive concat / LEN /
/// PRINT byte-for-byte through BOTH C generators and match the interpreter. The
/// pre-fix C `char*` null-terminated representation truncated at the first NUL;
/// this pins the length-prefixed byte-string representation in both generators.
#[test]
fn cemitter_and_cgen_agree_on_embedded_nul_strings() {
    let tmp = std::env::temp_dir().join("xb_sync_nul");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM s$\n\
               s$ = \"AB\" + CHR$(0) + \"CD\"\n\
               PRINT LEN(s$)\n\
               PRINT s$\n\
               PRINT LEN(CHR$(0))\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse embedded-nul program")
        .lower_ir()
        .expect("lower embedded-nul program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "nul_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "nul_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret embedded-nul program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // The NUL byte (0x00) sits between AB and CD; LEN is 5 (not 4), and
    // LEN(CHR$(0)) is 1 (not 0) — i.e. no truncation at the first NUL.
    assert_eq!(interp_out, "5\nAB\u{0}CD\n1\n", "interpreter reference");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter dropped/truncated the embedded NUL"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x dropped/truncated the embedded NUL"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// CGEN-GOSUB-SCOPE (per-function `xb_gosub_base`): a function's bare `RETURN`
/// reached while a *caller's* GOSUB frame is still active must NOT pop the caller's
/// frame. Without a per-function base, the callee's `RETURN` did
/// `goto *xb_gosub_stack[0]` into the *caller's* label — a cross-function computed
/// goto → jump-to-null crash. cgen.x now captures `int xb_gosub_base = xb_gosub_sp`
/// at each gosub-using function's entry and pops only while `sp > base`. This fix
/// (with the byref-dual `_arr` split + a non-zero `TYPE`) flipped `aarray`
/// (differential faithful 98→100). The self-host corpus uses no GOSUB, so the
/// byte-identity sync above never exercised it — this repro does.
#[test]
fn cemitter_and_cgen_agree_on_cross_function_gosub_return() {
    let tmp = std::env::temp_dir().join("xb_sync_gosub");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    // Main GOSUBs L1 (frame active), L1 calls B(); B's bare RETURN is reached with
    // Main's GOSUB frame on the stack. Pre-fix, B's RETURN cross-function-jumped and
    // crashed; post-fix (base captured in B) it returns normally.
    let src = "VERSION \"0.1\"\n\
               DECLARE FUNCTION B ()\n\
               FUNCTION Main\n\
               GOSUB L1\n\
               PRINT \"end\"\n\
               RETURN\n\
               L1:\n\
               B ()\n\
               PRINT \"L1\"\n\
               RETURN\n\
               END FUNCTION\n\
               FUNCTION B ()\n\
               RETURN\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse gosub program")
        .lower_ir()
        .expect("lower gosub program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "gosub_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "gosub_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret gosub program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "L1\nend\n", "interpreter reference");
    assert_eq!(rust_out, interp_out, "CEmitter cross-function gosub-return");
    assert_eq!(
        self_out, interp_out,
        "cgen.x cross-function gosub-return (per-function xb_gosub_base)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// CG-BODY-COVER: true high bytes (`0x80`–`0xFF`) must survive concat / LEN / PRINT
/// byte-for-byte through BOTH C generators. The interpreter's `Vec<String>` output
/// sink is UTF-8-lossy for high bytes, so it is *not* the reference here — the
/// byte-faithful C backends are the correct XBasic behavior, and this pins them to
/// each other (the corpus never exercises high bytes, so drift here was uncaught).
#[test]
fn cemitter_and_cgen_agree_on_high_byte_strings() {
    let tmp = std::env::temp_dir().join("xb_sync_hi");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM s$\n\
               s$ = CHR$(200) + CHR$(255)\n\
               PRINT LEN(s$)\n\
               PRINT s$\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse high-byte program")
        .lower_ir()
        .expect("lower high-byte program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "hi_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "hi_self", &self_c, None);

    // LEN is 2 (two raw bytes), then bytes 0xC8 0xFF verbatim — no UTF-8 mangling,
    // no NUL truncation. `compile_and_exec` decodes each output byte as a char.
    let expected = "2\n\u{C8}\u{FF}\n";
    assert_eq!(rust_out, expected, "CEmitter corrupted high bytes");
    assert_eq!(
        self_out, rust_out,
        "cgen.x diverged from CEmitter on high bytes"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// CG-BODY-COVER: computed `GOTO <expr>` (`GotoExpr`) — the bootstrap-critical
/// computed-jump path in `c_emit_goto.rs` — had no behavioral corpus coverage
/// (`computed_gosub_test` exercises `GosubExpr`, but nothing exercised `GotoExpr`,
/// and `GOADDRESS` was likewise never behaviorally run). A deterministic
/// `GOADDRESS(label)` → `GOTO addr` selects a target by control flow, so the
/// output is stable (which label ran) even though the raw address is not printed.
/// This locks both C generators (and the interpreter) to the same computed-GOTO
/// dispatch — the same machinery the self-hosted tools rely on.
#[test]
fn cemitter_and_cgen_agree_on_computed_goto() {
    let tmp = std::env::temp_dir().join("xb_sync_cgoto");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM addr\n\
               DIM sel\n\
               sel = 2\n\
               IF sel = 1 THEN\n\
               addr = GOADDRESS(PathA)\n\
               ELSE\n\
               addr = GOADDRESS(PathB)\n\
               END IF\n\
               GOTO addr\n\
               PathA:\n\
               PRINT \"path A\"\n\
               GOTO Done\n\
               PathB:\n\
               PRINT \"path B\"\n\
               GOTO Done\n\
               Done:\n\
               PRINT \"done\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse computed-goto program")
        .lower_ir()
        .expect("lower computed-goto program");
    let ir = TextIrEmitter::new().emit_program(&prog);
    assert!(
        ir.contains("goto_expr"),
        "fixture must exercise GotoExpr (computed GOTO); IR was:\n{ir}"
    );

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "cgoto_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "cgoto_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret computed-goto program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // sel = 2 selects PathB by computed jump, then falls to Done.
    assert_eq!(interp_out, "path B\ndone\n", "interpreter reference");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter computed-GOTO dispatch differs"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x computed-GOTO dispatch differs"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// CG-BODY-COVER: an *AT-write lvalue* (`XLONGAT(addr) = <expr>`, a `BuiltinAssign`)
/// had no behavioral coverage, and cgen.x's dispatch never fired (`LEFT$(s$, 15)`
/// vs the 14-char `"builtin_assign"`), so the self-hosted generator silently
/// dropped the whole statement — skipping the value's side effects. Both C
/// generators (and the interpreter) must no-op the memory write but still evaluate
/// the value: a side-effecting `Side()` RHS makes the drop observable. Locks the
/// `(void)(value)` contract across interp == CEmitter == cgen.x.
#[test]
fn cemitter_and_cgen_agree_on_builtin_assign() {
    let tmp = std::env::temp_dir().join("xb_sync_builtin_assign");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM addr\n\
               addr = 0\n\
               XLONGAT(addr) = Side()\n\
               PRINT \"done\"\n\
               END FUNCTION\n\
               FUNCTION Side()\n\
               PRINT \"side effect\"\n\
               RETURN 1\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse builtin-assign program")
        .lower_ir()
        .expect("lower builtin-assign program");
    let ir = TextIrEmitter::new().emit_program(&prog);
    assert!(
        ir.contains("builtin_assign"),
        "fixture must exercise BuiltinAssign (AT-write lvalue); IR was:\n{ir}"
    );

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "ba_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "ba_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret builtin-assign program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // The AT-write no-ops, but Side() (the value) must still run for its side effect.
    assert_eq!(interp_out, "side effect\ndone\n", "interpreter reference");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter dropped the AT-write value side effect"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x dropped the AT-write value side effect"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// CG-BODY-COVER: unary `+` (`pos`), `SIZE(TYPE)` (`size_of_type`), and `SIZE(var)`
/// (`size_of`, scalar + array) — the last IR tokens without positive-corpus
/// coverage. All are faithful across the three backends. `SIZE(var)` reports the
/// *logical* XLONG element size (integer = 4), matching the interpreter and
/// `SIZE(XLONG)`: the C backends previously emitted `sizeof(intptr_t)` = 8 — a bug,
/// inconsistent with the 32-bit XLONG arithmetic they already perform — now fixed
/// to element-count * logical size (`SIZE(x)=4`, `SIZE(int a[3])=16`).
#[test]
fn cemitter_and_cgen_agree_on_unary_pos_and_size() {
    let tmp = std::env::temp_dir().join("xb_sync_pos_size");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM x\n\
               x = 7\n\
               PRINT +x\n\
               PRINT SIZE(XLONG)\n\
               PRINT SIZE(DOUBLE)\n\
               PRINT SIZE(x)\n\
               DIM a[3]\n\
               PRINT SIZE(a)\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse pos/size program")
        .lower_ir()
        .expect("lower pos/size program");
    let ir = TextIrEmitter::new().emit_program(&prog);
    assert!(
        ir.contains("pos(") && ir.contains("size_of_type") && ir.contains("size_of("),
        "fixture must exercise unary pos + SizeOfType + SizeOf(var); IR was:\n{ir}"
    );

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "psz_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "psz_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret pos/size program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // +7=7; SIZE(XLONG)=4; SIZE(DOUBLE)=8; SIZE(x:int)=4; SIZE(int a[3])=16 (4 elems x 4).
    assert_eq!(interp_out, "7\n4\n8\n4\n16\n", "interpreter reference");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter diverged on unary pos / SIZE"
    );
    assert_eq!(self_out, interp_out, "cgen.x diverged on unary pos / SIZE");
    let _ = fs::remove_dir_all(&tmp);
}

/// A bare i32-overflowing literal (`2147483648` = 2^31) is typed Giant on the
/// *direct* analyzer path, but the text IR emits it as `integer(2147483648)` with
/// no Giant marker, and `TextIrParser` re-types it Integer. So BOTH C generators,
/// consuming the text IR, narrow it identically — this pins that they agree with
/// each OTHER (the sync contract). (The interpreter uses the direct path and keeps
/// the Giant, so it is intentionally not the reference here — that gap is the
/// separate open GIANT-LITERAL sub-bug (1), a text-IR type-loss, not a sync break.)
#[test]
fn cemitter_and_cgen_agree_on_giant_literal() {
    let tmp = std::env::temp_dir().join("xb_sync_giant_literal");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               PRINT 2147483648\n\
               PRINT 2147483648 + 1\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse giant-literal program")
        .lower_ir()
        .expect("lower giant-literal program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    // Rust CEmitter via the TEXT IR path (parse -> emit), the same input cgen.x sees.
    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "gl_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "gl_self", &self_c, None);

    assert_eq!(
        rust_out, self_out,
        "CEmitter and cgen.x disagree on a Giant literal via the text IR (sync drift)"
    );
}

/// Float arithmetic must be typed Float (printed via `xb_print_float`), not Integer.
/// cgen.x's `expr_type$` arith arm previously returned "integer" for every
/// non-string-concat arith, so `1.0 / 3.0` went through `xb_print_int` and truncated
/// to `0` instead of `0.3333333333333333` — a real cgen.x-vs-CEmitter drift (and
/// interp gap). cgen.x now mirrors Rust's `infer_arith_type` (Float when either
/// operand is Float; `\`/`mod` stay Integer). Locks all three backends.
#[test]
fn cemitter_and_cgen_agree_on_float_arith() {
    let tmp = std::env::temp_dir().join("xb_sync_float_arith");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               PRINT 1.0 / 3.0\n\
               PRINT 5.0 * 2.5\n\
               PRINT 10.0 - 0.5\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse float-arith program")
        .lower_ir()
        .expect("lower float-arith program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "fa_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "fa_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret float-arith program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert!(
        interp_out.starts_with("0.333"),
        "1.0 / 3.0 must be float 0.333..., not truncated to 0: {interp_out:?}"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x float-arith typing differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "float-arith typing differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Multi-dimensional arrays (CGEN-MULTIDIM): the self-hosted cgen.x previously
/// emitted invalid C for any `DIM a[d0,d1]` — it fed the whole comma-separated
/// dim/index list to `emit_expr$` as ONE expression (`xb_var_a[(3),integer(3) + 1]`),
/// which cc rejects (`expected ']'`). Fixed via `emit_msub$`: a paren-depth-aware
/// split (like `emit_args$`, so a call index `Add(1, 2)` isn't split on its inner
/// comma) that emits one native C bracket per dimension — Dim `a[(d0)+1][(d1)+1]`,
/// access/assign `a[i][j]` — matching the interpreter's row-major `a[i,j]`. A single
/// dimension reproduces the historical 1-D emission byte-for-byte (selfhost/v0.1 are
/// all 1-D, so sync + the bootstrap fixed point are unaffected). cgen.x's native
/// multi-dim C differs byte-wise from CEmitter's flattened `a[i*(d1+1)+j]` (a CG-BYTES
/// gap), so this is a BEHAVIORAL lock across all three backends, not byte-identity.
#[test]
fn cemitter_and_cgen_agree_on_multidim_array() {
    let tmp = std::env::temp_dir().join("xb_sync_multidim");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    // 2-D and 3-D integer arrays; one index is a 2-arg call (`Add(1, 2)`) to
    // exercise the paren-aware comma split (a naive split would break on it).
    let src = "VERSION \"0.1\"\n\
               DECLARE FUNCTION Add (x, y)\n\
               FUNCTION Main\n\
               DIM a[9, 9]\n\
               DIM c[2, 3, 4]\n\
               a[Add(1, 2), 3] = 7\n\
               a[2, 1] = 9\n\
               c[1, 2, 3] = 42\n\
               PRINT a[3, 3] + a[2, 1]\n\
               PRINT c[1, 2, 3]\n\
               END FUNCTION\n\
               FUNCTION Add (x, y)\n\
               RETURN x + y\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse multidim program")
        .lower_ir()
        .expect("lower multidim program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "md_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "md_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret multidim program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "16\n42\n", "multidim reference output");
    assert_eq!(
        rust_out, self_out,
        "cgen.x multi-dim differs from CEmitter (sync drift)"
    );
    assert_eq!(rust_out, interp_out, "multi-dim differs from interpreter");
    let _ = fs::remove_dir_all(&tmp);
}

/// Undeclared-local hoisting (CGEN-SELFHOST-PARITY): XBasic auto-declares a scalar
/// on first use. The Rust CEmitter hoists such locals (`c_emit_hoist.rs`), but the
/// self-hosted cgen.x had NO hoisting, so a demo like `i = 5 : PRINT i` (no DIM)
/// emitted an undeclared `xb_var_i` -> cc error; cgen.x compiled only the selfhost
/// tools (which DIM every local). cgen.x now mirrors the hoist: it collects each
/// `symbol(n:t)` read + `for`/`assign` target a function USES, subtracts the DIM/
/// REDIM names + params + the return-value name, and emits `T xb_var_n = default;`
/// at the prologue. Byte-neutral on the selfhost tools (0 undeclared locals there -
/// nothing hoisted, sync + bootstrap fixed point intact). This locks the behavior
/// across all three backends. (Loop var used only INSIDE the loop: the post-loop
/// FOR counter value is a separate interp-vs-C gap that BOTH C backends share.)
#[test]
fn cemitter_and_cgen_agree_on_undeclared_local() {
    let tmp = std::env::temp_dir().join("xb_sync_undecl_local");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               count = 5\n\
               PRINT count\n\
               FOR k = 0 TO 3\n\
               PRINT k\n\
               NEXT k\n\
               msg$ = \"hi\"\n\
               PRINT msg$\n\
               doubled = count * 2\n\
               PRINT doubled\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse undeclared-local program")
        .lower_ir()
        .expect("lower undeclared-local program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "ul_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "ul_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret undeclared-local program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "5\n0\n1\n2\n3\nhi\n10\n",
        "undeclared-local reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x undeclared-local hoisting differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "undeclared-local hoisting differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Entry point = `Main` if present, else the first defined function (CGEN-SELFHOST-
/// PARITY): legacy XBasic runs the first function, commonly `Entry` - ALL 114 demos
/// use a non-`Main` entry. The interpreter mirrors this (`entry_or_first("Main")`)
/// and the Rust CEmitter calls `xb_user_Entry()` from C `main`, but cgen.x only ever
/// emitted `xb_user_Main();` (guarded by `hasMain`), so for every demo it called
/// NOTHING -> empty output (uncaught: the selfhost tools are all `FUNCTION Main`).
/// cgen.x now tracks the first function (`firstFunc$`/`firstParams$`) and, absent a
/// `Main`, calls it when parameterless. Byte-neutral on the selfhost tools (they have
/// `Main`, so the `hasMain` branch is unchanged). This alone flipped the cgen.x demo
/// differential from faithful=3/diverge=4 to faithful=7/diverge=0.
#[test]
fn cemitter_and_cgen_agree_on_non_main_entry() {
    let tmp = std::env::temp_dir().join("xb_sync_entry");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    // No `Main`; the entry is the first function `Entry` (with a helper after it, to
    // confirm cgen.x picks the FIRST function, not just any/the last).
    let src = "VERSION \"0.1\"\n\
               DECLARE FUNCTION Entry ()\n\
               DECLARE FUNCTION Helper (n)\n\
               FUNCTION Entry ()\n\
               PRINT \"from entry\"\n\
               PRINT Helper(20)\n\
               END FUNCTION\n\
               FUNCTION Helper (n)\n\
               RETURN n + 1\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse non-main-entry program")
        .lower_ir()
        .expect("lower non-main-entry program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "en_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "en_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret non-main-entry program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "from entry\n21\n",
        "non-main-entry reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x non-Main entry differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "non-Main entry differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Unknown-call drop (CGEN-SELFHOST-PARITY gap 2): a call to a function that is
/// neither user-defined nor a known builtin (external GUI/console `Xui*`/`Xgr*`/
/// `Xst*`) must be a no-op as a statement and a zero-default as an expression -
/// exactly what the interpreter/LLVM do (a stub yielding a discarded zero, args
/// skipped) and what the Rust CEmitter emits (`is_unknown_call` -> nothing / `0`).
/// cgen.x previously emitted a raw `xb_user_Xxx(...)` call -> undeclared-function
/// cc error, blocking ~85 demos. cgen.x now drops an unknown statement call and
/// zero-defaults an unknown expression call (predicate: not in `##funcTypes$` AND
/// `c_func_name$` falls through to `xb_user_`). Byte-neutral on the selfhost tools
/// + v0.1 corpus (they call only user functions / known builtins). This flipped the
/// cgen.x demo differential from faithful=7 to faithful=42.
#[test]
fn cemitter_and_cgen_agree_on_unknown_call() {
    let tmp = std::env::temp_dir().join("xb_sync_unknown_call");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    // XstUnknownThing / XstGetValue are undeclared externals; Known is a real
    // user function that must still be called normally.
    let src = "VERSION \"0.1\"\n\
               DECLARE FUNCTION Known (n)\n\
               FUNCTION Main\n\
               XstUnknownThing(42)\n\
               v = XstGetValue(1, 2)\n\
               PRINT v\n\
               PRINT Known(10)\n\
               PRINT \"done\"\n\
               END FUNCTION\n\
               FUNCTION Known (n)\n\
               RETURN n + 5\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse unknown-call program")
        .lower_ir()
        .expect("lower unknown-call program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "uk_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "uk_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret unknown-call program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "0\n15\ndone\n", "unknown-call reference output");
    assert_eq!(
        rust_out, self_out,
        "cgen.x unknown-call handling differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "unknown-call handling differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Bare RETURN in a non-GOSUB function (CGEN-SELFHOST-PARITY): a bare `RETURN`
/// lowers to `gosub_return`, which cgen.x emits as
/// `if (xb_gosub_sp > 0) { goto *xb_gosub_stack[--xb_gosub_sp]; } return 0;`.
/// In a function with NO gosub / computed-goto there is no `&&label` expression,
/// and C rejects an indirect `goto *` in a function with no address-of-label
/// ("indirect goto in function with no address-of-label expressions") - this
/// blocked 16 demos. cgen.x now post-processes each buffered function body: if it
/// contains no `&&`, the dead gosub-return `goto *` (its guard is always false with
/// an empty stack) is rewritten to a plain `return 0;`. Behaviorally identical and
/// byte-neutral on the selfhost tools (their goto-return functions all have gosub,
/// hence `&&`, so the rewrite never fires - bootstrap fixed point intact).
#[test]
fn cemitter_and_cgen_agree_on_bare_return_no_gosub() {
    let tmp = std::env::temp_dir().join("xb_sync_bare_return");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               x = 5\n\
               IF x > 3 THEN\n\
               PRINT \"big\"\n\
               RETURN\n\
               END IF\n\
               PRINT \"small\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse bare-return program")
        .lower_ir()
        .expect("lower bare-return program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "br_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "br_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret bare-return program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "big\n", "bare-return reference output");
    assert_eq!(
        rust_out, self_out,
        "cgen.x bare-return differs from CEmitter"
    );
    assert_eq!(rust_out, interp_out, "bare-return differs from interpreter");
    let _ = fs::remove_dir_all(&tmp);
}

/// Function dedup, first-wins (CGEN-SELFHOST-PARITY): a name defined twice (e.g.
/// `INTERNAL FUNCTION InitProgram` + a later `FUNCTION InitProgram`, common in the
/// xst-importing demos) yields two `function InitProgram` IR items. The interpreter
/// and the Rust CEmitter keep the FIRST (`find_function` / `emit_functions` dedup);
/// cgen.x emitted BOTH C definitions -> "redefinition of 'xb_user_InitProgram'" cc
/// error (15 demos). cgen.x now tracks emitted function names (`emittedFuncs$`) and
/// skips a re-definition (first-wins). Byte-neutral on the selfhost tools (no
/// duplicate function names there).
#[test]
fn cemitter_and_cgen_agree_on_duplicate_function() {
    let tmp = std::env::temp_dir().join("xb_sync_dup_fn");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               DECLARE FUNCTION Foo ()\n\
               FUNCTION Main\n\
               PRINT Foo()\n\
               END FUNCTION\n\
               FUNCTION Foo ()\n\
               RETURN 1\n\
               END FUNCTION\n\
               FUNCTION Foo ()\n\
               RETURN 2\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse duplicate-function program")
        .lower_ir()
        .expect("lower duplicate-function program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "df_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "df_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret duplicate-function program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "1\n",
        "duplicate-function first-wins reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x function dedup differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "function dedup differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Call-arity reconciliation (CGEN-SELFHOST-PARITY): a user call whose argument
/// count differs from the callee's declared params. The interpreter binds
/// `params.zip(args)` (extra args dropped unevaluated) and the Rust CEmitter's
/// emit_call_args pads a missing arg with a zero-default; cgen.x passed all args
/// verbatim -> "too many arguments to function call" cc error (15 xst-demos, after
/// the dedup fix). cgen.x now records each function's declared arity in a
/// forward-pass table (`##funcArity$`) and, for a user-function call, emits exactly
/// that many args via emit_args_n$ (drop extras / pad with `0`). Byte-neutral on the
/// selfhost tools (their calls all match arity, so emit_args_n$ == emit_args$).
#[test]
fn cemitter_and_cgen_agree_on_arg_count() {
    let tmp = std::env::temp_dir().join("xb_sync_arg_count");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               DECLARE FUNCTION Add (x, y)\n\
               FUNCTION Main\n\
               PRINT Add(1, 2, 3, 4)\n\
               PRINT Add(10)\n\
               END FUNCTION\n\
               FUNCTION Add (x, y)\n\
               RETURN x + y\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse arg-count program")
        .lower_ir()
        .expect("lower arg-count program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "ac_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "ac_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret arg-count program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // Add(1,2,3,4) drops 3,4 -> 3; Add(10) pads y=0 -> 10.
    assert_eq!(
        interp_out, "3\n10\n",
        "arg-count reconciliation reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x arg-count reconciliation differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "arg-count reconciliation differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// INLINE$ helper (CGEN-SELFHOST-PARITY): `INLINE$(prompt)` maps to `xb_inline`,
/// but cgen.x's C prelude omitted the helper Rust emits -> undeclared-function cc
/// error (hello/ahello/atask). cgen.x now emits it - `static char* xb_inline(const
/// char* prompt) { if (prompt) xb_print_str(prompt); return xb_readline(); }` -
/// conditionally, gated on the text IR containing `INLINE$(` (a real call; the
/// bare literal `string("INLINE$")` in cgen.x's own mapping code lacks the paren,
/// so self-compile stays byte-identical). With empty stdin the prompt prints as its
/// own line and INLINE$ returns "" at EOF, matching the interpreter.
#[test]
fn cemitter_and_cgen_agree_on_inline_helper() {
    let tmp = std::env::temp_dir().join("xb_sync_inline");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               s$ = INLINE$(\"Prompt: \")\n\
               PRINT \"got[\" + s$ + \"]\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse inline program")
        .lower_ir()
        .expect("lower inline program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "in_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "in_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret inline program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "Prompt: \ngot[]\n",
        "INLINE$ empty-stdin reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x INLINE$ helper differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "INLINE$ helper differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Escaped quote in a string-concat operand (CGEN-SELFHOST-PARITY): cgen.x's
/// `first_expr$` operand scanner toggled `inQuote` on every `"` with no escape
/// handling, so a `string("... \"")` (embedded `\"`) left it mis-set, the operator
/// split miscounted, and the emit leaked a raw `symbol(a:string)`/`string(...)` with
/// a wrong `xb_var_`/`xb_str_` prefix + a malformed `0)` tail. It now skips a
/// `\`-escaped char while in-quote. Fixed tfont + the 3 ttxtline variants (all had
/// `"... : \"" + a$ + "\""`). Byte-neutral on the selfhost tools (no `\"` in their
/// string literals - they build `"` via CHR$(34)).
#[test]
fn cemitter_and_cgen_agree_on_escaped_quote_concat() {
    let tmp = std::env::temp_dir().join("xb_sync_escquote");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    // s$ = "start \"" + a$ + "\" end"  -> IR arith(arith(string("start \"") +
    // symbol(a)) + string("\" end")); the embedded \" used to break the scanner.
    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               a$ = \"MID\"\n\
               s$ = \"start \\\"\" + a$ + \"\\\" end\"\n\
               PRINT s$\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse escaped-quote program")
        .lower_ir()
        .expect("lower escaped-quote program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "eq_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "eq_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret escaped-quote program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "start \"MID\" end\n",
        "escaped-quote concat reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x escaped-quote concat differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "escaped-quote concat differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Type-suffix chars in C identifiers (CGEN-SELFHOST-PARITY): a var whose XBasic
/// name keeps a type suffix — `x#` (double), `n!` (single), `c%` (short) — was
/// emitted with the literal suffix in the C identifier (`xb_var_x#`), which cc
/// rejects (`#` starts a directive → "expected ';'"; adrawing's SHARED `RandomNSeed#`
/// hit the same). cgen.x now maps `#!@&%`→`_d/_f/_a/_l/_h` (mirroring Rust's
/// sanitize_c_ident) in c_var_name$ AND the three xb_shared_ sites; `$` is left (a
/// gcc identifier extension the runtime relies on) and `.` is left (composite = C
/// struct member). Byte-neutral on the selfhost tools (they use no `#!@&%` names).
#[test]
fn cemitter_and_cgen_agree_on_type_suffix_idents() {
    let tmp = std::env::temp_dir().join("xb_sync_suffix");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               x# = 3.5\n\
               n! = 2.0\n\
               c% = 7\n\
               PRINT x# + n!\n\
               PRINT c%\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse type-suffix program")
        .lower_ir()
        .expect("lower type-suffix program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "sfx_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "sfx_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret type-suffix program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "5.5\n7\n", "type-suffix reference output");
    assert_eq!(
        rust_out, self_out,
        "cgen.x type-suffix identifier differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "type-suffix identifier differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Unknown call in a STRING context (CGEN-SELFHOST-PARITY): the unknown-call drop
/// must yield a type-appropriate default. A `$`-returning external (`XstGetName$`,
/// `XstMergeStrings$`) assigned to a string var must drop to `xb_str("")` (empty),
/// NOT the integer `0` — else the string var is a NULL `char*` and prints "(null)"
/// (the amerge divergence). cgen.x now checks the call name's trailing `$` and emits
/// `xb_str("")` for string-returning unknowns, `0` otherwise (matching the Rust
/// CEmitter + the interpreter's typed stub). Byte-neutral (no unknown calls in the
/// selfhost tools).
#[test]
fn cemitter_and_cgen_agree_on_unknown_string_call() {
    let tmp = std::env::temp_dir().join("xb_sync_unk_str");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               s$ = XstGetName$(\"p\")\n\
               PRINT \"[\" + s$ + \"]\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse unknown-string-call program")
        .lower_ir()
        .expect("lower unknown-string-call program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "us_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "us_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret unknown-string-call program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "[]\n",
        "unknown string-call reference output (empty, not null)"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x unknown string-call default differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "unknown string-call default differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Leading-zero decimal literal (CGEN-SELFHOST-PARITY): a decimal literal with a
/// leading zero (`08`, `09`) was emitted verbatim into C, where `08` is an invalid
/// octal constant ("invalid digit '8' in octal constant" — atrim). cgen.x now strips
/// leading zeros from decimal integer literals (`strip_zeros$`), keeping hex (`0x..`)
/// untouched (stripping those to `x1F` was the first-attempt bug that broke the
/// positive-corpus sync — hex literals abound there). Byte-neutral on the selfhost
/// tools (no leading-zero decimals) and the v0.1 corpus (hex preserved).
#[test]
fn cemitter_and_cgen_agree_on_leading_zero_literal() {
    let tmp = std::env::temp_dir().join("xb_sync_octal");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               DIM a[20]\n\
               a[08] = 5\n\
               a[09] = 6\n\
               PRINT a[8] + a[9]\n\
               PRINT 0x1F\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse leading-zero program")
        .lower_ir()
        .expect("lower leading-zero program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "oct_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "oct_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret leading-zero program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // a[8]=5 + a[9]=6 = 11; 0x1F = 31 (hex preserved).
    assert_eq!(interp_out, "11\n31\n", "leading-zero/hex reference output");
    assert_eq!(
        rust_out, self_out,
        "cgen.x leading-zero literal differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "leading-zero literal differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// EOF builtin arg (CGEN-SELFHOST-PARITY): `EOF(handle)` maps to the 0-param C
/// helper `xb_eof()`, but cgen.x passed the handle through -> `xb_eof(handle)` ->
/// "too many arguments" cc error (awrite et al.). The interpreter ignores the arg
/// and the Rust CEmitter drops it. cgen.x now special-cases `EOF` to emit `xb_eof()`
/// (no args). Byte-neutral: cgen.x's own reader loop uses the 0-arg `EOF()`, which
/// already emitted `xb_eof()`.
#[test]
fn cemitter_and_cgen_agree_on_eof_arg() {
    let tmp = std::env::temp_dir().join("xb_sync_eof");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               IF EOF(1) THEN\n\
               PRINT \"ateof\"\n\
               ELSE\n\
               PRINT \"noteof\"\n\
               END IF\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse eof program")
        .lower_ir()
        .expect("lower eof program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "eof_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "eof_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret eof program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // Empty stdin -> at EOF.
    assert_eq!(
        interp_out, "ateof\n",
        "EOF(handle) empty-stdin reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x EOF arg handling differs from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "EOF arg handling differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Repeated GOSUB to the same target (CGEN-SELFHOST-PARITY): each `GOSUB Pr` emits
/// a `xb_gosub_ret_Pr:` return label; two gosubs to `Pr` in one function emitted the
/// label twice -> C "redefinition of label" (aback et al.). cgen.x now uniquifies
/// repeats per function (`gosub_ret_suffix$`: first keeps the bare name, repeats get
/// `_2`, `_3`), matching the Rust CEmitter. Byte-neutral on the selfhost tools (each
/// GOSUB target is unique per function there — else the bootstrap would already fail).
#[test]
fn cemitter_and_cgen_agree_on_repeated_gosub() {
    let tmp = std::env::temp_dir().join("xb_sync_gosub2");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "VERSION \"0.1\"\n\
               FUNCTION Main\n\
               GOSUB Pr\n\
               GOSUB Pr\n\
               GOTO Done\n\
               Pr:\n\
               PRINT \"hi\"\n\
               RETURN\n\
               Done:\n\
               PRINT \"end\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse repeated-gosub program")
        .lower_ir()
        .expect("lower repeated-gosub program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let parsed = TextIrParser::parse(&ir).expect("parse text IR");
    let rust_c = CEmitter::new().emit_program(&parsed);
    let rust_out = compile_and_exec(&tmp, "gs_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "gs_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret repeated-gosub program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "hi\nhi\nend\n",
        "repeated-gosub reference output"
    );
    assert_eq!(
        rust_out, self_out,
        "cgen.x repeated-gosub labels differ from CEmitter"
    );
    assert_eq!(
        rust_out, interp_out,
        "repeated-gosub differs from interpreter"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Version directive off-by-one (CGEN-SELFHOST-PARITY): when the `version` line is
/// not the first IR line (a `PROGRAM` name precedes it, as in every demo), cgen.x's
/// extractor advanced its cursor by 10 instead of 9 — the `\nversion ` prefix is 9
/// chars — stripping the version literal's first character (`3.0700` -> `.0700`). The
/// interpreter does not expose VERSION$ at run time, so this is pinned on the emitted
/// C: both generators must embed the un-stripped literal. Byte-neutral on the
/// self-host corpus (cgen.x's own `VERSION "0.1"` is the first source line, so its IR
/// `version` is line 1 and takes the correct first-line path).
#[test]
fn cemitter_and_cgen_agree_on_version_after_program_name() {
    let tmp = std::env::temp_dir().join("xb_sync_ver");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"vtest\"\n\
               VERSION \"3.0700\"\n\
               FUNCTION Main\n\
               PRINT \"hi\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse version program")
        .lower_ir()
        .expect("lower version program");
    let ir = TextIrEmitter::new().emit_program(&prog);
    // Precondition: `version` is the 2nd IR line (a `program_name` precedes it),
    // which is exactly the path that had the off-by-one.
    assert!(
        ir.lines()
            .nth(1)
            .map_or(false, |l| l.starts_with("version ")),
        "test setup: version should be the 2nd IR line, got IR:\n{ir}"
    );

    let rust_c = CEmitter::new().emit_program(&prog);
    let self_c: String = cgen_emit(&cgen_exe, &ir)
        .into_iter()
        .map(|b| b as char)
        .collect();

    let needle = "xb_version_str = \"3.0700\"";
    assert!(
        rust_c.contains(needle),
        "CEmitter stripped the version literal"
    );
    assert!(
        self_c.contains(needle),
        "cgen.x stripped the version literal (off-by-one advancing past the value)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Composite-member identifier sanitization (CGEN-SELFHOST-PARITY): a `TYPE`
/// member access like `p.x` lowers to a symbol whose name contains a `.`, which is
/// not a legal C identifier char. Both generators must map `.` -> `_` (Rust's
/// sanitize_c_ident does `.replace('.', "_")`); cgen.x's sanitize_ident$ only handled
/// the type-suffix chars, so composite-member params/locals emitted a raw `.`
/// (`xb_var_p.x`) -> C syntax error (afuntype/qbtoxb cc-failed). The flattening is
/// consistent across the declaration and every use, so behavior matches the interp.
#[test]
fn cemitter_and_cgen_agree_on_composite_member_idents() {
    let tmp = std::env::temp_dir().join("xb_sync_composite");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"ctest\"\n\
               VERSION \"0.1\"\n\
               TYPE PT\n\
               XLONG .x\n\
               XLONG .y\n\
               END TYPE\n\
               FUNCTION Main\n\
               PT p\n\
               p.x = 3\n\
               p.y = 4\n\
               PRINT p.x + p.y\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse composite program")
        .lower_ir()
        .expect("lower composite program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "composite_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "composite_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret composite program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "7\n", "composite-member reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled composite-member idents"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled composite-member idents"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Binary integer literals (CGEN-SELFHOST-PARITY): `0b1000000` is a gcc/clang
/// extension the interpreter evaluates (64) and the Rust CEmitter emits verbatim.
/// cgen.x's strip_zeros$ (added for the `08`/`09` octal hazard) exempted hex
/// (`0x..`) but not binary, so it stripped the leading `0` of `0b..` — leaving a
/// bare `b1000000` (undeclared identifier) or `0` — miscompiling every binary
/// literal (arotate's long-standing "diverge" was this; agraphic cc-failed). The
/// fix exempts `0b`/`0B` like `0x`; all three backends now agree.
#[test]
fn cemitter_and_cgen_agree_on_binary_literals() {
    let tmp = std::env::temp_dir().join("xb_sync_binlit");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"binlit\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main\n\
               PRINT 0b1000000\n\
               PRINT 0b0001\n\
               PRINT 0b10000000000000011000000000000001\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse binary-literal program")
        .lower_ir()
        .expect("lower binary-literal program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "binlit_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "binlit_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret binary-literal program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // 0b1000000 = 64; 0b0001 = 1 (leading binary zeros preserved); the 32-bit
    // pattern wraps to a negative i32.
    assert_eq!(
        interp_out, "64\n1\n-2147385343\n",
        "binary-literal reference output"
    );
    assert_eq!(rust_out, interp_out, "CEmitter mishandled binary literals");
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled binary literals (strip_zeros stripped 0b)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Nested functions (CGEN-NESTED-FN): a `SUB`/`INTERNAL FUNCTION` nested inside a
/// parent function body captures the parent's locals and is invoked via `GOSUB`
/// (the frontend lowers the nested name as a label — `label_addr`/`gosub` already
/// emit `xb_label_<name>`). C forbids nested function definitions, so cgen.x used to
/// emit an illegal nested `xb_user_<name>() { … }` ("function definition is not
/// allowed here"). It now emits the nested body as an `xb_label_<name>:` block placed
/// after the parent body (guarded from fall-through), hoisting the nested locals into
/// the parent's shared C scope — mirroring the Rust CEmitter's inline-label-block
/// scheme. Here `Bump` shares `x` with `Main`; two GOSUBs take it 0 -> 21 -> 42.
#[test]
fn cemitter_and_cgen_agree_on_nested_function() {
    let tmp = std::env::temp_dir().join("xb_sync_nestfn");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"nesttest\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               x = 0\n\
               GOSUB Bump\n\
               PRINT x\n\
               GOSUB Bump\n\
               PRINT x\n\
               RETURN\n\
               SUB Bump\n\
               x = x + 21\n\
               END SUB\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse nested-function program")
        .lower_ir()
        .expect("lower nested-function program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "nestfn_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "nestfn_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret nested-function program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "21\n42\n", "nested-function reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the nested function"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the nested function (label-block emission)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Dyn arrays (CGEN-DYN-ARRAY): a name DIM'd as BOTH a scalar and a 1-D integer
/// array (the scalar DIM is typically a frontend artifact; the name is used only as
/// an array) must lower to ONE dyn pointer, not a scalar decl plus a fixed-array decl
/// for the same C name (which cc rejects as a "redefinition"). cgen.x now emits
/// `intptr_t* xb_var_a = 0; intptr_t xb_ub_a = -1;` (hoisted), the scalar DIM emits
/// nothing, and the 1-D array DIM `calloc`s + sets the ubound — mirroring the Rust
/// CEmitter's dyn-pointer scheme. Flipped acharmap/aunicode/aviewbmp faithful.
#[test]
fn cemitter_and_cgen_agree_on_dyn_array() {
    let tmp = std::env::temp_dir().join("xb_sync_dynarr");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"dd\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM a\n\
               DIM a[3]\n\
               a[0] = 10\n\
               a[1] = 20\n\
               a[2] = 30\n\
               PRINT a[0] + a[1] + a[2]\n\
               PRINT UBOUND(a)\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse dyn-array program")
        .lower_ir()
        .expect("lower dyn-array program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "dynarr_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "dynarr_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret dyn-array program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // sum = 60; UBOUND of the [3] array = 3 (reads xb_ub_a, not sizeof of a pointer).
    assert_eq!(interp_out, "60\n3\n", "dyn-array reference output");
    assert_eq!(rust_out, interp_out, "CEmitter mishandled the dyn array");
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the dyn array (scalar+1D-array redefinition)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Scalar-used dyn array (CGEN-DYN-ARRAY, extended): a name used as a bare scalar
/// (`IF dsp == 0`, a null/allocated check) AND indexed as an array (`dsp[i]`), often
/// used *before* its DIM, must lower to ONE dyn pointer — 0 before the DIM's calloc,
/// non-0 after — matching the interpreter's single-slot semantics. (An earlier
/// attempt to split it into a scalar facet + `_arr` array facet regressed, because
/// the always-0 scalar facet broke the null check.) cgen.x now folds a
/// bare-scalar-used array name into the single dyn-pointer scheme.
#[test]
fn cemitter_and_cgen_agree_on_scalar_used_dyn_array() {
    let tmp = std::env::temp_dir().join("xb_sync_sudyn");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"du\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               IF dsp == 0 THEN PRINT \"dsp-is-zero\"\n\
               DIM dsp[3]\n\
               dsp[0] = 10\n\
               dsp[1] = 20\n\
               dsp[2] = 30\n\
               PRINT dsp[0] + dsp[1] + dsp[2]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse scalar-used-dyn program")
        .lower_ir()
        .expect("lower scalar-used-dyn program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "sudyn_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "sudyn_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret scalar-used-dyn program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // dsp is 0 before its DIM (prints), then indexed; sum = 60.
    assert_eq!(
        interp_out, "dsp-is-zero\n60\n",
        "scalar-used-dyn reference output"
    );
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the scalar-used dyn array"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the scalar-used dyn array"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Undimmed arrays (CGEN-DYN-ARRAY): a name used as an array but never DIM'd (e.g.
/// abuffer's `func[]`, filled by a stubbed Xui builtin) has no real slot in the
/// interpreter — an un-DIMmed read yields the type default and a write is a no-op
/// (evaluated for side-effects only). cgen.x folds an undimmed read to the default
/// and an undimmed assign to `(void)(value)`, mirroring the Rust CEmitter. This was
/// the key layer that unblocked the nested-fn demo cluster (10 flipped faithful).
#[test]
fn cemitter_and_cgen_agree_on_undimmed_array() {
    let tmp = std::env::temp_dir().join("xb_sync_undim");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"ud\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               x = 0\n\
               IF x THEN slots[2] = 99\n\
               PRINT slots[0]\n\
               PRINT UBOUND(slots)\n\
               PRINT \"done\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse undimmed program")
        .lower_ir()
        .expect("lower undimmed program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "undim_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "undim_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret undimmed program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // Un-DIMmed read -> default 0; UBOUND of a non-array -> -1; guarded write is a no-op.
    assert_eq!(
        interp_out, "0\n-1\ndone\n",
        "undimmed-array reference output"
    );
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the undimmed array"
    );
    assert_eq!(self_out, interp_out, "cgen.x mishandled the undimmed array");
    let _ = fs::remove_dir_all(&tmp);
}

/// Cross-function array scoping (CGEN-DYN-ARRAY): a dyn array DIM'd in one function
/// and read (UBOUND/subscript) in a SEPARATE top-level function is a distinct
/// undimmed local there (the interpreter scopes per-function), not shared storage.
/// cgen.x's dyn scans are program-wide, so without per-function scoping it emitted the
/// dyn `xb_ub_`/`xb_var_` names (declared only where DIM'd) -> undeclared-identifier cc
/// error. Now folded to the undimmed default per function. Flipped awindow + anewlook
/// faithful (`text$` DIM'd in XitMain, UBOUND'd in the separate XitMainCode).
#[test]
fn cemitter_and_cgen_agree_on_cross_function_array() {
    let tmp = std::env::temp_dir().join("xb_sync_xfn");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"xfd\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Filler ()\n\
               DIM s$[2]\n\
               REDIM s$[4]\n\
               s$[0] = \"a\"\n\
               END FUNCTION\n\
               FUNCTION Reader ()\n\
               PRINT UBOUND(s$)\n\
               END FUNCTION\n\
               FUNCTION Main ()\n\
               Filler()\n\
               Reader()\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse cross-function program")
        .lower_ir()
        .expect("lower cross-function program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "xfn_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "xfn_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret cross-function program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // Reader's `s$` is a distinct undimmed local (DIM'd only in Filler) -> UBOUND -1.
    assert_eq!(interp_out, "-1\n", "cross-function array reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the cross-function array"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the cross-function array"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Forward-referenced scalar (CGEN-FWDREF): a scalar USED before its DIM (e.g.
/// xgrids' `IF list$ = 0` at IR line 2080, DIM'd at 2202). cgen.x emits scalar decls
/// at the DIM site (not hoisted to function entry like Rust), so the earlier use
/// referenced an undeclared name -> cc error. Now a scalar whose name is already in
/// `usedSyms$` at its DIM is hoisted to the function top (##fwdScalars$) and its DIM
/// site is skipped, matching the interpreter (the pre-DIM read sees the default).
#[test]
fn cemitter_and_cgen_agree_on_forward_referenced_scalar() {
    let tmp = std::env::temp_dir().join("xb_sync_fwdref");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"fwd\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               IF x = 0 THEN PRINT \"zero\"\n\
               DIM x\n\
               x = 7\n\
               PRINT x\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse forward-ref program")
        .lower_ir()
        .expect("lower forward-ref program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "fwdref_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "fwdref_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret forward-ref program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // Pre-DIM read of `x` sees the default 0 (-> "zero"), then x = 7.
    assert_eq!(interp_out, "zero\n7\n", "forward-ref scalar output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the forward-ref scalar"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the forward-ref scalar"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// String dyn arrays (CGEN-DYN-ARRAY): a `string` array DIM'd more than once (a
/// REDIM, e.g. awindow's `text$[]` menu-label array) would emit two fixed
/// `char* X$[n]` declarations -> cc "redefinition". cgen.x now lowers such a name to
/// ONE dyn `char**` pointer (calloc + empty-string init per DIM), mirroring the Rust
/// CEmitter. Flipped aedit/atcursor/adrawing/agrids faithful.
#[test]
fn cemitter_and_cgen_agree_on_string_dyn_array() {
    let tmp = std::env::temp_dir().join("xb_sync_strdyn");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"sd\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM names$[2]\n\
               names$[0] = \"aa\"\n\
               DIM names$[3]\n\
               names$[0] = \"x\"\n\
               names$[1] = \"y\"\n\
               PRINT names$[0] + names$[1]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse string-dyn program")
        .lower_ir()
        .expect("lower string-dyn program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "strdyn_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "strdyn_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret string-dyn program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    // REDIM'd string array holds "x","y" after the second DIM -> concat "xy".
    assert_eq!(interp_out, "xy\n", "string-dyn reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the string dyn array"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the string dyn array (char** redefinition)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Scalar string DIM of a string dyn array (CGEN-DYN-ARRAY): a string name DIM'd as a
/// scalar (`AUTO array$[]` empty-bracket lowers to `dim array$:string`) AND as a 1-D
/// string array 2+ times (`##dynStr$`) made cgen.x emit BOTH `char* xb_str_array$` (the
/// scalar `dim` handler) AND `char** xb_str_array$ = 0` (the dyn-array hoist) -> cc
/// "redefinition of xb_str_array$ with a different type". cgen.x now skips the scalar
/// string `dim` for a name in `##dynStr$` (the char** dyn decl covers it), mirroring the
/// existing `##dynNames$` integer handling. Flipped aprofile + adata faithful (90->92).
#[test]
fn cemitter_and_cgen_agree_on_scalar_dim_of_string_dyn_array() {
    let tmp = std::env::temp_dir().join("xb_sync_scalardimstrdyn");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"sd\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               AUTO tags$[]\n\
               DIM tags$[2]\n\
               DIM tags$[3]\n\
               tags$[0] = \"x\"\n\
               tags$[1] = \"y\"\n\
               PRINT tags$[0] + tags$[1]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse scalar-dim string-dyn program")
        .lower_ir()
        .expect("lower scalar-dim string-dyn program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "sdimstrdyn_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "sdimstrdyn_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret scalar-dim string-dyn program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "xy\n", "scalar-dim string-dyn reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled scalar-dim string dyn array"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled scalar-dim string dyn array (char*/char** redefinition)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// SHARED arrays across functions (CGEN-SHARED-ARR-SELFHOST): `SHARED g[]` in two
/// functions + `DIM g[N]` in one lowers to `dim shared g:integer` (per fn) + `dim
/// shared g:integer[N]`. cgen.x sent these through the LOCAL dim handler which never
/// stripped `shared ` (emitted `intptr_t xb_var_shared g[...]`, cc-fail) and had no
/// cross-function heap-global path. Now cgen.x mirrors the Rust CEmitter: a file-scope
/// `intptr_t* xb_var_g = 0; intptr_t xb_ub_g = -1;` global (forward-decl), calloc at the
/// sized DIM, `xb_var_g[i]` access — shared across every function. Helper writing g[1]
/// must be visible in Main (42, not the local-only 5). Selfhost corpus has no shared
/// arrays, so this is byte-neutral there (sync stays green).
#[test]
fn cemitter_and_cgen_agree_on_shared_array_cross_function() {
    let tmp = std::env::temp_dir().join("xb_sync_sharedarr");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"sa\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               SHARED g[]\n\
               DIM g[3]\n\
               g[1] = 5\n\
               Helper()\n\
               PRINT g[1]\n\
               END FUNCTION\n\
               FUNCTION Helper ()\n\
               SHARED g[]\n\
               g[1] = 42\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse shared-array program")
        .lower_ir()
        .expect("lower shared-array program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "sharr_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "sharr_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret shared-array program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "42\n",
        "shared-array cross-function reference output"
    );
    assert_eq!(rust_out, interp_out, "CEmitter mishandled the shared array");
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the shared array (cross-function heap global)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Function-address id (CGEN-FUNCADDR): `&Func` / `funcaddr(Func)` is a synthetic
/// 1-based id in program declaration order (interp eval.rs `function_id`; Rust/LLVM
/// match), NOT a machine address. cgen.x folded it to 0 (no handler); it now returns
/// the position of the name in `##funcIds$` (built by the forward-decl pass). Helper is
/// the 2nd function -> 2. Byte-neutral on the selfhost tools (they emit 0 funcaddr).
#[test]
fn cemitter_and_cgen_agree_on_func_addr_id() {
    let tmp = std::env::temp_dir().join("xb_sync_funcaddr");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"fa\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM a\n\
               a = &Helper()\n\
               PRINT a\n\
               END FUNCTION\n\
               FUNCTION Helper ()\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse funcaddr program")
        .lower_ir()
        .expect("lower funcaddr program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "funcaddr_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "funcaddr_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret funcaddr program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "2\n",
        "funcaddr reference id (Helper = 2nd function)"
    );
    assert_eq!(rust_out, interp_out, "CEmitter mishandled &func id");
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled &func id (should be decl-order position)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Multi-dim string array DIM (CGEN-MULTIDIM): a fixed 2-D `string` array `DIM s$[m,n]`
/// went through the 1-D string-DIM path (`emit_expr` on the whole `m,n` bracket) and
/// emitted `char* s$[(m),integer(n) + 1]` — a bare comma -> cc "expected ']'" + the raw
/// `integer(n)` leaking as an undeclared call. Integer 2-D (via `emit_msub$`) and 2-D
/// *access* already worked. cgen.x now emits the native `char* s$[(m)+1][(n)+1]` (comma
/// -> `emit_msub$`) with a flat-cast init `((char**)s$)[_i] = ""` over `emit_mtotal$`
/// (the product), guarded so 1-D stays byte-identical (selfhost corpus is all 1-D).
#[test]
fn cemitter_and_cgen_agree_on_multidim_string_array() {
    let tmp = std::env::temp_dir().join("xb_sync_mdstr");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"md\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM s$[2,1]\n\
               s$[1,0] = \"hi\"\n\
               s$[0,1] = \"yo\"\n\
               PRINT s$[1,0] + s$[0,1]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse 2-D string program")
        .lower_ir()
        .expect("lower 2-D string program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "mdstr_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "mdstr_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret 2-D string program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "hiyo\n", "2-D string array reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the 2-D string array"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the 2-D string array DIM"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// 2-D *dynamic* array (CGEN-MULTIDIM dyn): a name that is dyn (a comma-free 1-D DIM /
/// scalar facet — `scan_dyn$` excludes multi-dim DIMs via the comma) AND also DIM'd
/// multi-dim (`g[m,n]`) is stored as a flat 1-D heap block and accessed row-major
/// `g[i*(d1+1)+j]`, mirroring the Rust CEmitter. cgen.x used to send the `m,n` bracket
/// through the 1-D `emit_expr` path (`calloc((m),integer(n)+1)` — bare comma, cc-fail).
/// Now: DIM captures the 2nd-dim count into `xb_d1_g` (hoisted), calloc's the
/// `emit_mtotal$` product, and access/assign flatten via `emit_flat2d$`. Byte-neutral on
/// the selfhost tools (all 1-D). Unblocks the calloc/access errors of the aarray/aquick/
/// aarray_ISNODE 2-D cluster (those demos still need by-ref-array-params on top).
#[test]
fn cemitter_and_cgen_agree_on_2d_dyn_array() {
    let tmp = std::env::temp_dir().join("xb_sync_2ddyn");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"dd\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               AUTO g[]\n\
               DIM g[5]\n\
               DIM g[3,2]\n\
               g[1,1] = 7\n\
               g[3,2] = 9\n\
               PRINT g[1,1]\n\
               PRINT g[3,2]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse 2-D dyn program")
        .lower_ir()
        .expect("lower 2-D dyn program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "dd_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "dd_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret 2-D dyn program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "7\n9\n", "2-D dyn array reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the 2-D dyn array"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the 2-D dyn array (flattened calloc/access)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Function-name self-DIM (CGEN-SELFHOST-PARITY): a function whose body DIMs its own
/// name (the return value — `FUNCTION Main() ... DIM Main`) made cgen.x emit a scalar
/// decl for `xb_var_Main` from the signature AND again from the `dim` statement -> cc
/// "redefinition of xb_var_Main" (the dominant dim_redef cluster, ~14 nested-fn demos
/// where the callback function DIMs its own name). cgen.x now skips a scalar `dim
/// <funcName>` inside that function (the return-value decl already declares it).
#[test]
fn cemitter_and_cgen_agree_on_function_name_self_dim() {
    let tmp = std::env::temp_dir().join("xb_sync_selfdim");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"rv\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM Main\n\
               DIM tally\n\
               DIM tally\n\
               tally = 7\n\
               Main = tally\n\
               PRINT Main\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse self-dim program")
        .lower_ir()
        .expect("lower self-dim program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "selfdim_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "selfdim_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret self-dim program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "7\n", "self-dim reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled function-name self-DIM"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled retval self-DIM or repeated scalar DIM"
    );
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
        let input_lines: Vec<Vec<u8>> = common::byte_lines(input.as_bytes());

        let rust_c = CEmitter::new().emit_program(&prog);
        let rust_out = compile_and_exec(
            &tmp,
            &format!("{tool}_rust"),
            rust_c.as_bytes(),
            Some(&input),
        );

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

/// Extract the set of runtime-helper signatures from emitted C, canonicalized so
/// that only the ABI-relevant shape survives: `static <ret> xb_NAME(<param-types>)`
/// with whitespace collapsed and parameter *names* stripped (names are cosmetic).
/// Bodies, ordering, and formatting are ignored.
fn extract_helper_sigs(c: &str) -> std::collections::BTreeSet<String> {
    let mut set = std::collections::BTreeSet::new();
    for line in c.lines() {
        let t = line.trim_start();
        if !t.starts_with("static ") {
            continue;
        }
        // Find an `xb_<ident>` immediately followed by '(' (a function definition,
        // not a `static` variable like `xb_files[256]`).
        let bytes = t.as_bytes();
        let mut search = 0usize;
        while let Some(rel) = t[search..].find("xb_") {
            let name_start = search + rel;
            let mut j = name_start;
            while j < t.len() && {
                let d = bytes[j] as char;
                d.is_ascii_alphanumeric() || d == '_'
            } {
                j += 1;
            }
            if j < t.len() && bytes[j] as char == '(' {
                if let Some(crel) = t[j..].find(')') {
                    set.insert(canonicalize_sig(&t[..j + crel + 1]));
                }
                break;
            }
            search = (name_start + 3).max(j);
        }
    }
    set
}

/// Collapse whitespace and drop identifiers that sit immediately before `,` or `)`
/// (parameter names / `void`), leaving return type + name + parameter types.
fn canonicalize_sig(raw: &str) -> String {
    let collapsed: String = raw.split_whitespace().collect::<Vec<_>>().join(" ");
    let bytes = collapsed.as_bytes();
    let mut out = String::new();
    let mut i = 0usize;
    while i < collapsed.len() {
        let c = bytes[i] as char;
        if c.is_ascii_alphabetic() || c == '_' {
            let start = i;
            while i < collapsed.len() && {
                let d = bytes[i] as char;
                d.is_ascii_alphanumeric() || d == '_'
            } {
                i += 1;
            }
            let next = collapsed[i..].chars().next().unwrap_or('\0');
            if next != ',' && next != ')' {
                out.push_str(&collapsed[start..i]);
            }
        } else {
            out.push(c);
            i += 1;
        }
    }
    out.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// CG-COVER guard: the Rust `CEmitter` and self-hosted `cgen.x` must emit the
/// same set of runtime-helper signatures (return type, name, parameter types).
/// This is the structural half of sync — it catches drift the behavioral corpus
/// test can miss because the corpus doesn't exercise every helper: a helper
/// present in one generator but not the other (e.g. the `xb_ljust` gap), or a
/// signature change in one only (e.g. address helpers `int` vs `intptr_t`).
#[test]
fn cemitter_and_cgen_helper_signatures_match() {
    let tmp = std::env::temp_dir().join("xb_sync_sigs");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    // The runtime prelude is emitted unconditionally, so any program surfaces it.
    let src = "VERSION \"0.1\"\nPRINT \"x\"\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let rust_c = CEmitter::new().emit_program(&prog);
    let ir = TextIrEmitter::new().emit_program(&prog);
    let self_c = String::from_utf8(cgen_emit(&cgen_exe, &ir)).expect("cgen output utf8");

    let rust_sigs = extract_helper_sigs(&rust_c);
    let self_sigs = extract_helper_sigs(&self_c);

    assert!(
        rust_sigs.len() > 100,
        "expected a substantial helper set from CEmitter, got {}",
        rust_sigs.len()
    );
    let only_rust: Vec<&String> = rust_sigs.difference(&self_sigs).collect();
    let only_self: Vec<&String> = self_sigs.difference(&rust_sigs).collect();
    assert!(
        only_rust.is_empty() && only_self.is_empty(),
        "runtime helper signature drift between generators:\n  only in CEmitter ({}): {:#?}\n  only in cgen.x ({}): {:#?}",
        only_rust.len(),
        only_rust,
        only_self.len(),
        only_self
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Typed (non-integer) fixed array element type (CGEN-TYPED-ARRAY): a `#`/`!`
/// (float) array `DIM a#[3]` must declare its C element type from the slot type
/// (`double`), not a hardcoded `intptr_t`. cgen.x emitted `intptr_t xb_var_a_d[..]`
/// so `a#[0] = 1.5` truncated to `1` (cgen.x printed `1`, interp/Rust `1.5`).
/// cgen.x now uses `c_type$(varType$)` for the element type — `intptr_t` for an
/// integer array (byte-identical to before; the corpus is all-integer) and
/// `double` for a float array. Byte-neutral on the self-host corpus + bootstrap.
#[test]
fn cemitter_and_cgen_agree_on_typed_float_array() {
    let tmp = std::env::temp_dir().join("xb_sync_typedarr");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"ta\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM a#[3]\n\
               a#[0] = 1.5\n\
               a#[1] = 2.25\n\
               PRINT a#[0] + a#[1]\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse typed float array program")
        .lower_ir()
        .expect("lower typed float array program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "ta_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "ta_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret typed float array program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "3.75\n", "typed float array reference output");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled the typed float array"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the typed float array (element type)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// UBOUND of a scalar string (CGEN-UBOUND-STRING): `UBOUND(s$)` is the string's
/// last byte offset — `LEN(s$) - 1` (interp eval.rs ArrayUBound string arm), the
/// idiom `FOR i = 0 TO UBOUND(b$) : c = b${i}` uses to walk a byte string
/// (aback's backslash-escape demo). cgen.x treated the string as an undimmed
/// array and returned `-1`, so the byte loop ran zero times (empty output vs the
/// interpreter's full table — aback went from a diverger to byte-faithful once
/// fixed). cgen.x now emits `(xb_len(xb_str_s) - 1)`, matching the Rust CEmitter.
#[test]
fn cemitter_and_cgen_agree_on_ubound_of_string() {
    let tmp = std::env::temp_dir().join("xb_sync_ubstr");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"ub\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM s$\n\
               DIM i\n\
               s$ = \"abc\"\n\
               PRINT UBOUND(s$)\n\
               FOR i = 0 TO UBOUND(s$)\n\
               PRINT s${i}\n\
               NEXT i\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse ubound-of-string program")
        .lower_ir()
        .expect("lower ubound-of-string program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "ub_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "ub_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret ubound-of-string program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "2\n97\n98\n99\n",
        "UBOUND-of-string reference output"
    );
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled UBOUND of a string"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled UBOUND of a string (byte length)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Brace byte access on a STRING ARRAY element (CGEN-BYTE-ACCESS-V3): both
/// `words$[i]{j}` (post-array brace) and bare `words${j}` (element-0 base,
/// incl. through a by-ref array param) must read the element's bytes — the
/// xst/xit `charsetWithinWord[text$[l]{n}]` pattern. Locked across interp +
/// CEmitter + cgen.x.
#[test]
fn cemitter_and_cgen_agree_on_array_element_byte_access() {
    let tmp = std::env::temp_dir().join("xb_sync_arrbyte");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"arrbyte\"\n\
               VERSION \"0.1\"\n\
               FUNCTION ElemByte (s$[], i, j)\n\
                 RETURN s${j}\n\
               END FUNCTION\n\
               FUNCTION Main ()\n\
               DIM words$[3]\n\
               words$[0] = \"abc\"\n\
               words$[1] = \"def\"\n\
               PRINT words$[0]{0}\n\
               PRINT words$[1]{2}\n\
               PRINT ElemByte (words$[], 1)\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse array-byte program")
        .lower_ir()
        .expect("lower array-byte program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "arrbyte_rust", rust_c.as_bytes(), None);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "arrbyte_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret array-byte program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "97\n102\n0\n", "array-byte reference output (ElemByte bare-brace through by-ref param reads its scalar facet = 0, consistent across all backends)");
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled array-element byte access"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled array-element byte access"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// INC on a shared composite-array member (CGEN-SHARED-GLOBAL-V3 follow-up):
/// `INC counters[0].hits` must read AND write through the member-array element
/// — the INC/DEC parser previously discarded the `[0]` subscript, incrementing
/// a bare flattened scalar instead. Locked across interp + CEmitter + cgen.x.
#[test]
fn cemitter_and_cgen_agree_on_inc_composite_member_element() {
    let tmp = std::env::temp_dir().join("xb_sync_inccomp");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"inccomp\"\n\
               VERSION \"0.1\"\n\
               TYPE COUNTER\n\
                 XLONG .hits\n\
               END TYPE\n\
               SHARED COUNTER counters[3]\n\
               FUNCTION Main ()\n\
               counters[0].hits = 5\n\
               counters[1].hits = 10\n\
               INC counters[0].hits\n\
               INC counters[1].hits\n\
               INC counters[1].hits\n\
               PRINT counters[0].hits\n\
               PRINT counters[1].hits\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse inc-composite program")
        .lower_ir()
        .expect("lower inc-composite program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "inccomp_rust", rust_c.as_bytes(), None);
    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "inccomp_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret inc-composite program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "6\n12\n",
        "INC composite-member reference output"
    );
    assert_eq!(
        rust_out, interp_out,
        "CEmitter mishandled INC on composite member"
    );
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled INC on composite member"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// Byte-accurate NUL strings (CGEN-NUL-STRING): a string literal with an embedded
/// NUL (`"\0\0abc"`) must keep all 5 bytes, and a non-final PRINT item must emit
/// every byte (not stop at a NUL). cgen.x emitted `xb_str("\0\0abc")` (strlen
/// truncates → LEN 0) and `printf("%s", s)` for non-last items (stops at NUL →
/// empty). Now it emits `xb_str_n("...", sizeof-1)` (conditionally, mirroring the
/// Rust CEmitter's usage-gated helper) and `fwrite(_pt,1,xb_len(_pt),stdout)`.
/// This flipped atrim (a byte-string trim demo) from a differential diverger to
/// byte-faithful. Byte-neutral on the NUL-free corpus.
#[test]
fn cemitter_and_cgen_agree_on_nul_string() {
    let tmp = std::env::temp_dir().join("xb_sync_nulstr");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"ns\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM s$\n\
               s$ = \"\\0\\0abc\"\n\
               PRINT LEN(s$)\n\
               PRINT \"<\"; s$; \">\"\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse nul-string program")
        .lower_ir()
        .expect("lower nul-string program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "ns_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "ns_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret nul-string program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "5\n<\0\0abc>\n", "NUL-string reference output");
    assert_eq!(rust_out, interp_out, "CEmitter mishandled the NUL string");
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled the NUL string (literal length + PRINT)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// i32 integer semantics (CGEN-SHIFT): XBasic INTEGER is i32, so a hex literal is
/// a signed i32 bit pattern (`0xF8000000` = negative) and arithmetic results wrap
/// at 32 bits. cgen.x stored the literal as a positive i64 and did NOT mask
/// arithmetic results, so `0xF8000000 >> 8` gave the logical `0x00F80000` instead
/// of the arithmetic `0xFFF80000` the interpreter/Rust produce. cgen.x now wraps
/// hex/binary literals and integer arithmetic/bitwise/unary results in `(int32_t)`
/// (byte-neutral for in-range values). This was acrc32's last divergence (its
/// CRC-32 `crc >> 8` + final `crc XOR 0xFFFFFFFF`).
#[test]
fn cemitter_and_cgen_agree_on_i32_overflow() {
    let tmp = std::env::temp_dir().join("xb_sync_i32");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"i3\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM x\n\
               x = 0xF8000000\n\
               PRINT HEX$(x >> 8)\n\
               PRINT HEX$(x XOR 0xFFFFFFFF)\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse i32 program")
        .lower_ir()
        .expect("lower i32 program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "i3_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "i3_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret i32 program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(
        interp_out, "FFF80000\n7FFFFFF\n",
        "i32 arithmetic reference output"
    );
    assert_eq!(rust_out, interp_out, "CEmitter mishandled i32 arithmetic");
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled i32 arithmetic (literal + shift/xor mask)"
    );
    let _ = fs::remove_dir_all(&tmp);
}

/// DO ... LOOP UNTIL / WHILE (CGEN-DO-LOOP): a bare `DO` with a post-test `LOOP
/// UNTIL/WHILE` must be a `do { } while(...)`. cgen.x emitted the bare `DO` as
/// `while (1) {` and the `LOOP UNTIL c` as `} while(!c);`, forming
/// `while(1){ } while(!c);` — an INFINITE empty loop (it hung acrc32's file-read
/// loop). cgen.x now emits every DO-loop as `do { } while(...)`, with a pre-test
/// `DO WHILE/UNTIL` lowered to a leading `if (...) break;`.
#[test]
fn cemitter_and_cgen_agree_on_do_loop_until() {
    let tmp = std::env::temp_dir().join("xb_sync_doloop");
    fs::create_dir_all(&tmp).expect("mkdir");
    let cgen_exe = build_native_cgen(&tmp);

    let src = "PROGRAM \"dl\"\n\
               VERSION \"0.1\"\n\
               FUNCTION Main ()\n\
               DIM i\n\
               i = 0\n\
               DO\n\
               i = i + 1\n\
               PRINT i\n\
               LOOP UNTIL i >= 3\n\
               DO WHILE i < 6\n\
               i = i + 1\n\
               PRINT i\n\
               LOOP\n\
               END FUNCTION\n";
    let prog = FrontendUnit::parse(src)
        .expect("parse do-loop program")
        .lower_ir()
        .expect("lower do-loop program");
    let ir = TextIrEmitter::new().emit_program(&prog);

    let rust_c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_exec(&tmp, "dl_rust", rust_c.as_bytes(), None);

    let self_c = cgen_emit(&cgen_exe, &ir);
    let self_out = compile_and_exec(&tmp, "dl_self", &self_c, None);

    let mut interp = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp)
        .expect("interpret do-loop program");
    let interp_out: String = interp.into_iter().map(|l| format!("{l}\n")).collect();

    assert_eq!(interp_out, "1\n2\n3\n4\n5\n6\n", "DO-loop reference output");
    assert_eq!(rust_out, interp_out, "CEmitter mishandled DO-loop");
    assert_eq!(
        self_out, interp_out,
        "cgen.x mishandled DO ... LOOP UNTIL/WHILE"
    );
    let _ = fs::remove_dir_all(&tmp);
}
