use crate::ir::IrExpr;

/// Emits C code for HEXX$(value[, width]). 1-arg form passes width=0.
pub(crate) fn emit_hexx(args: &[IrExpr], out: &mut String, emit_fn: impl Fn(&IrExpr, &mut String)) {
    out.push_str("xb_hexx(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    if args.len() == 2 {
        emit_fn(&args[1], out);
    } else {
        out.push('0');
    }
    out.push(')');
}

/// Emits C code for 2-arg HEX$(value, width) -> xb_hex2(value, width).
#[allow(dead_code)]
pub(crate) fn emit_hex2(args: &[IrExpr], out: &mut String, emit_fn: impl Fn(&IrExpr, &mut String)) {
    out.push_str("xb_hex2(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    emit_fn(&args[1], out);
    out.push(')');
}

/// Emits C code for STUFF$(into$, from$, start[, length]).
pub(crate) fn emit_stuff(
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) {
    out.push_str("xb_stuff(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    emit_fn(&args[1], out);
    out.push_str(", ");
    emit_fn(&args[2], out);
    out.push_str(", ");
    if args.len() == 4 {
        emit_fn(&args[3], out);
    } else {
        out.push_str("-1");
    }
    out.push(')');
}

/// Emits C code for RCLIP$/LCLIP$(s$[, n]). 1-arg -> trim, 2-arg -> remove N chars.
pub(crate) fn emit_clip(
    name: &str,
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) {
    let func = if args.len() == 2 {
        if name == "RCLIP$" {
            "xb_rclip2"
        } else {
            "xb_lclip2"
        }
    } else if name == "RCLIP$" {
        "xb_rclip1"
    } else {
        "xb_lclip1"
    };
    out.push_str(func);
    out.push('(');
    emit_fn(&args[0], out);
    if args.len() == 2 {
        out.push_str(", ");
        emit_fn(&args[1], out);
    }
    out.push(')');
}

/// Emits C code for 2-arg MID$(s$, start) -> xb_mid2(s, start).
pub(crate) fn emit_mid2(args: &[IrExpr], out: &mut String, emit_fn: impl Fn(&IrExpr, &mut String)) {
    out.push_str("xb_mid2(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    emit_fn(&args[1], out);
    out.push(')');
}

/// Emits 2-arg BIN$/BINB$/OCT$/OCTO$ as funcname(value, digits).
pub(crate) fn emit_int2str2(
    func: &str,
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) {
    out.push_str(func);
    out.push('(');
    emit_fn(&args[0], out);
    out.push_str(", ");
    emit_fn(&args[1], out);
    out.push(')');
}

/// Returns true and emits if `name` is a 2-arg BIN$/BINB$/OCT$/OCTO$ call.
pub(crate) fn try_emit_int2str2(
    name: &str,
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) -> bool {
    let func = match name {
        "BINB$" if args.len() == 2 => "xb_binb2",
        "BIN$" if args.len() == 2 => "xb_bin2",
        "OCTO$" if args.len() == 2 => "xb_octo2",
        "OCT$" if args.len() == 2 => "xb_oct2",
        "HEX$" if args.len() == 2 => "xb_hex2",
        _ => return false,
    };
    emit_int2str2(func, args, out, emit_fn);
    true
}

/// Returns true and emits if `name` is FORMAT$.
pub(crate) fn try_emit_format(
    name: &str,
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) -> bool {
    if name != "FORMAT$" {
        return false;
    }
    emit_format(args, out, emit_fn);
    true
}

/// Emits FORMAT$(fmt$, arg) with type-dispatched C call.
pub(crate) fn emit_format(
    args: &[IrExpr],
    out: &mut String,
    emit_fn: impl Fn(&IrExpr, &mut String),
) {
    use crate::ValueType;
    out.push_str("xb_format(");
    emit_fn(&args[0], out);
    out.push_str(", ");
    match args[1].value_type {
        ValueType::String => {
            out.push_str("xb_strdup(");
            emit_fn(&args[1], out);
            out.push_str("), 0, 0.0, 0, 1");
        }
        ValueType::Float => {
            out.push_str("NULL, 0, ");
            emit_fn(&args[1], out);
            out.push_str(", 1, 0");
        }
        ValueType::Integer => {
            out.push_str("NULL, ");
            emit_fn(&args[1], out);
            out.push_str(", 0.0, 0, 0");
        }
    }
    out.push(')');
}
