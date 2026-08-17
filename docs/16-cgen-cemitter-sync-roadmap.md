# 16 — cgen ↔ CEmitter Sync Roadmap

> Status: living roadmap. Behavioral sync is **locked by tests** as of this entry;
> byte-level parity and several semantic drifts remain **open** (items below).
> Companion to [17-open-work-roadmap.md](17-open-work-roadmap.md) (the umbrella
> "everything not done yet" list). This doc is scoped to the two C generators.

## 1. Why this exists

There are **two independent implementations of the same IR → C contract**:

| Generator | Language | Location | Role |
|---|---|---|---|
| `CEmitter` | Rust | `crates/xb-compiler/src/c_emit_*.rs`, `c_runtime*.rs` | reference C backend |
| `cgen.x` | XBasic | `selfhost/cgen.x` | self-hosted C generator the native bootstrap ships |

Every legacy cgen/bootstrap test checks **one** generator against the interpreter
or a golden. Nothing pinned the two generators **to each other**, so they could
drift silently: a codegen rule fixed in one but not the other only breaks a test
if some corpus program happens to exercise it.

That drift was real and undetected until this roadmap's tests were added — see §3.

## 2. What is LOCKED (tests, present tense)

`crates/xb-runtime/tests/cgen_cemitter_sync.rs`:

- **`cemitter_and_cgen_agree_on_positive_corpus`** — for every program in
  `fixtures/corpus/v0.1/positive`, both generators' native executables produce
  output byte-identical to each other **and** to the golden `.out`. This also
  added the previously-missing coverage of `CEmitter` over the whole corpus (it
  had only ever been run on a single hand-written program in `native_emit.rs`).
- **`cemitter_and_cgen_agree_on_selfhost_tools`** — for `compiler.x`, `lexer.x`,
  `parser.x`, and `cgen.x`, both generators' executables agree with each other
  **and** with the Rust interpreter on the tool's own input.

Sync is asserted on **observable behavior** (native run output), not on emitted
C text, because the emitted C is not yet byte-identical (item **CG-PRELUDE**).

Run: `cargo test -p xb-runtime --test cgen_cemitter_sync`

## 3. Drift fixed while landing the sync tests

The new tests immediately exposed real `CEmitter` defects (all fixed; cgen.x was
already correct — it is a strict superset of CEmitter's runtime):

1. **Missing runtime helpers** — `CEmitter` mapped builtins to `xb_ljust`,
   `xb_date`, `xb_atn`, `xb_tab_0` but never *defined* them. Added to
   `c_runtime_math.rs` / `c_runtime.rs`.
2. **2-arg `MID$`** — fell through to the default path, emitting `xb_mid(s,start)`
   against the 3-arg `xb_mid`. Wired the pre-existing (dead-coded) `emit_mid2`
   helper in `c_emit_expr.rs`; dropped its `#[allow(dead_code)]`.
3. **Missing call-close parens** — the `ABS`-float (`xb_fabs(`) and `STR$`-float
   (`xb_str_float(`) branches in `c_emit_expr.rs` opened a call paren but never
   emitted `)`. Only `str_float` had a corpus program; both fixed.

## 4. OPEN items (not done yet)

### CG-ADDR — address helpers truncate to `int` in CEmitter
`crates/xb-compiler/src/c_runtime.rs:227-229`:
```c
static int xb_goaddr(int x) { return x; }
static int xb_subaddr(int x) { return x; }
static int xb_funcaddress(int x) { return x; }
```
`cgen.x` uses `intptr_t` for all three. On 64-bit, the `CEmitter` versions
**truncate addresses**, and are internally inconsistent with
`xb_cstring(intptr_t addr)` on the next line (`:230`). Fix: change the three
signatures/returns to `intptr_t`. Guard: a sync fixture exercising `GOADDR` /
`SUBADDRESS` / `FUNCADDR` + `CSTRING` round-trips (none exist today → CG-COVER).

### CG-OPEN — `xb_open` ignores file mode 2 in CEmitter
`crates/xb-compiler/src/c_runtime.rs:174-179` maps modes 1→`r+b`, 3→`wb`,
4→`w+b`, everything else (incl. **2**) → `rb` (read-only). `cgen.x` maps modes
`1|2 → r+b`. Reconcile the mode table against the interpreter's semantics
(`$$RD`=0 … `$$RWNEW`=4) and add a mode-2 `OPEN` sync fixture.

### CG-PRELUDE — emitted C is not byte-identical
The two generators emit the same runtime helpers in **different order and
formatting**, and differ in `#include` order (`<ctype.h>`/`<math.h>`). Target:
make the preludes byte-identical so the sync tests can upgrade from behavioral
equality to `assert_eq!` on the emitted C text (the tightest possible lock).
Work: pick one canonical helper order + formatting and align both
`c_runtime*.rs` (Rust `push_str` order) and `selfhost/cgen.x`.

### CG-COVER — behavioral sync corpus has blind spots
The locked tests only cover constructs present in the positive corpus + selfhost
tools. They do **not** exercise address-of builtins (CG-ADDR), file mode 2
(CG-OPEN), or high-byte strings (see 17: RT-BYTESTRING). Add targeted fixtures
so those drifts are caught by CI, not by inspection.

## 5. Verification

```sh
cargo test -p xb-runtime --test cgen_cemitter_sync          # the sync lock
cargo test -p xb-runtime --test cgen_positive_corpus        # cgen.x vs golden
cargo test -p xb-runtime --test cgen_corpus --test cgen_selfhost   # bootstrap
```
