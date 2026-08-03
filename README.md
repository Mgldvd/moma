# Moma

<div align="center">
  <img src="./.img/moma.png" alt="Moma logo" height="300px">
</div>

Moma is a standalone Bash library and executable for terminal UI components.
It requires Bash 4.0 or newer and runs on macOS and Linux.

## Quick start

### Preview from GitHub

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview
```

### Install the executable

1. Create the local binary directory.

```bash
mkdir -p "$HOME/.local/bin"
```

2. Download Moma.

```bash
curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma -o "$HOME/.local/bin/moma"
```

3. Make the binary executable.

```bash
chmod 0755 "$HOME/.local/bin/moma"
```

4. Add the binary directory to the current shell.

```bash
export PATH="$HOME/.local/bin:$PATH"
```

5. Check the installation.

```bash
moma --help
```

Add the `PATH` export to the appropriate shell profile to keep it after the
current session.

### Check version and update

1. Check the installed version.

```bash
moma version
```

2. Download the latest executable.

```bash
moma update
```

`moma update` requires `curl` and write permission for the installed file and
its directory.

## Usage

### Load as a library

```bash
source dist/moma

moma-title "Moma" "Installer"
moma-msg "Ready" --success
moma-list "Clone repository" "Install dependencies"
```

Load the library directly from GitHub when a local copy is not available.

```bash
source <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma)
```

### Run as an executable

```bash
./dist/moma title "Moma" "Installer"
./dist/moma msg "Ready" --success
./dist/moma select "Development" "Staging" "Production"
./dist/moma confirm "Create this project?" --default yes
```

### Run the component showcase

```bash
task build
./example.sh
```

## Components

| Category | Component | Purpose |
| --- | --- | --- |
| Visual | `moma-title` | Print a primary title and subtitle. |
| Visual | `moma-title-sub` | Print a secondary title. |
| Visual | `moma-section` | Print a semantic section heading. |
| Visual | `moma-msg` | Print a styled semantic message. |
| Visual | `moma-msg-simple` | Print a compact message. |
| Visual | `moma-list` | Print an unordered list. |
| Visual | `moma-box` | Print a framed notice. |
| Visual | `moma-prompt` | Print a question lead-in. |
| Visual | `moma-label` | Print a decorated label. |
| Visual | `moma-rabbit` | Print the Moma activity component. |
| Interactive | `moma-input` | Display or read an input value. |
| Interactive | `moma-select` | Select one value. |
| Interactive | `moma-multi-select` | Select multiple values. |
| Interactive | `moma-confirm` | Select Yes or No. |
| Workflow | `moma-spinner` | Follow a running process. |
| Workflow | `moma-command-check` | Check executable dependencies. |

Open the complete component reference locally.

```bash
./dist/moma preview
```

The source reference is available in
[`docs/moma-docs.md`](docs/moma-docs.md).

## Configuration

### Decoration widths

Set one fixed inner width for supported decorations.

```bash
export MOMA_WIDTH=50
```

Set a maximum width while retaining automatic sizing.

```bash
unset MOMA_WIDTH
export MOMA_MAX_WIDTH=50
```

Override the width for one component when needed.

```bash
moma box "Important notice" --width 60
moma box "A long notice that may wrap" --max-width 40
```

Fixed width takes priority over maximum width. The minimum effective decoration
width is 8 columns.

### Colors

Use these names with component color options.

| Name | ANSI SGR sequence | Definition |
| --- | --- | --- |
| `black` | `\033[30m` | Standard terminal black |
| `red` | `\033[31m` | Standard terminal red |
| `green` | `\033[32m` | Standard terminal green |
| `yellow` | `\033[33m` | Standard terminal yellow |
| `blue` | `\033[34m` | Standard terminal blue |
| `purple` | `\033[35m` | Standard terminal magenta |
| `cyan` | `\033[36m` | Standard terminal cyan |
| `white` | `\033[37m` | Standard terminal white |
| `pink` | `\033[38;2;255;144;231m` | RGB `#ff90e7` |
| `gray` | `\033[38;2;200;200;200m` | RGB `#c8c8c8` |

The exact appearance of the standard colors depends on the terminal theme.
Use `grey` or `muted` as aliases for `gray`, `warning` or `warn` as aliases for
`yellow`, and `info` as an alias for `cyan`.

Set `NO_COLOR=1` to disable ANSI colors globally.

### Color themes

1. Create the user configuration directory.

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/momaui"
```

2. Install the example configuration.

```bash
install -m 0644 examples/moma.confg "${XDG_CONFIG_HOME:-$HOME/.config}/momaui/moma.confg"
```

3. Edit the installed configuration when needed.

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
accent = \033[38;2;255;184;108m
muted = \033[38;2;98;114;164m
success = \033[38;2;158;206;106m
error = \033[38;2;247;118;142m
warning = \033[38;2;224;175;104m
info = \033[38;2;125;207;255m
```

4. List the configured themes.

```bash
moma themes
```

5. Select a theme for one command.

```bash
moma --theme night title "Moma" "Night theme"
```

6. Select a theme before loading the library.

```bash
export MOMA_THEME=night
source dist/moma
```

Each theme role accepts a built-in name, a reusable name from `[colors]`, or an
ANSI SGR sequence. Additional themes inherit omitted roles from `default`.
Reusable custom colors also work with component-level `--color` options.

Moma loads `${XDG_CONFIG_HOME:-$HOME/.config}/momaui/moma.confg` by default.
Set `MOMA_CONFIG_FILE` to load another path. Explicit `MOMA_COLOR_*` variables
take priority over configured theme roles.

## Help and previews

```bash
./dist/moma help
./dist/moma preview
./dist/moma preview md
./dist/moma preview web
```

The web preview starts at `http://127.0.0.1:4173`. Set `MOMA_PREVIEW_PORT` to
change the starting port. Set `MOMA_HELP_WIDTH` or `MOMA_PREVIEW_WIDTH` to
change Glow's render width.

## Development

### Requirements

- Bash 4.0 or newer.
- Task 3 for development workflows.
- `rg` for the smoke suite.
- Python 3 for `preview web`.
- Bats-core and ShellCheck for the complete development checks.
- Glow optionally for rendered Markdown.
- `tput` optionally for the interactive spinner.

### Project structure

| Path | Responsibility |
| --- | --- |
| `src/core/` | Runtime, configuration, color, terminal, and registry modules. |
| `src/components/` | Public terminal UI components. |
| `src/preview/` | Terminal, Markdown, and browser previews. |
| `src/cli/` | Executable help and command dispatch. |
| `docs/` | Embedded help, API reference, and architecture. |
| `web/` | Embedded browser documentation. |
| `examples/` | Installable configuration examples. |
| `tests/` | Smoke, unit, integration, and contract tests. |
| `dist/moma` | Generated library and executable. |

Edit source modules and embedded assets. Do not edit `dist/moma` directly.

### Build and verify

```bash
task format
task lint
task test
```

Run the Bats suites as a required check when Bats-core is installed.

```bash
task test-bats
```

The formatting task downloads a pinned shfmt binary when it is not available.

### Architecture

Read [`docs/architecture.md`](docs/architecture.md) for layer boundaries,
output channels, exit statuses, terminal handling, and the build flow.
