#![allow(dead_code)]

pub mod cc;

/// On Windows, `cc -o name` produces `name.exe`. This helper returns the
/// path that `Command::new` should use to invoke the compiled binary.
pub fn exe_path(base: &Path) -> PathBuf {
    if cfg!(windows) {
        let mut p = base.to_path_buf();
        p.set_extension("exe");
        p
    } else {
        base.to_path_buf()
    }
}

use std::fs;
use std::path::{Path, PathBuf};
use xb_compiler::{
    FrontendUnit, IrExpr, IrExprKind, IrProgram, IrSymbol, TextIrEmitter, ValueType,
};
use xb_runtime::Interpreter;

pub fn lower(source: &str) -> IrProgram {
    FrontendUnit::parse(source).unwrap().lower_ir().unwrap()
}

pub fn symbol(name: &str, value_type: ValueType) -> IrSymbol {
    IrSymbol {
        name: name.to_string(),
        value_type,
    }
}
pub fn expression(kind: IrExprKind, value_type: ValueType) -> IrExpr {
    IrExpr { kind, value_type }
}

pub fn compile_and_run(
    source_path: &Path,
) -> Result<(String, String, xb_runtime::ExecutionState), String> {
    compile_and_run_mode(source_path, false)
}

pub fn compile_and_run_strict(
    source_path: &Path,
) -> Result<(String, String, xb_runtime::ExecutionState), String> {
    compile_and_run_mode(source_path, true)
}

fn compile_and_run_mode(
    source_path: &Path,
    strict: bool,
) -> Result<(String, String, xb_runtime::ExecutionState), String> {
    let source = fs::read_to_string(source_path)
        .map_err(|error| format!("cannot read {}: {error}", source_path.display()))?;
    let unit = FrontendUnit::parse(&source)
        .map_err(|error| format!("cannot parse {}: {error}", source_path.display()))?;
    let program = if strict {
        unit.lower_ir_strict()
    } else {
        unit.lower_ir()
    }
    .map_err(|error| format!("cannot lower {}: {error}", source_path.display()))?;
    let text_ir = TextIrEmitter::new().emit_program(&program);
    let mut lines = Vec::new();
    let input_path = source_path.with_extension("in");
    let state = if input_path.exists() {
        let input: Vec<Vec<u8>> = byte_lines(
            &fs::read(&input_path)
                .map_err(|error| format!("cannot read {}: {error}", input_path.display()))?,
        );
        Interpreter::new()
            .execute_main_with_input(&program, input, &mut lines)
            .map_err(|error| format!("cannot execute {}: {error}", source_path.display()))?
    } else {
        Interpreter::new()
            .execute_main(&program, &mut lines)
            .map_err(|error| format!("cannot execute {}: {error}", source_path.display()))?
    };
    let output = lines.into_iter().map(|line| format!("{line}\n")).collect();
    Ok((text_ir, output, state))
}

pub fn assert_golden(path: &Path, actual: &[u8]) -> Result<(), String> {
    let expected = fs::read(path)
        .map_err(|error| format!("cannot read golden {}: {error}", path.display()))?;
    if actual == expected {
        Ok(())
    } else {
        Err(format!("golden mismatch: {}", path.display()))
    }
}

pub fn check_selfhost(
    root: &Path,
    stems: &[PathBuf],
    name: &str,
    idx: usize,
) -> Result<(), String> {
    let (ir, _output, state) = compile_and_run(&root.join(format!("selfhost/{name}.x")))?;
    assert_golden(&stems[idx].with_extension("ir"), ir.as_bytes())?;
    if name == "xut_bootstrap_manifest" {
        assert_eq!(state.metadata().version(), Some("0.0001"));
    }
    Ok(())
}

/// Byte-faithful input lines with `str::lines()` semantics: split on LF,
/// strip a trailing CR per line, and drop the single trailing empty line
/// produced by a final newline (empty input -> no lines).
pub(crate) fn byte_lines(bytes: &[u8]) -> Vec<Vec<u8>> {
    let mut lines: Vec<Vec<u8>> = bytes.split(|b| *b == b'\n').map(|c| c.to_vec()).collect();
    for l in &mut lines {
        if l.last() == Some(&b'\r') {
            l.pop();
        }
    }
    if bytes.ends_with(b"\n") || bytes.is_empty() {
        lines.pop();
    }
    lines
}
