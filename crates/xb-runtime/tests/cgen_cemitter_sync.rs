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
//! byte-identical (helper ordering/formatting and parameter names differ —
//! tracked in `docs/16-cgen-cemitter-sync-roadmap.md`, item CG-BYTES). Output
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
        let rust_out =
            compile_and_exec(&tmp, &format!("{stem}_rust"), rust_c.as_bytes(), input_ref);

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
    assert_eq!(rust_out, interp_out, "CEmitter dropped/truncated the embedded NUL");
    assert_eq!(self_out, interp_out, "cgen.x dropped/truncated the embedded NUL");
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
    assert_eq!(self_out, rust_out, "cgen.x diverged from CEmitter on high bytes");
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
    assert_eq!(rust_out, interp_out, "CEmitter computed-GOTO dispatch differs");
    assert_eq!(self_out, interp_out, "cgen.x computed-GOTO dispatch differs");
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
    assert_eq!(rust_out, interp_out, "CEmitter dropped the AT-write value side effect");
    assert_eq!(self_out, interp_out, "cgen.x dropped the AT-write value side effect");
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
    assert_eq!(rust_out, interp_out, "CEmitter diverged on unary pos / SIZE");
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
    assert_eq!(rust_out, self_out, "cgen.x float-arith typing differs from CEmitter");
    assert_eq!(rust_out, interp_out, "float-arith typing differs from interpreter");
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
    assert_eq!(rust_out, self_out, "cgen.x multi-dim differs from CEmitter (sync drift)");
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

    assert_eq!(interp_out, "5\n0\n1\n2\n3\nhi\n10\n", "undeclared-local reference output");
    assert_eq!(rust_out, self_out, "cgen.x undeclared-local hoisting differs from CEmitter");
    assert_eq!(rust_out, interp_out, "undeclared-local hoisting differs from interpreter");
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

    assert_eq!(interp_out, "from entry\n21\n", "non-main-entry reference output");
    assert_eq!(rust_out, self_out, "cgen.x non-Main entry differs from CEmitter");
    assert_eq!(rust_out, interp_out, "non-Main entry differs from interpreter");
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
    assert_eq!(rust_out, self_out, "cgen.x unknown-call handling differs from CEmitter");
    assert_eq!(rust_out, interp_out, "unknown-call handling differs from interpreter");
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
    assert_eq!(rust_out, self_out, "cgen.x bare-return differs from CEmitter");
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

    assert_eq!(interp_out, "1\n", "duplicate-function first-wins reference output");
    assert_eq!(rust_out, self_out, "cgen.x function dedup differs from CEmitter");
    assert_eq!(rust_out, interp_out, "function dedup differs from interpreter");
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
    assert_eq!(interp_out, "3\n10\n", "arg-count reconciliation reference output");
    assert_eq!(rust_out, self_out, "cgen.x arg-count reconciliation differs from CEmitter");
    assert_eq!(rust_out, interp_out, "arg-count reconciliation differs from interpreter");
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

    assert_eq!(interp_out, "Prompt: \ngot[]\n", "INLINE$ empty-stdin reference output");
    assert_eq!(rust_out, self_out, "cgen.x INLINE$ helper differs from CEmitter");
    assert_eq!(rust_out, interp_out, "INLINE$ helper differs from interpreter");
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

    assert_eq!(interp_out, "start \"MID\" end\n", "escaped-quote concat reference output");
    assert_eq!(rust_out, self_out, "cgen.x escaped-quote concat differs from CEmitter");
    assert_eq!(rust_out, interp_out, "escaped-quote concat differs from interpreter");
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
    assert_eq!(rust_out, self_out, "cgen.x type-suffix identifier differs from CEmitter");
    assert_eq!(rust_out, interp_out, "type-suffix identifier differs from interpreter");
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

    assert_eq!(interp_out, "[]\n", "unknown string-call reference output (empty, not null)");
    assert_eq!(rust_out, self_out, "cgen.x unknown string-call default differs from CEmitter");
    assert_eq!(rust_out, interp_out, "unknown string-call default differs from interpreter");
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
    assert_eq!(rust_out, self_out, "cgen.x leading-zero literal differs from CEmitter");
    assert_eq!(rust_out, interp_out, "leading-zero literal differs from interpreter");
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
    assert_eq!(interp_out, "ateof\n", "EOF(handle) empty-stdin reference output");
    assert_eq!(rust_out, self_out, "cgen.x EOF arg handling differs from CEmitter");
    assert_eq!(rust_out, interp_out, "EOF arg handling differs from interpreter");
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
