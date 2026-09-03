//! ATTACH statement execution — array view/alias bindings (M1-ATTACH-ALIAS).
//!
//! Real XBasic `ATTACH` shares storage rather than copying: `ATTACH A TO B`
//! binds A as a view of B (whole-array or one 2-D row). Reads, writes,
//! REDIMs, and UBOUNDs route through the link, so later mutations are visible
//! from both names and REDIM-through-view resizes the shared store (the
//! `ary.x` row-growth idiom). Scalar operands still copy element-wise.
//!
//! - `ATTACH src[] TO dst[i,]` — link `src` as a view of row `i` of `dst`
//! - `ATTACH dst[i,] TO src[]` — bounded-copy `src`'s window into row `i`,
//!   then link `src` as a view of the row for shared futures
//! - `ATTACH src[] TO dst[]` — link `src` as a whole-array view of `dst`
//!
//! Links degrade to owned storage when the target is absent (e.g. across
//! call boundaries, which pass value snapshots) or on reference cycles.

use crate::eval::eval;
use crate::slot::{AliasLink, ExecutionState, RuntimeError, RuntimeValue, TypedSlot};
use xb_compiler::{IrExpr, IrProgram, IrSymbol};

/// Resolution of an array name through ATTACH alias links.
///
/// Returns `(holder, base, view_dims)` where `holder` owns the live flat
/// storage, `base` is the flat offset of this name's window, and `view_dims`
/// is `Some` window shape for row views (else the holder's own dims apply).
/// The window derives live from the target on every call, so REDIMs through
/// any name are instantly visible. Chains flatten through whole-links; only
/// the outermost row link contributes its window (deeper row links are
/// ignored — no corpus program nests views). Missing targets and cycles
/// degrade to the name itself (owned, copy-model behavior).
pub(crate) fn resolve_alias(
    state: &ExecutionState,
    name: &str,
) -> (String, usize, Option<Vec<usize>>) {
    fn store_has(state: &ExecutionState, name: &str) -> bool {
        state.shared.contains_key(name) || state.slots.contains_key(name)
    }
    fn row_len(state: &ExecutionState, target: &str) -> usize {
        let slot = state.shared.get(target).or_else(|| state.slots.get(target));
        match slot {
            Some(s) if s.dims.len() >= 2 => s.dims[1],
            Some(s) => s.array.as_ref().map_or(0, |a| a.len()),
            None => 0,
        }
    }
    let mut cur = name.to_string();
    let mut base = 0usize;
    let mut window: Option<(usize, usize)> = None; // (base, len) from outermost row link
    let mut visited: Vec<String> = vec![cur.clone()];
    for _ in 0..16 {
        let Some(link) = state.aliases.get(&cur) else {
            break;
        };
        if visited.contains(&link.target) {
            // Cycle: degrade to owned storage.
            return (name.to_string(), 0, None);
        }
        if !store_has(state, &link.target) {
            // Dangling target (e.g. across calls): stop at the last holder.
            // If even the first hop dangles, the view is unbacked: report the
            // holder as-is so reads yield defaults and writes discard.
            break;
        }
        if window.is_none() {
            if let Some(r) = link.row {
                let len = row_len(state, &link.target);
                base = r.saturating_mul(len);
                window = Some((base, len));
            }
        }
        visited.push(cur.clone());
        cur = link.target.clone();
    }
    match window {
        Some((b, len)) => (cur, b, Some(vec![len])),
        None if cur != name => (cur, base, None),
        None => (name.to_string(), 0, None),
    }
}

/// Live flat length of `name`'s window (holder flat for whole views and
/// plain names, row length for row views). Used for UBOUND folding.
pub(crate) fn alias_window_len(state: &ExecutionState, name: &str) -> Option<usize> {
    let (holder, base, vdims) = resolve_alias(state, name);
    let slot = state
        .shared
        .get(&holder)
        .or_else(|| state.slots.get(&holder))?;
    let flat = slot.array.as_ref()?.len();
    match vdims {
        Some(d) => Some(d.iter().product::<usize>().min(flat.saturating_sub(base))),
        None => Some(flat),
    }
}

/// Look up the holder's slot (shared-then-slots, matching eval read paths).
fn holder_slot<'a>(state: &'a ExecutionState, holder: &str) -> Option<&'a TypedSlot> {
    state.shared.get(holder).or_else(|| state.slots.get(holder))
}

