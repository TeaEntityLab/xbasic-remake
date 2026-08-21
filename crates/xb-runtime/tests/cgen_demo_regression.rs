//! CGEN-DEMO-REGRESSION (docs/17): a curated byte-faithfulness gate on the C
//! generator over legacy demo programs, locking the fixes that took the demo
//! sweep from 3 → 114/114 compiled and 36 → 71 byte-faithful.
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
//! is annotated with the emitter feature it guards. `gif`/`Kittedy`/`qbtoxb`
//! produce no output on empty stdin but still lock the codegen that lets them
//! compile (a scalar/array dual-use, nested-block array DIM, or dual-use
//! array-param regression would fail to compile them).

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
    (
        "qbtoxb",
        "nested-block array DIM → dyn + dual-use array param (CGEN-NESTED-DIM)",
    ),
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

/// Multi-dim arrays (CGEN-MULTIDIM): the interpreter flattens `DIM a[i,j,…]` to a
/// 1-D store (row-major); the C backend must compute the same flat offset for
/// `a[i,j]` and the same flat `UBOUND`. Locks the direct (`CEmitter`) path — the
/// CLI default. No demo exercises observable 2-D access (Kittedy is GUI-empty,
/// adatadim SWAP-slices), so this synthetic program is the regression guard.
#[test]
fn cgen_matches_interpreter_on_multidim_arrays() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tXLONG grid[2,3]
\tXLONG cube[1,2,1]
\tXLONG i, j, k
\tFOR i = 0 TO 2
\t\tFOR j = 0 TO 3
\t\t\tgrid[i,j] = i * 10 + j
\t\tNEXT j
\tNEXT i
\tFOR i = 0 TO 2
\t\tFOR j = 0 TO 3
\t\t\tPRINT grid[i,j];
\t\tNEXT j
\t\tPRINT
\tNEXT i
\tPRINT \"grid ubound=\"; UBOUND(grid[])
\tFOR i = 0 TO 1
\t\tFOR j = 0 TO 2
\t\t\tFOR k = 0 TO 1
\t\t\t\tcube[i,j,k] = i * 100 + j * 10 + k
\t\t\tNEXT k
\t\tNEXT j
\tNEXT i
\tPRINT \"cube[1,2,1]=\"; cube[1,2,1]
\tPRINT \"cube ubound=\"; UBOUND(cube[])
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_multidim_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "multidim", &tmp);
    assert_eq!(
        native, interp,
        "multi-dim cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
}

/// GOSUB stack scoping (CGEN-GOSUB-SCOPE): a bare `RETURN` in a gosub-using
/// function lowers to `GosubReturn`; the interpreter scopes GOSUB per function
/// (`Flow::GosubReturn` bubbles up within the function — if no `Gosub` catches
/// it, the function returns). The C backend's `xb_gosub_stack`/`xb_gosub_sp` is a
/// shared GLOBAL, so a function-level `RETURN` reached while a *caller* has an
/// active GOSUB must NOT pop the caller's frame. Fix: each function captures
/// `xb_gosub_base = xb_gosub_sp` on entry and `GosubReturn` pops only while
/// `sp > base`; reaching the base returns from the function. Here `Sub1(0)` takes
/// an early bare `RETURN` while `Main`'s `GOSUB Blk` is active — without the fix
/// it jumps to a garbage address (this is exactly aarray's segfault).
#[test]
fn cgen_matches_interpreter_on_gosub_scope() {
    let source = "\
VERSION \"0.1\"
DECLARE FUNCTION Sub1 (a)
FUNCTION Main
\tINTEGER x
\tGOSUB Blk
\tPRINT \"main done\"
\tRETURN
Blk:
\tx = Sub1(0)
\tPRINT \"blk got \"; x
\tRETURN
END FUNCTION
FUNCTION Sub1 (a)
\tIF a = 0 THEN RETURN
\tGOSUB Helper
\tRETURN
Helper:
\tPRINT \"helper\"
\tRETURN
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_gosub_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "gosubscope", &tmp);
    assert_eq!(
        native, interp,
        "gosub-scope cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
}

