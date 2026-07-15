# Refactor Audit

This audit records the baseline observed before the architecture refactor.

## Baseline

- `./tests/smoke.sh` passes.
- `bash -n` passes for the builder, source modules, smoke suite, and generated artifact.
- The development host runs Bash 5.2.
- Bats-core, ShellCheck, and shfmt are not installed on the development host.
- The implementation already requires Bash 4.0 because it uses associative
  arrays and lowercase parameter expansion.

## Public API

The generated library exports these public functions:

```text
moma-box
moma-command-check
moma-confirm
moma-input
moma-label
moma-list
moma-msg
moma-msg-simple
moma-multi-select
moma-prompt
moma-rabbit
moma-section
moma-select
moma-spinner
moma-title
moma-title-sub
```

The executable dispatcher exposes matching command names without the `moma-`
prefix, plus `help` and `preview`.

## Risks

- Argument parsing is repeated in every component, and usage failures return a
  mixture of status 1 and status 2.
- Palette, semantic resolution, string helpers, validation, and error reporting
  share one core file, which obscures dependency boundaries.
- Select, multi-select, and confirm combine state changes, key decoding, ANSI
  cursor movement, rendering, and result emission.
- Multi-select render and emission functions depend on a dynamically scoped
  `selected_indices` array instead of receiving state explicitly.
- ANSI cursor movement is duplicated and is difficult to isolate in unit tests.
- Spinner temporarily replaces `INT` and `TERM` traps and restores them through
  `eval`. An early return from `sleep` can bypass cursor and trap restoration.
- Spinner animation currently shares stdout with the final component output.
- Web preview uses a subshell for its temporary `cd` and cleanup, which is safe
  for the caller, but this safety is not covered by a source contract test.
- Source-time behavior initializes documented theme variables. Existing tests
  cover strict-shell compatibility but not current directory, `IFS`, shell
  options, `shopt`, traps, terminal state, cursor state, or unexpected output.
- `build.sh` writes through a temporary file and validates required inputs, but
  it publishes the artifact before running `bash -n` and has no deterministic
  comparison check.
- Command names and descriptions are duplicated across the dispatcher, help,
  web metadata, examples, documentation, and smoke expectations.
- The smoke suite provides broad integration coverage but little isolated
  coverage for parsing, validation, semantic resolution, or state transitions.

## Compatibility Baseline

- Visual output is the primary stdout result for non-interactive components.
- Interactive controls render to stderr and selected or entered values render
  to stdout.
- `moma-confirm` returns 0 for yes, 1 for no, 2 for invalid input, and 130 for
  cancellation.
- `moma-command-check` returns 1 when a command is missing.
- The generated artifact can be sourced under `set -euo pipefail`.
