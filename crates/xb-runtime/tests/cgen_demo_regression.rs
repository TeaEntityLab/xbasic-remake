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
    ("aarray", "cross-function gosub_base + array by-ref dual-use"),
    ("aarray_ISNODE", "int→ptr by-ref array call arg + gosub_base"),
    ("zap", "$$-const array assign + byref-dual param local DIM ub-hoist"),
    ("atools", "string scalar+array dual-use (CGEN-STRDUAL) + cross-fn fold"),
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
        let interp = interp_output_allow_quit(&source);
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

/// Content-preserving local `REDIM` (CGEN-REDIM): resizing a dyn array must keep
/// existing elements and default-fill the grown tail, matching the interpreter's
/// `execute_dim` (slot.rs). cgen previously re-`calloc`d (zeroing everything);
/// it now `realloc`s. (Golden IR doesn't serialize the `redim` flag, so frozen
/// goldens stay on the calloc path — byte-neutral.)
#[test]
fn cgen_matches_interpreter_on_local_redim() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tDIM a[2]
\ta[0] = 5
\ta[1] = 6
\tREDIM a[4]
\ta[4] = 9
\tPRINT \"ub=\"; UBOUND(a[])
\tPRINT \"a0=\"; a[0]; \" a1=\"; a[1]; \" a4=\"; a[4]
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_localredim_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "localredim", &tmp);
    assert_eq!(
        native, interp,
        "local REDIM cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("a0=5 a1=6 a4=9"),
        "REDIM must preserve existing elements: {interp:?}"
    );
}

/// `XstBackStringToBinString$` (RT-XST): pure string function converting XBasic
/// backslash escapes to binary bytes (xst.hlp). Duplicated in interp
/// (`xst::back_to_bin`), the gated C runtime (`emit_back_to_bin_runtime`), and
/// used by msc/fgr/vgr. Exercises `\t \n \xHH \<digit> \<A-F> \<G-V>` and a
/// literal char after `\`.
#[test]
fn cgen_matches_interpreter_on_back_string() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\ts$ = \"X\\tY\\nZ\\x42\\5\\A\\GW\"
\tr$ = XstBackStringToBinString$(@s$)
\tout$ = \"\"
\tFOR i = 1 TO LEN(r$)
\t\tout$ = out$ + STR$(ASC(MID$(r$, i, 1))) + \" \"
\tNEXT
\tPRINT \"len=\"; LEN(r$)
\tPRINT out$
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_backstring_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "backstring", &tmp);
    assert_eq!(
        native, interp,
        "back-string cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("88 9 89 10 90 66 5 10 16 87"),
        "expected decoded escape bytes: {interp:?}"
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

/// By-ref array descriptor (CGEN-BYREF-REDIM, docs/18): a `@array[]` param the
/// callee `REDIM`s must be a `(T** data, intptr_t* ub)` descriptor so the resize
/// + writes reach the caller; `XstQuickSort(@a[], @n[], …)` sorts `a[]` in place
/// and fills/resizes the index array `@n[]` through it. Both duplicated in the
/// interpreter (`call.rs`/`xst.rs`) and the gated C runtimes; this locks
/// interp==cgen for the whole descriptor path (params, REDIM realloc, UBOUND,
/// descriptor call-site, XstQuickSort permutation).
#[test]
fn cgen_matches_interpreter_on_byref_array_descriptor() {
    let source = "\
VERSION \"0.1\"
DECLARE FUNCTION Grow (@a[], newsize)
FUNCTION Main
\tDIM a[2]
\ta[0] = 5 : a[1] = 6 : a[2] = 7
\tGrow(@a[], 5)
\tPRINT \"ub=\"; UBOUND(a[])
\tFOR i = 0 TO UBOUND(a[]) : PRINT \"a\"; i; \"=\"; a[i] : NEXT
\tDIM v[3]
\tv[0] = 30 : v[1] = 10 : v[2] = 20 : v[3] = 40
\tDIM idx[1]
\tXstQuickSort(@v[], @idx[], 0, 3, 0)
\tFOR i = 0 TO 3 : PRINT \"v\"; i; \"=\"; v[i]; \" idx=\"; idx[i] : NEXT
END FUNCTION
FUNCTION Grow (@a[], newsize)
\tREDIM a[newsize]
\ta[newsize] = 99
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_byref_array_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "byrefarray", &tmp);
    assert_eq!(
        native, interp,
        "by-ref array descriptor cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("ub=5") && interp.contains("a5=99") && interp.contains("a1=6"),
        "REDIM-through-@a[] must resize the caller's array + preserve content: {interp:?}"
    );
    assert!(
        interp.contains("v0=10 idx=1") && interp.contains("v3=40 idx=3"),
        "XstQuickSort must sort @v[] + fill the @idx[] permutation: {interp:?}"
    );
}

