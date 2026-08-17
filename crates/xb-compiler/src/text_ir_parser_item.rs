use crate::ir::{IrExpr, IrExprKind, IrItem};
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
    if content == "version" || content.starts_with("version ") {
        let v = content.strip_prefix("version").unwrap_or("").trim();
        return Ok(IrItem::Version(v.to_string()));
    }
    if content == "program_name" || content.starts_with("program_name ") {
        let v = content.strip_prefix("program_name").unwrap_or("").trim();
        return Ok(IrItem::ProgramName(v.to_string()));
    }
    if content == "print" {
        return Ok(IrItem::Print {
            items: vec![],
            separators: vec![],
        });
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
    if let Some(rest) = content.strip_prefix("mid_assign ") {
        let parts: Vec<&str> = rest.split(" | ").collect();
        if parts.len() == 3 {
            let target = parse_expr(parts[0]).map_err(|e| err(e, l))?;
            let start = parse_expr(parts[1]).map_err(|e| err(e, l))?;
            let value = parse_expr(parts[2]).map_err(|e| err(e, l))?;
            return Ok(IrItem::MidAssign {
                target,
                start,
                length: None,
                value,
            });
        }
        if parts.len() == 4 {
            let target = parse_expr(parts[0]).map_err(|e| err(e, l))?;
            let start = parse_expr(parts[1]).map_err(|e| err(e, l))?;
            let length = parse_expr(parts[2]).map_err(|e| err(e, l))?;
            let value = parse_expr(parts[3]).map_err(|e| err(e, l))?;
            return Ok(IrItem::MidAssign {
                target,
                start,
                length: Some(length),
                value,
            });
        }
        return Err(err("mid_assign needs 3 or 4 parts".into(), l));
    }
    if let Some(rest) = content.strip_prefix("builtin_assign ") {
        // Format: builtin_assign NAME arg1 arg2 ... = value
        let eq_pos = rest
            .rfind(" = ")
            .ok_or_else(|| err("missing = in builtin_assign".into(), l))?;
        let before_eq = &rest[..eq_pos];
        let value_str = &rest[eq_pos + 3..];
        let sp = before_eq
            .find(' ')
            .ok_or_else(|| err("missing args in builtin_assign".into(), l))?;
        let name = before_eq[..sp].to_string();
        let args_str = &before_eq[sp + 1..];
        let args: Vec<IrExpr> = if args_str.is_empty() {
            vec![]
        } else {
            args_str
                .split(' ')
                .map(|s| parse_expr(s).map_err(|e| err(e, l)))
                .collect::<Result<_, _>>()?
        };
        let value = parse_expr(value_str).map_err(|e| err(e, l))?;
        return Ok(IrItem::BuiltinAssign { name, args, value });
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
        "gosub_return" => return Ok(IrItem::GosubReturn),
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
    if let Some(rest) = content.strip_prefix("gosub ") {
        return Ok(IrItem::Gosub(rest.trim().to_string()));
    }
    if let Some(rest) = content.strip_prefix("label ") {
        return Ok(IrItem::Label(rest.trim().to_string()));
    }
    if let Some(rest) = content.strip_prefix("goto ") {
        return Ok(IrItem::Goto(rest.trim().to_string()));
    }
    if let Some(rest) = content.strip_prefix("gosub_expr ") {
        let expr = parse_expr(rest).map_err(|e| err(e, l))?;
        return Ok(IrItem::GosubExpr(expr));
    }
    if let Some(rest) = content.strip_prefix("goto_expr ") {
        let expr = parse_expr(rest).map_err(|e| err(e, l))?;
        return Ok(IrItem::GotoExpr(expr));
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
