//! ATTACH statement execution — array move semantics (lang.txt:57-62).
//!
//! `ATTACH src TO dst` moves an array from source node to destination node.
//! If the destination node is not empty a runtime error occurs.
//! After the array is moved to the destination node, the source node is made empty.

use crate::eval::eval;
use crate::slot::{ExecutionState, RuntimeError, RuntimeValue, TypedSlot};
use xb_compiler::{IrExpr, IrProgram, IrSymbol, ValueType};

fn val_as_int(v: &RuntimeValue) -> i32 {
    match v {
        RuntimeValue::Integer(n) => *n,
        RuntimeValue::Giant(n) => *n as i32,
        _ => 0,
    }
}

fn get_slot_mut<'a>(state: &'a mut ExecutionState, name: &str) -> Option<&'a mut TypedSlot> {
    if state.shared.contains_key(name) {
        state.shared.get_mut(name)
    } else {
        state.slots.get_mut(name)
    }
}

/// ATTACH destination nodes may be undeclared (`xtemp[]` in aarray_ISNODE): an
/// absent name is an empty node, which lang.txt allows as a move target.
fn ensure_dest_slot(state: &mut ExecutionState, name: &str, ty: ValueType) {
    if state.shared.contains_key(name) || state.slots.contains_key(name) {
        return;
    }
    state.slots.insert(name.to_string(), TypedSlot::new(ty));
}

