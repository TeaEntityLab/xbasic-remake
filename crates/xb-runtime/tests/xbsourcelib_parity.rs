//! XBSourceLib parity: every non-GUI XBSourceLib program must produce
//! byte-identical output between the interpreter and the compiled C binary.

mod common;

use std::process::{Command, Stdio};

const PROGRAMS: &[&str] = &[
    "XBSourceLib/geo/geo.x",
    "XBSourceLib/msc/msc.x",
    "XBSourceLib/utils/XBMerge.x",
    "XBSourceLib/utils/mergeOut.x",
    "XBSourceLib/utils/mergeOut02.x",
    "XBSourceLib/utils/mergeTest01.x",
    "XBSourceLib/utils/mergeTest02.x",
    "XBSourceLib/utils/mergeTest03.x",
    // GUI programs: both paths exit 0 silently without a display; parity
    // still locks compile+link+run+exit behavior.
    "XBSourceLib/fgr/fgr.x",
    "XBSourceLib/vgr/vgr.x",
    "XBSourceLib/vgr/vgrOld.x",
];

fn repo_root() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf()
}

fn run_interp(src: &std::path::Path) -> Vec<u8> {
    let out = Command::new(common::xb_bin())
        .args(["--run"])
        .arg(src)
        .stdin(Stdio::null())
        .output()
        .expect("interp");
    out.stdout
}

fn run_compiled(src: &std::path::Path, tmp: &std::path::Path) -> Vec<u8> {
    let c_file = tmp.join("prog.c");
    let bin = tmp.join("prog_bin");
    let emit = Command::new(common::xb_bin())
        .args(["--emit-c"])
        .arg(src)
        .output()
        .expect("emit");
    std::fs::write(&c_file, &emit.stdout).unwrap();
    let cc = Command::new(common::cc::cc())
        .args([
            "-O0",
            "-Wno-incompatible-pointer-types",
            "-Wno-int-conversion",
        ])
        .arg(&c_file)
        .arg("-o")
        .arg(&bin)
        .output()
        .expect("cc");
    assert!(cc.status.success(), "cc failed for {src:?}");
    let out = Command::new(&bin)
        .stdin(Stdio::null())
        .output()
        .expect("run");
    let _ = std::fs::remove_file(&bin);
    out.stdout
}

#[test]
fn xbsourcelib_interp_matches_compiled() {
    let root = repo_root();
    let tmp = std::env::temp_dir().join("xbsrclib_parity");
    let _ = std::fs::create_dir_all(&tmp);
    for prog in PROGRAMS {
        let src = root.join(prog);
        let interp = run_interp(&src);
        let compiled = run_compiled(&src, &tmp);
        assert_eq!(
            interp, compiled,
            "output diverges for {prog}:\n  interp:   {interp:?}\n  compiled: {compiled:?}"
        );
    }
    let _ = std::fs::remove_dir_all(&tmp);
}

/// ary.x and ary1.0001.x crash at runtime (known composite-byref issue,
/// docs/18) so they can't be parity-locked — but they must keep compiling
/// cc-clean. This locks the emit+compile half of their pipeline.
#[test]
fn xbsourcelib_ary_compiles_clean() {
    let root = repo_root();
    let xb = common::xb_bin();
    let tmp = std::env::temp_dir().join("xbsrclib_ary");
    let _ = std::fs::create_dir_all(&tmp);
    for prog in ["XBSourceLib/ary/ary.x", "XBSourceLib/ary/ary1.0001.x"] {
        let src = root.join(prog);
        let emit = Command::new(&xb)
            .arg("--emit-c")
            .arg(&src)
            .output()
            .expect("emit");
        let c_file = tmp.join("prog.c");
        std::fs::write(&c_file, &emit.stdout).unwrap();
        let cc = Command::new(common::cc::cc())
            .args(["-O0", "-w", "-c"])
            .arg(&c_file)
            .arg("-o")
            .arg(tmp.join("prog.o"))
            .output()
            .expect("cc");
        assert!(
            cc.status.success(),
            "{prog} no longer compiles cc-clean:\n{}",
            String::from_utf8_lossy(&cc.stderr)
        );
    }
    let _ = std::fs::remove_dir_all(&tmp);
}
