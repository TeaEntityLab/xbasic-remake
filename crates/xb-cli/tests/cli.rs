use std::fs;
use std::process::Command;

#[test]
fn cli_prints_stable_ir_summary_for_file() {
    let path = std::env::temp_dir().join(format!("xb-cli-{}.x", std::process::id()));
    fs::write(
        &path,
        "VERSION \"6.5.0\"\nDIM name$\nname$ = \"hello\"\nPRINT name$\n",
    )
    .unwrap();

    let output = Command::new(env!("CARGO_BIN_EXE_xb"))
        .arg(&path)
        .output()
        .unwrap();
    let _ = fs::remove_file(&path);

    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).unwrap(),
        "version 6.5.0\ndim name:string\nassign name:string = string(\"hello\")\nprint symbol(name:string)\n"
    );
}
