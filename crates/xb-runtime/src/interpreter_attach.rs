//! ATTACH statement execution — array row aliasing with copy semantics.
//!
//! `ATTACH A TO B` copies B's data into A (A becomes a copy of B's view).
//! - `ATTACH src[] TO dst[i,]` — copy row `i` of 2D `dst` into 1D `src`
//! - `ATTACH dst[i,] TO src[]` — copy 1D `src` back into row `i` of 2D `dst`
//! - `ATTACH src[] TO dst[]`   — whole-array copy (`dst` → `src`)

use crate::eval::eval;
use crate::slot::{ExecutionState, RuntimeError, RuntimeValue, TypedSlot};
use xb_compiler::{IrExpr, IrProgram, IrSymbol};
/// Execute an ATTACH statement (copy semantics).
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
    fn get_slot_mut<'a>(
        state: &'a mut ExecutionState,
        name: &str,
    ) -> Option<&'a mut TypedSlot> {
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

    // Case 1: ATTACH src[] TO dst[i,] — copy row i of dst into src
    if !left_is_row && right_is_row && left_indices.is_empty() && right_idx_vals.len() == 1 {
        let row = right_idx_vals[0] as usize;
        let row_data = get_slot(state, &right.name).and_then(|rs| {
            rs.array.as_ref().and_then(|arr| {
                if rs.dims.len() >= 2 {
                    let row_size = rs.dims[1];
                    let start = row * row_size;
                    let end = (start + row_size).min(arr.len());
                    Some((arr[start..end].to_vec(), row_size))
                } else {
                    None
                }
            })
        });
        if let Some((data, row_size)) = row_data {
            if let Some(ls) = get_slot_mut(state, &left.name) {
                ls.array = Some(data);
                ls.dims = vec![row_size];
            }
        }
        return Ok(());
    }

    // Case 2: ATTACH dst[i,] TO src[] — copy src back into row i of dst
    if left_is_row && !right_is_row && left_idx_vals.len() == 1 && right_indices.is_empty() {
        let row = left_idx_vals[0] as usize;
        let src_data = get_slot(state, &right.name)
            .and_then(|rs| rs.array.as_ref().map(|a| a.clone()));
        if let Some(src_arr) = src_data {
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

    // Case 3: ATTACH src[] TO dst[] — whole array copy
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_indices.is_empty() {
        let right_data = get_slot(state, &right.name).and_then(|rs| {
            rs.array.as_ref().map(|a| (a.clone(), rs.dims.clone()))
        });
        if let Some((arr, dims)) = right_data {
            if let Some(ls) = get_slot_mut(state, &left.name) {
                ls.array = Some(arr);
                ls.dims = dims;
            }
        }
        return Ok(());
    }

    // Case 4: ATTACH src TO dst[k] — copy element k of dst into scalar src
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_idx_vals.len() == 1 {
        let k = right_idx_vals[0] as usize;
        let val = get_slot(state, &right.name)
            .and_then(|rs| rs.array.as_ref().and_then(|a| a.get(k).cloned()));
        if let Some(v) = val {
            if let Some(ls) = get_slot_mut(state, &left.name) {
                ls.value = v;
            }
        }
        return Ok(());
    }

    // Case 5: ATTACH dst[k] TO src — copy scalar src into element k of dst
    if !left_is_row && !right_is_row && left_idx_vals.len() == 1 && right_indices.is_empty() {
        let k = left_idx_vals[0] as usize;
        let val = get_slot(state, &right.name).map(|rs| rs.value.clone());
        if let Some(v) = val {
            if let Some(ls) = get_slot_mut(state, &left.name) {
                if let Some(ref mut arr) = ls.array {
                    if k < arr.len() {
                        arr[k] = v;
                    }
                }
            }
        }
        return Ok(());
    }

    // Fallback: no-op for unhandled patterns.
    Ok(())
}
