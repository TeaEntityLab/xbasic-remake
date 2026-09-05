//! CGEN-FACET-RETIREMENT slice 5: owned string-dual facets union into
//! `##strDual$` (docs/17 row CGEN-FACET-RETIREMENT, docs/19 §7).
//!
//! Locks the declaration shape for use-based duals the DIM-based scanner
//! misses: the self-hosted cgen.x must emit the split scalar + `_arr`
//! declaration the reference emitter emits. Guards the pass-2 rescan
//! clobber class (facet values rebuilt as scanner-only after the
//! forward-decl block) — a regression there reverts `file$` to a single
//! `char**` decl and fails this test without breaking any behavior gate.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

/// Build the native `cgen` executable from `selfhost/cgen.x` (same seeding
/// as `cgen_cemitter_sync::build_native_cgen`, separate cache dir).
static NATIVE_CGEN: std::sync::LazyLock<PathBuf> = std::sync::LazyLock::new(|| {
    let cgen_src = fs::read_to_string(root().join("selfhost/cgen.x")).expect("read cgen.x");
    let cgen_prog = xb_compiler::FrontendUnit::parse(&cgen_src)
        .expect("parse cgen.x")
        .lower_ir()
        .expect("lower cgen.x");
    let cgen_c = xb_compiler::CEmitter::new().emit_program(&cgen_prog);
    let shared_tmp = std::env::temp_dir().join("xb_strdual_union_cgen");
    let _ = fs::create_dir_all(&shared_tmp);
    let c_path = shared_tmp.join("cgen.c");
    let exe = shared_tmp.join("cgen");
    fs::write(&c_path, &cgen_c).expect("write cgen.c");
    let cc = Command::new("cc")
        .args(["-o", exe.to_str().unwrap(), c_path.to_str().unwrap()])
        .output()
        .expect("run cc for cgen");
    assert!(
        cc.status.success(),
        "cc cgen failed: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    exe
});

fn cgen_emit(ir: &str) -> String {
    let pid = std::process::id();
    let tmp_ir = std::env::temp_dir().join(format!("strdual_{pid}.ir"));
    let tmp_out = std::env::temp_dir().join(format!("strdual_{pid}.c"));
    fs::write(&tmp_ir, ir).unwrap();
    let out = Command::new("sh")
        .arg("-c")
        .arg(format!(
            "{} < {} > {}",
            NATIVE_CGEN.display(),
            tmp_ir.display(),
            tmp_out.display()
        ))
        .output()
        .unwrap();
    assert!(out.status.success(), "cgen failed");
    let data = fs::read(&tmp_out).unwrap();
    let _ = fs::remove_file(&tmp_ir);
    let _ = fs::remove_file(&tmp_out);
    String::from_utf8_lossy(&data).into_owned()
}

fn sanitize(name: &str) -> String {
    name.replace('.', "_")
        .replace('$', "_s")
        .replace('!', "_f")
        .replace('#', "_d")
        .replace('@', "_a")
        .replace('&', "_l")
        .replace('%', "_h")
}

/// True when `c` declares a single-star scalar `char* xb_str_<base>` (excludes
/// `char**` array decls and `char* *..._arr` split-array decls).
fn has_scalar_decl(c: &str, base: &str) -> bool {
    let needle = format!("xb_str_{base}");
    for line in c.lines() {
        let t = line.trim();
        let mut search: &str = t;
        while let Some(p) = search.find(&needle) {
            let before = &search[..p];
            let after = &search[p + needle.len()..];
            let boundary_ok = after
                .chars()
                .next()
                .is_none_or(|ch| !(ch == '_' || ch.is_alphanumeric()));
            if boundary_ok && before.trim_end().ends_with("char*") {
                return true;
            }
            search = &search[p + needle.len()..];
        }
    }
    false
}

/// Use-based duals the DIM scanner misses must lower with the split
/// scalar + `_arr` shape in both emitters.
#[test]
fn cgen_strdual_facet_union_decl_shape() {
    for (src_file, name) in [
        ("fixtures/corpus/v0.1/positive/ubound_test.x", "s$"),
        ("xbasic/demo/arecurse.x", "file$"),
        ("xbasic/demo/xgrids.x", "list$"),
    ] {
        let src = fs::read_to_string(root().join(src_file)).unwrap();
        let prog = xb_compiler::FrontendUnit::parse(&src)
            .unwrap()
            .lower_ir()
            .unwrap();
        let ir = xb_compiler::TextIrEmitter::new().emit_program_with_facets(&prog);
        assert!(
            ir.lines()
                .any(|l| l.contains(&format!("{name}:string")) && l.contains("dual=1")),
            "{src_file} {name}: expected a string dual=1 facet"
        );
        let base = sanitize(name);
        let rust_c = xb_compiler::CEmitter::new().emit_program(&prog);
        let self_c = cgen_emit(&ir);
        for (label, c) in [("rust", rust_c.as_str()), ("cgen.x", self_c.as_str())] {
            assert!(
                has_scalar_decl(c, &base),
                "{src_file} {name}: {label} missing split scalar decl"
            );
            assert!(
                c.contains(&format!("xb_str_{base}_arr")),
                "{src_file} {name}: {label} missing _arr facet"
            );
        }
    }
}
