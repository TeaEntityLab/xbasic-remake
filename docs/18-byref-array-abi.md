# 18 — By-ref array ABI (`CGEN-BYREF-REDIM`) — turnkey implementation guide

**Status (reviewed 2026-08-29, updated 2026-09-04 M1-PLAIN-FWD): LANDED for primitive/flat arrays, for shared composite `ARY_VAR_DATA` member arrays (compile-only), for typed composite-array by-ref reads + writeback (`FUNCTION Sum (PT p[])`, `7/30/60`), for callee-side member UBOUND at C-model parity (C `0,0`, interp `1,1`), and for plain forward-only callee-UBOUND (no scalar cell without a REDIM-seeded descriptor use, via headerless-safe `##redimNames$`; C `0`, interp `2`). Still open: REDIM through a composite member and UBOUND real bounds in C (descriptor seeding, deferred). Runtime `ARY` remains blocked on `ATTACH` alias semantics and a bounded behavior test (see docs/17 `RR-02`/`RR-06`).**
Merge `be03117` implemented the primitive-array descriptor `(T** data,
intptr_t* ub)`, content-preserving `REDIM`, and the `XstQuickSort`/
`XstCopyArray` helper path. Those contracts remain covered. A focused
follow-on (`c_emit_expr` `is_shared_array` → `emit_raw_array_name`) now forwards
the five `ARY_VAR_DATA` member arrays (`status` … `numElements`) as shared
`T*` globals at both definition and all four call sites. The last full
workspace run reports **308 passed / 0 failed**; both `ary.x` and
`ary1.0001.x` compile cc-clean in `xbsourcelib_ary_compiles_clean`. The
separate `xbsourcelib_interp_matches_compiled` loop covers 11 non-ARY programs,
not these sources. Runtime `ARY` remains compile-only until `ATTACH` alias
semantics and a bounded behavior test land (see docs/17 `RR-02`/`RR-06`).
### What the landed primitive-array implementation covers (branch `625ce19`)
- `collect_descriptor_params` fixpoint — **resize-seeded** (`REDIM`/`DIM`-with-size
  + `XstQuickSort`/`XstCopyArray` pos 0/1), **backward-propagated**; a bare
  `UBOUND`/`SIZE`/empty-`DIM x[]` does NOT seed (keeps qbtoxb's stubbed-Xst arrays
  plain — though qbtoxb still crashes on its *genuinely*-resized arrays).
- Descriptor `(T** xb_var_x_d, intptr_t* xb_ub_x)` via an `emit_array_var_name`
  **chokepoint** (`(*xb_var_x_d)` for descriptor params) + `emit_raw_array_name`
  (name-building, dual-use-independent so fwd-decl == definition) + `emit_array_ub_ref`.
- Descriptor-aware: `ArrayAccess`/`ArrayAssignment` (chokepoint), `ArrayUBound`
  (`*ub`), `SizeOf`, bare `Symbol` (`(intptr_t)(*x_d)`), `REDIM`/`DIM`
  (realloc; DIM zero-all, REDIM preserve+zero-tail), `emit_swap`, `emit_call_args`
  (passing-form consistency: descriptor pos → `(data,ub)`; plain pos ← descriptor
  local → `*x_d`), param decls (both sites).
- Genuinely-dual descriptor **locals** (`maxZ = z` scalar + `@maxZ[]` array) stay
  dual-use via `collect_dual_use(extra_array)`; a descriptor **param** used as a
  scalar also splits (dual=1, e.g. xit `XitSetFunction text$`) — the facet
  classifier forces descriptor params/locals into array-context like the
  reference emitter. Callers dispatch by callee argument **position**
  (`position=N` facets, `is_desc_position$`), never by variable name.
- A forwarded local whose callee never allocates has no array storage: reads
  are NULL-guarded (`(arr ? arr[i] : default)`), integer `UBOUND` stays `-1`,
  string `UBOUND`/`IFZ` keep the scalar fallbacks (`LEN-1`, scalar truthiness).
  A forwarded local used 2-D with no DIM shape falls back to first-index
  lowering, matching the reference emitter (xit `FindSearch matches`).
- `XstQuickSort`/`XstCopyArray`: interp (`xst::quicksort`/`copyarray`) + gated C
  runtimes (8-byte-slot reorder, `et`-dispatch, `xb_strdup` deep-copy).


### Composite `TYPE` array boundary

