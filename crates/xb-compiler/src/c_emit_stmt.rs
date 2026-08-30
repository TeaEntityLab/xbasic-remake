use crate::c_emit::c_type;
use crate::c_emit_expr::{emit_default, emit_expr, emit_var_name};
use crate::c_emit_helpers::emit_c_function_name;
use crate::c_emit_select::emit_body;
use crate::ir::{IrExpr, IrItem, IrSymbol};
use crate::ValueType;
fn collect_append_chain<'a>(target: &IrSymbol, expr: &'a IrExpr) -> Option<Vec<&'a IrExpr>> {
    if expr.value_type != ValueType::String {
        return None;
    }
    // A dyn array pointer (`a$[]`) is not a scalar `char*`. xb_append onto
    // `T*`/`T**` is a type error (xui string-array `a$` vs int scalar `a`).
    if crate::c_emit::is_dyn_array(&target.name) && !crate::c_emit::is_dual_use(&target.name) {
        return None;
    }
    let mut parts = Vec::new();
    let mut cur = expr;
    loop {
        match &cur.kind {
            crate::ir::IrExprKind::Arithmetic {
                op: crate::checked::ArithmeticOp::Add,
                left,
                right,
            } if cur.value_type == ValueType::String => {
                if expr_aliases_target(target, right) {
                    return None;
                }
                parts.push(right.as_ref());
                cur = left.as_ref();
            }
            crate::ir::IrExprKind::Symbol(sym)
                if sym.name == target.name && sym.value_type == target.value_type =>
            {
                if parts.is_empty() {
                    return None;
                }
                parts.reverse();
                return Some(parts);
            }
            _ => return None,
        }
    }
}
fn expr_aliases_target(target: &IrSymbol, expr: &IrExpr) -> bool {
    match &expr.kind {
        crate::ir::IrExprKind::Symbol(sym) => {
            sym.name == target.name && sym.value_type == target.value_type
        }
        crate::ir::IrExprKind::SharedVariable(sym) => {
            sym.name == target.name && sym.value_type == target.value_type
        }
        crate::ir::IrExprKind::Arithmetic { left, right, .. } => {
            expr_aliases_target(target, left) || expr_aliases_target(target, right)
        }
        crate::ir::IrExprKind::Comparison { left, right, .. } => {
            expr_aliases_target(target, left) || expr_aliases_target(target, right)
        }
        crate::ir::IrExprKind::Boolean { left, right, .. } => {
            expr_aliases_target(target, left) || expr_aliases_target(target, right)
        }
        crate::ir::IrExprKind::Logical { left, right, .. } => {
            expr_aliases_target(target, left) || expr_aliases_target(target, right)
        }
        crate::ir::IrExprKind::FunctionCall { args, .. } => {
            args.iter().any(|a| expr_aliases_target(target, a))
        }
        crate::ir::IrExprKind::ArrayAccess {
            symbol,
            index,
            extra_indices,
        } => {
            (symbol.name == target.name && symbol.value_type == target.value_type)
                || expr_aliases_target(target, index)
                || extra_indices.iter().any(|i| expr_aliases_target(target, i))
        }
        crate::ir::IrExprKind::ByRef(inner) => expr_aliases_target(target, inner),
        crate::ir::IrExprKind::Unary { operand, .. } => expr_aliases_target(target, operand),
        crate::ir::IrExprKind::Not(inner) => expr_aliases_target(target, inner),
        _ => false,
    }
}
pub(crate) fn emit_item(item: &IrItem, out: &mut String, indent: usize) {
    let ind = "    ".repeat(indent);
    match item {
        IrItem::Version(_) | IrItem::ProgramName(_) => {}
        IrItem::Print { items, separators } => {
            crate::c_emit_select::emit_print(items, separators, out, indent);
        }
        IrItem::Dim {
            symbol,
            size,
            is_array,
            extra_dims,
            redim,
            shared,
            ..
        } => {
            if crate::c_emit::is_descriptor_param(&symbol.name) {
                // DIM/REDIM of a descriptor by-ref array param resizes the caller's
                // array through the descriptor (realloc + `*ub`). REDIM preserves
                // existing content (zero the grown tail); DIM re-inits (zero all) —
                // matching the interpreter (docs/18).
                if let Some(sz) = size {
                    emit_descriptor_redim(symbol, sz, *redim, &ind, out);
                }
                return;
            }
            // A `Dim` of a name that is already a function parameter is a no-op
            // in C (the param is already declared); emitting it would be a
            // redefinition. The interpreter's execute_dim would reset the slot,
            // but for demo lifetimes this is safe.
            if crate::c_emit::is_fn_param(&symbol.name) {
                return;
            }
            // Keyword-`SHARED` scalar: storage is the file-scope `xb_shared_<n>`
            // global (declared by collect_shared); a local declaration would
            // shadow it. The zero-init global matches the interp's default slot.
            if *shared && !*is_array {
                return;
            }
            // A module-shared array is a heap global (emit_globals, CGEN-SHARED-ARR).
            // Its bare `SHARED a[]` declaration is a no-op — a per-function reset
            // would clear data another function stored. A sized DIM/REDIM still
            // (re)allocates the global via the dyn arms below (is_dyn_array=true).
            if *is_array && crate::c_emit::is_shared_array(&symbol.name) && size.is_none() {
                return;
            }
            // Scalar DIM of a STRING name whose storage is a dyn/shared array
            // (flattened `HOST.alias$[]`): do not emit a shadowing `char*`.
            // Indexing that scalar made `host.alias[0]` a `char`.
            if !*is_array
                && size.is_none()
                && symbol.value_type == ValueType::String
                && crate::c_emit::is_dyn_array(&symbol.name)
                && !crate::c_emit::is_shared_dual(&symbol.name)
            {
                return;
            }
            // Multi-dim array (`DIM a[i,j,…]`): the interpreter flattens to a 1-D
            // store of ∏(dk+1) elements (slot.rs::new_array_nd). Allocate the same
            // flat count; `arr[i,j]` accesses compute the row-major offset. 1-D
            // arrays (empty `extra_dims`) fall through to the byte-identical path.
            if !extra_dims.is_empty() {
                if let Some(sz) = size {
                    let mut dims = vec![sz.clone()];
                    dims.extend(extra_dims.iter().cloned());
                    let dyn_array = crate::c_emit::is_dyn_array(&symbol.name);
                    // Emit per-dimension size variables for ATTACH stride computation.
                    let ident = crate::c_emit::array_ident(&symbol.name);
                    out.push_str(&ind);
                    out.push_str("intptr_t xb_dim_");
                    out.push_str(&ident);
                    out.push_str("_0 = ");
                    crate::c_emit_expr::emit_expr(sz, out);
                    out.push_str(";\n");
                    for (di, ed) in extra_dims.iter().enumerate() {
                        out.push_str(&ind);
                        out.push_str("intptr_t xb_dim_");
                        out.push_str(&ident);
                        out.push_str("_");
                        out.push_str(&(di + 1).to_string());
                        out.push_str(" = ");
                        crate::c_emit_expr::emit_expr(ed, out);
                        out.push_str(";\n");
                    }
                    if dyn_array {
                        out.push_str("xb_ub_");
                        out.push_str(&crate::c_emit::array_ident(&symbol.name));
                        out.push_str(" = ");
                        crate::c_emit::emit_flat_size(&dims, out);
                        out.push_str(" - 1;\n");
                        out.push_str(&ind);
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push_str(" = calloc((size_t)(xb_ub_");
                        out.push_str(&crate::c_emit::array_ident(&symbol.name));
                        out.push_str(" + 1), sizeof(*");
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push_str("));\n");
                    } else {
                        out.push_str(c_type(symbol.value_type));
                        out.push(' ');
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push('[');
                        crate::c_emit::emit_flat_size(&dims, out);
                        out.push_str("]; memset(");
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push_str(", 0, sizeof(");
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push_str("));\n");
                    }
                    if symbol.value_type == ValueType::String {
                        out.push_str(&ind);
                        out.push_str("for (intptr_t _i = 0; _i < ");
                        crate::c_emit::emit_flat_size(&dims, out);
                        out.push_str("; _i++) ");
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push_str("[_i] = xb_str(\"\");\n");
                    }
                    return;
                }
            }
            let dyn_array = crate::c_emit::is_dyn_array(&symbol.name);
            let dyn_scalar = crate::c_emit::is_dyn_scalar(&symbol.name);
            out.push_str(&ind);
            match size {
                Some(sz) if dyn_array && *redim => {
                    // Content-preserving REDIM: realloc keeps existing elements
                    // and the grown tail is default-filled, matching the interp's
                    // execute_dim resize (slot.rs). (First DIM is redim=false →
                    // the calloc arm below.) Block-scoped so `_oldub` never clashes.
                    let id = crate::c_emit::array_ident(&symbol.name);
                    out.push_str("{ intptr_t _oldub = xb_ub_");
                    out.push_str(&id);
                    out.push_str("; xb_ub_");
                    out.push_str(&id);
                    out.push_str(" = (");
                    emit_expr(sz, out);
                    out.push_str("); ");
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str(" = realloc(");
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str(", (size_t)(xb_ub_");
                    out.push_str(&id);
                    out.push_str(" + 1) * sizeof(*");
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str(")); for (intptr_t _i = _oldub + 1; _i <= xb_ub_");
                    out.push_str(&id);
                    out.push_str("; _i++) ");
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str("[_i] = ");
                    out.push_str(if symbol.value_type == ValueType::String {
                        "xb_str(\"\")"
                    } else {
                        "0"
                    });
                    out.push_str("; }\n");
                }
                Some(sz) if dyn_array => {
                    // Late/repeated `DIM`: the pointer + xb_ub_ var are hoisted;
                    // the `Dim` site (re)allocates, matching the interpreter's
                    // execute-time slot reset. (Repeated DIMs leak the old block —
                    // acceptable for demo lifetimes.)
                    out.push_str("xb_ub_");
                    out.push_str(&crate::c_emit::array_ident(&symbol.name));
                    out.push_str(" = (");
                    emit_expr(sz, out);
                    out.push_str(");\n");
                    out.push_str(&ind);
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str(" = calloc((size_t)(xb_ub_");
                    out.push_str(&crate::c_emit::array_ident(&symbol.name));
                    out.push_str(" + 1), sizeof(*");
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str("));\n");
                    if symbol.value_type == ValueType::String {
                        out.push_str(&ind);
                        out.push_str("for (intptr_t _i = 0; _i <= xb_ub_");
                        out.push_str(&crate::c_emit::array_ident(&symbol.name));
                        out.push_str("; _i++) ");
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push_str("[_i] = xb_str(\"\");\n");
                    }
                }
                Some(sz) => {
                    out.push_str(c_type(symbol.value_type));
                    out.push(' ');
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str("[(");
                    emit_expr(sz, out);
                    out.push_str(") + 1]; memset(");
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str(", 0, sizeof(");
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str("));\n");
                    if symbol.value_type == ValueType::String {
                        out.push_str(&ind);
                        out.push_str("for (int _i = 0; _i < (");
                        emit_expr(sz, out);
                        out.push_str(") + 1; _i++) ");
                        crate::c_emit::emit_array_var_name(symbol, out);
                        out.push_str("[_i] = xb_str(\"\");\n");
                    }
                }
                None if dyn_array && *is_array => {
                    // Late/repeated `DIM a[]`: reset the hoisted pointer to the
                    // empty state (UBOUND -1), like the interpreter's empty array.
                    out.push_str("xb_ub_");
                    out.push_str(&crate::c_emit::array_ident(&symbol.name));
                    out.push_str(" = -1;\n");
                    out.push_str(&ind);
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str(" = 0;\n");
                }
                None if *is_array => {
                    // `DIM a[]` — an empty growable array (UBOUND = -1). C has no
                    // growable storage (REDIM is CGEN-REDIM, still open); a 1-slot
                    // zeroed array at least compiles subscripts. Previously this
                    // mis-emitted a *scalar*, so any later `a[i]` failed cc.
                    out.push_str(c_type(symbol.value_type));
                    out.push(' ');
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str("[1];\n");
                    out.push_str(&ind);
                    crate::c_emit::emit_array_var_name(symbol, out);
                    out.push_str("[0] = ");
                    emit_default(symbol.value_type, out);
                    out.push_str(";\n");
                }
                None if dyn_scalar
                    || crate::c_emit::is_dual_use(&symbol.name)
                    || crate::c_emit::is_shared_dual(&symbol.name) =>
                {
                    // Late/repeated scalar `DIM`, or the scalar facet of a dual-use
                    // name (`emit_hoisted_scalars` already declared it at the top):
                    // the site resets to the default like the interpreter's fresh
                    // slot. A dual-use scalar `DIM` that re-declared here would be a
                    // C redefinition — a flattened composite array member DIM'd as
                    // a scalar but indexed as an array (`px3D.shape[i].x`).
                    emit_var_name(symbol, out);
                    out.push_str(" = ");
                    emit_default(symbol.value_type, out);
                    out.push_str(";\n");
                }
                None => {
                    out.push_str(c_type(symbol.value_type));
                    out.push(' ');
                    emit_var_name(symbol, out);
                    out.push_str(" = ");
                    emit_default(symbol.value_type, out);
                    out.push_str(";\n");
                }
            }
        }
        IrItem::Assignment { target, value } => {
            if let Some(chain) = collect_append_chain(target, value) {
                out.push_str(&ind);
                emit_var_name(target, out);
                out.push_str(" = ");
                let mut expr_str = String::new();
                expr_str.push_str("xb_append(");
                let mut target_buf = String::new();
                emit_var_name(target, &mut target_buf);
                expr_str.push_str(&target_buf);
                expr_str.push_str(", ");
                let mut part_buf = String::new();
                emit_expr(chain[0], &mut part_buf);
                expr_str.push_str(&part_buf);
                expr_str.push(')');
                for part in chain.iter().skip(1) {
                    let mut new_buf = String::new();
                    new_buf.push_str("xb_append(");
                    new_buf.push_str(&expr_str);
                    new_buf.push_str(", ");
                    let mut p2 = String::new();
                    emit_expr(part, &mut p2);
                    new_buf.push_str(&p2);
                    new_buf.push(')');
                    expr_str = new_buf;
                }
                out.push_str(&expr_str);
                out.push_str(";\n");
            } else {
                out.push_str(&ind);
                emit_var_name(target, out);
                out.push_str(" = ");
                // String Symbol copy must be deep (xb_strdup), not shallow pointer share,
                // otherwise xb_append's free/realloc will dangle aliases (xgr abort).
                if target.value_type == ValueType::String {
                    match &value.kind {
                        crate::ir::IrExprKind::Symbol(_)
                        | crate::ir::IrExprKind::SharedVariable(_) => {
                            out.push_str("xb_strdup(");
                            emit_expr(value, out);
                            out.push_str(")");
                        }
                        _ => emit_expr(value, out),
                    }
                } else {
                    emit_expr(value, out);
                }
                out.push_str(";\n");
            }
        }
        IrItem::ArrayAssignment {
            target,
            index,
            extra_indices,
            value,
        } => {
            if crate::c_emit::is_undimmed_array(&target.name) {
                // Write to a never-`Dim`'d array: the interpreter errors only when
                // this *executes* (UnknownSlot) — interpreter-clean programs never
                // reach it. Evaluate+discard the value so the statement compiles.
                out.push_str(&ind);
                out.push_str("(void)(");
                emit_expr(value, out);
                out.push_str(");\n");
                return;
            }
            // Dynamic arrays (heap pointer + ubound var): a write past the
            // current ubound auto-vivifies — grow to index+1 (preserving the
            // prefix), matching the interpreter. 1-D only; realloc(NULL,·)
            // covers the never-allocated case. Fixed native arrays keep the
            // bare subscript (OOB is a program error, as in C).
            let dyn_1d = crate::c_emit::is_dyn_array(&target.name)
                && extra_indices.is_empty()
                && !crate::c_emit::is_descriptor_param(&target.name);
            if dyn_1d {
                let mut idx_c = String::new();
                emit_expr(index, &mut idx_c);
                let ident = crate::c_emit::array_ident(&target.name);
                let ptr = if target.value_type == ValueType::String {
                    format!("xb_str_{ident}")
                } else {
                    format!("xb_var_{ident}")
                };
                let ub = format!("xb_ub_{ident}");
                let fill = if target.value_type == ValueType::String {
                    "xb_str(\"\")".to_string()
                } else {
                    "0".to_string()
                };
                out.push_str(&ind);
                out.push_str(&format!(
                    "if (({idx_c}) > {ub}) {{ intptr_t _oldub = {ub}; {ub} = ({idx_c}); \
                     {ptr} = realloc({ptr}, (size_t)({ub} + 1) * sizeof(*{ptr})); \
                     for (intptr_t _i = _oldub + 1; _i <= {ub}; _i++) {ptr}[_i] = {fill}; }}\n"
                ));
            }
            out.push_str(&ind);
            crate::c_emit::emit_array_var_name(target, out);
            out.push('[');
            crate::c_emit::emit_array_subscript(&target.name, index, extra_indices, out);
            out.push_str("] = ");
            emit_expr(value, out);
            out.push_str(";\n");
        }
        IrItem::MidAssign {
            target,
            start,
            length,
            value,
        } => {
            out.push_str(&ind);
            out.push_str("xb_mid_assign(");
            emit_expr(target, out);
            out.push_str(", ");
            emit_expr(start, out);
            out.push_str(", ");
            if let Some(len) = length {
                emit_expr(len, out);
            } else {
                out.push_str("-1");
            }
            out.push_str(", ");
            emit_expr(value, out);
            out.push_str(");\n");
        }
        IrItem::BuiltinAssign { name, args, value } => {
            out.push_str(&ind);
            // *AT assignment: the interpreter has no real memory — it no-ops the
            // write, evaluating only the value for side-effects/errors
            // (interpreter.rs BuiltinAssign). Match it: a real `*(T*)(addr)=v`
            // would dereference the stub-0 address and crash.
            if is_at_write_builtin(name) {
                out.push_str("(void)(");
                emit_expr(value, out);
                out.push_str(");\n");
            } else {
                // Fallback: function call style
                emit_c_function_name(name, out);
                out.push('(');
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    emit_expr(arg, out);
                }
                out.push_str(") = ");
                emit_expr(value, out);
                out.push_str(";\n");
            }
        }
        IrItem::ConstantDefinition { .. } => {}
        IrItem::SharedAssignment { target, value } => {
            if let Some(chain) = collect_append_chain(target, value) {
                out.push_str(&ind);
                out.push_str("xb_shared_");
                out.push_str(&crate::c_emit_expr::sanitize_c_ident(&target.name));
                out.push_str(" = ");
                let mut expr_str = String::new();
                expr_str.push_str("xb_append(xb_shared_");
                expr_str.push_str(&crate::c_emit_expr::sanitize_c_ident(&target.name));
                expr_str.push_str(", ");
                let mut part_buf = String::new();
                emit_expr(chain[0], &mut part_buf);
                expr_str.push_str(&part_buf);
                expr_str.push(')');
                for part in chain.iter().skip(1) {
                    let mut new_buf = String::new();
                    new_buf.push_str("xb_append(");
                    new_buf.push_str(&expr_str);
                    new_buf.push_str(", ");
                    let mut p2 = String::new();
                    emit_expr(part, &mut p2);
                    new_buf.push_str(&p2);
                    new_buf.push(')');
                    expr_str = new_buf;
                }
                out.push_str(&expr_str);
                out.push_str(";\n");
            } else {
                out.push_str(&ind);
                out.push_str("xb_shared_");
                out.push_str(&crate::c_emit_expr::sanitize_c_ident(&target.name));
                out.push_str(" = ");
                if target.value_type == ValueType::String {
                    match &value.kind {
                        crate::ir::IrExprKind::Symbol(_)
                        | crate::ir::IrExprKind::SharedVariable(_) => {
                            out.push_str("xb_strdup(");
                            emit_expr(value, out);
                            out.push_str(")");
                        }
                        _ => emit_expr(value, out),
                    }
                } else {
                    emit_expr(value, out);
                }
                out.push_str(";\n");
            }
        }
        IrItem::If {
            condition,
            then_body,
            else_body,
        } => {
            out.push_str(&ind);
            out.push_str("if (");
            emit_expr(condition, out);
            out.push_str(") {\n");
            emit_body(then_body, out, indent + 1);
            if let Some(eb) = else_body {
                out.push_str(&ind);
                out.push_str("} else {\n");
                emit_body(eb, out, indent + 1);
            }
            out.push_str(&ind);
            out.push_str("}\n");
        }
        IrItem::While { condition, body } => {
            out.push_str(&ind);
            out.push_str("while (");
            emit_expr(condition, out);
            out.push_str(") {\n");
            emit_body(body, out, indent + 1);
            out.push_str(&ind);
            out.push_str("}\n");
        }
        IrItem::DoLoop {
            pre_condition,
            post_condition,
            body,
        } => {
            match pre_condition {
                Some((cond, is_while)) => {
                    out.push_str(&ind);
                    out.push_str("while (");
                    if !*is_while {
                        out.push_str("!(");
                        emit_expr(cond, out);
                        out.push(')');
                    } else {
                        emit_expr(cond, out);
                    }
                    out.push_str(") {\n");
                }
                None => {
                    if post_condition.is_some() {
                        out.push_str(&ind);
                        out.push_str("do {\n");
                    } else {
                        out.push_str(&ind);
                        out.push_str("while (1) {\n");
                    }
                }
            }
            emit_body(body, out, indent + 1);
            let pre_is_some = pre_condition.is_some();
            match post_condition {
                Some((cond, is_while)) if pre_is_some => {
                    // `DO WHILE/UNTIL pre ... LOOP WHILE/UNTIL post`: C has no
                    // dual-condition loop. Emitting `} while (post);` here would
                    // detach the post condition into a separate empty statement
                    // (the `while (pre) {` opener already consumed the brace).
                    // Check it with a break instead.
                    out.push_str(&ind);
                    out.push_str("if (");
                    if *is_while {
                        out.push_str("!(");
                        emit_expr(cond, out);
                        out.push(')');
                    } else {
                        emit_expr(cond, out);
                    }
                    out.push_str(") break;\n");
                    out.push_str(&ind);
                    out.push_str("}\n");
                }
                Some((cond, is_while)) => {
                    out.push_str(&ind);
                    out.push_str("} while (");
                    if !*is_while {
                        out.push_str("!(");
                        emit_expr(cond, out);
                        out.push(')');
                    } else {
                        emit_expr(cond, out);
                    }
                    out.push_str(");\n");
                }
                None => {
                    out.push_str(&ind);
                    out.push_str("}\n");
                }
            }
        }
        IrItem::For {
            var,
            start,
            end,
            step,
            body,
        } => {
            out.push_str(&ind);
            out.push_str("for (");
            emit_var_name(var, out);
            out.push_str(" = ");
            emit_expr(start, out);
            out.push_str("; ");
            match step {
                Some(s) => {
                    let neg = matches!(
                        &s.kind,
                        crate::ir::IrExprKind::IntegerLiteral(v) if v.starts_with('-')
                    );
                    emit_var_name(var, out);
                    if neg {
                        out.push_str(" >= ");
                    } else {
                        out.push_str(" <= ");
                    }
                    emit_expr(end, out);
                    out.push_str("; ");
                    emit_var_name(var, out);
                    out.push_str(" += ");
                    emit_expr(s, out);
                }
                None => {
                    emit_var_name(var, out);
                    out.push_str(" <= ");
                    emit_expr(end, out);
                    out.push_str("; ");
                    emit_var_name(var, out);
                    out.push_str("++");
                }
            }
            out.push_str(") {\n");
            emit_body(body, out, indent + 1);
            out.push_str(&ind);
            out.push_str("}\n");
        }
        IrItem::Function { .. } => {}
        IrItem::Return { value } => {
            // Copy-out by-ref scalar params before returning, so their final
            // values reach the caller (CGEN-BYREF-WRITEBACK). No-op when the
            // function has no by-ref scalar param (every corpus/most demos).
            crate::c_emit::emit_byref_copy_out(out, indent);
            out.push_str(&ind);
            match value {
                Some(e) => {
                    out.push_str("return ");
                    emit_expr(e, out);
                    out.push_str(";\n");
                }
                None => out.push_str("return 0;\n"),
            }
        }
        IrItem::Call { name, args } => {
            let is_user_defined = crate::c_emit::is_defined_func(name);
            if !is_user_defined && name == "XstQuickSort" && args.len() == 5 {
                out.push_str(&ind);
                crate::c_emit_expr::emit_quicksort_call(args, out);
                out.push_str(";\n");
                return;
            }
            if !is_user_defined && name == "XstCopyArray" && args.len() == 2 {
                out.push_str(&ind);
                crate::c_emit_expr::emit_copyarray_call(args, out);
                out.push_str(";\n");
                return;
            }
            if !is_user_defined && name == "XgrProcessMessages" {
                // Headless: terminate immediately (exit 0) instead of hanging in
                // the event loop. Mirrors the interp's Quit { code: 0 }.
                out.push_str(&ind);
                out.push_str("xb_xgr_process_messages(");
                if !args.is_empty() {
                    crate::c_emit_expr::emit_expr(&args[0], out);
                } else {
                    out.push('0');
                }
                out.push_str(");\n");
                return;
            }
            if !is_user_defined && name == "WriteFile" && args.len() == 5 {
                out.push_str(&ind);
                crate::c_emit_expr::emit_expr(
                    &crate::ir::IrExpr {
                        kind: crate::ir::IrExprKind::FunctionCall {
                            name: name.clone(),
                            args: args.to_vec(),
                        },
                        value_type: ValueType::Integer,
                    },
                    out,
                );
                out.push_str(";\n");
                return;
            }
            if !is_user_defined && name == "ReadFile" && args.len() == 5 {
                out.push_str(&ind);
                crate::c_emit_expr::emit_expr(
                    &crate::ir::IrExpr {
                        kind: crate::ir::IrExprKind::FunctionCall {
                            name: name.clone(),
                            args: args.to_vec(),
                        },
                        value_type: ValueType::Integer,
                    },
                    out,
                );
                out.push_str(";\n");
                return;
            }
            if crate::c_emit::is_unknown_call(name) {
                // Unknown callee: no-op (interp/LLVM stub yields a discarded
                // zero-default, args skipped). Emitting nothing keeps undefined/
                // external statement calls (GUI Xgr*/Xui*, etc.) compiling.
                return;
            }
            if !is_user_defined && crate::c_emit::is_builtin_without_helper(name) {
                // Builtin with no emitter arm / C helper (maps to xb_user_*):
                // interp errors only if executed; no-op like the unknown stub.
                return;
            }
            if name == "INLINE$" {
                // Statement-position INLINE$ *does* print a literal prompt (the
                // interp's call.rs pushes it to the real output sink; expression
                // position discards it — see c_emit_expr). Result discarded.
                out.push_str(&ind);
                out.push_str("xb_inline(");
                match args.first().map(|a| &a.kind) {
                    Some(crate::ir::IrExprKind::StringLiteral(_)) => emit_expr(&args[0], out),
                    _ => out.push('0'),
                }
                out.push_str(");\n");
                return;
            }
            if is_user_defined {
                // RR-07: User-defined function takes precedence over builtin.
                out.push_str(&ind);
                out.push_str("xb_user_");
                out.push_str(name);
                out.push('(');
                crate::c_emit_expr::emit_call_args(name, args, out);
                out.push_str(");\n");
            } else {
                out.push_str(&ind);
                crate::c_emit_helpers::emit_c_function_name(name, out);
                out.push('(');
                crate::c_emit_expr::emit_call_args(name, args, out);
                out.push_str(");\n");
            }
        }
        IrItem::ExitLoop => {
            out.push_str(&ind);
            out.push_str("break;\n");
        }
        IrItem::ExitSelect => {
            let id = crate::c_emit_select::current_select_id();
            out.push_str(&ind);
            out.push_str(&format!("goto _exit_sel_{id};\n"));
        }
        IrItem::Swap { left, right } => {
            crate::c_emit_select::emit_swap(left, right, out, &ind);
        }
        IrItem::Nop => {}
        IrItem::Attach {
            left,
            left_indices,
            left_is_row,
            right,
            right_indices,
            right_is_row,
        } => {
            crate::c_emit_attach::emit_attach(
                left,
                left_indices,
                *left_is_row,
                right,
                right_indices,
                *right_is_row,
                out,
                &ind,
            );
        }
        IrItem::SelectCase {
            selector,
            cases,
            default,
        } => {
            crate::c_emit_select::emit_select_case(selector, cases, default.as_deref(), out, indent)
        }
        IrItem::Compound(items) => {
            for item in items {
                emit_item(item, out, indent);
            }
        }
        IrItem::Read(symbols) => crate::c_emit_data::emit_read(symbols, out, indent),
        IrItem::Restore(label) => crate::c_emit_data::emit_restore(label.as_deref(), out, indent),
        IrItem::Stop => {
            out.push_str(&ind);
            out.push_str("exit(0);\n");
        }
        IrItem::Label(name) => {
            out.push_str(&format!("xb_label_{}:\n", name));
        }
        IrItem::Goto(name) => {
            out.push_str(&ind);
            if crate::c_emit::fn_has_label(name) {
                out.push_str(&format!("goto xb_label_{};\n", name));
            } else {
                // GOTO to a label this C function does not contain: the interpreter
                // errors only if this executes; unreached in clean programs.
                out.push_str("(void)0; /* goto missing label */\n");
            }
        }
        IrItem::Gosub(name) => {
            if !crate::c_emit::fn_has_label(name) {
                out.push_str(&ind);
                out.push_str("(void)0; /* gosub missing label */\n");
                return;
            }
            // Return labels must be unique per C function: the first `GOSUB name`
            // keeps the historical `xb_gosub_ret_<name>` (byte-identity with cgen.x
            // on the shared corpus), repeats get `_2`, `_3`, …
            let suffix = crate::c_emit::gosub_ret_suffix(name);
            out.push_str(&ind);
            out.push_str(&format!(
                "xb_gosub_stack[xb_gosub_sp++] = &&xb_gosub_ret_{name}{suffix}; goto xb_label_{name};\n"
            ));
            out.push_str(&format!("xb_gosub_ret_{name}{suffix}:\n"));
        }
        IrItem::GosubReturn => {
            // Pop only this function's own GOSUB frames (sp > entry base); reaching
            // the base means a function-level `RETURN`, so return from the function
            // instead of jumping to a caller's gosub frame (CGEN-GOSUB-SCOPE).
            out.push_str(&ind);
            out.push_str(
                "if (xb_gosub_sp > xb_gosub_base) { goto *xb_gosub_stack[--xb_gosub_sp]; } return 0;\n",
            );
        }
        IrItem::GosubExpr(expr) => {
            // Same per-site uniqueness for the computed-GOSUB return label (two
            // `GOSUB @x` in one function previously collided on `xb_gosub_ret_expr`).
            // Guard with `if (_xb_ge)` so a 0 address (undimmed Sub[] / unregistered
            // message) is a no-op instead of `goto *(void*)0` → SIGSEGV, matching the
            // interpreter's RT-GOSUB-ZERO behavior.
            let suffix = crate::c_emit::gosub_ret_suffix(" expr");
            out.push_str(&ind);
            out.push_str("{ intptr_t _xb_ge = ");
            emit_expr(expr, out);
            out.push_str(&format!(
                "; if (_xb_ge) {{ xb_gosub_stack[xb_gosub_sp++] = &&xb_gosub_ret_expr{suffix}; goto *(void*)_xb_ge; }} xb_gosub_ret_expr{suffix}: (void)0; }}\n"
            ));
        }
        IrItem::GotoExpr(expr) => {
            out.push_str(&ind);
            out.push_str("goto *(void*)");
            emit_expr(expr, out);
            out.push_str(";\n");
        }
    }
}

