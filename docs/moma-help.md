# Moma

Terminal UI components and workflow helpers for Bash.

Requires Bash 4.0 or newer.

Repository: <https://github.com/Mgldvd/moma>

## Usage

```bash
moma <command> [arguments] [options]
```

Use the installed executable directly, or source the library first to make
the same `moma` command available as a shell function in the current shell:

```bash
source dist/moma
moma <command> [arguments] [options]
```

Existing scripts that call direct `moma-*` functions (for example
`moma-msg-simple`) keep working after `source dist/moma`; they remain
supported for backward compatibility but are not the recommended interface.

## Component commands

| Command | Description |
| --- | --- |
| `header` | Print a Pagga ASCII heading. |
| `title` | Print a title and subtitle. |
| `title-sub` | Print a secondary title. |
| `section` | Print a section heading. |
| `msg` | Print a styled message. |
| `msg-simple` | Print a simple message with a dot marker. |
| `list` | Print an unordered list. |
| `box` | Print a boxed message. |
| `block` | Print a titled, colored content block. |
| `prompt` | Print a prompt. |
| `label` | Print a decorated input-style label. |
| `input` | Print or read an input field. |
| `select` | Select one value with the arrow keys (alias for `single-select`). |
| `single-select` | Select one value with the arrow keys. |
| `single-select-groups` | Select one value from named groups with the arrow keys. |
| `multi-select` | Select multiple values with the arrow keys and Space. |
| `multi-select-groups` | Select multiple values from named groups with the arrow keys and Space. |
| `rabbit` | Print the Moma rabbit component. |

## Helper commands

| Command | Description |
| --- | --- |
| `confirm` | Select Yes or No with the arrow keys or `y` and `n`. |
| `spinner` | Follow a process and print completion feedback. |
| `command-check` | Check whether executables are available. |
| `version` | Print the installed version. |
| `update` | Download and install the latest version. |

## Documentation commands

| Command | Description |
| --- | --- |
| `help` | Show this help with Glow when available. |
| `themes` | List configured color themes. |
| `preview` | Show the terminal reference. |
| `preview md` | Show the Markdown reference with Glow when available. |
| `preview web` | Open the hosted Moma documentation website in the default browser. |

