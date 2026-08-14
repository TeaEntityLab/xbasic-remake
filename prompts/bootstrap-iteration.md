# Bootstrap loop iteration prompt

You are working in `/Users/teee/dev/xbasic-remake`, the repo-root XBasic 6.5.0 Rust workspace.

Complete exactly the one backlog task shown below, then stop. Do not broaden the language subset beyond that task.

## Rules

- Keep all Rust source files under 250 pure LOC.
- No `unsafe`; if a task appears to need unsafe/FFI, stop and leave the task uncompleted.
- No new dependencies unless the task explicitly requires one and std/workspace code cannot do it.
- Add behavior tests before or with implementation.
- Do not edit `checks/verify-bootstrap.sh`, `scripts/bootstrap-loop.sh`, `TASKS.bootstrap.md`, or `state/TASKS.canon` from inside the agent body.
- Run: `cargo fmt --all -- --check`, `cargo check --workspace`, `cargo test --workspace`, `cargo clippy --workspace --all-targets`.

## Current task

{{TASK}}

## Ledger tail

{{LEDGER}}

## Last verifier output

{{VERIFY_OUTPUT}}
