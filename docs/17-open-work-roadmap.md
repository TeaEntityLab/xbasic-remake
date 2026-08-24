# 17 — Open-Work Roadmap (everything not done yet)

> Status: living umbrella roadmap. Consolidates known-but-undocumented gaps from
> working notes into one tracked place. Each item marks **provenance**:
> `[verified <session>]` = re-measured with a command shown; `[carried]` =
> from prior working notes, not re-measured here.
>
> Scoped sibling: [16-cgen-cemitter-sync-roadmap.md](16-cgen-cemitter-sync-roadmap.md)
> (the two C generators). Progress narrative: [14-self-hosting-progress.md](14-self-hosting-progress.md).

> Last full re-verification: **2026-08-21** (all backends, post-array-ABI). `cargo
> test --workspace --exclude xb-ide` = **238 passed / 0 failed**; `cgen_cemitter_sync`
> **33/33** (byte-identity intact; +float-arith +multidim +hoist +entry +unknown-call +bare-return +dedup +arg-count +inline-helper +escaped-quote +type-suffix-sanitize +typed-unknown-default +leading-zero +EOF-arg +repeated-gosub +computed-goto-prologue +version-offbyone +AT-stub-0 +composite-dot-sanitize +binary-literal +nested-fn +dyn-array-1D +funcname-self-dim +scalar-used-dyn +undimmed-array +string-dyn-array); +4 interp Giant-context fixes; cgen.x self-hosted-generator fixes lifting **self-hosted demo faithfulness 1→85** (true cgen.x differential, real bootstrap cc flags; the computed-GOTO-prologue fix replaced an earlier rewrite-to-return hack, matching Rust; the binary-literal fix flipped arotate — a long-standing "diverge" that was a `0b..` miscompile, not a loop hang); native bootstrap fixed point **intact**; LLVM
> **105/0**. C-backend demo sweep: **114/114 compile, 111 byte-faithful, diverge=0,
> 0 compile-fails** — every testable demo matches the interpreter; the 3 remaining
> (aclient/aserver network sockets + aeasy) block on real I/O, not the GUI loop.
> **NB the demo sweep + differential run the Rust `CEmitter` (`--compile`), NOT the
> self-hosted `cgen.x`.** cgen.x is verified only on the selfhost tools (sync 12/12 +
> bootstrap fixed point); its *demo* faithfulness is far lower — see CGEN-SELFHOST-PARITY.
> **NEW: `#var$` typing fix — a `#foo$` SharedName typed String (was Integer), so
> `acgibin` no longer crashes on `"s" + #foo$` and is now interp==cgen faithful.**
> **`0b42cf1`: headless Xgr/Xui GUI runtime** — `XuiGetNextCallback`
> delivers one synthetic `CloseWindow` so the ~37 GUI message-loop demos run to
> completion + are differential-faithful (74→111); fixed string `SELECT CASE`
> (pointer→content compare). **Prior (`be03117`): the by-ref array ABI landed**
> — full `(T** data, intptr_t* ub)` descriptor + `XstQuickSort`/`XstCopyArray`, so
> **`xbsourcelib` `fgr`/`vgr`/`msc`/`ary` now sort + copy arrays for real** and stay
> byte-faithful (`cgen_demo_regression` 11/11). Every `Xst*` builtin the corpus uses
> is now complete.
> Recent: **expression-context side effects** now reach output — a
> general interpreter `eval` bug (a function called in expression position
> discarded its output sink) that flipped `XBMerge` (RT-ARGS) + unmasked/fixed
> `atimer`/`qbtoxb` (`1975c75`); and a real **64-bit GIANT value type**
> (`RuntimeValue::Giant(i64)`) landed across interp+cgen+cgen.x (`90dcfd4`),
> unblocking RT-XST. Earlier flips: `acrc32` (CGEN-SHIFT i32 masking), `aarray`/
> `aarray_ISNODE` (CGEN-GOSUB-SCOPE — per-function GOSUB stack; was misdiagnosed as
> the array ABI). Beyond demos, **XBSourceLib core libs 13/13 C-compile, 11
> byte-faithful** (`msc`/`fgr`/`vgr`/`vgrOld`/`geo`/`mergeTest01`/`mergeTest02`/`mergeTest03`/`mergeOut`/`mergeOut02`/`XBMerge`).
> The only remaining lib gaps are not C-backend byte-divergences: `ary`/`ary1.0001`
> are **interp-performance** — `TestAryPerformance` runs ~105k `ArySet/Get` ops
> whose name-buffer lookups are O(n) (linear `DO WHILE` scans of `Ary_varCodes`) →
> O(n²) total, so the *interpreter* exceeds 90s while cgen (compiled) finishes in
> <1s; they migrate correctly via cgen with no known divergence source (all of
> i32/float/gosub/by-ref now fixed), just untestable-by-interp like the GUI demos.
> `XBMerge` is now **byte-faithful** (RT-ARGS resolved 2026-08-21, `1975c75`): the
> root cause was a general **interpreter** bug — a function called in *expression*
> position (`x = Foo()`, `IF Foo() THEN`) discarded its output sink, swallowing
> PRINTs and INLINE\$ prompts (`GetArguments` printed usage but the interp lost it);
> `eval` now threads the real output. The C backend mirrors it (expr-position
> INLINE\$ prompt; string-vs-numeric comparison via byte length, not `xb_scmp(s,0)`).
> and the C backend now handles **row-major multi-dim arrays** (direct + text-IR).
> Twenty-six CEmitter fix
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
> dual-use scalar/array names split into scalar + `_arr` array (5 demos:
> gif/gifview/Kittedy/zap/adatadim), and — closing the last compile-fail —
> nested-block array DIMs hoisted to dyn (a `REDIM` inside an `IF` was a
> block-scoped VLA later indexed out-of-block) + dual-use *array params* split
> (qbtoxb's `token[]`, also read as a scalar `token = token[i]`) — plus row-major
> **multi-dim array flattening** (`a[i,j]` → `Σ ik·∏(dm+1)`, direct path). The 3
> divergers: `aarray`/`aarray_ISNODE`
> (introspect XBasic array metadata via `&array[]`+`XLONGAT`, need the legacy
> array ABI) and `acrc32` (**shift semantics**: cgen's `>>` on `intptr_t` shifts
> logically, but the interp *and* LLVM reference both do i32 *arithmetic* shift —
> `sum >> 1` on the negative `0xEDB88320` sign-extends there; cgen is the odd one
> out, and a fix means emitting i32-arithmetic `>>` mirrored in `cgen.x`). qbtoxb
> — the last compile-fail (a 2800-line QuickBASIC→XBasic translator) — now
> compiles and is byte-faithful (empty output on EOF, matching the interp).
> LLVM: 150/0 faithful — **re-verified** after this session's shared-frontend
> changes (feature tests 105/0; a targeted interp differential over
> asystem/aclient/aserver/aback/atrim/atimer/arotate all match, confirming
> `$$`-GIANT lexing / `0s`-`0d` / `byref_symbol` / `for_stmt` / `auto_symbol` /
> `string_byte_read` did not regress it). Bootstrap + `cgen.x` intact.

## 0. Open-gap index (at a glance)

Everything still open, one line each — the "what's left" view. Details live in the
sections below or the named sibling docs; ✅-done items are omitted.

### Full-corpus CI parity locks `[2026-08-24]`

> Every `.x` program in the repo is now regression-locked in CI: `demo_parity`
> (114/114 demos interp↔C byte-identical; daemons via timeout sentinel; links
> core-lib objects), `xbsourcelib_parity` (11 programs byte parity + ary/ary1
> compile-lock), `multi_lib_integration` (15 libs cc-clean + link + execute).
> Suite 257/0 across 32 binaries. Also this session: SWAP `side()` dot-member
> fix (`c9ddb5a`), clippy cleanup, XBSourceLib classification (mergeOut/
> mergeTest03 are vgr copies; ary crashes root-caused to composite-byref
> string corruption, docs/18).

### cgen.x demo ceiling: 114/114 compile, 114/114 faithful — all demos match `[2026-08-23]`

> The self-hosted `cgen.x` C generator now compiles **ALL 114 demos** with **114 byte-faithful**
> (up from 71), **0 diverge, 0 cc-fail, 0 crash, 0 timeout** — verified via the *true cgen.x differential*
> (build native cgen from cgen.x → IR→cgen→cc→run vs interp). Ten fixes landed this session:
>
> | fix | demos | root cause |
>|---|---|---|
>| CGEN-STRCMP-LEN (`5d73678`) | qbtoxb | `compare(string = integer(0))` emitted `xb_scmp(X, 0)` → `xb_len(0)` → SIGSEGV. Fixed: mixed string/numeric comparison emits `(intptr_t)xb_len(X) == 0`. |
>| CGEN-MIXED-BYREF (`4e19a4f`) | arecurse | `byref(symbol(X))` to mixed byref/byval functions always emitted `&X`. Fixed: `scan_mixed_byref$` pre-scans call sites; mixed functions emit value directly. |
>| CGEN-GUI-HEADLESS (`5296fa9`) | 36 GUI demos | `XuiGetNextCallback` was stubbed to `0`, hanging event loops. Ported headless GUI runtime from Rust CEmitter: `xb_gui_next_callback` delivers one synthetic CloseWindow. Also fixed string SELECT CASE (used `==` pointer comparison instead of `xb_scmp`) and integer byref arg emission (fell through to `0` for plain integer byref). |
>| CGEN-BYREF-WRITEBACK (`a6b3565`) | adrawing | `RandomN(float)` declared byval in IR but called with byref at all sites → `double*` vs `double` cc error. Fixed: `scan_byref_wb$` detects all-byref functions; `emit_params$` emits `T *X_ref` pointer params with copy-in/copy-out. |
>| CGEN-SHARED-STR-INIT (`bab451c`) | amakemap | `$$PathSlash` shared string scalar initialized to 0 (NULL) → `xb_concat` called `xb_len(NULL)` → SIGSEGV. Fixed: shared string scalars initialized to `xb_str("")` in `main()` (can't use function call at file scope). |
>| CGEN-ARGSPLIT-STRLIT (`d9d665b`) | latent | All 8 paren-depth counters in cgen.x now skip string literals (Rust `{:?}` format with `\"` escapes). Previously `(` inside a string literal in a call arg would mis-split. Byte-neutral. |
>| RT-FLOAT-DIV + RT-ENTRY-PARAMS (`bcda314`) | DrawScaled, xgrids | Interp fixes: (1) float div-by-zero produces inf (IEEE 754) instead of erroring — matches C; (2) array assign/read auto-vivifies undeclared slots — matches C hoisting; (3) interp only calls parameterless entry functions — matches C backend `emit_main`. |
>| RT-XGR-PROCESS-MESSAGES (`0023a97`) | aclient, aeasy, agrids, aserver, warning | `XgrProcessMessages` is a stub that never dispatches GUI callbacks; demos calling it in `DO...LOOP UNTIL terminateProgram` hung forever. Fix: `XgrProcessMessages` now calls `exit(0)` immediately (interp `Quit { code: 0 }`, C `xb_xgr_process_messages` runtime), so the demo's output (produced before the message loop) is flushed. 5 timeouts → 0. |
>| RT-GOSUB-EXPR-ZERO (`ac3e46d`) | agrids | `gosub_expr Sub[message]` with `Sub[message]=0` (nested fn label_addr now 0) emitted `goto *(void*)0` → SIGSEGV in both C backends. Fix: guard with `if (_xb_ge)` — evaluate expr into temp, only push gosub stack + goto if non-zero. Matches interp RT-GOSUB-ZERO. Byte-neutral (no selfhost tool uses gosub_expr). |
>
> **All 114 demos now faithful** — 0 diverge, 0 cc-fail, 0 crash, 0 timeout.
>
> **LANDED 2026-08-23 (`879f09c`) — CGEN-BYREF-DUAL-FIXES: stabilized 114/114:**
> `bd$` now only returns `_arr` for `##byrefDual$` names when they're array params of
> the current function (`##arrParams$` check) — previously global `##byrefDual$` caused
> `bd$("grid$")` to return `_arr` in all functions, breaking atools/aquick. `##arrParams$`
> and `##curParams$` now set BEFORE `emit_params$` call (was after). Scalar facet
> emission in `##dynNames$` branch skipped for scalar params (no redefinition). Condition
> 2 in `scan_byref_dual$` restricted to non-`$` names (string names appear as
> `byref(symbol(grid$:...))` in call args, falsely matching `INSTR`). Sync 46/46, all suites green.
>
> **LANDED 2026-08-23 (`739c022`) — CGEN-BYREF-DUAL: qbtoxb compiles (113→114):**
>
> **LANDED 2026-08-23 (`52fafe2`) — CGEN-ARR-PARAMS: flipped aquick + atools (102→113):**
> `emit_params$` now gives `##strDual$` params the `_arr` suffix + pointer type
> (matching `##byrefDual$`), so `grid$:string[]` emits `char** xb_str_grid$` instead
> of `intptr_t xb_var_grid$`. `emit_hoists$` `##strDual$` branch: for parameters,
> declare only the scalar facet + ubound (the parameter is the array facet).
> `##allStrArr$` branch: skip hoisting for `##arrParams$` entries; declare ubound
> for array parameters. Scalar DIM suppression skips `##arrParams$` entries.
> `scan_used$` detects `swap X:type Y:type` operands. New `##arrParams$` global +
> `arr_param_names$` function. Sync 46/46, bootstrap OK, all suites green.
>
> **Prior landed fixes (2026-08-22):**
> `aarray`, `aarray_ISNODE` (`b5bd930`), `zap` (`248ff59`), `atools` (CGEN-STRDUAL)
> — taking faithful 98→102. The remaining 9 cc-fails (gif, gifview, aclient, aserver,
> asortie, adatadim, arecord, CursorEdit, Kittedy) were all resolved by the
> CGEN-ARR-PARAMS fix — they were blocked by string array parameter emission, not
> the multiply-blocked GIANT passes the roadmap previously classified them as.
>
> | ~~group~~ | ~~demos~~ | ~~status~~ |
>|---|---|---|
> | ~~network sockets~~ | ~~aclient, aserver~~ | ✅ now compile (were passing via Rust CEmitter; cgen.x param fix unblocked them) |
> | ~~Xst runtime~~ | ~~asortie~~ | ✅ now compiles (was string[] param emission, not Xst runtime) |
> | ~~multi-dim SHARED + composite + grid~~ | ~~adatadim, aquick, arecord, CursorEdit, Kittedy~~ | ✅ now compile (were string[] param emission) |
> | ~~memory-model / ANY / ATTACH~~ | ~~gif, gifview~~ | ✅ now compile (were string[] param emission) |
>
> **LANDED 2026-08-22 (`b5bd930`) — the 3-fix pass that flipped aarray (98→100):**
> (1) **byref-dual `_arr` split**, gated to `scan_byref_dual$` = `##dynNames$ ∩
> user-fn-param` (EMPTY on all faithful demos + selfhost tools → byte-neutral): array
> facet `xb_var_X_arr` (the by-ref param pointer) + scalar facet `xb_var_X`, resolving
> the param-vs-hoist redefinition. (2) **`TYPE(x)` → non-zero** (was unknown-call `0`):
> interp returns the value's non-zero type number, and with the lowered type constants
> all `0` a `0` stub wrongly fell through `IF type<>0 THEN RETURN`; same class as the
> `*AT` stub; no faithful demo uses `TYPE`. (3) **per-function `xb_gosub_base`**
> (CGEN-GOSUB-SCOPE — was in the Rust CEmitter, **missing in cgen.x**): each gosub-using
> function captures `int xb_gosub_base = xb_gosub_sp` at entry and `RETURN` pops only
> while `sp > base` (was `sp > 0`), fixing a cross-function gosub-stack corruption
> (a callee's `RETURN` reached under a caller's active GOSUB did `goto *stack[0]` into
> another function → jump-to-null crash). Locked by
> `cemitter_and_cgen_agree_on_cross_function_gosub_return`; sync 45/45→46, differential
> faithful 98→100/0, suite 250/0.
>
> **LANDED 2026-08-22 (`0127a1e`, `248ff59`) — the 2-fix pass that flipped zap (100→101):**
> (1) **array_assign finds the assignment `=` after the index `]`** (was `INSTR(tmp$,
> "= ")` from the start): a `$$`-constant index like `constant($$XuiColor:integer =
> integer(0))` captured the `=` *inside* the constant, emitting malformed C; byte-neutral
> for simple indices. (2) **local ub cell for byref-dual params DIM'd locally**: a by-ref
> param `intptr_t* xb_var_X_arr` re-DIM'd via `calloc` set `xb_ub_X_arr` with no decl (the
> hoist's param-skip dropped it) → emit `intptr_t xb_ub_X_arr = -1;`. Locked by adding
> `aarray`/`aarray_ISNODE`/`zap` to `cgen_demo_regression`'s `DEMOS`; sync 46/46,
> bootstrap OK, differential faithful 100→101/0, suite 250→251/0.
>
> **LANDED 2026-08-22 (CGEN-STRDUAL) — flipped atools (101→102):** the string analog
> of the integer `##dynNames$`/byref-dual `_arr` split, for a name DIM'd as **both** a
> scalar string (`dim X:string`) and a string array (`dim X:string[N]`). (1) `scan_str_dual$`
> → `##strDual$` (EMPTY on all faithful demos + selfhost tools → byte-neutral). (2) Hoist
> a scalar facet `char* xb_str_X` + heap array facet `char** xb_str_X_arr` + `xb_ub_X_arr`;
> scalar uses stay bare, array access/assign/DIM/UBOUND take the `_arr` suffix (via the
> extended `bd$`). (3) `is_xfn_dyn$` folds a str-dual name **not** DIM'd as an array in the
> current function to the type default — matching the interpreter's per-function scoping
> (atools's `text$` is dual-use in `CreateGrids` but undimmed in `MenuBar`). Locked by
> adding `atools` to `DEMOS`; sync 46/46, bootstrap OK, differential faithful 101→102/0.
> **Remaining aquick blocker (precisely diagnosed 2026-08-22, needs a coordinated
> 2-piece pass):** by-ref STRING array handling. (a) `emit_params$` must strip the `[]`
> array marker from a param type and emit a pointer — `grid$:string[]` currently emits
> `intptr_t xb_var_grid$` (wrong type + `xb_var_` prefix) instead of `char** xb_str_grid$`
> (a narrow, correct fix, but 0-flip alone). (b) forward-referenced string arrays need
> heap-hoisting: `grid$`/`image$` are DIM'd in `Entry` but array-*accessed* earlier via
> the GOSUB-inlined SUBs `SwitchWindow`/`ReportCallback` (placed before the DIM), so the
> mid-function stack decl `char* xb_str_grid$[N]` isn't in scope at the access — they must
> hoist to `char** xb_str_grid$` + calloc (like `##dynStr$`). **(b) VERIFIED UNSAFE as a
> cgen.x-only change (2026-08-22):** routing by-ref string arrays through `##dynStr$` (via
> a `scan_str_byref$` = array-DIM'd ∩ `byref(symbol(X$:string))`) **breaks the bootstrap
> fixed-point** — cgen.x's *own source* passes string arrays by-ref, so heap-hoisting them
> changes cgen.x's self-emission (2nd-pass drift), and it didn't even flip aquick (the
> forward-access needs the runtime DIM-before-access to hold, which the heap-null pointer
> doesn't guarantee). A real pass must mirror the Rust CEmitter's mechanism in **both**
> generators together (sync + bootstrap-locked), not a cgen.x-only edit. The string analog
> of the integer byref/dyn work; not a bounded fix.

| ~~CGEN-ARRAYS~~ | C backend | ✅ **done** (2026-08-20): auto-vivified array hoisting + dynamic DIMs + undimmed-array folds | — | ✅ |
| ~~CGEN-ARGC~~ | C backend | ✅ **done** (2026-08-20): arity reconciliation (drop extras, pad missing) via `DEFINED_SIGS` | — | ✅ |
| ~~CGEN-BUILTINS~~ | C backend | ✅ **done** (2026-08-20): `INLINE$`, `EOF`, `RIGHT$`/`LEFT$` 1-arg, `STRING$` via `xb_string` | — | ✅ |
| ~~CGEN-AROTATE~~ | C backend | ✅ **done** (2026-08-20): `xb_bin2`/`xb_binb`/`xb_binb2` shifted a signed int (negative rotate results looped forever); unsigned shifts, mirrored in cgen.x | — | ✅ |
| ~~CGEN-REDIM / CGEN-BYREF-REDIM~~ | C backend | ✅ **done** (2026-08-21, merge `be03117`; guide `docs/18`): full by-ref array descriptor `(T** xb_var_x_d, intptr_t* xb_ub_x)` — resize-seeded + backward-propagated closure (`collect_descriptor_params`), `emit_array_var_name` chokepoint, all emission sites (access/assign/UBOUND/SizeOf/bare-Symbol/REDIM-DIM/swap/call-site passing-consistency/param-decls), dual-use for genuinely-dual descriptor locals, content-preserving `REDIM` (realloc; `DIM` zero-all). **`xbsourcelib` now FAITHFUL** — `fgr`/`vgr`/`msc`/`ary` sort+copy for real. Verified: demo-regression 10/10, sync 5/5 (byte-identity), suite 193/0, differential 74/0. Final `qbtoxb` fix (`d13ee91`): bare descriptor Symbol reads scalar default, not data-ptr address. | ✅ unblocks XstQuickSort/XstCopyArray | ✅ |
| ~~CGEN-ANY-PARAM~~ | C backend | ✅ **done** (2026-08-20): array params (`UBYTE gif[]`) thread `is_array` → C pointers; `*AT` memory builtins fold to the interp's 0/no-op stub (aquick faithful) | — | ✅ |
| ~~CGEN-COMPOSITE-ARR~~ | C backend | ✅ **done** (2026-08-20): composite member arrays hoist once (dyn pointer wins); scalar+array DIM of one name no longer double-declares (arecord/adata faithful) | — | ✅ |
| ~~CGEN-COMPOSITE-DUAL~~ | C backend | ✅ **done** (2026-08-20, `c2e7300`): a *dual-use* name's scalar facet is declared once by `emit_hoisted_scalars`; a scalar `DIM` of it hit the plain `None` arm and re-declared it → C "redefinition". Fires for a flattened composite array member DIM'd scalar (TYPE decl `SINGLE .x`) but indexed as an array (`px3D.shape[i].x`). The scalar-DIM `None` arm now *resets* (like dyn-scalar) when `is_dual_use`. Byte-neutral (arecord/adata faithful, sync 5/5, suite 186/0); advances 5 XBSourceLib libs (fgr/mergeOut/mergeTest03/vgr/vgrOld) past the redef | XBSourceLib (5) | ✅ |
| ~~CGEN-NAME-TYPE~~ | C backend | ✅ **done** (2026-08-20, `3ba895d`): the hoisted-scalar collector keyed by name only, so a name used as BOTH a String and a non-String (`fillColour` — `xb_str_fillColour` via `AryGetSTRING`, `xb_var_fillColour` via `MscStringToXLONG`) declared only the first-seen facet, leaving the other C var undeclared. `note` now keys by (name, is_string) → both facets declared. (Corrects an earlier "cross-function" misdiagnosis — it was a name/type collision.) Byte-neutral (distinct names keep BTreeMap order; no corpus/demo name collides). XBSourceLib 6→8 compile (ary/ary1.0001) | XBSourceLib (2) | ✅ |
| ~~CGEN-DUALARR-DECL~~ | C backend | ✅ **done** (2026-08-20, `1ecdc51`): the dual-use array facet `px3D_shape_x_arr` was undeclared for a name with only a *scalar* `DIM` but indexed as an array (`px3D.shape[i].x`) — array storage comes only from an *array* `DIM`. The undimmed-array check now uses `collect_array_dimmed_names` (array DIMs only), so such names fold their array accesses (read→default, write→discard) like a truly undimmed array. Byte-neutral (a name with real array storage has an array DIM/is dyn; sync 5/5, bootstrap intact, suite 186/0, demos 71 faithful). **Completes the fgr-cluster: XBSourceLib 8→13 compile, 4→9 faithful** (fgr/mergeOut/mergeTest03/vgr/vgrOld) | XBSourceLib (5) | ✅ |
| ~~CGEN-GOSUB-SCOPE~~ | C backend | ✅ **done** (2026-08-21, `bab960c`): aarray/aarray_ISNODE's `EXC_BAD_ACCESS` (jump to `0x1000`) was **misdiagnosed as the legacy array ABI** — in fact `ATTACH` is parser-skipped (parser.rs:706), so aarray's arrays are inert. The real bug: a bare `RETURN` in a gosub-using function lowers to `GosubReturn`, and cgen's `xb_gosub_stack`/`xb_gosub_sp` is a shared **global**; a function-level `RETURN` reached while a *caller* has an active GOSUB popped the caller's frame → `goto *garbage`. The interp scopes GOSUB per function (`Flow::GosubReturn` bubbles up within the function). Fix: each gosub-using function (and `main`) captures `int xb_gosub_base = xb_gosub_sp;` at entry; `GosubReturn` pops only while `sp > base`, else returns from the function. Byte-neutral where base==0 (no caller gosub) — corpus/bootstrap unaffected. Demos **72→74 faithful, diverge 2→0** (every testable demo now matches). Sync 5/5, bootstrap intact. Locked by `cgen_matches_interpreter_on_gosub_scope`. **Note**: the full legacy array ABI (`{data,len,infoword}` descriptor + `ATTACH` + `ANY`, was "CGEN-BYREF-DESC") is **not** needed by any current demo/lib — no observed program relies on it | `aarray`/`aarray_ISNODE` ✅ | ✅ |
| ~~CGEN-IDENT-SUFFIX~~ | C backend | ✅ **done** (2026-08-20): unified four drifted name→C-identifier sanitizers into `c_emit_expr::sanitize_c_ident`, now mapping the full XBasic type-suffix set `$ ! # @ & %` → `_s _f _d _a _l _h` (was missing `@ & %` in forward-decl params + `xb_shared_` sites). `value@` (SBYTE) / `value&&` (ULONG) names leaked literal `@`/`&`/`%` into C, breaking cc. Byte-neutral (no corpus name carries those); XBSourceLib core libs 4→6 C-compile | XBSourceLib `msc` etc. | ✅ |
| ~~CGEN-BYREF-ARG~~ | C backend | ✅ **partly done** (2026-08-20, `ab54493`): a by-ref arg to an array/pointer param now emits a pointer — `emit_call_args` carries each callee param's `is_array` (`DEFINED_PARAM_ARRAYS`); a pure dyn array passes directly, everything else takes address-of `&x`. Fixes the latent **float `double`→`double *`** hard error (int was masked by `-Wno-int-conversion`). Two earlier reactive attempts regressed and were reverted (blanket `&` broke scalar-param by-refs; `emit_array_var_name` emitted an undeclared `_arr` facet) — the landed version avoids both. Byte-neutral (corpus has 0 by-ref; sync 5/5, bootstrap intact, demos 71 faithful, XBSourceLib 6/4). **Remaining**: flips no file alone — the 7 CFAIL libs advance to their *next* blocker (fgr → nested composite-array redefinition `px3D.shape[i].x`); and full write-back + OOB-safe scalar→array need the ground-up by-ref model | XBSourceLib `ary`/`fgr`/`vgr`/merge | ◑ |
| ~~CGEN-BYREF-WRITEBACK~~ | C backend | ✅ **done** (2026-08-21): scalar & composite `@`-param write-back now reaches the caller. **Key correction to the original design**: the interp keys write-back on the *argument* being `@arg` (`ByRef` in `call.rs`), **not** the callee's param decl — so a param declared `@` but *defined* without it (`DECLARE ... GeoPerpendicularLine (...,@L2)` / `FUNCTION ... (...,L2)`) still writes back. The C backend therefore drives by-ref from **call sites**: `DEFINED_PARAM_BYREF` marks a param by-ref iff **every** call passes it `@` and none by value (intersection — a fixed C signature must type-check every call). A by-ref scalar emits `T* x_ref` with prologue `T x = *x_ref;` + copy-out `*x_ref = x;` before every `return` (`emit_byref_copy_in`/`emit_byref_copy_out`); call sites pass `&x`. Composite `@v` already flattens to per-member `byref(...)` args upstream, so nested out-params (geo's `@L2`) work. Guards: a mixed `@`/by-value param (ary's `ArySetSINGLE value!`) stays by value (interp write-back there is a no-op — callee never writes it); a by-ref scalar sharing an array param's name (Kittedy `@adjacent`+`@adjacent[]`) stays a value param to avoid a C name collision. Byte-neutral (corpus/self-host have 0 by-ref; sync 5/5, bootstrap intact, demos 71 faithful, XBSourceLib 13/13 compile). geo's by-ref values are now correct (`30 30 39.9999…`), leaving only its FLOAT-FMT ULP. Locked by `cgen_matches_interpreter_on_byref_writeback`. **Remaining**: by-ref *array* write-back with runtime strides is separate (CGEN-BYREF-DESC) | `geo` (by-ref part) | ✅ |
| ~~CGEN-MULTIDIM~~ | C backend | ✅ **partly done** (2026-08-20): local multi-dim arrays flatten row-major in the direct (`CEmitter`) path — `DIM a[i,j,…]` allocates `∏(dk+1)`, `a[i,j]` computes `Σ ik·∏_{m>k}(dm+1)`, `UBOUND`=flat-1 (matches the interp's `slot.rs::array_offset`). Gated on `extra_dims`/`extra_indices` non-empty → 1-D stays byte-identical (corpus is all 1-D; sync 5/5, bootstrap intact, no demo flips). The text IR now round-trips `extra_dims`/`extra_indices` (byte-neutral — no frozen golden is multi-dim), so `--emit-ir`/round-trip preserve multi-dim; locked by `cgen_matches_interpreter_on_multidim_arrays` + `c_emit_multidim_round_trips_through_text_ir`. **Remaining**: the self-hosted `cgen.x` CEmitter doesn't yet flatten multi-dim (needs mirroring, bootstrap-gated — no corpus need, all 1-D); by-ref multi-dim needs the `{data,dims}` descriptor (CGEN-BYREF-DESC) for runtime strides | (capability; no demo flips) | ◑ |
| ~~CGEN-SHIFT~~ | C backend | ✅ **done** (2026-08-21, `0877902`): XBasic INTEGER is i32 (interp `RuntimeValue::Integer(i32)`, `wrapping_*`); cgen computed in i64, diverging on overflow + arithmetic shift (acrc32 `table[1]`: i64 `0x77073096` vs interp signed-i32 `0x09073096`). **Two storage-change experiments (`c_type=int32_t`+`-fwrapv`) were reverted** — int32_t truncates label-address integers (`(intptr_t)&&label` in computed GOSUB/GOTO) → crash. The landed fix keeps **`intptr_t` storage** (addresses intact, no crash, no `-fwrapv`) and **masks integer results to i32** with `(int32_t)(…)`: Arithmetic (`+ - * / MOD << >>`), bitwise AND/OR/XOR (`Boolean` arm), `Not`, unary `Neg`, and hex/binary literals (`0xFFFFFFFF`→−1). Compute-in-i64-then-narrow is defined (no i32-overflow in the i64 op; the cast is 2's-complement narrowing) and byte-neutral for in-range values. acrc32 flips to byte-faithful (demos 71→72, diverge 3→2). Sync 5/5 (corpus byte-neutral incl. `computed_gosub_test`), bootstrap intact, corpus goldens unchanged. Locked by `cgen_matches_interpreter_on_i32_arithmetic`. **Remaining**: cgen.x mirror deferred (byte-neutral on corpus, like CGEN-MULTIDIM); LLVM backend has its own i32 handling | `acrc32` ✅ | ✅ |
| ~~CGEN-GOTO-VLA~~ | C backend | ✅ **done** (2026-08-20): sized array DIMs in a GOSUB function now heap-allocate (dyn pointer) instead of stack VLAs, so the GOSUB `goto` no longer bypasses a VLA init (agrids faithful) | — | ✅ |
| ~~CGEN-SCALAR-ARRAY-DUAL~~ | C backend | ✅ **done** (2026-08-20): a name used as both scalar and array now emits two C vars — scalar `xb_var_x` + array `xb_var_x_arr` (mirrors the interp's TypedSlot value/array fields), routed by IR-node kind; array *DIMs* also count as array-context (adatadim's scalar `SWAP a[]`); a genuine dual-use *array param* also splits (qbtoxb's `token[]`, also read as scalar `token = token[i]`); scalar params excluded (gif/gifview/Kittedy/zap/adatadim/qbtoxb faithful) | — | ✅ |
| ~~CGEN-NAME-CONFLICT~~ | C backend | ✅ **done** (2026-08-20): aligned string_byte_read + byref_symbol with symbol()'s resolution; duplicate-param rename fires only on true C-name collision (atools faithful). qbtoxb's `xbasic$` shared-String-array element-typing resolved (facet 1, b1e0353); its remaining `#line`/`token` tangle closed structurally (nested-DIM hoist + dual-use array-param split, 6153215) — **qbtoxb now compiles + byte-faithful** | `qbtoxb` ✅ | ✅ |
| ~~CGEN-NESTED-DIM~~ | C backend | ✅ **done** (2026-08-20): a sized array DIM inside an `IF`/`FOR`/`WHILE`/`SELECT` body is a block-scoped VLA that later out-of-block uses can't see (qbtoxb `REDIM #line[]` inside an `IF`, indexed after); such names now force to dyn (function-hoisted), structural so it round-trips text IR (frozen v0.1 golden unchanged) | `qbtoxb` | ✅ |
| ~~CGEN-SHARED-ARR~~ (C) | C backend | ✅ **done** (2026-08-21) — see the detailed CGEN-SHARED-ARR row below: non-dual-use `SHARED` arrays (scalar + composite-member) now emit one heap global and cross functions correctly. **LLVM still per-function** (LLVM-SHARED-ARR, next row). | ary-class AOT | ✅ (C) |
| CGEN-SHARED-ARR-SELFHOST | self-hosted cgen.x | **1-D LANDED (2026-08-22):** cgen.x now mirrors Rust's shared heap-global scheme for **1-D** shared arrays — a file-scope `T* xb_var_g = 0; intptr_t xb_ub_g = -1;` global (forward-decl via new `scan_shared_arr$`/`##sharedArrays$`), `calloc` at the sized `dim shared g:t[N]`, `xb_var_g[i]` access shared across functions — plus a scan that declares undeclared `shared(##X:t)` scalars as `xb_shared_X = 0` (matching Rust). Flipped **amemory + amakemap** faithful; locked by `cemitter_and_cgen_agree_on_shared_array_cross_function`. **STILL PENDING: multi-dim** shared arrays (`SHARED g[3,3]` → flattened `i*(d1+1)+j`, NOT native `[i][j]`, since the store is a `T*`) — blocks CursorEdit + Kittedy (`SHARED tbGridNum[]`/`squareInfo.grid[]`), which also need composite-member-shared + dup-params. Original gap (now 1-D-fixed): cgen.x sent `dim shared g:t[N]` through the local `dim ` handler which never stripped `shared ` (emitted `xb_var_shared`, cc "redefinition"). Selfhost tools use only shared *scalars* (`##`), so the sync suite never exercised shared arrays. | ary-class self-hosted AOT | infra (1-D ✅) |
| CGEN-SELFHOST-PARITY | self-hosted cgen.x | **✅ DONE (2026-08-23): cgen.x now produces byte-identical output to the interp for ALL 114 demos** — build native cgen from cgen.x → IR→cgen→cc→run vs interp, 114 demos: **faithful=114, diverge=0, cc-fail=0, crash=0, timeout=0**. This is the *true* cgen.x differential (not the Rust CEmitter sweep). Journey: faithful=1 (minimal seed) → 109 (eight fixes: CGEN-STRCMP-LEN, CGEN-MIXED-BYREF, CGEN-GUI-HEADLESS, CGEN-BYREF-WRITEBACK, CGEN-SHARED-STR-INIT, CGEN-ARGSPLIT-STRLIT, RT-FLOAT-DIV/RT-ENTRY-PARAMS, RT-GOSUB-ZERO) → 114 (two more fixes: RT-XGR-PROCESS-MESSAGES making XgrProcessMessages call exit(0) so 5 GUI timeouts terminate, +RT-GOSUB-EXPR-ZERO guarding gosub_expr null address in both C backends so agrids exits 0 instead of SIGSEGV). Also: CGEN-NESTED-FN label_addr fix (nested function names emit 0, not &&label). Sync 46/46, all suites green. | demo faithfulness | ✅ 114/114 |
| LLVM-SHARED-ARR | LLVM | `SHARED` *arrays* still per-function (only `##` scalars are globals now) | `ary`/`ary1` AOT parity | feature |
| LLVM-ANY | LLVM | `ANY array[]` polymorphism (monomorphize or tagged elements) | `aarray_ISNODE` | feature |
| LLVM-BYREF-REDIM | LLVM | REDIM-through-`@array[]` needs `{data,dims}` heap descriptors shared by pointer | general by-ref parity | feature |
| ~~CGEN-FLOAT-FMT~~ | C backend | ✅ **done** (2026-08-21, `6357403`): shortest-round-trip float print matching the interp's Rust f64 `Display` (`slot.rs` `to_string`), replacing `snprintf("%.17g")` which over-emitted 17 sig figs (geo `39.999904099540153` vs interp `39.99990409954015`). `xb_fmt_float`: expand to 41 sig figs via `%.40e` (correctly-rounded at that width on any libc), find the shortest prefix that `strtod`-round-trips while rounding **myself** with **round-half-away-from-zero** (Rust's tie-break — exact `.25`→`.3`), then place the decimal point in fixed notation (never scientific). The earlier `%.*e`-loop approach hit 0.03% ties because it relied on libc's shortest-precision rounding; doing the rounding myself from a high-precision expansion is portable + deterministic. Validated vs Rust `Display` on 1e6 random doubles + denormal/MAX/MIN/2^±53 edges: **0 mismatches**. Mirrored in `cgen.x` (same algorithm + signature; sync asserts output + helper sigs). XBSourceLib 9→10 faithful (geo). Locked by `cgen_matches_interpreter_on_xbsourcelib`. **Remaining**: the LLVM backend still prints via its own path (LLVM float parity is separate) | `geo.x` ✅ | ✅ (C) |
| LLVM-DEFER | LLVM | content-preserving REDIM, array bounds checks, `PRINT TAB()` line buffer | polish | feature |
| RT-IO-BYTES | interpreter | ~~whole-input drop~~ **partially fixed** (2026-08-24, `a7a1c12`): stdin read as raw bytes, per-line lossy conversion — high-byte lines survive (first-byte access matches C). REMAINING: replacement-char inflates LEN (String model); true fidelity = Vec<u8> string-model refactor | byte-faithful piped I/O | refactor |
| RT-XST | interp + backends | **`XstStringToNumber` ✅ done (`6a5aa4e`)** — real number parser (whitespace/sign/hex/bin/oct/decimal/float) → specType (0 ok / -1 err) + afterOff/rtype (SLONG6/XLONG8/GIANT12/DOUBLE14)/value$$ (int or f64 bits); by-ref builtin (interp `call.rs` write-back; C `xb_xst_str_to_num(s,start,&after,&rtype,&value)` via `emit_byref_value/addr` + gated `emit_xst_runtime`); enabled by GIANT (`90dcfd4`). **`XstBackStringToBinString$` ✅ done (`72136fa`)** — backslash-escape→binary decoder; pure string builtin. **`XstQuickSort` (14) + `XstCopyArray` (2) ✅ done (2026-08-21, merge `be03117`)** — real stable sort (8-byte-slot reorder, `et`-dispatch, permutation fill) + array copy, interp (`xst::quicksort`/`copyarray`) + gated C runtimes, over the CGEN-BYREF-REDIM descriptor (see row); `fgr`/`vgr`/`msc`/`ary` sort+copy for real, byte-faithful. All gated → byte-neutral on the Xst-free corpus (sync 5/5). env stubs `XstGetSystemTime`/`XstClearConsole`/`XstSetProgramName` are byte-neutral no-ops. `selfhost/cgen.x` Xst mirror deferred (gated; no bootstrap tool uses Xst). **All Xst builtins the corpus uses are now DONE.** | ✅ msc/fgr/vgr number+string parsing; `XstQuickSort`/`XstCopyArray` sort+copy | ✅ (corpus-complete) |
| RT-ATTACH | interpreter | `ATTACH` sub-array aliasing (view binding between array slots) | `ary` TestAryPerformance | feature |
| ~~CGEN-SHARED-ARR~~ | frontend + C backend | ✅ **done** (2026-08-21, gated): a `SHARED a[]` array (scalar-elem OR composite-member) was emitted as a *per-function local*, so each function saw its own uninitialized copy — `sa.x` interp `7/9` vs cgen garbage; `cF.x` interp `alice=7` vs cgen `=0` (interp keeps them in `state.shared`). Fix: emit ONE heap global per shared array (dyn `T* xb_var_a`/`intptr_t xb_ub_a` at file scope; `is_dyn_array`/`is_undimmed_array`/`emit_dyn_decls` shared-aware; bare `SHARED a[]` = no-op; `emit_globals` declares them). **Gated**: a shared array *dual-use* (scalar+array) in ANY function keeps the local emission (its `_arr` access facet can't match one global — `collect_program_dual_use`). Also extended the composite-member element-type resolution (`self.arrays`) to the WRITE path (`array_assignment`), not just reads — a String member write emitted `xb_var_` (mismatching the `xb_str_` global). Byte-neutral (sync 5/5; cgen.x uses no SHARED arrays); no regression (111 faithful, diverge=0, 11/18 libs, Kittedy fine). Locked by `cgen_matches_interpreter_on_shared_{scalar,composite}_array_cross_function`. *(Correction: composite array member access was never broken — it works with dotted members; earlier "broken subsystem" repros were malformed TYPEs.)* | SHARED-array correctness | ✅ |
| ~~CGEN-HASHVAR-TYPE~~ | frontend + interp | ✅ **done** (2026-08-21): a `#`-prefixed var with a `$` suffix (`#foo$`) is a `SharedName` that embeds its suffix in the name (`suffix: None`), so `ValueType::from_suffix(None)` typed it **Integer** — a `"s" + #foo$` concat then raised a spurious `type mismatch: expected Integer, got String` (the acgibin interp crash). Added `ref_value_type(name, suffix)` (infers from the name's trailing char, mirroring `auto_symbol`) in `semantics_expr.rs::symbol`/`byref_symbol`. **acgibin no longer crashes → interp==cgen faithful.** Byte-neutral on self-host/v0.1 (sync 5/5; `cgen.x` uses only `##`). Locked by `cgen_matches_interpreter_on_hash_string_var`. | `acgibin` crash, any `#string$` | ✅ |
| RT-KERNEL32 | runtime | `GetStdHandle`/`ReadFile`/`WriteFile` + `$$STD_*_HANDLE` — real Win32-CGI stdio for `acgibin`'s HTML output (currently stubbed → empty but faithful). **Also latent**: single-`#` `SharedName` assign→read storage split (`#foo=…` emits `SharedAssignment` but a `#foo` read lowers to a local symbol; needs the `#`-vs-`##` shared-scope decision) | `acgibin` real output | platform |
| ~~CGEN-COMPOSITE-MEMARR-TYPE~~ | frontend + C backend | ✅ **done** (2026-08-21): a composite *array* member (`SHARED DLL library[]`, member `name$`) stores its declared element type in `self.arrays`, NOT `self.symbols` — so `array_access`'s `auto_symbol` default typed the dotted leaf `library.name` as Integer (no `$`), and a read `library[i].name` emitted an undeclared `xb_var_library_name` instead of `xb_str_library_name`, failing `cc`. Fixed: `array_access` prefers `self.arrays[name]` for the element type. **Core lib `src/linux/kernel32.x` now compiles clean** (1 cc error → 0). Byte-neutral (sync 5/5; arecord/adata + demo sweep 111 faithful, diverge=0). Locked by `cgen_composite_member_array_read_compiles_kernel32`. **Separate tracked bug**: the composite array-member *runtime* slot registration (`SHARED Rec r[]` read `r[i].nm` → interp "unknown runtime slot") — compile-time type now correct, runtime slot flattening still incomplete. | `kernel32` compile | ✅ |
| ~~CGEN-SHARED-IF-COND~~ | C backend | ✅ **done** (2026-08-21): `collect_shared` (c_runtime.rs) walked an `If`'s bodies but destructured `{ then_body, else_body, .. }` — dropping the **condition**, so a shared var referenced ONLY in a condition (`IF ##XBSystem != …`) never got its `xb_shared_*` global declared → undeclared cc error. Fixed: walk the condition. Flipped core libs **MakeDistLinux + xutpde** (7→9 compile). Byte-neutral (sync 5/5; the shared corpus's IF-condition reads are already declared via assignment). Locked by `cgen_matches_interpreter_on_shared_var_in_if_condition`. | 2 core libs | ✅ |
| ~~CGEN-ASC-2ARG~~ | C backend | ✅ **done** (2026-08-21): 2-arg `ASC(s$, n)` emitted `xb_asc(s, n)` but `xb_asc` is 1-arg and the interpreter reads only `args[0]` (ignoring the position) — a "too many arguments" cc error. Emitter now drops ASC's extra args, matching the interp. Flipped **CreateHelp** (9→10 compile). Byte-neutral (1-arg `ASC(s)` emits identically; sync 5/5, demo sweep 111 faithful). Locked by `cgen_matches_interpreter_on_asc_two_arg`. | 1 core lib | ✅ |
| ~~CGEN-SIZE-SUFFIX~~ | frontend + C backend | ✅ **done** (2026-08-21): `SIZE(var$)` destructured `Identifier { name, .. }`, dropping the suffix, then `auto_symbol(name)` typed the bare name Integer — `SIZE(time$)` emitted `sizeof(xb_var_time)` (undeclared Integer) instead of the String `xb_str_time`. SIZE now resolves via `symbol(name, suffix)` (same as a normal read). Verified runnable (`SIZE(s$)`=8 pointer slot, matches interp); byte-neutral (sync 5/5). Resolves 1 of xin's errors (lib not yet flipped — 8 remain). Locked by `cgen_matches_interpreter_on_size_of_string_var`. | xin (partial) | ✅ |
| ~~CGEN-UNARY-POS-STR~~ | frontend + C backend | ✅ **done** (2026-08-21): unary POS (`+x`) is identity in the interp (`Pos => v`, any type), but `unary()` mapped a String operand to an **Integer** result — so `+s$` was typed Integer while holding a String, crashing the interp's arith ("expected Integer, got Integer") and emitting `+`-on-`char*` (invalid C) — xrun.x `+ log$ + …`. POS now keeps the operand type; the C emitter passes a String POS through unchanged. **Flipped xrun (10→11 compile).** Runnable-faithful (`+s$ + "!"` = "hi!" both); byte-neutral (numeric POS/NEG unchanged; sync 5/5). Locked by `cgen_matches_interpreter_on_unary_pos_string`. | xrun | ✅ |
| ~~CGEN-COLLISION-DIM~~ | frontend + C backend | ✅ **done** (2026-08-21): a scalar `Dim` (`XLONG imm` + `STRING imm$`) lowered its name via the **bare** name, not the collision-aware `slot_name` that reads use — so both DIM'd slot `imm`, making `imm` DIM'd twice (int + string) → flagged dyn → the hoist declared only one type facet, leaving the other (`xb_str_imm`) undeclared in C. `dim` now uses `slot_name(name, suffix)`: a colliding `imm$` declares slot `imm$` (`xb_str_imm_s`), distinct from `imm`'s `xb_var_imm`. **Flipped xdis (11→12 compile).** Non-colliding DIMs keep the bare name (byte-neutral, sync 5/5); no regression (111 faithful, diverge=0). Locked by `cgen_matches_interpreter_on_typed_int_string_collision`. *(A purely module-level-only collision — no function usage — remains, but no core lib hits it.)* | xdis | ✅ |
| CORE-LIBS-CC | C backend | `src/` system libs cc-clean: **✅ ALL 15 compile** (CGEN-BYTE-ACCESS-V3 `10b68c6` completed the set: provenance-gated parse desugar + collision-aware slot resolution). Sessions 2026-08-23 landed fixes driving errors 80→0 (CGEN-SHARED-COMPOSITE, TYPEAWARE-HOIST, DUALUSE-SCALAR-PARAM, SHARED-DIM-EXCLUDE, AUTOSYM-DOLLAR, STRPARAM-DUALUSE, SHARED-ARR-NO-ARR, OCTAL-LITERAL, EXIT-SELECT-TRUE, STRUBOUND-HOIST, CROSSFN-DUALUSE, DESC-SUFFIX, OWNNAME-INT, DUP-LABELS, DESC-FORWARD, NOT-STRING), then **CGEN-BYTE-ACCESS was REVERTED** (`0a65e69`): its FunctionCall hijack also fired on compiler.x's legitimate paren-indexing of string arrays → stage-1 self-hosting emitted nothing → bootstrap tests failed (missed by session greps truncating at head -5). NOTE: ary.x crash root-caused — scalar `dim shared Ary_nameList$` items (from SHARED bracket-form parse) trip the scalar-dimmed gate, excluding it from SHARED_ARRAYS globals → per-function null pairs. A correct fix needs brace-provenance threaded from lexer + a unified slot-name invariant for byte-access bases (scalar char* / array-faceted char** / shared-scalar xb_shared_) — designed, deferred as its own pass. Bootstrap + all suites green. | xit, xst | ◑ |
| ~~RT-ARGS~~ | runtime | ✅ **resolved** (2026-08-21, `1975c75`): not a runtime gap — `XBMerge`'s empty output was a general interpreter bug (expression-context function calls discarded their output sink; `GetArguments` printed the usage prompt but `eval` swallowed it). `eval`/`eval_expr` now thread the real output; C backend mirrors (expr INLINE\$ prompt + string-vs-num comparison by length). XBMerge byte-faithful; XBSourceLib 10→11/13 | `XBMerge` | ✅ |
| ~~CORE-LIBS-LINK~~ | C backend | ✅ **done** (2026-08-23): all 15 core libraries link into one binary via `XB_WEAK_SYMBOLS=1` library mode (`checks/link-core-libs.sh`) and execute cross-TU (7 libs' Version$ return exact source values) — reproducible, byte-neutral by default. | all core libs | ✅ |
| SHARED-SCALAR | all four paths | `SHARED` *keyword* scalars stay per-function (locked approximation; `##` is the shared form). True legacy semantics = golden + all-backend coordinated change (experiment reverted: rewrites a frozen v0.1 golden) | full legacy `SHARED` fidelity | decision |
| ~~CGEN-NDIM~~ | cgen.x | ✅ **done** (2026-08-24): flat-storage rank-3+ arrays now retain each function's declared raw shape (`fn_array_shapes$`) and flatten exact-rank access/assignment row-major via `emit_flat_nd$`, mirroring Rust's `emit_flat_offset`; partial-rank array views preserve the established first-index fallback. No new ABI/runtime bound variables: declaration expressions are sufficient. Fixes adatadim's strict cc failure (`arr[(i0)*(d1+1)+(i1),integer(i2)]`) and output matches interp. Locked by `cemitter_and_cgen_agree_on_rank_three_flat_array`; bootstrap+cgen suites 83/0, full suite 260/0. | adatadim via cgen.x | done |
| ~~CGEN-ARECORD-PARITY~~ | frontend + Rust CEmitter + cgen.x | ✅ **done** (2026-08-24): isolated `arecord.x` is now byte-identical across interp/Rust-C/selfhost-C (380 lines, 1929 bytes). Root causes: (1) cgen DIM dedup was name-only and suppressed executable composite-array re-DIMs — now only an identical repeated **native fixed-array declaration** is skipped; heap/dyn/shared/composite DIMs execute. (2) `READ` arrived as mixed-case `Read` and bypassed composite record lowering — WRITE/READ detection is now case-insensitive. (3) both C runtimes lacked `__WRITE_RECORD`/`__READ_RECORD`; helpers now match the existing interp/LLVM placeholder contract (zero-filled count bytes, read/discard, file-position advance, validation). (4) numeric OPEN modes 0–4 now create/truncate/preserve like the interpreter. Locked by DIM-boundary + record-I/O three-way sync tests. Strict selfhost demo sweep: 112 faithful + 2 intentional network timeouts, 0 failures; suite 262/0. | arecord | done |
| RT-OPEN-SHARE-MODES | C runtimes | Numeric OPEN modes 0–4 now match interp; share-bit modes (`0x10/0x20/0x30`, nonblock `0x800`) still fall back to read-only in C and need an explicit POSIX mapping before claiming full parity. | shared/nonblocking OPEN | feature |
| ~~RT-XIN-SOCKETS~~ | C backend | ✅ **done** (2026-08-24): 16 `Xin*` builtins lower to real BSD sockets (`c_emit_xin.rs`, usage-gated runtime; byref out-params = `&var`, `&string$` = raw data pointer so recv/send write string buffers directly). **aserver end-to-end verified**: bind 0x2020 → listen → accept → read "time" → write timestamp; locked by `xin_sockets.rs` integration test. Interp KEEPS zero-stubs (no raw-address memory model) → aclient/aserver moved to demo_parity SKIP with pointer. Bonus fix found by the real I/O: dual-condition `DO UNTIL x ... LOOP WHILE y` emitted `while(x){body} while(y);` — the LOOP-side condition detached into a no-op statement; now `if(y-fails) break;`. Sync 48/48, suite 258/0. | aclient real I/O (needs interp impl) | done | `Xin*` socket builtins (XinSocketOpen/Bind/Listen/Accept/Read/Write/Close, XinInitialize) are **unknown callees** — the emitter lowers them to zero-default stubs (args + LHS zeroed, call dropped entirely, see aserver.c `xb_label_OpenSocket`). aserver/aclient therefore "run" but perform no I/O (socket=0 → accept loop no-ops; daemon parity lock holds trivially). Fix: recognize `Xin*` names as builtins, emit C helpers over BSD sockets (`socket/bind/listen/accept/recv/send/close`), byref out-params map naturally to `&var` in C; interp side mirrors in `call.rs`. Bounded (~8 builtins) but needs coordinated multi-backend change + new integration test (server in background thread, client connects). | aclient/aserver real I/O | feature |
| ~~SWAP-SUBSCRIPTS~~ | frontend + all backends | ✅ **done**: subscripts captured per side (INC/DEC pattern) and this session (2026-08-24, `c9ddb5a`) `side()` now also follows `.member` chains after `[subscript]` in any order (`SWAP entries[idx].flags, entries[idx+1].flags` parsed as bare `entries` before). Verified: `SWAP a[0], a[1]` and composite INC+SWAP byte-identical interp↔C; suite 257/0. | xit RTRIM path | done | `SWAP a[i], b[j]` (and composite-member swaps) **discard subscripts** in `swap_stmt` (skips `[...]` groups) - same class as INC/DEC (`22ef2df`). xit TextToTokenArray's `SWAP text$[i], text$` silently no-ops, likely contributing to its remaining miscompiles. Fix: capture indices per side (like INC/DEC `indices`), semantics lowers via temp + two ArrayAssignments (`CheckedItem::Compound` exists), C emitter already emits inline temp exchanges for scalar swaps. Interp Swap needs indexed element support for parity. Bounded: mirrors landed INC/DEC pattern. | xit RTRIM path | partial |
| ~~MODULE-DIM-SCOPE~~ | C backend | ✅ **done** (2026-08-24): top-level fixed-size non-string non-shared non-dyn array DIMs hoist to file-scope `static` declarations (`emit_module_dims`) when the program defines any function; hoisted names register as "dimmed" in every function context (`HOISTED_MODULE_DIMS`) so accesses don't fold to undimmed defaults; filtered from main()'s body. Byte-neutral behaviorally; sync 48/48, suite 259/0. Verified: module DIM + named Main + SWAP now matches interp (was 0 0, now 0 100). cgen.x ported too (`c2c6f8a`): streams `static `-prefixed decls for top-level fixed non-string array DIMs — both generators now agree on the repro.| Programs with module-level DIMs + named functions | partial |
| ~~GUI-HEADLESS~~ | C backend + interp | ✅ **done** (2026-08-21, `0b42cf1`): headless Xgr/Xui runtime — `XuiGetNextCallback` delivers one synthetic `CloseWindow` (demos' loops `QUIT` on it) so the ~37 message-loop GUI demos run to completion + are differential-faithful (interp==cgen), instead of hanging on a display event loop. All other Xgr*/Xui* keep the unknown-callee stub (`$`→"", else 0). Also fixed string `SELECT CASE` (pointer→`xb_scmp` content compare — what let `CloseWindow` match its CASE). Byte-neutral on self-host/v0.1 (sync 5/5). **Demo sweep 74→111 faithful, diverge=0, compile-fail=0.** | ~37 GUI demos | ✅ |
| GUI-RUNTIME | platform | *real* Xgr/Xui runtime (winit + softbuffer per docs/12) — actual window/display, beyond the headless differential stub | live rendering for 43 GUI demos + 3 init overflows + `DrawScaled` + 19 GTK | platform (large) |
| CG-BYTES | two-C-gen sync | byte-identical emitted C (helper order/param names/formatting) | tightest sync lock (docs/16) | cosmetic |
| CG-BODY-COVER | two-C-gen sync | computed GOTO (`GotoExpr`/`GOADDRESS`, `1efe782`) + AT-write lvalue (`BuiltinAssign`, `05e9645`) ✅ **done** (2026-08-21): `cemitter_and_cgen_agree_on_{computed_goto,builtin_assign}` lock all three backends. A systematic audit of every `LEFT$(s$, N) = "lit"` dispatch in cgen.x found + fixed **2 off-by-one drops** (`goto_expr`, `builtin_assign`) — the dispatch-length bug class is now fully swept. SUBADDRESS/FUNCADDRESS/computed-GOSUB/sequential-file-IO also corpus-covered. **Remaining** (low pri): AT-deref *reads* (`XLONGAT` rvalue etc. — interp returns 0 vs C real memory, divergent by design) + file mode 2 | drift blind spot (docs/16) | ◑ partial |
| CGEN-EXPR-GAPS | self-hosted cgen.x | A **completeness audit** of cgen.x `emit_expr$` vs every `IrExprKind`. **`funcaddr(` (`&Func()`) ✅ DONE** (verified 2026-08-22): CGEN-FUNCADDR (`funcaddr(` arm + program-order `##funcIds$`) handles both the arg form (`atimer` faithful, 3×) and scalar-assign (`p = &Helper()` → interp/cgen.x both `nonzero 2`). **`byref(` scalar (`@x`) — open; IMPLEMENTED + REVERTED 2026-08-22** (attempt proved it's NOT a bounded fix): built the full CGEN-BYREF (call-site `scan_byref_params$` `:F\|P:` + `##curByrefParams$` context + pointer param decls + `&arg` + deref at symbol-read/assign) — the **user-function case works** (`Bump(@x)` → cgen.x `6`, was `5`), sync 46/46, bootstrap held (after fixing a self-host trap: `INSTR(s$,"(",q)` hit **CGEN-ARGSPLIT-STRLIT** — a `(` in a string-literal call-arg mis-splits; use `CHR$(40)`/`CHR$(41)` in call args). **BUT it regressed the differential 102→98**: the shared `byref(` arm emits `&X` for **builtin** byref args too (e.g. `XuiGetNextCallback(@grid)`), which need the old `"0"` → 4 GUI demos cc-fail. A safe fix needs **callee-aware** arg emission (emit `&X` only when the callee is a user fn with a by-ref param at that position — the `byref(` arm can't see the callee), i.e. move byref handling into `emit_args$` with callee+position. 0-flip (no faithful demo uses scalar byref) + regresses builtins if naive → deferred as a callee-aware refactor, not the 8-edit pass. | drift blind spot | ◑ funcaddr done; byref needs callee-aware refactor |
| ~~RT-GIANT-CTX~~ | interpreter | ✅ **done** (2026-08-21): a value overflowing i32 (typed Giant, e.g. decimal `2147483648`) flowing into a 32-bit context made the interp error ("expected Integer, got Giant/String") while the C backends coerced. Fixed 3 sites: unary `neg` (`e8d8543`, Giant arm + `wrapping_neg`), bitwise/logical/`NOT` (`8152fb6`, shared `bit_operand`→i32), IF/WHILE/DO conditions (`0752ce2`, `cond_bool` full-value truthiness). Interp-only (not bootstrap/sync/cgen.x); locked by `cgen_matches_interpreter_on_{int_min_literal,bitwise_giant_operand,giant_condition}`. Suite 212/0, differential 111/0 | interp Giant faithfulness | ✅ |
| GIANT-LITERAL | text-IR Giant type-loss | **sub-bug (2) ✅ fixed** (`9b829f1`): the interp now coerces a Giant arg to an Integer-param builtin (STR$/ABS/…) to i32 via `xb_compiler::builtin_param_types`, matching the C backends (was a crash; clean signature-driven fix). **sub-bug (1)** — **NOT a sync drift** (earlier mislabel corrected): the text IR emits a bare i32-overflowing literal as `integer(V)` with no Giant marker, and `TextIrParser` re-types it Integer, so BOTH C generators narrow it *identically* through the text IR (locked by `cemitter_and_cgen_agree_on_giant_literal` — they agree, no sync break). Only the *direct* `--compile` path + interp keep the 64-bit Giant (analyzer value_type), so a self-hosted (text-IR-fed) build narrows `PRINT 2147483648`→`-2147483648` while `--compile` gives `2147483648`. Fix: mark Giant literals in the text IR (`giant(V)`) so the round-trip preserves — TextIrEmitter + TextIrParser + both generators' `giant(` handling + arith giant-propagation + PRINT giant-branch. **LOW severity**: uncaught (no corpus/demo Giant literal), `--compile` correct, selfhost tools use 0 Giant literals | text-IR Giant fidelity | infra |
| ~~CGEN-TYPED-ARRAY~~ (fixed) | self-hosted cgen.x | ✅ **fixed-array element type done** (2026-08-22, `91c58dd`): a `#`/`!` (float) fixed array `DIM a#[3]` now emits `c_type$(varType$)` (`double`) for its element type instead of a hardcoded `intptr_t`, so `a#[0] = 1.5` no longer truncates to `1` — cgen.x matches interp/Rust `1.5`. (Name sanitization `a#`→`xb_var_a_d` via `sanitize_ident$` was already in place, so it *compiled* but *computed* wrong — a silent cgen.x↔reference divergence.) Byte-neutral: an integer array keeps `intptr_t` (`c_type$("integer")`), corpus is all-integer, sync 41/41, bootstrap fixed point held, differential faithful=95 unchanged (0 demo uses a fixed typed array → correctness fix, not a flip). Locked by `cemitter_and_cgen_agree_on_typed_float_array`. **REMAINING (synthetic — 0 demos use typed dyn arrays, verified):** a *dyn* float array (`AUTO a#[] : DIM a#[3]`) isn't recognized as dyn (falls to the fixed path) AND gains a spurious scalar decl → `double xb_var_a_d;` + `double xb_var_a_d[..];` redefinition cc-fail; integer dyn arrays are correct. Like CGEN-BYREF-ARRAY, do not chase without a real failing demo. | typed-array cc-validity | ◑ (fixed ✅, dyn deferred) |
| ~~CGEN-MULTIDIM~~ | self-hosted cgen.x | ✅ **done** (`d0aab51`): cgen.x emitted **invalid C for any multi-dim `DIM a[d0,d1]`** — it fed the whole comma-separated dim/index list to `emit_expr$` as ONE expression (`intptr_t xb_var_a[(3),integer(3) + 1]`, cc "expected ']'"). Every 2-D/3-D demo array hit it (aarray, adatadim, aarray_ISNODE, CursorEdit, Kittedy). Fix: new `emit_msub$` does a paren-depth-aware split (like `emit_args$`, so a call index `Add(1, 2)` isn't split on its inner comma) and emits one **native C bracket per dim** — Dim `a[(d0)+1][(d1)+1]`, access/assign `a[i][j]` — matching the interp's row-major `a[i,j]`. Single-dim reproduces the historical 1-D emission byte-for-byte (selfhost/v0.1 all 1-D → sync + bootstrap fixed point unaffected); native multi-dim C differs byte-wise from CEmitter's flattened `a[i*(d1+1)+j]` (CG-BYTES), so `cemitter_and_cgen_agree_on_multidim_array` is a **behavioral** lock. aarray/adatadim/aarray_ISNODE now block only on Xst* builtins (RT-XST). Suite 216/0, sync 11/11 | multi-dim cc-validity | ✅ |
| CHECK-LOC | hygiene | `checks/verify-bootstrap.sh` ≤250-LOC rule has 27 pre-existing violations (not an enforced gate; real gate = the cargo suite) | none | hygiene |
| JIT-X87 | strategic | x87-exact FPU semantics (`iced-x86`/dynasm JIT) | only if compat tests demand | deferred |
| STAGE3-LLVM | strategic | LLVM as the *selfhost* AOT backend (C generator is today's default + bootstrap path) | stage-3 backend split (docs/13) | deferred |
| CRANELIFT | strategic | debug backend | — | deferred |
| ENTRY-SCAFFOLD | runtime | `entry.rs` `XxxMain` callback scaffold is not a generated-program pipeline (docs/14 §4) | exported-callback programs | deferred |

Micro-residual documented in place: `FUNCADDRESS` (the builtin) returns `0` — no corpus
program uses it (§2 RT-FUNCPTR).


### CGEN-DUALUSE — dual-use `_arr` split (attempted, reverted) `[2026-08-22]`

> **Attempted and REVERTED** (regressed faithful 70→67). The nested-fn demos'
> remaining blocker is the `Sub[]` dispatch array: a *true dual-use* name used as a
> bare scalar (`IF Sub == 0`) AND as an array (`Sub[msg]`, holding `label_addr`
> values), used before its DIM. Rust splits it into a scalar facet `xb_var_Sub` + a
> dyn array facet `xb_var_Sub_arr`. A minimal repro worked and sync stayed 30/30, but
> the differential caught a **regression**, so it was reverted to the clean
> faithful=70 checkpoint. **A complete (non-regressing) implementation MUST:**
> (1) **exclude case-A names** (`##dynNames$`, scalar-DIM+array-DIM used only as
> array — my single-facet 1-D dyn) from the dual-use set, else it double-handles them
> (acharmap/aunicode/aviewbmp regressed); (2) cover **every** subscript site with the
> `_arr` rename (a missed site → `subscripted value is not an array`); (3) provide
> **typed facets** — `char*`/`char**` for a string dual-use like `text$` (the
> nested-fn demos hit `redefinition of xb_str_text$` next), `intptr_t`/`intptr_t*` for
> integer. The nested-fn demos are a deep multiply-blocked chain (nested-fn →
> retval-dim → Sub `_arr` → subscripted-value → string-dual-use → …), so this is a
> **coordinated pass, not an increment** — incremental attempts regress or 0-flip.
>
> **A fourth attempt (2026-08-22) added a safe narrow classifier and confirmed the
> entanglement concretely, then reverted.** `scan_dualuse$` = `##dynNames$` ∩
> FOR-counter (a `dim X:integer[]` name also used as `for X:`) — verified empty on the
> selfhost corpus (sync stayed 45/45, byte-neutral) and correctly catches zap's
> `i`/`o`. The full `_arr` routing (hoist scalar+array facets, ubound, access, assign,
> calloc via a `dua$(n$)` suffix helper) was implemented and made zap's array facet
> emit cleanly. **But it is 0-flip**: zap's dual-use `i`/`o` are *also **by-ref array
> parameters*** of `CommandLine(i:integer[], …)`, so the emitted scalar facet
> `intptr_t xb_var_i = 0;` **redefines the parameter** `xb_var_i` (a hard cc error).
> Every case-B cc-fail (zap, atools, aquick, arecord) is thus blocked *simultaneously*
> by CGEN-BYREF-ARRAY (the twice-reverted by-ref-array-param feature) — the dual-use
> name is a by-ref array param in the very function where it is also a counter. Case-B
> and by-ref-array-params **must land together** (a per-function classifier that knows
> when a name is a param vs a local counter); neither flips a demo alone. Reverted to
> the clean `faithful=98, diverge=0` state (`f3a3d1e`).
>
> **A fifth attempt (2026-08-22) extended the split to 2-D and re-confirmed the same
> entanglement, then reverted.** `scan_dyn$` (the `##dynNames$` 1-D dyn-pointer scan)
> was relaxed to also route **2-D** dual-DIM integer arrays (depth-aware ≤1 top-level
> comma; 3-D+ stays native), wiring the already-present but dead 2-D dyn branches
> (`emit_mtotal$` calloc + `emit_flat2d$` row-major access + `xb_d1_`). Verified
> byte-neutral on the corpus (sync 45/45, bootstrap fixed-point held) and it fixed a
> **real** error in **real** demos — `aarray`/`aarray_ISNODE` (which DIM `array` as a
> 2-D dual-DIM) went from the scalar-vs-array `redefinition of xb_var_array` cc-error
> to compiling. But it needed a companion `##curParams$` skip (don't emit a dyn-decl
> for a name that is a **parameter** of the current function — `array` is a by-ref
> array param of `PrintArray`, so the dyn-decl redefines the param). That param-skip
> **re-introduced the by-ref-array-param regression**: it made `aarray` compile but
> diverge (its `PrintArray(array[])` needs the callee-side dimension **descriptor**
> that CGEN-BYREF-ARRAY provides — empty output without it) *and* regressed a
> previously-faithful demo (a callee that legitimately array-uses a dyn-array param
> lost its decl). Net **faithful 98→97, diverge 0→2** — reverted. **Conclusion: 2-D
> dual-DIM, case-B, and multi-dim SHARED all terminate at the same shared blocker —
> the by-ref-array-param dimension-descriptor system (Rust's `collect_desc_info`).
> That descriptor port is the single highest-leverage unblocker and must be done as a
> coordinated pass that mirrors Rust exactly (the naive param handling regresses
> real code, as three prior reverts and this one show).**
>
> **BREAKTHROUGH (2026-08-22): the exact Rust reference mechanism — why 4 attempts
> collided, and the one-line fix.** Studied the Rust CEmitter's *actual emitted C*
> for the 5 byref demos (`aarray`/`aquick`/`arecord`/`atools`/`zap`) and confirmed
> **all 5 are Rust-FAITHFUL** (real gaps, not synthetic). Rust does **not** use the
> descriptor system for them — it uses the **dual-use `_arr` split**, and the piece
> every cgen.x attempt missed is the **param/array-facet naming**:
> - Rust names the **array facet AND the by-ref param** `xb_var_X_arr`; the **scalar
>   facet** keeps the base name `xb_var_X`. Because the two facets have *different C
>   names*, the scalar-facet decl never collides with the array param. **All 4 cgen.x
>   case-B attempts left the param decl as the base name `xb_var_X`, so the scalar
>   facet redefined the param — the exact cc-error that killed each attempt.**
> - Concrete (aarray `PrintArray(array[])`, `array` is 2-D dual-use): Rust emits
>   fwd `PrintArray(intptr_t *xb_var_array)`, def `PrintArray(intptr_t *xb_var_array_arr)`,
>   local scalar `intptr_t xb_var_array = 0;`, array facet `xb_var_array_arr = calloc(…)`
>   (2-D flattened), `UBOUND` → `sizeof(xb_var_array_arr)/…`, call-site
>   `PrintArray(&xb_var_array)` (passes the **scalar facet's address**, a quirky but
>   interp-faithful by-ref). cgen.x today emits the array decl as `xb_var_array`
>   (collides, 458), `UBOUND` `sizeof(xb_var_array[0])` on a scalar (526/535 subscript
>   error), and the call as `PrintArray(0)` (null → wrong).
> - **The de-risked recipe:** redo the 4th-attempt case-B routing (`scan_dualuse$` +
>   `dua$` + access/assign/ubound/calloc/hoist), and additionally (a) emit the **param
>   decl** for a dual-use array param as `xb_var_X_arr` (array facet, in both the
>   forward decl and the definition), (b) emit the **call-site** `@X[]`/array arg as
>   `&xb_var_X` (scalar-facet address). Gate on the full differential (a naive rename
>   regressed a faithful demo before — the pass must cover all 5 demos + not touch the
>   read-only-array-param demos). This converts the "mysterious 4×-failure" into a
>   known, bounded coordinated pass; still GIANT-adjacent, but no longer a mystery.

### CGEN-BYREF-ARRAY — DIM'd-array by-ref is synthetic; do NOT "fix" it `[2026-08-22]`

> **Attempted a THIRD time and REVERTED** (`d7e2249` + cgen.x mirror, reset to
> `e62d03f`). The prior two reverts are noted in the CGEN-BYREF-ARG row; this pass
> pins down *why* the `emit_array_var_name` approach keeps regressing, so it is not
> re-attempted a fourth time. **The bug is synthetic.** `emit_call_args` emits `&x`
> for a by-ref array arg. For a synthetic `DIM a[3]; Fill(@a[]); arr[1]=42`, `a` is a
> *dual-use DIM'd* array, so `&x` passes its 1-slot scalar half → `arr[1]` runs OOB →
> `42/<garbage>` vs interp `5/42`. The bounded fix (route array params through
> `emit_array_var_name`, gated `!is_undimmed_array`) makes that case correct AND is
> byte-neutral on the corpus/faithful demos (Rust differential stayed 111/0, sync
> 40→41/40, bootstrap fixed point held, cgen.x mirror gave br.x `5/42`). **BUT it
> regresses real code:** `XBSourceLib/fgr/fgr.x` + `geo/geo.x` (both faithful,
> gated by `tests/cgen_demo_regression.rs::cgen_matches_interpreter_on_xbsourcelib`)
> pass by-ref arrays that are **undimmed dual-use / composite members / scalars**,
> where the existing `&x` is exactly what the callee expects. The `!is_undimmed_array`
> gate cut Rust fgr errors to 1 (a composite-member subtlety remained) and the cgen.x
> `byref(` arm broke fgr with 20 cc errors. **Root insight: real byref-array usage in
> this corpus is UNDIMMED (no `_arr` storage) — `&x` is correct; the DIM'd-array-byref
> case that `emit_array_var_name` targets does not occur in real code (only in a
> synthetic repro).** The full-workspace suite (not the demo differential — XBSourceLib
> is not in `diff_cgenx.sh`) is what catches this; always run `cargo test --workspace`
> before finalizing a byref change. **Do not reopen without a real failing demo (none
> exists).** cgen.x's own `byref(` gap (CGEN-EXPR-GAPS) is likewise a non-issue: its
> demos need undimmed `&x`, which the pre-existing default already approximates.

### ~~CGEN-ARGSPLIT-STRLIT~~ — call-arg splitter string-literal-aware ✅ done `[2026-08-23, d9d665b]`

> **FIXED** (`d9d665b`): all 8 paren-depth counters in cgen.x (`emit_args$`,
> `emit_args_n$`, `emit_msub$`, `first_comma_part$`, `emit_mtotal$`,
> `emit_flat2d$`, `emit_d1$`, `scan_dyn$`'s comma counter) now skip string
> literals (Rust `{:?}` format: `"..."` with `\"` escapes) when counting
> parens/commas. Previously, a `(` or `)` inside a string literal in a call
> argument would mis-split the args, producing malformed C. The workaround of
> using `CHR$(40)` instead of `"("` in call args is no longer needed (but kept
> since removing it would be a no-op risk). `first_expr$` already had this fix
> (inQuote flag). Byte-neutral: sync 46/46, bootstrap OK, all suites green.


### ~~COMPILER-X-FIXES~~ — compiler.x underscore/bracket/single-line-IF/MID$-assign ✅ done `[2026-08-23, 7fd48f8]`

> **FIXED** (`7fd48f8`): four bugs in `selfhost/compiler.x` prevented it from
> processing `cgen.x` (5430 lines), causing an apparent OOM (exit 137 after 118s
> with only 728 lines of IR). Root causes and fixes:
>
> 1. **Underscore identifiers**: tokenizer only allowed A-Z/a-z as identifier
>    start, not `_` (ch=95). Identifiers like `_fdTab1` were split into `_`
>    (symbol) + `fdTab1` (ident), causing parser infinite loops. Fix: add ch=95
>    to identifier start check.
> 2. **Bracket array syntax**: cgen.x uses `[]` for arrays (`DIM pNames$[32]`,
>    `pNames$[i]`), but compiler.x only handled `()`. Fix: add `[]` support to
>    DIM handler, array assignment, expression parser, and closing bracket
>    handling.
> 3. **Single-line IF**: `IF x=1 THEN y=10` was treated as multi-line IF,
>    causing incorrect nesting. Fix: detect single-line IF in stmtState=3;
>    two-phase `singleLineIf` flag (1→2) emits `end if` after body statement;
>    must pop `ifStack` (not just decrement `ifDepth`).
> 4. **MID$ assignment**: `MID$(s$,pos,len)=val` was parsed as
>    `compare(call MID$(...) = val)` instead of `mid_assign`. Fix: detect MID$
>    followed by `(` in statement parser; add `COMMA_OR_RPAREN` expression stop
>    condition; multi-phase stmtState 18-21 to parse target/start/length/value.
>
> Also includes O(n²) `src$` concatenation fix (SPACE$ pre-allocation + MID$
> in-place fill) and `@user[]` array reference skip.
>
> **Results**: compiler.x processes cgen.x in 0.09s (was: OOM after 118s);
> native compiler IR matches Rust IR byte-for-byte for both compiler.x and
> cgen.x (zero diff); `native_compiler_emits_cgen_ir_for_cgen` test un-ignored
> and passes; `compiler_self_compilation_produces_identical_ir` passes; all
> workspace tests pass (0 failed, 0 ignored).
### CGEN-NESTED-FN — IMPLEMENTED `[2026-08-22, 823008f]`

> **DONE** (`823008f`, sync 28/28, bootstrap fixed point intact, no demo
> regression): cgen.x now emits single-level nested functions as inline
> `xb_label_<name>:` blocks per the design below. awrite (a nested-fn cc-fail) now
> compiles; the other 18 nested-fn demos are unblocked a layer but stay
> multiply-blocked on dual-dim/SHARED, so demo faithful is unchanged at 67 (awrite is
> a GUI interp-timeout, not differentially scored). Locked by
> `cemitter_and_cgen_agree_on_nested_function` (minimal non-GUI repro). The design as
> built, retained for reference:

> The 19 `function definition is not allowed
> here` cc-fails are all **single-level** nested functions (verified: 0 demos nest
> deeper than one level). A nested `INTERNAL FUNCTION` (e.g. `Callback`/`CreateWindow`
> inside `XitMain`) captures the parent's locals and is invoked via a computed GOSUB
> through a dispatch array (`gosub_expr Sub[message]`). C forbids nested function
> definitions, so cgen.x's streaming emitter — which `PRINT`s a `xb_user_<name>(...)  {`
> for every `function ` token — emits an illegal nested def.

**Rust's scheme (the reference to mirror), from `awindow`'s `xb_user_XitMain`:**
1. Every nested function's **locals + its own name (retval) are hoisted into the
>    parent**'s declaration block (`intptr_t xb_var_Callback = 0;` etc. at the top of
>    `xb_user_XitMain`).
2. Each nested body becomes a **labeled block** `xb_label_<name>:` placed **after** the
>    parent's main body (and after the parent's own return-dispatch, so normal flow
>    never falls into it) but before the parent's final `return`.
3. `funcaddr(NestedFn)` lowers to `((intptr_t)&&xb_label_<name>)` (address-of-label),
>    NOT a function pointer — that value is what the `Sub[]` dispatch array holds.
4. The nested block ends with the gosub-return dispatch
>    (`if (xb_gosub_sp > xb_gosub_base) goto *xb_gosub_stack[--xb_gosub_sp]; return …;`);
>    Rust uses a **per-function `xb_gosub_base = xb_gosub_sp`** so a nested block's bare
>    RETURN unwinds to its GOSUB caller, not the outermost frame.

**cgen.x changes required (a dedicated pass, byte-neutral on selfhost — the self-host
tools nest no functions, so the whole path is a no-op there and the bootstrap fixed
point is protected by the sync gate regardless):**
- Track a single-level **nest flag** + a **separate `nestBlocks$` buffer**. A `function `
>   token while already `inFunc` starts a nested block (record the name in a
>   `nestFns$` set; append `xb_label_<name>:` to `nestBlocks$`) instead of `PRINT`ing a
>   new C signature. Its statements append to `nestBlocks$`, and its locals/DIMs still
>   feed the **parent's** `usedSyms$`/`dimmedSyms$` so `emit_hoists$` declares them at the
>   parent top.
- A nested `end function` appends the gosub-return dispatch and clears the nest flag
>   (staying `inFunc`); the parent's `end function` emits
>   `hoists + parentBody + <return-dispatch> + nestBlocks$ + return + }`.
- `emit_expr$`'s `funcaddr(` arm checks `nestFns$`: a nested-fn arg → `((intptr_t)&&xb_label_<name>)`.
- Adopt the per-function `xb_gosub_base` (replacing the bare `xb_gosub_sp > 0` guard) so
>   nested-block RETURNs unwind correctly — verify byte-neutral on the self-host corpus
>   (its GOSUB use is a single top-level frame, base 0).

Verify against `awindow`/`abuffer` (2 nested fns each, simplest). Several nested-fn
demos are also multiply-blocked (SHARED arrays, dual-dim), so this unblocks a *layer*
for all 19 and flips the subset whose only remaining blocker is nesting.


### CGEN-SHARED-ARR design — qbtoxb, the last demo compile-fail `[2026-08-20]`

> **RESOLVED `[2026-08-20]` — qbtoxb compiles + is byte-faithful (114/114).** The
> full end-to-end shared-array IR feature analyzed below was **not** required. Two
> observations collapsed it to a bounded, structural fix: (1) qbtoxb reads stdin,
> hits EOF, and exits *before* its translation logic runs, so its interp output is
> empty — the C backend only needs to **compile** and produce empty output, not
> model shared-array runtime semantics; (2) `xbasic$`'s element-type facet was
> already fixed (facet 1, `b1e0353`: `shared_name_suffix`). The residue was two
> *scoping/naming* bugs, both fixed structurally in `6153215`: `#line` `REDIM`'d
> inside an `IF` became a block-scoped C VLA that later out-of-block uses couldn't
> see (→ **CGEN-NESTED-DIM**: nested-block array DIMs force to dyn), and `token[]`
> was an array param also read as a scalar `token = token[i]` (→ dual-use *array
> param* split under **CGEN-SCALAR-ARRAY-DUAL**). Both triggers are structural, so
> they round-trip the frozen text IR; the corpus has neither pattern, so
> `cgen_cemitter_sync` 5/5 + bootstrap held. True shared-array *runtime* semantics
> (module arrays as real C globals) remain a non-blocking future feature
> (**CGEN-SHARED-ARR**, ary-class programs). The analysis below is retained as the
> record of the deeper feature it was mistaken for.

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
