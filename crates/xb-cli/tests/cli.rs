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
