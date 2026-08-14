use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

fn collect_x_sources(directory: &Path, sources: &mut Vec<PathBuf>) {
    for entry in fs::read_dir(directory)
        .unwrap_or_else(|error| panic!("failed to read {}: {error}", directory.display()))
    {
        let entry = entry.unwrap_or_else(|error| {
            panic!("failed to read entry in {}: {error}", directory.display())
        });
        let path = entry.path();
        let file_type = entry
            .file_type()
            .unwrap_or_else(|error| panic!("failed to inspect {}: {error}", path.display()));

        if file_type.is_dir() {
            collect_x_sources(&path, sources);
        } else if file_type.is_file() && path.extension().is_some_and(|extension| extension == "x")
        {
            sources.push(path);
        }
    }
}

#[test]
fn cli_accepts_every_selfhost_source() {
    // Given
    let selfhost = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../selfhost");
    let mut sources = Vec::new();
    collect_x_sources(&selfhost, &mut sources);
    sources.sort();
    assert!(
        !sources.is_empty(),
        "no .x sources found under {}",
        selfhost.display()
    );

    // When / Then
    for source in sources {
        let output = Command::new(env!("CARGO_BIN_EXE_xb"))
            .arg(&source)
            .output()
            .unwrap_or_else(|error| panic!("failed to run xb for {}: {error}", source.display()));

        assert!(
            output.status.success(),
            "xb rejected {}\nstatus: {}\nstderr:\n{}",
            source.display(),
            output.status,
            String::from_utf8_lossy(&output.stderr),
        );
    }
}
