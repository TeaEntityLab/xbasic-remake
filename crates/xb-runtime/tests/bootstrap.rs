use xb_compiler::{FrontendUnit, TextIrEmitter};
use xb_runtime::Interpreter;

fn root() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn stage0_ir(source: &str) -> String {
    let unit = FrontendUnit::parse(source).unwrap();
    let program = unit.lower_ir().unwrap();
    TextIrEmitter::new().emit_program(&program)
}

fn stage1_ir(compiler_source: &str, target_source: &str) -> String {
    let unit = FrontendUnit::parse(compiler_source).unwrap();
    let program = unit.lower_ir().unwrap();
    let input: Vec<Vec<u8>> = target_source
        .lines()
        .map(|l| l.as_bytes().to_vec())
        .collect();
    let mut output = Vec::new();
    Interpreter::new()
        .execute_main_with_input(&program, input, &mut output)
        .unwrap();
    output.into_iter().map(|l| format!("{l}\n")).collect()
}

#[test]
fn compiler_self_compilation_produces_identical_ir() {
    let compiler_source = std::fs::read_to_string(root().join("selfhost/compiler.x")).unwrap();
    let s0 = stage0_ir(&compiler_source);
    let s1 = stage1_ir(&compiler_source, &compiler_source);
    assert_eq!(s0, s1, "Stage-0 and Stage-1 IR must be identical");
}

#[test]
fn stage1_matches_stage0_on_corpus_programs() {
    let compiler_source = std::fs::read_to_string(root().join("selfhost/compiler.x")).unwrap();
    let programs: &[(&str, &str)] = &[
        ("hello", "VERSION \"0.1\"\nPRINT \"hello\"\n"),
        ("arith", "VERSION \"0.1\"\nDIM x\nx = 3 + 4 * 2\nPRINT x\n"),
        ("if_else", "VERSION \"0.1\"\nDIM x\nx = 5\nIF x > 3 THEN\nPRINT \"big\"\nELSE\nPRINT \"small\"\nEND IF\n"),
        ("while", "VERSION \"0.1\"\nDIM i\ni = 0\nWHILE i < 5\nPRINT i\ni = i + 1\nWEND\n"),
        ("for_next", "VERSION \"0.1\"\nDIM i\nFOR i = 1 TO 3\nPRINT i\nNEXT i\n"),
        ("function", "VERSION \"0.1\"\nFUNCTION add(a, b)\nRETURN a + b\nEND FUNCTION\nDIM r\nr = add(3, 4)\nPRINT r\n"),
        ("elseif", "VERSION \"0.1\"\nDIM x\nx = 2\nIF x = 1 THEN\nPRINT \"one\"\nELSEIF x = 2 THEN\nPRINT \"two\"\nELSE\nPRINT \"other\"\nEND IF\n"),
        ("array", "VERSION \"0.1\"\nDIM a(10)\nDIM i\nFOR i = 1 TO 5\na(i) = i * i\nNEXT i\nPRINT a(3)\n"),
        ("strings", "VERSION \"0.1\"\nDIM s$\ns$ = \"hello\"\nPRINT LEN(s$)\nPRINT LEFT$(s$, 2)\n"),
        ("standalone_call", "VERSION \"0.1\"\nFUNCTION greet()\nPRINT \"hi\"\nEND FUNCTION\ngreet()\n"),
    ];
    for (name, source) in programs {
        let s0 = stage0_ir(source);
        let s1 = stage1_ir(&compiler_source, source);
        assert_eq!(s0, s1, "Stage-1 mismatch on {name}");
    }
}
