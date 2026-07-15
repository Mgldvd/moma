# Architecture

## Layers

Moma is assembled from ordered Bash modules into one generated `dist/moma`
artifact.

```text
src/core
    ↑
src/components
    ↑
src/preview and src/cli
```

- `src/core/` contains runtime checks, errors, strings, validation, palette,
  semantics, terminal operations, and command metadata. It does not call public
  components.
- `src/components/` implements the public `moma-*` functions. Components may
  call core helpers and other public components where composition is useful.
- `src/preview/` consumes the public API to render examples and serve embedded
  documentation.
- `src/cli/` validates command names against the registry and dispatches through
  an explicit allowlist. It does not use `eval`.

The ordered module list in `build.sh` is the dependency graph used to create the
standalone artifact.

## Naming

- `moma-*` functions are public and covered by API contract tests.
- `_moma_*` functions are private and may change between releases.
- `MOMA_COLOR_*` and `MOMA_STYLE_*` are documented theme inputs initialized at
  source time while preserving values already supplied by the consumer.

## Public API

The command registry in `src/core/registry.sh` maps each executable command to
its public function and short description. The registry, CLI, web metadata,
examples, source index, and smoke expectations must remain synchronized.

Library usage:

```bash
source dist/moma
moma-msg "Ready" --success
```

Executable usage:

```bash
./dist/moma msg "Ready" --success
```

## Output Contract

- stdout carries a component's primary output or consumable data.
- stderr carries diagnostics and interactive controls.
- `moma-input`, `moma-select`, and `moma-multi-select` emit captured values only
  on stdout while their prompts and controls use stderr.
- `moma-confirm` communicates its result through its exit status and renders its
  controls on stderr.
- `moma-spinner` renders animation on stderr. Its final semantic completion
  message remains the primary stdout output for compatibility.
- Non-interactive visual components intentionally render their primary display
  on stdout.

## Exit Statuses

```text
0    completed successfully or affirmative result
1    expected negative result or legacy component failure
2    invalid usage or arguments for interactive and dispatcher contracts
3    runtime or environment failure
130  user cancellation or interruption
```

`moma-confirm` reserves status 1 for “no”. `moma-command-check` uses status 1
when any command is missing. Some established visual-component validation paths
retain status 1 for backward compatibility; new shared usage errors use status
2 internally unless a public compatibility contract overrides them.

## Terminal Handling

`src/core/terminal.sh` owns TTY detection, width lookup, cursor visibility,
line clearing, cursor movement, and key decoding. Non-TTY calls are no-ops where
appropriate.

Select and confirm components keep transition logic separate from rendering and
key input, so transitions can be tested without a terminal. Spinner installs
temporary signal and cleanup traps only inside a subshell. Its `EXIT` cleanup
always restores the cursor, and the caller's traps are never replaced.

Moma does not permanently modify `stty`, `IFS`, shell options, `shopt`, the
working directory, or consumer traps when sourced.

## Build Flow

`build.sh` performs these stages:

1. Validate every embedded document, web asset, and ordered module.
2. Create a temporary artifact in the destination directory.
3. Embed Markdown and web assets.
4. Concatenate core, component, preview, and CLI modules in dependency order.
5. Add the executable-only `_moma_main` guard.
6. Run `bash -n` on the complete temporary artifact.
7. Set executable permissions and atomically rename it to `dist/moma`.
8. Remove the temporary file on any failure.

The inputs contain no timestamps or temporary paths, so identical sources
produce identical artifact bytes.

## Verification

- `tests/smoke.sh` covers the existing API, exact rendering, CLI, library,
  pseudo-TTY, documentation, preview, and standalone contracts.
- `tests/unit/` covers pure validation, semantic, and state-transition helpers.
- `tests/integration/` covers CLI/library equivalence and stdout/stderr routing.
- `tests/contract/` covers public API metadata and safe `source` behavior.
- `make test`, `make lint`, `make format`, and `make check` are development
  entrypoints. Bats-core, ShellCheck, and shfmt are development-only tools.
- ShellCheck runs on source modules and test scripts. The concatenated artifact
  is syntax-checked instead because cross-function local names in one generated
  file produce false array/scalar warnings that do not occur in separate source
  modules.
