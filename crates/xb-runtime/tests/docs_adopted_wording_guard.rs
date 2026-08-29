use std::fs;
use std::path::Path;

fn read_repo_file(rel_path: &str) -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../")
        .join(rel_path);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {}: {}", path.display(), e))
}

fn assert_contains(rel_path: &str, needle: &str) {
    let content = read_repo_file(rel_path);
    assert!(
        content.contains(needle),
        "expected wording not found in {rel_path}: {needle:?}"
    );
}

fn assert_not_contains(rel_path: &str, needle: &str) {
    let content = read_repo_file(rel_path);
    assert!(
        !content.contains(needle),
        "superseded wording remains in {rel_path}: {needle:?}"
    );
}

fn assert_occurs_exactly(rel_path: &str, needle: &str, expected: usize) {
    let content = read_repo_file(rel_path);
    let actual = content.matches(needle).count();
    assert_eq!(
        actual, expected,
        "unexpected occurrence count in {rel_path}: {needle:?}"
    );
}

#[test]
fn docs_adopted_wording_is_present() {
    let open_work = "docs/17-open-work-roadmap.md";

    // One canonical evidence banner: standalone raw result, harness-assisted CI.
    assert_occurs_exactly(open_work, "Last full re-verification:", 1);
    assert_contains(
        open_work,
        "that manual raw result is evidence, not yet an unassisted CI contract",
    );
    assert_contains(open_work, "transitional post-emission rewrites");
    assert_not_contains(open_work, "raw cgen.x output is not yet a 114/114");

    // Current compiler queue and falsifiability.
    assert_contains(open_work, "RR-13 raw demo guard & RR-03 scoped facets");
    assert_contains(
        open_work,
        "Strip test-local harness rewrites in `cgen_x_compiles_all_demos_cc_clean`",
    );
    assert_contains(open_work, "Heuristic patch falsifiability");
    assert_contains(open_work, "9/15 at `54db874`");

    // ARY compile-only evidence is separate from the 11-program parity loop.
    assert_contains("README.md", "locks runtime parity for 11 non-ARY programs");
    assert_contains(
        "docs/18-byref-array-abi.md",
        "loop covers 11 non-ARY programs",
    );
    assert_contains(
        "docs/README.md",
        "general composite `TYPE` array by-ref and runtime behavior remain open",
    );

    // Historical documents cannot masquerade as living roadmaps.
    assert_contains(
        "docs/10-unification-plan.md",
        "Lifecycle: historical proposal / superseded architecture",
    );
    assert_contains(
        "docs/12-rust-llvm-rewrite-survey.md",
        "Lifecycle: historical research survey / reference design",
    );
    assert_contains(
        "docs/13-bootstrap-scaffold.md",
        "Lifecycle: frozen milestone record",
    );
    assert_contains(
        "docs/14-self-hosting-progress.md",
        "Lifecycle: milestone progress narrative",
    );
    assert_contains("docs/README.md", "Roadmap and lifecycle authority");

    // Current LLVM and selfhost floors replace the stale milestone claims.
    assert_contains("docs/13-bootstrap-scaffold.md", "Homebrew LLVM **22.1.8**");
    assert_contains(
        "docs/14-self-hosting-progress.md",
        "test-locked **9/15 floor**",
    );
    assert_not_contains(
        "docs/14-self-hosting-progress.md",
        "currently returns an empty `ObjectFile`",
    );

    // Compile/link, runtime effects, and provenance are explicit boundaries.
    assert_contains(
        "docs/04-libraries.md",
        "Compile/link is not runtime behavioral fidelity",
    );
    assert_contains("docs/04-libraries.md", "`ATTACH` array-aliasing gap");
    assert_contains(
        "docs/04-libraries.md",
        "Capability security and host access",
    );
    assert_contains("docs/04-libraries.md", "Headless GUI execution model");
    assert_contains("docs/00-overview.md", "Three Win32 compatibility shims");
    assert_contains(
        open_work,
        "compliance risk assessment, not a legal determination",
    );
    assert_contains(open_work, "Notice-file boundary");
    assert_not_contains(open_work, "legally GPL-2.0-infected");
    assert_not_contains(open_work, "truncated at §0");

    // cgen.x body architecture and scoped-facet cutover remain explicit.
    assert_contains(
        "docs/16-cgen-cemitter-sync-roadmap.md",
        "without a global `cOut$` buffer",
    );
    assert_contains(
        "crates/xb-runtime/tests/cgen_cemitter_sync.rs",
        "via per-function fullBody$",
    );
    assert_contains(
        "docs/19-cgen-facet-manifest.md",
        "keyed by `(scope, name, type)`",
    );
}