/// Read one element of `name`'s window at `idxs`: row-override rows redirect
/// to the source window; alias windows offset into holder storage; plain
/// names use the existing shape logic. `None` = unbacked or out of range.
pub(crate) fn read_window_element(
    state: &ExecutionState,
    name: &str,
    idxs: &[usize],
) -> Option<RuntimeValue> {
    let (holder, base, vdims) = resolve_alias(state, name);
    let slot = holder_slot(state, &holder)?;
    let arr = slot.array.as_ref()?;
    match vdims {
        Some(vd) => {
            let len: usize = vd.iter().product();
            let i = idxs.first().copied().unwrap_or(0);
            if i >= len {
                return None;
            }
            arr.get(base + i).cloned()
        }
        None => slot.array_offset(idxs).and_then(|o| slot.array_get(o).ok()),
    }
}

/// Write one element through views (`true` = stored). Row-override rows and
/// alias windows write into shared storage; plain names use the existing
/// offset logic with the dyn grow-guard. Views grow dyn holders (row splice
/// or whole resize); non-dyn out-of-range writes discard like before.
pub(crate) fn write_window_element(
    state: &mut ExecutionState,
    name: &str,
    idxs: &[usize],
    v: RuntimeValue,
) -> bool {
    let (holder, base, vdims) = resolve_alias(state, name);
    let dyn_ok = state.dyn_arrays.contains(name) || state.dyn_arrays.contains(&holder);
    // Row-view write: flat index into holder storage, growing the shared row.
    if let Some(vd) = vdims {
        let len: usize = vd.iter().product();
        let i = idxs.first().copied().unwrap_or(0);
        let slot = match state
            .shared
            .get_mut(&holder)
            .or_else(|| state.slots.get_mut(&holder))
        {
            Some(s) => s,
            None => return false,
        };
        let arr = match slot.array.as_mut() {
            Some(a) => a,
            None => return false,
        };
        if i < len && base + i < arr.len() {
            arr[base + i] = v;
            return true;
        }
        if !dyn_ok || i >= (1 << 20) {
            return false;
        }
        // Grow the shared row: splice room at the row end (later rows shift,
        // preserving row-major layout) and widen the holder's stride.
        let want = i + 1;
        if slot.dims.len() >= 2 {
            let fill = RuntimeValue::default_for(slot.value_type);
            let at = (base + len).min(arr.len());
            arr.splice(at..at, std::iter::repeat_n(fill, want - len));
            slot.dims[1] += want - len;
            arr[base + i] = v;
            return true;
        }
        return false;
    }
    // Owned / whole-view write with the historical offset + grow rule.
    let slot = match state
        .shared
        .get_mut(&holder)
        .or_else(|| state.slots.get_mut(&holder))
    {
        Some(s) => s,
        None => return false,
    };
    // Re-resolve the offset against the holder's live shape (mirrors
    // `TypedSlot::array_offset`; whole views share the holder's dims).
    let off = slot.array_offset(idxs);
    if let Some(o) = off {
        if slot.array.as_ref().is_some_and(|a| o < a.len()) {
            slot.array_set(o, v).ok();
            return true;
        }
        return false;
    }
    if dyn_ok && idxs.len() == 1 && idxs[0] < (1 << 20) {
        slot.array_reshape(vec![idxs[0] + 1]);
        slot.array_set(idxs[0], v).ok();
        return true;
    }
    false
}
/// Materialize `name`'s window as owned values + shape (for by-value call
/// passing): row views copy their window; whole views and plain names clone
/// holder storage.
pub(crate) fn materialize_window(
    state: &ExecutionState,
    name: &str,
) -> Option<(Vec<RuntimeValue>, Vec<usize>)> {
    let (holder, base, vdims) = resolve_alias(state, name);
    let slot = holder_slot(state, &holder)?;
    let arr = slot.array.as_ref()?.clone();
    match vdims {
        Some(vd) => {
            let len: usize = vd.iter().product();
            let end = (base + len).min(arr.len());
            let mut out = arr[base.min(arr.len())..end].to_vec();
            out.resize(len, RuntimeValue::default_for(slot.value_type));
            Some((out, vd))
        }
        None => {
            let out = arr;
            let dims = slot.dims.clone();
            Some((out, dims))
        }
    }
}

/// Mutable store holding `holder` (shared-preferred, matching read paths).
fn store_of<'a>(
    state: &'a mut ExecutionState,
    holder: &str,
) -> &'a mut std::collections::BTreeMap<String, TypedSlot> {
    if state.shared.contains_key(holder) {
        &mut state.shared
    } else {
        &mut state.slots
    }
}

