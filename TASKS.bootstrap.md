# XBasic 6.5.0 bootstrap/self-host backlog

Each `- [ ]` line below is one loop-dispatch task. The loop script copies this file into `state/TASKS.canon` and removes a pending line only after `checks/verify-bootstrap.sh` passes.

- [x] Add assignment parsing for `identifier = expression`, including tests for `name$ = "hello"`, numeric assignment, and trailing-token rejection.
- [x] Add semantic assignment checks: target symbol must exist, RHS type must match target type, and tests cover unknown assignment target plus string/integer mismatch.
- [x] Add typed IR assignment item and tests proving `DIM name$ / name$ = "hello" / PRINT name$` lowers with matching types.
- [x] Add a minimal CLI crate `xb` that can parse/analyze/lower a `.x` file and print a stable IR summary for the bootstrap subset.
- [x] Add a fixture under `fixtures/bootstrap/hello.x` and an integration test that runs the CLI over it.
- [x] Add a text IR emitter module that serializes the typed IR deterministically for golden-style tests without snapshotting prose.
- [ ] Add first runtime-backed interpreter for the typed IR subset: VERSION is metadata, DIM allocates a typed slot, assignment stores, PRINT appends to an output sink.
- [ ] Add semantic support for function entry lookup (`Main`) and an interpreter test that executes `FUNCTION Main ... END FUNCTION`.
- [ ] Add a minimal self-host utility written in XBasic source under `selfhost/` that the Rust CLI parses/analyzes/lowers successfully.
- [ ] Add a self-host smoke test proving the Rust-hosted compiler pipeline accepts every `.x` file under `selfhost/`.
- [ ] Document the completed Stage-0-to-Stage-1 bootstrap path in `docs/14-self-hosting-progress.md` with verifier evidence and remaining Stage-2 compiler-self-host tasks.
