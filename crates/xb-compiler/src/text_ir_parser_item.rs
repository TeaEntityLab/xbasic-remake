use crate::ir::{IrExprKind, IrItem, IrParam, IrSymbol};
use crate::text_ir_parser_expr::parse_expr;
use crate::text_ir_parser_helpers::parse_type;

use crate::text_ir_parser::{err, parse_items, TextIrParseError};

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
        let e = parse_expr(rest).map_err(|e| err(e, l))?;
        return Ok(IrItem::Print(e));
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
        let end = parse_expr(&after[to + 4..]).map_err(|e| err(e, l))?;
        let body = parse_items(lines, idx, indent + 1)?;
        if *idx >= lines.len() || lines[*idx].trim() != "next" {
            return Err(err("expected 'next'".into(), l));
        }
        *idx += 1;
        return Ok(IrItem::For {
            var,
            start,
            end,
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
    if content == "exit_loop" {
        return Ok(IrItem::ExitLoop);
    }
    let expr = parse_expr(content).map_err(|e| err(e, l))?;
    if let IrExprKind::FunctionCall { name, args } = expr.kind {
        return Ok(IrItem::Call { name, args });
    }
    Err(err(format!("unknown item: {content}"), l))
}

fn parse_symbol_decl(s: &str) -> Result<IrSymbol, String> {
    let colon = s
        .find(':')
        .ok_or_else(|| format!("missing : in symbol: {s}"))?;
    let name = s[..colon].to_string();
    let vt = parse_type(s[colon + 1..].trim())?;
    Ok(IrSymbol {
        name,
        value_type: vt,
    })
}

fn parse_params(s: &str) -> Result<Vec<IrParam>, String> {
    let s = s.trim();
    if s.is_empty() {
        return Ok(Vec::new());
    }
    s.split(',')
        .map(|p| {
            let p = p.trim();
            let colon = p
                .find(':')
                .ok_or_else(|| format!("missing : in param: {p}"))?;
            let name = p[..colon].to_string();
            let vt = parse_type(p[colon + 1..].trim())?;
            Ok(IrParam {
                name,
                value_type: vt,
            })
        })
        .collect()
}
