# 16 — cgen ↔ CEmitter Sync Roadmap

> Status: living dual-generator contract. Behavioral equivalence, runtime-ABI
> conformance, helper-signature parity, and the narrow positive-corpus
> emitted-C lock are test-enforced contracts. A failing gate records an
> implementation regression; it does not relax the contract. Demo- and
> library-scale C-text identity remains a non-goal.
>
> **Active development notice (2026-09-01):**
> `cgen_x_compiles_all_demos_cc_clean` currently fails for 21 demos on missing
> generated label definitions, and the positive-corpus `fileio_test` golden is
> under investigation. The last green totals below are dated historical
> evidence. Current defects and exit gates are owned by docs/17.
>
> Historical snapshot **2026-08-29/30**: the positive-corpus test asserted
> per-program emitted-C equality; RR-13 subsequently removed all-demo harness
> rewrites and established the raw-generator compile contract. This snapshot
> must not be read as the current working-tree result.

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

### 1.1 Contract authority

Both generators implement one shared typed-IR and runtime ABI contract:

1. **Typed IR syntax and meaning:** every statement, expression, value type,
   control-flow form, and `version` transition has one defined interpretation.
2. **Scope-qualified symbol facets:** storage, rank, dual-use, shared, and
   by-ref facts are frontend-owned and serialized for consumers as specified
   by docs/19. A generator must not silently reconstruct a conflicting fact.
3. **Runtime ABI:** primitive and composite representations, managed-string
   layout, array descriptors, by-ref write-back, lowered symbol/label
   conventions, entry points, and helper signatures are shared invariants.
4. **Observable behavior:** exit status, stdout/stderr, files and permitted host
   effects, memory/aliasing semantics, and runtime errors must agree for the
   same supported program.

The implementations may differ in traversal, temporary names, whitespace,
comments, and local organization. Any lowering or ABI change updates the
applicable contract surface, both implementations unless explicitly
backend-only, and the smallest differential test that observes the change.
Hand-maintained line-by-line emitter mirroring is not evidence of conformance.

“Versioned” means the existing Text IR `version` field and documented ABI
transitions. It does not introduce parallel-version or SemVer machinery until
the toolchain actually needs to consume more than one live contract version.

Text identity has two bounded roles: cross-generator emitted-C identity on the
positive diagnostic corpus, and stage-to-stage identity in bootstrap
fixed-point checks. Demo/library C text identity is not required.

## 2. What the tests lock (contract, not a green-status claim)

`crates/xb-runtime/tests/cgen_cemitter_sync.rs`:

A red result means an implementation currently violates the named contract; it
must not be rewritten as a weaker claim to make the test pass.

- **`cemitter_and_cgen_agree_on_positive_corpus`** — for every program in
  `fixtures/corpus/v0.1/positive`, both generators' native executables produce
  output byte-identical to each other **and** to the golden `.out`. This also
  added the previously-missing coverage of `CEmitter` over the whole corpus (it
  had only ever been run on a single hand-written program in `native_emit.rs`).
- **`cemitter_and_cgen_agree_on_selfhost_tools`** — for `compiler.x`, `lexer.x`,
  `parser.x`, and `cgen.x`, both generators' executables agree with each other
  **and** with the Rust interpreter on the tool's own input.

Sync is asserted on observable native behavior, and the positive-corpus test
additionally asserts the two generators' emitted C byte-for-byte per program
(added 2026-08-27 — previously session-verified only). demo-scale C-text identity is **de-scoped**; see docs/17 CGEN-FACET-MANIFEST. Positive-corpus and selfhost-tool identity are **locked by tests**.

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

### CG-BYTES — positive corpus byte-identical ✅ done; demo text identity de-scoped
All **81/81** programs in `fixtures/corpus/v0.1/positive` now emit byte-identical
C from the Rust CEmitter and self-hosted `cgen.x`. The sync suite locks this
contract alongside behavioral parity and helper signatures.

The broader demo surface is not text-identical (~7/114 at last measurement) and
**demo text identity is a non-goal** (panel 2026-08-27): behavioral parity plus
the corpus byte lock are the governing contracts. The residual signal — cgen.x's
fragile global classifiers — is tracked as CGEN-FACET-MANIFEST in docs/17; any
future text-identity work goes through that route, never more text scanning.
*Note on demo emission:* `cgen.x` uses per-function `fullBody$`, top-level
`mainBody$`, and `fwdDeclsBuf$` transforms without a global `cOut$` buffer.
The named 114/114 compile test additionally applies transitional harness
rewrites; that result is not raw-generator proof until RR-13.