/// Emit a `DIM`/`REDIM` of a descriptor by-ref array param — realloc the caller's
/// array through `*xb_var_x_d` and update `*xb_ub_x`. `REDIM` (`redim`) preserves
/// existing elements + default-fills the grown tail; `DIM` re-initializes every
/// element (matching the interpreter — docs/18).
fn emit_descriptor_redim(symbol: &IrSymbol, sz: &IrExpr, redim: bool, ind: &str, out: &mut String) {
    let ub = crate::c_emit::descriptor_ub_ident(&symbol.name);
    let mut dp = String::new();
    crate::c_emit::emit_descriptor_data_ptr(symbol, &mut dp);
    let dflt = if symbol.value_type == ValueType::String {
        "xb_str(\"\")"
    } else {
        "0"
    };
    out.push_str(ind);
    out.push_str("{ ");
    if redim {
        out.push_str("intptr_t _oldub = *");
        out.push_str(&ub);
        out.push_str("; ");
    }
    out.push('*');
    out.push_str(&ub);
    out.push_str(" = (");
    emit_expr(sz, out);
    out.push_str("); *");
    out.push_str(&dp);
    out.push_str(" = realloc(*");
    out.push_str(&dp);
    out.push_str(", (size_t)(*");
    out.push_str(&ub);
    out.push_str(" + 1) * sizeof(**");
    out.push_str(&dp);
    out.push_str(")); for (intptr_t _i = ");
    out.push_str(if redim { "_oldub + 1" } else { "0" });
    out.push_str("; _i <= *");
    out.push_str(&ub);
    out.push_str("; _i++) (*");
    out.push_str(&dp);
    out.push_str(")[_i] = ");
    out.push_str(dflt);
    out.push_str("; }\n");
}

pub(crate) fn is_at_write_builtin(name: &str) -> bool {
    matches!(
        name,
        "SBYTEAT"
            | "UBYTEAT"
            | "SSHORTAT"
            | "USHORTAT"
            | "SLONGAT"
            | "ULONGAT"
            | "XLONGAT"
            | "GIANTAT"
            | "SINGLEAT"
            | "DOUBLEAT"
            | "SUBADDRAT"
            | "GOADDRAT"
    )
}

pub(crate) fn at_write_ctype(name: &str) -> (&'static str, bool) {
    match name {
        "SBYTEAT" => ("signed char", false),
        "UBYTEAT" => ("unsigned char", false),
        "SSHORTAT" => ("signed short", false),
        "USHORTAT" => ("unsigned short", false),
        "SLONGAT" => ("signed int", false),
        "ULONGAT" => ("unsigned int", false),
        "XLONGAT" => ("intptr_t", false),
        "GIANTAT" => ("intptr_t", false),
        "SINGLEAT" => ("float", true),
        "DOUBLEAT" => ("double", true),
        "SUBADDRAT" => ("intptr_t", false),
        "GOADDRAT" => ("intptr_t", false),
        _ => ("int", false),
    }
}
