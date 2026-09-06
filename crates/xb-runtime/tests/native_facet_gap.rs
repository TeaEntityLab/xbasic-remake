//! P1 of docs/19 §9 (compiler.x facet emission): the native compiler's
//! `##FACETS##` dump must agree with the Rust `TextIrEmitter` on the
//! allStrArr field — the set of names whose facet is `type=string`,
//! `rank>=1`, without `storage=shared`, `storage=param`, or `byref=1`
//! (the exact predicate cgen.x uses to rebuild `##allStrArr$` from facets).
//!
//! P1 storage is syntactic only (`fixed`/`shared` from the `#` prefix;
//! `dual=0` placeholder; no param/member/descriptor facts), which suffices
//! for this field: every other storage value the reference emitter produces
//! (`dyn`, `param`, `byref=1`) is excluded by the same predicate, and names
//! with no native facet are absent from both sets. Scope values are not
//! compared (cgen.x consumes the set program-wide). Corpus per §9.4:
//! selfhost tools + positive corpus.
mod common;

use std::collections::BTreeSet;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;
use xb_compiler::{FrontendUnit, TextIrEmitter};

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

/// Build the native compiler (compA) from `selfhost/compiler.x` via the Rust
/// `CEmitter` (same seeding as `native_pipeline`, separate cache dir).
static NATIVE_COMP: std::sync::LazyLock<PathBuf> = std::sync::LazyLock::new(|| {
    let comp_src = fs::read_to_string(root().join("selfhost/compiler.x")).expect("read compiler.x");
    let comp_prog = FrontendUnit::parse(&comp_src)
        .expect("parse compiler.x")
        .lower_ir()
        .expect("lower compiler.x");
    let comp_c = xb_compiler::CEmitter::new().emit_program(&comp_prog);
    let shared_tmp = std::env::temp_dir().join("xb_native_facet_gap");
    let _ = fs::create_dir_all(&shared_tmp);
    let c_path = shared_tmp.join("compA.c");
    let exe = shared_tmp.join("compA");
    fs::write(&c_path, &comp_c).expect("write compA.c");
    let cc = Command::new(common::cc::cc())
        .args(["-o", exe.to_str().unwrap(), c_path.to_str().unwrap()])
        .output()
        .expect("run cc for compA");
    assert!(
        cc.status.success(),
        "cc compA failed: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    exe
});

/// The allStrArr field of a facet stream: names satisfying cgen.x's
/// `##allStrArr$` rebuild predicate (`cgen.x`: `type=string`, `rank>=1`,
/// no `storage=shared`, no `storage=param`, no `byref=1`).
fn allstrarr_field(text: &str) -> BTreeSet<String> {
    let mut set = BTreeSet::new();
    for line in text.lines() {
        let body = match line.strip_prefix("facet ") {
            Some(b) => b,
            None => continue,
        };
        let colon = match body.find(':') {
            Some(c) => c,
            None => continue,
        };
        let name = &body[..colon];
        // P1 allowlist (docs/19 §9.4; shrinks at P5): dotted member facets
        // (employee.city) need composite TYPE/member parsing plus P2 dual
        // analysis, neither of which P1 has. Skipped on both sides; the
        // gate covers plain names.
        if name.contains('.') {
            continue;
        }
        let rest = &body[colon + 1..];
        let ty = rest.split(' ').next().unwrap_or("");
        if ty != "string" {
            continue;
        }
        let rank = match rest.find(" rank=") {
            Some(p) => rest[p + 6..]
                .split(' ')
                .next()
                .unwrap_or("0")
                .parse::<i64>()
                .unwrap_or(0),
            None => continue,
        };
        if rank < 1 {
            continue;
        }
        if rest.contains(" storage=shared")
            || rest.contains(" storage=param")
            || rest.contains(" byref=1")
        {
            continue;
        }
        set.insert(name.to_string());
    }
    set
}
/// The dual field: `(scope, name)` pairs whose facet carries `dual=1`.
/// Dotted member names take the same P1/P5 allowlist as the allStrArr field.
fn dual_field(text: &str) -> BTreeSet<(String, String)> {
    let mut set = BTreeSet::new();
    for line in text.lines() {
        let body = match line.strip_prefix("facet ") {
            Some(b) => b,
            None => continue,
        };
        let colon = match body.find(':') {
            Some(c) => c,
            None => continue,
        };
        let name = &body[..colon];
        if name.contains('.') {
            continue;
        }
        let rest = &body[colon + 1..];
        let scope = match rest.find(" scope=") {
            Some(p) => rest[p + 7..].split(' ').next().unwrap_or(""),
            None => continue,
        };
        let is_dual = match rest.find(" dual=") {
            Some(p) => rest[p + 6..].starts_with('1'),
            None => false,
        };
        if is_dual {
            set.insert((scope.to_string(), name.to_string()));
        }
    }
    set
}
fn rust_facets(
    src: &str,
    label: &str,
) -> (
    BTreeSet<String>,
    BTreeSet<String>,
    BTreeSet<(String, String)>,
) {
    let prog = FrontendUnit::parse(src)
        .unwrap_or_else(|e| panic!("Rust parse failed for {label}: {e:?}"))
        .lower_ir()
        .unwrap_or_else(|e| panic!("Rust lower failed for {label}: {e:?}"));
    let ir = TextIrEmitter::new().emit_program_with_facets(&prog);
    let include = allstrarr_field(&ir);
    let mut byref = BTreeSet::new();
    for line in ir.lines() {
        let body = match line.strip_prefix("facet ") {
            Some(b) => b,
            None => continue,
        };
        let colon = match body.find(':') {
            Some(c) => c,
            None => continue,
        };
        let name = &body[..colon];
        if name.contains('.') {
            continue;
        }
        if body[colon + 1..].contains(" byref=1") {
            byref.insert(name.to_string());
        }
    }
    (include, byref, dual_field(&ir))
}

fn native_facets(
    comp: &Path,
    src: &str,
    label: &str,
) -> (BTreeSet<String>, BTreeSet<(String, String)>) {
    let mut child = Command::new(common::exe_path(comp))
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("spawn compA");
    child
        .stdin
        .take()
        .expect("compA stdin")
        .write_all(format!("##FACETS##\n{src}").as_bytes())
        .expect("write source");
    let out = child.wait_with_output().expect("wait compA");
    assert!(
        out.status.success(),
        "compA failed on {label} (exit {:?}): {}",
        out.status.code(),
        String::from_utf8_lossy(&out.stderr)
    );
    let text = String::from_utf8_lossy(&out.stdout);
    (allstrarr_field(&text), dual_field(&text))
}

fn collect_x(dir: &Path, out: &mut Vec<(String, PathBuf)>, root: &Path) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let p = entry.path();
        if p.is_dir() {
            collect_x(&p, out, root);
        } else if p.extension().and_then(|e| e.to_str()) == Some("x") {
            let label = p
                .strip_prefix(root)
                .unwrap_or(&p)
                .to_str()
                .unwrap()
                .to_string();
            out.push((label, p));
        }
    }
}

