//! ATTACH statement emission — array row aliasing with copy semantics.
//!
//! `ATTACH A TO B` copies B's data into A (A becomes a copy of B's view).
//! - `ATTACH src[] TO dst[i,]` — copy row `i` of 2D `dst` into 1D `src`
//! - `ATTACH dst[i,] TO src[]` — copy 1D `src` back into row `i` of 2D `dst`
//! - `ATTACH src[] TO dst[]`   — whole-array copy (`dst` → `src`)
//!
use crate::c_emit::array_dims;

use crate::c_emit::{array_ident, emit_array_var_name};
use crate::c_emit_expr::emit_expr;
use crate::checked::ValueType;
use crate::ir::{IrExpr, IrSymbol};

#[allow(clippy::too_many_arguments)]
pub(crate) fn emit_attach(
    left: &IrSymbol,
    left_indices: &[IrExpr],
    left_is_row: bool,
    right: &IrSymbol,
    right_indices: &[IrExpr],
    right_is_row: bool,
    out: &mut String,
    ind: &str,
) {
    // Case 1: ATTACH src[] TO dst[i,]  (left=1D whole, right=2D row)
    // Copy row i of dst into src, set src ubound to row size (if dynamic).
    if !left_is_row && right_is_row && left_indices.is_empty() && right_indices.len() == 1 {
        // Only emit copy code if the 2D array has known dimensions.
        if array_dims(&right.name).is_some_and(|d| d.len() >= 2) {
            let dst_ident = array_ident(&right.name);
            out.push_str(ind);
            out.push_str("memcpy(");
            emit_array_var_name(left, out);
            out.push_str(", &");
            emit_array_var_name(right, out);
            out.push_str("[(");
            emit_expr(&right_indices[0], out);
            out.push_str(") * (xb_dim_");
            out.push_str(&dst_ident);
            out.push_str("_1 + 1)], (size_t)(xb_dim_");
            out.push_str(&dst_ident);
            out.push_str("_1 + 1) * sizeof(*");
            emit_array_var_name(left, out);
            out.push_str("));\n");
            // Set ubound only for dynamic arrays (fixed-size have no xb_ub_ var).
            if crate::c_emit::is_dyn_array(&left.name) {
                out.push_str(ind);
                out.push_str("xb_ub_");
                out.push_str(&array_ident(&left.name));
                out.push_str(" = xb_dim_");
                out.push_str(&dst_ident);
                out.push_str("_1;\n");
            }
        }
        return;
    }

    // Case 2: ATTACH dst[i,] TO src[]  (left=2D row, right=1D whole)
    // Copy src back into row i of dst.
    if left_is_row && !right_is_row && left_indices.len() == 1 && right_indices.is_empty() {
        if array_dims(&left.name).is_some_and(|d| d.len() >= 2) {
            let dst_ident = array_ident(&left.name);
            out.push_str(ind);
            out.push_str("memcpy(&");
            emit_array_var_name(left, out);
            out.push_str("[(");
            emit_expr(&left_indices[0], out);
            out.push_str(") * (xb_dim_");
            out.push_str(&dst_ident);
            out.push_str("_1 + 1)], ");
            emit_array_var_name(right, out);
            out.push_str(", (size_t)(");
            if crate::c_emit::is_dyn_array(&right.name) {
                out.push_str("xb_ub_");
                out.push_str(&array_ident(&right.name));
                out.push_str(" + 1");
            } else {
                // Fixed-size stack array: use sizeof to get total byte count.
                out.push_str("sizeof(");
                emit_array_var_name(right, out);
                out.push_str(") / sizeof(*");
                emit_array_var_name(right, out);
                out.push(')');
            }
            out.push_str(") * sizeof(*");
            emit_array_var_name(right, out);
            out.push_str("));\n");
        }
        return;
    }

    // Case 3: ATTACH src[] TO dst[]  (both whole arrays, same type)
    // Copy dst into src. For dynamic arrays, use ubound-tracked memcpy +
    // ubound copy. For fixed-size stack arrays, use sizeof-based memcpy.
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_indices.is_empty() {
        if left.value_type != right.value_type {
            return;
        }
        // Alias path (M1-ATTACH-ALIAS): both sides share one heap block after
        // `dst = src`, so later writes/REDIMs are visible through both names
        // (the interpreter links instead of copying). Same-group members only;
        // everything else keeps the copy paths below.
        let gl = crate::c_emit::attach_group(&left.name);
        let gr = crate::c_emit::attach_group(&right.name);
        if !gl.is_empty() && gl == gr {
            out.push_str(ind);
            emit_array_var_name(left, out);
            out.push_str(" = ");
            emit_array_var_name(right, out);
            out.push_str(";\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&array_ident(&left.name));
            out.push_str(" = xb_ub_");
            out.push_str(&array_ident(&right.name));
            out.push_str(";\n");
            return;
        }
        let left_dyn = crate::c_emit::is_dyn_array(&left.name);
        let right_dyn = crate::c_emit::is_dyn_array(&right.name);
        if left_dyn && right_dyn {
            out.push_str(ind);
            out.push_str("memcpy(");
            emit_array_var_name(left, out);
            out.push_str(", ");
            emit_array_var_name(right, out);
            out.push_str(", (size_t)(xb_ub_");
            out.push_str(&array_ident(&right.name));
            out.push_str(" + 1) * sizeof(*");
            emit_array_var_name(left, out);
            out.push_str("));\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&array_ident(&left.name));
            out.push_str(" = xb_ub_");
            out.push_str(&array_ident(&right.name));
            out.push_str(";\n");
        } else if !left_dyn
            && !right_dyn
            && array_dims(&left.name).is_some()
            && array_dims(&right.name).is_some()
        {
            // Fixed-size stack arrays: copy min(sizeof(left), sizeof(right)).
            out.push_str(ind);
            out.push_str("memcpy(");
            emit_array_var_name(left, out);
            out.push_str(", ");
            emit_array_var_name(right, out);
            out.push_str(", sizeof(");
            emit_array_var_name(left, out);
            out.push_str(") < sizeof(");
            emit_array_var_name(right, out);
            out.push_str(") ? sizeof(");
            emit_array_var_name(left, out);
            out.push_str(") : sizeof(");
            emit_array_var_name(right, out);
            out.push_str("));\n");
        }
        return;
    }

    // Case 4: ATTACH src TO dst[k]  (left=scalar, right=indexed element)
    // Copy element k of dst into scalar src. Only for same-type.
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_indices.len() == 1 {
        if left.value_type == right.value_type {
            out.push_str(ind);
            if left.value_type == ValueType::String {
                out.push_str("xb_str_");
                out.push_str(&crate::c_emit_expr::sanitize_c_ident(&left.name));
                out.push_str(" = xb_strdup(");
            } else {
                out.push_str("xb_var_");
                out.push_str(&crate::c_emit_expr::sanitize_c_ident(&left.name));
                out.push_str(" = ");
            }
            emit_array_var_name(right, out);
            out.push('[');
            emit_expr(&right_indices[0], out);
            if left.value_type == ValueType::String {
                out.push_str("]);\n");
            } else {
                out.push_str("];\n");
            }
        }
        return;
    }

    // Case 5: ATTACH dst[k] TO src  (left=indexed element, right=scalar)
    // Copy scalar src into element k of dst. Only for same-type.
    if !left_is_row
        && !right_is_row
        && left_indices.len() == 1
        && right_indices.is_empty()
        && left.value_type == right.value_type
    {
        out.push_str(ind);
        emit_array_var_name(left, out);
        out.push('[');
        emit_expr(&left_indices[0], out);
        out.push_str("] = ");
        if right.value_type == ValueType::String {
            out.push_str("xb_strdup(xb_str_");
            out.push_str(&crate::c_emit_expr::sanitize_c_ident(&right.name));
            out.push_str(");\n");
        } else {
            out.push_str("xb_var_");
            out.push_str(&crate::c_emit_expr::sanitize_c_ident(&right.name));
            out.push_str(";\n");
        }
    }

    // Fallback: no-op for unhandled patterns (e.g. 3D ATTACH, type-punning).
    // These are rare and will be handled as needed.
}

/// Group-aware REDIM for a whole-array ATTACH alias member (M1-ATTACH-ALIAS).
/// `group` is the sorted member list, `home` = group[0] owns the shared block.
/// Snapshots the home block, then: when live with some member sharing it,
/// realloc the home, fill the grown tail, and repoint exactly the sharing
/// members (+ bound cells); otherwise the member resizes independently.
/// Sound for conditional ATTACH (never-taken stays independent) and detach
/// (re-DIM'd members keep their blocks). Tail fill mirrors the single arm.
pub(crate) fn emit_group_redim(
    symbol: &IrSymbol,
    size: &IrExpr,
    group: &[String],
    home: &str,
    ind: &str,
    out: &mut String,
) {
    let home_sym = IrSymbol {
        name: home.to_string(),
        value_type: symbol.value_type,
    };
    let hid = array_ident(home);
    let fill = if symbol.value_type == ValueType::String {
        "xb_str(\"\")"
    } else {
        "0"
    };
    out.push_str(ind);
    out.push_str("{ intptr_t _oldub = xb_ub_");
    out.push_str(&hid);
    out.push_str("; xb_ub_");
    out.push_str(&hid);
    out.push_str(" = (");
    emit_expr(size, out);
    out.push_str(");\n");
    // Snapshot the home block: members sharing it ride the group realloc;
    // detached/conditional-never-taken members keep independent blocks.
    out.push_str(ind);
    out.push_str("    ");
    out.push_str(crate::c_emit::c_type(symbol.value_type));
    out.push_str(" *_att_home = ");
    emit_array_var_name(&home_sym, out);
    out.push_str(";\n");
    // Group path iff the home is live and some member shares it.
    out.push_str(ind);
    out.push_str("if (_att_home != 0 && (");
    let mut first = true;
    for m in group {
        if !first {
            out.push_str(" || ");
        }
        first = false;
        let msym = IrSymbol {
            name: m.clone(),
            value_type: symbol.value_type,
        };
        emit_array_var_name(&msym, out);
        out.push_str(" == _att_home");
    }
    out.push_str(")) {\n");
    out.push_str(ind);
    out.push_str("    ");
    emit_array_var_name(&home_sym, out);
    out.push_str(" = realloc(_att_home");
    out.push_str(", (size_t)(xb_ub_");
    out.push_str(&hid);
    out.push_str(" + 1) * sizeof(*");
    emit_array_var_name(&home_sym, out);
    out.push_str(")); if (!");
    emit_array_var_name(&home_sym, out);
    out.push_str(") abort();\n");
    out.push_str(ind);
    out.push_str("    for (intptr_t _i = _oldub + 1; _i <= xb_ub_");
    out.push_str(&hid);
    out.push_str("; _i++) ");
    emit_array_var_name(&home_sym, out);
    out.push_str("[_i] = ");
    out.push_str(fill);
    out.push_str(";\n");
    // Repoint exactly the members sharing the old home block (detached
    // members keep their blocks).
    for m in group {
        if m == home {
            continue;
        }
        let msym = IrSymbol {
            name: m.clone(),
            value_type: symbol.value_type,
        };
        out.push_str(ind);
        out.push_str("    if (");
        emit_array_var_name(&msym, out);
        out.push_str(" == _att_home) { ");
        emit_array_var_name(&msym, out);
        out.push_str(" = ");
        emit_array_var_name(&home_sym, out);
        out.push_str("; xb_ub_");
        out.push_str(&array_ident(m));
        out.push_str(" = xb_ub_");
        out.push_str(&hid);
        out.push_str("; }\n");
    }
    // single-REDIM shape on the member itself.
    out.push_str(ind);
    out.push_str("} else {\n");
    out.push_str(ind);
    out.push_str("    ");
    emit_array_var_name(symbol, out);
    out.push_str(" = realloc(");
    emit_array_var_name(symbol, out);
    out.push_str(", (size_t)(xb_ub_");
    out.push_str(&hid);
    out.push_str(" + 1) * sizeof(*");
    emit_array_var_name(symbol, out);
    out.push_str(")); if (!");
    emit_array_var_name(symbol, out);
    out.push_str(") abort();\n");
    out.push_str(ind);
    out.push_str("    for (intptr_t _i = _oldub + 1; _i <= xb_ub_");
    out.push_str(&hid);
    out.push_str("; _i++) ");
    emit_array_var_name(symbol, out);
    out.push_str("[_i] = ");
    out.push_str(fill);
    out.push_str(";\n");
    out.push_str(ind);
    out.push_str("} }\n");
}
