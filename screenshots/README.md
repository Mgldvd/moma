# moma screenshot generator

A small, self-contained Python tool that generates terminal screenshots of
the moma CLI. It lives entirely in this folder, separate from moma's own
Bash source and from the Astro docs site under `web/`.

## What makes this different from a mockup

Every image comes from actually running the real `dist/moma` executable
inside a genuine pseudo-terminal (`pty`) - the same mechanism a real
terminal emulator uses - and capturing the exact bytes it writes, ANSI
escapes included. Those bytes are fed into a real terminal emulator
(`pyte`) to work out the resulting screen contents, which are then drawn to
a PNG and framed in a terminal-window chrome. Nothing here hand-authors or
guesses at what a command's output looks like; it's a screenshot of the
real thing.

## Every screenshot is the same size

The pty is opened at a **fixed** column/row size (`RenderConfig.cols` /
`.rows`, 84x23 by default) *before* the command ever runs, and `COLUMNS`
/ `LINES` are exported to match. moma sizes its own decorations (box width,
scroll windows, ...) from that size, so the resulting image dimensions are
a pure function of the render config - never of how much a given command
actually prints:

- Short output (`moma label "TEXT HERE"`, one line) leaves blank terminal
  rows below it.
- Output that would overflow the configured rows scrolls off the top, the
  same way it would in a real terminal.

`generate.py` asserts this after every render, so a config change that
breaks the invariant fails loudly instead of silently producing
mismatched images. The defaults (84 columns x 23 rows) were sized to fit
the widest (`moma-block`, ~66 columns) and tallest
(`moma-multi-select-groups`, ~20 lines) entries in the catalog with a
little headroom - see the `--cols`/`--rows` flags to change this.

## Setup

Managed with [uv](https://docs.astral.sh/uv/) - no manual venv or pip
required:

```bash
cd screenshots
uv sync
```

Requires Python 3.10+ (uv will fetch an interpreter if needed) and a built
`dist/moma` (`../build.sh` from the repo root, or `task build`).

## Usage

```bash
uv run generate.py                          # every command in the catalog
uv run generate.py --list                   # show available command ids
uv run generate.py --commands block box     # only these
uv run generate.py --output ../.img         # regenerate the repo's docs/README screenshots
uv run generate.py --cols 100 --rows 30      # a different fixed terminal size
```

Images are written to `screenshots/output/<command-id>.png` by default.
That's a **staging** folder, not the final destination: review what lands
there, then move the ones you want to keep into `../.img` (overwriting the
project's real screenshots) as a separate, deliberate step - `--output
../.img` does that directly once you're ready to publish, skipping the
staging folder.

## How it's organized

```
screenshots/
  generate.py              CLI entry point
  pyproject.toml           uv-managed dependencies (Pillow, pyte)
  assets/fonts/            bundled DejaVu Sans Mono (regular + bold)
  moma_screenshots/
    commands.py             catalog of `moma ...` invocations to capture
    capture.py               runs one command in a real pty, returns a pyte.Screen
    render.py                 pyte.Screen -> framed PNG (fixed size, terminal chrome)
    palette.py                 ANSI color -> RGB, matched to the docs site's theme
  output/                  staged PNGs, reviewed here before moving to ../.img
```

### `capture.py`

Opens a pty pair, sizes the slave end with `TIOCSWINSZ`, runs
`bash -c '<script>'` with the slave as its stdin/stdout/stderr, and reads
the master end until the process exits (or a timeout fires). The captured
bytes are fed to a `pyte.Screen` sized to match, which is the thing that
actually interprets cursor movement, redraws, and color the same way a
terminal emulator would.

### `commands.py`

One entry per moma component, each a real shell snippet run after
`source dist/moma`. Interactive components use their non-interactive flags
(`--choose`, `--answer`) for a deterministic result, exactly like
`src/preview/main.sh` and `example.sh` already do elsewhere in this repo.
`moma-update` is intentionally excluded - it performs a real network
install and has no non-interactive equivalent, so it isn't safe to run
unattended from a screenshot tool.

To add a new command: add a `Command(id=..., title=..., script=...)` entry.
`id` should match the `.img/<id>.png` naming convention used elsewhere in
the repo if you intend the output to replace one of those.

### `render.py`

Turns one `pyte.Screen` into a PNG:

- Renders at `supersample`x internally (2x by default) and downsamples with
  Lanczos for crisp anti-aliased text and rounded corners; the *layout*
  math (cell size, padding, final canvas size) is always computed at 1x
  first and only then scaled up, so the downsampled result is always
  exactly what `canvas_size()` predicts - never off by a stray rounding
  pixel.
- Unicode Block Elements (`█ ▀ ▄ ▌ ▐ ░ ▒ ▓`) - what moma's Pagga ASCII art
  (`moma-header`) is built from - are drawn as plain filled rectangles
  instead of trusting the font's glyph outlines. General-purpose fonts hint
  these with a little internal padding, which leaves visible seams between
  adjacent cells; real terminal emulators special-case this same Unicode
  block for exactly that reason, and so do we.
- `moma-rabbit`'s ground line (`⎺`, U+23BA HORIZONTAL SCAN LINE-1) isn't in
  DejaVu Sans Mono's coverage and would otherwise render as a tofu box;
  it's drawn geometrically too.

### `palette.py`

Maps pyte's reported colors - `"default"`, a named ANSI color, or a 6-digit
truecolor hex string - to RGB. The window chrome and the standard 16-color
ANSI palette are matched to the moma docs site's own dark theme
(`web/src/styles/_tokens.scss`) so a CLI screenshot and the website's
terminal-window mockups read as the same product. Truecolor escapes (moma's
pink accent and gray muted text) are rendered at their exact literal RGB
regardless of this palette, because that's what real terminal fidelity
requires.

## Fonts

`assets/fonts/` bundles DejaVu Sans Mono (regular + bold) rather than
depending on whatever happens to be installed on the machine running this
tool - see `assets/fonts/DEJAVU-LICENSE.txt` for its (permissive) license.
It was chosen for its broad coverage of the box-drawing and block-element
glyphs moma's components actually use.

## Known limitations

- Every glyph is assumed single-width. moma's own character set (box
  drawing, block elements, arrows, checkmarks) is single-width in practice,
  so this hasn't needed full East-Asian-width handling, but a component
  that started printing wide (e.g. CJK or emoji) characters wouldn't align
  correctly without extending `render.py`.
- Colors come from a fixed, hardcoded ANSI-16 palette (see `palette.py`),
  not from moma's theme system (`moma --theme NAME`) - screenshots always
  reflect moma's shipped defaults.