### CG-BODY-COVER — computed GOTO + AT-write lvalue closed; AT-deref reads + file-mode-2 remain (low priority)
Behavioral coverage of the addr-of / control-flow builtins is now substantial: the
positive corpus executes computed GOSUB (`computed_gosub_test`, `GosubExpr` via
`SUBADDRESS`), `FUNCADDRESS` (`funcaddress_test`), and sequential file I/O
(`fileio_test`, mode 0) through both C generators + the interpreter. **Computed GOTO
(`GotoExpr` via `GOADDRESS`) and AT-write lvalues (`XLONGAT(addr) = <expr>`, a
`BuiltinAssign`) are now locked** by `cemitter_and_cgen_agree_on_computed_goto` /
`_on_builtin_assign`. Adding them surfaced — and a systematic audit of *every*
`LEFT$(s$, N) = "literal"` statement-dispatch arm in cgen.x confirmed — a real bug class:
two arms had an off-by-one length that silently dropped their whole statement. `goto_expr`
compared `LEFT$(s$, 9)` against the 10-char `"goto_expr "` (fixed `1efe782`); `builtin_assign`
compared `LEFT$(s$, 15)` against the 14-char `"builtin_assign"` (fixed `05e9645`, which also
aligned its handler to the Rust CEmitter's `(void)(value)` — a no-op write that still
evaluates the value for side-effects, matching the interpreter). Both byte-neutral on the
corpus, bootstrap fixed point intact; the dispatch-length class is now fully swept.
Embedded-NUL / low-byte strings are covered by CG-BYTESTRING; **true high bytes
(`0x80`–`0xFF`)** by `cemitter_and_cgen_agree_on_high_byte_strings` (`CHR$(200)+CHR$(255)` →
byte-faithful `LEN`/`PRINT`; the interpreter is excluded there — its `Vec<String>` output
sink is UTF-8-lossy for high bytes, so the byte-faithful C backends are the reference).
Remaining blind spots are the **AT-dereference *reads*** (`XLONGAT`/`GIANTAT`/… as rvalues)
and **file mode 2**: the AT reads are interp-divergent *by design* (the interpreter has no
real memory and returns 0, while the C backends dereference real addresses), so a clean
deterministic cross-backend fixture is genuinely hard — tracked, low priority.

Unary `+` (`pos`), `SIZE(TYPE)` (`size_of_type`), and `SIZE(var)` (`size_of`, scalar +
array) — the last IR tokens with no positive-corpus coverage — are now locked by
`cemitter_and_cgen_agree_on_unary_pos_and_size` (all three backends agree). Verifying them
surfaced and **fixed** (`d2dfd6b`) a genuine faithfulness bug: `SIZE(var)` on a scalar
integer returned **4** in the interpreter (logical XLONG size) but **8** in both C backends
(they emitted `sizeof(intptr_t)` storage, not the logical size) — inconsistent with the
32-bit XLONG *arithmetic* the C backends already perform (verified: `2e9 + 2e9` wraps to
`-294967296` in all three) and with `SIZE(XLONG)` = 4. Both backends now emit element-count
`*` logical size (`SIZE(x)` = 4, `SIZE(int a[3])` = 16); `logical` is 4 for Integer, 8 for
Giant/Double/String, matching `SizeOfType` + the interpreter. Bootstrap-safe (cgen.x does
not use `SIZE(var)` — the IR hits were its own dispatch string literals) and byte-neutral on
the corpus/selfhost (0 `SIZE(var)` uses).

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

### CG-SELFHOST-DETERMINISM — three extra `END IF`s made selfhosted compile nondeterministic ✅ done `[2026-09-04]`
Compiling `cgen.x` with the selfhosted `compiler.x` binary was nondeterministic: identical
inputs produced byte-identical output most runs but occasional multi-hundred-MB floods of bare
`end if` lines (or hangs), and downstream core-lib `cc` failures (`xit.c` undeclared
`xb_str_text_s_arr`, `xgr.c`/`xst.c` undeclared `xb_ub_*`, `xit.c`/`xui.c` redefinitions) that
looked like real descriptor-lowering bugs but were flood artifacts — the whole sync suite
(85/85) passes with no lowering change once the flood is gone.
Root cause: three functions in `selfhost/cgen.x` each carried one unmatched `END IF`
(`scan_mixed_byref$`, `scan_dynstr$` — both pre-existing — plus one off-by-one in the new
`scan_attach_groups$` close cascade). The Rust frontend tolerates extras in permissive mode
(verified: Rust-emitted IR is byte-identical before/after), but `compiler.x` counts
`IF`/`END IF` on an `ifStack` with no underflow guard, so each extra `END IF` pops garbage
(ASLR-dependent heap contents) into `ifDepth`; a positive garbage depth makes the `END IF`
handler print millions of closers. Fix: delete the three dead `END IF`s (3-line diff, Rust
IR-neutral by construction). Verified: 5/5 byte-identical self-compiles with zero underflows,
`cgen_x_compiles_core_libs_floor_9_cc_clean` and `cgen_x_compiles_all_demos_cc_clean` green.
Lesson: chase `cc` failures in `cgen.x` output only from a known-deterministic compile —
re-run the self-compile a few times and `cmp` before treating an error as structural.
Follow-up hardening (`compiler.x` `GUARD-UNDERFLOW`): the `END IF` handler now skips the
pop/print when `ifSP = 0` instead of reading `ifStack` out of bounds — byte-identical to the
Rust frontend's permissive skip (verified: guarded-vs-original output `diff`-clean on all of
`cgen.x`, and byte-equal to Rust IR on stray-`END IF` probes), turning any future stray from
intermittent UB into deterministic output. No stderr/diagnostic channel exists in `compiler.x`
(`PRINT` is the IR stream), so detection of future strays stays with the gates, not the guard.

## 5. Verification

```sh
cargo test -p xb-runtime --test cgen_cemitter_sync          # the sync lock
cargo test -p xb-runtime --test cgen_positive_corpus        # cgen.x vs golden
cargo test -p xb-runtime --test cgen_corpus --test cgen_selfhost   # bootstrap
```
