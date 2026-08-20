use crate::checked::{BooleanOp, LogicalOp};
use crate::ir::{IrExpr, IrExprKind, IrSymbol};
use crate::text_ir_parser_helpers::{
    extract_parens, infer_arith_type, parse_arith_op, parse_cmp_op, parse_rust_string,
    parse_symbol, parse_type,
};
use crate::ValueType;

pub(crate) fn parse_expr(s: &str) -> Result<IrExpr, String> {
    let (expr, rest) = parse_sub_expr(s)?;
    let rest = rest.trim();
    if !rest.is_empty() {
        return Err(format!("trailing content after expression: {rest}"));
    }
    Ok(expr)
}

fn parse_sub_expr(s: &str) -> Result<(IrExpr, &str), String> {
    let s = s.trim_start();
    let paren_pos = s.find('(').ok_or_else(|| format!("no '(' in: {s}"))?;
    let type_prefix = s[..paren_pos].trim();
    let after_paren = &s[paren_pos + 1..];
    if let Some(name) = type_prefix.strip_prefix("call ") {
        let name = name.trim();
        let (content, rest) = extract_parens(after_paren)?;
        let args = parse_args(content)?;
        let vt = if name.ends_with('$') {
            ValueType::String
        } else if name == "ABS" && !args.is_empty() {
            args[0].value_type
        } else {
            crate::builtin::builtin_return_type(name).unwrap_or(ValueType::Integer)
        };
        return Ok((
            IrExpr::new(
                IrExprKind::FunctionCall {
                    name: name.to_string(),
                    args,
                },
                vt,
            ),
            rest,
        ));
    }
    let (content, rest) = extract_parens(after_paren)?;
    let result = match type_prefix {
        "string" => {
            let value = parse_rust_string(content.trim())?;
            IrExpr::new(IrExprKind::StringLiteral(value), ValueType::String)
        }
        "integer" => IrExpr::new(
            IrExprKind::IntegerLiteral(content.trim().to_string()),
            ValueType::Integer,
        ),
        "float" => IrExpr::new(
            IrExprKind::FloatLiteral(content.trim().to_string()),
            ValueType::Float,
        ),
        "symbol" => {
            let (name, vt) = parse_symbol(content.trim())?;
            IrExpr::new(
                IrExprKind::Symbol(IrSymbol {
                    name,
                    value_type: vt,
                }),
                vt,
            )
        }
        "byref" => {
            let inner = parse_expr(content.trim())?;
            let vt = inner.value_type;
            IrExpr::new(IrExprKind::ByRef(Box::new(inner)), vt)
        }
        "shared" => {
            let c = content.trim();
            let name = c.strip_prefix("##").ok_or("missing ## in shared")?;
            let (name, vt) = parse_symbol(name)?;
            IrExpr::new(
                IrExprKind::SharedVariable(IrSymbol {
                    name,
                    value_type: vt,
                }),
                vt,
            )
        }
        "constant" => {
            let c = content.trim();
            let name = c.strip_prefix("$$").ok_or("missing $$ in constant")?;
            let colon = name.find(':').ok_or("missing : in constant")?;
            let const_name = &name[..colon];
            let after = &name[colon + 1..];
            let eq = after.find('=').ok_or("missing = in constant")?;
            let vt = parse_type(after[..eq].trim())?;
            let val_str = after[eq + 1..].trim();
            let (val_expr, _) = parse_sub_expr(val_str)?;
            let value = match val_expr.kind {
                IrExprKind::IntegerLiteral(v) => v,
                _ => return Err("constant value is not integer".into()),
            };
            IrExpr::new(
                IrExprKind::Constant {
                    name: const_name.to_string(),
                    value,
                },
                vt,
            )
        }
        "compare" => {
            let (left, al) = parse_sub_expr(content)?;
            let (op, ao) = parse_cmp_op(al.trim_start())?;
            let (right, _) = parse_sub_expr(ao.trim_start())?;
            IrExpr::new(
                IrExprKind::Comparison {
                    op,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                ValueType::Integer,
            )
        }
        "arith" => {
            let (left, al) = parse_sub_expr(content)?;
            let (op, ao) = parse_arith_op(al.trim_start())?;
            let (right, _) = parse_sub_expr(ao.trim_start())?;
            let vt = infer_arith_type(op, &left, &right);
            IrExpr::new(
                IrExprKind::Arithmetic {
                    op,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                vt,
            )
        }
        "not" => {
            let (inner, _) = parse_sub_expr(content)?;
            IrExpr::new(IrExprKind::Not(Box::new(inner)), ValueType::Integer)
        }
        "neg" => {
            let (inner, _) = parse_sub_expr(content)?;
            let vt = inner.value_type;
            IrExpr::new(
                IrExprKind::Unary {
                    op: xb_frontend::UnaryOp::Neg,
                    operand: Box::new(inner),
                },
                vt,
            )
        }
        "pos" => {
            let (inner, _) = parse_sub_expr(content)?;
            let vt = inner.value_type;
            IrExpr::new(
                IrExprKind::Unary {
                    op: xb_frontend::UnaryOp::Pos,
                    operand: Box::new(inner),
                },
                vt,
            )
        }
        "and" => {
            let (left, al) = parse_sub_expr(content)?;
            let (right, _) = parse_sub_expr(al.trim_start())?;
            IrExpr::new(
                IrExprKind::Boolean {
                    op: BooleanOp::And,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                ValueType::Integer,
            )
        }
        "or" => {
            let (left, al) = parse_sub_expr(content)?;
            let (right, _) = parse_sub_expr(al.trim_start())?;
            IrExpr::new(
                IrExprKind::Boolean {
                    op: BooleanOp::Or,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                ValueType::Integer,
            )
        }
        "xor" => {
            let (left, al) = parse_sub_expr(content)?;
            let (right, _) = parse_sub_expr(al.trim_start())?;
            IrExpr::new(
                IrExprKind::Boolean {
                    op: BooleanOp::Xor,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                ValueType::Integer,
            )
        }
        "land" => {
            let (left, al) = parse_sub_expr(content)?;
            let (right, _) = parse_sub_expr(al.trim_start())?;
            IrExpr::new(
                IrExprKind::Logical {
                    op: LogicalOp::And,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                ValueType::Integer,
            )
        }
        "lor" => {
            let (left, al) = parse_sub_expr(content)?;
            let (right, _) = parse_sub_expr(al.trim_start())?;
            IrExpr::new(
                IrExprKind::Logical {
                    op: LogicalOp::Or,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                ValueType::Integer,
            )
        }
        "lxor" => {
            let (left, al) = parse_sub_expr(content)?;
            let (right, _) = parse_sub_expr(al.trim_start())?;
            IrExpr::new(
                IrExprKind::Logical {
                    op: LogicalOp::Xor,
                    left: Box::new(left),
                    right: Box::new(right),
                },
                ValueType::Integer,
            )
        }
        "array_access" => {
            let bracket = content.find('[').ok_or("missing [ in array_access")?;
            let (name, vt) = parse_symbol(content[..bracket].trim())?;
            let idx_part = &content[bracket + 1..];
            let rbracket = idx_part.rfind(']').ok_or("missing ] in array_access")?;
            let mut idxs = parse_args(&idx_part[..rbracket])?;
            if idxs.is_empty() {
                return Err("empty index in array_access".into());
            }
            let index = idxs.remove(0);
            IrExpr::new(
                IrExprKind::ArrayAccess {
                    symbol: IrSymbol {
                        name,
                        value_type: vt,
                    },
                    index: Box::new(index),
                    extra_indices: idxs,
                },
                vt,
            )
        }
        "array_ubound" => {
            let (name, vt) = parse_symbol(content.trim())?;
            IrExpr::new(
                IrExprKind::ArrayUBound {
                    symbol: IrSymbol {
                        name,
                        value_type: vt,
                    },
                },
                ValueType::Integer,
            )
        }
        "funcaddr" => IrExpr::new(
            IrExprKind::FuncAddr(content.trim().to_string()),
            ValueType::Integer,
        ),
        "size_of" => {
            let (name, vt) = parse_symbol(content.trim())?;
            IrExpr::new(
                IrExprKind::SizeOf {
                    symbol: IrSymbol {
                        name,
                        value_type: vt,
                    },
                },
                ValueType::Integer,
            )
        }
        "size_of_type" => {
            let vt = match content.trim() {
                "integer" => ValueType::Integer,
                "float" => ValueType::Float,
                "string" => ValueType::String,
                _ => return Err(format!("unknown type in size_of_type: {content}")),
            };
            IrExpr::new(
                IrExprKind::SizeOfType { value_type: vt },
                ValueType::Integer,
            )
        }
        "label_addr" => IrExpr::new(
            IrExprKind::LabelAddress(content.trim().to_string()),
            ValueType::Integer,
        ),
        _ => return Err(format!("unknown expression type: {type_prefix}")),
    };
    Ok((result, rest))
}

pub(crate) fn parse_args(s: &str) -> Result<Vec<IrExpr>, String> {
    let s = s.trim();
    if s.is_empty() {
        return Ok(Vec::new());
    }
    let mut args = Vec::new();
    let mut remaining = s;
    loop {
        let (arg, rest) = parse_sub_expr(remaining)?;
        args.push(arg);
        remaining = rest.trim_start();
        if let Some(r) = remaining.strip_prefix(',') {
            remaining = r.trim_start();
        } else {
            break;
        }
    }
    Ok(args)
}
