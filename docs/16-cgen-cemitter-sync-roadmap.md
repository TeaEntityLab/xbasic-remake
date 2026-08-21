# 16 — cgen ↔ CEmitter Sync Roadmap

> Status: living roadmap. Behavioral sync is **locked by tests** as of this entry;
> byte-level parity and several semantic drifts remain **open** (items below).
> Companion to [17-open-work-roadmap.md](17-open-work-roadmap.md) (the umbrella
> "everything not done yet" list). This doc is scoped to the two C generators.
>
> Re-verified **2026-08-20**: `cargo test -p xb-runtime --test cgen_cemitter_sync`
> = **5/5** (positive-corpus, selfhost-tools, helper-signatures, embedded-NUL strings,
> high-byte strings). CG-ADDR / CG-OPEN / CG-SIG / CG-BYTESTRING remain ✅ done;
> CG-BYTES / CG-BODY-COVER remain deferred/open. Full workspace suite: **182 / 0**.
> Note: the five 2026-08-20 CEmitter demo fixes (docs/17 §1 Backend feature-sync) are
> deliberate **no-ops on the shared corpus** — byte-identity with `cgen.x` held without
> touching it.

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

### CG-BODY-COVER — computed GOTO closed; AT-deref + file-mode-2 remain (low priority)
Behavioral coverage of the addr-of / control-flow builtins is now substantial: the
positive corpus executes computed GOSUB (`computed_gosub_test`, `GosubExpr` via
`SUBADDRESS`), `FUNCADDRESS` (`funcaddress_test`), and sequential file I/O
(`fileio_test`, mode 0) through both C generators + the interpreter. **Computed GOTO
(`GotoExpr` via `GOADDRESS`) is now locked** by `cemitter_and_cgen_agree_on_computed_goto`
— adding it surfaced a real latent drift: cgen.x's `goto_expr` arm compared `LEFT$(s$, 9)`
against the 10-char `"goto_expr "` and never fired, so the self-hosted generator silently
dropped every computed GOTO (fixed `1efe782`, byte-neutral on the corpus, bootstrap fixed
point intact). Embedded-NUL / low-byte strings are covered by CG-BYTESTRING; **true high
bytes (`0x80`–`0xFF`)** by `cemitter_and_cgen_agree_on_high_byte_strings` (`CHR$(200)+CHR$(255)`
→ byte-faithful `LEN`/`PRINT`; the interpreter is excluded there — its `Vec<String>` output
sink is UTF-8-lossy for high bytes, so the byte-faithful C backends are the reference).
Remaining blind spots are the **AT-dereference builtins** (`XLONGAT`/`GIANTAT`/`SUBADDRAT`/
`GOADDRAT`) and **file mode 2**: the AT builtins are interp-divergent *by design* (the
interpreter has no real memory and returns 0, while the C backends dereference real
addresses), so a clean deterministic cross-backend fixture is genuinely hard — tracked, low
priority.

### CG-BYTESTRING — byte-accurate strings in both C generators ✅ done `[2026-08-18]`
Both C generators previously represented strings as C `char*` null-terminated (`xb_len` =
`strlen`, `xb_concat`/`xb_left`/… `strlen`-based, `xb_chr` NUL-terminating), so `CHR$(0)`,
embedded, and high bytes were silently lost — the same defect the LLVM backend had before
its RT-BYTESTRING fix (docs/17). Before: `"AB" + CHR$(0) + "CD"` printed `ABCD` with `LEN`
4 and `LEN(CHR$(0))` 0.

**Fix (applied identically to `c_runtime*.rs` / `c_emit_*.rs` and `cgen.x`):** a string is
now a length-prefixed byte-string — a `char*` to the data with a `size_t` length in an
8-byte header before it (`xb_alloc` / `xb_len`) plus a trailing NUL for C interop. Every
producer allocates via `xb_alloc`; `xb_concat` / `LEN` / `LEFT$` / `RIGHT$` / `MID$` /
`CHR$` / case / trim / space / `STR$` / `HEX$` / `FORMAT$` / … use the prefix length;
`PRINT` writes exact bytes via `fwrite`; string comparison uses `xb_scmp` (`memcmp` +
length tiebreak). Boundary sources that hand back raw C strings (`xb_cstring` from an
address — now `0`-guarded, `INPUT`/`fgets`, `INKEY$`, DATA literals, program/version
names) snapshot into a prefixed buffer via `xb_from_cstr`. String literals keep the
`xb_str("…")` emission (now a prefixed copy).

Now byte-exact and identical across interpreter, CEmitter, and native `cgen.x`:
`"AB"+CHR$(0)+"CD"` → `35 0a 41 42 00 43 44 0a 41 00 42 0a 31 0a` (LEN 5; `AB\0CD`; `A\0B`;
`LEN(CHR$(0))` 1) from all three. The bootstrap fixed point (`compiler.ir` SHA-256
`c8d5c7f1…`) is unchanged (runtime-independent). Locked by
`cgen_cemitter_sync::cemitter_and_cgen_agree_on_embedded_nul_strings` (both generators ==
interpreter), plus the existing corpus/selfhost sync tests. Residual: the `INSTR` / `RINSTR`
/ case-insensitive search helpers still use `strstr` / `strncmp` internally — correct for
the null-free norm, imperfect only for an embedded NUL *inside a search string* (extreme
edge), documented and non-crashing.

## 5. Verification

```sh
cargo test -p xb-runtime --test cgen_cemitter_sync          # the sync lock
cargo test -p xb-runtime --test cgen_positive_corpus        # cgen.x vs golden
cargo test -p xb-runtime --test cgen_corpus --test cgen_selfhost   # bootstrap
```
