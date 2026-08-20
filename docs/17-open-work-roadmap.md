# 17 — Open-Work Roadmap (everything not done yet)

> Status: living umbrella roadmap. Consolidates known-but-undocumented gaps from
> working notes into one tracked place. Each item marks **provenance**:
> `[verified <session>]` = re-measured with a command shown; `[carried]` =
> from prior working notes, not re-measured here.
>
> Scoped sibling: [16-cgen-cemitter-sync-roadmap.md](16-cgen-cemitter-sync-roadmap.md)
> (the two C generators). Progress narrative: [14-self-hosting-progress.md](14-self-hosting-progress.md).

> Last full re-verification: **2026-08-20**. `cargo test --workspace --exclude
> xb-ide` = **182 passed / 0 failed**. C-backend demo sweep: **113/114 compile,
> 70 byte-faithful, diverge=3** (up from 3→55→97→113). Nineteen CEmitter fix
> batches — each byte-neutral on the self-host + v0.1 corpus or mirrored in
> `cgen.x` (`cgen_cemitter_sync` 5/5 throughout; native bootstrap fixed point
> re-verified) — landed: arity reconciliation, dynamic DIMs, label guards,
> INLINE\$, FOR-var type fix, suffix-aware auto_symbol, identifier sanitization
> (`. \$ ! # @`), param-Dim guard, shared-variable read collection, leading-zero
> literals, `\$\$` GIANT suffix lexing, synthetic `&Func` ids, NUL-safe literals,
> string-scalar UBOUND, unsigned-shift bin helpers (arotate hang),
> array-parameter pointers, `*AT` memory-builtin stubs, composite-member-array
> single-hoist, consistent brace-byte-read naming, GOSUB-function VLAs→heap,
> type-conflict byte-reads, duplicate-param rename only on true C-name collision,
> and dual-use scalar/array names split into scalar + `_arr` array (5 demos:
> gif/gifview/Kittedy/zap/adatadim). The 3 divergers: `aarray`/`aarray_ISNODE`
> (introspect XBasic array metadata via `&array[]`+`XLONGAT`, need the legacy
> array ABI) and `acrc32` (**shift semantics**: cgen's `>>` on `intptr_t` shifts
> logically, but the interp *and* LLVM reference both do i32 *arithmetic* shift —
> `sum >> 1` on the negative `0xEDB88320` sign-extends there; cgen is the odd one
> out, and a fix means emitting i32-arithmetic `>>` mirrored in `cgen.x`). **One**
> compile-fail left: qbtoxb (shared String array + `0s`/`0d` float-hex literals).
> LLVM: 150/0 faithful — **re-verified** after this session's shared-frontend
> changes (feature tests 105/0; a targeted interp differential over
> asystem/aclient/aserver/aback/atrim/atimer/arotate all match, confirming
> `$$`-GIANT lexing / `0s`-`0d` / `byref_symbol` / `for_stmt` / `auto_symbol` /
> `string_byte_read` did not regress it). Bootstrap + `cgen.x` intact.

## 0. Open-gap index (at a glance)

