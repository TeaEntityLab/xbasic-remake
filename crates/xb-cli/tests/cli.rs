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
            "function Main\n",
            "  dim utilityName:string\n",
            "  dim utilityVersion:float\n",
            "  assign utilityName:string = string(\"xut\")\n",
            "  assign utilityVersion:float = float(0.0001)\n",
            "  print symbol(utilityName:string)\n",
            "  print symbol(utilityVersion:float)\n",
            "  print constant($$XBSysLinux:integer = integer(1))\n",
            "  print constant($$XBSysWin32:integer = integer(2))\n",
            "end function\n",
        )
    );
}