/// Expression-context function side effects (interpreter `eval` output-sink bug):
/// a function called in *expression* position (`x = Foo()`, `IF Foo() THEN`)
/// discarded a *local* output buffer, so its PRINTs (and INLINE$ prompts) were
/// swallowed while the return value stayed correct — this made `XBMerge` print
/// nothing. `eval`/`eval_expr` now thread the real output sink. Also locks the C
/// mirror: expression-position INLINE$ prints its literal prompt, and `IFZ s$`
/// (string vs integer `0`) compares byte length — never `xb_scmp(s, 0)`, whose
/// `xb_len(0)` read a bogus length header and crashed (qbtoxb's segfault).
#[test]
fn cgen_matches_interpreter_on_expr_call_side_effects() {
    let source = "\
VERSION \"0.1\"
DECLARE FUNCTION Foo ()
FUNCTION Main
\tINTEGER x
\tx = Foo()
\tPRINT \"x=\"; x
\tIF Foo() THEN PRINT \"cond\"
\ts$ = INLINE$ (\"prompt>\")
\tIFZ s$ THEN PRINT \"empty\"
\ts$ = \"hi\"
\tIFZ s$ THEN PRINT \"wrong\"
\tPRINT \"done\"
END FUNCTION
FUNCTION Foo ()
\tPRINT \"side\"
\tRETURN 1
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_exprcall_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "exprcall", &tmp);
    assert_eq!(
        native, interp,
        "expr-call side-effect cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    // The previously-swallowed side effects must actually appear (guard against a
    // regression that makes BOTH backends silently empty again — which would
    // still be "equal" but wrong).
    assert!(
        interp.contains("side") && interp.contains("prompt>") && interp.contains("empty"),
        "expected expression-context side effects in output: {interp:?}"
    );
}

/// i32 arithmetic semantics (CGEN-SHIFT): XBasic INTEGER is i32 (`RuntimeValue::
/// Integer(i32)`, `wrapping_*`), but the C backend stores values as `intptr_t`
/// (i64) so that label-address integers aren't truncated. Integer arithmetic,
/// bitwise ops, unary, and hex/binary literals are therefore masked to i32 with
/// `(int32_t)(...)` so overflow/shift/sign match the interpreter. Locks the cases
/// that diverge under raw i64: arithmetic right-shift sign-extension of a
/// bit-31-set value, `0xFFFFFFFF` as -1, multiply/add overflow wrap, and XOR with
/// a high-bit literal. This is what makes acrc32's CRC table byte-faithful.
#[test]
fn cgen_matches_interpreter_on_i32_arithmetic() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tXLONG x, y
\tx = 0xEDB88320
\tPRINT HEX$(x, 8)
\ty = x >> 1
\tPRINT HEX$(y, 8)
\tx = 0xFFFFFFFF
\tPRINT HEX$(x >> 8, 8)
\tx = 0x40000000
\ty = x * 4
\tPRINT HEX$(y, 8)
\tx = 0x12345678 XOR 0xFFFFFFFF
\tPRINT HEX$(x, 8)
\tx = 0x7FFFFFFF
\ty = x + 1
\tPRINT HEX$(y, 8)
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_i32_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "i32arith", &tmp);
    assert_eq!(
        native, interp,
        "i32 arithmetic cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
}

/// By-ref parameter write-back (CGEN-BYREF-WRITEBACK): the interpreter's call
/// binding keys write-back on the *argument* being `@arg` (`ByRef`), not the
/// callee's param decl, so the C backend makes a param a pointer (`T* x_ref` with
/// copy-in/copy-out) iff EVERY call site passes it `@` (and none by value). Locks:
/// (1) a scalar `@n` out-param writes back; (2) a composite `@p` out-param writes
/// each member back; (3) a param `@`-ed at one site but passed by value at another
/// (`UseVal`) stays by value and still type-checks (the intersection rule) - here
/// the callee never writes it, so the interp's write-back is a no-op and matches.
/// geo's `GeoPerpendicularLine @L2` is the real-world driver (diverges only on
/// FLOAT-FMT now, not the by-ref part).
#[test]
fn cgen_matches_interpreter_on_byref_writeback() {
    let source = "\
VERSION \"0.1\"
TYPE PT
\tSINGLE .x
\tSINGLE .y
END TYPE
FUNCTION Main
\tINTEGER n
\tPT p
\tINTEGER a, b
\tn = 5
\tDoubler(@n)
\tPRINT \"n=\"; n
\tFillPt(@p)
\tPRINT \"p=\"; p.x; p.y
\ta = 3
\tb = 7
\tUseVal(@a)
\tUseVal(b)
\tPRINT \"a=\"; a
END FUNCTION
FUNCTION Doubler (INTEGER q)
\tq = q * 2
END FUNCTION
FUNCTION FillPt (PT r)
\tr.x = 1.5
\tr.y = 2.5
END FUNCTION
FUNCTION UseVal (INTEGER v)
\tPRINT \"got=\"; v
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_byref_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "byref", &tmp);
    assert_eq!(
        native, interp,
        "by-ref write-back cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
}