/// Locks the string `SELECT CASE` fix (`0b42cf1`): the C backend emitted a raw
/// `_sel == xb_str("…")` **pointer** comparison for a string selector, which is
/// always false — the wrong CASE (or CASE ELSE) ran. It must compare by content
/// (`xb_scmp`), matching the interpreter. This is what lets the headless GUI
/// runtime's `CloseWindow` match its CASE; a regression here would silently break
/// every string `SELECT`, so it is locked directly (no GUI loop, no hang risk).
#[test]
fn cgen_matches_interpreter_on_string_select_case() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tDIM msg$
\tmsg$ = \"Close\" + \"Window\"
\tSELECT CASE msg$
\t\tCASE \"Open\"        : PRINT \"open\"
\t\tCASE \"CloseWindow\" : PRINT \"close\"
\t\tCASE ELSE           : PRINT \"else\"
\tEND SELECT
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_string_select_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "strselect", &tmp);
    assert_eq!(
        native, interp,
        "string SELECT CASE cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("close") && !interp.contains("else"),
        "a computed string must match its CASE by content, not pointer identity: {interp:?}"
    );
}

/// Like `interp_output`, but treats a `QUIT(n)` (`RuntimeError::Quit`) as a clean
/// program exit — exactly as the CLI's `run_path` does — keeping the output
/// collected before the quit. GUI demos exit via `QUIT` on `CloseWindow`.
fn interp_output_allow_quit(source: &str) -> String {
    let prog = FrontendUnit::parse(source)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let mut lines = Vec::new();
    match Interpreter::new().execute_main_with_input(&prog, Vec::new(), &mut lines) {
        Ok(_) | Err(xb_runtime::RuntimeError::Quit { .. }) => {}
        Err(e) => panic!("interp execute: {e:?}"),
    }
    lines.into_iter().map(|l| format!("{l}\n")).collect()
}
/// Locks the headless Xgr/Xui GUI runtime (`0b42cf1`): a `DO WHILE
/// XuiGetNextCallback(...)` message loop that `QUIT`s on `CloseWindow` must run to
/// completion (not hang) in **both** backends, and match. `XuiGetNextCallback`
/// delivers one synthetic `CloseWindow` then FALSE. Both sides are timeout-guarded
/// so a regression (infinite loop) fails the test instead of stalling the suite.
#[test]
fn cgen_gui_message_loop_terminates_and_matches() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tDIM grid, message$, v0, v1, v2, v3, kid, r1$
\tXuiCreateWindow (@grid, 100, 100, 200, 200, 0, \"demo\")
\tPRINT \"before-loop\"
\tDO WHILE XuiGetNextCallback (@grid, @message$, @v0, @v1, @v2, @v3, @kid, @r1$)
\t\tSELECT CASE message$
\t\t\tCASE \"CloseWindow\" : PRINT \"got-close\" : QUIT (0)
\t\t\tCASE ELSE          : PRINT \"other\"
\t\tEND SELECT
\tLOOP
\tPRINT \"after-loop\"
END FUNCTION
";
    // Interpreter reference, in a thread so a regressed infinite loop fails fast.
    let src_owned = source.to_string();
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let _ = tx.send(interp_output_allow_quit(&src_owned));
    });
    let interp = rx
        .recv_timeout(std::time::Duration::from_secs(20))
        .expect("interp GUI message loop did not terminate (XuiGetNextCallback regression)");

    // cgen: compile, then spawn + poll try_wait, killing if it overruns.
    let prog = FrontendUnit::parse(source)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let c_src = CEmitter::new().emit_program(&prog);
    let tmp = std::env::temp_dir().join("xb_cgen_gui_loop_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let c_path = tmp.join("guiloop.c");
    let exe = tmp.join("guiloop");
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
        "cc failed for GUI loop: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    let mut child = Command::new(common::exe_path(&exe))
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .expect("spawn binary");
    let deadline = std::time::Instant::now() + std::time::Duration::from_secs(20);
    loop {
        match child.try_wait().expect("try_wait") {
            Some(_) => break,
            None if std::time::Instant::now() >= deadline => {
                let _ = child.kill();
                panic!("cgen GUI message loop did not terminate (XuiGetNextCallback regression)");
            }
            None => std::thread::sleep(std::time::Duration::from_millis(50)),
        }
    }
    let out = child.wait_with_output().expect("wait binary");
    let native: String = out.stdout.iter().map(|&b| b as char).collect();
    let _ = fs::remove_file(&c_path);
    let _ = fs::remove_file(&exe);
    assert_eq!(
        native, interp,
        "GUI message-loop cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("before-loop") && interp.contains("got-close"),
        "the loop must run once, receive the synthetic CloseWindow, and QUIT: {interp:?}"
    );
    assert!(
        !interp.contains("after-loop"),
        "QUIT(0) must terminate before the post-loop PRINT: {interp:?}"
    );
}

