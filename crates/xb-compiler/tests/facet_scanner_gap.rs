//! CGEN-FACET-RETIREMENT gap ratchet (docs/19 §5/§7, docs/20 M1 work package 2).
//!
//! `selfhost/cgen.x` still derives three storage facts by *program-wide* text
//! scans of the IR — `scan_all_strarr$`, `scan_str_dual$`, `scan_xst_arrays$` —
//! instead of consuming the frontend's `facet` header. A previous retirement
//! attempt (docs/19 slice 4 → 4.1) regressed `arecurse`/`Kittedy` because the
//! facet-derived sets differed from the scanners in ways nobody had measured.
//!
//! This test ports the three scanners as exact oracles over the emitted text IR
//! and diffs them against the sets derivable from the `facet` header, across the
//! whole tracked corpus (demos, 15 core libs, selfhost tools, positive corpus).
//! It is a ratchet: the recorded gap totals may only go down. A classifier whose
//! gap is 0 in both directions on every program can have its scanner and
//! fallback deleted from `cgen.x` with zero emission change.
//!
//! Run with `--nocapture` for the per-program gap listing.

use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::{Path, PathBuf};
use xb_compiler::{FrontendUnit, TextIrEmitter};

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn collect_x(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let p = entry.path();
        if p.is_dir() {
            collect_x(&p, out);
        } else if p.extension().and_then(|e| e.to_str()) == Some("x") {
            out.push(p);
        }
    }
}

/// `trim_spaces$`: strips ASCII 32 only (not tabs), like cgen.x.
fn trim_spaces(s: &str) -> &str {
    s.trim_matches(' ')
}

/// `scan_all_strarr$`: every `dim <name>:string[...]` line, program-wide.
/// Returns the raw set; a `dim shared X:string[..]` line yields the dead
/// entry `shared X` exactly as cgen.x does (it never matches a `:name:` probe).
fn scan_all_strarr(ir: &str) -> BTreeSet<String> {
    let mut res = BTreeSet::new();
    for raw in ir.split('\n') {
        let ln = trim_spaces(raw);
        let r = if let Some(r) = ln.strip_prefix("dim ") {
            r
        } else if let Some(r) = ln.strip_prefix("redim ") {
            r
        } else {
            continue;
        };
        let Some(bp) = r.find('[') else {
            continue;
        };
        let nm = &r[..bp];
        let Some(e) = nm.find(':') else {
            continue;
        };
        if &nm[e + 1..] == "string" {
            res.insert(nm[..e].to_string());
        }
    }
    res
}

/// `scan_str_dual$`: names with BOTH a scalar `dim X:string` and an array
/// `dim X:string[...]` anywhere in the program (DIM-based, cross-function).
fn scan_str_dual(ir: &str) -> BTreeSet<String> {
    let mut scal: BTreeSet<String> = BTreeSet::new();
    let mut arr: BTreeSet<String> = BTreeSet::new();
    let mut res = BTreeSet::new();
    for raw in ir.split('\n') {
        let ln = trim_spaces(raw);
        let r = if let Some(r) = ln.strip_prefix("dim ") {
            r
        } else if let Some(r) = ln.strip_prefix("redim ") {
            r
        } else {
            continue;
        };
        if let Some(bp) = r.find('[') {
            let nm = &r[..bp];
            let Some(e) = nm.find(':') else {
                continue;
            };
            if &nm[e + 1..] == "string" {
                let name = &nm[..e];
                if scal.contains(name) {
                    res.insert(name.to_string());
                }
                arr.insert(name.to_string());
            }
        } else {
            let Some(e) = r.find(':') else {
                continue;
            };
            if &r[e + 1..] == "string" {
                let name = &r[..e];
                if arr.contains(name) {
                    res.insert(name.to_string());
                }
                scal.insert(name.to_string());
            }
        }
    }
    res
}

/// `extract_byref_sym$`: `byref(symbol(X:type))` → `X:type`.
fn extract_byref_sym(arg: &str) -> Option<(String, String)> {
    if !arg.starts_with("byref(s") {
        return None;
    }
    let sp = arg.find("symbol(")?;
    let mut inner = &arg[sp + 7..];
    inner = inner.strip_suffix(')').unwrap_or(inner);
    inner = inner.strip_suffix(')').unwrap_or(inner);
    let c = inner.find(':')?;
    Some((inner[..c].to_string(), inner[c + 1..].to_string()))
}

