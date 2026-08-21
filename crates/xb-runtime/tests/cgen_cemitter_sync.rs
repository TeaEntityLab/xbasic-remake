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