/// `XstStringToNumber` (RT-XST): a by-ref builtin that parses a number out of a
/// string, writing `@afterOff`/`@rtype`/`@value$$` and returning specType. The
/// parser is duplicated in the interp (`xst.rs`), the C runtime
/// (`c_runtime.rs::emit_xst_runtime`), and `cgen.x`; this locks all paths
/// byte-identical. Exercises the four `rtype` outcomes and the msc-wrapper
/// extraction (GLOW for SLONG, DMAKE(GHIGH,GLOW) for the DOUBLE f64 bits).
#[test]
fn cgen_matches_interpreter_on_xst_string_to_number() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\ts$ = \"  42abc\"
\te = XstStringToNumber(@s$, 0, @after, @rtype, @v$$)
\tPRINT \"int e=\"; e; \" after=\"; after; \" rtype=\"; rtype; \" val=\"; GLOW(v$$)
\ts2$ = \"-3.14e2 rest\"
\te2 = XstStringToNumber(@s2$, 0, @a2, @rt2, @v2$$)
\tPRINT \"flt e=\"; e2; \" rtype=\"; rt2; \" d=\"; DMAKE(GHIGH(v2$$), GLOW(v2$$))
\ts3$ = \"0xFF\"
\te3 = XstStringToNumber(@s3$, 0, @a3, @rt3, @v3$$)
\tPRINT \"hex e=\"; e3; \" rtype=\"; rt3; \" val=\"; GLOW(v3$$)
\ts4$ = \"5000000000\"
\te4 = XstStringToNumber(@s4$, 0, @a4, @rt4, @v4$$)
\tPRINT \"giant e=\"; e4; \" rtype=\"; rt4; \" v=\"; v4$$
\ts5$ = \"xyz\"
\te5 = XstStringToNumber(@s5$, 0, @a5, @rt5, @v5$$)
\tPRINT \"err e=\"; e5; \" after=\"; a5; \" rtype=\"; rt5
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_xst_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "xst", &tmp);
    assert_eq!(
        native, interp,
        "XstStringToNumber cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    // The parse actually happened (guards against a mutual stub-0 regression).
    assert!(
        interp.contains("val=42") && interp.contains("d=-314") && interp.contains("rtype=14"),
        "expected real parse results: {interp:?}"
    );
}

/// XBSourceLib core libraries that now C-compile and match the interpreter
/// (MIG-SEMANTICS): extends the byte-faithfulness gate beyond the demo corpus to
/// legacy core libs. `msc` exercises the full XBasic type-suffix sanitization
/// (`value@` SBYTE, `value&&` ULONG, …) that a plain `. $ ! #` sanitizer dropped.
/// `geo` exercises `@`-param write-back (CGEN-BYREF-WRITEBACK) AND shortest-float
/// printing (CGEN-FLOAT-FMT) — both now land, so it's byte-faithful. (XBMerge
/// still diverges on RT-ARGS; `ary` on the legacy array ABI — see docs/17.)
#[test]
fn cgen_matches_interpreter_on_xbsourcelib() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_cgen_xbsourcelib_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let libs: &[(&str, &str)] = &[
        ("XBSourceLib/msc/msc.x", "type-suffix sanitization (@ & %)"),
        ("XBSourceLib/utils/mergeTest01.x", "core-lib compile+run"),
        ("XBSourceLib/utils/mergeTest02.x", "core-lib compile+run"),
        ("XBSourceLib/utils/mergeOut02.x", "core-lib compile+run"),
        ("XBSourceLib/fgr/fgr.x", "array-facet fold (dual-use undimmed)"),
        ("XBSourceLib/utils/mergeOut.x", "core-lib compile+run"),
        ("XBSourceLib/utils/mergeTest03.x", "core-lib compile+run"),
        ("XBSourceLib/vgr/vgr.x", "array-facet fold (dual-use undimmed)"),
        ("XBSourceLib/vgr/vgrOld.x", "array-facet fold (dual-use undimmed)"),
        ("XBSourceLib/geo/geo.x", "by-ref write-back + shortest-float printing"),
    ];
    let mut failures = Vec::new();
    for (rel, feature) in libs {
        let source = fs::read_to_string(root.join(rel))
            .unwrap_or_else(|e| panic!("read {rel}: {e}"));
        let stem = Path::new(rel).file_stem().unwrap().to_str().unwrap();
        let interp = interp_output(&source);
        let native = cgen_output(&source, stem, &tmp);
        if native != interp {
            failures.push(format!(
                "{rel} ({feature}): cgen output differs from interpreter\n  \
                 interp={interp:?}\n  cgen  ={native:?}"
            ));
        }
    }
    assert!(
        failures.is_empty(),
        "XBSourceLib cgen regression:\n{}",
        failures.join("\n")
    );
}