/// Replace `name`'s window with `vals` (XstCopyArray / quicksort writeback
/// through views): whole views replace holder storage (dropping its stale
/// row overrides); row views splice the shared row to the arrival length;
/// plain names take the historical wholesale replace.
pub(crate) fn write_window_values(state: &mut ExecutionState, name: &str, vals: Vec<RuntimeValue>) {
    let (holder, base, vdims) = resolve_alias(state, name);
    let is_view = state.aliases.contains_key(name) && holder != name;
    match (is_view, vdims) {
        (true, Some(vd)) => {
            let rowlen: usize = vd.iter().product();
            let want = vals.len();
            let store = store_of(state, &holder);
            if let Some(hslot) = store.get_mut(&holder) {
                if let Some(harr) = hslot.array.as_mut() {
                    let end = (base + rowlen).min(harr.len());
                    let fill = RuntimeValue::default_for(hslot.value_type);
                    if want >= rowlen {
                        harr.splice(end..end, std::iter::repeat_n(fill, want - rowlen));
                    } else {
                        harr.drain(end - (rowlen - want)..end);
                    }
                    for (di, sv) in vals.into_iter().enumerate() {
                        if let Some(cell) = harr.get_mut(base + di) {
                            *cell = sv;
                        }
                    }
                }
                if hslot.dims.len() >= 2 {
                    hslot.dims[1] = want;
                }
            }
        }
        _ => {
            // Whole views replace holder storage; plain names take the
            // historical wholesale replace. (A `None` window with no link is
            // unreachable — resolve only windows through links.)
            let store = store_of(state, &holder);
            let len = vals.len();
            if let Some(hslot) = store.get_mut(&holder) {
                hslot.array = Some(vals);
                hslot.dims = vec![len];
            }
        }
    }
}