/// Locks the `#var$` string-typing fix: a `#`-prefixed variable with a `$`
/// suffix embeds its suffix in the name (SharedName, `suffix: None`), so the
/// reference/by-ref typing (`ref_value_type`) must infer String from the name's
/// trailing char — otherwise `from_suffix(None)` types it Integer and a
/// `"s" + #foo$` concat raises a spurious "expected Integer, got String" (the
/// real acgibin crash). Both backends must agree (faithful). This does NOT assert
/// the single-`#` shared round-trip (assign→read), which is a separate deeper
/// `#`-vs-`##` storage question — only the type/no-crash/faithfulness contract.
#[test]
fn cgen_matches_interpreter_on_hash_string_var() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tname$ = \"HOME\"
\tXstGetEnvironmentVariable (@name$, @#homeDir$)
\tx$ = \"[\" + #homeDir$ + \"]\"
\tPRINT x$
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_hash_string_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "hashstr", &tmp);
    assert_eq!(
        native, interp,
        "#var$ string concat cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.starts_with("[") && interp.contains("]"),
        "a `\"s\" + #foo$` concat must run without a spurious type mismatch: {interp:?}"
    );
}

/// Locks the composite-member array element-type fix. A composite *array* member
/// (e.g. `SHARED DLL library[]`, member `name$`) stores its declared element type
/// in `self.arrays`, NOT `self.symbols`, so `array_access`'s old `auto_symbol`
/// default typed the dotted leaf `library.name` as Integer (no `$` suffix) and a
/// read `library[i].name` emitted an **undeclared** `xb_var_library_name` instead
/// of the String array `xb_str_library_name`, failing `cc`. `src/kernel32.x` — a
/// non-runnable EXTERNAL-bottomed core lib — went from 1 cc error to clean.
/// Compile-clean lock (the fix's contract is type-correct C emission); the
/// composite array-member *runtime* slot registration is a separate tracked bug.
#[test]
fn cgen_composite_member_array_read_compiles_kernel32() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let src = fs::read_to_string(root.join("xbasic-6.4.5/src/linux/kernel32.x"))
        .expect("read kernel32.x");
    let prog = FrontendUnit::parse(&src)
        .expect("parse kernel32")
        .lower_ir()
        .expect("lower kernel32");
    let c_src = CEmitter::new().emit_program(&prog);
    assert!(
        c_src.contains("xb_str_library_name") && !c_src.contains("xb_var_library_name"),
        "the String member `library[i].name` must emit `xb_str_library_name`, \
         not an undeclared Integer `xb_var_library_name`"
    );
    let tmp = std::env::temp_dir().join("xb_cgen_kernel32_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let c_path = tmp.join("kernel32.c");
    fs::write(&c_path, &c_src).expect("write C");
    let cc = Command::new(common::cc::cc())
        .args([
            "-c",
            "-O0",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
            "-o",
            tmp.join("kernel32.o").to_str().unwrap(),
            c_path.to_str().unwrap(),
        ])
        .output()
        .expect("cc spawn");
    assert!(
        cc.status.success(),
        "kernel32 emitted C must compile clean: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    let _ = fs::remove_file(&c_path);
}

/// Locks the shared-global collection fix: `collect_shared` (c_runtime.rs) walked
/// an `If`'s bodies but SKIPPED its condition, so a shared var referenced ONLY in
/// a condition (`IF ##Flag != 0 …`) never got a `xb_shared_Flag` global declared —
/// an undeclared-identifier cc failure. This unblocked core libs `MakeDistLinux`
/// and `xutpde` (`IF ##XBSystem != …`). Runnable + faithful: an unset shared reads
/// its default (0), matching the interpreter's permissive auto-declare.
#[test]
fn cgen_matches_interpreter_on_shared_var_in_if_condition() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tIF ##Flag != 0 THEN
\t\tPRINT \"set\"
\tELSE
\t\tPRINT \"unset\"
\tEND IF
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_shared_if_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "sharedif", &tmp);
    assert_eq!(
        native, interp,
        "shared-var-in-IF-condition cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert_eq!(
        interp.trim(),
        "unset",
        "an unset shared var read in an IF condition must default to 0: {interp:?}"
    );
}

