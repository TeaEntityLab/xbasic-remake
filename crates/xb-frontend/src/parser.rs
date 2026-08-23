use crate::ast::{Expression, FunctionDecl, Program, Statement, TypeMember};
use crate::lexer::{lex, LexError};
use crate::token::{full_name, Keyword, Token, TokenKind, TypeSuffix};
use thiserror::Error;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum ParseError {
    #[error(transparent)]
    Lex(#[from] LexError),
    #[error("expected {expected} at {line}:{column}")]
    Expected {
        expected: &'static str,
        line: usize,
        column: usize,
    },
}

pub fn parse_program(source: &str) -> Result<Program, ParseError> {
    Parser::new(lex(source)?).parse_program()
}

pub struct Parser {
    pub(crate) tokens: Vec<Token>,
    pub(crate) index: usize,
    pub(crate) in_single_line_if: bool,
    /// Names of composite TYPE declarations seen so far, so that
    /// `TYPE0 var` declarations can be distinguished from primitive typed dims.
    pub(crate) composite_types: std::collections::HashSet<String>,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Self {
            tokens,
            index: 0,
            in_single_line_if: false,
            composite_types: std::collections::HashSet::new(),
        }
    }

    pub fn parse_program(mut self) -> Result<Program, ParseError> {
        let mut statements = Vec::new();
        self.skip_newlines();
        while !self.at_eof() {
            statements.push(self.statement()?);
            self.skip_newlines();
        }
        Ok(Program::new(statements))
    }

    pub(crate) fn statement(&mut self) -> Result<Statement, ParseError> {
        if self.starts_constant_definition() {
            return self.constant_definition_stmt();
        }
        if self.starts_shared_assignment() {
            return self.shared_assignment_stmt();
        }
        if self.starts_shared_name_assignment() {
            return self.shared_name_assignment_stmt();
        }
        // `##NAME[i]=v` / `##NAME.m=v` / `#NAME.m=v` — system-variable or shared-name
        // member/array lvalue. SharedName + `[` is left to `call_stmt`, which already
        // handles nested array members like `#token[i].akind[0] = v`.
        if (matches!(self.peek_kind(), TokenKind::SystemVariable { .. })
            && matches!(
                self.peek_next_kind(),
                Some(TokenKind::Symbol('[')) | Some(TokenKind::Symbol('.'))
            ))
            || (matches!(self.peek_kind(), TokenKind::SharedName(_))
                && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('.'))))
        {
            return self.dot_access_stmt();
        }
        if self.starts_label() {
            return self.label_stmt();
        }
        // Legacy XBasic freely uses keywords (IMPORT, EXPORT, STOP, TYPE, DATA, …)
        // as ordinary variable names. A keyword directly followed by `=` is always
        // an assignment — no statement keyword's own syntax places `=` immediately
        // after it — so route it uniformly before keyword-statement dispatch.
        if matches!(self.peek_kind(), TokenKind::Keyword(_))
            && matches!(self.peek_next_kind(), Some(TokenKind::Symbol('=')))
        {
            return self.keyword_assignment_stmt();
        }
        match self.peek_keyword() {
            Some(Keyword::Version)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Version) => self.version_stmt(),
            Some(Keyword::Print)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Print) => self.print_stmt(),
            Some(Keyword::Dim) => self.dim_stmt(),
            Some(Keyword::If) => self.if_stmt(),
            Some(Keyword::Ifz) => self.ifz_stmt(),
            Some(Keyword::Ift) => self.ift_stmt(),
            Some(Keyword::Iff) => self.iff_stmt(),
            Some(Keyword::For) => self.for_stmt(),
            Some(Keyword::While) => self.while_stmt(),
            Some(Keyword::Function)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Function)
            | Some(Keyword::External)
            | Some(Keyword::Internal)
            | Some(Keyword::CFunction) => self.function_stmt(),
            Some(Keyword::Do) if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) => {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Do) => self.do_stmt(),
            Some(Keyword::Select)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Select) => self.select_case_stmt(),
            Some(Keyword::Sub) if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('['))) => {
                self.call_stmt()
            }
            Some(Keyword::Sub) => self.sub_stmt(),
            Some(Keyword::Exit) => self.exit_stmt(),
            Some(Keyword::Inc) if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) => {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Inc) => self.inc_dec_stmt(true),
            Some(Keyword::Dec) if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) => {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Dec) => self.inc_dec_stmt(false),
            Some(Keyword::Return)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Return) => self.return_stmt(),
            Some(Keyword::Swap) => self.swap_stmt(),
            Some(Keyword::Program) => self.program_stmt(),
            Some(Keyword::Import) => self.import_stmt(),
            Some(Keyword::Declare) => self.declare_stmt(),
            Some(Keyword::End) if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) => {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::End) if self.is_end_program() => self.end_program_stmt(),
            Some(Keyword::End) if self.is_end_export() => self.end_export_stmt(),
            Some(Keyword::End) if self.starts_end_if() => {
                // Orphaned END IF (e.g., THEN was consumed by a ''' comment)
                self.index += 2;
                self.expect_line_end()?;
                Ok(Statement::Compound(vec![]))
            }
            Some(Keyword::Static) | Some(Keyword::Shared) => self.shared_static_stmt(),
            Some(Keyword::Redim) => self.redim_stmt(),
            Some(Keyword::Gosub) => self.gosub_stmt(),
            Some(Keyword::DoEvents) => self.doevents_stmt(),
            Some(Keyword::Randomize) => self.randomize_stmt(),
            Some(Keyword::Break)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Break)
                if matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Symbol('(')) | Some(TokenKind::Symbol('['))
                ) =>
            {
                self.call_stmt()
            }
            Some(Keyword::Break) => self.break_stmt(),
            Some(Keyword::Goto) => self.goto_stmt(),
            Some(Keyword::Const)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Const) => self.const_stmt(),
            Some(Keyword::Data)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Data)
                if matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Symbol('[')) | Some(TokenKind::Symbol('('))
                ) =>
            {
                self.call_stmt()
            }
            Some(Keyword::Data) => self.data_stmt(),
            Some(Keyword::Read)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Read)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('['))) =>
            {
                self.call_stmt()
            }
            Some(Keyword::Read) => self.read_stmt(),
            Some(Keyword::Stop)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Stop)
                if matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Symbol('[')) | Some(TokenKind::Symbol('.'))
                ) =>
            {
                self.dot_access_stmt()
            }
            Some(Keyword::Stop) => self.stop_stmt(),
            Some(Keyword::Restore) => self.restore_stmt(),
            Some(Keyword::Export) => self.export_stmt(),
            Some(Keyword::FuncAddr) => self.funcaddr_stmt(),
            Some(Keyword::Type) | Some(Keyword::Packed)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Type) | Some(Keyword::Packed)
                if matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Symbol('['))
                        | Some(TokenKind::Symbol('.'))
                        | Some(TokenKind::Symbol('('))
                ) =>
            {
                self.dot_access_stmt()
            }
            Some(Keyword::Type) | Some(Keyword::Packed) => self.type_stmt(),
            Some(Keyword::Next)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Step)
            | Some(Keyword::Case)
            | Some(Keyword::Loop)
            | Some(Keyword::Until)
            | Some(Keyword::Wend)
            | Some(Keyword::To)
            | Some(Keyword::Then)
            | Some(Keyword::Else)
            | Some(Keyword::ElseIf)
            | Some(Keyword::Mod)
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))) =>
            {
                self.keyword_assignment_stmt()
            }
            Some(Keyword::Next)
                if matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Keyword(Keyword::Case))
                ) =>
            {
                self.index += 2;
                self.expect_line_end()?;
                Ok(Statement::ExitSelect)
            }
            Some(Keyword::Let) => {
                self.index += 1;
                self.assignment_stmt()
            }
            _ if matches!(self.peek_kind(), TokenKind::Identifier { ref name, .. } if name.eq_ignore_ascii_case("ENDIF")) =>
            {
                self.index += 1;
                self.expect_line_end()?;
                Ok(Statement::Compound(vec![]))
            }
            _ if self.starts_attach() => self.attach_stmt(),
            _ if self.starts_dot_access() => self.dot_access_stmt(),
            _ if self.starts_composite_decl() => self.composite_decl_stmt(),
            _ if self.starts_typed_dim() => self.typed_dim_stmt(),
            _ if self.starts_assignment() => self.assignment_stmt(),
            _ if matches!(self.peek_kind(), TokenKind::Symbol('@')) => self.at_call_stmt(),
            _ if self.starts_call() => self.call_stmt(),
            _ => Err(self.expected("statement")),
        }
    }

    pub(crate) fn print_stmt(&mut self) -> Result<Statement, ParseError> {
        crate::parser_select::parse_print(self)
    }

    /// A `#`-prefixed `SharedName` embeds its type suffix in the name with
    /// `suffix: None` (e.g. `#xbasic$` lexes to name `"xbasic$"`), whereas a
    /// regular `Identifier` already carries a separate suffix. Split a trailing
    /// `$`/`!`/`#` off such a name so the declared element type is correct
    /// (`STRING #xbasic$[]` / `DIM #xbasic$[]` -> String, not the default
    /// Integer). No-op when a suffix is already present or none is embedded.
    pub(crate) fn shared_name_suffix(
        (name, suffix): (String, Option<TypeSuffix>),
    ) -> (String, Option<TypeSuffix>) {
        if suffix.is_some() {
            return (name, suffix);
        }
        if let Some(base) = name.strip_suffix('$') {
            (base.to_string(), Some(TypeSuffix::String))
        } else if let Some(base) = name.strip_suffix('!') {
            (base.to_string(), Some(TypeSuffix::Single))
        } else if let Some(base) = name.strip_suffix('#') {
            (base.to_string(), Some(TypeSuffix::Double))
        } else {
            (name, None)
        }
    }

    fn dim_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::Dim)?;
        let mut dims = Vec::new();
        loop {
            let (name, suffix) = Self::shared_name_suffix(self.expect_name_or_keyword()?);
            let (size, is_array, extra_dims) = self.parse_array_size()?;
            dims.push(Statement::Dim { name, suffix, size, extra_dims, is_array, redim: false, shared: false });
            if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
            } else {
                break;
            }
        }
        self.expect_line_end()?;
        if dims.len() == 1 {
            Ok(dims.pop().unwrap())
        } else {
            Ok(Statement::Compound(dims))
        }
    }

    fn typed_dim_stmt(&mut self) -> Result<Statement, ParseError> {
        // Skip all leading identifiers (type qualifiers + storage classes like AUTO, AUTOX)
        // until we reach the variable name. The variable name is the last identifier
        // before [, =, ,, or line end.
        while (matches!(self.peek_kind(), TokenKind::Identifier { .. })
            || matches!(self.peek_kind(), TokenKind::Keyword(_)))
            && (matches!(self.peek_next_kind(), Some(TokenKind::Identifier { .. }))
                || matches!(self.peek_next_kind(), Some(TokenKind::Keyword(_)))
                || matches!(self.peek_next_kind(), Some(TokenKind::SharedName(_)))
                || matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::SystemVariable { .. })
                ))
        {
            self.index += 1;
        }
        let mut dims = Vec::new();
        loop {
            let (name, name_suffix) = Self::shared_name_suffix(self.expect_name_or_keyword()?);
            // Skip parameter type list in parentheses (FUNCADDR declarations)
            // Check before parse_array_size to avoid consuming ( as array size
            if matches!(self.peek_kind(), TokenKind::Symbol('('))
                && (matches!(self.peek_next_kind(), Some(TokenKind::Symbol(')')))
                    || matches!(self.peek_next_kind(), Some(TokenKind::Identifier { .. }))
                    || matches!(self.peek_next_kind(), Some(TokenKind::Keyword(_))))
            {
                // Handle empty () param list
                if matches!(self.peek_next_kind(), Some(TokenKind::Symbol(')'))) {
                    self.index += 2; // skip ( and )
                } else {
                    // Peek ahead: if it's Identifier followed by , or ), it's a param list
                    let save = self.index;
                    self.index += 2; // skip ( and first type
                    if matches!(
                        self.peek_kind(),
                        TokenKind::Symbol(',') | TokenKind::Symbol(')')
                    ) {
                        // Parameter list — skip to )
                        while !matches!(self.peek_kind(), TokenKind::Symbol(')')) && !self.at_eof()
                        {
                            self.index += 1;
                        }
                        if matches!(self.peek_kind(), TokenKind::Symbol(')')) {
                            self.index += 1;
                        }
                    } else {
                        // Not a param list — restore and let parse_array_size handle it
                        self.index = save;
                    }
                }
            }
            let (size, is_array, extra_dims) = self.parse_array_size()?;
            dims.push(Statement::Dim {
                name,
                suffix: name_suffix,
                size,
                extra_dims,
                is_array,
                redim: false,
                shared: false,
            });
            if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
            } else {
                break;
            }
        }
        self.expect_line_end()?;
        if dims.len() == 1 {
            Ok(dims.pop().unwrap())
        } else {
            Ok(Statement::Compound(dims))
        }
    }
    fn funcaddr_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::FuncAddr)?;
        // Optional return type: a keyword (DOUBLE/XLONG/…) or an identifier type
        // name. Only consume an identifier type when a further name follows, so
        // `FUNCADDR foo` keeps `foo` as the name while `FUNCADDR XLONG foo` treats
        // `XLONG` as the return type.
        if matches!(self.peek_kind(), TokenKind::Keyword(_)) {
            self.index += 1;
        } else if matches!(self.peek_kind(), TokenKind::Identifier { .. })
            && matches!(
                self.peek_next_kind(),
                Some(TokenKind::Identifier { .. }) | Some(TokenKind::Keyword(_))
            )
        {
            self.index += 1;
        }
        // Optional dot prefix for member variables
        if matches!(self.peek_kind(), TokenKind::Symbol('.')) {
            self.index += 1;
        }
        let (name, suffix) = self.expect_name_or_keyword()?;
        // Optional array brackets []
        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            self.expect_symbol(']')?;
        }
        // Skip parameter type list in parentheses
        if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.index += 1;
            while !matches!(self.peek_kind(), TokenKind::Symbol(')')) {
                self.index += 1;
            }
            self.expect_symbol(')')?;
        }
        self.expect_line_end()?;
        // Treat FUNCADDR as an integer DIM (function addresses are intptr_t)
        Ok(Statement::Dim {
            name,
            suffix,
            size: None,
            extra_dims: Vec::new(),
            is_array: false,
            redim: false,
            shared: false,
        })
    }
    fn type_stmt(&mut self) -> Result<Statement, ParseError> {
        // TYPE or PACKED — capture the composite type name and its members.
        self.index += 1; // TYPE/PACKED keyword
        let type_name = if let TokenKind::Identifier { name, .. } = self.peek_kind().clone() {
            self.index += 1;
            name
        } else {
            String::new()
        };
        // Type alias (TYPE LINE = BOX): skip the rest of the line, no members.
        if matches!(self.peek_kind(), TokenKind::Symbol('=')) {
            self.index += 1;
            while !self.at_line_end() && !self.at_eof() {
                self.index += 1;
            }
            self.expect_line_end()?;
            return Ok(Statement::Compound(vec![]));
        }
        self.expect_line_end()?;
        let mut members = Vec::new();
        let mut depth = 1;
        // Consume the TYPE body one token at a time. Track statement-start so
        // depth is only adjusted by TYPE/PACKED/END TYPE that actually begin a
        // line — a keyword-named member such as `XLONG .type` must never be
        // mistaken for a nested composite (that bug swallowed whole files to
        // EOF). Members are recorded purely by peeking.
        let mut line_start = true;
        while !self.at_eof() && depth > 0 {
            if line_start {
                if let Some(kw_tok) = self.tokens.get(self.index) {
                    let type_kw: Option<&str> = match &kw_tok.kind {
                        TokenKind::Identifier { name, .. } => Some(name.as_str()),
                        TokenKind::Keyword(Keyword::FuncAddr) => Some("FUNCADDR"),
                        _ => None,
                    };
                    if let Some(type_kw) = type_kw {
                        // A member may carry a fixed-length/size spec between the
                        // type keyword and the `.member`, e.g. `STRING*32 .name`.
                        // Skip an optional `*<int>` so the member is still recorded
                        // (it was previously dropped from the layout entirely) and
                        // use the length as the member's byte size.
                        let (dot_off, fixed_len) = if matches!(
                            self.tokens.get(self.index + 1).map(|t| &t.kind),
                            Some(TokenKind::Symbol('*'))
                        ) {
                            let len = match self.tokens.get(self.index + 2).map(|t| &t.kind) {
                                Some(TokenKind::IntegerLiteral(n)) => n.parse::<usize>().ok(),
                                _ => None,
                            };
                            (3, len)
                        } else {
                            (1, None)
                        };
                        if let (Some(dot_tok), Some(name_tok)) = (
                            self.tokens.get(self.index + dot_off),
                            self.tokens.get(self.index + dot_off + 1),
                        ) {
                            if matches!(dot_tok.kind, TokenKind::Symbol('.')) {
                                let member_name = match &name_tok.kind {
                                    TokenKind::Identifier { name, .. } => Some(name.clone()),
                                    TokenKind::SharedName(n) => Some(n.clone()),
                                    TokenKind::Keyword(kw) => Some(format!("{kw:?}")),
                                    _ => None,
                                };
                                if let Some(member_name) = member_name {
                                    let (byte_size, is_float, is_string) =
                                        Self::member_type_info(type_kw);
                                    let byte_size = fixed_len.unwrap_or(byte_size);
                                    // A `FUNCADDR` member carries a param signature,
                                    // e.g. `.setName (DOG, STRING)`. Capture the param
                                    // type names so an indirect call through the member
                                    // flattens composite args like the target function.
                                    let mut funcaddr_params = Vec::new();
                                    let mut j = self.index + dot_off + 2;
                                    if matches!(
                                        self.tokens.get(j).map(|t| &t.kind),
                                        Some(TokenKind::Symbol('('))
                                    ) {
                                        j += 1;
                                        while let Some(tok) = self.tokens.get(j) {
                                            match &tok.kind {
                                                TokenKind::Symbol(')') => break,
                                                TokenKind::Identifier { name, .. } => {
                                                    funcaddr_params.push(name.clone())
                                                }
                                                TokenKind::Keyword(kw) => {
                                                    funcaddr_params.push(format!("{kw:?}"))
                                                }
                                                _ => {}
                                            }
                                            j += 1;
                                        }
                                    }
                                    members.push(TypeMember {
                                        name: member_name,
                                        byte_size,
                                        is_float,
                                        is_string,
                                        type_name: type_kw.to_owned(),
                                        funcaddr_params,
                                    });
                                }
                            }
                        }
                    }
                }
            }
            if line_start
                && matches!(
                    self.peek_keyword(),
                    Some(Keyword::Type) | Some(Keyword::Packed)
                )
            {
                depth += 1;
                self.index += 1;
                line_start = false;
            } else if line_start && matches!(self.peek_keyword(), Some(Keyword::End)) {
                self.index += 1;
                if matches!(
                    self.peek_keyword(),
                    Some(Keyword::Type) | Some(Keyword::Packed)
                ) {
                    self.index += 1;
                    depth -= 1;
                }
                line_start = false;
            } else {
                let is_break = matches!(
                    self.peek_kind(),
                    TokenKind::Newline | TokenKind::Symbol(':')
                );
                self.index += 1;
                line_start = is_break;
            }
        }
        self.expect_line_end()?;
        if !type_name.is_empty() {
            self.composite_types.insert(type_name.clone());
        }
        Ok(Statement::TypeDecl {
            name: type_name,
            members,
        })
    }

    /// Map a composite member type keyword to (byte_size, is_float, is_string).
    fn member_type_info(kw: &str) -> (usize, bool, bool) {
        match kw.to_ascii_uppercase().as_str() {
            "UBYTE" | "SBYTE" | "BYTE" | "CHAR" => (1, false, false),
            "USHORT" | "SSHORT" | "SHORT" | "WORD" => (2, false, false),
            "ULONG" | "SLONG" | "LONG" | "XLONG" | "INTEGER" | "DWORD" => (4, false, false),
            "GIANT" => (8, false, false),
            "SINGLE" | "FLOAT" => (4, true, false),
            "DOUBLE" => (8, true, false),
            "STRING" => (0, false, true),
            _ => (4, false, false),
        }
    }

    /// A statement starting with a known composite type name followed by a
    /// variable name is a composite variable declaration (`TYPE0 var`).
    pub(crate) fn starts_composite_decl(&self) -> bool {
        if let TokenKind::Identifier { name, .. } = self.peek_kind() {
            if self.composite_types.contains(name) {
                return matches!(
                    self.peek_next_kind(),
                    Some(TokenKind::Identifier { .. }) | Some(TokenKind::SharedName(_))
                );
            }
        }
        false
    }

    fn composite_decl_stmt(&mut self) -> Result<Statement, ParseError> {
        let TokenKind::Identifier {
            name: type_name, ..
        } = self.peek_kind().clone()
        else {
            return Err(self.expected("composite type"));
        };
        self.index += 1;
        let mut decls: Vec<Statement> = Vec::new();
        loop {
            let (var, shared) = match self.peek_kind().clone() {
                TokenKind::SharedName(n) => {
                    self.index += 1;
                    (n, true)
                }
                TokenKind::Identifier { name, .. } => {
                    self.index += 1;
                    (name, false)
                }
                _ => return Err(self.expected("composite variable")),
            };
            let mut is_array = false;
            if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                self.index += 1;
                while !matches!(self.peek_kind(), TokenKind::Symbol(']'))
                    && !self.at_line_end()
                    && !self.at_eof()
                {
                    self.index += 1;
                }
                if matches!(self.peek_kind(), TokenKind::Symbol(']')) {
                    self.index += 1;
                }
                is_array = true;
            }
            decls.push(Statement::CompositeDecl {
                type_name: type_name.clone(),
                var,
                shared,
                is_array,
            });
            // Additional comma-separated variables share the same TYPE.
            if matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
            } else {
                break;
            }
        }
        // Consume any trailing tokens to end of line (comments, etc.).
        while !self.at_line_end() && !self.at_eof() {
            self.index += 1;
        }
        self.expect_line_end()?;
        if decls.len() == 1 {
            Ok(decls.pop().unwrap())
        } else {
            Ok(Statement::Compound(decls))
        }
    }
    fn assignment_stmt(&mut self) -> Result<Statement, ParseError> {
        let (target, suffix) = self.expect_identifier()?;
        self.expect_symbol('=')?;
        let value = self.expression()?;
        self.expect_line_end()?;
        Ok(Statement::Assignment {
            target,
            suffix,
            value,
        })
    }

    fn attach_stmt(&mut self) -> Result<Statement, ParseError> {
        // ATTACH var$ TO display$ — skip the whole statement
        self.index += 1; // ATTACH
                         // Skip everything until end of line
        self.skip_to_line_end();
        self.expect_line_end()?;
        Ok(Statement::Compound(vec![]))
    }

    fn dot_access_stmt(&mut self) -> Result<Statement, ParseError> {
        // Parse dot-access: identifier.member.member... = expression
        // or identifier.member(args) as a call
        let (name, suffix) = self.expect_name_or_keyword()?;
        let mut full = name;
        while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
            self.index += 1;
            if let TokenKind::Identifier { name: member, .. } = self.peek_kind().clone() {
                self.index += 1;
                full = format!("{full}.{member}");
            } else if let TokenKind::Keyword(kw) = self.peek_kind().clone() {
                self.index += 1;
                full = format!("{full}.{kw:?}");
            } else {
                break;
            }
        }
        let mut array_extra: Vec<Expression> = Vec::new();
        let array_index = if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            let idx = self.expression()?;
            array_extra = self.collect_extra_indices()?;
            self.expect_symbol(']')?;
            Some(idx)
        } else {
            None
        };
        // Member access after an array index: `px3D.shape[k].x = v` lowers to the
        // struct-of-arrays target `px3D.shape.x` indexed by k.
        if array_index.is_some() {
            while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                self.index += 1;
                if let TokenKind::Identifier { name: m2, .. } = self.peek_kind().clone() {
                    self.index += 1;
                    full = format!("{full}.{m2}");
                } else if let TokenKind::Keyword(kw) = self.peek_kind().clone() {
                    self.index += 1;
                    full = format!("{full}.{kw:?}");
                } else {
                    break;
                }
            }
        }
        if let Some(idx) = array_index {
            if matches!(self.peek_kind(), TokenKind::Symbol('=')) {
                self.index += 1;
                let value = self.expression()?;
                self.expect_line_end()?;
                return Ok(Statement::ArrayAssignment {
                    target: full,
                    index: idx,
                    extra_indices: array_extra,
                    value,
                });
            }
        }
        if matches!(self.peek_kind(), TokenKind::Symbol('=')) {
            self.index += 1;
            let value = self.expression()?;
            self.expect_line_end()?;
            Ok(Statement::Assignment {
                target: full,
                suffix,
                value,
            })
        } else if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            // Function call or bitfield access with dot access
            let args = self.parse_args()?;
            // Check for assignment: x.flags{2,3} = 1 (bitfield)
            if matches!(self.peek_kind(), TokenKind::Symbol('=')) {
                self.index += 1;
                let value = self.expression()?;
                self.expect_line_end()?;
                // Treat as array assignment on the dot-accessed name
                let full = crate::token::full_name(full, suffix);
                let mut it = args.into_iter();
                let index = it
                    .next()
                    .unwrap_or_else(|| Expression::IntegerLiteral("0".to_string()));
                let extra_indices: Vec<Expression> = it.collect();
                return Ok(Statement::ArrayAssignment {
                    target: full,
                    index,
                    extra_indices,
                    value,
                });
            }
            self.expect_line_end()?;
            let full = crate::token::full_name(full, suffix);
            Ok(Statement::Call { name: full, args })
        } else {
            self.expect_line_end()?;
            let full = crate::token::full_name(full, suffix);
            Ok(Statement::Call {
                name: full,
                args: vec![],
            })
        }
    }
    fn keyword_assignment_stmt(&mut self) -> Result<Statement, ParseError> {
        let (target, suffix) = self.expect_name_or_keyword()?;
        self.expect_symbol('=')?;
        let value = self.expression()?;
        self.expect_line_end()?;
        Ok(Statement::Assignment {
            target,
            suffix,
            value,
        })
    }
    fn at_call_stmt(&mut self) -> Result<Statement, ParseError> {
        // @name.method(args) or @name[args](args) — call with @ prefix
        self.expect_symbol('@')?;
        let (name, suffix) = self.expect_name_or_keyword()?;
        let mut full = full_name(name, suffix);
        // Handle dot member access
        while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
            self.index += 1;
            if let TokenKind::Identifier { name: member, .. } = self.peek_kind().clone() {
                self.index += 1;
                full = format!("{full}.{member}");
            } else {
                break;
            }
        }
        // Handle array index: @func[wintag]
        if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            let _ = self.expression(); // skip index
            while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
                let _ = self.expression();
            }
            self.expect_symbol(']')?;
        }
        // Parse call args
        let args = if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.parse_args()?
        } else {
            vec![]
        };
        self.expect_line_end()?;
        Ok(Statement::Call { name: full, args })
    }
    fn call_stmt(&mut self) -> Result<Statement, ParseError> {
        let (name, suffix) = self.expect_name_or_keyword()?;
        let is_bracket = matches!(self.peek_kind(), TokenKind::Symbol('['));
        let args = if is_bracket {
            self.index += 1;
            let mut args = vec![self.expression()?];
            while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
                args.push(self.expression()?);
            }
            self.expect_symbol(']')?;
            // Handle comma after bracket: WRITE [file], data$
            while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                self.index += 1;
                args.push(self.expression()?);
            }
            args
        } else {
            self.parse_args()?
        };
        let (name, suffix) = if is_bracket && matches!(self.peek_kind(), TokenKind::Symbol('.')) {
            let mut full = full_name(name, suffix);
            while matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                self.index += 1;
                if let TokenKind::Identifier { name: member, .. } = self.peek_kind().clone() {
                    self.index += 1;
                    full = format!("{full}.{member}");
                } else if let TokenKind::Keyword(kw) = self.peek_kind().clone() {
                    self.index += 1;
                    full = format!("{full}.{kw:?}");
                } else {
                    break;
                }
            }
            (full, None)
        } else {
            (name, suffix)
        };
        // Handle array access after dot member: host[i].alias[n] = ...
        let mut extra_index_rest: Vec<Expression> = Vec::new();
        let extra_index = if is_bracket && matches!(self.peek_kind(), TokenKind::Symbol('[')) {
            self.index += 1;
            let idx = self.expression()?;
            extra_index_rest = self.collect_extra_indices()?;
            self.expect_symbol(']')?;
            Some(idx)
        } else {
            None
        };
        let full_at = full_name(name.clone(), suffix);
        let is_at = is_at_builtin(&full_at) && (args.len() == 1 || args.len() == 2);
        if matches!(self.peek_kind(), TokenKind::Symbol('=')) && is_at {
            self.index += 1;
            let value = self.expression()?;
            self.expect_line_end()?;
            return Ok(Statement::BuiltinAssign {
                name: full_at,
                args,
                value,
            });
        }
        if let Some(idx) = extra_index {
            if matches!(self.peek_kind(), TokenKind::Symbol('=')) {
                self.index += 1;
                let value = self.expression()?;
                self.expect_line_end()?;
                let full = full_name(name, suffix);
                return Ok(Statement::ArrayAssignment {
                    target: full,
                    index: idx,
                    extra_indices: extra_index_rest,
                    value,
                });
            }
        }
        let is_mid = suffix == Some(TypeSuffix::String)
            && name == "MID"
            && (args.len() == 2 || args.len() == 3);
        if matches!(self.peek_kind(), TokenKind::Symbol('=')) && is_mid {
            self.index += 1;
            let value = self.expression()?;
            self.expect_line_end()?;
            let mut iter = args.into_iter();
            let target = iter.next().unwrap();
            let start = iter.next().unwrap();
            let length = iter.next();
            return Ok(Statement::MidAssign {
                target,
                start,
                length,
                value,
            });
        }
        if matches!(self.peek_kind(), TokenKind::Symbol('=')) && !args.is_empty() {
            self.index += 1;
            let value = self.expression()?;
            self.expect_line_end()?;
            let full = full_name(name, suffix);
            // For multi-dim arrays, only use the first dimension
            let mut it = args.into_iter();
            let index = it.next().unwrap();
            let extra_indices: Vec<Expression> = it.collect();
            return Ok(Statement::ArrayAssignment {
                target: full,
                index,
                extra_indices,
                value,
            });
        }
        self.expect_line_end()?;
        let full = full_name(name, suffix);
        Ok(Statement::Call { name: full, args })
    }
    fn function_stmt(&mut self) -> Result<Statement, ParseError> {
        while matches!(
            self.peek_keyword(),
            Some(Keyword::External) | Some(Keyword::Internal)
        ) {
            self.index += 1;
        }
        if matches!(self.peek_kind(), TokenKind::SystemVariable { .. })
            || matches!(self.peek_kind(), TokenKind::Symbol('/'))
            || matches!(self.peek_kind(), TokenKind::SharedName(_))
        {
            self.skip_to_line_end();
            self.expect_line_end()?;
            return Ok(Statement::Compound(vec![]));
        }
        if matches!(self.peek_keyword(), Some(Keyword::CFunction)) {
            self.index += 1;
        } else {
            self.expect_keyword(Keyword::Function)?;
        }
        // Skip optional return type qualifier (DOUBLE, XLONG, STRING, etc.)
        if matches!(self.peek_kind(), TokenKind::Identifier { .. }) {
            let save = self.index;
            self.index += 1;
            // If next is another identifier, the first was a return type
            if !matches!(self.peek_kind(), TokenKind::Identifier { .. })
                && !matches!(self.peek_kind(), TokenKind::Keyword(_))
            {
                self.index = save;
            }
        }
        let (name, suffix) = self.expect_name_or_keyword()?;
        let params = if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
            self.parse_params()?
        } else {
            Vec::new()
        };
        // Skip optional return type after params: FUNCTION Xcm () DOUBLE
        if matches!(self.peek_kind(), TokenKind::Identifier { .. }) {
            self.index += 1;
        }
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        // Check for forward declaration: if next token starts another
        // function/declare/program/end, this is a declaration only
        let is_forward = self.at_eof()
            || self.is_end_program()
            || (self.peek_keyword() == Some(Keyword::Function)
                && !matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))))
            || matches!(
                self.peek_keyword(),
                Some(Keyword::Internal)
                    | Some(Keyword::CFunction)
                    | Some(Keyword::Declare)
                    | Some(Keyword::Program)
                    | Some(Keyword::Export)
            );
        if is_forward {
            return Ok(Statement::Function(FunctionDecl::new(
                name, suffix, params, body,
            )));
        }
        while !self.at_eof() && !self.starts_end_function() {
            // If we encounter a new function declaration, this is a forward declaration
            if (matches!(
                self.peek_keyword(),
                Some(Keyword::Function) | Some(Keyword::Internal) | Some(Keyword::CFunction)
            ) && !matches!(self.peek_next_kind(), Some(TokenKind::Symbol('='))))
            {
                break;
            }
            body.push(self.statement()?);
            self.skip_newlines();
        }
        if self.starts_end_function() {
            self.expect_keyword(Keyword::End)?;
            self.expect_keyword(Keyword::Function)?;
            // Skip optional function name or $$TRUE/$$FALSE after END FUNCTION
            if matches!(self.peek_kind(), TokenKind::Identifier { .. })
                || matches!(self.peek_kind(), TokenKind::SystemVariable { .. })
                || matches!(self.peek_kind(), TokenKind::SystemConstant(_))
            {
                self.index += 1;
            }
            // Optional return value: `END FUNCTION (expr)`.
            if matches!(self.peek_kind(), TokenKind::Symbol('(')) {
                let _ = self.parse_args()?;
            }
            self.expect_line_end()?;
        } else if self.at_eof() {
            return Err(self.expected("keyword"));
        }
        Ok(Statement::Function(FunctionDecl::new(
            name, suffix, params, body,
        )))
    }
    fn if_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::If)?;
        let condition = self.expression()?;
        // THEN is optional in single-line IF: IF (cond) statement
        let has_then = matches!(self.peek_keyword(), Some(Keyword::Then));
        if has_then {
            self.index += 1;
        }
        if has_then && self.at_line_end() {
            let stmt = self.parse_if_chain_with_cond(condition)?;
            self.expect_end_if()?;
            self.expect_line_end()?;
            Ok(stmt)
        } else if !has_then && self.at_line_end() {
            // Multi-line IF without THEN: `IF cond` <newline> body [ELSE body] END IF.
            // A bare `IF cond` at line end always opens a block in XBasic (THEN optional).
            self.expect_line_end()?;
            self.skip_newlines();
            let mut then_body = Vec::new();
            while !self.at_eof() && !self.starts_end_if() && !self.starts_else() {
                then_body.push(self.statement()?);
                self.skip_newlines();
            }
            let else_body = if self.starts_else() {
                self.expect_keyword(Keyword::Else)?;
                self.expect_line_end()?;
                self.skip_newlines();
                let mut body = Vec::new();
                while !self.at_eof() && !self.starts_end_if() {
                    body.push(self.statement()?);
                    self.skip_newlines();
                }
                Some(body)
            } else {
                None
            };
            self.expect_end_if()?;
            self.expect_line_end()?;
            Ok(Statement::If {
                condition,
                then_body,
                else_body,
            })
        } else {
            // Skip extra THEN (legacy: IF x THEN THEN RETURN)
            while matches!(self.peek_keyword(), Some(Keyword::Then)) {
                self.index += 1;
            }
            // Redundant `THEN THEN` (or `THEN` then newline): a block IF, not a
            // single-line one. Parse the body until END IF.
            if self.at_line_end() {
                let stmt = self.parse_if_chain_with_cond(condition)?;
                self.expect_end_if()?;
                self.expect_line_end()?;
                return Ok(stmt);
            }
            self.in_single_line_if = true;
            let body_start = self.index;
            let mut then_body = vec![self.statement()?];
            // Parse additional statements separated by : (not consumed as line end
            // when in_single_line_if is true)
            while matches!(self.peek_kind(), TokenKind::Symbol(':')) {
                self.index += 1;
                then_body.push(self.statement()?);
            }
            let consumed_newline = self.tokens[body_start..self.index]
                .iter()
                .any(|t| matches!(t.kind, TokenKind::Newline));
            let else_body =
                if !consumed_newline && matches!(self.peek_keyword(), Some(Keyword::Else)) {
                    self.index += 1;
                    let mut body = vec![self.statement()?];
                    while matches!(self.peek_kind(), TokenKind::Symbol(':')) {
                        self.index += 1;
                        body.push(self.statement()?);
                    }
                    Some(body)
                } else {
                    None
                };
            self.in_single_line_if = false;
            Ok(Statement::If {
                condition,
                then_body,
                else_body,
            })
        }
    }
    fn inc_dec_stmt(&mut self, is_inc: bool) -> Result<Statement, ParseError> {
        self.index += 1;
        let (target, suffix) = self.expect_name_or_keyword()?;
        let mut full = target;
        let mut indices: Vec<Expression> = Vec::new();
        // Walk trailing `[sub]` / `.member` groups. Subscripts are CAPTURED
        // (not discarded): `INC Ary_varData[pIndex].numElements` must increment
        // the element, not a bare flattened member name.
        loop {
            if matches!(self.peek_kind(), TokenKind::Symbol('[')) {
                self.index += 1;
                indices.push(self.expression()?);
                while matches!(self.peek_kind(), TokenKind::Symbol(',')) {
                    self.index += 1;
                    indices.push(self.expression()?);
                }
                self.expect_symbol(']')?;
            } else if matches!(self.peek_kind(), TokenKind::Symbol('.')) {
                self.index += 1;
                if let TokenKind::Identifier { name: member, .. } = self.peek_kind().clone() {
                    self.index += 1;
                    full = format!("{full}.{member}");
                } else {
                    break;
                }
            } else {
                break;
            }
        }
        self.expect_line_end()?;
        if is_inc {
            Ok(Statement::Inc { target: full, suffix, indices })
        } else {
            Ok(Statement::Dec { target: full, suffix, indices })
        }
    }
    fn swap_stmt(&mut self) -> Result<Statement, ParseError> {
        // Parse one side: `name[subs...]` (subscripts are CAPTURED, not
        // discarded - `SWAP text$[i], text$` must exchange the element with
        // the scalar). Returns (name, suffix, indices).
        fn side(p: &mut Parser) -> Result<(String, Option<TypeSuffix>, Vec<Expression>), ParseError> {
            let (target, suffix) = p.expect_name_or_keyword()?;
            let mut full = target;
            let mut indices: Vec<Expression> = Vec::new();
            while matches!(p.peek_kind(), TokenKind::Symbol('[')) {
                p.index += 1;
                indices.push(p.expression()?);
                while matches!(p.peek_kind(), TokenKind::Symbol(',')) {
                    p.index += 1;
                    indices.push(p.expression()?);
                }
                p.expect_symbol(']')?;
                if !matches!(p.peek_kind(), TokenKind::Symbol('[')) {
                    break;
                }
            }
            Ok((full, suffix, indices))
        }
        self.index += 1; // SWAP
        let (left, left_suffix, left_indices) = side(self)?;
        self.expect_symbol(',')?;
        let (right, right_suffix, right_indices) = side(self)?;
        self.expect_line_end()?;
        Ok(Statement::Swap {
            left,
            left_suffix,
            left_indices,
            right,
            right_suffix,
            right_indices,
        })
    }

    pub(crate) fn while_stmt(&mut self) -> Result<Statement, ParseError> {
        self.expect_keyword(Keyword::While)?;
        let condition = self.expression()?;
        self.expect_line_end()?;
        let mut body = Vec::new();
        self.skip_newlines();
        while !self.at_eof() && !self.starts_wend() {
            body.push(self.statement()?);
            self.skip_newlines();
        }
        self.expect_keyword(Keyword::Wend)?;
        self.expect_line_end()?;
        Ok(Statement::While { condition, body })
    }
}

fn is_at_builtin(name: &str) -> bool {
    matches!(
        name,
        "SBYTEAT"
            | "UBYTEAT"
            | "SSHORTAT"
            | "USHORTAT"
            | "SLONGAT"
            | "ULONGAT"
            | "XLONGAT"
            | "GIANTAT"
            | "SINGLEAT"
            | "DOUBLEAT"
            | "SUBADDRAT"
            | "GOADDRAT"
    )
}
