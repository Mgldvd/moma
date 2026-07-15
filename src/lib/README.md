# Moma Source Index

The legacy `src/lib` directory now contains this compatibility index. Editable
modules live in the layered directories under `src/`.

```bash
./build.sh
```

## Module index

| Layer or file | Responsibility | Public functions |
| --- | --- | --- |
| [`src/core/`](../core/) | Version, errors, strings, validation, palette, semantics, terminal, and registry. | None |
| [`src/components/title.sh`](../components/title.sh) | Primary and secondary headings. | `moma-title`, `moma-title-sub` |
| [`src/components/section-message.sh`](../components/section-message.sh) | Semantic sections and messages. | `moma-section`, `moma-msg` |
| [`src/components/simple-list.sh`](../components/simple-list.sh) | Dot messages and unordered lists. | `moma-msg-simple`, `moma-list` |
| [`src/components/box-prompt.sh`](../components/box-prompt.sh) | Framed notices and prompt lead-ins. | `moma-box`, `moma-prompt` |
| [`src/components/label.sh`](../components/label.sh) | Decorated labels. | `moma-label` |
| [`src/components/input.sh`](../components/input.sh) | Display and interactive input fields. | `moma-input` |
| [`src/components/select.sh`](../components/select.sh) | Single and multiple selection state machines. | `moma-select`, `moma-multi-select` |
| [`src/components/rabbit.sh`](../components/rabbit.sh) | Branded activity feedback. | `moma-rabbit` |
| [`src/components/interaction.sh`](../components/interaction.sh) | Confirmation and process feedback. | `moma-confirm`, `moma-spinner` |
| [`src/components/command-check.sh`](../components/command-check.sh) | Executable dependency checks. | `moma-command-check` |
| [`src/preview/web.sh`](../preview/web.sh) | Embedded browser preview server. | None |
| [`src/preview/markdown.sh`](../preview/markdown.sh) | Embedded Markdown preview. | None |
| [`src/preview/main.sh`](../preview/main.sh) | Terminal preview and preview dispatcher. | None |
| [`src/cli/usage.sh`](../cli/usage.sh) | Plain and Markdown-aware CLI help. | None |
| [`src/cli/main.sh`](../cli/main.sh) | Explicit executable command dispatcher. | None |

Functions beginning with `_moma_` are private implementation details.

Interactive controls and decorated labels leave one blank line below their output. Compact messages, lists, and content lead-ins remain continuous.

## `src/core/`

Defines the namespaced ANSI palette, semantic theme values, option errors, text
helpers, and color resolution shared by every component.

```text
success → green + ✔
error   → red + ✖
warning → yellow + !
info    → cyan + →
```

---

## `src/components/title.sh`

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

## `src/components/section-message.sh`

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

## `src/components/simple-list.sh`

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

## `src/components/box-prompt.sh`

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

## `src/components/label.sh`

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

## `src/components/input.sh`

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

## `src/components/select.sh`

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

## `src/components/rabbit.sh`

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

## `src/components/interaction.sh`

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

## `src/components/command-check.sh`

### `moma-command-check`

```bash
moma-command-check bash curl
```

```text
  ▪   bash is available
  ▪   curl is available
```

---

## `src/preview/main.sh`

Provides the documentation previews used by the standalone executable.

```bash
./dist/moma preview
./dist/moma preview md
./dist/moma preview web
```

---

## `src/cli/main.sh`

Dispatches executable commands and renders embedded help.

```bash
./dist/moma help
./dist/moma --help
```