/// Locks the 2-arg `ASC(s$, n)` fix: the interpreter's ASC reads only `args[0]`
/// (byte 0), ignoring an optional position arg, and the C runtime `xb_asc` is
/// 1-arg — but the emitter passed all args, so `ASC(line$, 1)` (core libs
/// CreateHelp/xcol) emitted `xb_asc(s, 1)` and failed `cc` with "too many
/// arguments". The emitter now drops ASC's extra args, matching the interpreter.
#[test]
fn cgen_matches_interpreter_on_asc_two_arg() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tline$ = \"Colon\"
\tIF ASC (line$, 1) = 67 THEN
\t\tPRINT \"C-first\"
\tELSE
\t\tPRINT \"other\"
\tEND IF
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_asc2_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "asc2", &tmp);
    assert_eq!(
        native, interp,
        "2-arg ASC cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert_eq!(
        interp.trim(),
        "C-first",
        "`ASC(line$, 1)` must read the first byte (67='C'): {interp:?}"
    );
}

/// Locks the `SIZE(var$)` typing fix: the SIZE handler destructured
/// `Identifier { name, .. }`, dropping the type suffix, then called
/// `auto_symbol(name)` — so `SIZE(time$)` typed the symbol Integer (bare `time`,
/// last char not `$`) and emitted `sizeof(xb_var_time)`, an undeclared Integer
/// (core lib xin). SIZE now resolves via `symbol(name, suffix)` (same as a normal
/// read), so a String var reads `xb_str_*`. A scalar String's SIZE is 8 (pointer
/// slot), matching the interpreter.
#[test]
fn cgen_matches_interpreter_on_size_of_string_var() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\ts$ = \"hello\"
\tPRINT SIZE (s$); \"/\"; SIZE (XLONG)
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_size_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "sizestr", &tmp);
    assert_eq!(
        native, interp,
        "SIZE(var$) cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert_eq!(
        interp.trim(),
        "8/4",
        "SIZE of a scalar String is the 8-byte slot; SIZE(XLONG) is 4: {interp:?}"
    );
}

/// Locks the unary-POS-on-String fix (`+ s$`, xrun.x line 149 `+ log$ + …`). The
/// interpreter's POS is identity (`Pos => v`, any type), but `unary()` in
/// semantics mapped a String operand to an Integer *result* — so `+s$` was typed
/// Integer while holding a String, crashing the interp's arith ("expected
/// Integer, got Integer") and emitting `+`-on-`char*` (invalid C) in the backend.
/// POS now keeps the operand's type; the C emitter passes a String POS through
/// unchanged. Flipped core lib xrun (11/18 `src/` libs compile).
#[test]
fn cgen_matches_interpreter_on_unary_pos_string() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\ts$ = \"hi\"
\tt$ = + s$ + \"!\"
\tPRINT t$
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_pos_string_regression");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "posstr", &tmp);
    assert_eq!(
        native, interp,
        "unary +string cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert_eq!(
        interp.trim(),
        "hi!",
        "unary POS on a String is identity, so `+s$ + \"!\"` concatenates: {interp:?}"
    );
}

/// Locks CGEN-SHARED-ARR: a `SHARED a[]` array written in one function must be
/// visible (same storage) in another. cgen emitted a per-function LOCAL, so each
/// function saw its own uninitialized copy (interp keeps them in `state.shared`,
/// one global). Now emitted as ONE heap global. Verified runnable end-to-end.
#[test]
fn cgen_matches_interpreter_on_shared_scalar_array_cross_function() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tSetup ()
\tShow ()
END FUNCTION
FUNCTION Setup ()
\tSHARED a[]
\tREDIM a[1]
\ta[0] = 7 : a[1] = 9
END FUNCTION
FUNCTION Show ()
\tSHARED a[]
\tPRINT a[0]; \"/\"; a[1]
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_shared_arr_scalar");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "sharrscl", &tmp);
    assert_eq!(
        native, interp,
        "SHARED scalar array cross-function cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert_eq!(interp.trim(), "7/9", "a SHARED array must persist across functions: {interp:?}");
}

