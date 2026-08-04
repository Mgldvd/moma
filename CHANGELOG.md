# Changelog

All notable changes to Moma are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and Moma follows [Semantic Versioning](https://semver.org/). See
[Versioning](README.md#versioning) in the README for the release policy.

## [Unreleased]

### Fixed

- `moma-multi-select` no longer loses track of the active row when the
  option list is taller than the terminal. Interactive navigation now
  scrolls a fixed-size window with a "N more above/below" indicator instead
  of relying on the terminal's own scrollback, which redrew the full list
  on every keypress and made the highlighted row appear to jump around or
  scroll away. `--choose` is unaffected and always renders the complete
  list.

## [1.2.0] - 2026-08-03

### Added

- Canonical `moma <command>` dispatcher (`moma() { _moma_main "$@"; }`),
  defined the same way whether `dist/moma` is sourced or run as the
  installed executable. Direct `moma-*` functions (for example
  `moma-msg-simple`) remain callable for backward compatibility.
- Top-level `--version` and `-v` flags, equivalent to `moma version`.
- A focusable "Select All" row and a per-group "All" row for
  `moma multi-select-groups`, toggling every option across all groups or
  within one group.
- Website: Bash syntax highlighting on every code block (component
  signatures, usage examples, and the hero quick-start commands).
- Website: a "Copy" button on every code block.
- Website: responsive off-canvas component navigation with a mobile menu
  button, scroll-spy `aria-current` highlighting, and filtering that keeps
  the sidebar in sync with the visible components.
- Website: a version badge in the site header, kept in sync with
  `MOMA_VERSION`.
- This changelog and a documented versioning policy.

### Changed

- `moma preview web` now opens the hosted GitHub Pages documentation
  (`https://mgldvd.github.io/moma/`) in the default browser instead of
  starting a local Python HTTP server; `python3` is no longer required for
  it.
- README, `docs/moma-docs.md`, `docs/moma-help.md`, `example.sh`, and the
  website now use the canonical `moma <command>` form throughout instead of
  mixing it with `moma-*` and `./dist/moma`.
- Website: hero quick-start commands now share the same background
  treatment as the other code blocks on the page, and the Preview/Load/
  Install commands are grouped into distinct bordered cards for clarity.

### Removed

- Website: the "Stable" / "Interactive" / "N variants" status badges, which
  duplicated information already stated by the surrounding content.

## [1.1.0] - 2026-08-03

### Added

- `moma single-select-groups` and `moma multi-select-groups`, selecting one
  or multiple values organized under named groups.

### Changed

- Selection components split into single- and multi-select variants;
  `moma select` remains a compatibility alias for `moma single-select`.

## [1.0.0] - 2026-08-03

### Added

- Initial public release: the core visual and interactive component
  library (`header`, `title`, `title-sub`, `section`, `msg`, `msg-simple`,
  `list`, `box`, `prompt`, `label`, `input`, `select`, `multi-select`,
  `rabbit`, `confirm`, `spinner`, `command-check`), the `moma` CLI
  dispatcher, `moma version`, and `moma update` for self-updating an
  installed executable.

[Unreleased]: https://github.com/Mgldvd/moma/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/Mgldvd/moma/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Mgldvd/moma/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Mgldvd/moma/releases/tag/v1.0.0
