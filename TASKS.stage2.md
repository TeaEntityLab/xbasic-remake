# XBasic 6.5.0 Stage-2 M1 backlog

`TASKS.bootstrap.md` is closed and immutable. Its baseline working-file hash is
`f554e9fd44d013b7ab59d14872bd9db0c56602392491874171b6ff158cc35aac` and must not change.

Each `- [ ]` line below is one loop-dispatch task. The loop script copies this file into
`state/TASKS.canon` and removes a pending line only after `checks/verify-bootstrap.sh`
passes. `state/TASKS.canon` must be absent before the first Stage-2 loop so the loop
copies this file fresh instead of resuming the closed bootstrap backlog. Agents must not
commit; the loop detects progress from the working tree.

Run the Stage-2 loop with the exact invocation:

```sh
TASKS=./TASKS.stage2.md AGENT_CMD='<host agent command>' scripts/bootstrap-loop.sh
```

- [x] Freeze the Stage-2 M1 v0.1 source, typed-IR, diagnostic, and interpreter contract without changing the completed bootstrap backlog.
- [x] Add stable compile diagnostic identifiers with exhaustive unit coverage for every current LexError, ParseError, SemanticError, and CompileError variant.
- [x] Add the LLVM-independent corpus harness with strict missing, orphan, unexpected-file, and diagnostic-coverage assertions.
- [x] Add the complete positive and negative v0.1 source corpus with byte-exact text-IR, output, and diagnostic-code goldens.
- [x] Execute the live selfhost/xut_bootstrap_manifest.x through FrontendUnit lowering and Interpreter::execute_main against committed IR and output goldens.
- [x] Run all Stage-2 M1 gates and close TASKS.stage2.md only after the contract, corpus, diagnostics, safety, and bootstrap regressions pass.