/// `scan_xst_arrays$`: by-ref array args at positions 0–1 of
/// `XstQuickSort`/`XstCopyArray` calls → name → type.
fn scan_xst_arrays(ir: &str) -> BTreeMap<String, String> {
    let mut res = BTreeMap::new();
    for raw in ir.split('\n') {
        let ln = trim_spaces(raw);
        if !(ln.starts_with("call XstQuickSort(") || ln.starts_with("call XstCopyArray(")) {
            continue;
        }
        let sp = ln.find('(').unwrap();
        let args = &ln[sp + 1..ln.len() - 1];
        let mut depth = 0i32;
        let mut start = 0usize;
        let mut arg_pos = 0usize;
        let note = |part: &str, pos: usize, res: &mut BTreeMap<String, String>| {
            if pos < 2 {
                if let Some((nm, tp)) = extract_byref_sym(trim_spaces(part)) {
                    res.entry(nm).or_insert(tp);
                }
            }
        };
        for (i, ch) in args.char_indices() {
            match ch {
                '(' => depth += 1,
                ')' => depth -= 1,
                ',' if depth == 0 => {
                    note(&args[start..i], arg_pos, &mut res);
                    start = i + 1;
                    arg_pos += 1;
                }
                _ => {}
            }
        }
        note(&args[start..], arg_pos, &mut res);
    }
    res
}

#[derive(Debug, Clone)]
struct Facet {
    name: String,
    ty: String,
    storage: String,
    rank: usize,
    dual: bool,
    byref: bool,
}

fn parse_facets(ir: &str) -> Vec<Facet> {
    let mut out = Vec::new();
    for raw in ir.split('\n') {
        let Some(rest) = raw.strip_prefix("facet ") else {
            continue;
        };
        let mut it = rest.split(' ');
        let head = it.next().unwrap_or("");
        let Some(c) = head.rfind(':') else {
            continue;
        };
        let mut f = Facet {
            name: head[..c].to_string(),
            ty: head[c + 1..].to_string(),
            storage: String::new(),
            rank: 0,
            dual: false,
            byref: false,
        };
        for kv in it {
            if let Some(v) = kv.strip_prefix("storage=") {
                f.storage = v.to_string();
            } else if let Some(v) = kv.strip_prefix("rank=") {
                f.rank = v.parse().unwrap_or(0);
            } else if let Some(v) = kv.strip_prefix("dual=") {
                f.dual = v == "1";
            } else if let Some(v) = kv.strip_prefix("byref=") {
                f.byref = v == "1";
            }
        }
        out.push(f);
    }
    out
}

#[derive(Default)]
struct Gap {
    scanner_only: usize,
    facet_only: usize,
    lines: Vec<String>,
}

impl Gap {
    fn diff(&mut self, prog: &str, scanner: &BTreeSet<String>, facet: &BTreeSet<String>) {
        let so: Vec<&String> = scanner.difference(facet).collect();
        let fo: Vec<&String> = facet.difference(scanner).collect();
        self.scanner_only += so.len();
        self.facet_only += fo.len();
        if !so.is_empty() || !fo.is_empty() {
            self.lines
                .push(format!("  {prog}: scanner-only={so:?} facet-only={fo:?}"));
        }
    }
}

