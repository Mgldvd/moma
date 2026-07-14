# Moma Component Reference

Reference for the complete public Moma Bash API.

Repository: <https://github.com/Mgldvd/moma>

## Load the library

```bash
source dist/moma
```

## Visual components

### `moma-title`

```bash
moma-title "Moma" "Terminal UI library"
```

```text
  ┌─────────────────────────────────────┐
  ▪  Moma  Terminal UI library          ▪
  └─────────────────────────────────────┘
```

### `moma-title-sub`

```bash
moma-title-sub "Deployment" "Production environment"
```

```text
  ▪  Deployment  Production environment
  └───────────────────────────────────────
```

### `moma-section`

```bash
moma-section "Dependencies ready" --success
moma-section "Configuration failed" --error
moma-section "Review required" --warning
moma-section "Next step" --info
```

```text
  ┌
  ▪ ✔ Dependencies ready
  └
```

### `moma-msg`

```bash
moma-msg "Package installed" --success
moma-msg "Connection refused" --error
```

```text
  ▪ ✔ Package installed  ✔
```

### `moma-msg-simple`

```bash
moma-msg-simple "Package installed"
moma-msg-simple "Package installation failed" --error
```

```text
  ▪   Package installed
```

### `moma-list`

```bash
moma-list "Clone repository" "Install dependencies" "Start application"
```

```text
  ▪   Clone repository
  ▪   Install dependencies
  ▪   Start application
```

### `moma-box`

```bash
moma-box "Configuration is ready." --success
```

```text
  ┌────────────────────────────────┐
  │ ✔ Configuration is ready.     │
  └────────────────────────────────┘
```

### `moma-prompt`

```bash
moma-prompt "Continue with the installation?" --color pink
```

```text
  ▪  Continue with the installation?
  └──────────────────────────────────────
```

### `moma-label`

```bash
moma-label "TEXT HERE"
```

```text
  ┌─ TEXT HERE ────────────────────────────┐
```

Use `--width <number>`, `--color <color>`, `--icon <symbol>`, or a semantic style.
The label leaves one blank line below the decorated line.

### `moma-input`

```bash
moma-input --title "Project name" --placeholder "my-project"
project="$(moma-input --title "Project name" --read --required --trim)"
password="$(moma-input --title "Password" --read --secret --required)"
```

Secret mode prints `*` for each typed character. Use `--mask <symbol>` to
change the mask.

Interactive inputs leave one blank line below the entered value.

```text
  ┌─ Owner ────────────────────────────────┐
  │❯ asdf

  ┌─ Secret ───────────────────────────────┐
  │❯ ****
```

```text
  ┌─ Project name ────────────────────────┐
  │ my-project                            │
  └───────────────────────────────────────┘
```

### `moma-select`

Use ↑ and ↓ to move, then press Enter to return the selected value.

```bash
environment="$(
    moma-select \
        "Development" \
        "Staging" \
        "Production" \
        --title "Environment"
)"
```

```text
  Environment
    Development
  ▪ Staging
    Production
  ↑/↓ move · Enter select · q cancel
```

Use `--choose <number>` for scripts and tests without an interactive terminal.
The selector leaves one blank line below the controls when it finishes.

```bash
environment="$(moma-select "Development" "Staging" "Production" --choose 2)"
```

### `moma-multi-select`

Use ↑ and ↓ to move, Space to toggle `▢`/`▣`, then press Enter to return all
selected values.

```bash
selected_features="$(
    moma-multi-select \
        "Docker" \
        "CI" \
        "Tests" \
        --title "Features" \
        --required
)"
mapfile -t features <<< "$selected_features"
```

```text
  ▪  Features
  └──────────────────────────────
  › ▣ Docker
    ▢ CI
    ▣ Tests
  ↑/↓ move · Space toggle · Enter confirm · q cancel
```

Each selected value is returned on its own line. Use comma-separated option
numbers with `--selected` or `--choose`.
The selector leaves one blank line below the controls when it finishes.

```bash
selected_features="$(moma-multi-select "Docker" "CI" "Tests" --choose 1,3)"
```

### `moma-rabbit`

```bash
moma-rabbit "Preparing workspace" --info
```

```text
  | → Preparing workspace
  /⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺

    (\(\
    (-.-)
  o_(")(")
```

## Workflow helpers

### `moma-confirm`

Select Yes or No with the arrow keys and press Enter. Press `y` for Yes, `n` for No, or `q` or Escape to cancel. The selected value is shown in brackets inside the decorated Moma prompt.

```text
  ▪  Create this project? [yes]
  └────────────────────────────────
  ▪ Yes
    No
  ↑/↓ move · Enter confirm · y yes · n no
```

The function returns status `0` for Yes, `1` for No, `2` for invalid input, and `130` for cancellation.
After a successful answer, the confirmation leaves one blank line below the controls.

```bash
if moma-confirm "Create this project?" --default yes; then
    moma-msg "Continuing" --success
fi
```

Use `--answer` in non-interactive scripts and tests.

```bash
moma-confirm "Create this project?" --answer yes
```

### `moma-spinner`

```bash
long_running_command &
moma-spinner "$!" "Processing"
```

### `moma-command-check`

```bash
moma-command-check bash curl git
moma-command-check bash curl git --quiet
```

## Semantic styles

| Flag | Default color | Default icon |
| --- | --- | --- |
| `--success` | Green | `✔` |
| `--error` | Red | `✖` |
| `--warning` | Yellow | `!` |
| `--info` | Cyan | `→` |

## Preview commands

```bash
./dist/moma preview
./dist/moma preview md
./dist/moma preview web
./dist/moma help
```

## Remote preview

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview
```