## Remote preview

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview
```

## Global options

- `--theme <name>`: Use a configured color theme for this command.
- `--version`, `-v`: Print the installed version and exit. Recognized only
  as a leading argument, before a command is selected.
- `-h`, `--help`: Show help.

## Color themes

Create `~/.config/momaui/moma.confg` with a complete `[theme default]` section.
Define reusable ANSI SGR colors in `[colors]` and additional themes in
`[theme name]` sections.

```ini
[colors]
violet = \033[38;2;189;147;249m

[theme default]
primary = cyan
accent = yellow
muted = gray
success = green
error = red
warning = yellow
info = cyan

[theme night]
primary = violet
```

```bash
moma themes
moma --theme night msg "Ready"
MOMA_THEME=night moma msg "Ready"
```

Additional themes inherit omitted roles from `default`. Set `MOMA_CONFIG_FILE`
to load a different configuration file.

## Selection components

`moma-select` is a documented compatibility alias for `moma-single-select`;
both accept the same arguments and render identically. `moma-multi-select`
keeps its existing arguments and behavior.

When an option list is taller than the terminal, `moma-multi-select` scrolls
a fixed-size window instead of letting the terminal's own scrollback carry
the active row out of view. A "N more above" / "N more below" line replaces
the hidden rows, up and down keep the active row inside the visible window,
and every redraw moves the cursor by the same number of lines regardless of
the total option count. `--choose` always prints every option, unwindowed,
so scripted and documented output stays complete and deterministic.

`moma-single-select-groups` and `moma-multi-select-groups` organize options
under repeated `--group <name>` and `--option <value>` pairs. Group headings
are display-only: they never receive focus, are never toggled, are never
counted as options, and are never printed on stdout. `--initial`, `--choose`,
and `--selected` use one-based indexes that count only options, in visual
order across every group. Up and down navigation skips headings and wraps
between the first and last focusable row across all groups.

`moma-multi-select-groups` also renders a focusable "All" row above each
group's options and a focusable "Select All" row above every group. Space on
an "All" row toggles every option in that group; Space on "Select All"
toggles every option across all groups. Both fill (`▣`) once every option in
their scope is selected, show a hatched glyph (`▨`) once some but not all
are, and are otherwise empty (`□`); toggling clears a fully selected scope
and otherwise fills whatever is still unselected. Neither row counts as an
option or is ever printed on stdout, so `--initial`, `--choose`, and
`--selected` numbering is unaffected.

When the full grouped layout is taller than the terminal, `moma-multi-select-groups`
switches to a compact scrolling window like `moma-multi-select`'s: group
heading lines are dropped, each group's "All" row is labeled with its group
name instead (for example "All · South America") and keeps its blank
separator so groups stay visually distinct, and every row — including
options deep inside a scrolled-out group — remains fully navigable and
selectable. `--choose` keeps the full layout with headings, unwindowed and
deterministic.

## Decoration width

- `MOMA_WIDTH=<number>`: Give every horizontal decoration the same fixed inner width.
- `MOMA_MAX_WIDTH=<number>`: Let decorations grow automatically, but not beyond this width.

A fixed width takes priority over a maximum width. `moma-title`,
`moma-title-sub`, `moma-box`, `moma-prompt`, `moma-label`, and `moma-input`
also accept component-level `--width` and `--max-width` options. Long boxed
content wraps inside the selected width. The minimum effective decoration
width is 8 columns and box padding may require a larger value.

## Binary examples

```bash
./dist/moma msg "Ready" --success
./dist/moma header "Moma" --color cyan
./dist/moma title "Moma" "Installer"
./dist/moma label "TEXT HERE"
./dist/moma select "Development" "Staging" "Production" --choose 2
./dist/moma single-select "Up" "Down" "Stop" --choose 1
./dist/moma single-select-groups --title "Features" \
  --group "Docker" --option "Up" --option "Down" --option "Stop" \
  --group "npm" --option "install" --option "run dev" --option "run deploy" \
  --choose 4
./dist/moma multi-select "Docker" "CI" "Tests" --choose 1,3
./dist/moma multi-select-groups --title "Features" \
  --group "North America" --option "United States" --option "Canada" --option "Mexico" \
  --group "South America" --option "Colombia" --option "Argentina" --option "Peru" \
  --choose 1,3
./dist/moma confirm "Create this project?" --default yes
./dist/moma command-check bash curl
./dist/moma themes
./dist/moma preview
./dist/moma preview web
./dist/moma version
./dist/moma --version
./dist/moma -v
```

## Library examples

```bash
source dist/moma

moma-header "Moma" --color cyan --margin-top 0 --margin-bottom 1 --margin-left 2
moma-title "Moma" "Installer"
moma-msg "Ready" --success
moma-label "TEXT HERE"
moma-select "Development" "Staging" "Production"
moma-single-select "Up" "Down" "Stop"
moma-single-select-groups \
    --title "Features" \
    --group "Docker" --option "Up" --option "Down" --option "Stop" \
    --group "npm" --option "install" --option "run dev" --option "run deploy"
moma-multi-select "Docker" "CI" "Tests"
moma-multi-select-groups \
    --title "Features" \
    --group "North America" --option "United States" --option "Canada" --option "Mexico" \
    --group "South America" --option "Colombia" --option "Argentina" --option "Peru"
if moma-confirm "Create this project?"; then
    moma-msg "Project created" --success
fi
moma-box "Important notice" --info
```

## Updates

Run these commands from an executable installation.

```bash
moma version
moma --version
moma -v
moma update
```

`moma update` requires `curl` and write permission for the installed file and
its directory. It validates the download before replacing the executable.

## Semantic styles

- `--success`
- `--error`
- `--warning`
- `--info`

Use `--color <value>`, `--icon <value>`, or `--no-color` where supported.
Set `NO_COLOR=1` to disable ANSI colors globally.

Interactive controls and diagnostics use stderr. Capturable input and selection
values use stdout. Exit statuses are 0 for success, 1 for an expected negative
result, 2 for invalid usage, 3 for a runtime failure, and 130 for cancellation.
