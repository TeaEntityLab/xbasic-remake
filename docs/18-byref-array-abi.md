# 18 — By-ref array ABI (`CGEN-BYREF-REDIM`) — turnkey implementation guide

**Status:** designed + de-risked, not implemented. This is the single remaining
high-value C-backend gap. It unblocks `RT-XST` `XstQuickSort` (14 uses) +
`XstCopyArray` (2 uses) and general `REDIM`-through-`@array[]`, which the core
libs (`fgr`/`vgr`/`msc` + 5 `ary`/merge variants) all need. Scale ≈ GIANT: a
byte-identity-critical ABI change best done in one focused pass with the demo/lib
differential budget (~300s/cycle), **not** a tail-end grind (two prior partial
attempts were correctly reverted — see roadmap row `CGEN-REDIM`).

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

## Design: resize-only descriptor (minimal blast radius)

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

## Verification plan + gates

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
