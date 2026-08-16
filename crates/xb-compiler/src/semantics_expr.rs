use xb_frontend::{ArithmeticOp, BooleanOp, ComparisonOp, Expression, TypeSuffix};

use crate::checked::{CheckedExpr, CheckedExprKind, CheckedItem, CheckedSymbol};
use crate::semantics::{Analyzer, ExprResult, ItemResult, SemanticError, ValueType};

impl Analyzer {
    pub(crate) fn expr(&self, expr: &Expression) -> ExprResult {
        match expr {
            Expression::IntegerLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::IntegerLiteral(v.clone()),
                ValueType::Integer,
            )),
            Expression::FloatLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::FloatLiteral(v.clone()),
                ValueType::Float,
            )),
            Expression::StringLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::StringLiteral(v.clone()),
                ValueType::String,
            )),
            Expression::SystemConstant { name } => self.constant(name),
            Expression::SystemVariable { name, suffix } => self.shared_variable(name, *suffix),
            Expression::Identifier { name, suffix } => self.symbol(name, *suffix),
            Expression::ByRefIdentifier { name, suffix } => self.byref_symbol(name, *suffix),
            Expression::Comparison { op, left, right } => self.comparison(*op, left, right),
            Expression::Arithmetic { op, left, right } => self.arithmetic(*op, left, right),
            Expression::Not(inner) => self.not_expr(inner),
            Expression::Unary { op, operand } => self.unary(*op, operand),
            Expression::Boolean { op, left, right } => self.boolean(*op, left, right),
            Expression::Logical { op, left, right } => self.logical(*op, left, right),
            Expression::FunctionCall { name, args } => self.function_call(name, args),
            Expression::ArrayAccess { name, index } => self.array_access(name, index),
            Expression::ArrayRef { name } => self.array_ref(name),
        }
    }

    fn array_access(&self, name: &str, index: &Expression) -> ExprResult {
        let sym = self.auto_symbol(name);
        let vt = sym.value_type;
        let idx = self.expr(index)?;
        Ok(CheckedExpr::new(
            CheckedExprKind::ArrayAccess {
                symbol: sym,
                index: Box::new(idx),
            },
            vt,
        ))
    }

    fn array_ref(&self, name: &str) -> ExprResult {
        let sym = self.auto_symbol(name);
        let vt = sym.value_type;
        Ok(CheckedExpr::new(
            CheckedExprKind::ArrayRef { symbol: sym },
            vt,
        ))
    }

    fn comparison(&self, op: ComparisonOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        if lv.value_type != rv.value_type && !(lv.value_type == ValueType::String && rv.value_type == ValueType::Integer)
            && !(lv.value_type == ValueType::Integer && rv.value_type == ValueType::String) {
            return Err(SemanticError::ComparisonTypeMismatch {
                left: lv.value_type,
                right: rv.value_type,
            });
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::Comparison {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            ValueType::Integer,
        ))
    }

    fn arithmetic(&self, op: ArithmeticOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        if lv.value_type == ValueType::String && rv.value_type == ValueType::String {
            if op == ArithmeticOp::Add {
                return Ok(CheckedExpr::new(
                    CheckedExprKind::Arithmetic {
                        op,
                        left: Box::new(lv),
                        right: Box::new(rv),
                    },
                    ValueType::String,
                ));
            }
            // Non-add string-string: allow as integer (treated as 0)
            return Ok(CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op,
                    left: Box::new(lv),
                    right: Box::new(rv),
                },
                ValueType::Integer,
            ));
        }
        if lv.value_type == ValueType::String || rv.value_type == ValueType::String {
            // Allow string operands in arithmetic (treated as 0 in numeric context)
            return Ok(CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op,
                    left: Box::new(lv),
                    right: Box::new(rv),
                },
                ValueType::Integer,
            ));
        }
        let rt = if op.is_integer_op()
            || (lv.value_type != ValueType::Float && rv.value_type != ValueType::Float)
        {
            ValueType::Integer
        } else {
            ValueType::Float
        };
        Ok(CheckedExpr::new(
            CheckedExprKind::Arithmetic {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            rt,
        ))
    }

    fn not_expr(&self, inner: &Expression) -> ExprResult {
        let v = self.expr(inner)?;
        // Allow any type in NOT (XBasic treats strings as boolean)
        Ok(CheckedExpr::new(
            CheckedExprKind::Not(Box::new(v)),
            ValueType::Integer,
        ))
    }

    fn unary(&self, op: xb_frontend::UnaryOp, operand: &Expression) -> ExprResult {
        let v = self.expr(operand)?;
        let vt = match v.value_type {
            ValueType::String => ValueType::Integer,
            other => other,
        };
        Ok(CheckedExpr::new(
            CheckedExprKind::Unary {
                op,
                operand: Box::new(v),
            },
            vt,
        ))
    }

    fn boolean(&self, op: BooleanOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        // Allow any type in boolean ops (XBasic treats strings as boolean)
        Ok(CheckedExpr::new(
            CheckedExprKind::Boolean {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            ValueType::Integer,
        ))
    }
    pub(crate) fn function_call(&self, name: &str, args: &[Expression]) -> ExprResult {
        if self.arrays.contains_key(name) && args.len() == 1 {
            let sym = self.auto_symbol(name);
            let vt = sym.value_type;
            let index = self.expr(&args[0])?;
            return Ok(CheckedExpr::new(
                CheckedExprKind::ArrayAccess {
                    symbol: sym,
                    index: Box::new(index),
                },
                vt,
            ));
        }
        if name == "UBOUND" && args.len() == 1 {
            if let Expression::ArrayRef { name: arr_name } = &args[0] {
                let sym = self.auto_symbol(arr_name);
                return Ok(CheckedExpr::new(
                    CheckedExprKind::ArrayUBound { symbol: sym },
                    ValueType::Integer,
                ));
            }
        }
        if name == "SIZE" && args.len() == 1 {
            if let Expression::ArrayRef { name: arr_name } = &args[0] {
                let sym = self.auto_symbol(arr_name);
                return Ok(CheckedExpr::new(
                    CheckedExprKind::SizeOf { symbol: sym },
                    ValueType::Integer,
                ));
            }
            if let Expression::Identifier { name: var_name, .. } = &args[0] {
                let type_map = [
                    ("XLONG", ValueType::Integer),
                    ("SBYTE", ValueType::Integer),
                    ("UBYTE", ValueType::Integer),
                    ("SSHORT", ValueType::Integer),
                    ("USHORT", ValueType::Integer),
                    ("SLONG", ValueType::Integer),
                    ("ULONG", ValueType::Integer),
                    ("GIANT", ValueType::Integer),
                    ("DOUBLE", ValueType::Float),
                    ("SINGLE", ValueType::Float),
                    ("STRING", ValueType::String),
                ];
                for (tn, vt) in type_map {
                    if var_name.eq_ignore_ascii_case(tn) {
                        return Ok(CheckedExpr::new(
                            CheckedExprKind::SizeOfType { value_type: vt },
                            ValueType::Integer,
                        ));
                    }
                }
                let sym = self.auto_symbol(var_name);
                return Ok(CheckedExpr::new(
                    CheckedExprKind::SizeOf { symbol: sym },
                    ValueType::Integer,
                ));
            }
        }
        if (name == "SUBADDRESS" || name == "GOADDRESS") && args.len() == 1 {
            if let Expression::Identifier { name: label_name, suffix: None } = &args[0] {
                return Ok(CheckedExpr::new(
                    CheckedExprKind::LabelAddress(label_name.clone()),
                    ValueType::Integer,
                ));
            }
        }
        if let Some(result) = self.type_conversion(name, args) {
            return result;
        }
        if let Some(rt) = crate::builtin::builtin_return_type(name) {
            return crate::builtin::builtin_call(self, name, args, rt);
        }
        let (resolved_name, sig) = if let Some(s) = self.functions.get(name) {
            (name.to_owned(), s)
        } else {
            let with_suffix = format!("{name}$");
            match self.functions.get(&with_suffix) {
                Some(s) => (with_suffix, s),
                None => {
                    // Stub unknown functions: return Integer (or String if $ suffix)
                    let rt = if name.ends_with('$') {
                        ValueType::String
                    } else {
                        ValueType::Integer
                    };
                    let checked_args: Vec<CheckedExpr> = args
                        .iter()
                        .map(|a| self.expr(a))
                        .collect::<Result<_, _>>()?;
                    return Ok(CheckedExpr::new(
                        CheckedExprKind::FunctionCall {
                            name: name.to_owned(),
                            args: checked_args,
                        },
                        rt,
                    ));
                }
            }
        };
        let normalized = resolved_name.trim_end_matches('$').to_owned();
        if args.len() != sig.params.len() {
            return Err(SemanticError::FunctionArgCount {
                name: name.to_owned(),
                expected: sig.params.len(),
                actual: args.len(),
            });
        }
        let mut checked = Vec::with_capacity(args.len());
        for (i, arg) in args.iter().enumerate() {
            let v = self.expr(arg)?;
            if v.value_type != sig.params[i] {
                return Err(SemanticError::FunctionArgType {
                    name: name.to_owned(),
                    index: i,
                    expected: sig.params[i],
                    actual: v.value_type,
                });
            }
            checked.push(v);
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::FunctionCall {
                name: normalized,
                args: checked,
            },
            sig.return_type,
        ))
    }

    fn symbol(&self, name: &str, suffix: Option<xb_frontend::TypeSuffix>) -> ExprResult {
        let full = xb_frontend::full_name(name.to_owned(), suffix);
        let suffix_vt = ValueType::from_suffix(suffix);
        match self.checked_symbol(name) {
            Ok(s) => {
                // If the found type matches the suffix type, use it
                if s.value_type == suffix_vt {
                    Ok(CheckedExpr::new(
                        CheckedExprKind::Symbol(s.clone()),
                        s.value_type,
                    ))
                } else {
                    // Type conflict: v0 (Integer) vs v0$ (String) — treat as different variable
                    Ok(CheckedExpr::new(
                        CheckedExprKind::Symbol(CheckedSymbol::new(full, suffix_vt)),
                        suffix_vt,
                    ))
                }
            }
            Err(_) => {
                if self.constants.contains_key(name) {
                    self.constant(name)
                } else if crate::builtin::is_zero_arg_builtin(&full) {
                    let rt = crate::builtin::builtin_return_type(&full).unwrap();
                    Ok(CheckedExpr::new(
                        CheckedExprKind::FunctionCall {
                            name: full,
                            args: vec![],
                        },
                        rt,
                    ))
                } else {
                    // Auto-declare unknown variables based on type suffix
                    Ok(CheckedExpr::new(
                        CheckedExprKind::Symbol(CheckedSymbol::new(name.to_owned(), suffix_vt)),
                        suffix_vt,
                    ))
                }
            }
        }
    }
    fn byref_symbol(&self, name: &str, suffix: Option<xb_frontend::TypeSuffix>) -> ExprResult {
        // @-prefixed identifiers are pass-by-reference; auto-declare based on suffix
        let vt = ValueType::from_suffix(suffix);
        let sym = CheckedSymbol::new(name.to_owned(), vt);
        Ok(CheckedExpr::new(
            CheckedExprKind::Symbol(sym),
            vt,
        ))
    }

    pub(crate) fn call_stmt(&self, name: &str, args: &[Expression]) -> ItemResult {
        let checked_call = self.function_call(name, args)?;
        let resolved = match checked_call.kind {
            CheckedExprKind::FunctionCall { ref name, .. } => name.clone(),
            _ => name.to_owned(),
        };
        let checked_args = args
            .iter()
            .map(|a| self.expr(a))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(CheckedItem::Call {
            name: resolved,
            args: checked_args,
        })
    }
}
