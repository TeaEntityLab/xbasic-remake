# Licensing

The XBasic remake's own code is **MIT licensed** ([`LICENSE`](LICENSE)).
The ported upstream XBasic source material in [`xbasic/`](xbasic/) remains
under the upstream **GPL-2.0 / LGPL-2.1** licenses (complete canonical
texts at `xbasic/COPYING` and `xbasic/COPYING_LIB`; per-file audit in
[`xbasic/LICENSES.md`](xbasic/LICENSES.md)).

## Per-directory map

| Path | License | Notes |
|---|---|---|
| `crates/*` (compiler, frontend, cli, runtime, gui, ide, link) | `MIT` | Declared in each `Cargo.toml`. Original code, written from scratch for this project. |
| `selfhost/` | `MIT` | Self-hosted compiler sources written in XBasic for this project. |
| `fixtures/`, `docs/`, `checks/`, `scripts/`, `prompts/` | `MIT` | Project test fixtures, documentation, and tooling. |
| `xbasic/` | upstream GPL-2 / LGPL-2.1 | **Tracked, distributed.** Verbatim port of license-cleared source material from the upstream 6.4.5 release, reorganized (`lib/`, `include/`, `demo/`, `crtl/`, …). Copyright 1988-2000+ Max Reason; C runtime ports (`crtl/`) copyright 2000 Wade Maxfield (LGPL). Not relicensable by this project. |
| `xbasic-6.2.3/`, `xbasic-6.3.26-D/`, `xbasic-6.4.5/`, `XBSourceLib/` | upstream GPL-2 / LGPL-2.1 (XBSourceLib: none stated) | **Local reference material only — gitignored, not distributed.** Each XBasic tree carries its own `COPYING`/`COPYING_LIB`; per-file headers govern. XBSourceLib has no explicit license statement and is therefore excluded from the tracked port. |

## Provenance rules

1. **MIT covers original work only.** The Rust crates are a fresh
   implementation of documented XBasic behavior — not a translation of
   the upstream assembly (`xlib.s`) or the LGPL C ports (`crtl/`).
   Audited: no upstream copyright markers or copied code in `crates/`,
   `selfhost/`, `fixtures/`, `checks/`, `scripts/`. Any future code
   translated or copied from upstream sources must live under the
   upstream license (in `xbasic/` or clearly marked), never under MIT.
2. **The tracked corpus is `xbasic/`.** The gitignored legacy trees
   remain local-only inputs (superseded versions, generated `.s`
   assembly, binaries, unlicensed XBSourceLib). Tests targeting the
   ported tree run everywhere; tests targeting local-only material
   (`.s` source-coverage guard, XBSourceLib corpus rows) skip when the
   trees are absent.
3. **LGPL-derived C code lives in exactly one place** —
   `xbasic/crtl/` (upstream's own C ports). The `.c` counterpart files
   beside legacy `.s` files in the local 6.4.5 tree are pure reference
   stubs with no duplicated code; superseded dated snapshots are
   isolated in `xbasic-6.4.5/src/linux/lib/old-versions/`.
4. **Compilation does not propagate licenses.** Compiling GPL/LGPL
   `.x` sources with the MIT toolchain leaves the toolchain MIT and
   the sources under their own license. A *program* that links the
   ported `xbasic/lib` libraries or `crtl/` runtime inherits GPL/LGPL
   obligations **for those parts**; a program using only the MIT
   `crates/xb-runtime` C runtime is unencumbered.
5. Nothing in this file grants or changes any license; it documents
   the declarations in `LICENSE`, the `Cargo.toml` files, and the
   upstream trees.

## Known gaps (tracked as RR-11 in docs/17-open-work-roadmap.md)

- Three upstream Win32 compatibility shims (`xbasic/lib/gdi32.x`,
  `kernel32.x`, `user32.x`) carry **no copyright notice or license
  statement**. They ship solely as part of the upstream release under
  its tree-level distribution; do not redistribute them separately
  until provenance is resolved.
- `checks/link-core-libs.sh` combines GPL-header, LGPL-header, and
  no-notice inputs into one `xblibs` test artifact. That artifact is
  **internal-test-only** and must not be packaged or redistributed
  until shim provenance and distribution obligations are resolved.
  See README §License and docs/17 L15/RR-11.
