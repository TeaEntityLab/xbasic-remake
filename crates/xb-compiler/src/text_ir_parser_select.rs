use crate::checked::PrintSep;
use crate::ir::{IrCaseClause, IrExpr, IrItem};
use crate::text_ir_parser::{err, parse_items, TextIrParseError};
use crate::text_ir_parser_expr::parse_expr;

pub(crate) fn parse_select_case(
    content: &str,
    lines: &[&str],
    idx: &mut usize,
    indent: usize,
    l: usize,
) -> Result<IrItem, TextIrParseError> {
    let rest = content.strip_prefix("select_case ").unwrap();
    let selector = parse_expr(rest).map_err(|e| err(e, l))?;
    let mut cases = Vec::new();
    let mut default = None;
    while *idx < lines.len() {
        let case_line = lines[*idx].trim();
        if case_line == "end_select" {
            *idx += 1;
            return Ok(IrItem::SelectCase {
                selector,
                cases,
                default,
            });
        }
        if case_line == "case_else" {
            *idx += 1;
            default = Some(parse_items(lines, idx, indent + 2)?);
            continue;
        }
        if let Some(cond_rest) = case_line.strip_prefix("case ") {
            *idx += 1;
            let conds: Vec<IrExpr> = cond_rest
                .split(',')
                .map(|s| parse_expr(s.trim()).map_err(|e| err(e, l)))
                .collect::<Result<_, _>>()?;
            let body = parse_items(lines, idx, indent + 2)?;
            cases.push(IrCaseClause {
                conditions: conds,
                body,
            });
            continue;
        }
        break;
    }
    Err(err("expected 'end_select'".into(), l))
}

pub(crate) fn parse_print_items(
    rest: &str,
    l: usize,
) -> Result<(Vec<IrExpr>, Vec<PrintSep>), TextIrParseError> {
    let mut items = Vec::new();
    let mut separators = Vec::new();
    let mut depth = 0;
    let mut start = 0;
    let bytes = rest.as_bytes();
    for i in 0..bytes.len() {
        match bytes[i] {
            b'(' => depth += 1,
            b')' => depth -= 1,
            b';' if depth == 0 => {
                items.push(parse_expr(rest[start..i].trim()).map_err(|e| err(e, l))?);
                separators.push(PrintSep::Semicolon);
                start = i + 1;
            }
            b',' if depth == 0 => {
                items.push(parse_expr(rest[start..i].trim()).map_err(|e| err(e, l))?);
                separators.push(PrintSep::Comma);
                start = i + 1;
            }
            _ => {}
        }
    }
    items.push(parse_expr(rest[start..].trim()).map_err(|e| err(e, l))?);
    Ok((items, separators))
}
