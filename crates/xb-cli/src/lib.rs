use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use thiserror::Error;
use xb_compiler::{CEmitter, CompileError, FrontendUnit, TextIrEmitter};
use xb_runtime::Interpreter;

#[derive(Debug, Error)]
pub enum CliError {
    #[error("usage: xb [--emit-ir|--emit-c|--compile] <source.x> [-o <output>]")]
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
    EmitC,
    Run,
    Compile { output: PathBuf },
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Args {
    source: PathBuf,
    mode: Mode,
    input_path: Option<PathBuf>,
}

fn parse_args(args: &[String]) -> Result<Args, CliError> {
    if args.is_empty() {
        return Err(CliError::Usage);
    }
    let mut source: Option<PathBuf> = None;
    let mut mode = Mode::Summary;
    let mut input_path: Option<PathBuf> = None;
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--emit-ir" => mode = Mode::EmitIr,
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
    })
}

pub fn run(args: &[String]) -> Result<String, CliError> {
    let parsed = parse_args(args)?;
    match parsed.mode {
        Mode::Summary => summary_for_path(&parsed.source),
        Mode::EmitIr => emit_ir_for_path(&parsed.source),
        Mode::Run => run_path(&parsed.source, parsed.input_path.as_deref()),
        Mode::EmitC => emit_c_for_path(&parsed.source),
        Mode::Compile { output } => compile_to_native(&parsed.source, &output),
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

fn emit_c_for_path(path: &Path) -> Result<String, CliError> {
    let source = read_source(path)?;
    let unit = FrontendUnit::parse(&source)?;
    let program = unit.lower_ir()?;
    Ok(CEmitter::new().emit_program(&program))
}

fn compile_to_native(source: &Path, output: &Path) -> Result<String, CliError> {
    let c_source = emit_c_for_path(source)?;
    let tmp = std::env::temp_dir().join("xb_cli_compile");
    fs::create_dir_all(&tmp).map_err(|e| CliError::Write {
        path: tmp.display().to_string(),
        source: e,
    })?;
    let c_path = tmp.join("output.c");
    fs::write(&c_path, &c_source).map_err(|e| CliError::Write {
        path: c_path.display().to_string(),
        source: e,
    })?;
    let cc = std::env::var("CC").unwrap_or_else(|_| "cc".to_string());
    let result = Command::new(&cc)
        .args([
            "-O0",
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

fn run_path(path: &Path, input_path: Option<&Path>) -> Result<String, CliError> {
    let source = read_source(path)?;
    let unit = FrontendUnit::parse(&source)?;
    let program = unit.lower_ir()?;
    let mut lines = Vec::new();
    if let Some(inp) = input_path {
        let input: Vec<String> = read_source(inp)?.lines().map(|l| l.to_string()).collect();
        match Interpreter::new().execute_main_with_input(&program, input, &mut lines) {
            Ok(_) | Err(xb_runtime::RuntimeError::Quit { .. }) => {}
            Err(e) => return Err(CliError::Runtime(e.to_string())),
        }
    } else {
        match Interpreter::new().execute_main(&program, &mut lines) {
            Ok(_) | Err(xb_runtime::RuntimeError::Quit { .. }) => {}
            Err(e) => return Err(CliError::Runtime(e.to_string())),
        }
    }
    Ok(lines.into_iter().map(|l| format!("{l}\n")).collect())
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
