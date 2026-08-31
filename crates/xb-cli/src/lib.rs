use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use thiserror::Error;
use xb_compiler::{CEmitter, CompileError, FrontendUnit, TextIrEmitter};
use xb_runtime::Interpreter;

#[derive(Debug, Error)]
pub enum CliError {
    #[error("usage: xb [--emit-ir|--emit-ir-facets|--emit-c|--run|--compile] <source.x> [-o <output>] [--backend c|llvm]")]
    Usage,
    #[error("failed to read {path}: {source}")]
    Read {
        path: String,
        source: std::io::Error,
    },
    #[error(transparent)]
    Compile(#[from] CompileError),
    #[error("failed to write {path}: {source}")]
    Write {
        path: String,
        source: std::io::Error,
    },
    #[error("cc failed: {stderr}")]
    Link { stderr: String },
    #[error("runtime error: {0}")]
    Runtime(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum Mode {
    Summary,
    EmitIr,
    EmitIrFacets,
    EmitC,
    Run,
    Compile { output: PathBuf },
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Backend {
    C,
    Llvm,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Args {
    source: PathBuf,
    mode: Mode,
    input_path: Option<PathBuf>,
    backend: Backend,
}

fn parse_args(args: &[String]) -> Result<Args, CliError> {
    if args.is_empty() {
        return Err(CliError::Usage);
    }
    let mut source: Option<PathBuf> = None;
    let mut mode = Mode::Summary;
    let mut input_path: Option<PathBuf> = None;
    let mut backend = Backend::C;
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--emit-ir" => mode = Mode::EmitIr,
            "--emit-ir-facets" => mode = Mode::EmitIrFacets,
            "--emit-c" => mode = Mode::EmitC,
            "--run" => mode = Mode::Run,
            "--with-input" => {
                if i + 1 < args.len() {
                    input_path = Some(PathBuf::from(&args[i + 1]));
                    i += 1;
                }
            }
            "--compile" => {
                let output = if i + 2 < args.len() && args[i + 1] == "-o" {
                    i += 2;
                    PathBuf::from(&args[i])
                } else {
                    PathBuf::from("a.out")
                };
                mode = Mode::Compile { output };
            }
            "-o" => {
                if i + 1 < args.len() {
                    if let Mode::Compile { .. } = &mode {
                        mode = Mode::Compile {
                            output: PathBuf::from(&args[i + 1]),
                        };
                        i += 1;
                    }
                }
            }
            "--backend" => {
                if i + 1 < args.len() {
                    backend = match args[i + 1].as_str() {
                        "llvm" => Backend::Llvm,
                        _ => Backend::C,
                    };
                    i += 1;
                }
            }
            s if !s.starts_with('-') => source = Some(PathBuf::from(s)),
            _ => {}
        }
        i += 1;
    }
    let source = source.ok_or(CliError::Usage)?;
    Ok(Args {
        source,
        mode,
        input_path,
        backend,
    })
}

pub fn run(args: &[String]) -> Result<String, CliError> {
    let parsed = parse_args(args)?;
    match parsed.mode {
        Mode::Summary => summary_for_path(&parsed.source),
        Mode::EmitIr => emit_ir_for_path(&parsed.source),
        Mode::EmitIrFacets => emit_ir_facets_for_path(&parsed.source),
        Mode::Run => run_path(&parsed.source, parsed.input_path.as_deref()),
        Mode::EmitC => emit_c_for_path(&parsed.source),
        Mode::Compile { output } => compile_to_native(&parsed.source, &output, parsed.backend),
    }
}

pub fn summary_for_path(path: &Path) -> Result<String, CliError> {
    let source = read_source(path)?;
    summary_for_source(&source)
}

pub fn summary_for_source(source: &str) -> Result<String, CliError> {
    let unit = FrontendUnit::parse(source)?;
    Ok(unit.lower_ir()?.summary())
}

fn emit_ir_for_path(path: &Path) -> Result<String, CliError> {
    let source = read_source(path)?;
    let unit = FrontendUnit::parse(&source)?;
    let program = unit.lower_ir()?;
    Ok(TextIrEmitter::new().emit_program(&program))
}

fn emit_ir_facets_for_path(path: &Path) -> Result<String, CliError> {
    let source = read_source(path)?;
    let unit = FrontendUnit::parse(&source)?;
    let program = unit.lower_ir()?;
    Ok(TextIrEmitter::new().emit_program_with_facets(&program))
}

fn emit_c_for_path(path: &Path) -> Result<String, CliError> {
    let source = read_source(path)?;
    let unit = FrontendUnit::parse(&source)?;
    let constants = resolve_import_constants(path, &unit);
    let extra_decls = resolve_import_decls(path, &unit);
    let unit = if extra_decls.is_empty() {
        unit
    } else {
        unit.with_extra_statements(extra_decls)
    };
    let program = if constants.is_empty() {
        unit.lower_ir()?
    } else {
        unit.lower_ir_with_constants(constants)?
    };
    Ok(CEmitter::new().emit_program(&program))
}

/// Extract `$$` constant definitions from IMPORTed libraries.
/// XBasic `$$` constants are compile-time, not link-time. When a library
/// like xcm.x does `IMPORT "xma"`, the `$$PI`/`$$PIDIV2` constants defined
/// in xma.x must be available during C emission of xcm.x. This function
/// finds imported library files, parses them, and extracts their `$$`
/// constant definitions.
fn resolve_import_constants(
    source_path: &Path,
    unit: &FrontendUnit,
) -> std::collections::BTreeMap<String, String> {
    let mut constants = std::collections::BTreeMap::new();
    let source_dir = source_path.parent().unwrap_or(Path::new("."));
    use xb_compiler::Statement;
    for statement in unit.program().statements.iter() {
        if let Statement::Import(lib_name) = statement {
            // Search order: same-dir .x, same-dir .dec, ../shared/*.x,
            // ../../include/*.dec — matching the XBasic library layout.
            let candidates = [
                source_dir.join(format!("{lib_name}.x")),
                source_dir.join(format!("{lib_name}.dec")),
                source_dir
                    .join("..")
                    .join("shared")
                    .join(format!("{lib_name}.x")),
                source_dir
                    .join("..")
                    .join("..")
                    .join("include")
                    .join(format!("{lib_name}.dec")),
                source_dir
                    .join("..")
                    .join("include")
                    .join(format!("{lib_name}.dec")),
            ];
            for lib_path in &candidates {
                if let Ok(lib_source) = fs::read_to_string(lib_path) {
                    if lib_path.extension().is_some_and(|e| e == "dec") {
                        // .dec files contain C declarations our parser can't handle;
                        // extract $$ constants via text scan instead.
                        extract_constants_from_text(&lib_source, &mut constants);
                    } else if let Ok(lib_unit) = FrontendUnit::parse(&lib_source) {
                        extract_constants(&lib_unit, &mut constants);
                    }
                }
            }
        }
    }
    constants
}

/// Extract TYPE definitions and EXTERNAL FUNCTION/CFUNCTION declarations
/// from IMPORTed `.dec` files.  These are prepended to the main program's
/// statement list so the analyzer can register composite types and function
/// signatures from declaration files.
///
/// Only `.dec` files are processed here — `.x` files already have their
/// TYPE and FUNCTION declarations in the source that gets compiled directly.
/// Returns statements in order: TYPE declarations first, then FUNCTION decls.
fn resolve_import_decls(path: &Path, unit: &FrontendUnit) -> Vec<xb_compiler::Statement> {
    let mut decls = Vec::new();
    let mut seen_types: std::collections::HashSet<String> = std::collections::HashSet::new();
    let mut seen_funcs: std::collections::HashSet<String> = std::collections::HashSet::new();
    let source_dir = path.parent().unwrap_or(Path::new("."));
    use xb_compiler::Statement;
    for statement in unit.program().statements.iter() {
        if let Statement::Import(lib_name) = statement {
            let candidates = [
                source_dir.join(format!("{lib_name}.dec")),
                source_dir
                    .join("..")
                    .join("..")
                    .join("include")
                    .join(format!("{lib_name}.dec")),
                source_dir
                    .join("..")
                    .join("include")
                    .join(format!("{lib_name}.dec")),
            ];
            for lib_path in &candidates {
                if lib_path.extension().is_none_or(|e| e != "dec") {
                    continue;
                }
                let Ok(lib_source) = fs::read_to_string(lib_path) else {
                    continue;
                };
                let Ok(lib_unit) = FrontendUnit::parse(&lib_source) else {
                    // Fall back to text-scan constants only (already handled
                    // by resolve_import_constants).
                    continue;
                };
                for stmt in lib_unit.program().statements.iter() {
                    match stmt {
                        Statement::TypeDecl { name, .. } => {
                            if seen_types.insert(name.to_ascii_uppercase()) {
                                decls.push(stmt.clone());
                            }
                        }
                        // Composite-typed signatures (DCOMPLEX return/params)
                        // are only injected as knowledge the CEmitter can use
                        // once the composite call ABI covers import-only
                        // functions (RR-08/18-byref-array-abi). Injecting them
                        // today makes call sites emit struct-return handling
                        // for functions whose flattened variables don't exist.
                        Statement::Function(f)
                            if f.body.is_empty()
                                && f.return_type_name.is_none()
                                && f.params.iter().all(|p| p.type_name.is_none()) =>
                        {
                            let key = xb_compiler::full_name(f.name.clone(), f.suffix);
                            if seen_funcs.insert(key) {
                                decls.push(stmt.clone());
                            }
                        }
                        _ => {}
                    }
                }
            }
        }
    }
    decls
}

/// Extract `$$` constant definitions from raw text (for `.dec` files that
/// can't be fully parsed). Matches lines like `$$NAME = value` after stripping
/// trailing comments. Handles hex (0x), decimal, and negative values.
/// Resolves alias chains: `$$A = $$B` where `$$B = 0x80` → `$$A = 0x80`.
fn extract_constants_from_text(source: &str, out: &mut std::collections::BTreeMap<String, String>) {
    // First pass: collect raw name→value pairs.
    let mut raw: std::collections::BTreeMap<String, String> = std::collections::BTreeMap::new();
    for line in source.lines() {
        let trimmed = line.trim_start();
        if !trimmed.starts_with("$$") {
            continue;
        }
        // Strip trailing comment
        let line_no_comment = match trimmed.find('\'') {
            Some(pos) => &trimmed[..pos],
            None => trimmed,
        };
        if let Some(eq_pos) = line_no_comment.find('=') {
            let name = line_no_comment[..eq_pos]
                .trim()
                .trim_start_matches("$$")
                .to_string();
            let value = line_no_comment[eq_pos + 1..].trim();
            if !name.is_empty() && !value.is_empty() {
                raw.entry(name).or_insert(value.to_string());
            }
        }
    }
    // Second pass: resolve alias chains ($$A = $$B = ... = literal).
    for (name, value) in &raw {
        let resolved = resolve_alias(value, &raw);
        out.entry(name.clone()).or_insert(resolved);
    }
}

/// Resolve a `$$` constant alias chain to its literal value.
/// `$$B` → looks up `B` in `raw`, follows until a non-`$$` value is found.
fn resolve_alias(value: &str, raw: &std::collections::BTreeMap<String, String>) -> String {
    let mut current = value.to_string();
    let mut seen = std::collections::HashSet::new();
    while let Some(rest) = current.strip_prefix("$$") {
        let ref_name = rest.trim();
        if !seen.insert(ref_name.to_string()) {
            break; // cycle guard
        }
        match raw.get(ref_name) {
            Some(v) => current = v.clone(),
            None => break, // unresolved $$ reference — keep as-is
        }
    }
    current
}

/// Extract `$$` constant definitions from a parsed program.
fn extract_constants(unit: &FrontendUnit, out: &mut std::collections::BTreeMap<String, String>) {
    use xb_compiler::Statement;
    for statement in unit.program().statements.iter() {
        if let Statement::ConstantDefinition { name, value } = statement {
            // Only import constants not already defined (first-definition-wins,
            // matching XBasic's duplicate constant handling).
            out.entry(name.clone()).or_insert(value.clone());
        }
    }
}

/// A process-unique temp path under `xb_cli_compile/` for intermediate artifacts,
/// so concurrent compiles never collide on a shared file name.
fn unique_tmp(ext: &str) -> PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static SEQ: AtomicU64 = AtomicU64::new(0);
    let seq = SEQ.fetch_add(1, Ordering::Relaxed);
    std::env::temp_dir()
        .join("xb_cli_compile")
        .join(format!("out_{}_{seq}.{ext}", std::process::id()))
}

fn compile_to_native(source: &Path, output: &Path, backend: Backend) -> Result<String, CliError> {
    match backend {
        Backend::C => compile_via_c(source, output),
        Backend::Llvm => compile_via_llvm(source, output),
    }
}

/// AOT via the reference C generator (`emit-c` → `cc`). The default backend.
fn compile_via_c(source: &Path, output: &Path) -> Result<String, CliError> {
    let c_source = emit_c_for_path(source)?;
    let tmp = std::env::temp_dir().join("xb_cli_compile");
    fs::create_dir_all(&tmp).map_err(|e| CliError::Write {
        path: tmp.display().to_string(),
        source: e,
    })?;
    let c_path = unique_tmp("c");
    fs::write(&c_path, &c_source).map_err(|e| CliError::Write {
        path: c_path.display().to_string(),
        source: e,
    })?;
    let cc = std::env::var("CC").unwrap_or_else(|_| "cc".to_string());
    let result = Command::new(&cc)
        .args([
            "-O0",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
            "-o",
            output.to_str().unwrap(),
            c_path.to_str().unwrap(),
        ])
        .output()
        .map_err(|e| CliError::Write {
            path: cc.clone(),
            source: e,
        })?;
    if !result.status.success() {
        return Err(CliError::Link {
            stderr: String::from_utf8_lossy(&result.stderr).to_string(),
        });
    }
    let _ = fs::remove_file(&c_path);
    Ok(format!(
        "Compiled {} → {}\n",
        source.display(),
        output.display()
    ))
}

/// AOT via the LLVM backend (native object → `cc` link). Requires the `llvm`
/// feature; otherwise reports `XB-B001` (LlvmDisabled).
#[cfg(feature = "llvm")]
fn compile_via_llvm(source: &Path, output: &Path) -> Result<String, CliError> {
    use xb_compiler::Codegen;
    let src = read_source(source)?;
    let unit = FrontendUnit::parse(&src)?;
    let obj = xb_compiler::llvm_backend::LlvmBackend.compile(&unit)?;
    let tmp = std::env::temp_dir().join("xb_cli_compile");
    fs::create_dir_all(&tmp).map_err(|e| CliError::Write {
        path: tmp.display().to_string(),
        source: e,
    })?;
    let obj_path = unique_tmp("o");
    fs::write(&obj_path, obj.as_bytes()).map_err(|e| CliError::Write {
        path: obj_path.display().to_string(),
        source: e,
    })?;
    let cc = std::env::var("CC").unwrap_or_else(|_| "cc".to_string());
    let result = Command::new(&cc)
        .args(["-o", output.to_str().unwrap(), obj_path.to_str().unwrap()])
        .output()
        .map_err(|e| CliError::Write {
            path: cc.clone(),
            source: e,
        })?;
    if !result.status.success() {
        return Err(CliError::Link {
            stderr: String::from_utf8_lossy(&result.stderr).to_string(),
        });
    }
    let _ = fs::remove_file(&obj_path);
    Ok(format!(
        "Compiled {} → {} (LLVM)\n",
        source.display(),
        output.display()
    ))
}

#[cfg(not(feature = "llvm"))]
fn compile_via_llvm(_source: &Path, _output: &Path) -> Result<String, CliError> {
    Err(CliError::Compile(CompileError::LlvmDisabled))
}

fn run_path(path: &Path, input_path: Option<&Path>) -> Result<String, CliError> {
    let source = read_source(path)?;
    let unit = FrontendUnit::parse(&source)?;
    let program = unit.lower_ir()?;
    let mut lines = Vec::new();
    let input: Vec<Vec<u8>> = match input_path {
        Some(inp) => std::fs::read(inp)
            .map_err(|e| CliError::Read {
                path: inp.display().to_string(),
                source: e,
            })?
            .split(|b| *b == b'\n')
            .map(|c| c.to_vec())
            .collect(),
        None => read_stdin_lines(),
    };
    match Interpreter::new().execute_main_with_input(&program, input, &mut lines) {
        Ok(_) | Err(xb_runtime::RuntimeError::Quit { .. }) => {}
        Err(e) => return Err(CliError::Runtime(e.to_string())),
    }
    Ok(lines.into_iter().map(|l| format!("{l}\n")).collect())
}

/// Read piped stdin as `--run` input lines when no `--with-input` file is given.
/// A terminal stdin is skipped (returns empty) so no-input/interactive runs never
/// block; non-UTF-8 stdin is treated as empty (see RT-BYTESTRING in docs/17).
fn read_stdin_lines() -> Vec<Vec<u8>> {
    use std::io::{IsTerminal, Read};
    let stdin = std::io::stdin();
    if stdin.is_terminal() {
        return Vec::new();
    }
    // RT-IO-BYTES: raw bytes, split on LF — the interp string model holds
    // bytes, so stdin is byte-faithful end-to-end (matches the C backend).
    let mut bytes = Vec::new();
    if stdin.lock().read_to_end(&mut bytes).is_err() {
        return Vec::new();
    }
    let mut lines = Vec::new();
    for chunk in bytes.split(|b| *b == b'\n') {
        let mut line = chunk.to_vec();
        if line.last() == Some(&b'\r') {
            line.pop();
        }
        lines.push(line);
    }
    // A trailing newline yields one empty trailing chunk — `str::lines`
    // semantics drop it.
    if lines.last().is_some_and(|l| l.is_empty()) {
        lines.pop();
    }
    lines
}

fn read_source(path: &Path) -> Result<String, CliError> {
    fs::read_to_string(path).map_err(|source| CliError::Read {
        path: path.display().to_string(),
        source,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarizes_bootstrap_subset_source() {
        let summary =
            summary_for_source("VERSION \"6.5.0\"\nDIM name$\nname$ = \"hello\"\nPRINT name$\n")
                .unwrap();
        assert_eq!(
            summary,
            "version 6.5.0\ndim name:string\nassign name:string = string(\"hello\")\nprint symbol(name:string)\n"
        );
    }

    #[test]
    fn rejects_missing_argument() {
        let args = Vec::new();
        let result = run(&args);
        assert!(matches!(result, Err(CliError::Usage)));
    }

    #[test]
    fn parse_args_rejects_empty() {
        assert!(parse_args(&[]).is_err());
    }

    #[test]
    fn parse_args_summary_mode() {
        let args = vec!["foo.x".to_string()];
        let parsed = parse_args(&args).unwrap();
        assert_eq!(parsed.source, PathBuf::from("foo.x"));
        assert_eq!(parsed.mode, Mode::Summary);
    }

    #[test]
    fn parse_args_emit_c_mode() {
        let args = vec!["--emit-c".to_string(), "foo.x".to_string()];
        let parsed = parse_args(&args).unwrap();
        assert_eq!(parsed.mode, Mode::EmitC);
    }

    #[test]
    fn parse_args_compile_mode_with_output() {
        let args = vec![
            "--compile".to_string(),
            "foo.x".to_string(),
            "-o".to_string(),
            "myexe".to_string(),
        ];
        let parsed = parse_args(&args).unwrap();
        assert_eq!(
            parsed.mode,
            Mode::Compile {
                output: PathBuf::from("myexe")
            }
        );
    }

    #[test]
    fn parse_args_compile_mode_default_output() {
        let args = vec!["--compile".to_string(), "foo.x".to_string()];
        let parsed = parse_args(&args).unwrap();
        assert_eq!(
            parsed.mode,
            Mode::Compile {
                output: PathBuf::from("a.out")
            }
        );
    }
}
