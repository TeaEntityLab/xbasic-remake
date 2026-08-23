use crate::token::TypeSuffix;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Program {
    pub statements: Vec<Statement>,
}

impl Program {
    pub fn new(statements: Vec<Statement>) -> Self {
        Self { statements }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Statement {
    Version(String),
    Print {
        items: Vec<Expression>,
        separators: Vec<PrintSep>,
    },
    Dim {
        name: String,
        suffix: Option<TypeSuffix>,
        size: Option<Expression>,
        /// Extra subscripts for a multi-dimensional array (`a[d0, d1, …]`); dim0
        /// stays in `size`. Empty for scalars and 1-D arrays.
        extra_dims: Vec<Expression>,
        /// `true` when the declaration carried array brackets (`a[]` or `a[n]`),
        /// distinguishing an empty array `DIM a[]` from a scalar `DIM a`.
        is_array: bool,
        /// `true` for `REDIM` (resize preserving existing contents) vs `DIM`.
        redim: bool,
        /// `true` when declared via the `SHARED` keyword (module-shared storage);
        /// array declarations then route to the interpreter's shared store.
        shared: bool,
    },
    Assignment {
        target: String,
        suffix: Option<TypeSuffix>,
        value: Expression,
    },
    ArrayAssignment {
        target: String,
        index: Expression,
        /// Extra subscripts for a multi-dimensional write (`a[i0, i1, …] = v`).
        extra_indices: Vec<Expression>,
        value: Expression,
    },
    MidAssign {
        target: Expression,
        start: Expression,
        length: Option<Expression>,
        value: Expression,
    },
    BuiltinAssign {
        name: String,
        args: Vec<Expression>,
        value: Expression,
    },
    ConstantDefinition {
        name: String,
        value: String,
    },
    SharedAssignment {
        name: String,
        suffix: Option<TypeSuffix>,
        value: Expression,
    },
    If {
        condition: Expression,
        then_body: Vec<Statement>,
        else_body: Option<Vec<Statement>>,
    },
    While {
        condition: Expression,
        body: Vec<Statement>,
    },
    DoLoop {
        pre_condition: Option<(Expression, bool)>,
        post_condition: Option<(Expression, bool)>,
        body: Vec<Statement>,
    },
    For {
        var: String,
        start: Expression,
        end: Expression,
        step: Option<Expression>,
        body: Vec<Statement>,
    },
    Return {
        value: Option<Expression>,
    },
    ExitFunction,
    Call {
        name: String,
        args: Vec<Expression>,
    },
    ExitLoop,
    ExitSelect,
    Inc {
        target: String,
        suffix: Option<TypeSuffix>,
        /// Subscripts captured from the statement's `[…]` groups, in order
        /// (`INC arr[i].m` → `[i]`); empty for plain scalars.
        indices: Vec<Expression>,
    },
    Dec {
        target: String,
        suffix: Option<TypeSuffix>,
        indices: Vec<Expression>,
    },
    Swap {
        left: String,
        left_suffix: Option<TypeSuffix>,
        /// Subscripts captured from the LEFT operand's `[...]` groups, in order.
        left_indices: Vec<Expression>,
        right: String,
        right_suffix: Option<TypeSuffix>,
        /// Subscripts captured from the RIGHT operand's `[...]` groups, in order.
        right_indices: Vec<Expression>,
    },
    Function(FunctionDecl),
    Import(String),
    Declare {
        name: String,
        args: Vec<String>,
    },
    Program(String),
    EndProgram,
    SelectCase {
        selector: Expression,
        cases: Vec<CaseClause>,
        default: Option<Vec<Statement>>,
    },
    Goto(Expression),
    Gosub(Expression),
    Label(String),
    Data(Vec<DataValue>),
    Read(Vec<(String, Option<TypeSuffix>)>),
    Stop,
    Restore(Option<String>),
    Compound(Vec<Statement>),
    TypeDecl {
        name: String,
        members: Vec<TypeMember>,
    },
    CompositeDecl {
        type_name: String,
        var: String,
        shared: bool,
        is_array: bool,
    },
}

/// One member of a composite TYPE declaration (e.g. `GIANT .a`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TypeMember {
    pub name: String,
    pub byte_size: usize,
    pub is_float: bool,
    pub is_string: bool,
    /// Raw member type keyword (e.g. `SINGLE`, or a composite type name like
    /// `BICOORD`). Used by the analyzer to recurse into nested composite members.
    pub type_name: String,
    /// For a `FUNCADDR` member, the declared param type names (e.g.
    /// `["DOG", "STRING"]`); empty for non-function-pointer members.
    pub funcaddr_params: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CaseClause {
    pub conditions: Vec<Expression>,
    pub body: Vec<Statement>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DataValue {
    Integer(String),
    Float(String),
    String(String),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrintSep {
    Semicolon,
    Comma,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Param {
    pub name: String,
    pub suffix: Option<TypeSuffix>,
    /// Composite TYPE name when the parameter's type is a composite (e.g.
    /// `GEO_BINODE`); enables the analyzer to flatten it into member params.
    pub type_name: Option<String>,
    /// `@`-prefixed pass-by-reference parameter.
    pub by_ref: bool,
    /// `true` when the parameter carried array brackets (`a[]` / `TYPE a[]`), so
    /// the analyzer flattens composite members as arrays and array access binds.
    pub is_array: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FunctionDecl {
    pub name: String,
    pub suffix: Option<TypeSuffix>,
    pub params: Vec<Param>,
    pub body: Vec<Statement>,
}

impl FunctionDecl {
    pub fn new(
        name: String,
        suffix: Option<TypeSuffix>,
        params: Vec<Param>,
        body: Vec<Statement>,
    ) -> Self {
        Self {
            name,
            suffix,
            params,
            body,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComparisonOp {
    Equal,
    NotEqual,
    Less,
    Greater,
    LessEqual,
    GreaterEqual,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ArithmeticOp {
    Add,
    Sub,
    Mul,
    Div,
    IntegerDiv,
    Mod,
    Shl,
    Shr,
    Pow,
}

impl ArithmeticOp {
    pub fn is_integer_op(self) -> bool {
        matches!(self, Self::IntegerDiv | Self::Mod | Self::Shl | Self::Shr)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UnaryOp {
    Neg,
    Pos,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BooleanOp {
    And,
    Or,
    Xor,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LogicalOp {
    And,
    Or,
    Xor,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Expression {
    StringLiteral(String),
    IntegerLiteral(String),
    FloatLiteral(String),
    SystemConstant {
        name: String,
    },
    SystemVariable {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    Identifier {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    ByRefIdentifier {
        name: String,
        suffix: Option<TypeSuffix>,
    },
    Comparison {
        op: ComparisonOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Not(Box<Expression>),
    Boolean {
        op: BooleanOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Logical {
        op: LogicalOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Arithmetic {
        op: ArithmeticOp,
        left: Box<Expression>,
        right: Box<Expression>,
    },
    Unary {
        op: UnaryOp,
        operand: Box<Expression>,
    },
    FunctionCall {
        name: String,
        args: Vec<Expression>,
    },
    ArrayAccess {
        name: String,
        index: Box<Expression>,
        /// Extra subscripts for a multi-dimensional read (`a[i0, i1, …]`).
        extra_indices: Vec<Expression>,
    },
    ArrayRef {
        name: String,
    },
    /// Address-of a function (`&Func()`), an intptr-sized function-pointer value.
    FuncAddr(String),
}
