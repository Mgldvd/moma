# Moma

<div align="center">
  <img src="./.img/moma.png" alt="moma logo" height="300px">
</div>

Moma is a standalone Bash library and executable for terminal UI components.

## Preview with curl

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview
```

## Install as a binary

1. Create the local binary directory.

```bash
mkdir -p "$HOME/.local/bin"
```

2. Download Moma with curl.

```bash
curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma -o "$HOME/.local/bin/moma"
```

3. Make the binary executable.

```bash
chmod 0755 "$HOME/.local/bin/moma"
```

4. Add the local binary directory to the shell profile.

```bash
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" 2>/dev/null || printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.profile"
```

5. Add the local binary directory to the current shell.

```bash
export PATH="$HOME/.local/bin:$PATH"
```

6. Check the installation.

```bash
moma --help
```

## Components

### Visual components

- `moma-title`: Print a primary title and subtitle.

  ![moma-title preview](.img/moma-title.png)

- `moma-title-sub`: Print a secondary title.

  ![moma-title-sub preview](.img/moma-title-sub.png)

- `moma-section`: Print a semantic section heading.

  ![moma-section preview](.img/moma-section.png)

- `moma-msg`: Print a styled semantic message.

  ![moma-msg preview](.img/moma-msg.png)

- `moma-msg-simple`: Print a compact message with a dot marker.

  ![moma-msg-simple preview](.img/moma-msg-simple.png)

- `moma-list`: Print a list with consistent markers.

  ![moma-list preview](.img/moma-list.png)

- `moma-box`: Print a framed notice.

  ![moma-box preview](.img/moma-box.png)

- `moma-prompt`: Print a question or confirmation prompt.

  ![moma-prompt preview](.img/moma-prompt.png)

- `moma-label`: Print a decorated input label.

  ![moma-label preview](.img/moma-label.png)

- `moma-rabbit`: Print the Moma activity component.

  ![moma-rabbit preview](.img/moma-rabbit.png)

### Interactive components

- `moma-input`: Display or read an input field.

  ![moma-input preview](.img/moma-input.png)

- `moma-select`: Select one value.

  ![moma-select preview](.img/moma-select.png)

- `moma-multi-select`: Select multiple values.

  ![moma-multi-select preview](.img/moma-multi-select.png)

- `moma-confirm`: Select a Yes or No answer.

  ![moma-confirm preview](.img/moma-confirm.png)

### Workflow components

- `moma-spinner`: Follow a running process and print its result.

  ![moma-spinner preview](.img/moma-spinner.png)

- `moma-command-check`: Check whether commands are available.

  ![moma-command-check preview](.img/moma-command-check.png)

## Project structure

- `src/lib/`: Editable source modules.
- `docs/`: Embedded Markdown help and reference.
- `.img/`: Logos and component preview screenshots.
- `enhancement.md`: Future component backlog.
- `web/`: Embedded browser documentation.
- `build.sh`: Standalone-file builder.
- `dist/moma`: Generated library and executable.
- `tests/smoke.sh`: API and behavior checks.

Edit the source modules. Do not edit `dist/moma` directly.

## Requirements

- Bash 4 or newer.
- Python 3 only for `preview web`.
- Glow optionally for rendered help and Markdown previews.
- `tput` optionally for the interactive spinner.

## Build

1. Run the builder.

```bash
./build.sh
```

2. Check the generated file help.

```bash
./dist/moma --help
```

## Test

1. Run the smoke tests.

```bash
./tests/smoke.sh
```

## Run the example

1. Build the standalone file.

```bash
./build.sh
```

2. Run the interactive component showcase.

```bash
./example.sh
```

## Load as a library

1. Source the generated file.

```bash
source dist/moma
```

2. Call a component.

```bash
moma-title "Moma" "Installer"
moma-msg "Ready" --success
moma-list "Clone repository" "Install dependencies"
moma-label "TEXT HERE"
moma-select "Development" "Staging" "Production"
moma-multi-select "Docker" "CI" "Tests"
moma-confirm "Create this project?"
```

## Load from GitHub

1. Source the generated file from the Moma repository.

```bash
source <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma)
```

2. Call a component.

```bash
moma-msg "Ready" --success
```

## Run as an executable

1. Run component commands.

```bash
./dist/moma title "Moma" "Installer"
./dist/moma msg "Ready" --success
./dist/moma msg-simple "Package installed" --error
./dist/moma list "Clone repository" "Install dependencies"
./dist/moma label "TEXT HERE"
./dist/moma select "Development" "Staging" "Production"
./dist/moma multi-select "Docker" "CI" "Tests"
```

2. Run helper commands.

```bash
./dist/moma confirm "Create this project?" --default yes
./dist/moma command-check bash curl
```

## Open help and previews

1. Open the library help.

```bash
./dist/moma help
```

2. Open the terminal component reference.

```bash
./dist/moma preview
```

3. Open the Markdown reference.

```bash
./dist/moma preview md
```

4. Start the browser reference.

```bash
./dist/moma preview web
```

5. Open the local URL.

```text
http://127.0.0.1:4173
```

Set `MOMA_PREVIEW_PORT` to change the starting web port. Moma selects the next
available port when it is occupied. Set `MOMA_HELP_WIDTH` or `MOMA_PREVIEW_WIDTH`
to change Glow's render width. Set `NO_COLOR=1` to disable ANSI colors.
