//! MIG-CORPUS-GATE (docs/17): regression gate on legacy migration parse coverage.
//!
//! Every XBasic source file in the migration corpus must lower to IR, and must
//! not be "swallowed". Swallowing = the TYPE-depth bug where a whole file body
//! was consumed to EOF yet still counted as a pass because a 2-line header
//! (`program_name` + `version`) was emitted. The honest success metric is a
//! successful parse+lower (equivalent to `rc == 0` from `xb --emit-ir`), NOT
//! non-empty output and NOT a fixed minimum IR-line count (which would
//! false-fail legitimately tiny files). The swallow guard therefore only fires
//! on *large* sources (>20 lines) that collapse to <=2 IR lines.
//!
//! Corpus = `xbasic/**/*.x` + `XBSourceLib/**/*.x` + XBSourceLib's
//! per-function source `.txt` fragments (docs/README + WorkLog + *Notes are docs,
//! excluded by the source-header heuristic).

use std::fs;
use std::path::{Path, PathBuf};
use xb_compiler::{FrontendUnit, TextIrEmitter};

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn rel(p: &Path) -> String {
    p.strip_prefix(root()).unwrap_or(p).display().to_string()
}

/// Recursively collect files with the given extension under `dir`.
fn collect_ext(dir: &Path, ext: &str, out: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            collect_ext(&path, ext, out);
        } else if path.extension().and_then(|e| e.to_str()) == Some(ext) {
            out.push(path);
        }
    }
}

/// A `.txt` in XBSourceLib is XBasic source (not a WorkLog/Notes doc) iff its
/// first non-comment, non-blank line opens a declaration/program/function.
fn is_source_txt(content: &str) -> bool {
    for line in content.lines() {
        let t = line.trim_start();
        if t.is_empty() || t.starts_with('\'') {
            continue;
        }
        let upper = t.to_ascii_uppercase();
        return [
            "DECLARE",
            "FUNCTION",
            "PROGRAM",
            "EXTERNAL",
            "INTERNAL",
            "CFUNCTION",
        ]
        .iter()
        .any(|kw| upper.starts_with(kw));
    }
    false
}

/// Parse + lower one file; push a human-readable reason on failure/swallow.
fn check_lowers(path: &Path, failures: &mut Vec<String>) {
    let src = match fs::read_to_string(path) {
        Ok(s) => s,
        Err(e) => {
            failures.push(format!("{}: READ {e}", rel(path)));
            return;
        }
    };
    let unit = match FrontendUnit::parse(&src) {
        Ok(u) => u,
        Err(e) => {
            failures.push(format!("{}: PARSE {e:?}", rel(path)));
            return;
        }
    };
    let program = match unit.lower_ir() {
        Ok(p) => p,
        Err(e) => {
            failures.push(format!("{}: LOWER {e:?}", rel(path)));
            return;
        }
    };
    let src_lines = src.lines().count();
    let ir_lines = TextIrEmitter::new().emit_program(&program).lines().count();
    if src_lines > 20 && ir_lines <= 2 {
        failures.push(format!(
            "{}: SWALLOWED ({src_lines} src lines -> {ir_lines} IR lines)",
            rel(path)
        ));
    }
}

#[test]
fn legacy_corpus_lowers_to_ir_without_swallow() {
    let root = root();

    let mut legacy_x = Vec::new();
    collect_ext(&root.join("xbasic"), "x", &mut legacy_x);
    let mut lib_x = Vec::new();
    collect_ext(&root.join("XBSourceLib"), "x", &mut lib_x);
    let mut lib_txt_all = Vec::new();
    collect_ext(&root.join("XBSourceLib"), "txt", &mut lib_txt_all);
    let lib_src_txt: Vec<PathBuf> = lib_txt_all
        .into_iter()
        .filter(|p| {
            fs::read_to_string(p)
                .map(|c| is_source_txt(&c))
                .unwrap_or(false)
        })
        .collect();

    // Pin current coverage: additions are fine (must still lower); removals fail.
    // The tracked xbasic port is always present; XBSourceLib has no
    // explicit license and remains gitignored local-only reference material,
    // so its counts are only enforced when the tree is present.
    assert!(
        legacy_x.len() >= 151,
        "xbasic .x count regressed: {} (<151)",
        legacy_x.len()
    );
    let has_xbsourcelib = root.join("XBSourceLib").exists();
    if has_xbsourcelib {
        assert!(
            lib_x.len() >= 13,
            "XBSourceLib .x count regressed: {} (<13)",
            lib_x.len()
        );
        assert!(
            lib_src_txt.len() >= 40,
            "XBSourceLib source .txt count regressed: {} (<40)",
            lib_src_txt.len()
        );
    }

    let mut all = Vec::new();
    all.extend(legacy_x.iter().cloned());
    all.extend(lib_x.iter().cloned());
    all.extend(lib_src_txt.iter().cloned());
    all.sort();

    let total = all.len();
    let mut failures = Vec::new();
    for path in &all {
        check_lowers(path, &mut failures);
    }

    assert!(
        failures.is_empty(),
        "{}/{} legacy corpus files failed to lower cleanly:\n{}",
        failures.len(),
        total,
        failures.join("\n")
    );
    let floor = if has_xbsourcelib { 204 } else { 151 };
    assert!(
        total >= floor,
        "combined migration corpus shrank: {total} (<{floor})"
    );
}
