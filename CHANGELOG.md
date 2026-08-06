# Changelog

All notable changes to Moma are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and Moma follows [Semantic Versioning](https://semver.org/). See
[Versioning](README.md#versioning) in the README for the release policy.

## [2.0.0] - 2026-08-06

### Added

- `moma-divider` (`moma divider`), a marker-led horizontal rule using `—`
  (em dash), for separating sections without a full heading. `--icon` /
  `--no-icon` and the semantic flags set the marker; `--border` open
  (default) prints a bare rule, `line` and `mirror` both frame it with a
  bare `┌` above and `└` below.
- `moma-sub-title` (`moma sub-title`), a rule-first secondary title: the
  same marker + padding line as `moma-title-sub`, but with the rule printed
  above the text instead of below it, and no closing row. `--icon` /
  `--no-icon` / the semantic flags and `--border mirror|line|open` work the
  same way as on `moma-title-sub`, except `--border` controls whether the
  rule above closes with a `┐`.
- `moma-title` gains `--icon` / `--no-icon` (swap or drop the `▪` marker),
  the semantic flags (set marker + color together), and
  `--border mirror|line|open` controlling the right marker: `mirror`
  (default, matches prior behavior) repeats the left marker, `line` closes
  with a plain edge instead, `open` drops the right side entirely.
- `moma-title-sub` gains the same `--icon` / `--no-icon` / semantic /
  `--border` options as `moma-title`. `--border` defaults to `open`
  (matches prior behavior: a bare underline); `mirror` closes the underline
  with `┘` and repeats the marker at the end of the line, aligned with that
  closing corner.
- `moma-resume` gains a boxed, `moma-title`-style header: setting `--icon`,
  `--no-icon`, or a semantic flag switches the title from a single open
  line to a full-width top border, marker + title line, and a blank
  separator row before the content rows. `--border mirror|line|open`
  controls the closing edge (default `mirror`, closed). Also gains
  `--width` / `--min-width` / `--max-width`.
- `moma-label` gains `--edge top|bottom` (which corner the rule uses: `┌`/
  `┐` or `└`/`┘`) and `--border line|open` (closes the far end with the
  matching corner, or leaves it a bare rule), plus `--min-width`.
- `moma-prompt` reads and returns a free-text answer directly (see Changed
  below), sharing its read/validate/secret-masking machinery with
  `moma-input`: `--default`, `--required`, `--trim`, `--secret`, `--mask`,
  and the same `--icon` / `--no-icon` / semantic / `--border` / `--cursor`
  options as `moma-title-sub`.
- A real-terminal screenshot generator (`screenshots/`): every command
  example in the README and website is now an actual PNG captured from a
  real pseudo-terminal running the built `dist/moma`, at a fixed size per
  command, instead of a hand-made or mocked image.
- Website: an output carousel showing one real screenshot per documented
  example, a lightbox for enlarged screenshots, an options-reference table
  per component, and docs restructured into topic sections.

### Changed

- **Breaking:** `moma-block` (`moma block`) renamed to `moma-resume`
  (`moma resume`). Flags and rendering are unchanged aside from the name
  and the new boxed-header options above.
- **Breaking:** `moma-prompt` no longer just prints a static lead-in line -
  it now reads and returns a free-text answer directly, the way
  `moma-input` does but with `moma-title-sub`'s look instead of a boxed
  field. Scripts that called `moma prompt "..."` as a non-blocking lead-in
  before a separate `moma select`/`moma input` call will now block waiting
  for typed input at that line; moved from the website's Visual section to
  Interactive to match.
- `moma-resume`'s default single-line title gained one column of indent
  (`┌─ Title` / `│  item`, previously `┌ Title` / `│ item`) to line up with
  the rest of the title family.
- `moma-label`'s default minimum width lowered from 40 to 35, matching
  `moma-title`, `moma-sub-title`, and `moma-divider`.
- `moma preview`'s terminal gallery: sections now mirror the website's own
  grouping (Visual, Interactive, Selection, Decorative, Utils) instead of a
  separate hand-picked narrative grouping; most components show 2-3
  representative variants instead of just the default; each example block
  dropped its purpose/description line, colors only the `$` in the example
  command, and section headings are a plain `▍` left bar instead of a
  full-width ruled box.
- Website: dropped the `moma-` prefix from component titles and
  navigation, redesigned site chrome, and enlarged screenshot previews.

### Fixed

- `moma-title-sub`'s `--border mirror` now aligns the trailing mirrored
  marker with the closing `┘` instead of always sitting one hardcoded space
  after the text.
- `moma-divider` switched from `⎼` (a scan-line character that sits near
  the bottom of the cell and renders inconsistently across terminal fonts)
  to `—` (em dash), which renders as a solid, vertically-centered rule
  almost everywhere.
- `moma-box`, `moma-label`, and `moma-input` no longer misalign their
  border when the icon - or, for `moma-label`, a truncation ellipsis - is a
  multi-byte character, under locales where Bash counts bytes rather than
  display columns instead of the display width. `moma-rabbit`'s ground-line
  length is corrected the same way.

## [1.3.0] - 2026-08-04

### Added

- `moma-block` (`moma block`), a titled, colored content block for grouping
  related information, such as a résumé section or a categorized reference
  list. Rows come from repeated `--item` (a bold term next to a muted
  description, aligned as a column) and `--text` (a plain line) flags,
  interleaved in the order given; each block can use its own color and one
  blank line follows it, so calling it repeatedly stacks blocks with
  consistent spacing.

## [1.2.1] - 2026-08-04

### Fixed

- `moma-multi-select` and `moma-multi-select-groups` no longer lose track of
  the active row when the option list is taller than the terminal.
  Interactive navigation now scrolls a fixed-size window with a "N more
  above/below" indicator instead of relying on the terminal's own
  scrollback, which redrew the full list on every keypress and made the
  highlighted row appear to jump around or scroll away.
  `moma-multi-select-groups` switches to a compact layout while scrolled
  (heading text dropped, each group's All row labeled with its group name,
  blank separators between groups kept) so every option, including ones
  scrolled well out of the initial view, stays individually selectable and
  groups stay visually distinct. `--choose` is unaffected on both and always
  renders the complete list.

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
