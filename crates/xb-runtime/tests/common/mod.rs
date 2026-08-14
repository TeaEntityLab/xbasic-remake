use xb_compiler::{FrontendUnit, IrExpr, IrExprKind, IrProgram, IrSymbol, ValueType};

pub fn lower(source: &str) -> IrProgram {
    FrontendUnit::parse(source).unwrap().lower_ir().unwrap()
}

pub fn symbol(name: &str, value_type: ValueType) -> IrSymbol {
    IrSymbol {
        name: name.to_string(),
        value_type,
    }
}

pub fn expression(kind: IrExprKind, value_type: ValueType) -> IrExpr {
    IrExpr { kind, value_type }
}
