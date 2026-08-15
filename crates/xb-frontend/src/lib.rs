pub mod ast;
mod lexeme;
pub mod lexer;
mod literal;
pub mod parser;
mod parser_cursor;
mod parser_expr;
mod parser_if;
#[cfg(test)]
mod parser_tests;
pub mod token;

pub use ast::{
    ArithmeticOp, BooleanOp, ComparisonOp, Expression, FunctionDecl, Param, Program, Statement,
};
pub use lexer::{lex, LexError, Lexer};
pub use parser::{parse_program, ParseError, Parser};
pub use token::{full_name, Keyword, SourcePos, Token, TokenKind, TypeSuffix};
