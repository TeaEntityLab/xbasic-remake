use std::fs;
use std::path::Path;
use thiserror::Error;
use xb_compiler::{CompileError, FrontendUnit};

#[derive(Debug, Error)]
pub enum CliError {
    #[error("usage: xb <source.x>")]
    Usage,
    #[error("failed to read {path}: {source}")]
    Read {
        path: String,
        source: std::io::Error,
    },
    #[error(transparent)]
    Compile(#[from] CompileError),
}

pub fn run(args: &[String]) -> Result<String, CliError> {
    let [path] = args else {
        return Err(CliError::Usage);
    };
    summary_for_path(Path::new(path))
}

pub fn summary_for_path(path: &Path) -> Result<String, CliError> {
    let source = fs::read_to_string(path).map_err(|source| CliError::Read {
        path: path.display().to_string(),
        source,
    })?;
    summary_for_source(&source)
}

pub fn summary_for_source(source: &str) -> Result<String, CliError> {
    let unit = FrontendUnit::parse(source)?;
    Ok(unit.lower_ir()?.summary())
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
}