fn run_facet_gap() -> (
    usize,
    usize,
    Vec<(String, Vec<String>, Vec<String>)>,
    usize,
    usize,
    Vec<(String, Vec<(String, String)>, Vec<(String, String)>)>,
) {
    let comp = NATIVE_COMP.clone();
    let r = root();
    let mut corpus: Vec<(String, PathBuf)> = Vec::new();
    // Same roots as facet_scanner_gap's 234-program universe: the dump path
    // needs only the lexer + pre-pass, so parser coverage is no constraint.
    // compA exit is asserted per program: a capacity overflow (srcLines$,
    // token tables) or uncovered syntax fails loudly instead of comparing
    // truncated output.
    for dir in [
        "xbasic/demo",
        "xbasic/lib",
        "selfhost",
        "fixtures/corpus/v0.1/positive",
        "fixtures/corpus/v0.1/selfhost",
    ] {
        collect_x(&r.join(dir), &mut corpus, &r);
    }
    corpus.sort();
    assert!(corpus.len() >= 200, "corpus unexpectedly small");
    let mut nonzero_programs = 0usize;
    let mut total_names = 0usize;
    let mut carved_byref = 0usize;
    let mut diffs: Vec<(String, Vec<String>, Vec<String>)> = Vec::new();
    let mut dual_programs = 0usize;
    let mut dual_names = 0usize;
    let mut dual_diffs: Vec<(String, Vec<(String, String)>, Vec<(String, String)>)> = Vec::new();
    for (label, path) in &corpus {
        let src = fs::read_to_string(path).expect("read corpus program");
        let (rust, rust_byref, rust_dual) = rust_facets(&src, label);
        let (native, native_dual) = native_facets(&comp, &src, label);
        if !rust.is_empty() || !native.is_empty() {
            nonzero_programs += 1;
            total_names += rust.len();
            eprintln!("{label}: rust={} native={}", rust.len(), native.len());
        }
        if native != rust {
            // P1 carve-out (docs/19 §9.4; P4 removes it): native-only names
            // that Rust marks byref=1 need descriptor/call-graph analysis
            // no syntactic P1 rule can soundly reproduce. rust-only names
            // always fail: anything Rust includes, P1 must also include.
            let hard_native: Vec<String> = native
                .difference(&rust)
                .filter(|n| !rust_byref.contains(n.as_str()))
                .cloned()
                .collect();
            carved_byref += native
                .len()
                .saturating_sub(rust.len())
                .saturating_sub(hard_native.len());
            let rust_only: Vec<String> = rust.difference(&native).cloned().collect();
            if !hard_native.is_empty() || !rust_only.is_empty() {
                diffs.push((label.clone(), hard_native, rust_only));
            }
        }
        if !rust_dual.is_empty() || !native_dual.is_empty() {
            dual_programs += 1;
            dual_names += rust_dual.len();
        }
        if native_dual != rust_dual {
            dual_diffs.push((
                label.clone(),
                native_dual.difference(&rust_dual).cloned().collect(),
                rust_dual.difference(&native_dual).cloned().collect(),
            ));
        }
    }
    eprintln!(
        "programs={} nonzero={} total_names={} differing={} carved_byref={}",
        corpus.len(),
        nonzero_programs,
        total_names,
        diffs.len(),
        carved_byref
    );
    for (label, native_only, rust_only) in &diffs {
        eprintln!("DIFF {label}: native-only={native_only:?} rust-only={rust_only:?}");
    }
    eprintln!(
        "dual_programs={} dual_names={} dual_differing={}",
        dual_programs,
        dual_names,
        dual_diffs.len()
    );
    for (label, native_only, rust_only) in &dual_diffs {
        eprintln!("DUAL-DIFF {label}: native-only={native_only:?} rust-only={rust_only:?}");
    }
    (
        nonzero_programs,
        total_names,
        diffs,
        dual_programs,
        dual_names,
        dual_diffs,
    )
}

#[test]
fn native_facet_gap_allstrarr_field_matches_rust() {
    let (nonzero_programs, _total_names, diffs, _, _, _) = run_facet_gap();
    // A both-sides-empty regression (e.g. hook silently stops firing) must
    // not pass: the corpus is known to hold string arrays.
    assert!(
        nonzero_programs >= 3,
        "gate looks vacuous: only {nonzero_programs} programs with facets"
    );
    assert!(
        diffs.is_empty(),
        "{} programs differ (see DIFF lines above)",
        diffs.len()
    );
}

#[test]
#[ignore = "P2 owns dual (use-based scan_dual_use$ port); the allstrarr gate above is the P1 lock"]
fn native_facet_gap_dual_field_matches_rust() {
    let (_, _, _, _, dual_names, dual_diffs) = run_facet_gap();
    assert!(
        dual_names > 0,
        "dual gate looks vacuous: no dual=1 facets anywhere"
    );
    assert!(
        dual_diffs.is_empty(),
        "{} programs differ on dual= (see DUAL-DIFF lines above)",
        dual_diffs.len()
    );
}
