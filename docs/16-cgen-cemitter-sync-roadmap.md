# 16 — cgen ↔ CEmitter Sync Roadmap

> Status: living roadmap. Behavioral sync is **locked by tests** as of this entry;
> byte-level parity and several semantic drifts remain **open** (items below).
> Companion to [17-open-work-roadmap.md](17-open-work-roadmap.md) (the umbrella
> "everything not done yet" list). This doc is scoped to the two C generators.
>
> Re-verified **2026-08-17**: `cargo test -p xb-runtime --test cgen_cemitter_sync`
> = **3/3** (positive-corpus, selfhost-tools, helper-signatures). CG-ADDR / CG-OPEN
> / CG-SIG remain ✅ done; CG-BYTES / CG-BODY-COVER remain deferred/open. Full
> workspace suite: 154 passed / 0 failed.

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
C text, because the emitted C is not yet byte-identical (item **CG-BYTES**).

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

## 4. Item status

### CG-ADDR — address helpers now `intptr_t` ✅ done
`c_runtime.rs:227-229` changed `int` → `intptr_t` for `xb_goaddr` / `xb_subaddr`
/ `xb_funcaddress`, matching `cgen.x` and consistent with `xb_cstring(intptr_t)`.
The three emitted definitions are now byte-identical between generators. Guarded
by CG-SIG.

### CG-OPEN — `xb_open` maps file mode 2 ✅ done
`c_runtime.rs:176` now maps `mode == 1 || mode == 2` → `r+b`, matching `cgen.x`'s
table (0→rb, 1|2→r+b, 3→wb, 4→w+b, else rb). Behaviorally identical; the residual
chain-vs-ternary *text* form is cosmetic (CG-BYTES).

### CG-SIG — helper signature parity ✅ done
`cemitter_and_cgen_helper_signatures_match` (in `cgen_cemitter_sync.rs`) asserts
both generators emit the same set of `static <ret> xb_NAME(<param-types>)`
signatures (param names, ordering, and bodies ignored). This is the structural
half of sync — it catches the two drift classes that slip past the behavioral
corpus: a helper present in one generator only (the `xb_ljust` gap), and a
signature/type change in one only (the CG-ADDR `int`/`intptr_t` drift). 174
signatures, identical on both sides.

### CG-BYTES — full byte-identical C — deferred (cosmetic)
Beyond signatures the generators still differ in: helper *ordering*, parameter
*names* (`addr`/`off` vs `a`/`o` in the 12 `*AT` accessors), `#include` order
(`<ctype.h>`/`<math.h>`), and body formatting (e.g. `xb_open` chain vs ternary).
None affect behavior or the signature contract. Full byte-identity would let the
sync test upgrade to `assert_eq!` on emitted C (the tightest lock) but requires
reconciling ~170 helpers' order/formatting between a Rust emitter and an XBasic
one — an ongoing cosmetic burden. **Deferred**: CG-SIG + the behavioral corpus
cover the high-value drift.

### CG-BODY-COVER — behavioral blind spots remain (low priority)
The behavioral tests don't exercise address-of builtins, file mode 2, or
high-byte strings (now a **confirmed** defect — see CG-BYTESTRING), so body-logic drift *in those specific
helpers* isn't caught behaviorally (their signatures still are, via CG-SIG).
Clean closure needs deterministic fixtures (hard for raw addresses / temp files);
tracked, low priority given CG-SIG coverage.

### CG-BYTESTRING — C backend drops embedded NULs / high bytes `[confirmed 2026-08-18]`
Both C generators represent strings as C `char*` null-terminated (`xb_len` = `strlen`,
`xb_concat`/`xb_left`/… `strlen`-based, `xb_chr` NUL-terminates), so `CHR$(0)`, embedded,
and high bytes are silently lost — the **same defect the LLVM backend had before its
RT-BYTESTRING fix (docs/17)**. Evidence — `"AB" + CHR$(0) + "CD"` prints `ABCD` with
`LEN` 4 (should be `AB\0CD`, `LEN` 5) and `LEN(CHR$(0))` 0 (should be 1):

```
xb --run    : 35 0a 41 42 00 43 44 0a 41 00 42 0a 31 0a   (LEN 5; AB\0CD; A\0B; 1)
xb --emit-c : 34 0a 41 42    43 44 0a 41    42 0a 30 0a   (LEN 4; ABCD;  AB;  0)
```

A correctness bug in the **primary AOT path** (the secondary LLVM backend is now correct).
CG-BODY-COVER named this a blind spot; it is now a confirmed, evidence-backed defect.
**Fix path**: length-prefixed strings mirroring the LLVM fix — keep the C type `char*`
but store a `size_t` length in a header before the data (`xb_len` reads the prefix,
`PRINT` writes exact bytes via `fwrite`, compare via `memcmp`+length, string literals
wrapped `xb_lit("…", N)`), applied **identically** to `c_runtime.rs` / `c_emit_*.rs`
**and** `cgen.x` so the sync tests stay green. The bootstrap fixed point (`compiler.ir`,
IR text) is runtime-independent → unaffected; only `cgen_cemitter_sync` +
`cgen_positive_corpus` (behavioral) gate it. Scoped as a large two-generator change
(~40 helpers each); corpus-neutral today (no interp-clean corpus program uses embedded
NULs), so it is **latent-correctness**, not a reach unlock.

**Design boundary (harder than the LLVM fix):** unlike the LLVM backend — where every
string is created by a helper I control — the C backend has strings that arrive as **raw
`char*` aliasing arbitrary memory**: `xb_cstring(intptr_t addr)` returns `(char*)addr`,
and the `*AT` peeks / `VARPTR` paths hand back untracked pointers; file `INPUT`/`fgets`
and `INKEY$` also produce plain C buffers. A uniform prefix representation must therefore
either copy each such source into a prefixed buffer at the boundary, or keep an
address-aliased escape hatch (no prefix, `strlen`-length) — a real design decision, not a
mechanical helper sweep. This is why it is a **multi-day representation overhaul**, not a
drop-in of the LLVM change.

## 5. Verification

```sh
cargo test -p xb-runtime --test cgen_cemitter_sync          # the sync lock
cargo test -p xb-runtime --test cgen_positive_corpus        # cgen.x vs golden
cargo test -p xb-runtime --test cgen_corpus --test cgen_selfhost   # bootstrap
```
