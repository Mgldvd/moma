# Repository Instructions

## Source And Build

- Treat `src/{core,components,preview,cli}/*.sh`, `docs/moma-help.md`, `docs/moma-docs.md`, and `web/{index.html,styles.css,app.js}` as sources. `dist/moma` is generated; never edit it directly.
- `build.sh` concatenates an explicit, ordered module list and embeds the docs and preview assets. Add or reorder a module in that list, not merely under `src/`.
- Keep public functions named `moma-*`; `_moma_*` is the private namespace. The generated file must remain safe both to source under `set -euo pipefail` and to execute as a CLI.
- `src/cli/main.sh` defines the explicit dispatcher `_moma_main` and the public `moma()` shell function (`moma() { _moma_main "$@"; }`). Sourcing `dist/moma` defines both `moma` and every `moma-*` function without executing anything; the executable-only guard at the end of the generated file calls `_moma_main` directly (never `moma`) so there is one dispatcher and no recursion. Canonical usage (`moma <command>`) works identically whether the file is sourced or run as the installed executable; keep documentation and examples on that canonical form and treat direct `moma-*` calls as a documented backward-compatibility path, not the primary interface.

## Shell Style And Static Analysis

- Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) for all new or generated Shell code and when modifying existing Shell code.
- Write executable scripts for Bash with `#!/bin/bash`, use two-space indentation without tabs, keep lines at 80 characters when practical, and send error messages to stderr.
- Quote variable and command substitutions, prefer `"${name}"` for named variables, use `$(command)` instead of backticks, use `[[ ... ]]` for tests, and use arrays for argument lists.
- Run [ShellCheck](https://github.com/koalaman/shellcheck) on every new or modified Shell or Bats file. Fix all applicable findings before completing the change.
- Add a narrow `# shellcheck disable=SCxxxx` directive only when the warning is intentionally inapplicable, and place a comment next to it explaining why when the reason is not obvious.
- Run `task format` followed by `task lint` after generating or changing Shell code. Do not manually edit `dist/moma`; rebuild it from the validated source files.

## Verification

- Run `./tests/smoke.sh` for the full verification. It rebuilds `dist/moma`, runs Bash syntax checks, and exercises library, CLI, interactive, documentation, and standalone behavior.
- The smoke suite requires `rg`. TTY-specific checks run only when the system `script` command is available.
- Bats suites under `tests/{unit,integration,contract}` provide focused coverage when Bats-core is installed. For a quick syntax/build check, run `task build && task lint` before the full smoke suite.

## Cross-File Contracts

- When adding or removing a public `moma-*` function, update `tests/smoke.sh`'s `expected_functions`, `web/index.html` (`data-api`), `src/lib/README.md`, and `example.sh`; the smoke suite requires all four to match. `example.sh` and other user-facing examples use the canonical `moma <command>` invocation; the smoke check accepts either that form or the literal `moma-*` name.
- Preserve stdout as the return channel for interactive values. Prompts and controls use stderr where needed so command substitution captures only the selected or entered value.
- Use `NO_COLOR=1` and non-interactive options such as `--choose` or `--answer` in deterministic checks; tests assert exact Unicode layout and blank-line composition.
- Rebuild after changing source modules, embedded Markdown, or preview assets, and include the resulting `dist/moma` update with the source change.
- Record every notable change under the `Unreleased` heading in `CHANGELOG.md` as it lands. When cutting a release, bump `MOMA_VERSION` in `src/core/version.sh`, retitle `Unreleased` to the matching `vMAJOR.MINOR.PATCH`, update the version badge (`data-moma-version` and its `vX.Y.Z` text) and the `moma-version` preview output in `web/index.html`, and update the hardcoded expected version in `tests/smoke.sh`; the smoke suite checks all of these against `MOMA_VERSION` and the release tag. See [Versioning](README.md#versioning) for the policy.
