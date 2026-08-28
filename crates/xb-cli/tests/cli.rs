use std::path::Path;
use std::process::Command;

#[test]
fn cli_prints_stable_ir_summary_for_committed_fixture() {
    let fixture = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures/bootstrap/hello.x");
    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .arg(fixture)
        .output()
        .unwrap();

    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).unwrap(),
        "version 6.5.0\ndim name:string\nassign name:string = string(\"hello\")\nprint symbol(name:string)\n"
    );
}

#[test]
fn cli_prints_stable_ir_for_static_xut_bootstrap_manifest() {
    // Given
    let manifest =
        Path::new(env!("CARGO_MANIFEST_DIR")).join("../../selfhost/xut_bootstrap_manifest.x");

    // When
    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .arg(manifest)
        .output()
        .unwrap();

    // Then
    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).unwrap(),
        concat!(
            "version 0.0001\n",
            "const $$XBSysLinux:integer = integer(1)\n",
            "const $$XBSysWin32:integer = integer(2)\n",
            "function PlatformName() -> string\n",
            "  if constant($$XBSysLinux:integer = integer(1))\n",
            "    return string(\"linux\")\n",
            "  end if\n",
            "  return string(\"unknown\")\n",
            "end function\n",
            "function Main() -> integer\n",
            "  dim utilityName:string\n",
            "  dim utilityVersion:float\n",
            "  assign utilityName:string = string(\"xut\")\n",
            "  assign utilityVersion:float = float(0.0001)\n",
            "  shared ##XBSystem:integer = constant($$XBSysLinux:integer = integer(1))\n",
            "  print symbol(utilityName:string)\n",
            "  print symbol(utilityVersion:float)\n",
            "  print constant($$XBSysLinux:integer = integer(1))\n",
            "  print constant($$XBSysWin32:integer = integer(2))\n",
            "  print shared(##XBSystem:integer)\n",
            "  if constant($$XBSysLinux:integer = integer(1))\n",
            "    print string(\"linux\")\n",
            "  end if\n",
            "  if compare(shared(##XBSystem:integer) = constant($$XBSysLinux:integer = integer(1)))\n",
            "    print string(\"match\")\n",
            "    print arith(constant($$XBSysLinux:integer = integer(1)) + constant($$XBSysWin32:integer = integer(2)))\n",
            "    print call PlatformName()\n",
            "    dim counter:integer\n",
            "    assign counter:integer = integer(3)\n",
            "    while compare(symbol(counter:integer) > integer(0))\n",
            "      print symbol(counter:integer)\n",
            "      assign counter:integer = arith(symbol(counter:integer) - integer(1))\n",
            "    wend\n",
            "  end if\n",
            "end function\n",
        )
    );
}

