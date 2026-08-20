use crate::c_emit::c_type;
use crate::c_emit_expr::{emit_default, emit_expr, emit_var_name};
use crate::c_emit_helpers::emit_c_function_name;
use crate::c_emit_select::emit_body;
use crate::ir::IrItem;
use crate::ValueType;
pub(crate) fn emit_item(item: &IrItem, out: &mut String, indent: usize) {
    let ind = "    ".repeat(indent);
    match item {
        IrItem::Version(_) | IrItem::ProgramName(_) => {}
        IrItem::Print { items, separators } => {
            crate::c_emit_select::emit_print(items, separators, out, indent);
        }
        IrItem::Dim { symbol, size, is_array, .. } => {
            // A `Dim` of a name that is already a function parameter is a no-op
            // in C (the param is already declared); emitting it would be a
            // redefinition. The interpreter's execute_dim would reset the slot,
            // but for demo lifetimes this is safe.
            if crate::c_emit::is_fn_param(&symbol.name) {
                return;
            }
            let dyn_array = crate::c_emit::is_dyn_array(&symbol.name);
            let dyn_scalar = crate::c_emit::is_dyn_scalar(&symbol.name);
            out.push_str(&ind);
            match size {
                Some(sz) if dyn_array => {
                    // Late/repeated `DIM`: the pointer + xb_ub_ var are hoisted;
                    // the `Dim` site (re)allocates, matching the interpreter's
                    // execute-time slot reset. (Repeated DIMs leak the old block —
                    // acceptable for demo lifetimes.)
                    out.push_str("xb_ub_");
                    out.push_str(&crate::c_emit_expr::sanitize_c_ident(&symbol.name));
                    out.push_str(" = (");
                    emit_expr(sz, out);
                    out.push_str(");\n");
                    out.push_str(&ind);
                    emit_var_name(symbol, out);
                    out.push_str(" = calloc((size_t)(xb_ub_");
                    out.push_str(&crate::c_emit_expr::sanitize_c_ident(&symbol.name));
                    out.push_str(" + 1), sizeof(*");
                    emit_var_name(symbol, out);
                    out.push_str("));\n");
                    if symbol.value_type == ValueType::String {
                        out.push_str(&ind);
                        out.push_str("for (intptr_t _i = 0; _i <= xb_ub_");
                        out.push_str(&crate::c_emit_expr::sanitize_c_ident(&symbol.name));
                        out.push_str("; _i++) ");
                        emit_var_name(symbol, out);
                        out.push_str("[_i] = xb_str(\"\");\n");
                    }
                }
                Some(sz) => {
                    out.push_str(c_type(symbol.value_type));
                    out.push(' ');
                    emit_var_name(symbol, out);
                    out.push_str("[(");
                    emit_expr(sz, out);
                    out.push_str(") + 1];\n");
                    if symbol.value_type == ValueType::String {
                        out.push_str(&ind);
                        out.push_str("for (int _i = 0; _i < (");
                        emit_expr(sz, out);
                        out.push_str(") + 1; _i++) ");
                        emit_var_name(symbol, out);
                        out.push_str("[_i] = xb_str(\"\");\n");
                    }
                }
                None if *is_array && dyn_array => {
                    // Late/repeated `DIM a[]`: reset the hoisted pointer to the
                    // empty state (UBOUND -1), like the interpreter's empty array.
                    out.push_str("xb_ub_");
                    out.push_str(&crate::c_emit_expr::sanitize_c_ident(&symbol.name));
                    out.push_str(" = -1;\n");
                    out.push_str(&ind);
                    emit_var_name(symbol, out);
                    out.push_str(" = 0;\n");
                }
                None if *is_array => {
                    // `DIM a[]` — an empty growable array (UBOUND = -1). C has no
                    // growable storage (REDIM is CGEN-REDIM, still open); a 1-slot
                    // zeroed array at least compiles subscripts. Previously this
                    // mis-emitted a *scalar*, so any later `a[i]` failed cc.
                    out.push_str(c_type(symbol.value_type));
                    out.push(' ');
                    emit_var_name(symbol, out);
                    out.push_str("[1];\n");
                    out.push_str(&ind);
                    emit_var_name(symbol, out);
                    out.push_str("[0] = ");
                    emit_default(symbol.value_type, out);
                    out.push_str(";\n");
                }
                None if dyn_scalar => {
                    // Late/repeated scalar `DIM`: declaration hoisted; the site
                    // resets to the default like the interpreter's fresh slot.
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
            out.push_str(&ind);
            emit_var_name(target, out);
            out.push_str(" = ");
            emit_expr(value, out);
            out.push_str(";\n");
        }
        IrItem::ArrayAssignment {
            target,
            index,
            value,
            ..
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
            out.push_str(&ind);
            emit_var_name(target, out);
            out.push('[');
            emit_expr(index, out);
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
                out.push_str("(");
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
            out.push_str(&ind);
            out.push_str("xb_shared_");
            out.push_str(&target.name.replace('.', "_").replace('$', "_s").replace('!', "_f").replace('#', "_d"));
            out.push_str(" = ");
            emit_expr(value, out);
            out.push_str(";\n");
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
            match post_condition {
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
            if crate::c_emit::is_unknown_call(name) {
                // Unknown callee: no-op (interp/LLVM stub yields a discarded
                // zero-default, args skipped). Emitting nothing keeps undefined/
                // external statement calls (GUI Xgr*/Xui*, etc.) compiling.
                return;
            }
            if crate::c_emit::is_builtin_without_helper(name) {
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
            out.push_str(&ind);
            crate::c_emit_helpers::emit_c_function_name(name, out);
            out.push('(');
            crate::c_emit_expr::emit_call_args(name, args, out);
            out.push_str(");\n");
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
            out.push_str(&ind);
            out.push_str(
                "if (xb_gosub_sp > 0) { goto *xb_gosub_stack[--xb_gosub_sp]; } return 0;\n",
            );
        }
        IrItem::GosubExpr(expr) => {
            // Same per-site uniqueness for the computed-GOSUB return label (two
            // `GOSUB @x` in one function previously collided on `xb_gosub_ret_expr`).
            let suffix = crate::c_emit::gosub_ret_suffix(" expr");
            out.push_str(&ind);
            out.push_str(&format!(
                "xb_gosub_stack[xb_gosub_sp++] = &&xb_gosub_ret_expr{suffix}; goto *(void*)"
            ));
            emit_expr(expr, out);
            out.push_str(&format!("; xb_gosub_ret_expr{suffix}: (void)0;\n"));
        }
        IrItem::GotoExpr(expr) => {
            out.push_str(&ind);
            out.push_str("goto *(void*)");
            emit_expr(expr, out);
            out.push_str(";\n");
        }
    }
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