#[allow(clippy::too_many_arguments)]
pub(crate) fn exec_attach(
    program: &IrProgram,
    left: &IrSymbol,
    left_indices: &[IrExpr],
    left_is_row: bool,
    right: &IrSymbol,
    right_indices: &[IrExpr],
    right_is_row: bool,
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<(), RuntimeError> {
    // Evaluate index expressions.
    let left_idx_vals: Vec<i64> = left_indices
        .iter()
        .map(|e| eval(program, e, state, output))
        .collect::<Result<Vec<_>, _>>()?
        .into_iter()
        .map(|v| match v {
            RuntimeValue::Integer(n) => n as i64,
            RuntimeValue::Giant(g) => g,
            _ => 0,
        })
        .collect();
    let right_idx_vals: Vec<i64> = right_indices
        .iter()
        .map(|e| eval(program, e, state, output))
        .collect::<Result<Vec<_>, _>>()?
        .into_iter()
        .map(|v| match v {
            RuntimeValue::Integer(n) => n as i64,
            RuntimeValue::Giant(g) => g,
            _ => 0,
        })
        .collect();

    // Helper: get a mutable slot from either shared or local slots.
    fn get_slot_mut<'a>(state: &'a mut ExecutionState, name: &str) -> Option<&'a mut TypedSlot> {
        if state.shared.contains_key(name) {
            state.shared.get_mut(name)
        } else {
            state.slots.get_mut(name)
        }
    }

    // Helper: get an immutable slot.
    fn get_slot<'a>(state: &'a ExecutionState, name: &str) -> Option<&'a TypedSlot> {
        state.shared.get(name).or_else(|| state.slots.get(name))
    }
    // Case 1: ATTACH src[] TO dst[i,] — link src as a view of row i of dst.
    // Requires the view slot to exist and dst to be 2-D with a live row
    // (mirrors the old copy guard); otherwise a no-op. Later reads, writes,
    // REDIMs, and UBOUNDs of src see the shared row. Self-attach keeps the
    // historical whole-flat replace.
    if !left_is_row && right_is_row && left_indices.is_empty() && right_idx_vals.len() == 1 {
        let row = right_idx_vals[0].max(0) as usize;
        let row_data = get_slot(state, &right.name).and_then(|rs| {
            rs.array.as_ref().and_then(|arr| {
                if rs.dims.len() >= 2 {
                    let row_size = rs.dims[1];
                    let start = row * row_size;
                    if start >= arr.len() {
                        return None;
                    }
                    let end = (start + row_size).min(arr.len());
                    Some((arr[start..end].to_vec(), row_size))
                } else {
                    None
                }
            })
        });
        let view_exists = get_slot(state, &left.name).is_some();
        if left.name == right.name {
            // Historical self replace (pathological; preserved verbatim).
            if let Some((data, row_size)) = row_data {
                if let Some(ls) = get_slot_mut(state, &left.name) {
                    ls.array = Some(data);
                    ls.dims = vec![row_size];
                }
            }
        } else if row_data.is_some() && view_exists {
            state.aliases.insert(
                left.name.clone(),
                AliasLink {
                    target: right.name.clone(),
                    row: Some(row),
                },
            );
        }
        return Ok(());
    }

    // Case 2: ATTACH dst[i,] TO src[] — bounded-copy src's live window into
    // row i of dst (historical behavior, now window-aware), then link src as
    // a view of the row so later mutations are shared (the ary.x row-growth
    // idiom: an empty src copies nothing, links, and sees the row; REDIM
    // through the view grows the shared holder). Requires src array storage
    // and a 2-D dst holder; otherwise a no-op. Self-attach copies verbatim.
    if left_is_row && !right_is_row && left_idx_vals.len() == 1 && right_indices.is_empty() {
        let row = left_idx_vals[0].max(0) as usize;
        if left.name == right.name {
            // Historical self copy (pathological; preserved verbatim).
            if let Some(src_arr) = get_slot(state, &right.name).and_then(|rs| rs.array.clone()) {
                if let Some(ls) = get_slot_mut(state, &left.name) {
                    if let Some(ref mut dst_arr) = ls.array {
                        if ls.dims.len() >= 2 {
                            let row_size = ls.dims[1];
                            let start = row * row_size;
                            let copy_len = src_arr.len().min(row_size);
                            for (di, sv) in src_arr[..copy_len].iter().enumerate() {
                                if start + di < dst_arr.len() {
                                    dst_arr[start + di] = sv.clone();
                                }
                            }
                        }
                    }
                }
            }
            return Ok(());
        }
        let src_win = materialize_window(state, &right.name);
        let dst_ok = get_slot(state, &left.name)
            .is_some_and(|ls| ls.array.is_some() && ls.dims.len() >= 2 && left.name != right.name);
        if let (Some((vals, _)), true) = (src_win, dst_ok) {
            // Bounded copy into the row (historical shape, window-aware).
            if let Some(ls) = get_slot_mut(state, &left.name) {
                if let Some(ref mut dst_arr) = ls.array {
                    if ls.dims.len() >= 2 {
                        let row_size = ls.dims[1];
                        let start = row * row_size;
                        let copy_len = vals.len().min(row_size);
                        for (di, sv) in vals[..copy_len].iter().enumerate() {
                            if start + di < dst_arr.len() {
                                dst_arr[start + di] = sv.clone();
                            }
                        }
                    }
                }
            }
            // Link the source as a view of the row for shared futures. The
            // source slot must exist (it does — its window materialized).
            state.aliases.insert(
                right.name.clone(),
                AliasLink {
                    target: left.name.clone(),
                    row: Some(row),
                },
            );
        }
        return Ok(());
    }

    // Case 3: ATTACH src[] TO dst[] — link src as a whole-array view of dst.
    // Requires both slots with array storage (mirrors the old copy guard);
    // otherwise a no-op. Self-attach is a no-op (historical self-copy).
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_indices.is_empty() {
        if left.name != right.name {
            let ok = get_slot(state, &right.name).is_some_and(|rs| rs.array.is_some())
                && get_slot(state, &left.name).is_some();
            if ok {
                state.aliases.insert(
                    left.name.clone(),
                    AliasLink {
                        target: right.name.clone(),
                        row: None,
                    },
                );
            }
        }
        return Ok(());
    }

    // Case 4: ATTACH src TO dst[k] — copy element k of dst into scalar src.
    // The element reads through dst's view (row override or alias window).
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_idx_vals.len() == 1 {
        let k = right_idx_vals[0].max(0) as usize;
        let val = read_window_element(state, &right.name, &[k]);
        if let Some(v) = val {
            if let Some(ls) = get_slot_mut(state, &left.name) {
                ls.value = v;
            }
        }
        return Ok(());
    }

    // Case 5: ATTACH dst[k] TO src — copy scalar src into element k of dst.
    // The write goes through dst's view into shared storage.
    if !left_is_row && !right_is_row && left_idx_vals.len() == 1 && right_indices.is_empty() {
        let k = left_idx_vals[0].max(0) as usize;
        let val = get_slot(state, &right.name).map(|rs| rs.value.clone());
        if let Some(v) = val {
            let _ = write_window_element(state, &left.name, &[k], v);
        }
        return Ok(());
    }

    // Fallback: no-op for unhandled patterns.
    Ok(())
}
