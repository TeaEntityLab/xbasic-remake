//! Multi-library integration test: verifies that the 15 core libraries
//! compile cc-clean, link together into one binary via weak-symbol mode,
//! and that cross-TU function calls resolve correctly.
//!
//! Uses `checks/link-core-libs.sh` (which sets XB_WEAK_SYMBOLS=1) to build
//! all libraries and link them with a smoke test calling Version$ from
//! seven libraries. Locks the CGEN-LIB-MODE + CORE-LIBS-LINK milestones.

use std::process::Command;

#[test]
fn core_libraries_link_and_execute() {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap();
    let script = root.join("checks").join("link-core-libs.sh");
    assert!(script.exists(), "link-core-libs.sh not found");

    let out_dir = std::env::temp_dir().join("xb_multi_lib_test");
    let _ = std::fs::remove_dir_all(&out_dir);

    let output = Command::new("sh")
        .arg(&script)
        .arg(&out_dir)
        .output()
        .expect("failed to run link-core-libs.sh");

    let stderr = String::from_utf8_lossy(&output.stderr);
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Script should succeed
    assert!(
        output.status.success(),
        "link-core-libs.sh failed:\nstderr: {stderr}\nstdout: {stdout}"
    );

    // Binary should exist
    let binary = out_dir.join("xblibs");
    assert!(binary.exists(), "linked binary not found at {binary:?}");

    // Smoke test output should contain ALL OK
    assert!(
        stdout.contains("ALL OK"),
        "smoke test did not pass:\n{stdout}"
    );
}