Everything still open, one line each — the "what's left" view. Details live in the
sections below or the named sibling docs; ✅-done items are omitted.
| ~~CGEN-ARRAYS~~ | C backend | ✅ **done** (2026-08-20): auto-vivified array hoisting + dynamic DIMs + undimmed-array folds | — | ✅ |
| ~~CGEN-ARGC~~ | C backend | ✅ **done** (2026-08-20): arity reconciliation (drop extras, pad missing) via `DEFINED_SIGS` | — | ✅ |
| ~~CGEN-BUILTINS~~ | C backend | ✅ **done** (2026-08-20): `INLINE$`, `EOF`, `RIGHT$`/`LEFT$` 1-arg, `STRING$` via `xb_string` | — | ✅ |
| ~~CGEN-AROTATE~~ | C backend | ✅ **done** (2026-08-20): `xb_bin2`/`xb_binb`/`xb_binb2` shifted a signed int (negative rotate results looped forever); unsigned shifts, mirrored in cgen.x | — | ✅ |
| CGEN-REDIM | C backend | `REDIM` emitted as `DIM` (fixed C arrays; no resize-preserving realloc). No demo blocker (adatadim's `SWAP a[],z[]` was a dual-use scalar swap, not growable arrays); needed only for content-preserving REDIM idioms | — (no demo) | feature |
| ~~CGEN-ANY-PARAM~~ | C backend | ✅ **done** (2026-08-20): array params (`UBYTE gif[]`) thread `is_array` → C pointers; `*AT` memory builtins fold to the interp's 0/no-op stub (aquick faithful) | — | ✅ |
| ~~CGEN-COMPOSITE-ARR~~ | C backend | ✅ **done** (2026-08-20): composite member arrays hoist once (dyn pointer wins); scalar+array DIM of one name no longer double-declares (arecord/adata faithful) | — | ✅ |
| CGEN-BYREF-DESC | C backend | array-by-ref has no length/metadata in C: `UBOUND(param[])`, `&array[]`+`XLONGAT` introspection segfault/diverge; needs a `{data,len}` descriptor matching the legacy array ABI | `aarray`/`aarray_ISNODE` | feature |
| CGEN-SHIFT | C backend | `>>` on `intptr_t` shifts logically; interp+LLVM reference do i32 *arithmetic* shift (`0xEDB88320>>1` sign-extends). cgen is the odd one out — emit i32-arithmetic `>>` mirrored in cgen.x (broad; risks `(int32_t)` truncating 64-bit values) | `acrc32` (diverge) | feature |
| ~~CGEN-GOTO-VLA~~ | C backend | ✅ **done** (2026-08-20): sized array DIMs in a GOSUB function now heap-allocate (dyn pointer) instead of stack VLAs, so the GOSUB `goto` no longer bypasses a VLA init (agrids faithful) | — | ✅ |
| ~~CGEN-SCALAR-ARRAY-DUAL~~ | C backend | ✅ **done** (2026-08-20): a name used as both scalar and array now emits two C vars — scalar `xb_var_x` + array `xb_var_x_arr` (mirrors the interp's TypedSlot value/array fields), routed by IR-node kind; array *DIMs* also count as array-context (adatadim's scalar `SWAP a[]`); params excluded (gif/gifview/Kittedy/zap/adatadim faithful) | — | ✅ |
| ~~CGEN-NAME-CONFLICT~~ | C backend | ✅ **partly done** (2026-08-20): aligned string_byte_read + byref_symbol with symbol()'s resolution and fixed duplicate-param rename to fire only on true C-name collision (atools faithful). qbtoxb still fails — its `xbasic$` is a shared *String array* force-dyn'd as `intptr_t*` (should be `char**`) with a byref-arg tangle → folded into CGEN-SHARED-ARR | `qbtoxb` (via CGEN-SHARED-ARR) | ◑ |
| CGEN-SHARED-ARR | C backend | `SHARED`/composite arrays + array-by-ref lower function-local (ary-class programs; agrids now compiles via VLAs→heap) | ary-class AOT | feature |
| LLVM-SHARED-ARR | LLVM | `SHARED` *arrays* still per-function (only `##` scalars are globals now) | `ary`/`ary1` AOT parity | feature |
| LLVM-ANY | LLVM | `ANY array[]` polymorphism (monomorphize or tagged elements) | `aarray_ISNODE` | feature |
| LLVM-BYREF-REDIM | LLVM | REDIM-through-`@array[]` needs `{data,dims}` heap descriptors shared by pointer | general by-ref parity | feature |
| FLOAT-FMT | LLVM + C runtime | shortest-round-trip float print (Ryū-class) vs `snprintf("%g")` | `geo.x` byte-parity | feature |
| LLVM-DEFER | LLVM | content-preserving REDIM, array bounds checks, `PRINT TAB()` line buffer | polish | feature |
| RT-IO-BYTES | interpreter | I/O channels are `Vec<String>`; high-byte PRINT/INPUT lossy at the pipe boundary | byte-faithful piped I/O | refactor |
| RT-XST | interp + backends | real `XstStringToNumber`/`XstQuickSort`/`XstCopyArray` (all zero-stubs today) | `ary`'s `-48000`; **coordinated** change per the §1 lock | feature |
| RT-ATTACH | interpreter | `ATTACH` sub-array aliasing (view binding between array slots) | `ary` TestAryPerformance | feature |
| RT-KERNEL32 | runtime | `GetStdHandle`/`ReadFile`/`WriteFile` + `$$STD_*_HANDLE` | `acgibin` | platform |
| RT-ARGS | runtime | `XstGetCommandLineArguments` | `XBMerge` | platform |
| SHARED-SCALAR | all four paths | `SHARED` *keyword* scalars stay per-function (locked approximation; `##` is the shared form). True legacy semantics = golden + all-backend coordinated change (experiment reverted: rewrites a frozen v0.1 golden) | full legacy `SHARED` fidelity | decision |
| GUI-RUNTIME | platform | Xgr/Xui runtime (winit + softbuffer per docs/12) | 43 GUI demos + 3 init overflows + `DrawScaled` + 19 GTK | platform (large) |
| CG-BYTES | two-C-gen sync | byte-identical emitted C (helper order/param names/formatting) | tightest sync lock (docs/16) | cosmetic |
| CG-BODY-COVER | two-C-gen sync | behavioral coverage of addr-of builtins / file mode 2 | drift blind spot (docs/16) | test gap |
| CHECK-LOC | hygiene | `checks/verify-bootstrap.sh` ≤250-LOC rule has 27 pre-existing violations (not an enforced gate; real gate = the cargo suite) | none | hygiene |
| JIT-X87 | strategic | x87-exact FPU semantics (`iced-x86`/dynasm JIT) | only if compat tests demand | deferred |
| STAGE3-LLVM | strategic | LLVM as the *selfhost* AOT backend (C generator is today's default + bootstrap path) | stage-3 backend split (docs/13) | deferred |
| CRANELIFT | strategic | debug backend | — | deferred |
| ENTRY-SCAFFOLD | runtime | `entry.rs` `XxxMain` callback scaffold is not a generated-program pipeline (docs/14 §4) | exported-callback programs | deferred |

Micro-residual documented in place: `FUNCADDRESS` (the builtin) returns `0` — no corpus
program uses it (§2 RT-FUNCPTR).

### CGEN-SHARED-ARR design — qbtoxb, the last demo compile-fail `[2026-08-20]`

qbtoxb (a 2800-line QuickBASIC→XBasic translator) is the only remaining C
compile-fail (113/114). Its 7 cc errors trace to two variables, both facets of
the SHARED-array feature — a **coordinated** change, not a bounded fix, so it is
scoped here rather than attempted reactively (a wrong move risks the `cgen.x`
byte-identity lock; the payoff is one demo, 113→114):

1. **`xbasic$` — String-array element type under a shared/local/type-conflict
   tangle.** `STRING #xbasic$[]` (a `#`-shared String array, src line 271)
   coexists with a local `DIM xbasic$[#xuline]` (line 1671) *and* an Integer
   `xbasic`. The analyzer lowers the DIM as **`dim xbasic$:integer`** (wrong —
   it is a String array), so the dyn-array hoist emits `intptr_t* xb_var_xbasic_s`
   while element writes use `char** xb_str_xbasic_s` → undeclared-identifier +
   `intptr_t*`-vs-`int` cc errors. Fix needs the analyzer to type a `$`-suffixed
   array as String even under an Integer/shared name conflict, and the emitter to
   carry the String element type through the (possibly shared) array.
2. **`line` — cross-function array flow.** `@line[]` is a by-ref array param of
   `TranslateLine`/`TranslateStatement` (src 105-106), but `line[i]` is also used
   in a function where `line` is neither a param nor a local `DIM` → undeclared
   `xb_var_line`. Fix needs shared/threaded array storage across the call chain
   (the interp shares one slot; the C backend lowers each function's `line`
   independently).

Both reduce to: **`SHARED`/`#`-prefixed and cross-function arrays must lower to
correctly-typed C globals (or a shared `{data,len,elem}` descriptor), not
per-function locals**, with the analyzer's `$`/type-suffix resolution kept
consistent for shared arrays. Prerequisite verified: no `SHARED` *array* appears
in the self-host tools or v0.1 corpus — BUT the corpus *does* use shared string
*scalars* (`##XBDir$`, `##funcTypes$`, `##sharedDecls$`, …) that are currently
typed **Integer** (the embedded `$` is not read as a suffix) and lower to
`intptr_t` globals holding punned `char*` values — and the bootstrap depends on
exactly that lowering. So the fix must type shared string *arrays* as `char**`
**without** changing shared string *scalar* typing, and MUST be gated on
`cgen_cemitter_sync` + the native bootstrap fixed point before landing. This
entanglement (the "bounded" element-type fix touches load-bearing shared-scalar
typing) is why qbtoxb is a deliberate coordinated effort, not a reactive patch.

**Entry point (turnkey).** `xb_frontend::parser::typed_dim_stmt` (parser.rs:318)
is where a `<TYPE> name[]` declaration loses three things at once: it *skips* the
leading element-type keyword (`STRING`), takes a `#`-prefixed `SharedName`
(`#xbasic$`) as the bare name `"xbasic$"` with `suffix: None`, and hardcodes
`shared: false`. So `STRING #xbasic$[]` emits `Dim { name: "xbasic$", suffix:
None, shared: false }` → `dim xbasic$:integer`. The feature therefore starts
there: (a) capture the type keyword / read the SharedName's trailing `$`/`!`/`#`
as the element type, (b) set `shared: true` for a `SharedName`; then (c)
`semantics::dim` routes a shared array to module-shared storage, and (d) the C
emitter lowers shared arrays to correctly-typed globals — each step gated on
`cgen_cemitter_sync` + the bootstrap fixed point, and none allowed to change the
Integer typing of shared string *scalars* (`assignment`-path, not `dim`).

**Progress `[2026-08-20]`.** Facet 1 (element type) **landed** (`b1e0353`):
`Parser::shared_name_suffix` splits a SharedName's embedded `$`/`!`/`#` in both
`dim_stmt` and `typed_dim_stmt`, so `STRING #xbasic$[]` / `DIM #xbasic$[]` now
type uniformly as String (`dim xbasic$:string`) — byte-neutral (interp 183/0,
bootstrap MATCH, sync 5/5, LLVM 105/0), resolving qbtoxb's `xbasic$` element-type
error class. Facet 2 (the harder core) is now mapped to code: `#line` is a
**shared dual-use** slot — a scalar (`XLONG #line`, `#line = n`) AND an array
(`#line[i]`, `REDIM #line[n]`), used cross-function (OutputToken, TranslateLine).
But `#line[i]` lowers to a *local* `array_assign line:integer[…]` (a `Symbol`,
not a `SharedVariable`), because `parser::primary` routes a `SharedName` through
`identifier_expr` — dropping the `#` for array/subscript positions. Facet 2 thus
needs: (i) `primary`/semantics to route a `SharedName` array access/`REDIM` to
shared storage (a `SharedVariable`), not a local `Symbol`; (ii) the emitter to
lower a shared array to a module global (`xb_shared_line_arr` + `xb_ub_…`),
reusing the local dual-use split (scalar `xb_shared_line` + array
`xb_shared_line_arr`) for a shared slot; (iii) `REDIM #line[n]` to resize it.
This is shared-array-globals + shared-dual-use + REDIM combined — a multi-step
feature, each step gated on sync + bootstrap, none touching shared-scalar typing.

**Scope depth (why facet 2 is a major feature, not a parser tweak).** The
`SharedVariable` IR node is *scalar-only*: `semantics::array_access` has no shared
path, so even `##name[i]` lowers to a **local** `ArrayAccess`/`array_assign`
(untested — the corpus has no shared arrays, only shared scalars). Routing the
parser's `SharedName` reads to shared therefore does *not* suffice; facet 2 needs
a new **end-to-end shared-array concept**: parser marks a shared array
access/assign/`REDIM`, semantics tracks shared-array names, a new IR node carries
the shared-array op, and the emitter lowers it to a module global. That threads
all four layers (parser/semantics/IR/emitter) — the reason qbtoxb (one demo,
113→114) is a dedicated feature, not the reactive continuation of facet 1.

## 1. Backends

### LB-STUB — LLVM backend emits a real native object ✅ done
`llvm_backend::LlvmBackend::compile` (feature `llvm`) builds an LLVM module and writes a
real host-target object via `TargetMachine::write_to_memory_buffer(Object)` (was
`ObjectFile::from_bytes(Vec::new())`). A recursive `Emit` translates a growing subset into
a `main` driving `printf` (top-level items + the entry-function body, mirroring
`execute_main`): scalar `DIM`/assignment, **integers** (literals, vars, arithmetic
`+ - * /`, `MOD`/`\`/`<<`/`>>` integer ops, comparisons → XBasic `-1/0`, boolean/logical/`NOT`), **doubles** (literals,
vars, arithmetic, comparison, `%g` print, int→float promotion), **strings** (literals,
vars, `PRINT`), **`IF`/`WHILE`/`FOR`** control flow + **`SELECT CASE`** (equality chain
+ `CASE ELSE`) via basic blocks + **`GOSUB`/`RETURN`/`GOTO`** (top-level, via a
`pc`-dispatch state machine with a return-index stack; nested GOSUB falls back to
linear), **user-defined
functions** (definitions, calls, returns, params, per-function scope; two-pass declare +
emit), **N-dim arrays** (`DIM a[d0,d1,…]` → `calloc`'d row-major heap buffer with a
per-dimension count shape; `a[i,j,…]` read/write via a Horner offset mirroring
builtins** (int/float abs via select). **Byte-strings**: a string value is a `ptr` to
its bytes with the `i64` length in an 8-byte prefix at `ptr-8` (signatures stay `ptr`),
plus a trailing NUL for C interop. This makes **`CHR$(0)`, embedded, and high bytes**
byte-accurate — **`LEN`** reads the prefix (not `strlen`), **`PRINT`** writes the exact
bytes via a `putchar` loop (not `printf("%s")`, which truncates at NUL), **string
comparison** uses `memcmp` + a length tiebreak (`str_cmp`, matching Rust `Vec<u8>`
ordering), **`CHR$`** is a 1-byte byte-string, **`LEFT$`/`RIGHT$`/`MID$`/concat** build
fresh byte-strings via `str_new`+`memcpy`, and **`STR$`/`HEX$`** copy `snprintf` output
into a byte-string. **`TRIM$`/`LTRIM$`/`RTRIM$`/`UCASE$`/`LCASE$`/`SPACE$`** (loop-based
ASCII scan/fold/`memset`), **`ASC`/`SGN`/`INT`/`FIX`/`MAX`/`MIN`** numeric builtins,
**libc math** (`SQRT`/`SIN`/`COS`/`TAN`/`EXP`/`LOG`/`LOG10`/`ATN`/`ATAN`/`ASIN`/`ACOS`/
`ATAN2`/`SINH`/`COSH`/`TANH`/`CEIL`/`FLOOR`/`ROUND`/`POWER`/`EXP10`/`EXP2` + reciprocal/
inverse `COT`/`SEC`/`CSC`/`ACOT`/`ASEC`/… via get-or-declare `double f(double)`),
**`INSTR`** (2-arg, `strstr`), **`STRING$`**, **`CSIZE`**, **`OCT$`/`OCTO$`/`HEXX$`/
`SIGNED$`/`NULL$`** (radix / signed / NUL-fill), **`LJUST$`/`RJUST$`** (pad, keep over-long)
/ **`CJUST$`** (center, truncates to width) / **`LCLIP$`/`RCLIP$`** (drop n bytes),
**`ROTATEL`/`ROTATER`** (rotate), **`DHIGH`/`DLOW`/`DMAKE`/`SMAKE`/`XMAKE`/`GMAKE`** (float
bit-reinterpret), **`FORMAT$`** (string align `<`/`>`/`|`/`&` + numeric `#`/`.`/`,`/`$`/`*`/
sign patterns, byte-exact) with **`CHR$(c,count)`**, and
**`PRINT` comma/semicolon separators** (comma→tab, semicolon→none; one line per `PRINT`,
matching `exec_print`). All
string/array semantics parity-checked vs
`xb --run`. Still deferred (incremental; C backend stays the full AOT path):
content-preserving `REDIM` / array bounds checks, float `STR$` + `VAL` (Rust float-fmt /
strict `i32::parse` ≠ `printf`/`strtol`), `PRINT TAB()` column padding (needs a line
buffer). Proven end-to-end (compile → `cc` link →
run): `hello`; `2*3+1`→`7`; `FOR` sum 1..3 + `IF`→`6`,`big`; `10.0/4.0`→`2.5`;
`Square(5)`→`25`; `a[2]=a[0]+a[1]`→`30`; `DIM m[2,3]` row-major → `5/9/7`;
`FOR i=0 TO UBOUND(a)` → `a[4]=16`; `LEN("hello")`→`5`, `ABS(0-7)`→`7`;
`IF n$="yes"`→`match`; `CHR$(65)`→`A`; `LEFT$/RIGHT$/MID$("hello world")`;
`"n="+STR$(42)`→`n=42`. Locked by feature-gated `lib.rs::tests::{llvm_backend_emits_runnable_object,
llvm_backend_compiles_integer_arithmetic, llvm_backend_compiles_control_flow,
llvm_backend_compiles_float_arithmetic, llvm_backend_compiles_user_function_call,
llvm_backend_compiles_array_indexing, llvm_backend_compiles_multidim_array,
llvm_backend_compiles_ubound, llvm_backend_compiles_builtins_abs_len,
llvm_backend_compiles_string_comparison, llvm_backend_compiles_chr_builtin,
llvm_backend_compiles_substring_builtins, llvm_backend_compiles_string_build,
llvm_backend_compiles_string_transform_builtins, llvm_backend_compiles_print_separators,
llvm_backend_compiles_select_case, llvm_backend_compiles_gosub_goto,
llvm_backend_nested_gosub_falls_back_to_linear, llvm_backend_compiles_numeric_builtins,
llvm_backend_compiles_integer_ops, llvm_backend_compiles_embedded_nul_strings}`. New error
leaf `CompileError::Llvm` = `XB-B002`. Reference: `docs/12 §3.1`.

### LB-TOOLCHAIN — LLVM feature builds against local LLVM 22 ✅ done
`cargo check/build/test -p xb-compiler --features llvm` now succeeds with
`LLVM_SYS_221_PREFIX=/opt/homebrew/opt/llvm` — the default Homebrew `llvm` is **22.1.8**
(and `llvm@22` is a keg), matching the documented `inkwell` `llvm22-1` pin, so **no version
reversal was needed** (the earlier "only llvm@21 installed" note was stale). The prior
failure was solely the missing `LLVM_SYS_221_PREFIX`. The `llvm` feature stays off by
default (`DisabledLlvmBackend` → `XB-B001`); the C generator remains the default AOT
backend (docs/13 §Stage 3). To build/test the LLVM path, set that env var.

### LB-CLI — LLVM backend reachable from the CLI ✅ done
`xb --compile <src.x> -o <out> --backend llvm` compiles via the LLVM backend
(native object → `cc` link); `--backend c` (default) uses the reference C generator.
The `llvm` path is behind the `xb-cli` `llvm` feature (`--features llvm`, forwarding
`xb-compiler/llvm`, needs `LLVM_SYS_221_PREFIX`); a default build reports
`XB-B001` (LlvmDisabled) for `--backend llvm`. Locked by
`xb-cli/tests/cli.rs::{cli_compile_llvm_backend_produces_native_executable (feature on),
cli_backend_llvm_errors_when_feature_disabled (feature off)}`.

**Reach `[verified 2026-08-18]`:** a differential sweep (LLVM-native vs `xb --run`
over `xbasic-6.4.5/**/*.x`) finds **96 programs** produce **byte-identical** native
output (up from 61 pre-`GOSUB`, 79 pre-FORMAT$, 84 pre-arotate), with **0** invalid-IR compile-fails — every runnable
corpus program now emits valid IR (`module.verify()` gates it). Guarded by
`cli.rs::cli_llvm_matches_interpreter_on_corpus_programs` (curated rich-output subset:
`aarray`/`aloha`/`ahello`); the full 151-file sweep is a manual measurement (too slow
for the suite; counts vary slightly with the interpreter's timeout cutoff).

The **+17** came from landing `GOSUB`/`RETURN`/`GOTO` (additive `pc`-dispatch state
machine — see LB-STUB) plus three latent-bug fixes that `verify()` exposed:
`entry_alloca` (all persistent allocas in the entry block, which dominates the SM's
switch-reached blocks), **per-function `arrays` scoping** (array allocas no longer leak
across functions — had been silently suppressing many array programs), **call-arg
coercion** (`eval_args` coerces args to the callee's param types + reconciles arity —
fixed 6 signature-mismatch compile-fails), and a **FOR back-edge guard** (a `RETURN`/`GOTO`
in a loop body no longer appends an unreachable increment past the terminator — cleared
the last invalid-IR case). Plus `ASC`/`SGN`/`INT`/`FIX`/`MAX`/`MIN`/`HEX$` builtins.

The **+1** to **79** came from the **byte-string representation overhaul** (RT-BYTESTRING
in the LLVM backend): a string value is now a length-prefixed `ptr` (`i64` length at
`ptr-8`, trailing NUL for C interop), so `CHR$(0)`, embedded, and high bytes are
byte-accurate through concat / `LEN` / `PRINT` / comparison (`putchar` loop + `memcmp`
with a length tiebreak), not truncated at the first NUL by `printf("%s")`. Proven
byte-exact (`AB\0CD`) and locked by `llvm_backend_compiles_embedded_nul_strings`.
All **106/106 interpreter-clean programs now compile to byte-faithful native binaries**
(`diverge=0`, `compile-fails=0`, re-measured this session). There are **no remaining
blockers** for interpreter-clean programs — every non-platform-dependent legacy program is
workable *and* AOT-faithful. This session cleared the last of them:
- `atask`, whose earlier "task-runtime" classification was wrong — it never reaches its
  message loop, exiting first via `IFZ assigned THEN RETURN` (a bare `RETURN` → GosubReturn).
  Needed the **GosubReturn-halt** fix (bare `RETURN` with no GOSUB in flight halts the
  function) + the **unary-negation** fix (`count = -1` → `Unary{Neg}`, previously dropped).
- `qbtoxb` (a QuickBASIC→XBasic translator) — the interpreter *itself* errored on it, an
  input-independent bug: `IFZ qfile$` lowers to `qfile$ == 0` (String vs Integer), which
  had no comparison rule. A **string compared to a number now uses its byte length** (so
  `IFZ s$` tests emptiness), fixed in both the interpreter (`compare.rs`) and the LLVM
  backend. It grew the interpreter-clean set from 105 to 106.

The remaining 45 corpus programs (40 interpreter message-loop timeouts + 5 errors —
`DrawScaled`, `acgibin`, `agrids`, `warning`, `xgrids`) are **all platform-dependent**
(GUI/graphics/`Xgr`/`Xui`, CGI), out of the "except platform dependencies" scope; they need
the GUI runtime (`docs/12`), not compiler work.

| Blocker | Programs | Nature |
|---|---|---|
| _(none, non-platform)_ | — | All 106 interpreter-clean programs are byte-faithful. |

The incremental LLVM roadmap is at
**106/106 faithful, 0 compile-fails** (byte-strings resolved RT-BYTESTRING; byte-faithful
PRINT output — high bytes/NULs raw, unblocked `aback`/`acharmap`; `MID$`/`s${n}=v` byte-
assignment (copy-on-write) + auto-vivified-scalar prealloc, unblocked `acharmap`; `$$`
constant evaluation + the `OPEN`/`CLOSE`/`LOF`/`WRITE`/`READ` file runtime, unblocked
`astring`/`arecord`, plus `EOF` (invalid/closed handle → true) unblocking `acrc32`; the
previously-unhandled **`DO…LOOP` codegen** (body-first post-condition loops ran zero times),
unblocked `aprofile`; **`&func()` synthetic ids** (`FuncAddr` = 1-based program order),
unblocked `atimer` (which only prints `&Timer()`, not a clock — the earlier
"nondeterministic" label was wrong); **forward-/GOSUB-`DIM`'d array pre-registration** so
`UBOUND`/element access before the `DIM` reads the real runtime shape (not -1) + null-safe
string-element PRINT, unblocked `asortie` (its earlier "@array REDIM write-back" diagnosis
was wrong — `XstQuickSort` is stubbed in both, so the *unsorted* arrays already match);
**unary negation** (`-1` → `Unary{Neg}`, previously dropped) + **bare-`RETURN` halt**
(GosubReturn with no GOSUB in flight returns from the function), unblocked `atask` (which
`IFZ assigned THEN RETURN`s before its message loop — never the task/GUI runtime it was
mis-classified as needing); **string-vs-number comparison by byte length** (`IFZ s$` →
`s$ == 0` tests emptiness), fixed in interpreter + backend, unblocked `qbtoxb` (an
input-independent interpreter error, not just a backend gap); `FORMAT$` +
`CHR$(c,count)`, `BIN$`/`BINB$`, `0b`/`0o` literals, width-padded `HEXX$`/`HEX$`/`OCTO$`/
`OCT$` (2-arg); unknown-call + undefined-variable zero-defaults; and **nested-GOSUB control
flow** — a GOSUB nested in an `IF`/`FOR`/… now resumes correctly via a per-site *landing
block* through the `pc`-dispatch, with FOR bound/step hoisted to entry allocas so landing
re-entry does not break SSA dominance; unblocked `gif`/`gifview`/`aviewbmp`/`MakeDist`/
`MakeDistLinux`, 2-arg radix unblocked `asystem`/`amodal`, **scalar `@` by-ref** lowers as a
shared pointer param, and **read-only 1-D `@array[]` by-ref** (a `{data, dims}` descriptor)
unblocked `aarray_ISNODE`). **Every interpreter-clean program is now byte-faithful (106/106);
no residual blockers remain.**

### XBSourceLib library reach `[2026-08-19]`

Beyond the 151-program `xbasic-6.4.5` demo corpus, the separate `XBSourceLib/` library
(13 runnable `.x` programs) was re-measured for runtime + LLVM parity: **9/13 byte-faithful**;
the other 4 are blocked by three genuine (non-platform) *features*, not bounded bugs:

- **Float formatting** (`geo.x`): the interpreter prints floats via Rust's `f64::Display`
  (shortest round-trip, decimal — `39.99990409954015`); the LLVM backend uses
  `snprintf("%g")` (6 sig figs — `39.9999`). Byte-exact parity needs a shortest-round-trip
  decimal formatter (Ryū/Grisu-class) in the C runtime; a naïve `%g` retry breaks simple
  values (`30` → `3e+01`). The demo corpus never prints such computed floats, so it is
  unaffected (all 106 already match).
- **Cross-function `SHARED` arrays — interpreter side ✅ done `[2026-08-20]`** (`ary`, `ary1`):
  the `SHARED` *keyword* array declaration now routes to the interpreter's module-shared store
  (commit `ccec0a5`), so `SHARED x[]` propagates across functions; this advanced `ary` past the
  `nameList$` blocker. Only arrays route to shared (scalar `SHARED` stays per-function, so the
  LLVM backend — where scalar `SHARED` is also per-function — stays byte-identical). The backend
  still treats `SHARED` *arrays* as per-function, so `ary` is interpreter-workable but not yet
  AOT-byte-faithful; the only faithful demos using `SHARED` arrays (`CursorEdit`/`Kittedy`)
  print nothing, so `diverge=0` held (verified full differential).
- **Composite-ARRAY by-ref params — ✅ done `[2026-08-20]`**: `pathMember[i].code = c$` on a
  `@`-by-ref composite *array* param now flattens each member as an array (`pathMember.code[]`)
  and lowers to array access, not a scalar byte-index (commit `3649aa8`), clearing the spurious
  `CHR$(String)`.
- **Composite `SHARED` arrays — ✅ done `[2026-08-20]`**: `SHARED <TYPE> var[size]` now
  recognizes the composite type and creates shared, sized member arrays (commit `c818b58`),
  clearing `unknown runtime slot Ary_varData.numElements`.
- **`REDIM`-of-shared arrays — ✅ done `[2026-08-20]`**: a `REDIM` of a `SHARED`-declared array
  (incl. composite `REDIM Ary_varData[m]`) now resizes the module-shared storage instead of
  shadowing it locally (commit `b15004f`; the analyzer tracks `SHARED` array names per function).
  This **completes the SHARED-array feature**: DIM / access / `@`by-ref / REDIM, scalar-member +
  composite, cross-function. Contract-safe (arrays-only, no `SharedVariable`, no golden touch).
- **`ary` `-48000` — definitively the stubbed builtins `[2026-08-20]`**: `ary` blocks on an
  `-48000` index: `Ary_GetCodeBufferIndexCode` hashes `charCode = (c${0} - ASC("0")) * 1000`, and
  on an **empty** `name$`, `c${0}` = 0 → `(0-48)*1000`. Two candidate causes were **tested and
  eliminated** this session — scalar `SHARED` and `REDIM`-of-shared-composite both now work, yet
  ary still hits `-48000` — so the empty `name$` comes from the **stubbed builtins** below
  (`XstStringToNumber` feeds ary's number/name parsing). (The scalar-`SHARED` experiment was
  reverted: it rewrites a frozen v0.1 golden and diverges inkwell without unblocking ary.)
- **Stubbed runtime builtins — `ary`'s remaining blocker** (`ary`/`ary1`): `XstStringToNumber`
  (×15, used by 34 corpus files incl. the faithful demos `aconvert`/`qbtoxb`), `XstQuickSort`
  (×5), `XstCopyArray` hit the generic unknown-call stub (return `0`/`""`). Real implementations
  must land in **both** the interpreter and a backend (per the lock): interp + CEmitter is
  straightforward, but the demos using them are byte-faithful *because* both stub identically, so
  an interp-only impl diverges them — needs the same **gate-backend decision** (C backend primary
  + inkwell deferred). Golden-safe (no v0.1 golden uses `Xst*`).
- **Command-line arguments** (`XBMerge.x`): reads `XstGetCommandLineArguments`; with no args
  the interpreter and backend take different usage-vs-empty paths (borderline platform).

Bootstrap-safe: the self-host toolchain uses none of these (no printed floats, zero composite
params, no `XstGetCommandLineArguments`).

### Interpreter/backend byte-faithful lock — the constraint on all remaining reach `[2026-08-20]`

The 106/106 (and XBSourceLib 9/13) byte-faithful result means the interpreter and the LLVM
backend are **locked together**: they match today partly because they share the *same*
approximations (stubbed `Xst*` builtins, `SHARED`-keyword → per-function local, GUI no-ops).
Consequently there are **no interpreter-only correctness wins left** — improving any such
behavior in the interpreter alone would *diverge* it from the backend and regress the faithful
set. Every remaining non-platform feature (SHARED semantics, real `Xst*` builtins, float
formatting) is therefore a **coordinated interpreter + backend change**, verified against the
full 151-demo differential. (This session's `@array` by-ref was safe precisely because it made
the interpreter *converge* to behavior the backend already had, rather than diverge.)

### Backend feature-sync — cgen demos 3→55, LLVM shared vars `[2026-08-20]`

The three execution paths (interpreter, C generator "cgen", LLVM) were measured for
demo-corpus parity and synced. Empirically the **C generator — the primary/bootstrap
backend — was the *least* capable on the demo corpus**: only **3/151** demos
compiled+ran byte-faithfully (vs LLVM's 150), because cgen lacked several structural
features the interpreter and LLVM already had. Five contract-safe CEmitter fixes —
each a **no-op on the self-host tools + v0.1 corpus**, so `cgen.x` stays byte-identical
and the bootstrap is untouched — raised it to **55/151** (one diverge: `arotate.x`):

- **Unknown-callee stubs (`96ee9e5`)** — a call to a non-builtin, non-user function
  (GUI `Xgr*`/`Xui*`, forward-referenced library funcs like `Howdy`) emitted an
  undeclared `xb_user_<name>`; now yields the zero-default (`""`/`0`, args skipped),
  matching interp (`call.rs`) and LLVM (`lib.rs`).
- **Entry point (`3213d23`)** — `main` now runs `entry_or_first("Main")` (the `Main`
  function, else the first defined function — legacy `Entry`), not only `Main`, so
  Entry-based demos (`aloha`, `ahowdy`) produce output.
- **Function dedup (`e58fc50`)** — XBasic forward declarations lower to a duplicate
  function item; emit each `xb_user_<name>` once (first-wins, matching the
  interpreter's `find_function`) to avoid a C `redefinition`.
- **Scalar hoisting (`6d68db4`)** — the dominant blocker: auto-vivified scalars
  (`FOR i`, `kid`, `text`) have no `Dim`, so cgen emitted undeclared `xb_var_i` /
  `xb_str_text`. `c_emit_hoist` declares every referenced-but-undimensioned scalar
  (excluding params / the return var) at function top, mirroring the interp/LLVM lazy
  alloca (**+47 demos**).
- **Computed-GOTO prologue (`7a0fee9`)** — `GotoExpr`/`GosubReturn` lower to `goto
  *expr`, which C accepts only with an `&&label` present; `c_emit_goto` emits an
  unreachable dummy-label block when a function performs a bare computed goto and
  provides none (excludes `Gosub`/`GosubExpr`, which already emit one).

**LLVM shared variables (`287397a`)** — the LLVM backend silently dropped
`SharedAssignment` (fell through `emit_item`'s `_ => {}`) and read `SharedVariable` as
`None`, so a module-shared `##` scalar written in one function read back as its default
in another. `declare_shared` now creates an LLVM global (`xb_shared_<name>`) per
`SharedAssignment` target; stores/loads mirror the interp's `state.shared` and cgen's
globals. A `##counter`/`##name$` program prints `42`/`hello` identically on interp, C,
and LLVM (was `0`/empty on LLVM). LLVM differential unchanged at **150/150 faithful,
diverge=0**; locked by `llvm_backend_shares_variables_across_functions`.

**Remaining C-backend blockers (the 55→ tail — structural, not correctness):**
undeclared **arrays** (auto-vivified arrays such as `Sub[]` — the array analogue of
scalar hoisting), callback **arg-count** mismatches (a defined function called with
extra args via `funcaddr`), genuinely deferred builtins (`STRING$`→`xb_string`,
`INLINE$`→`xb_inline`, float `STR$`/`VAL`), and one diverge — `arotate.x`: the
generated C **hangs** (6 s timeout, no output) where the interpreter prints its
rotation patterns (re-measured 2026-08-20), i.e. a loop-condition miscompile, not
wrong text. `cgen.x` needs none of the demo-only fixes: it only ever compiles the
all-`Main`, all-dimensioned, computed-goto-free self-host toolchain, where each fix
is a no-op.

Verification each step: full suite **181/0**; `cgen_cemitter_sync` / `bootstrap` /
`cgen_selfhost` / `native_pipeline` / `self_rebuild` green; C + LLVM demo differentials.

### `@array` by-ref — interpreter side ✅ done `[2026-08-20]`
The interpreter now implements array pass-by-reference end-to-end (commit `47a68ac`):

- **Pass-in + write-back** (`call.rs`): a call arg naming an array (directly or via `@`) copies
  the caller's storage (elements + shape) into the callee's param slot; on `@`-writeback the
  callee's (possibly `REDIM`'d) array + dims are copied back, so read-through, element
  write-back, and **REDIM-through-by-ref** all work (locked by 4 interpreter tests).
- **`$`-naming normalization** (`parser`): `@a$[]` (call-site) and `a$[]` (param decl) now bake
  the type suffix into the slot name (like `ArrayRef`/`ArrayAccess`), so the by-ref symbol and
  param bind to the same `a$` slot the callee body uses (integer arrays already matched).

Verified regression-free: full suite 173/0, interp corpus clean=106 (unchanged), LLVM
differential faithful on all array-affected demos, bootstrap `c8d5c7f1` intact.

Remaining `@array` work (not yet done):

- **LLVM backend general `@array` parity.** The backend handles read-only 1-D `@array[]`
  (`aarray_ISNODE`) and array-by-ref params; general REDIM-through-by-ref needs arrays as heap
  descriptors `{data, dims}` shared by pointer (callee resizes the caller's storage, not a copy).
- **`ANY` polymorphism.** `aarray_ISNODE`'s `PrintArray (ANY array[])` is called with a string
  *and* an integer array — one statically-compiled function can't hold both element reps
  (`ptr` vs `i32`); needs monomorphization or a boxed/tagged element.

Bootstrap-safe: the self-host toolchain uses zero array parameters, so none of this perturbs
the byte-exact 3-stage bootstrap fixed point.

### JIT-X87 — FPU-intrinsic JIT not implemented `[verified]`
No JIT crate is present (`iced-x86` / `dynasm` absent from `Cargo.lock`). The
x87 FPU-intrinsic JIT (old `xlib.s` FSIN/FCOS/FPREM/…) is deferred; runtime math
uses plain `f64`. Only pursue if exact x87 compat semantics are ever required
(`docs/12 §3.2`).

## 2. Runtime semantics

### RT-BYTESTRING — byte-accurate strings: value layer ✅ done; I/O channels deferred
`RuntimeValue::String` is now `Vec<u8>` (slot.rs), so `CHR$(>127)` yields a single
byte and `LEN`/`ASC`/`MID$`/`LEFT$`/`RIGHT$`/`INSTR`/`RINSTR`/concat/compare/
`STUFF$`/justify/clip and `{}` brace access are byte-accurate; textual ops (`VAL`,
case, `TRIM$`, `FORMAT$`, numeric parse) use a lossy UTF-8 view (ASCII unchanged).
~85 value sites updated across arith/builtin*/call/data_segment/eval/helpers/
interpreter; `render()` is the lossy display boundary. Locked by
`interpreter.rs::{chr_above_127_is_a_single_byte, string_builtins_are_byte_accurate}`
(full suite 158/0). **Still deferred**: the interpreter's I/O channels remain
`String`-based (`execute_main*` take `output: &mut Vec<String>` / `input:
Vec<String>`, used by ~10 test files + the sync tests), so *faithful high-byte
PRINT/INPUT* needs byte-capable channels — a separate refactor. **Correction**: the
old "msc.x MscEncrypt/MscDecrypt … stray 0x60" repro was mis-attributed to UTF-8
mangling; the msc.x "Decoded as" line is actually blocked by SEL-CASE-TRUE below
(`MscHexStr$`), not by string storage.

### SEL-CASE-TRUE — `SELECT CASE TRUE`/`FALSE`/`ALL` truthiness matching ✅ done
The idiom `SELECT CASE TRUE` with `CASE <boolexpr>:` branches (pervasive across the
legacy libs — xcol/xgr/xin/xst/xui/xma/kernel32) never matched a true branch: the
parser discarded the `TRUE`/`FALSE` keyword and set the selector to
`IntegerLiteral("1")`, then matched by *equality*, but comparisons/`&&` yield `-1`,
so control always fell to `CASE ELSE`. Fixed in `parser_select.rs` by desugaring the
special forms to `IF` (which tests non-zero): `SELECT CASE TRUE` → nested `IF/ELSE`
over each CASE condition (first truthy wins); `FALSE` → `IF NOT cond`; `ALL TRUE`/
`ALL FALSE`/`ALL <expr>` → independent `IF`s (every match runs). Plain `SELECT CASE
<expr>` still lowers to the value/first-match `SelectCase` IR unchanged — the
text-IR goldens and `cgen.x`'s `select_case ` contract are untouched (no
golden-bearing source uses the special forms). Locked by
`interpreter.rs::{select_case_true_matches_first_truthy_branch,
select_case_all_true_runs_every_truthy_branch}`; legacy corpus still 204/204.

### VAR-SUFFIX-COLLISION — numeric `x` and string `x$` sharing a base name ✅ done
`self.symbols` is keyed by BASE name, so a numeric `x` and a string `x$` in one scope
would otherwise fight over slot `x` (declaration order deciding the winner). Fixed with
a per-function pre-scan (`semantics_suffix.rs::scan_body_collisions`, run in
`function()`): a base referenced with both a string and a non-string type is a
collision, and `slot_name` then gives the string variant its `$`-suffixed slot and the
numeric the bare base — applied consistently at reads (`symbol`) and writes
(`assignment`), so it is **order-independent** (numeric-first `c = 5 : c$ = "F"` and
string-first `c$ = "F" : c = 5` both keep `c` / `c$` distinct). Non-colliding bases
still strip the suffix (goldens / `cgen.x` unchanged; only String/numeric collisions —
absent from every golden source — get the `$`-bearing slot, a C-backend concern of the
CG-BODY-COVER class). Locked by
`interpreter.rs::{numeric_then_string_same_base_name_are_distinct_slots,
string_then_numeric_same_base_name_are_distinct_slots}`.

### GOSUB-SCOPE — `GOSUB` to a local `SUB` shares the caller's scope ✅ done
A `SUB` inside a function (a local subroutine reached by `GOSUB`, classic BASIC) was
lowered as a *separate* nested `function` and run by `gosub` in a fresh scope, so its
mutations were lost (`x = 5 : GOSUB Bump` / `SUB Bump : x = x + 10` printed `5`, not
`15`). Fixed at the **semantic** layer (`semantics_function.rs::inline_gosub_subs`, run
in `function()`): a SUB whose name is a `GOSUB` target (scanning nested SUB bodies too)
is rewritten to inline `Label(name)` + body + bare `RETURN` (→ `GosubReturn`, after a
`RETURN` guard) and analyzed **in the caller's own scope**, so its variables share the
caller's symbol table + collision set; the interpreter's existing shared-scope
`Label`/`GosubReturn` path runs it. (A lowering-only inline — the first attempt — left
the SUB in a separate semantic scope → divergent types/names, i.e. the `ary.x`
`String`/`String` mismatch; the semantic fix resolves that.) Locked by
`interpreter.rs::gosub_to_local_sub_shares_caller_scope`; golden-safe (selfhost has no
SUBs; non-SUB bodies unchanged). Also made `ASC("")` → `0` (legacy) en route.

**msc.x fully closed**: RT-BYTESTRING + SEL-CASE-TRUE + VAR-SUFFIX-COLLISION +
GOSUB-SCOPE together make `msc.x`'s `TestMscHex` round-trip print `Decoded as:
robin@example.com`; locked by `xbsourcelib_run.rs::xbsourcelib_msc_strhex_is_correct`.

### MIG-ARY-REDIM — growable `DIM a[]` + `REDIM` preserving contents ✅ done
XBasic arrays do **not** auto-grow on assignment (an earlier note mis-stated this); they
use `DIM`/`REDIM`, where **`REDIM` resizes preserving existing contents** (grow
default-fills the new tail; shrink truncates), and `DIM a[]` is an *empty growable* array
(`UBOUND` = −1). Both were broken: `REDIM` lowered to a plain `DIM` that replaced the
slot (contents lost), and `DIM a[]` was indistinguishable from a scalar `DIM a`
(→ "not an array"). Fix: carry `is_array` + `redim` on `Statement::Dim`/`CheckedItem::Dim`/
`IrItem::Dim` (parser distinguishes `[]` from scalar; `REDIM` sets `redim`); the
interpreter honors them via `TypedSlot::array_resize` (`Vec::resize`, preserve semantics).
This unblocks the pervasive `REDIM a$[UBOUND(a$[]) + N]` idiom (ary/fgr/xui/msc/XBMerge +
demos adata/aprofile/agrids/CursorEdit). Locked by
`interpreter.rs::{redim_grows_preserving_contents_from_empty_dim,
redim_shrink_truncates_and_preserves_low_indices}`. **Golden-safe**: text-IR emission is
unchanged (`is_array`/`redim` are in-memory flags honored on the `--run` path, which
interprets IR directly; `static_redim_doevents.ir` stays byte-identical), and selfhost
uses no arrays, so the bootstrap fixed point is untouched. Note: the text-IR/C backends
treat `REDIM` as `DIM` (no dynamic resize — C emits fixed stack arrays); the interpreter
is the faithful runtime.

Confirmed spec-correct against `lang.txt:389-392` ("when an array is redimensioned, the
existing contents not in the new (smaller) size are lost, contents in both old and new
size are unchanged, and contents in the new (larger) size only are zeroed") — exactly
`Vec::resize`'s truncate / preserve / default-fill behavior.

### MIG-ARY-MULTIDIM — N-dim indexing ✅ done; `ATTACH` aliasing deferred
**N-dimensional row-major indexing done.** `a[i,j]` previously dropped all but the first
subscript, silently aliasing 2-D cells (`a[1,0]` and `a[1,1]` both hit `a[1]` → printed
`9,9` for distinct writes). Fixed by carrying extra subscripts as `Vec` fields alongside
the first (`Statement::Dim.extra_dims`, `Expression::ArrayAccess.extra_indices`,
`Statement::ArrayAssignment.extra_indices`, mirrored on Checked/IR) and a `TypedSlot`
shape (`dims`) with a Horner row-major `array_offset`; `DIM a[d0,d1,…]` allocates the flat
product and records the shape. **1-D byte-identical** (extras ignored in text-IR/C via
`..`; goldens + bootstrap fixed point unchanged; selfhost uses no arrays). Locked by
`interpreter.rs::two_dim_array_cells_are_distinct` (prints `7,9`).

**Still deferred: `ATTACH`** sub-array aliasing (`ATTACH bufferIndex[charCode,] TO a[]`),
the remaining blocker for `ary.x`'s `TestAryPerformance` (which also needs the 2-D buffer
index + is a 50k-iteration perf test). Real `ATTACH` = a view/alias binding between array
slots — a distinct feature. `ary.x` still parses+lowers (MIG-CORPUS-GATE) and stays out of
the `xbsourcelib_smoke_libs_run_clean` clean-run set.

### RT-KERNEL32 — kernel32/stdio stubs for `acgibin` `[verified 2026-08-17]`
`acgibin.x` needs `GetStdHandle`/`ReadFile`/`WriteFile` and the handle constants
`$$STD_INPUT_HANDLE=-10` / `$$STD_OUTPUT_HANDLE=-11`. Not implemented in the
interpreter runtime.

### CLI-STDIN — `xb --run` reads piped stdin ✅ done
`xb --run <file>` previously took input only from `--with-input <file>` and
ignored piped stdin, so every interactive program (`READLINE$` / `INLINE$`) saw
empty input. `run_path` now reads stdin (via `read_stdin_lines`) when no
`--with-input` is given: a terminal stdin is skipped so no-input/interactive runs
never block, and non-UTF-8 stdin is treated as empty (RT-BYTESTRING).
`printf 'hi\n' | xb --run echo.x` now feeds the program. Locked by
`cli.rs::cli_run_reads_piped_stdin_as_input`.

### RT-FUNCPTR — function-pointer calls (`afuntype`) ✅ done
`afuntype.x` calls through a `FUNCADDR` composite member: `dog.setName = &NameDog()`
then `@dog.setName (@dog, answer$)`. Two bugs made it silently wrong (printed `You claim
 has brown hair.` — empty name): `&NameDog()` **mis-lowered to a direct `call NameDog()`**
(the `&` dropped), and the indirect call had no dispatch + passed `@dog` as one unflattened
integer. Fixed in two sub-steps:
- **Sub-step 1 (`882cb70`)** — `&Func(...)` parses to a new `Expression::FuncAddr(name)`
  threaded through checked/IR/text-IR; the interpreter resolves it to the function's stable
  1-based id (`eval::function_id` walks top-level `IrItem::Function`, since `IrProgram` has
  no `functions` list); the C backend emits a real `((intptr_t)&func)` pointer.
- **Sub-step 2** — `parser.rs::type_stmt` now records `FUNCADDR` members (it only handled
  `Identifier` type-keywords; `FUNCADDR` is a `Keyword`, so `setName` was dropped from the
  DOG layout) and captures the member's `(DOG, STRING)` param signature on
  `TypeMember`/`CompositeMember`. `semantics_expr::call_stmt` derives `param_composites` from
  that signature so `flatten_call_args` flattens `@dog` → `(dog.name, dog.hairColor,
  dog.setName)` byref; and `call.rs` dispatches an unknown callee that is a slot holding a
  positive func-id to `function_name_by_id` → the real function (reusing the direct-call
  frame + byref write-back).

`afuntype` now prints **`You claim Rex has brown hair.`** Locked by
`interpreter.rs::{func_addr_yields_stable_function_id,
funcaddr_member_indirect_call_dispatches_and_writes_back}`. **Golden-safe**: selfhost uses
no `&Func()`/`FUNCADDR`, so text-IR for existing goldens and the bootstrap fixed point are
unchanged. `FUNCADDRESS` (the builtin) still returns `0` — no corpus program uses it; only
`&Func` + member dispatch (the `afuntype` path) is exercised.

### RT-FIXEDSTR — fixed-length string (`STRING*N`) composite members ✅ done
A composite TYPE member declared `STRING*N .m` was silently **dropped from the
layout entirely**: the TYPE-member parser matched only `TYPEKW . name`, and the
`*N` size spec between the keyword and the `.member` broke the match, so `.name` /
`.hairColor` / `STRING*32 .s` never became members and read back as Integer `0`.
Fixed in `parser.rs` (`type_stmt`): skip an optional `*<int>` before the `.`,
record the member with the type keyword's `is_string`, and use `N` as its byte
size. Repro now prints `fixed:hi var:yo` (was `fixed:0 var:yo`). Locked by
`interpreter.rs::fixed_length_string_composite_member_holds_string`. No
golden-bearing source (selfhost, positive corpus) uses `STRING*N` members, so the
bootstrap fixed point is unaffected.

### RT-BYREF — pass-by-reference (`@`) parameter write-back ✅ done
`@x` call arguments now write the callee's final parameter value back into the
caller's lvalue. `CheckedExprKind::ByRef` / `IrExprKind::ByRef` wrap by-ref *call
args only* (rvalue `@x` stays a plain symbol, preserving IR goldens); `call.rs`
records `(param, target)` pairs and copies them back after the call. Threaded
through lowering, interpreter eval, C emit (emits inner value; native C
write-back deferred, untested), and text-IR round-trip. Locked by
`interpreter.rs::by_ref_parameter_writes_back_to_caller`. Foundation for the
composite by-ref params below.

### RT-NESTED-COMPOSITE — nested composite TYPEs + composite params ✅ done
A TYPE member whose type is itself a composite (e.g. `GEO_BINODE` holds two
`GEO_BICOORD`s) flattens **recursively** into leaf struct-of-arrays slots
(`L1.a.x`) — `register_type` / `composite_decl` / `dim` (semantics*.rs), plus a
pre-existing bug where suffix-less non-Integer slots (incl. flat *float* composite
members) were overridden to Integer: dotted member slots now trust their declared
type (`symbol` / `assignment`).

**Composite parameters** (incl. by reference) now work: `Param` carries the
composite type + `@`; `FuncSig.param_composites` records them; `function()`
flattens a composite param into member `CheckedParam`s + member slots;
`flatten_call_args` expands composite call-args (with `@` members via RT-BYREF) to
match. Fixed en route: (a) **multi-variable composite decl** `T a, b` declared
only the first var (`composite_decl_stmt` skipped to line-end) — now one decl per
comma-separated var; (b) **mixed-numeric comparison** `a! = 0` (float vs integer
literal) errored (`compare` lacked Float/Integer arms) — now promotes int→float.

`XBSourceLib/geo/geo.x` runs end to end. Locked by `interpreter.rs`
(`composite_by_ref_parameter_writes_members_back`, `compares_float_to_integer_literal`,
`nested_composite_members_resolve_to_declared_float_type`) and
`xbsourcelib_run.rs::xbsourcelib_geo_runs_via_composite_params`.

## 3. Frontend / migration coverage

### MIG-CORPUS-GATE — legacy parse coverage gated by a test ✅ done
Combined parse coverage is **204/204** (151 `xbasic-6.4.5/*.x` + 13
`XBSourceLib/*.x` + 40 `XBSourceLib` source `.txt`). Now gated by
`crates/xb-compiler/tests/legacy_corpus.rs`
(`legacy_corpus_lowers_to_ir_without_swallow`): it walks both trees, requires
every file to parse+lower (the honest `rc == 0` metric — not "non-empty output",
not a min-IR-line threshold), and flags swallow regressions (a `>20`-source-line
file collapsing to `<=2` IR lines). Floors pin current counts (≥151 / ≥13 / ≥40,
≥204 total); additions must still lower, removals fail the gate.

### MIG-SEMANTICS — run-level fixtures landed for clean libs `[verified 2026-08-17]`
Beyond parse/lower (MIG-CORPUS-GATE), `crates/xb-runtime/tests/xbsourcelib_run.rs`
now runs core libs through the interpreter: `utils/mergeTest01`/`mergeTest02` run to a
clean exit; **`msc.x` round-trips fully** — `MscStrHex$` (string→hex) *and* the
`MscHexStr$` decode line are locked correct (RT-BYTESTRING + SEL-CASE-TRUE +
VAR-SUFFIX-COLLISION + GOSUB-SCOPE together closed it); **`geo.x` runs** end to end via
composite params (RT-NESTED-COMPOSITE). `ary.x` parses+lowers (MIG-CORPUS-GATE) but its
`TestAryPerformance` needs MIG-ARY-MULTIDIM, so it is out of the clean-run smoke set.

### MIG-RUNTIME-SWEEP — legacy runtime coverage measured end to end `[verified 2026-08-17]`
Beyond parse/lower (MIG-CORPUS-GATE, 204/204), the runnable *programs* were run
through the interpreter and classified. Of **130** candidate programs — 114
`demo/*.x` + 3 `helpsrc/help_program/*.x` + 13 `XBSourceLib/*.x` — **84 run to a
clean exit**, **46 are platform/library-blocked** (43 GUI = 40 message-loop
timeouts + 3 GUI-init overflows; 1 Win32 console `acgibin`/RT-KERNEL32; 1 X11/GDI
graphics `DrawScaled`; 1 unlinked Xst std-lib `qbtoxb`/`XstLoadStringArray`), and
**0 fail for a genuine interpreter/language reason**. Libraries are not standalone
programs: `src/shared/*` (6, platform-neutral) and `src/linux/*` (9, the platform
deps themselves) parse+lower but are linked, not run; `demo/gtk/*` (19) are GTK
GUI. Conclusion: **all legacy code that does not depend on platform features (GUI,
Win32/kernel32, X11/GDI, sockets) or on an unlinked standard library is workable**
through the interpreter.

Correctness note (2026-08-18): `afuntype` was the one program that exited cleanly but
printed **wrong** output (empty name — the funcptr call was a silent no-op). RT-FUNCPTR
fixed it (`You claim Rex has brown hair.`), so the non-GUI/non-platform corpus now has
**zero genuine failures and zero known silent-wrong-output bugs**.

## 4. Demos / GUI

### DEMO-RUNTIME — 68/114 demos run clean `[verified 2026-08-17]`
Re-measured with `xb --run` (6 s timeout, `</dev/null`): **68 / 114**
`xbasic-6.4.5/demo/*.x` reach a clean exit; **40** are GUI message-loop timeouts,
**3** are GUI-init stack overflows (`agrids`, `warning`, `xgrids`), and **3** are
platform/library-blocked — `DrawScaled` (`XgrCreateWindow`; div-by-zero from a 0
display size), `acgibin` (RT-KERNEL32), and `qbtoxb` (`XstLoadStringArray`, an Xst
std-lib function not linked into the standalone interpreter). **Zero of the 46
non-clean demos fail for a non-platform, non-library reason.** GUI runtime (winit +
softbuffer GDI-shim, per `docs/12`) is a large separate effort, intentionally
deferred.

Re-measured 2026-08-18 (after the msc-saga + MIG-ARY-REDIM fixes): demo-only is still
**68/114** — the session's runtime gains landed in the *libraries* (`msc`/`geo`/`mergeTest`
now run; the `ary` `REDIM a[UBOUND(a[])+N]` idiom works), not the GUI-heavy demos. The 6
non-timeout errors are all GUI/platform/library: `qbtoxb`/`DrawScaled`/`acgibin`, and
`agrids`/`warning`/`xgrids` now surface as `unknown runtime slot func` (the GUI builtin
`XuiGetDefaultMessageFuncArray(@func[])` never allocates the by-ref array) rather than the
earlier stack overflow. `ary`×2 need MIG-ARY-MULTIDIM. **Still 0 genuine interpreter
failures.**

## 5. Cross-references

- Two-C-generator drift and byte-identity: **16-cgen-cemitter-sync-roadmap.md**.
- Backend rationale / crate survey: **12-rust-llvm-rewrite-survey.md**.
- Stage status and decisions: **13-bootstrap-scaffold.md**, **14-self-hosting-progress.md**.
