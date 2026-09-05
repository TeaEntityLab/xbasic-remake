//! ATTACH statement emission — array move semantics (lang.txt:57-62).
//!
//! `ATTACH src TO dst` moves ownership: dst receives the data, src is emptied.
//! Node holders (in-function rank-2 row-ATTACH operands) are `T**` row tables.
//! Other 2-D holders stay contiguous; unknown-shape row ATTACH is a no-op.
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
    // Case 1: ATTACH src[] TO dst[i,]  (left=1D whole source, right=2D row destination)
    // Move 1-D src into row i of 2-D dst.
    if !left_is_row && right_is_row && left_indices.is_empty() && right_indices.len() == 1 {
        let dst_ident = array_ident(&right.name);
        if crate::c_emit::is_node_array(&right.name) {
            out.push_str(ind);
            emit_array_var_name(right, out);
            out.push('[');
            emit_expr(&right_indices[0], out);
            out.push_str("] = ");
            emit_array_var_name(left, out);
            out.push_str(";\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&dst_ident);
            out.push_str("_rows[");
            emit_expr(&right_indices[0], out);
            out.push_str("] = xb_ub_");
            out.push_str(&array_ident(&left.name));
            out.push_str(";\n");
            out.push_str(ind);
            emit_array_var_name(left, out);
            out.push_str(" = 0;\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&array_ident(&left.name));
            out.push_str(" = -1;\n");
            return;
        }
        if array_dims(&right.name).is_some_and(|d| d.len() >= 2) {
            out.push_str(ind);
            out.push_str("memcpy(&");
            emit_array_var_name(right, out);
            out.push_str("[(");
            emit_expr(&right_indices[0], out);
            out.push_str(") * (xb_dim_");
            out.push_str(&dst_ident);
            out.push_str("_1 + 1)], ");
            emit_array_var_name(left, out);
            out.push_str(", (size_t)(");
            if crate::c_emit::is_dyn_array(&left.name) {
                out.push_str("xb_ub_");
                out.push_str(&array_ident(&left.name));
                out.push_str(" + 1");
            } else {
                out.push_str("sizeof(");
                emit_array_var_name(left, out);
                out.push_str(") / sizeof(*");
                emit_array_var_name(left, out);
                out.push(')');
            }
            out.push_str(") * sizeof(*");
            emit_array_var_name(left, out);
            out.push_str("));\n");
            if crate::c_emit::is_dyn_array(&left.name) {
                out.push_str(ind);
                emit_array_var_name(left, out);
                out.push_str(" = 0;\n");
                out.push_str(ind);
                out.push_str("xb_ub_");
                out.push_str(&array_ident(&left.name));
                out.push_str(" = -1;\n");
            }
        }
        return;
    }

    // Case 2: ATTACH src[i,] TO dst[]  (left=2D row source, right=1D whole destination)
    // Move row i of 2-D src into 1-D dst.
    if left_is_row && !right_is_row && left_indices.len() == 1 && right_indices.is_empty() {
        let src_ident = array_ident(&left.name);
        if crate::c_emit::is_node_array(&left.name) {
            out.push_str(ind);
            emit_array_var_name(right, out);
            out.push_str(" = ");
            emit_array_var_name(left, out);
            out.push('[');
            emit_expr(&left_indices[0], out);
            out.push_str("];\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&array_ident(&right.name));
            out.push_str(" = xb_ub_");
            out.push_str(&src_ident);
            out.push_str("_rows[");
            emit_expr(&left_indices[0], out);
            out.push_str("];\n");
            out.push_str(ind);
            emit_array_var_name(left, out);
            out.push('[');
            emit_expr(&left_indices[0], out);
            out.push_str("] = 0;\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&src_ident);
            out.push_str("_rows[");
            emit_expr(&left_indices[0], out);
            out.push_str("] = -1;\n");
            return;
        }
        if array_dims(&left.name).is_some_and(|d| d.len() >= 2) {
            let src_ident = array_ident(&left.name);
            if crate::c_emit::is_dyn_array(&right.name) {
                out.push_str(ind);
                emit_array_var_name(right, out);
                out.push_str(" = realloc(");
                emit_array_var_name(right, out);
                out.push_str(", (size_t)(xb_dim_");
                out.push_str(&src_ident);
                out.push_str("_1 + 1) * sizeof(*");
                emit_array_var_name(right, out);
                out.push_str(")); if (!");
                emit_array_var_name(right, out);
                out.push_str(") abort();\n");
            }
            out.push_str(ind);
            out.push_str("memcpy(");
            emit_array_var_name(right, out);
            out.push_str(", &");
            emit_array_var_name(left, out);
            out.push_str("[(");
            emit_expr(&left_indices[0], out);
            out.push_str(") * (xb_dim_");
            out.push_str(&src_ident);
            out.push_str("_1 + 1)], (size_t)(xb_dim_");
            out.push_str(&src_ident);
            out.push_str("_1 + 1) * sizeof(*");
            emit_array_var_name(right, out);
            out.push_str("));\n");
            if crate::c_emit::is_dyn_array(&right.name) {
                out.push_str(ind);
                out.push_str("xb_ub_");
                out.push_str(&array_ident(&right.name));
                out.push_str(" = xb_dim_");
                out.push_str(&src_ident);
                out.push_str("_1;\n");
            }
        }
        return;
    }

    // Case 3: ATTACH src[] TO dst[]  (whole arrays, same type) or ATTACH src$ TO dst$
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_indices.is_empty() {
        if left.value_type != right.value_type {
            return;
        }
        // String scalar to string scalar move
        let left_is_arr = crate::c_emit::is_dyn_array(&left.name)
            || crate::c_emit::array_dims(&left.name).is_some()
            || crate::c_emit::is_array_param(&left.name);
        if left.value_type == ValueType::String && !left_is_arr {
            out.push_str("xb_str_");
            out.push_str(&crate::c_emit_expr::sanitize_c_ident(&right.name));
            out.push_str(" = xb_str_");
            out.push_str(&crate::c_emit_expr::sanitize_c_ident(&left.name));
            out.push_str(";\n");
            out.push_str(ind);
            out.push_str("xb_str_");
            out.push_str(&crate::c_emit_expr::sanitize_c_ident(&left.name));
            out.push_str(" = xb_str(\"\");\n");
            return;
        }
        let left_dyn = crate::c_emit::is_dyn_array(&left.name);
        let right_dyn = crate::c_emit::is_dyn_array(&right.name);
        if left_dyn && right_dyn {
            out.push_str(ind);
            emit_array_var_name(right, out);
            out.push_str(" = ");
            emit_array_var_name(left, out);
            out.push_str(";\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&array_ident(&right.name));
            out.push_str(" = xb_ub_");
            out.push_str(&array_ident(&left.name));
            out.push_str(";\n");
            out.push_str(ind);
            emit_array_var_name(left, out);
            out.push_str(" = 0;\n");
            out.push_str(ind);
            out.push_str("xb_ub_");
            out.push_str(&array_ident(&left.name));
            out.push_str(" = -1;\n");
        } else if !left_dyn
            && !right_dyn
            && array_dims(&left.name).is_some()
            && array_dims(&right.name).is_some()
        {
            out.push_str(ind);
            out.push_str("memcpy(");
            emit_array_var_name(right, out);
            out.push_str(", ");
            emit_array_var_name(left, out);
            out.push_str(", sizeof(");
            emit_array_var_name(right, out);
            out.push_str(") < sizeof(");
            emit_array_var_name(left, out);
            out.push_str(") ? sizeof(");
            emit_array_var_name(right, out);
            out.push_str(") : sizeof(");
            emit_array_var_name(left, out);
            out.push_str("));\n");
        }
        return;
    }

    // Case 4: ATTACH src$ TO dst$[k]  (left=scalar, right=indexed element)
    // Move scalar src into element k of dst.
    if !left_is_row && !right_is_row && left_indices.is_empty() && right_indices.len() == 1 {
        if left.value_type == right.value_type {
            out.push_str(ind);
            emit_array_var_name(right, out);
            out.push('[');
            emit_expr(&right_indices[0], out);
            out.push_str("] = ");
            if left.value_type == ValueType::String {
                out.push_str("xb_str_");
                out.push_str(&crate::c_emit_expr::sanitize_c_ident(&left.name));
                out.push_str(";\n");
                out.push_str(ind);
                out.push_str("xb_str_");
                out.push_str(&crate::c_emit_expr::sanitize_c_ident(&left.name));
                out.push_str(" = xb_str(\"\");\n");
            } else {
                out.push_str("xb_var_");
                out.push_str(&crate::c_emit_expr::sanitize_c_ident(&left.name));
                out.push_str(";\n");
            }
        }
        return;
    }

    // Case 5: ATTACH src$[k] TO dst$  (left=indexed element, right=scalar)
    // Move element k of src into scalar dst.
    if !left_is_row
        && !right_is_row
        && left_indices.len() == 1
        && right_indices.is_empty()
        && left.value_type == right.value_type
    {
        out.push_str(ind);
        if right.value_type == ValueType::String {
            out.push_str("xb_str_");
            out.push_str(&crate::c_emit_expr::sanitize_c_ident(&right.name));
            out.push_str(" = ");
            emit_array_var_name(left, out);
            out.push('[');
            emit_expr(&left_indices[0], out);
            out.push_str("];\n");
            out.push_str(ind);
            emit_array_var_name(left, out);
            out.push('[');
            emit_expr(&left_indices[0], out);
            out.push_str("] = xb_str(\"\");\n");
        } else {
            out.push_str("xb_var_");
            out.push_str(&crate::c_emit_expr::sanitize_c_ident(&right.name));
            out.push_str(" = ");
            emit_array_var_name(left, out);
            out.push('[');
            emit_expr(&left_indices[0], out);
            out.push_str("];\n");
        }
        return;
    }
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
    let mid = array_ident(&symbol.name);
    let fill = if symbol.value_type == ValueType::String {
        "xb_str(\"\")"
    } else {
        "0"
    };
    out.push_str(ind);
    out.push_str("{ ");
    out.push_str(crate::c_emit::c_type(symbol.value_type));
    out.push_str(" *_att_home = ");
    emit_array_var_name(&home_sym, out);
    out.push_str(";\n");
    out.push_str(ind);
    out.push_str("if (");
    emit_array_var_name(symbol, out);
    if symbol.name == home {
        out.push_str(" != 0) {\n");
    } else {
        out.push_str(" == _att_home && ");
        emit_array_var_name(symbol, out);
        out.push_str(" != 0) {\n");
    }
    // Group path: realloc the home block, fill the grown tail, repoint the
    // member itself plus exactly the members still sharing the old block.
    out.push_str(ind);
    out.push_str("    { intptr_t _oldub = xb_ub_");
    out.push_str(&hid);
    out.push_str("; xb_ub_");
    out.push_str(&hid);
    out.push_str(" = (");
    emit_expr(size, out);
    out.push_str("); ");
    emit_array_var_name(&home_sym, out);
    out.push_str(" = realloc(_att_home, (size_t)(xb_ub_");
    out.push_str(&hid);
    out.push_str(" + 1) * sizeof(*");
    emit_array_var_name(&home_sym, out);
    out.push_str(")); if (!");
    emit_array_var_name(&home_sym, out);
    out.push_str(") abort(); for (intptr_t _i = _oldub + 1; _i <= xb_ub_");
    out.push_str(&hid);
    out.push_str("; _i++) ");
    emit_array_var_name(&home_sym, out);
    out.push_str("[_i] = ");
    out.push_str(fill);
    out.push_str("; ");
    if symbol.name != home {
        emit_array_var_name(symbol, out);
        out.push_str(" = ");
        emit_array_var_name(&home_sym, out);
        out.push_str("; xb_ub_");
        out.push_str(&mid);
        out.push_str(" = xb_ub_");
        out.push_str(&hid);
        out.push_str("; ");
    }
    out.push_str("}\n");
    for m in group {
        if m == home || m == &symbol.name {
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
    // Independent path: existing single-REDIM shape on the member itself.
    out.push_str(ind);
    out.push_str("} else {\n");
    out.push_str(ind);
    out.push_str("    { intptr_t _oldub = xb_ub_");
    out.push_str(&mid);
    out.push_str("; xb_ub_");
    out.push_str(&mid);
    out.push_str(" = (");
    emit_expr(size, out);
    out.push_str("); ");
    emit_array_var_name(symbol, out);
    out.push_str(" = realloc(");
    emit_array_var_name(symbol, out);
    out.push_str(", (size_t)(xb_ub_");
    out.push_str(&mid);
    out.push_str(" + 1) * sizeof(*");
    emit_array_var_name(symbol, out);
    out.push_str(")); if (!");
    emit_array_var_name(symbol, out);
    out.push_str(") abort(); for (intptr_t _i = _oldub + 1; _i <= xb_ub_");
    out.push_str(&mid);
    out.push_str("; _i++) ");
    emit_array_var_name(symbol, out);
    out.push_str("[_i] = ");
    out.push_str(fill);
    out.push_str("; }\n");
    out.push_str(ind);
    out.push_str("} }\n");
}
