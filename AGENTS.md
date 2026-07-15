# Repository Instructions

## Source And Build

- Treat `src/lib/*.sh`, `docs/moma-help.md`, `docs/moma-docs.md`, and `web/{index.html,styles.css,app.js}` as sources. `dist/moma` is generated; never edit it directly.
- `build.sh` concatenates an explicit, ordered module list and embeds the docs and preview assets. Add or reorder a module in that list, not merely in `src/lib/`.
- Keep public functions named `moma-*`; `_moma_*` is the private namespace. The generated file must remain safe both to source under `set -euo pipefail` and to execute as a CLI.

## Verification

- Run `./tests/smoke.sh` for the full verification. It rebuilds `dist/moma`, runs Bash syntax checks, and exercises library, CLI, interactive, documentation, and standalone behavior.
- The smoke suite requires `rg`. TTY-specific checks run only when the system `script` command is available.
- There is no separate focused test harness. For a quick syntax/build check, run `./build.sh && bash -n build.sh src/lib/*.sh dist/moma` before the full smoke suite.

## Cross-File Contracts

- When adding or removing a public `moma-*` function, update `tests/smoke.sh`'s `expected_functions`, `web/index.html` (`data-api`), `src/lib/README.md`, and `example.sh`; the smoke suite requires all four to match.
- Preserve stdout as the return channel for interactive values. Prompts and controls use stderr where needed so command substitution captures only the selected or entered value.
- Use `NO_COLOR=1` and non-interactive options such as `--choose` or `--answer` in deterministic checks; tests assert exact Unicode layout and blank-line composition.
- Rebuild after changing source modules, embedded Markdown, or preview assets, and include the resulting `dist/moma` update with the source change.
