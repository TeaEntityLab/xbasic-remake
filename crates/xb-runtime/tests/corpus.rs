mod common;
use common::{assert_golden, check_selfhost, compile_and_run};
use std::collections::{BTreeMap, BTreeSet};
use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};
use xb_compiler::{FrontendUnit, SOURCE_DIAGNOSTIC_CODES};

fn path_error(message: &str, path: &Path) -> String {
    format!("{message}: {}", path.display())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum RootEntryKind {
    File,
    Directory,
}

fn validate_root_entries(root: &Path, entries: &[(PathBuf, RootEntryKind)]) -> Result<(), String> {
    let expected = ["negative", "positive", "selfhost"].map(|name| root.join(name));
    let actual: BTreeMap<_, _> = entries.iter().cloned().collect();
    if let Some(path) = actual.keys().find(|path| !expected.contains(*path)) {
        return Err(path_error("unexpected corpus root entry", path));
    }
    for path in expected {
        match actual.get(&path) {
            None => return Err(path_error("missing corpus root directory", &path)),
            Some(RootEntryKind::File) => return Err(path_error("not a directory", &path)),
            Some(RootEntryKind::Directory) => {}
        }
    }
    Ok(())
}

fn validate_corpus_root(root: &Path) -> Result<(), String> {
    let entries = fs::read_dir(root)
        .map_err(|error| format!("cannot read corpus root {}: {error}", root.display()))?;
    let mut typed = Vec::new();
    for entry in entries {
        let entry = entry.map_err(|error| format!("cannot read {}: {error}", root.display()))?;
        let path = entry.path();
        let kind = match entry
            .file_type()
            .map_err(|error| format!("cannot inspect {}: {error}", path.display()))?
            .is_dir()
        {
            true => RootEntryKind::Directory,
            false => RootEntryKind::File,
        };
        typed.push((path, kind));
    }
    validate_root_entries(root, &typed)
}

fn discover(directory: &Path) -> Result<Vec<PathBuf>, String> {
    let entries = fs::read_dir(directory)
        .map_err(|error| format!("cannot read {}: {error}", directory.display()))?;
    let mut paths = Vec::new();
    for entry in entries {
        let entry =
            entry.map_err(|error| format!("cannot read {}: {error}", directory.display()))?;
        let path = entry.path();
        let file_type = entry
            .file_type()
            .map_err(|error| format!("cannot inspect {}: {error}", path.display()))?;
        if !file_type.is_file() {
            return Err(path_error("malformed corpus path", &path));
        }
        paths.push(path);
    }
    paths.sort();
    Ok(paths)
}

fn validate_layout(
    directory: &Path,
    paths: &[PathBuf],
    required: &[&str],
    optional: &[&str],
) -> Result<Vec<PathBuf>, String> {
    if paths.is_empty() {
        return Err(path_error("empty corpus layout", directory));
    }
    let mut cases: BTreeMap<PathBuf, BTreeSet<String>> = BTreeMap::new();
    for path in paths {
        let stem = path.file_stem().and_then(OsStr::to_str);
        let extension = path.extension().and_then(OsStr::to_str);
        let (Some(stem), Some(extension)) = (stem, extension) else {
            return Err(path_error("malformed corpus path", path));
        };
        if stem.is_empty() || (!required.contains(&extension) && !optional.contains(&extension)) {
            return Err(path_error("unexpected extension or malformed path", path));
        }
        let stem_path = path.with_file_name(stem);
        if !cases
            .entry(stem_path)
            .or_default()
            .insert(extension.to_owned())
        {
            return Err(path_error("duplicate corpus file", path));
        }
    }
    for (stem, extensions) in &cases {
        if required.contains(&"x") && !extensions.contains("x") {
            return Err(path_error("source-less orphan golden", stem));
        }
        for extension in required {
            let path = stem.with_extension(extension);
            if !extensions.contains(*extension) {
                return Err(path_error("missing corpus file", &path));
            }
        }
    }
    Ok(cases.into_keys().collect())
}

#[test]
fn corpus_v0_1_is_valid_and_executable() -> Result<(), String> {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let corpus = root.join("fixtures/corpus/v0.1");
    validate_corpus_root(&corpus)?;
    let positive = corpus.join("positive");
    let positive_cases = validate_layout(
        &positive,
        &discover(&positive)?,
        &["x", "ir", "out"],
        &["in"],
    )?;
    for stem in positive_cases {
        let (ir, output, state) = compile_and_run(&stem.with_extension("x"))?;
        assert_golden(&stem.with_extension("ir"), ir.as_bytes())?;
        assert_golden(&stem.with_extension("out"), output.as_bytes())?;
        if stem.file_name() == Some(OsStr::new("execution_order")) {
            assert_eq!(state.metadata().version(), Some("0.1"));
            for name in ["topMessage", "mainMessage"] {
                assert!(
                    state.slot(name).is_some(),
                    "missing {name}: {}",
                    stem.display()
                );
            }
        }
    }

    let negative = corpus.join("negative");
    let negative_cases = validate_layout(&negative, &discover(&negative)?, &["x", "diag"], &[])?;
    let mut covered = BTreeSet::new();
    for stem in negative_cases {
        let source_path = stem.with_extension("x");
        let source = fs::read_to_string(&source_path)
            .map_err(|error| format!("cannot read {}: {error}", source_path.display()))?;
        let error = match FrontendUnit::parse(&source) {
            Err(error) => error,
            Ok(unit) => match unit.lower_ir() {
                Err(error) => error,
                Ok(_) => return Err(path_error("negative fixture compiled", &source_path)),
            },
        };
        let code = error.diagnostic_code();
        if !SOURCE_DIAGNOSTIC_CODES.contains(&code) {
            return Err(path_error(
                &format!("non-source diagnostic {code}"),
                &source_path,
            ));
        }
        let diag_path = stem.with_extension("diag");
        let diag = fs::read_to_string(&diag_path)
            .map_err(|error| format!("cannot read {}: {error}", diag_path.display()))?;
        let Some(expected) = diag.strip_suffix('\n') else {
            return Err(path_error("diagnostic must end in LF", &diag_path));
        };
        if expected.contains(['\n', '\r']) || expected != code {
            return Err(path_error("diagnostic mismatch", &diag_path));
        }
        covered.insert(code);
    }
    for code in SOURCE_DIAGNOSTIC_CODES {
        if !covered.contains(code) {
            return Err(path_error(
                &format!("diagnostic {code} has no fixture"),
                &negative,
            ));
        }
    }

    let selfhost = corpus.join("selfhost");
    let selfhost_cases =
        validate_layout(&selfhost, &discover(&selfhost)?, &["ir", "out"], &["in"])?;
    let expected_stems = [
        selfhost.join("lexer"),
        selfhost.join("xut_bootstrap_manifest"),
    ];
    if selfhost_cases != expected_stems {
        return Err(path_error("unexpected selfhost cases", &selfhost));
    }
    check_selfhost(&root, &expected_stems, "lexer", 0)?;
    check_selfhost(&root, &expected_stems, "xut_bootstrap_manifest", 1)?;
    Ok(())
}

fn bad(paths: &[&str], required: &[&str], message: &str) {
    let directory = Path::new("/synthetic");
    let paths: Vec<_> = paths.iter().map(|path| directory.join(path)).collect();
    let error = match validate_layout(directory, &paths, required, &[]) {
        Ok(cases) => panic!("layout unexpectedly accepted: {cases:?}"),
        Err(error) => error,
    };
    assert!(error.contains(message), "{error}");
    assert!(error.contains("/synthetic"), "failure lacks path: {error}");
}

fn root_bad(entries: &[(&str, RootEntryKind)], expected_path: &str) {
    let root = Path::new("/synthetic");
    let entries: Vec<_> = entries
        .iter()
        .map(|(name, kind)| (root.join(name), *kind))
        .collect();
    let error = match validate_root_entries(root, &entries) {
        Ok(()) => panic!("root layout unexpectedly accepted"),
        Err(error) => error,
    };
    assert!(error.contains(expected_path), "{error}");
}

macro_rules! rejection_tests {
    ($($name:ident => $assertion:expr;)*) => {
        $(
            #[test]
            fn $name() { $assertion }
        )*
    };
}

const P: &[&str] = &["x", "ir", "out"];
const D: RootEntryKind = RootEntryKind::Directory;
const F: RootEntryKind = RootEntryKind::File;

rejection_tests! {
    rejects_positive_missing_ir => bad(&["case.x", "case.out"], P, "case.ir");
    rejects_positive_missing_out => bad(&["case.x", "case.ir"], P, "case.out");
    rejects_negative_missing_diag => bad(&["case.x"], &["x", "diag"], "case.diag");
    rejects_source_less_orphan_golden => bad(&["orphan.ir", "orphan.out"], P, "source-less");
    rejects_unexpected_extension => bad(&["case.x", "case.ir", "case.out", "case.txt"], P, "case.txt");
    rejects_empty_layout => bad(&[], P, "empty");
    rejects_malformed_path => bad(&["case"], P, "malformed");
    rejects_unexpected_root_entry => root_bad(&[("positive", D), ("negative", D), ("selfhost", D), ("notes.txt", F)], "notes.txt");
    rejects_required_root_entry_that_is_not_a_directory => root_bad(&[("positive", F), ("negative", D), ("selfhost", D)], "positive");
    rejects_missing_required_root_directory => root_bad(&[("positive", D), ("negative", D)], "selfhost");
}
