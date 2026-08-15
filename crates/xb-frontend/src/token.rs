#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SourcePos {
    pub line: usize,
    pub column: usize,
}

impl SourcePos {
    pub const fn new(line: usize, column: usize) -> Self {
        Self { line, column }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TypeSuffix {
    String,
    Integer,
    Single,
    Double,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Keyword {
    Function,
    End,
    Declare,
    Internal,
    External,
    CFunction,
    If,
    Then,
    Else,
    ElseIf,
    Select,
    Case,
    For,
    To,
    Next,
    Step,
    Do,
    Loop,
    While,
    Until,
    Wend,
    Return,
    Dim,
    Type,
    Packed,
    Print,
    Import,
    And,
    Or,
    Not,
    Mod,
    Exit,
    Version,
}
impl Keyword {
    pub fn parse(input: &str) -> Option<Self> {
        match input.to_ascii_uppercase().as_str() {
            "FUNCTION" => Some(Self::Function),
            "END" => Some(Self::End),
            "DECLARE" => Some(Self::Declare),
            "INTERNAL" => Some(Self::Internal),
            "EXTERNAL" => Some(Self::External),
            "CFUNCTION" => Some(Self::CFunction),
            "IF" => Some(Self::If),
            "THEN" => Some(Self::Then),
            "ELSE" => Some(Self::Else),
            "ELSEIF" => Some(Self::ElseIf),
            "SELECT" => Some(Self::Select),
            "TO" => Some(Self::To),
            "FOR" => Some(Self::For),
            "NEXT" => Some(Self::Next),
            "STEP" => Some(Self::Step),
            "DO" => Some(Self::Do),
            "WHILE" => Some(Self::While),
            "UNTIL" => Some(Self::Until),
            "WEND" => Some(Self::Wend),
            "LOOP" => Some(Self::Loop),
            "RETURN" => Some(Self::Return),
            "DIM" => Some(Self::Dim),
            "TYPE" => Some(Self::Type),
            "PACKED" => Some(Self::Packed),
            "PRINT" => Some(Self::Print),
            "IMPORT" => Some(Self::Import),
            "AND" => Some(Self::And),
            "OR" => Some(Self::Or),
            "NOT" => Some(Self::Not),
            "MOD" => Some(Self::Mod),
            "EXIT" => Some(Self::Exit),
            "VERSION" => Some(Self::Version),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Token {
    pub kind: TokenKind,
    pub pos: SourcePos,
}

impl Token {
    pub const fn new(kind: TokenKind, pos: SourcePos) -> Self {
        Self { kind, pos }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TokenKind {
    Keyword(Keyword),
    Identifier {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    SystemConstant(String),
    SystemVariable {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    SharedName(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    StringLiteral(String),
    ColonColon,
    LessEqual,
    GreaterEqual,
    NotEqual,
    Power,
    Symbol(char),
    Newline,
    Eof,
}

pub fn full_name(name: String, suffix: Option<TypeSuffix>) -> String {
    match suffix {
        Some(TypeSuffix::String) => format!("{name}$"),
        Some(TypeSuffix::Single) => format!("{name}!"),
        Some(TypeSuffix::Double) => format!("{name}#"),
        Some(TypeSuffix::Integer) => format!("{name}%"),
        None => name,
    }
}
