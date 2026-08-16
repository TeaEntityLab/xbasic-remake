use crate::c_emit_expr::emit_expr;
use crate::ir::IrExpr;

fn bit_op_c_name(name: &str) -> &'static str {
    match name {
        "BITFIELD" => "xb_bitfield",
        "EXTS" => "xb_exts",
        "EXTU" => "xb_extu",
        "CLR" => "xb_clr",
        "SET" => "xb_set",
        "MAKE" => "xb_make",
        "HIGH0" => "xb_high0",
        "HIGH1" => "xb_high1",
        "GHIGH" => "xb_ghigh",
        "GLOW" => "xb_glow",
        "SIGN" => "xb_sign",
        _ => unreachable!(),
    }
}

pub(crate) fn emit_bit_op_call(name: &str, args: &[IrExpr], out: &mut String) {
    out.push_str(bit_op_c_name(name));
    out.push('(');
    for (i, arg) in args.iter().enumerate() {
        if i > 0 {
            out.push_str(", ");
        }
        emit_expr(arg, out);
    }
    if args.len() == 2 {
        out.push_str(", -99999");
    }
    out.push(')');
}