/// Locks CGEN-SHARED-ARR for a SHARED composite ARRAY (`SHARED Rec r[]`, member
/// `.nm$`/`.id`) written in one function + read in another — the xst/kernel32
/// pattern. Each member array is one heap global; the composite member WRITE
/// (`r[i].nm = …`) resolves its String element type from `self.arrays` (mirrors
/// the read fix), not the Integer `auto_symbol` default.
#[test]
fn cgen_matches_interpreter_on_shared_composite_array_cross_function() {
    let source = "\
VERSION \"0.1\"
TYPE Rec
\tXLONG .id
\tSTRING .nm
END TYPE
FUNCTION Main
\tSetup ()
\tShow ()
END FUNCTION
FUNCTION Setup ()
\tSHARED Rec r[]
\tREDIM r[1]
\tr[0].nm = \"alice\" : r[0].id = 7
\tr[1].nm = \"bob\"   : r[1].id = 9
END FUNCTION
FUNCTION Show ()
\tSHARED Rec r[]
\tFOR i = 0 TO 1
\t\tPRINT r[i].nm; \"=\"; r[i].id
\tNEXT
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_shared_arr_composite");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "sharrcmp", &tmp);
    assert_eq!(
        native, interp,
        "SHARED composite array cross-function cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("alice=7") && interp.contains("bob=9"),
        "a SHARED composite array's members must persist + type correctly across functions: {interp:?}"
    );
}

/// Locks the typed int/string VAR-SUFFIX-COLLISION DIM fix (xdis `imm`/`imm$`):
/// `XLONG imm` + `STRING imm$` both lowered a *scalar* `Dim` to slot `imm`
/// (`dim` used the bare name, not the collision-aware `slot_name` that reads
/// use), so `imm` was DIM'd twice (int + string) → flagged dyn → the hoist
/// declared only one type facet, leaving the other (`xb_str_imm`) undeclared in
/// C. The scalar `Dim` now uses `slot_name`, so `imm$` declares slot `imm$`
/// (`xb_str_imm_s`) distinct from `imm`'s `xb_var_imm`. Non-colliding DIMs keep
/// the bare name (byte-neutral).
#[test]
fn cgen_matches_interpreter_on_typed_int_string_collision() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tXLONG imm
\tSTRING imm$
\timm = 5 : imm$ = \"hex\"
\tPRINT imm; \"/\"; imm$
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_typed_collision");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "typedcol", &tmp);
    assert_eq!(
        native, interp,
        "typed int/string collision cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert_eq!(
        interp.trim(),
        "5/hex",
        "`XLONG imm` and `STRING imm$` are distinct slots: {interp:?}"
    );
}

/// Locks the CGEN-SHARED-ARR composite-member gate (xin `host.address`): a name
/// used as a scalar composite (`Rec host`) in one function AND a SHARED composite
/// array (`SHARED Rec host[]`) in another shares flattened member slots
/// (`host.id`). The array member must NOT become a heap-global pointer (which
/// would clash with the scalar `host.id` uses); it stays local. `collect_dual_use`
/// skips dotted names, so a dedicated scalar-DIM'd exclusion gates it.
#[test]
fn cgen_matches_interpreter_on_composite_scalar_vs_shared_array() {
    let source = "\
VERSION \"0.1\"
TYPE Rec
\tXLONG .id
\tSTRING .nm
END TYPE
FUNCTION Main
\tRec host
\thost.id = 5 : host.nm = \"sc\"
\tFill ()
\tPRINT host.nm; \"=\"; host.id
END FUNCTION
FUNCTION Fill ()
\tSHARED Rec host[]
\tREDIM host[1]
\thost[0].id = 7 : host[0].nm = \"arr\"
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_composite_scalar_shared");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "compsclshr", &tmp);
    assert_eq!(
        native, interp,
        "composite scalar vs shared array cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert_eq!(
        interp.trim(),
        "sc=5",
        "the scalar composite `host` must be independent of the SHARED `host[]` array: {interp:?}"
    );
}

