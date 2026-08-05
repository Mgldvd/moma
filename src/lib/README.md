# Moma Source Index

Moma uses layered source modules under `src/`. The legacy `src/lib` directory
retains this index for source navigation and public API contract checks.

`src/cli/main.sh` defines the explicit dispatcher `_moma_main` and the public
`moma()` shell function (`moma() { _moma_main "$@"; }`). Sourcing `dist/moma`
defines `moma`, so `moma <command>` works the same way whether the library is
sourced or the generated file is run as the installed executable. Every
public function below also remains directly callable (for example
`moma-title`) for backward compatibility with existing scripts; both forms
dispatch through the same implementation.

## Core

| Path | Responsibility |
| --- | --- |
| [`src/core/`](../core/) | Runtime, validation, theme configuration, colors, terminal handling, and command metadata. |

Core helpers use the private `_moma_*` namespace. Theme inputs use
`MOMA_COLOR_*`, `MOMA_STYLE_*`, and `MOMA_THEME`.

## Components

| Source | Public functions |
| --- | --- |
| [`header.sh`](../components/header.sh) | `moma-header` |
| [`title.sh`](../components/title.sh) | `moma-title`, `moma-title-sub`, `moma-sub-title` |
| [`section-message.sh`](../components/section-message.sh) | `moma-section`, `moma-msg` |
| [`simple-list.sh`](../components/simple-list.sh) | `moma-msg-simple`, `moma-list` |
| [`box.sh`](../components/box.sh) | `moma-box` |
| [`resume.sh`](../components/resume.sh) | `moma-resume` |
| [`divider.sh`](../components/divider.sh) | `moma-divider` |
| [`label.sh`](../components/label.sh) | `moma-label` |
| [`input.sh`](../components/input.sh) | `moma-input` |
| [`prompt.sh`](../components/prompt.sh) | `moma-prompt` |
| [`select-common.sh`](../components/select-common.sh) | Private selection rendering, transition, and group-validation helpers |
| [`single-select.sh`](../components/single-select.sh) | `moma-single-select`, `moma-select` (alias) |
| [`single-select-groups.sh`](../components/single-select-groups.sh) | `moma-single-select-groups` |
| [`multi-select.sh`](../components/multi-select.sh) | `moma-multi-select` |
| [`multi-select-groups.sh`](../components/multi-select-groups.sh) | `moma-multi-select-groups` |
| [`rabbit.sh`](../components/rabbit.sh) | `moma-rabbit` |
| [`interaction.sh`](../components/interaction.sh) | `moma-confirm`, `moma-spinner` |
| [`command-check.sh`](../components/command-check.sh) | `moma-command-check` |
| [`version.sh`](../core/version.sh) | `moma-version`, `moma-update` |

## Interfaces

| Path | Responsibility |
| --- | --- |
| [`src/preview/`](../preview/) | Terminal, Markdown, and browser previews. |
| [`src/cli/`](../cli/) | Executable help and explicit command dispatch. |

Build the standalone artifact after changing a source module.

```bash
task build
```

Read the [public API reference](../../docs/moma-docs.md) for component usage
and the [architecture guide](../../docs/architecture.md) for internal
contracts.