The compiler represents a composite array as parallel member arrays. A correct
by-ref ABI must forward every member array in exactly the shape its callee
declares: a plain element pointer for read-only parameters or a coherent
`(T** data, intptr_t* ub)` descriptor where resizing/length propagation requires
it. Declaration/definition differences in `@` syntax must not change the C
parameter count or indirection level.

The immediate compile-only gate is now **done for the shared `ARY_VAR_DATA`
case**: both ARY sources are cc-clean and the full workspace is green.
Runtime-faithful `ARY` remains blocked on `ATTACH` alias semantics and a
bounded behavior test; see docs/17 `RR-02` (now done for compile) and `RR-06`.

### Original framing (pre-verification)
The single remaining high-value C-backend gap. Scale ≈ GIANT: a
byte-identity-critical ABI change best done in one focused pass with the demo/lib
differential budget (~300s/cycle), **not** a tail-end grind.

## The bug (verified 2026-08-21)

Reference (interp) is correct; cgen is wrong. Minimal repro:

```basic
VERSION "0.1"
DECLARE FUNCTION Grow (@a[], newsize)
FUNCTION Main
	DIM a[2]
	a[0] = 5 : a[1] = 6 : a[2] = 7
	Grow(@a[], 5)
	PRINT "ub="; UBOUND(a[])        ' interp: 5   cgen: 2 (WRONG)
	FOR i = 0 TO UBOUND(a[]) : PRINT "a"; i; "="; a[i] : NEXT
END FUNCTION
FUNCTION Grow (@a[], newsize)
	REDIM a[newsize]               ' resizes the caller's array
	a[newsize] = 99
END FUNCTION
```

Interp: `ub=5`, `[5,6,7,0,0,99]` (content preserved, caller sees resize).
cgen: `ub=2`, `[5,6,7]` — the `REDIM` is dropped and the caller never resizes.

### Root cause (from emitted C)

`@a[]` lowers to `byref(symbol(a))` (a bare symbol, **not** an `ArrayAccess`).
Today cgen emits, for `Grow(@a[], 5)`:

```c
intptr_t xb_user_Grow(intptr_t *xb_var_a, intptr_t xb_var_newsize);   /* fwd */
/* in Main: a is DUAL-USE — a scalar AND an array */
intptr_t xb_var_a = 0;              /* spurious scalar facet */
intptr_t xb_var_a_arr[(2) + 1];     /* the real array */
xb_user_Grow(&xb_var_a, 5);         /* passes &SCALAR (WRONG) */
...
intptr_t xb_user_Grow(intptr_t *xb_var_a, intptr_t xb_var_newsize) {
    xb_var_a[xb_var_newsize] = 99;  /* REDIM was silently dropped */
}
```

Three faults, all from arrays having no `{data, ub}` descriptor:
1. **Dual-use scalar facet.** `byref(symbol(a))` counts as a *scalar* use of `a`,
   so `FN_DUAL_USE` marks `a` dual → a bogus `xb_var_a` scalar is emitted and
   passed (`&xb_var_a`) instead of the array.
2. **No length cell.** `UBOUND` emits `sizeof(arr)/sizeof(arr[0])-1`, which is
   wrong for a pointer param (`8/8-1 = 0`) and impossible after a resize.
3. **`REDIM` dropped / no realloc.** A by-ref param can't be reallocated because
   it's a fixed stack array with no heap storage or writeback path.

## Attempt 1 (2026-08-21): mechanism verified; scope is the FULL descriptor

A complete implementation pass was built end-to-end and then reverted (kept the
tree green at 193/0). It **proved the descriptor mechanism** and **corrected the
scope**. Findings, so the next pass starts from truth:

**Verified working (byte-identical interp==cgen) with a resize-only descriptor:**
- `collect_resized(program)` fixpoint (in `c_emit_hoist.rs`): seeds = array params
  `Dim`'d in body + `XstQuickSort`/`XstCopyArray` resized positions; propagates
  through call args. Returns per-fn (resized params, must-be-dyn locals). Empty
  for the whole corpus → sync-safe. This analysis is correct — reuse it.
- Descriptor `(T** xb_var_p_d, intptr_t* xb_ub_p)`; emission wired through params,
  forward-decls, `ArrayAccess`, `ArrayAssignment`, `ArrayUBound`, `REDIM`/`DIM`,
  call-args, and bare `Symbol`. **`DIM`-of-param zeros all (calloc semantics);
  `REDIM` preserves + zero-fills the grown tail (realloc)** — both matched the
  interpreter. Repros `Grow(@a[]){REDIM}`, `Fill(@a[]){DIM}`, and local
  `XstQuickSort` (int/string/decreasing/case-insensitive/partial-range +
  permutation) were **byte-identical**.