#[test]
fn cli_emit_c_produces_compilable_c_source() {
    let fixture = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures/bootstrap/hello.x");
    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .args(["--emit-c", fixture.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(
        output.status.success(),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let c_source = String::from_utf8(output.stdout).unwrap();
    assert!(c_source.contains("int main(int argc, char **argv)"));
    assert!(c_source.contains("xb_print_str"));
    assert!(c_source.contains("#include <stdio.h>"));
}

#[test]
fn cli_compile_produces_native_executable() {
    let fixture = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures/bootstrap/hello.x");
    let tmp = std::env::temp_dir().join("xb_cli_compile_test");
    let _ = std::fs::create_dir_all(&tmp);
    let exe = tmp.join("hello_exe");
    let _ = std::fs::remove_file(&exe);

    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .args([
            "--compile",
            fixture.to_str().unwrap(),
            "-o",
            exe.to_str().unwrap(),
        ])
        .output()
        .unwrap();
    assert!(
        output.status.success(),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        exe.exists(),
        "executable was not created at {}",
        exe.display()
    );

    // Run the native executable and verify output
    let run = Command::new(&exe).output().unwrap();
    assert!(run.status.success());
    assert_eq!(String::from_utf8(run.stdout).unwrap(), "hello\n");

    let _ = std::fs::remove_file(&exe);
}

#[test]
fn cli_c_backend_syncs_entry_hoist_and_unknown_calls() {
    // Locks three C-generator sync fixes together (each a no-op on the self-host /
    // v0.1 corpus): the entry point runs the first function when there is no `Main`
    // (legacy `Entry`); auto-vivified scalars (`i`, `total`) are hoisted and declared;
    // and an unknown callee is stubbed to the zero-default (statement = no-op,
    // expression = 0) — matching `xb --run`. Output: total 1+2+3 = 6, then the stubbed
    // `XstUnknownVal` call = 0.
    let src = "VERSION \"0.1\"\n\
        FUNCTION Entry ()\n\
        FOR i = 1 TO 3\n\
        total = total + i\n\
        NEXT i\n\
        PRINT total\n\
        XstUnknownProc (total)\n\
        PRINT XstUnknownVal (total)\n\
        END FUNCTION\n";
    let tmp = std::env::temp_dir().join("xb_cli_cgen_sync");
    let _ = std::fs::create_dir_all(&tmp);
    let srcp = tmp.join("sync.x");
    std::fs::write(&srcp, src).unwrap();
    let exe = tmp.join("sync_exe");
    let _ = std::fs::remove_file(&exe);
    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .args([
            "--compile",
            srcp.to_str().unwrap(),
            "-o",
            exe.to_str().unwrap(),
        ])
        .output()
        .unwrap();
    assert!(
        output.status.success(),
        "compile stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let run = Command::new(&exe).output().unwrap();
    assert_eq!(String::from_utf8(run.stdout).unwrap(), "6\n0\n");
    let _ = std::fs::remove_file(&exe);
    let _ = std::fs::remove_file(&srcp);
}

#[cfg(feature = "llvm")]
#[test]
fn cli_compile_llvm_backend_produces_native_executable() {
    let fixture = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures/bootstrap/hello.x");
    let tmp = std::env::temp_dir().join("xb_cli_llvm_test");
    let _ = std::fs::create_dir_all(&tmp);
    let exe = tmp.join("hello_llvm_exe");
    let _ = std::fs::remove_file(&exe);

    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .args([
            "--compile",
            fixture.to_str().unwrap(),
            "-o",
            exe.to_str().unwrap(),
            "--backend",
            "llvm",
        ])
        .output()
        .unwrap();
    assert!(
        output.status.success(),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        exe.exists(),
        "executable was not created at {}",
        exe.display()
    );

    let run = Command::new(&exe).output().unwrap();
    assert!(run.status.success());
    assert_eq!(String::from_utf8(run.stdout).unwrap(), "hello\n");

    let _ = std::fs::remove_file(&exe);
}

/// Differential reach check: for real corpus programs, the LLVM-compiled native
/// binary must produce byte-identical output to the interpreter. Guards against
/// LLVM codegen regressions on arrays/loops/strings (the 61/151 faithful set,
/// docs/17 LB-STUB). Curated to rich-output programs; the full sweep is a manual
/// measurement (too slow for the suite).
#[cfg(feature = "llvm")]
#[test]
fn cli_llvm_matches_interpreter_on_corpus_programs() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let tmp = std::env::temp_dir().join("xb_cli_llvm_diff");
    let _ = std::fs::create_dir_all(&tmp);
    for name in ["demo/aarray.x", "demo/aloha.x", "demo/ahello.x"] {
        let src = root.join("xbasic-6.4.5").join(name);
        let refr = Command::new(env!("CARGO_BIN_EXE_xb"))
            .args(["--run", src.to_str().unwrap()])
            .output()
            .unwrap();
        assert!(refr.status.success(), "interpreter failed on {name}");
        let reference = String::from_utf8_lossy(&refr.stdout).to_string();
        assert!(!reference.is_empty(), "no reference output for {name}");

        let exe = tmp.join(format!("{}.bin", name.replace('/', "_")));
        let _ = std::fs::remove_file(&exe);
        let comp = Command::new(env!("CARGO_BIN_EXE_xb"))
            .args([
                "--compile",
                src.to_str().unwrap(),
                "-o",
                exe.to_str().unwrap(),
                "--backend",
                "llvm",
            ])
            .output()
            .unwrap();
        assert!(
            comp.status.success(),
            "llvm compile failed on {name}: {}",
            String::from_utf8_lossy(&comp.stderr)
        );
        let run = Command::new(&exe).output().unwrap();
        assert!(run.status.success(), "native run failed on {name}");
        assert_eq!(
            String::from_utf8_lossy(&run.stdout),
            reference,
            "LLVM output diverged from interpreter on {name}"
        );
        let _ = std::fs::remove_file(&exe);
    }
}

#[cfg(not(feature = "llvm"))]
#[test]
fn cli_backend_llvm_errors_when_feature_disabled() {
    let fixture = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures/bootstrap/hello.x");
    let tmp = std::env::temp_dir().join("xb_cli_llvm_off_test");
    let _ = std::fs::create_dir_all(&tmp);
    let exe = tmp.join("nope");
    let _ = std::fs::remove_file(&exe);

    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .args([
            "--compile",
            fixture.to_str().unwrap(),
            "-o",
            exe.to_str().unwrap(),
            "--backend",
            "llvm",
        ])
        .output()
        .unwrap();
    assert!(!output.status.success());
    assert!(
        String::from_utf8_lossy(&output.stderr).contains("disabled"),
        "stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn cli_run_reads_piped_stdin_as_input() {
    use std::io::Write;
    use std::process::Stdio;
    // `--run` with no `--with-input` must read piped stdin so interactive
    // programs (READLINE$ / INLINE$) work from a pipe.
    let prog = std::env::temp_dir().join("xb_cli_stdin_test.x");
    std::fs::write(
        &prog,
        "PROGRAM \"echo\"\nVERSION \"1\"\nFUNCTION Main\nline$ = READLINE$\nPRINT \"got:\"; line$\nEND FUNCTION\nEND PROGRAM\n",
    )
    .unwrap();

    let mut child = Command::new(env!("CARGO_BIN_EXE_xb"))
        .args(["--run", prog.to_str().unwrap()])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();
    {
        let mut si = child.stdin.take().unwrap();
        si.write_all(b"hello\n").unwrap();
    } // dropped -> stdin EOF
    let output = child.wait_with_output().unwrap();

    assert!(output.status.success());
    assert_eq!(String::from_utf8(output.stdout).unwrap(), "got:hello\n");
    let _ = std::fs::remove_file(&prog);
}
