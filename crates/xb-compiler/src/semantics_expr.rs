use xb_frontend::{ArithmeticOp, BooleanOp, ComparisonOp, Expression, TypeSuffix};

use crate::checked::{CheckedExpr, CheckedExprKind, CheckedSymbol};
use crate::semantics::{Analyzer, ExprResult, SemanticError, ValueType};

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
            Expression::Identifier { name, .. } => self.symbol(name),
            Expression::Comparison { op, left, right } => self.comparison(*op, left, right),
            Expression::Arithmetic { op, left, right } => self.arithmetic(*op, left, right),
            Expression::Not(inner) => self.not_expr(inner),
            Expression::Boolean { op, left, right } => self.boolean(*op, left, right),
            Expression::FunctionCall { name, args } => self.function_call(name, args),
        }
    }

    fn comparison(&self, op: ComparisonOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        if lv.value_type != rv.value_type {
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
            if op != ArithmeticOp::Add {
                return Err(SemanticError::ArithmeticStringOperand);
            }
            return Ok(CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op,
                    left: Box::new(lv),
                    right: Box::new(rv),
                },
                ValueType::String,
            ));
        }
        if lv.value_type == ValueType::String || rv.value_type == ValueType::String {
            return Err(SemanticError::ArithmeticStringOperand);
        }
        let rt = if lv.value_type == ValueType::Float || rv.value_type == ValueType::Float {
            ValueType::Float
        } else {
            ValueType::Integer
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
        if v.value_type != ValueType::Integer {
            return Err(SemanticError::IfConditionNotInteger {
                actual: v.value_type,
            });
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::Not(Box::new(v)),
            ValueType::Integer,
        ))
    }

    fn boolean(&self, op: BooleanOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        if lv.value_type != ValueType::Integer || rv.value_type != ValueType::Integer {
            return Err(SemanticError::IfConditionNotInteger {
                actual: if lv.value_type != ValueType::Integer {
                    lv.value_type
                } else {
                    rv.value_type
                },
            });
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::Boolean {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            ValueType::Integer,
        ))
    }
    fn function_call(&self, name: &str, args: &[Expression]) -> ExprResult {
        if let Some(rt) = crate::builtin::builtin_return_type(name) {
            return crate::builtin::builtin_call(self, name, args, rt);
        }
        let Some(sig) = self.functions.get(name) else {
            return Err(SemanticError::UnknownFunction {
                name: name.to_owned(),
            });
        };
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
                name: name.to_owned(),
                args: checked,
            },
            sig.return_type,
        ))
    }

    fn constant(&self, name: &str) -> ExprResult {
        let Some(value) = self.constants.get(name) else {
            return Err(SemanticError::UnknownConstant {
                name: name.to_owned(),
            });
        };
        Ok(CheckedExpr::new(
            CheckedExprKind::Constant {
                name: name.to_owned(),
                value: value.clone(),
            },
            ValueType::Integer,
        ))
    }

    fn shared_variable(&self, name: &str, s: Option<TypeSuffix>) -> ExprResult {
        let Some(declared) = self.shared.get(name).copied() else {
            return Err(SemanticError::UnknownSharedVariable {
                name: name.to_owned(),
            });
        };
        let requested = ValueType::from_suffix(s);
        if declared != requested {
            return Err(SemanticError::TypeMismatch {
                name: name.to_owned(),
                expected: requested,
                actual: declared,
            });
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::SharedVariable(CheckedSymbol::new(name.to_owned(), declared)),
            declared,
        ))
    }

    fn symbol(&self, name: &str) -> ExprResult {
        let s = self.checked_symbol(name)?;
        Ok(CheckedExpr::new(
            CheckedExprKind::Symbol(s.clone()),
            s.value_type,
        ))
    }

    pub(crate) fn checked_symbol(&self, name: &str) -> Result<CheckedSymbol, SemanticError> {
        let Some(vt) = self.symbols.get(name).copied() else {
            return Err(SemanticError::UnknownSymbol {
                name: name.to_owned(),
            });
        };
        Ok(CheckedSymbol::new(name.to_owned(), vt))
    }
}
