//! Tests that `.dec` file TYPE definitions and EXTERNAL FUNCTION/CFUNCTION
//! declarations are processed and made available to the compiler when a
//! `.x` file imports them.

use xb_compiler::{FrontendUnit, Statement};

/// A `.dec` file with a TYPE definition and EXTERNAL FUNCTION declarations
/// should parse successfully, yielding TypeDecl and Function statements.
#[test]
fn dec_file_type_and_external_parsed() {
    let dec_src = "\
TYPE UTM
\tSLONG      .tm_sec
\tSLONG      .tm_min
\tSLONG      .tm_hour
END TYPE
EXTERNAL FUNCTION UTM  gmtime     (addrTime)
EXTERNAL CFUNCTION  calloc         (bytes)
EXTERNAL FUNCTION DOUBLE  sqrt        (DOUBLE x)
";
    let unit = FrontendUnit::parse(dec_src).expect("dec parse");
    let stmts = unit.program().statements.clone();

    // Should have 4 statements: 1 TypeDecl + 3 Function (all forward/empty body)
    let type_decls: Vec<_> = stmts
        .iter()
        .filter(|s| matches!(s, Statement::TypeDecl { .. }))
        .collect();
    let func_decls: Vec<_> = stmts
        .iter()
        .filter(|s| matches!(s, Statement::Function(f) if f.body.is_empty()))
        .collect();

    assert_eq!(
        type_decls.len(),
        1,
        "expected 1 TypeDecl, got {type_decls:?}"
    );
    assert_eq!(
        func_decls.len(),
        3,
        "expected 3 forward Function decls, got {func_decls:?}"
    );

    // Verify TYPE name
    if let Statement::TypeDecl { name, members } = &type_decls[0] {
        assert_eq!(name, "UTM");
        assert_eq!(members.len(), 3);
        assert_eq!(members[0].name, "tm_sec");
    } else {
        panic!("expected TypeDecl");
    }

    // Verify function names
    let func_names: Vec<String> = func_decls
        .iter()
        .filter_map(|s| {
            if let Statement::Function(f) = s {
                Some(f.name.clone())
            } else {
                None
            }
        })
        .collect();
    assert!(func_names.contains(&"gmtime".to_string()));
    assert!(func_names.contains(&"calloc".to_string()));
    assert!(func_names.contains(&"sqrt".to_string()));
}

/// A `.dec` file with `$$` constants after EXTERNAL FUNCTION declarations
/// should parse successfully — the `$$` constants should not cause the
/// parser to expect a function body.
#[test]
fn dec_file_constants_after_external_parsed() {
    let dec_src = "\
EXTERNAL FUNCTION Foo ()
EXTERNAL FUNCTION Bar ()
\t$$MAX_TASKS = 15
\t$$PATH_SLASH$ = \"/\"
";
    let unit = FrontendUnit::parse(dec_src).expect("dec parse");
    let stmts = unit.program().statements.clone();

    // Should have 4 statements: 2 Function (forward) + 2 ConstantDefinition
    let func_decls: Vec<_> = stmts
        .iter()
        .filter(|s| matches!(s, Statement::Function(f) if f.body.is_empty()))
        .collect();
    let const_defs: Vec<_> = stmts
        .iter()
        .filter(|s| matches!(s, Statement::ConstantDefinition { .. }))
        .collect();

    assert_eq!(func_decls.len(), 2, "expected 2 forward Function decls");
    assert_eq!(const_defs.len(), 2, "expected 2 ConstantDefinition");
}

/// A `.dec` file with a large TYPE definition (like clib.dec's MALLINFO)
/// should parse all members correctly.
#[test]
fn dec_file_large_type_parsed() {
    let dec_src = "\
TYPE MALLINFO
\tULONG   .arena
\tULONG   .ordblks
\tULONG   .smblks
\tULONG   .hblks
\tULONG   .hblkhd
\tULONG   .usmblks
\tULONG   .fsmblks
\tULONG   .wordblks
\tULONG   .fordblks
\tULONG   .keepcost
END TYPE
";
    let unit = FrontendUnit::parse(dec_src).expect("dec parse");
    let stmts = unit.program().statements.clone();

    let type_decls: Vec<_> = stmts
        .iter()
        .filter(|s| matches!(s, Statement::TypeDecl { .. }))
        .collect();
    assert_eq!(type_decls.len(), 1);

    if let Statement::TypeDecl { name, members } = &type_decls[0] {
        assert_eq!(name, "MALLINFO");
        assert_eq!(members.len(), 10);
        assert_eq!(members[0].name, "arena");
        assert_eq!(members[9].name, "keepcost");
    } else {
        panic!("expected TypeDecl");
    }
}

/// Regular FUNCTION bodies with `$$` constants inside should still parse
/// correctly — the `is_external` gate ensures `$$` constants only signal
/// "no body" for EXTERNAL/INTERNAL declarations.
#[test]
fn function_body_with_constants_still_parses() {
    let src = "\
$$XBSysLinux = 1
FUNCTION Main
$$Local = 0x2
PRINT $$XBSysLinux
END FUNCTION
";
    let unit = FrontendUnit::parse(src).expect("parse");
    let stmts = &unit.program().statements;

    // First statement: top-level $$ constant
    assert!(matches!(
        stmts[0],
        Statement::ConstantDefinition { ref name, ref value }
            if name == "XBSysLinux" && value == "1"
    ));

    // Second statement: FUNCTION with body containing $$ constant
    if let Statement::Function(f) = &stmts[1] {
        assert_eq!(f.name, "Main");
        assert_eq!(f.body.len(), 2, "body should have 2 statements");
        assert!(matches!(
            f.body[0],
            Statement::ConstantDefinition { ref name, ref value }
                if name == "Local" && value == "0x2"
        ));
    } else {
        panic!("expected Function");
    }
}