/// Execute an ATTACH statement under legacy move semantics (lang.txt:57-62).
///
/// `ATTACH left TO right`:
/// - `left` is the SOURCE node.
/// - `right` is the DESTINATION node.
/// - If destination is not empty, runtime error occurs.
/// - Source node is made empty after the transfer.
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
    let mut left_idx_vals = Vec::with_capacity(left_indices.len());
    for ie in left_indices {
        left_idx_vals.push(eval(program, ie, state, output)?);
    }
    let mut right_idx_vals = Vec::with_capacity(right_indices.len());
    for ie in right_indices {
        right_idx_vals.push(eval(program, ie, state, output)?);
    }
    ensure_dest_slot(state, &right.name, right.value_type);

    // Case 1: ATTACH src[i,] TO dst[] — move row i of 2-D src into 1-D dst
    if left_is_row && !right_is_row && left_idx_vals.len() == 1 && right_indices.is_empty() {
        let row = val_as_int(&left_idx_vals[0]).max(0) as usize;
        // Check destination is empty
        if let Some(dst) = get_slot_mut(state, &right.name) {
            if !dst.is_empty_array() {
                return Err(RuntimeError::AttachDestinationNotEmpty);
            }
        }
        // Extract row from source
        let (moved_arr, moved_dims) = {
            let src = get_slot_mut(state, &left.name).ok_or_else(|| RuntimeError::UnknownSlot {
                name: left.name.clone(),
            })?;
            src.ensure_node_rows();
            // No in-scope 2-D shape (by-ref param, trailing-comma DIM): match
            // CEmitter's guarded no-op instead of crashing.
            if src.node_rows.is_none() {
                return Ok(());
            }
            let rows = src.node_rows.as_mut().unwrap();
            if row >= rows.len() {
                return Err(RuntimeError::ArrayIndexOutOfRange { index: row as i32 });
            }
            let row_slot = &mut rows[row];
            let arr = row_slot.array.take();
            let dims = row_slot.dims.clone();
            row_slot.dims = vec![0];
            (arr, dims)
        };
        // Move into destination
        let dst = get_slot_mut(state, &right.name).ok_or_else(|| RuntimeError::UnknownSlot {
            name: right.name.clone(),
        })?;
        dst.array = moved_arr;
        dst.dims = moved_dims;
        dst.node_rows = None;
        return Ok(());
    }

    // Case 2: ATTACH src[] TO dst[i,] — move 1-D src into row i of 2-D dst
    if !left_is_row && right_is_row && left_indices.is_empty() && right_idx_vals.len() == 1 {
        let row = val_as_int(&right_idx_vals[0]).max(0) as usize;
        // Ensure destination has node_rows and check row is empty
        {
            let dst =
                get_slot_mut(state, &right.name).ok_or_else(|| RuntimeError::UnknownSlot {
                    name: right.name.clone(),
                })?;
            dst.ensure_node_rows();
            if dst.node_rows.is_none() {
                return Ok(());
            }
            let rows = dst.node_rows.as_mut().unwrap();
            if row >= rows.len() {
                return Err(RuntimeError::ArrayIndexOutOfRange { index: row as i32 });
            }
            if !rows[row].is_empty_array() {
                return Err(RuntimeError::AttachDestinationNotEmpty);
            }
        }
        // Take from source
        let (moved_arr, moved_dims) = {
            let src = get_slot_mut(state, &left.name).ok_or_else(|| RuntimeError::UnknownSlot {
                name: left.name.clone(),
            })?;
            let arr = src.array.take();
            let dims = src.dims.clone();
            src.dims = vec![0];
            (arr, dims)
        };
        // Put into destination row
        let dst = get_slot_mut(state, &right.name).unwrap();
        let rows = dst.node_rows.as_mut().unwrap();
        rows[row].array = moved_arr;
        rows[row].dims = moved_dims;
        return Ok(());
    }

    // Case 3: ATTACH src[] TO dst[] — move whole 1-D array (or string scalar to string scalar)
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_indices.is_empty() {
        // Check if string scalar to string scalar
        let is_str_scalar = left.value_type == ValueType::String
            && get_slot_mut(state, &left.name)
                .map_or(false, |s| s.array.is_none() && s.node_rows.is_none());
        if is_str_scalar {
            let dst_empty = get_slot_mut(state, &right.name).map_or(true, |s| match &s.value {
                RuntimeValue::String(bytes) => bytes.is_empty(),
                _ => false,
            });
            if !dst_empty {
                return Err(RuntimeError::AttachDestinationNotEmpty);
            }
            let src = get_slot_mut(state, &left.name).unwrap();
            let val = std::mem::replace(&mut src.value, RuntimeValue::String(Vec::new()));
            let dst = get_slot_mut(state, &right.name).unwrap();
            dst.value = val;
            return Ok(());
        }

        // Array to array move
        if let Some(dst) = get_slot_mut(state, &right.name) {
            if !dst.is_empty_array() {
                return Err(RuntimeError::AttachDestinationNotEmpty);
            }
        }
        let (arr, dims, rows) = {
            let src = get_slot_mut(state, &left.name).ok_or_else(|| RuntimeError::UnknownSlot {
                name: left.name.clone(),
            })?;
            let a = src.array.take();
            let d = src.dims.clone();
            let r = src.node_rows.take();
            src.dims = vec![0];
            (a, d, r)
        };
        let dst = get_slot_mut(state, &right.name).ok_or_else(|| RuntimeError::UnknownSlot {
            name: right.name.clone(),
        })?;
        dst.array = arr;
        dst.dims = dims;
        dst.node_rows = rows;
        return Ok(());
    }

    // Case 4: ATTACH src$ TO dst$[i] — move string scalar into element of string array
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_idx_vals.len() == 1 {
        let k = val_as_int(&right_idx_vals[0]).max(0) as usize;
        {
            let dst =
                get_slot_mut(state, &right.name).ok_or_else(|| RuntimeError::UnknownSlot {
                    name: right.name.clone(),
                })?;
            let arr = dst.array.as_mut().ok_or(RuntimeError::NotAnArray)?;
            if k >= arr.len() {
                return Err(RuntimeError::ArrayIndexOutOfRange { index: k as i32 });
            }
            let elem_empty = match &arr[k] {
                RuntimeValue::String(s) => s.is_empty(),
                _ => false,
            };
            if !elem_empty {
                return Err(RuntimeError::AttachDestinationNotEmpty);
            }
        }
        let val = {
            let src = get_slot_mut(state, &left.name).ok_or_else(|| RuntimeError::UnknownSlot {
                name: left.name.clone(),
            })?;
            std::mem::replace(&mut src.value, RuntimeValue::String(Vec::new()))
        };
        let dst = get_slot_mut(state, &right.name).unwrap();
        dst.array.as_mut().unwrap()[k] = val;
        return Ok(());
    }

    // Case 5: ATTACH src$[i] TO dst$ — move element of string array into string scalar
    if !left_is_row && !right_is_row && left_idx_vals.len() == 1 && right_indices.is_empty() {
        let k = val_as_int(&left_idx_vals[0]).max(0) as usize;
        {
            let dst =
                get_slot_mut(state, &right.name).ok_or_else(|| RuntimeError::UnknownSlot {
                    name: right.name.clone(),
                })?;
            let dst_empty = match &dst.value {
                RuntimeValue::String(s) => s.is_empty(),
                _ => false,
            };
            if !dst_empty {
                return Err(RuntimeError::AttachDestinationNotEmpty);
            }
        }
        let val = {
            let src = get_slot_mut(state, &left.name).ok_or_else(|| RuntimeError::UnknownSlot {
                name: left.name.clone(),
            })?;
            let arr = src.array.as_mut().ok_or(RuntimeError::NotAnArray)?;
            if k >= arr.len() {
                return Err(RuntimeError::ArrayIndexOutOfRange { index: k as i32 });
            }
            std::mem::replace(&mut arr[k], RuntimeValue::String(Vec::new()))
        };
        let dst = get_slot_mut(state, &right.name).unwrap();
        dst.value = val;
        return Ok(());
    }

    Ok(())
}
