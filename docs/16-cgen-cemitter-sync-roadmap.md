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
`end if` lines (or hangs). Independently reproduced by the 2026-09-04 review panel: the
unguarded `compiler.x` on the pre-fix `cgen.x` emitted 745 MB / 113 M bare `end if` lines in
~18 s before being killed.
Root cause: three functions in `selfhost/cgen.x` each carried one unmatched `END IF` —
`scan_mixed_byref$` and `scan_dynstr$` (blame-confirmed pre-existing: `4e19a4ff` 2026-08-23
and `60a12f3e` 2026-08-22) plus one off-by-one in the new `scan_attach_groups$` close cascade
(`6f16ef2e`). The Rust **parser** unconditionally drops an orphaned `END IF` (the
`starts_end_if` arm in `crates/xb-frontend/src/parser.rs` returns an empty `Compound`; this is
NOT governed by the semantics `permissive` flag, which only relaxes type checking), so the
Rust-emitted IR was byte-identical before and after the deletions (measured: SHA-256
`197c77bf…d992bed` both sides; identity is empirical per site, not "by construction" — the
attach-cascade deletion re-pairs consecutive closers without moving any statement's scope).
`compiler.x` counts `IF`/`END IF` on an `ifStack` with no underflow guard, so each extra
`END IF` popped garbage (ASLR-dependent heap contents) into `ifDepth`; a positive garbage
depth makes the `END IF` handler print millions of closers. Fix: delete the three surplus
closers (3-line diff). Verified: 5/5 byte-identical self-compiles with zero underflows;
`cgen_x_compiles_core_libs_floor_9_cc_clean` and `cgen_x_compiles_all_demos_cc_clean` green.
Attribution correction (panel): the same-session core-lib `cc` failures (`xit.c` undeclared
`xb_str_text_s_arr`, `xgr.c`/`xst.c` undeclared `xb_ub_*`, `xit.c`/`xui.c` redefinitions)
were NOT flood artifacts — the sync suite builds its `cgen` from the Rust `CEmitter` and never
runs `compiler.x`, so the flood cannot reach it. Those failures were resolved by the
descriptor-lowering changes in `9f8817e` (M1-DESCRIPTOR-REDIM), 29 commits earlier.
Lesson: chase `cc` failures in `cgen.x` output only from a known-deterministic compile —
re-run the self-compile a few times and `cmp` before treating an error as structural.
Follow-up hardening (`compiler.x` `GUARD-UNDERFLOW`): the block-`END IF` handler now skips the
pop/print when `ifSP = 0` instead of reading `ifStack` out of bounds — byte-identical to the
Rust parser's orphan drop whenever the stray meets `ifSP = 0` (verified: guarded-vs-original
output `diff`-clean on all of `cgen.x`; byte-equal to Rust IR on stray-`END IF` probes). The
guard covers only that path: the single-line-`IF` closure at the loop head still pops
unconditionally (`IF 1 THEN END IF` reaches `ifSP = -1` and emits one extra `end if`; nested
single-line `IF 1 THEN IF 1 THEN PRINT 1` drops the outer closer — both reproduced, both
pre-existing, neither present in the selfhost corpus), `ifSP` is not reset at `END FUNCTION`,
and `ifStack(64)` has no overflow guard (measured max nesting 20). No stderr/diagnostic
channel exists in `compiler.x` (`PRINT` is the IR stream), and no current gate can detect a
stray that both frontends drop identically (`verify-bootstrap.sh` L118 compares native IR to
Rust IR, which drops the stray too). See the Candidate Adoption Ledger below.
Verification correction (found while re-running the gate for the panel edits): the guard
commit `51e7eb2` changed `compiler.x`'s own IR, so the golden
`fixtures/corpus/v0.1/selfhost/compiler.ir` went stale and `corpus_v0_1_is_valid_and_executable`
failed inside `verify-bootstrap.sh`'s debug-suite step. The commit message's "verify-bootstrap
exit 0" was `tail`'s exit status in a `script | tail; echo $?` pipeline, not the script's — the
run never printed `verify-bootstrap: ok`. Golden regenerated from `xb --emit-ir` (diff is
exactly the guard hunk, precedent `5819d6e`); gate re-run with the script's own exit captured.
Rule: capture gate exit codes with `script > log; echo $?`, never through a pipe.

#### Candidate Adoption Ledger — 2026-09-04 panel (devin/glm-5.2, codex/gpt-5.6-sol, claude/fable-5.1)

| ID | Candidate | Status | Evidence | Next action / trigger |
|---|---|---|---|---|
| P1 | Replace "Rust permissive mode" wording with "unconditional parser orphan-`END IF` drop" (docs/16, `compiler.x` comment) | adopted | `parser.rs` `starts_end_if` arm; `semantics.rs` `permissive` gates type checks only — all 3 lenses | — |
| P2 | Downgrade "cc failures were flood artifacts" to the `9f8817e` attribution | adopted | `NATIVE_CGEN` in `cgen_cemitter_sync.rs` builds via Rust `CEmitter`; `git log -S is_array_position` → `9f8817e` | — |
| P3 | Upgrade "pre-existing" from inference to blame-confirmed | adopted | `git blame 3f558ce~1 -L 6149 / -L 8188` | — |
| P4 | Narrow guard claim to the block-`END IF` path; record single-line counterexamples | adopted | `IF 1 THEN END IF` and nested single-line probes reproduced by codex and coordinator | — |
| P5 | Parser-side orphan-`END IF` counter asserted zero over `selfhost/*.x` (named contract: "the bootstrap corpus never exercises either frontend's orphan-drop path") | deferred | 3/3 lenses: no current gate sees a stray both stages drop | implement with the next `selfhost/*.x` structural change or CGEN-FACET-MANIFEST slice |
| P6 | Guard/redesign the single-line-`IF` pop (`singleLineIf` scalar → per-IF state) | deferred | counterexamples above; pre-existing; absent from corpus (gates green) | trigger: any selfhost source adopting single-line `IF … THEN` with nested/empty bodies |
| P7 | Symmetric overflow guard for `ifStack(64)` | deferred | max nesting 20 measured (codex + coordinator scans) | trigger: nesting > 48 appears in any `selfhost/*.x` |
| P8 | "Compile twice, `cmp`" determinism test | rejected | adds a second sample only; P5 is the real guard (claude); codex dissents (wants it alongside probes) | revisit only if P5 is not adopted |

## 5. Verification

```sh
cargo test -p xb-runtime --test cgen_cemitter_sync          # the sync lock
cargo test -p xb-runtime --test cgen_positive_corpus        # cgen.x vs golden
cargo test -p xb-runtime --test cgen_corpus --test cgen_selfhost   # bootstrap
```
