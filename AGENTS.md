# AGENTS.md

Shared instructions for AI agents collaborating on this repository.

## Repo facts

- Rust crate: `satoridb` (edition 2021), Linux-only (io_uring/glommio).

## Common commands

- Build: `cargo build`
- Test: `cargo test`
- Format: `cargo fmt`
- Lint: `cargo clippy --all-targets --all-features -- -D warnings`

## Agent rules (keep minimal)

- Make the smallest change that satisfies the request; avoid drive-by refactors.
- Follow existing code patterns and module structure; prefer clarity over cleverness.
- When behavior changes, add/update tests in `tests/` (and keep them deterministic).
- Avoid adding new dependencies unless necessary and justified.
- Do not run/download BigANN benchmark assets unless explicitly requested (`make benchmark` can exceed ~1TB disk).
