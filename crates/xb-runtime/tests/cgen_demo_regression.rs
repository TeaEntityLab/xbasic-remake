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
