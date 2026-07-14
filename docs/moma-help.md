# Moma

Terminal UI components and workflow helpers for Bash.

Repository: <https://github.com/Mgldvd/moma>

## Usage

```bash
moma <command> [arguments] [options]
source dist/moma
```

## Component commands

| Command | Description |
| --- | --- |
| `title` | Print a title and subtitle. |
| `title-sub` | Print a secondary title. |
| `section` | Print a section heading. |
| `msg` | Print a styled message. |
| `msg-simple` | Print a simple message with a dot marker. |
| `list` | Print an unordered list. |
| `box` | Print a boxed message. |
| `prompt` | Print a prompt. |
| `label` | Print a decorated input-style label. |
| `input` | Print or read an input field. |
| `select` | Select one value with the arrow keys. |
| `multi-select` | Select multiple values with the arrow keys and Space. |
| `rabbit` | Print the Moma rabbit component. |

## Helper commands

| Command | Description |
| --- | --- |
| `confirm` | Select Yes or No with the arrow keys or `y` and `n`. |
| `spinner` | Follow a process and print completion feedback. |
| `command-check` | Check whether executables are available. |

## Documentation commands

| Command | Description |
| --- | --- |
| `help` | Show this help with Glow when available. |
| `preview` | Show the terminal reference. |
| `preview md` | Show the Markdown reference with Glow when available. |
| `preview web` | Serve the browser reference. |

## Remote preview

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview
```

## Global options

- `-h`, `--help`: Show help.
- `-v`, `--version`: Show the Moma version.

## Binary examples

```bash
./dist/moma msg "Ready" --success
./dist/moma title "Moma" "Installer"
./dist/moma label "TEXT HERE"
./dist/moma select "Development" "Staging" "Production" --choose 2
./dist/moma multi-select "Docker" "CI" "Tests" --choose 1,3
./dist/moma confirm "Create this project?" --default yes
./dist/moma command-check bash curl
./dist/moma preview
```

## Library examples

```bash
source dist/moma

moma-title "Moma" "Installer"
moma-msg "Ready" --success
moma-label "TEXT HERE"
moma-select "Development" "Staging" "Production"
moma-multi-select "Docker" "CI" "Tests"
if moma-confirm "Create this project?"; then
    moma-msg "Project created" --success
fi
moma-box "Important notice" --info
```

## Semantic styles

- `--success`
- `--error`
- `--warning`
- `--info`

Use `--color <value>`, `--icon <value>`, or `--no-color` where supported.
Set `NO_COLOR=1` to disable ANSI colors globally.
