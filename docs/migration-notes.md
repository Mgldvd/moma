# Migration Notes

## Internal Changes

- Replaced the numbered flat source layout with `core`, `components`, `preview`,
  and `cli` layers.
- Split the former core module into version, error, string, validation, color,
  semantic, terminal, and registry modules.
- Added a Bash 4.0 runtime compatibility check with a clear status-3 failure.
- Added shared usage and runtime error helpers.
- Added an explicit command registry without dynamic evaluation.
- Split browser, Markdown, terminal preview, CLI usage, and CLI dispatch
  responsibilities into separate modules.
- Extracted pure state transitions for select, multi-select, and confirm.
- Removed multi-select's dynamically scoped mutable selection array.
- Centralized key reading and ANSI cursor operations.
- Moved spinner signal handling into a subshell, removed `eval`, guaranteed
  cursor restoration through an `EXIT` trap, and moved animation to stderr.
- Hardened `build.sh` to validate all inputs before generation and syntax-check
  the temporary artifact before atomic publication.
- Added Bats unit, integration, and contract suites, EditorConfig, and
  ShellCheck configuration.
- Replaced the Makefile with a compact `Taskfile.yml` backed by scripts in
  `.tasks/`.

## Compatibility Preserved

- All 16 public `moma-*` functions remain available.
- All existing executable command names remain available.
- `dist/moma` remains both sourceable and directly executable.
- Existing flags, non-interactive automation options, Unicode layout, color
  overrides, `NO_COLOR`, and documented theme variables remain supported.
- Existing smoke expectations for visual output, blank lines, stdout/stderr,
  exit statuses, preview assets, and strict-shell loading continue to pass.

## Intentional Behavior Changes

- Spinner animation is now written to stderr so command substitution captures
  only the final primary output.
- Plain CLI help is generated from the command registry and displays one command
  and description per line.
- A runtime older than Bash 4.0 now fails immediately with status 3 and an
  explicit compatibility message.

## Pending Risks

- Visual width calculations count Bash characters rather than terminal display
  cells, so combining characters and some wide Unicode glyphs can still produce
  alignment differences.
- Bats-core and ShellCheck must be installed separately; they are optional
  development dependencies. Formatting tasks bootstrap shfmt when needed.
- Pseudo-TTY tests still depend on the system `script` command and are skipped
  when it is unavailable.
- Static Markdown and web presentation still require cross-file contract checks
  when a public command is added or removed.
