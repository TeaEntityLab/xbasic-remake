//! Every `.s` (assembly) file in the XBasic source tree must have a
//! `.x` (XBasic source) or `.c` (C source) counterpart.  This prevents
//! features from leaking into assembly-only files with no readable
//! source equivalent.
//!
//! The infrastructure `.s` files in `src/linux/lib/` (appstart, xstart,
//! xzzz, xlib) have `.c` reference stubs pointing at the canonical LGPL
//! C ports in `src/crtl/` and the Rust toolchain replacement — no
//! LGPL-derived code is duplicated outside `src/crtl/` (see
//! LICENSING.md).  Superseded dated snapshots live in
//! `src/linux/lib/old-versions/` (own README) and are skipped here.
//!
//! The legacy tree is gitignored local reference material; both tests
//! skip when it is absent (fresh clones, CI).

use std::path::{Path, PathBuf};

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("..")
        .canonicalize()
        .unwrap_or_else(|_| Path::new(".").to_path_buf())
}

fn collect_ext(dir: &Path, ext: &str, out: &mut Vec<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            // Archived superseded snapshots — documented in their README.
            if path.file_name().and_then(|n| n.to_str()) == Some("old-versions") {
                continue;
            }
            collect_ext(&path, ext, out);
        } else if path.extension().and_then(|e| e.to_str()) == Some(ext) {
            out.push(path);
        }
    }
}

#[test]
fn every_s_file_has_x_or_c_counterpart() {
    let root = repo_root();
    let src = root.join("xbasic-6.4.5").join("src");
    if !src.exists() {
        return; // legacy corpus is gitignored local material; absent in CI
    }

    let mut s_files = Vec::new();
    collect_ext(&src, "s", &mut s_files);

    assert!(
        !s_files.is_empty(),
        "xbasic-6.4.5/src exists but no .s files found — directory scan broken"
    );

    let mut missing: Vec<String> = Vec::new();
    for s in &s_files {
        let stem = s.file_stem().unwrap().to_str().unwrap();
        let dir = s.parent().unwrap();
        let x = dir.join(format!("{stem}.x"));
        let c = dir.join(format!("{stem}.c"));
        if !x.exists() && !c.exists() {
            missing.push(s.display().to_string());
        }
    }

    assert!(
        missing.is_empty(),
        "{} .s file(s) have no .x or .c counterpart (features may be leaked in assembly):\n{}",
        missing.len(),
        missing.join("\n")
    );
}

/// Every `.a` (static archive) member must trace back to a `.x` or `.c`
/// source file somewhere in the tree.  The archive is precompiled; this
/// test ensures no object in it is assembly-only with no source.
#[test]
fn every_a_member_has_source_counterpart() {
    let root = repo_root();
    let src = root.join("xbasic-6.4.5").join("src");
    let archive = src.join("bin").join("libxb64.a");
    if !archive.exists() {
        return; // archive not present in all checkouts
    }

    // Collect all .x and .c stems in the tree
    let mut x_files = Vec::new();
    let mut c_files = Vec::new();
    collect_ext(&src, "x", &mut x_files);
    collect_ext(&src, "c", &mut c_files);

    let source_stems: std::collections::HashSet<String> = x_files
        .iter()
        .chain(c_files.iter())
        .filter_map(|p| {
            p.file_stem()
                .and_then(|s| s.to_str())
                .map(|s| s.to_string())
        })
        .collect();

    // Known archive members (from `ar t libxb64.a`)
    let members = [
        "appstart", "xrun", "xlib", "xin", "xcm", "xma", "xst", "xgr", "kernel32", "gdi32",
        "user32", "xbiface", "chkmem", "xui", "xut", "xzzz",
    ];

    let mut missing: Vec<String> = Vec::new();
    for member in &members {
        if !source_stems.contains(*member) {
            missing.push(member.to_string());
        }
    }

    assert!(
        missing.is_empty(),
        "{} archive member(s) have no .x or .c source counterpart:\n{}",
        missing.len(),
        missing.join(", ")
    );
}
