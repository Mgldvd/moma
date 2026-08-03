# Moma Source Index

Moma uses layered source modules under `src/`. The legacy `src/lib` directory
retains this index for source navigation and public API contract checks.

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
| [`title.sh`](../components/title.sh) | `moma-title`, `moma-title-sub` |
| [`section-message.sh`](../components/section-message.sh) | `moma-section`, `moma-msg` |
| [`simple-list.sh`](../components/simple-list.sh) | `moma-msg-simple`, `moma-list` |
| [`box-prompt.sh`](../components/box-prompt.sh) | `moma-box`, `moma-prompt` |
| [`label.sh`](../components/label.sh) | `moma-label` |
| [`input.sh`](../components/input.sh) | `moma-input` |
| [`select.sh`](../components/select.sh) | `moma-select`, `moma-multi-select` |
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
