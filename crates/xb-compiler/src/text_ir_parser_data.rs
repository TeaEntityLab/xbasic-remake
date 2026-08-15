use crate::ir::IrItem;
use crate::text_ir_parser::err;
use crate::text_ir_parser_helpers::parse_symbol_decl;

pub(crate) fn parse_read(
    rest: &str,
    l: usize,
) -> Result<IrItem, crate::text_ir_parser::TextIrParseError> {
    let mut symbols = Vec::new();
    for part in rest.split(',') {
        let sym = parse_symbol_decl(part.trim()).map_err(|e| err(e, l))?;
        symbols.push(sym);
    }
    Ok(IrItem::Read(symbols))
}

pub(crate) fn parse_restore(rest: &str) -> IrItem {
    let label = rest.trim();
    if label.is_empty() {
        IrItem::Restore(None)
    } else {
        IrItem::Restore(Some(label.to_string()))
    }
}

pub(crate) fn parse_stop() -> IrItem {
    IrItem::Stop
}

pub(crate) fn parse_exit_select() -> IrItem {
    IrItem::ExitSelect
}
