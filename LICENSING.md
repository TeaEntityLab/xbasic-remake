# Licensing

This repository is a Rust reimplementation of XBasic. It follows the
upstream XBasic licensing split: **compiler/tooling under GPL, runtime
libraries under LGPL** (so programs built with the toolchain are not
forced under the GPL by linking the runtime).

License texts at the repository root (complete canonical GNU texts —
the upstream trees ship their numbered bodies without the GNU title,
version line, and Preamble; the root copies restore the full texts):

- [`COPYING`](COPYING) — GNU General Public License, version 2
- [`COPYING_LIB`](COPYING_LIB) — GNU Lesser General Public License, version 2.1

## Per-directory map

| Path | License | Notes |
|---|---|---|
| `crates/xb-compiler`, `crates/xb-frontend`, `crates/xb-cli`, `crates/xb-ide`, `crates/xb-link` | `GPL-2.0-or-later` | Declared in each `Cargo.toml`. New code. |
| `crates/xb-runtime`, `crates/xb-gui` | `LGPL-2.1-or-later` | Declared in each `Cargo.toml`. New code; LGPL so user programs linking the runtime stay freely licensable. |
| `selfhost/` | `GPL-2.0-or-later` | Self-hosted compiler sources written in XBasic for this project (compiler component). |
| `fixtures/`, `docs/`, `checks/`, `scripts/`, `prompts/` | `GPL-2.0-or-later` | Project test fixtures, documentation, and tooling. |
| `xbasic/` | upstream GPL-2 / LGPL-2.1 | **Tracked, distributed.** Verbatim port of license-cleared source material from the upstream 6.4.5 release, reorganized (`lib/`, `include/`, `demo/`, `crtl/`, …). Per-file audit in [`xbasic/LICENSES.md`](xbasic/LICENSES.md); canonical `COPYING`/`COPYING_LIB` copies in the tree. |
| `xbasic-6.2.3/`, `xbasic-6.3.26-D/`, `xbasic-6.4.5/`, `XBSourceLib/` | upstream GPL-2 / LGPL-2.1 (XBSourceLib: none stated) | **Local reference material only — gitignored, not distributed.** Each XBasic tree carries its own `COPYING`/`COPYING_LIB`; per-file headers govern. XBSourceLib has no explicit license statement and is therefore excluded from the tracked port. Copyright 1988-2000+ Max Reason; C runtime ports copyright 2000 Wade Maxfield (LGPL). |

## Provenance rules

1. **The tracked corpus is `xbasic/`.** The gitignored legacy
   trees remain local-only inputs (superseded versions, generated `.s`
   assembly, binaries, unlicensed XBSourceLib). Tests targeting the
   ported tree run everywhere; tests targeting local-only material
   (`.s` source-coverage guard, XBSourceLib corpus rows) skip when the
   trees are absent.
2. **LGPL-derived C code lives in exactly one place** — `crtl/`
   (upstream's own C ports; `xbasic/crtl/` in the tracked tree,
   mirrored from `xbasic-6.4.5/src/crtl/`). The `.c` counterpart files
   beside legacy `.s` files are pure reference stubs with no duplicated
   code; superseded dated snapshots are isolated in
   `xbasic-6.4.5/src/linux/lib/old-versions/` with their own README.
3. **The Rust runtime (`crates/xb-runtime`) is a fresh implementation**
   of the documented XBasic runtime behavior, not a translation of the
   LGPL assembly. It is nevertheless licensed LGPL-2.1-or-later to
   match the upstream runtime's licensing intent.
4. Nothing in this file grants or changes any license; it documents the
   declarations already present in `Cargo.toml` files and upstream
   trees.

## Known gaps (tracked as RR-11 in docs/17-open-work-roadmap.md)

- Three upstream Win32 compatibility shims (`gdi32.x`, `kernel32.x`,
  `user32.x` in the legacy trees) carry **no copyright notice or license
  statement**. Their provenance cannot be resolved from repository
  evidence alone.
- `checks/link-core-libs.sh` combines GPL-header, LGPL-header, and
  no-notice inputs into one `xblibs` test artifact. That artifact is
  **internal-test-only** and must not be packaged or redistributed
  until shim provenance and distribution obligations are resolved.
  See README §License and docs/17 L15/RR-11.
