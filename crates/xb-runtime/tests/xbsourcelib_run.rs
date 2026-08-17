//! MIG-SEMANTICS (docs/17): run-level coverage of XBSourceLib core libraries
//! through the interpreter — not just parse/lower (that is MIG-CORPUS-GATE), but
//! executing to a clean exit and locking observable output where it is correct.

use std::path::{Path, PathBuf};
use xb_compiler::FrontendUnit;
use xb_runtime::Interpreter;

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn run_lib(rel: &str) -> Vec<String> {
    let src =
        std::fs::read_to_string(root().join(rel)).unwrap_or_else(|e| panic!("read {rel}: {e}"));
    let program = FrontendUnit::parse(&src)
        .unwrap_or_else(|e| panic!("parse {rel}: {e:?}"))
        .lower_ir()
        .unwrap_or_else(|e| panic!("lower {rel}: {e:?}"));
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main(&program, &mut output)
        .unwrap_or_else(|e| panic!("run {rel}: {e:?}"));
    output
}

/// The merge-utility programs lower AND run to a clean exit through the
/// interpreter. Guards run-level regressions the parse-only MIG-CORPUS-GATE
/// cannot catch. (ary.x also lowers, but its `Entry` now runs `TestAryPerformance`
/// end to end via GOSUB-SCOPE, which needs array-of-composite / auto-grow arrays
/// not yet supported — tracked in docs/17.)
#[test]
fn xbsourcelib_smoke_libs_run_clean() {
    assert_eq!(run_lib("XBSourceLib/utils/mergeTest01.x"), [" Got Here"]);
    assert_eq!(run_lib("XBSourceLib/utils/mergeTest02.x"), [" Got Here"]);
}

/// `msc.x` runs end to end through `TestMscHex`: `MscStrHex$` encodes the string to
/// hex and `MscHexStr$` decodes it back. The full round-trip is now correct
/// (RT-BYTESTRING + SEL-CASE-TRUE + VAR-SUFFIX-COLLISION + GOSUB-SCOPE), so all
/// three lines — including the decoded original — are locked.
#[test]
fn xbsourcelib_msc_strhex_is_correct() {
    let out = run_lib("XBSourceLib/msc/msc.x");
    assert_eq!(out.len(), 3, "msc.x should print 3 lines, got {out:?}");
    assert_eq!(out[0], "Test: robin@example.com");
    assert_eq!(
        out[1], "Coded as: 726F62696E406578616D706C652E636F6D",
        "MscStrHex$ string->hex encoding must be correct"
    );
    assert_eq!(
        out[2], "Decoded as: robin@example.com",
        "MscHexStr$ hex->string round-trip must recover the original"
    );
}

/// `geo.x` runs end to end via nested composite parameters passed by reference
/// (`GeoPerpendicularLine(GEO_BINODE L1, ..., GEO_BINODE @L2)`), float/int
/// comparison, and multi-variable composite declarations.
#[test]
fn xbsourcelib_geo_runs_via_composite_params() {
    let out = run_lib("XBSourceLib/geo/geo.x");
    assert_eq!(out.len(), 1, "geo.x should print one line, got {out:?}");
    // Midpoint of (10,10)-(50,50) is (30,30); the perpendicular starts there.
    assert!(
        out[0].starts_with("Perpendicular:") && out[0].contains("30"),
        "unexpected geo.x output: {:?}",
        out[0]
    );
}