- Dual-use fix: exclude resized/dyn closure names from `FN_DUAL_USE` so
  `@a[]`→`byref(symbol(a))` stops minting a spurious `xb_var_a` scalar facet. Works.

**Why resize-only is INSUFFICIENT (the scope correction):** the libs `UBOUND` an
array that is a **read-only param in one function but resized in another**
(`msc`/`Kittedy`: `UBOUND(colors[])`, `UBOUND(error[])`). A read-only array param
has no length cell, so `UBOUND` emits `xb_ub_colors` → **undeclared identifier**.
So **length must ride on every by-ref array param**, not just resized ones —
i.e. the full ~4430-site descriptor, or two shapes: length-carrying read-only
`(T* data, intptr_t ub)` vs resizable `(T** data_d, intptr_t* ub)`, with the
**length-carrying closure** (UBOUND'd ∪ Xst-source ∪ resized) propagated through
the call graph so a caller passing `@x[]` supplies `x`'s length consistently.
- `nameList$` (XstCopyArray source in the libs) **is** REDIM'd (fgr.x:8866) → it is
  a resized param and already carries length; the earlier "read-only source needs
  length" worry was a bad test. The real read-only-length need is **`UBOUND` of a
  read-only param**.
- Bare array name as a scalar (`addr = bmp`) = the buffer address; emit
  `(intptr_t)(*xb_var_bmp_d)` (interp has no real addresses, but the consuming
  `*AT` memory builtins are stubbed 0/no-op in both backends, so it stays faithful).
- `XstQuickSort`/`XstCopyArray` C runtimes (8-byte-slot reorder + `et`-dispatch +
  `xb_strdup` deep-copy) + interp `xst::quicksort`/`copyarray` were written and
  work; wire them once the descriptor threads length everywhere.

**Recommended next-pass shape:** implement the **length-carrying closure** (not
resize-only): every by-ref array param in the closure becomes
`(T** data_d, intptr_t* ub)` (uniform — read-only just never reallocs); route it
through **all** emission sites (the list above **plus** `SizeOf`, `MidAssign`,
`Swap`, `Read`, `BuiltinAssign`, `Inc`/`Dec`); verify against `cgen_demo_regression`
(fast, includes the 8 libs) before the full differential.

## Chokepoint design + complete emission-site checklist (2026-08-21)

Attempt 1 failed by *whack-a-mole* — per-arm branches meant each new site
(`gif`→`Kittedy`→`msc`) surfaced only at `cc` time. Fix: a **chokepoint** so most
sites auto-handle, plus this **exhaustive checklist** (grepped from the tree) so
the next pass covers everything before the first build.

**Chokepoint:** make `emit_array_var_name(sym)` emit `(*xb_var_x_d)` when
`is_descriptor_param(sym)` (else unchanged). Add a raw builder
`emit_raw_array_name` (current body) for constructing the `_d`/param names, and a
`emit_array_ub_ref(name)` returning `(*xb_ub_x)` for a descriptor param / `xb_ub_x`
for a dyn local. Then every caller of `emit_array_var_name` (24 sites, mostly
local-dyn `DIM` allocations that never fire for a param) auto-derefs correctly.

**Sites that auto-handle via the chokepoint** (they call `emit_array_var_name`, or
`emit_expr` which routes through `ArrayAccess`/`Symbol`):
- `ArrayAccess` read (`c_emit_expr`), `ArrayAssignment` write (`c_emit_stmt`),
  `MidAssign` target (`emit_expr(target)`), `ArrayUBound` sizeof-branch.

**Sites needing an explicit descriptor branch** (direct `emit_var_name` / hardcoded
`xb_ub_` / special shape):
1. `emit_symbol_ref` (bare `Symbol`) → `(intptr_t)(*xb_var_x_d)` (bare array name =
   buffer address; `*AT` consumers are stubbed, so faithful).
2. `ArrayUBound` → descriptor: `(*xb_ub_x)`, not `sizeof`.
3. `SizeOf` (`SIZE(x[])`) → `(*xb_ub_x + 1) * sizeof(**xb_var_x_d)` (byte size), not
   `sizeof((*x_d))` (that's element size — wrong).
4. `emit_swap` (`c_emit_select`, uses `emit_var_name`) → whole-array descriptor swap.
5. `emit_read` (`c_emit_data`) → array-element target of a descriptor.
6. `Inc`/`Dec` of a descriptor array element.
7. `BuiltinAssign` / `*AT` memory-op args (`c_emit_stmt` `is_at_write_builtin`).
8. Param decl — `emit_functions` (`c_emit.rs`) **and** `emit_forward_decls`
   (`c_runtime.rs`): descriptor shape `T **xb_var_x_d, intptr_t *xb_ub_x`, RAW name.
9. Call-site `emit_call_args`: **passing-form consistency** — the arg form is
   dictated by the *callee's* param shape, not the caller's need:
   - callee param i is a descriptor → pass descriptor: local dyn `&xb_var_x,&xb_ub_x`;
     descriptor param forward `xb_var_x_d, xb_ub_x`.
   - callee param i is plain `T*` but caller's `x` is a descriptor → pass `*xb_var_x_d`.
10. `REDIM`/`DIM` of a descriptor param → realloc + `*ub` (verified in Attempt 1).

**Closure (length-carrying), backward fixpoint** — a param is a descriptor iff its
body `UBOUND`s / `SIZE`s / `REDIM`/`DIM`s it, or passes it to `XstQuickSort`/
`XstCopyArray` (pos 0 or 1), **or** passes `@x[]` to a callee position that is
itself a descriptor. Locals passed to a descriptor position → dyn. Exclude all
closure names from `FN_DUAL_USE`.

**Order of work:** closure analysis → chokepoint + `emit_raw`/`ub_ref` → the 10
branch sites → dyn promotion + dual-use exclusion → `XstQuickSort`/`XstCopyArray`
(interp `xst.rs` + gated C runtimes) → `cargo test cgen_demo_regression` (6s, 8
libs) green → full differential → suite. Each site is now known up front.


## Design: descriptor mechanics (scope superseded by Attempt 1 → full closure)

> The mechanics below (descriptor shape, per-site emission, dyn promotion) are
> correct and were verified. Only the **scope** changed: Attempt 1 proved the
> closure must be **length-carrying** (UBOUND'd ∪ Xst-source ∪ resized), not
> resize-only. Read "resized" below as "in the length-carrying closure".

Blast radius matters: there are **4430** `@array[]` param mentions across the
corpus. Do **not** change every by-ref array param — read-only ones stay `T* x`
(unchanged → faithful libs preserved). Only the **resize closure** changes.

**A by-ref array param is "resized"** iff, transitively:
- its body `REDIM`s it (incl. a re-`DIM` of a param name — `DIM nameIndex[1]`), or
- it is passed as `XstQuickSort` arg 1 (`@n[]`) or `XstCopyArray` arg 2 (`@copy[]`), or
- it is passed as `@x[]` to another function at a position that is itself a
  resized param (call-graph fixpoint).

A **local** array passed `@x[]` to a resized param position must be promoted to
**dyn** (heap `xb_var_x` + `xb_ub_x`).

### Emission for a resized array param `p` (element type `T`)

| construct | today (`T* xb_var_p`) | descriptor (`T** xb_var_p_d, intptr_t* xb_ub_p`) |
|---|---|---|
| fwd decl + def sig | `T *xb_var_p` | `T **xb_var_p_d, intptr_t *xb_ub_p` |
| read/write `p[i]` | `xb_var_p[i]` | `(*xb_var_p_d)[i]` |
| `UBOUND(p[])` | `sizeof/..` | `(*xb_ub_p)` |
| `REDIM p[n]` | *(dropped)* | `*xb_var_p_d = realloc(*xb_var_p_d,(size_t)((n)+1)*sizeof(T)); *xb_ub_p = (n);` (preserve; zero-fill grown tail) |
| call-site `@x[]` (x local dyn) | `&xb_var_x` | `&xb_var_x, &xb_ub_x` |
| call-site `@x[]` (x resized param) | `xb_var_x` | `xb_var_x_d, xb_ub_x` (forward) |

## Implementation steps (files + functions)

1. **Resize-closure analysis** — new program-level pass, run once in
   `emit_program` next to `set_defined_funcs` (`c_emit.rs`). Fixpoint over
   `program.items`: seed = params `REDIM`'d / passed to `XstQuickSort` arg1 /
   `XstCopyArray` arg2; propagate through call args at resized positions. Output:
   `HashMap<fn_name, HashSet<param_name>>` (resized params) + per-fn
   `HashSet<local_name>` (must-be-dyn locals). Store in two new thread-locals
   (`RESIZED_PARAMS`, plus feed dyn locals into `FN_DYN`).
2. **Per-function context** — in `set_fn_context`, load this function's resized
   param set into a `FN_RESIZED` thread-local + accessor `is_resized_param(name)`.
3. **Kill the dual-use scalar facet** for closure names — in the `FN_DUAL_USE`
   collector, a `byref(symbol(x))` where `x` is a resized array must **not** count
   as a scalar use. Force such `x` pure-dyn (array-only).
4. **Param + forward-decl emission** — where params are formatted (`emit_functions`
   + `emit_forward_decls` in `c_runtime.rs`/`c_emit.rs`), a resized array param
   emits two C params `(T** name_d, intptr_t* name_ub)`.
5. **Access** — `c_emit_expr.rs` `ArrayAccess`/`ArrayUBound`: if
   `is_resized_param(sym)`, emit `(*xb_var_p_d)[i]` / `(*xb_ub_p)`.
6. **REDIM** — `c_emit_stmt.rs` `Dim{redim|re-dim of param}`: for a resized param,
   emit the realloc + `*ub` update above (reuse the content-preserving local
   REDIM logic from `65f81fb`, but through the `*_d`/`*_ub` indirection).
7. **Call-site** — `c_emit_expr.rs::emit_call_args` (+ the stmt `Call` path): a
   `@x[]` arg at a resized param position emits the 2-arg descriptor form.
8. **Local dyn promotion** — extend `collect_dyn_names` (`c_emit_hoist.rs`) so
   must-be-dyn locals (from step 1) are forced dyn (generalize the reverted
   `resized_byref` idea).
9. **`XstQuickSort` / `XstCopyArray`** — interp + cgen. The sort algorithm is
   **validated** (below); emit `xb_quicksort`/`xb_copyarray` taking the descriptor
   for the resized args, plain data ptr + `emit_array_len` for the read-only args.

Existing infra to extend (already present): `FN_BYREF_PARAMS` (scalar by-ref
copy-in/out), `DEFINED_PARAM_BYREF`, `DEFINED_PARAM_ARRAYS`, `FN_DYN`,
`array_ident`, `emit_array_var_name`, content-preserving local `REDIM`.

## Validated `XstQuickSort` algorithm (from a verified local-only attempt)

All XBasic array elements are 8-byte slots (i64 / double / char\*), so one helper
reorders via 8-byte copies + an `et`-dispatched (0=int64,1=double,2=string)
**stable insertion sort** (ties keep ascending original index — the doc's
"secondary sort increasing only"). `mode` bit0 = decreasing, bit1 =
case-insensitive. It returns the reordered array + a permutation `n` (`n[new]=old`;
indices outside `[low,high]` map to themselves), resizing `@n[]` to match `@a[]`.
Interp: run in the caller's state (by-ref arrays are the caller's slots). Verified
byte-identical interp==cgen for **local** arrays across
increasing/decreasing/case-insensitive/partial-range + the permutation; the corpus
uses it on by-ref **params** (fgr `Ary_AddName(@nameList$[], @nameIndex[])`), which
is exactly what this ABI unblocks. `XstCopyArray(@src[], @dst[])` resizes `dst` to
`src`'s length and copies elements (spec: simple numeric/string only).

## Historical verification plan + gates (primitive-array landing)

- Iterate on the minimal repro above (fast) until `interp == cgen` byte-for-byte.
- Then, in order, all must stay green:
  - `cargo test -p xb-runtime --test cgen_cemitter_sync` = **5/5** (self-host tools
    + v0.1 corpus have **no** resized by-ref params → emission unchanged → safe).
  - `cargo test -p xb-runtime --test cgen_demo_regression` = **10/10** (locks the 8
    lib files incl. the `Ary_AddName` sort/copy pattern).
  - full demo/lib differential (`/tmp/diff_cgen.sh`) — the 8 lib files
    (`ary`/`ary1`/`fgr`/`mergeOut`/`mergeOut02`/`mergeTest03`/`vgr`/`vgrOld`) must
    stay `interp==cgen` (they were faithful only because both stubbed the sort;
    now both must sort identically).
  - `cargo test --workspace --exclude xb-ide` = **≥193/0**.
- Add a regression test locking the minimal repro + a param-sort case.
- **Golden/bootstrap/sync-safe:** no v0.1 golden or bootstrap self-host tool passes
  `@array[]` at a resized position (verified) — like GIANT, this is CEmitter-only,
  verified via the differential.