#[test]
fn facet_header_covers_cgen_scanner_facts_ratchet() {
    let r = root();
    let mut files: Vec<PathBuf> = Vec::new();
    collect_x(&r.join("xbasic/demo"), &mut files);
    collect_x(&r.join("xbasic/lib"), &mut files);
    collect_x(&r.join("selfhost"), &mut files);
    collect_x(&r.join("fixtures/corpus/v0.1/positive"), &mut files);
    collect_x(&r.join("fixtures/corpus/v0.1/selfhost"), &mut files);
    files.sort();
    assert!(files.len() >= 200, "corpus too small: {}", files.len());

    let mut all_strarr = Gap::default();
    let mut str_dual = Gap::default();
    let mut xst_not_dyn = Gap::default();
    let mut programs = 0usize;

    for path in &files {
        let src = fs::read_to_string(path).unwrap();
        let Ok(unit) = FrontendUnit::parse(&src) else {
            continue;
        };
        let Ok(prog) = unit.lower_ir() else {
            continue;
        };
        programs += 1;
        let ir = TextIrEmitter::new().emit_program_with_facets(&prog);
        let name = path.strip_prefix(&r).unwrap_or(path).display().to_string();
        let facets = parse_facets(&ir);

        // (1) allStrArr: any non-shared, non-parameter string-array DIM.
        // The legacy scanner also sees a parameter's in-body DIM/REDIM, but
        // parameter storage is owned by the signature/descriptor path and is
        // not an effective allStrArr fact. Remove names that are param-only;
        // retain a name when another scope has real local array storage.
        let f_strarr: BTreeSet<String> = facets
            .iter()
            .filter(|f| {
                f.ty == "string"
                    && f.rank >= 1
                    && f.storage != "shared"
                    && f.storage != "param"
                    && !f.byref
            })
            .map(|f| f.name.clone())
            .collect();
        let f_param_strarr: BTreeSet<String> = facets
            .iter()
            .filter(|f| f.ty == "string" && f.rank >= 1 && f.storage == "param")
            .map(|f| f.name.clone())
            .collect();
        let s_strarr: BTreeSet<String> = scan_all_strarr(&ir)
            .into_iter()
            .filter(|n| !n.contains(' '))
            .filter(|n| !f_param_strarr.contains(n) || f_strarr.contains(n))
            .collect();
        all_strarr.diff(&name, &s_strarr, &f_strarr);

        // (2) strDual: scalar-DIM + array-DIM of one string name (DIM-based).
        // Closest facet fact today is use-based `dual=1` on a string array.
        let s_dual: BTreeSet<String> = scan_str_dual(&ir)
            .into_iter()
            .filter(|n| !n.contains(' '))
            .collect();
        let f_dual: BTreeSet<String> = facets
            .iter()
            .filter(|f| f.ty == "string" && f.rank >= 1 && f.dual)
            .map(|f| f.name.clone())
            .collect();
        str_dual.diff(&name, &s_dual, &f_dual);

        // (3) xstArrays: every consumer of ##xstArrays$ is guarded by
        // `NOT IN ##dynNames$`, and facets rebuild ##dynNames$ from storage=dyn.
        // The scanner is retirable iff every xst array is facet-dyn.
        let s_xst: BTreeSet<String> = scan_xst_arrays(&ir).into_keys().collect();
        let f_dyn: BTreeSet<String> = facets
            .iter()
            .filter(|f| f.storage == "dyn")
            .map(|f| f.name.clone())
            .collect();
        let missing: BTreeSet<String> = s_xst.difference(&f_dyn).cloned().collect();
        xst_not_dyn.diff(&name, &missing, &BTreeSet::new());
    }

    println!(
        "facet/scanner gap over {programs} programs ({} files):",
        files.len()
    );
    for (label, g) in [
        ("allStrArr (string array DIM, non-shared)", &all_strarr),
        ("strDual (scalar+array string DIM)", &str_dual),
        ("xstArrays not facet-dyn", &xst_not_dyn),
    ] {
        println!(
            "  {label}: scanner-only={} facet-only={}",
            g.scanner_only, g.facet_only
        );
        for l in &g.lines {
            println!("  {l}");
        }
    }

    // Ratchet (2026-09-02, 234 programs). `scanner-only` = facts a scanner
    // derives that the facet header lacks; that is the retirement blocker and
    // may only shrink. `facet-only` is a retirement metric only where the facet
    // fact is *defined* to equal the scanner fact (allStrArr).
    //
    // allStrArr: exact equivalence, both directions 0. This became true once
    //   the text IR kept `[]` on unsized non-shared array DIMs (`DIM x$[]`);
    //   before that the scanner could not see 21 such arrays.
    // strDual: a DIM-based fact (scalar DIM + array DIM of one string name)
    //   with no emitted counterpart; facet `dual=1` is use-based and a
    //   superset (scanner-only 0), so `facet-only` is reported, not ratcheted.
    // xstArrays not facet-dyn = 4: xcol `export$`/`import$`, xit `symbol$`,
    //   xui `helpText$` (shared / param arrays passed to XstQuickSort).
    const XST_NOT_DYN: usize = 4;
    assert!(programs >= 200, "only {programs} programs lowered");
    assert!(
        all_strarr.scanner_only == 0 && all_strarr.facet_only == 0,
        "allStrArr facet/scanner equivalence broken: scanner-only={} facet-only={}",
        all_strarr.scanner_only,
        all_strarr.facet_only
    );
    assert!(
        str_dual.scanner_only == 0,
        "strDual: facet dual=1 no longer covers every DIM-based string dual: scanner-only={}",
        str_dual.scanner_only
    );
    assert!(
        xst_not_dyn.scanner_only <= XST_NOT_DYN,
        "xstArrays-not-dyn regressed: {}",
        xst_not_dyn.scanner_only
    );
}
