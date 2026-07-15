# Moma Source Module Index

Edit these modules and run the build from the project root.

```bash
./build.sh
```

## Module index

| File | Responsibility | Public functions |
| --- | --- | --- |
| [`10-core.sh`](./10-core.sh) | Theme defaults and private shared helpers. | None |
| [`20-title.sh`](./20-title.sh) | Primary and secondary headings. | `moma-title`, `moma-title-sub` |
| [`30-section-message.sh`](./30-section-message.sh) | Semantic sections and messages. | `moma-section`, `moma-msg` |
| [`35-simple-list.sh`](./35-simple-list.sh) | Dot messages and unordered lists. | `moma-msg-simple`, `moma-list` |
| [`40-box-prompt.sh`](./40-box-prompt.sh) | Framed notices and prompt lead-ins. | `moma-box`, `moma-prompt` |
| [`45-label.sh`](./45-label.sh) | Decorated labels aligned with input headers. | `moma-label` |
| [`50-input.sh`](./50-input.sh) | Display and interactive input fields. | `moma-input` |
| [`55-select.sh`](./55-select.sh) | Single and multiple arrow-key selection lists. | `moma-select`, `moma-multi-select` |
| [`60-rabbit.sh`](./60-rabbit.sh) | Branded activity feedback. | `moma-rabbit` |
| [`70-interaction.sh`](./70-interaction.sh) | Confirmation and process feedback. | `moma-confirm`, `moma-spinner` |
| [`75-system.sh`](./75-system.sh) | Executable dependency checks. | `moma-command-check` |
| [`80-preview.sh`](./80-preview.sh) | Terminal, Markdown, and browser previews. | None |
| [`90-cli.sh`](./90-cli.sh) | Executable command dispatcher and help renderer. | None |

Functions beginning with `_moma_` are private implementation details.

Interactive controls and decorated labels leave one blank line below their output. Compact messages, lists, and content lead-ins remain continuous.

## `10-core.sh`

Defines the namespaced ANSI palette, semantic theme values, option errors, text
helpers, and color resolution shared by every component.

```text
success → green + ✔
error   → red + ✖
warning → yellow + !
info    → cyan + →
```

---

## `20-title.sh`

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

---

## `30-section-message.sh`

### `moma-section`

```bash
moma-section "Next step" --info
```

```text
  ┌
  ▪ → Next step
  └
```

### `moma-msg`

```bash
moma-msg "Package installed" --success
```

```text
  ▪ ✔ Package installed  ✔
```

---

## `35-simple-list.sh`

### `moma-msg-simple`

```bash
moma-msg-simple "Package installed"
moma-msg-simple "Package installation failed" --error
```

```text
  ▪   Package installed
  ▪   Package installation failed
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

---

## `40-box-prompt.sh`

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

---

## `45-label.sh`

### `moma-label`

```bash
moma-label "TEXT HERE"
```

```text
  ┌─ TEXT HERE ────────────────────────────┐
```

Use `--width <number>`, `--color <color>`, `--icon <symbol>`, or a semantic style.
The label leaves one blank line below the decorated line.

---

## `50-input.sh`

### `moma-input`

```bash
moma-input --title "Project name" --placeholder "my-project"
```

```text
  ┌─ Project name ────────────────────────┐
  │ my-project                            │
  └───────────────────────────────────────┘
```

Read values through standard output.

```bash
project="$(moma-input --title "Project name" --read --required --trim)"
password="$(moma-input --title "Password" --read --secret --required)"
```

Secret mode keeps the real value in the result and prints `*` for every typed
character. Use `--mask <symbol>` to select another mask.

Interactive inputs leave one blank line below the entered value.

```text
  ┌─ Owner ────────────────────────────────┐
  │❯ asdf

  ┌─ Secret ───────────────────────────────┐
  │❯ ****
```

---

## `55-select.sh`

### `moma-select`

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
  ▪  Environment
  └──────────────────────────────
    Development
  ▪ Staging
    Production
  ↑/↓ move · Enter select · q cancel
```

Use ↑ and ↓ to move, Enter to select, and `--choose <number>` for automation.
The selector leaves one blank line below the controls when it finishes.

### `moma-multi-select`

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

Use `--selected 1,3` for initial values and `--choose 1,3` for automation.
The selector leaves one blank line below the controls when it finishes.

---

## `60-rabbit.sh`

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

---

## `70-interaction.sh`

### `moma-confirm`

```bash
moma-confirm "Create this project?" --default yes
```

```text
  ▪  Create this project? [yes]
  └────────────────────────────────
  ▪ Yes
    No
  ↑/↓ move · Enter confirm · y yes · n no
```

Use `--answer yes` or `--answer no` for non-interactive scripts and tests.
After a successful answer, the confirmation leaves one blank line below the controls.

### `moma-spinner`

```bash
sleep 1 &
moma-spinner "$!" "Preparing workspace"
```

```text
  ▪ ✔ Preparing workspace  ✔
```

---

## `75-system.sh`

### `moma-command-check`

```bash
moma-command-check bash curl
```

```text
  ▪   bash is available
  ▪   curl is available
```

---

## `80-preview.sh`

Provides the documentation previews used by the standalone executable.

```bash
./dist/moma preview
./dist/moma preview md
./dist/moma preview web
```

---

## `90-cli.sh`

Dispatches executable commands and renders embedded help.

```bash
./dist/moma help
./dist/moma --help
```
