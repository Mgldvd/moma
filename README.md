# Moma

<div align="center">
  <img src="./.img/moma.png" alt="moma logo" height="300px">
</div>

Moma is a standalone Bash library and executable for terminal UI components.

Repository: <https://github.com/Mgldvd/moma>

## Clone the repository

1. Clone Moma from GitHub.

```bash
git clone https://github.com/Mgldvd/moma.git
```

2. Enter the repository.

```bash
cd moma
```

## Project structure

- `src/lib/`: Editable source modules.
- `docs/`: Embedded Markdown help and reference.
- `enhancement.md`: Future component backlog.
- `preview/`: Embedded browser documentation.
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

2. Check the generated file.

```bash
./dist/moma --version
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

## Preview with curl

1. Download and open the terminal component reference.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview
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

Set `MOMA_PREVIEW_PORT` to change the web port. Set `MOMA_HELP_WIDTH` or
`MOMA_PREVIEW_WIDTH` to change Glow's render width. Set `NO_COLOR=1` to disable
ANSI colors.
