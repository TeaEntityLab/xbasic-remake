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
    assert!(c_source.contains("int main(void)"));
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