/// Locks the interpreter's unary negation of an i32::MIN literal. `-2147483648`
/// parses as `neg(2147483648)`, and `2147483648` (2^31) overflows i32 so it is
/// typed Giant; `neg(Giant)` previously errored ("expected Integer, got Giant"),
/// while the C backends produced i32::MIN. `neg` now wraps (two's complement) and
/// the Giant->Integer assignment coercion narrows to i32::MIN, matching cgen.
/// Guards MIN_INT / &H80000000 constants against interp-vs-cgen divergence.
#[test]
fn cgen_matches_interpreter_on_int_min_literal() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tDIM z
\tz = -2147483648
\tPRINT z
\tPRINT ROTATEL(z, 1)
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_int_min");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "intmin", &tmp);
    assert_eq!(
        native, interp,
        "i32::MIN literal cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("-2147483648") && !interp.to_lowercase().contains("error"),
        "z = -2147483648 must evaluate (not error) in the interpreter: {interp:?}"
    );
}

/// Locks bitwise/logical ops with a Giant operand. A large decimal mask like
/// `2147483648` (2^31) overflows i32 so it is typed Giant; the interp's `AND`/`OR`/
/// `XOR`/`NOT`/logical handlers previously required both operands be Integer and
/// errored on Giant ("expected Integer, got String"), while the C backends did the
/// 32-bit bitwise op. `bit_operand` now narrows Giant to the low 32 bits so the
/// interpreter matches cgen. Guards `&H80000000`-class masks written in decimal.
#[test]
fn cgen_matches_interpreter_on_bitwise_giant_operand() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tDIM x
\tx = 5
\tPRINT x OR 2147483648
\tPRINT x AND 2147483648
\tPRINT NOT 2147483648
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_bitwise_giant");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "bwgiant", &tmp);
    assert_eq!(
        native, interp,
        "bitwise-with-Giant cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("-2147483643") && !interp.to_lowercase().contains("error"),
        "bitwise op with a Giant mask must evaluate (not error) in the interpreter: {interp:?}"
    );
}

/// Locks control-flow truthiness of a Giant condition. `IF 2147483648 THEN` (the
/// bare literal overflows i32 -> Giant) was skipped by the interp (its IF/WHILE/DO
/// handlers matched only `Integer`, treating a Giant condition as neither-true-nor
/// -false and skipping the branch), while the C backends took it (nonzero -> true).
/// `cond_bool` now tests Integer/Giant against zero on the full value. Guards
/// `IF <giant-flag>` / `WHILE <giant>` against interp-vs-cgen divergence.
#[test]
fn cgen_matches_interpreter_on_giant_condition() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tDIM x
\tx = 5
\tIF x < 2147483648 THEN
\t\tPRINT \"less\"
\tEND IF
\tIF 2147483648 THEN
\t\tPRINT \"truthy\"
\tEND IF
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_giant_cond");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "giantcond", &tmp);
    assert_eq!(
        native, interp,
        "Giant-condition cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        interp.contains("truthy"),
        "a nonzero Giant condition must be truthy in the interpreter: {interp:?}"
    );
}

/// Locks Giant-argument coercion for Integer-parameter builtins. `STR$`/`ABS`
/// declare Integer params; a Giant arg (e.g. `2147483648` = 2^31, which overflows
/// i32) previously errored in the interp ("expected .., got Giant") while the C
/// backends narrowed it (parameter coercion). The interp's builtin call path now
/// narrows Giant->i32 for Integer params (via `xb_compiler::builtin_param_types`),
/// matching cgen. Giant-accepting builtins (Giant params, e.g. GHIGH) are untouched.
#[test]
fn cgen_matches_interpreter_on_giant_arg_to_int_builtin() {
    let source = "\
VERSION \"0.1\"
FUNCTION Main
\tPRINT STR$(2147483648)
\tPRINT ABS(2147483648)
END FUNCTION
";
    let tmp = std::env::temp_dir().join("xb_cgen_giant_arg");
    fs::create_dir_all(&tmp).expect("mkdir");
    let interp = interp_output(source);
    let native = cgen_output(source, "giantarg", &tmp);
    assert_eq!(
        native, interp,
        "Giant-arg-to-Integer-builtin cgen output differs from interpreter\n  interp={interp:?}\n  cgen  ={native:?}"
    );
    assert!(
        !interp.to_lowercase().contains("error"),
        "a Giant arg to an Integer-param builtin must coerce (not error) in the interpreter: {interp:?}"
    );
}
