use crate::ir::{IrExprKind, IrItem};
use crate::text_ir_parser_expr::parse_expr;
use crate::text_ir_parser_helpers::{parse_params, parse_symbol_decl, parse_type};

use crate::text_ir_parser::{err, parse_items, parse_loop_condition, TextIrParseError};

pub(crate) fn parse_item(
    content: &str,
    lines: &[&str],
    idx: &mut usize,
    indent: usize,
) -> Result<IrItem, TextIrParseError> {
    *idx += 1;
    let l = *idx;
    if let Some(v) = content.strip_prefix("version ") {
        return Ok(IrItem::Version(v.to_string()));
    }
    if let Some(rest) = content.strip_prefix("print ") {
        let (items, separators) = crate::text_ir_parser_select::parse_print_items(rest, l)?;
        return Ok(IrItem::Print { items, separators });
    }
    if let Some(rest) = content.strip_prefix("dim ") {
        if let Some(br) = rest.find('[') {
            let sym = parse_symbol_decl(rest[..br].trim()).map_err(|e| err(e, l))?;
            let rb = rest.rfind(']').ok_or_else(|| err("missing ]".into(), l))?;
            let sz = parse_expr(&rest[br + 1..rb]).map_err(|e| err(e, l))?;
            return Ok(IrItem::Dim {
                symbol: sym,
                size: Some(sz),
            });
        }
        let sym = parse_symbol_decl(rest.trim()).map_err(|e| err(e, l))?;
        return Ok(IrItem::Dim {
            symbol: sym,
            size: None,
        });
    }
    if let Some(rest) = content.strip_prefix("assign ") {
        let eq = rest
            .find(" = ")
            .ok_or_else(|| err("missing = in assign".into(), l))?;
        let tgt = parse_symbol_decl(rest[..eq].trim()).map_err(|e| err(e, l))?;
        let val = parse_expr(&rest[eq + 3..]).map_err(|e| err(e, l))?;
        return Ok(IrItem::Assignment {
            target: tgt,
            value: val,
        });
    }
    if let Some(rest) = content.strip_prefix("array_assign ") {
        let br = rest.find('[').ok_or_else(|| err("missing [".into(), l))?;
        let tgt = parse_symbol_decl(rest[..br].trim()).map_err(|e| err(e, l))?;
        let rb = rest
            .find("] = ")
            .ok_or_else(|| err("missing ] =".into(), l))?;
        let idx_e = parse_expr(&rest[br + 1..rb]).map_err(|e| err(e, l))?;
        let val = parse_expr(&rest[rb + 4..]).map_err(|e| err(e, l))?;
        return Ok(IrItem::ArrayAssignment {
            target: tgt,
            index: idx_e,
            value: val,
        });
    }
    if let Some(rest) = content.strip_prefix("const ") {
        let name = rest
            .strip_prefix("$$")
            .ok_or_else(|| err("missing $$".into(), l))?;
        let colon = name
            .find(':')
            .ok_or_else(|| err("missing : in const".into(), l))?;
        let cn = name[..colon].to_string();
        let after = &name[colon + 1..];
        let eq = after
            .find(" = ")
            .ok_or_else(|| err("missing = in const".into(), l))?;
        let vt = parse_type(after[..eq].trim()).map_err(|e| err(e, l))?;
        let vs = after[eq + 3..].trim();
        let val = vs
            .strip_prefix("integer(")
            .and_then(|s| s.strip_suffix(')'))
            .ok_or_else(|| err("const value not integer()".into(), l))?;
        return Ok(IrItem::ConstantDefinition {
            name: cn,
            value: val.to_string(),
            value_type: vt,
        });
    }
    if let Some(rest) = content.strip_prefix("shared ") {
        let name = rest
            .strip_prefix("##")
            .ok_or_else(|| err("missing ##".into(), l))?;
        let eq = name
            .find(" = ")
            .ok_or_else(|| err("missing = in shared".into(), l))?;
        let tgt = parse_symbol_decl(name[..eq].trim()).map_err(|e| err(e, l))?;
        let val = parse_expr(&name[eq + 3..]).map_err(|e| err(e, l))?;
        return Ok(IrItem::SharedAssignment {
            target: tgt,
            value: val,
        });
    }
    if let Some(rest) = content.strip_prefix("if ") {
        let cond = parse_expr(rest).map_err(|e| err(e, l))?;
        let then_body = parse_items(lines, idx, indent + 1)?;
        let else_body = if *idx < lines.len() && lines[*idx].trim() == "else" {
            *idx += 1;
            Some(parse_items(lines, idx, indent + 1)?)
        } else {
            None
        };
        if *idx >= lines.len() || lines[*idx].trim() != "end if" {
            return Err(err("expected 'end if'".into(), l));
        }
        *idx += 1;
        return Ok(IrItem::If {
            condition: cond,
            then_body,
            else_body,
        });
    }
    if let Some(rest) = content.strip_prefix("while ") {
        let cond = parse_expr(rest).map_err(|e| err(e, l))?;
        let body = parse_items(lines, idx, indent + 1)?;
        if *idx >= lines.len() || lines[*idx].trim() != "wend" {
            return Err(err("expected 'wend'".into(), l));
        }
        *idx += 1;
        return Ok(IrItem::While {
            condition: cond,
            body,
        });
    }
    if content == "do" {
        let body = parse_items(lines, idx, indent + 1)?;
        let post = parse_loop_condition(lines, idx, l)?;
        return Ok(IrItem::DoLoop {
            pre_condition: None,
            post_condition: post,
            body,
        });
    }
    if let Some(rest) = content.strip_prefix("do while ") {
        let cond = parse_expr(rest).map_err(|e| err(e, l))?;
        let body = parse_items(lines, idx, indent + 1)?;
        let post = parse_loop_condition(lines, idx, l)?;
        return Ok(IrItem::DoLoop {
            pre_condition: Some((cond, true)),
            post_condition: post,
            body,
        });
    }
    if let Some(rest) = content.strip_prefix("do until ") {
        let cond = parse_expr(rest).map_err(|e| err(e, l))?;
        let body = parse_items(lines, idx, indent + 1)?;
        let post = parse_loop_condition(lines, idx, l)?;
        return Ok(IrItem::DoLoop {
            pre_condition: Some((cond, false)),
            post_condition: post,
            body,
        });
    }
    if let Some(rest) = content.strip_prefix("for ") {
        let eq = rest
            .find(" = ")
            .ok_or_else(|| err("missing = in for".into(), l))?;
        let var = parse_symbol_decl(rest[..eq].trim()).map_err(|e| err(e, l))?;
        let after = &rest[eq + 3..];
        let to = after
            .find(" to ")
            .ok_or_else(|| err("missing to".into(), l))?;
        let start = parse_expr(&after[..to]).map_err(|e| err(e, l))?;
        let after_to = &after[to + 4..];
        let (end_str, step) = if let Some(sp) = after_to.find(" step ") {
            let end = parse_expr(&after_to[..sp]).map_err(|e| err(e, l))?;
            let s = parse_expr(&after_to[sp + 6..]).map_err(|e| err(e, l))?;
            (end, Some(s))
        } else {
            (parse_expr(after_to).map_err(|e| err(e, l))?, None)
        };
        let body = parse_items(lines, idx, indent + 1)?;
        if *idx >= lines.len() || lines[*idx].trim() != "next" {
            return Err(err("expected 'next'".into(), l));
        }
        *idx += 1;
        return Ok(IrItem::For {
            var,
            start,
            end: end_str,
            step,
            body,
        });
    }
    if let Some(rest) = content.strip_prefix("function ") {
        let paren = rest
            .find('(')
            .ok_or_else(|| err("missing ( in function".into(), l))?;
        let name = rest[..paren].to_string();
        let rparen = rest
            .find(')')
            .ok_or_else(|| err("missing ) in function".into(), l))?;
        let params = parse_params(&rest[paren + 1..rparen]).map_err(|e| err(e, l))?;
        let arrow = rest
            .find("-> ")
            .ok_or_else(|| err("missing ->".into(), l))?;
        let rt = parse_type(rest[arrow + 3..].trim()).map_err(|e| err(e, l))?;
        let body = parse_items(lines, idx, indent + 1)?;
        if *idx >= lines.len() || lines[*idx].trim() != "end function" {
            return Err(err("expected 'end function'".into(), l));
        }
        *idx += 1;
        return Ok(IrItem::Function {
            name,
            params,
            return_type: rt,
            body,
        });
    }
    if content == "return" {
        return Ok(IrItem::Return { value: None });
    }
    if let Some(rest) = content.strip_prefix("return ") {
        let val = parse_expr(rest).map_err(|e| err(e, l))?;
        return Ok(IrItem::Return { value: Some(val) });
    }
    match content {
        "exit_loop" => return Ok(IrItem::ExitLoop),
        "exit_select" => return Ok(crate::text_ir_parser_data::parse_exit_select()),
        "stop" => return Ok(crate::text_ir_parser_data::parse_stop()),
        _ => {}
    }
    if let Some(rest) = content.strip_prefix("swap ") {
        let parts: Vec<&str> = rest.splitn(2, ' ').collect();
        if parts.len() == 2 {
            let left = parse_symbol_decl(parts[0]).map_err(|e| err(e, l))?;
            let right = parse_symbol_decl(parts[1]).map_err(|e| err(e, l))?;
            return Ok(IrItem::Swap { left, right });
        }
    }
    if let Some(rest) = content.strip_prefix("read ") {
        return Ok(crate::text_ir_parser_data::parse_read(rest, l)?);
    }
    if let Some(rest) = content.strip_prefix("restore") {
        return Ok(crate::text_ir_parser_data::parse_restore(rest));
    }
    if content.starts_with("select_case ") {
        return crate::text_ir_parser_select::parse_select_case(content, lines, idx, indent, l);
    }
    let expr = parse_expr(content).map_err(|e| err(e, l))?;
    if let IrExprKind::FunctionCall { name, args } = expr.kind {
        return Ok(IrItem::Call { name, args });
    }
    Err(err(format!("unknown item: {content}"), l))
}
