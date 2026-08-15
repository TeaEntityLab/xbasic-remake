use crate::ir::{IrItem, IrProgram};
use crate::text_ir_parser_item::parse_item;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TextIrParseError {
    pub message: String,
    pub line: usize,
}

impl std::fmt::Display for TextIrParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "text IR parse error at line {}: {}",
            self.line, self.message
        )
    }
}

pub struct TextIrParser;

impl TextIrParser {
    pub fn parse(text: &str) -> Result<IrProgram, TextIrParseError> {
        let lines: Vec<&str> = text.lines().collect();
        let mut idx = 0;
        let items = parse_items(&lines, &mut idx, 0)?;
        Ok(IrProgram { items })
    }
}

pub(crate) fn err(msg: String, line: usize) -> TextIrParseError {
    TextIrParseError { message: msg, line }
}

pub(crate) fn parse_items(
    lines: &[&str],
    idx: &mut usize,
    indent: usize,
) -> Result<Vec<IrItem>, TextIrParseError> {
    let mut items = Vec::new();
    while *idx < lines.len() {
        let line = lines[*idx];
        if line.trim().is_empty() {
            *idx += 1;
            continue;
        }
        let lead = line.len() - line.trim_start().len();
        let level = lead / 2;
        if level < indent {
            break;
        }
        if level > indent {
            return Err(err(
                format!("unexpected indent: expected {indent}, got {level}"),
                *idx + 1,
            ));
        }
        let content = line.trim();
        if is_closer(content) {
            break;
        }
        items.push(parse_item(content, lines, idx, indent)?);
    }
    Ok(items)
}

fn is_closer(s: &str) -> bool {
    matches!(
        s,
        "end if" | "else" | "wend" | "next" | "end function" | "loop"
    )
}

pub(crate) fn parse_loop_condition(
    lines: &[&str],
    idx: &mut usize,
    l: usize,
) -> Result<Option<(crate::ir::IrExpr, bool)>, TextIrParseError> {
    if *idx >= lines.len() {
        return Err(err("expected 'loop'".into(), l));
    }
    let content = lines[*idx].trim();
    if content == "loop" {
        *idx += 1;
        return Ok(None);
    }
    if let Some(rest) = content.strip_prefix("loop while ") {
        *idx += 1;
        let cond = crate::text_ir_parser_expr::parse_expr(rest).map_err(|e| err(e, l))?;
        return Ok(Some((cond, true)));
    }
    if let Some(rest) = content.strip_prefix("loop until ") {
        *idx += 1;
        let cond = crate::text_ir_parser_expr::parse_expr(rest).map_err(|e| err(e, l))?;
        return Ok(Some((cond, false)));
    }
    Err(err("expected 'loop'".into(), l))
}
