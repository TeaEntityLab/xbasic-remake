//! Demo corpus interp<->C parity: every demo that compiles+links standalone
//! must produce byte-identical stdout between the interpreter and the
//! compiled C binary (both with stdin=/dev/null, 10s timeout).
//!
//! The SKIP list is demos whose standalone link fails on undefined symbols
//! (GUI/network/kernel32 functions that only resolve when linked against
//! the prebuilt core-library objects — see checks/link-core-libs.sh).

use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

/// Demos that fail standalone LINK (undefined external symbols).
const SKIP: &[&str] = &[
    "Kittedy",
    "aarray_ISNODE",
    "acgibin",
    "aclient",
    "aprofile",
    "aserver",
    "gif",
    "gifview",
    "qbtoxb",
];

fn repo_root() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

/// Run with a timeout; None = timed out.
fn run_timed(cmd: &mut Command, timeout: Duration) -> Option<Vec<u8>> {
    use std::io::Read;
    let mut child = cmd
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .spawn()
        .expect("spawn");
    let deadline = Instant::now() + timeout;
    let mut out = Vec::new();
    loop {
        if let Some(mut pipe) = child.stdout.take() {
            let mut buf = [0u8; 65536];
            match pipe.read(&mut buf) {
                Ok(0) => break,
                Ok(n) => out.extend_from_slice(&buf[..n]),
                Err(_) => break,
            }
        }
        if Instant::now() > deadline {
            let _ = child.kill();
            let _ = child.wait();
            return None;
        }
        match child.try_wait() {
            Ok(Some(_)) => break,
            Ok(None) => std::thread::sleep(Duration::from_millis(10)),
            Err(_) => return None,
        }
    }
    let _ = child.wait();
    Some(out)
}

#[test]
fn demo_interp_matches_compiled() {
    let root = repo_root();
    let demo_dir = root.join("xbasic-6.4.5/demo");
    let tmp = std::env::temp_dir().join("demo_parity");
    let _ = std::fs::create_dir_all(&tmp);
    let xb = root.join("target/release/xb");

    let mut sources: Vec<_> = std::fs::read_dir(&demo_dir)
        .expect("demo dir")
        .filter_map(|e| {
            let p = e.ok()?.path();
            (p.extension()?.to_str()? == "x").then_some(p)
        })
        .collect();
    sources.sort();

    let mut checked = 0;
    for src in &sources {
        let name = src.file_stem().unwrap().to_str().unwrap().to_owned();
        if SKIP.contains(&name.as_str()) {
            continue;
        }

        // Interpreter output. Run from the temp dir: some demos write
        // side-effect files (astring.dat, *.map, *.lab) into the CWD.
        let mut interp_cmd = Command::new(&xb);
        interp_cmd.arg("--run").arg(src).current_dir(&tmp);
        let interp = run_timed(
            &mut interp_cmd,
            Duration::from_secs(10),
        )
        .unwrap_or_else(|| panic!("{name}: interp timed out"));

        // Emit C, compile, link, run.
        let emit = Command::new(&xb)
            .arg("--emit-c")
            .arg(src)
            .output()
            .expect("emit");
        let c_file = tmp.join("demo.c");
        std::fs::write(&c_file, &emit.stdout).unwrap();
        let bin = tmp.join("demo_bin");
        let cc = Command::new("cc")
            .args(["-O1", "-w"])
            .arg(&c_file)
            .arg("-o")
            .arg(&bin)
            .output()
            .expect("cc");
        assert!(cc.status.success(), "{name}: cc/link failed");

        let mut bin_cmd = Command::new(&bin);
        bin_cmd.current_dir(&tmp);
        let compiled = run_timed(
            &mut bin_cmd,
            Duration::from_secs(10),
        )
        .unwrap_or_else(|| panic!("{name}: compiled binary timed out"));
        let _ = std::fs::remove_file(&bin);

        assert_eq!(
            interp, compiled,
            "{name}: output diverges:\n  interp:   {}\n  compiled: {}",
            String::from_utf8_lossy(&interp),
            String::from_utf8_lossy(&compiled),
        );
        checked += 1;
    }
    let _ = std::fs::remove_dir_all(&tmp);
    assert!(checked >= 100, "expected >=100 parity demos, got {checked}");
}
