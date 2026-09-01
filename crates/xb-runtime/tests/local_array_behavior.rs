//! Local dyn-array behavior gate (RR-02 light).
//!
//! Verifies that *non-param* dynamic arrays work end-to-end through the
//! Rust CEmitter vs the interpreter, without touching the byref-descriptor
//! ABI that blocks XstBackArrayToBinArray-style param tests.
//!
//! This is the convergence point per advisory: a deterministic UBOUND/REDIM
//! test that does NOT require IMPORT resolution or composite array forwarding.
//! It locks the working local-array path while the descriptor ABI remains
//! deferred as COMPOSITE-ARR-BYREF/CGEN-FACET-MANIFEST.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use xb_compiler::{CEmitter, FrontendUnit};
use xb_runtime::Interpreter;

mod common;

fn compile_and_run(c: &[u8], tmp: &Path, name: &str) -> String {
    let c_path = tmp.join(format!("{name}.c"));
    let exe = tmp.join(name);
    fs::write(&c_path, c).unwrap();
    let cc = Command::new(common::cc::cc())
        .args(["-o", exe.to_str().unwrap(), c_path.to_str().unwrap()])
        .output()
        .expect("cc");
    assert!(
        cc.status.success(),
        "cc {name} failed: {}",
        String::from_utf8_lossy(&cc.stderr)
    );
    let out = Command::new(common::exe_path(&exe))
        .output()
        .expect("run exe");
    assert!(
        out.status.success(),
        "exe {name} failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    out.stdout.iter().map(|&b| b as char).collect()
}

#[test]
fn local_dyn_string_array_ubound_and_redim() {
    let tmp = PathBuf::from(std::env::temp_dir().join("xb_local_array_behavior"));
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    // Fixed-size baseline + dynamic REDIM/UBOUND — both local, no param ABI.
    let src = r#"PROGRAM "t"
VERSION "0.1"
FUNCTION Main()
  DIM a$[]
  REDIM a$[2]
  a$[0] = "hello"
  a$[1] = "world"
  a$[2] = "!"
  PRINT UBOUND(a$[])
  PRINT a$[0]
  PRINT a$[1]
  PRINT a$[2]
END FUNCTION
"#;

    let prog = FrontendUnit::parse(src)
        .expect("parse")
        .lower_ir()
        .expect("lower");

    // Interpreter reference.
    let mut interp_out = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp_out)
        .expect("interp");
    let interp_str: String = interp_out.into_iter().map(|l| format!("{l}\n")).collect();
    assert_eq!(interp_str, "2\nhello\nworld\n!\n", "interp reference");

    // Rust CEmitter path.
    let c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_run(c.as_bytes(), &tmp, "local_dyn_rust");
    assert_eq!(rust_out, interp_str, "CEmitter mismatch");

    // Also verify fixed-size UBOUND via sizeof path.
    let src2 = r#"PROGRAM "t2"
VERSION "0.1"
FUNCTION Main()
  DIM b$[1]
  b$[0] = "foo"
  b$[1] = "bar"
  PRINT UBOUND(b$[])
  PRINT b$[0]
  PRINT b$[1]
END FUNCTION
"#;
    let prog2 = FrontendUnit::parse(src2)
        .expect("parse2")
        .lower_ir()
        .expect("lower2");
    let mut interp2 = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog2, Vec::new(), &mut interp2)
        .expect("interp2");
    let interp2_str: String = interp2.into_iter().map(|l| format!("{l}\n")).collect();
    assert_eq!(interp2_str, "1\nfoo\nbar\n");
    let c2 = CEmitter::new().emit_program(&prog2);
    let rust2_out = compile_and_run(c2.as_bytes(), &tmp, "local_fixed_rust");
    assert_eq!(rust2_out, interp2_str, "fixed-size UBOUND mismatch");

    let _ = fs::remove_dir_all(&tmp);
}

#[test]
fn local_dyn_integer_array_redim_preserves() {
    let tmp = PathBuf::from(std::env::temp_dir().join("xb_local_int_array"));
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    let src = r#"PROGRAM "ti"
VERSION "0.1"
FUNCTION Main()
  DIM a[]
  REDIM a[2]
  a[0] = 10
  a[1] = 20
  a[2] = 30
  PRINT UBOUND(a[])
  PRINT a[0]
  PRINT a[1]
  PRINT a[2]
  REDIM a[4]
  PRINT UBOUND(a[])
  PRINT a[2]
  PRINT a[4]
END FUNCTION
"#;
    let prog = FrontendUnit::parse(src)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let mut interp_out = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp_out)
        .expect("interp");
    let interp_str: String = interp_out.into_iter().map(|l| format!("{l}\n")).collect();
    // REDIM preserves prior elements, new slots zero-filled.
    assert_eq!(interp_str, "2\n10\n20\n30\n4\n30\n0\n");
    let c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_run(c.as_bytes(), &tmp, "local_int_rust");
    assert_eq!(rust_out, interp_str, "integer dyn REDIM mismatch");
    let _ = fs::remove_dir_all(&tmp);
}

#[test]
fn local_fixed_2d_array_row_major() {
    let tmp = PathBuf::from(std::env::temp_dir().join("xb_local_2d"));
    let _ = fs::remove_dir_all(&tmp);
    fs::create_dir_all(&tmp).unwrap();

    // Fixed 2D row-major: DIM g[3,2] => (3+1)*(2+1) = 12 elements, flat index = i*(2+1)+j
    let src = r#"PROGRAM "t2d"
VERSION "0.1"
FUNCTION Main()
  DIM g[3,2]
  g[1,1] = 7
  g[3,2] = 9
  PRINT g[1,1]
  PRINT g[3,2]
  PRINT UBOUND(g[])
END FUNCTION
"#;
    let prog = FrontendUnit::parse(src)
        .expect("parse")
        .lower_ir()
        .expect("lower");
    let mut interp_out = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&prog, Vec::new(), &mut interp_out)
        .expect("interp");
    let interp_str: String = interp_out.into_iter().map(|l| format!("{l}\n")).collect();
    // UBOUND for 2D dyn would be flat-1, but for fixed 2D with current CEmitter it is flat-1 as well via emit_mtotal
    // For DIM g[3,2], flat size = (3+1)*(2+1)=12, UBOUND = 11 (flat-1) per current lowering.
    // However fixed-size path via sizeof reports (3+1)*(2+1)-1 = 11.
    assert_eq!(interp_str, "7\n9\n11\n");
    let c = CEmitter::new().emit_program(&prog);
    let rust_out = compile_and_run(c.as_bytes(), &tmp, "local_2d_rust");
    assert_eq!(rust_out, interp_str, "fixed 2D mismatch");
    let _ = fs::remove_dir_all(&tmp);
}
