# Moma Documentation

Reference for the complete public Moma Bash API.

Repository: <https://github.com/Mgldvd/moma>

## Load the library

```bash
source dist/moma
```

## Visual components

### `moma-title`

Primary identity block for the beginning of a script or major workflow.

```text
moma-title "Moma" "Terminal UI library" [--primary color] [--accent color]
```

```bash
# Example 1
moma-title "Moma" "Terminal UI library"

# Example 2
moma-title "Deploy" "Production" --primary cyan

# Example 3
moma-title "Backup" "Nightly job" --accent yellow --min-width 48
```

![moma-title preview](../.img/moma-title.png)

### `moma-title-sub`

Secondary heading for stages nested inside the main workflow.

```text
moma-title-sub "Deployment" "Production environment"
```

```bash
# Example 1
moma-title-sub "Dependencies" "Installing packages"

# Example 2
moma-title-sub "Deploy" "Production" --color cyan

# Example 3
moma-title-sub "Tests" --message "Running suite" --min-width 42
```

![moma-title-sub preview](../.img/moma-title-sub.png)

### `moma-section`

Strong separator that gives semantic context to the content that follows.

```text
moma-section "Dependencies ready" --success
```

```bash
# Example 1
moma-section "Dependencies ready" --success

# Example 2
moma-section "Configuration failed" --error

# Example 3
moma-section "Next step" --info --icon "→"
```

![moma-section preview](../.img/moma-section.png)

### `moma-msg`

Compact feedback with semantic defaults or custom color and icon overrides.

```text
moma-msg "Package installed" --success [--color value] [--icon value]
```

```bash
# Example 1
moma-msg "Package installed" --success

# Example 2
moma-msg "Connection refused" --error

# Example 3
moma-msg "Downloading metadata" --color cyan --icon "→"
```

![moma-msg preview](../.img/moma-msg.png)

### `moma-msg-simple`

A quiet message with only a dot marker and no semantic icon.

```text
moma-msg-simple "Package installed" [--success|--error|--warning|--info] [--color value]
```

```bash
# Example 1
moma-msg-simple "Package installed"

# Example 2
moma-msg-simple "Package installation failed" --error

# Example 3
moma-msg-simple "Queued" --color yellow --marker "•"
```

![moma-msg-simple preview](../.img/moma-msg-simple.png)

### `moma-list`

An unordered terminal list with a consistent marker for every item.

```text
moma-list "Clone repository" "Install dependencies" [--success|--error|--warning|--info]
```

```bash
# Example 1
moma-list "Clone repository" "Install dependencies" "Start application"

# Example 2
moma-list "Database ready" "Cache ready" --success

# Example 3
moma-list "Review logs" "Retry deployment" --marker "→" --color yellow
```

![moma-list preview](../.img/moma-list.png)

### `moma-box`

Framed notice for information that must stand apart from surrounding output.

```text
moma-box "Configuration is ready." --success
```

```bash
# Example 1
moma-box "Configuration is ready." --success

# Example 2
moma-box "Review the deployment settings." --warning --width 48

# Example 3
moma-box "Build failed." --error --icon "✖" --padding 2
```

![moma-box preview](../.img/moma-box.png)

### `moma-prompt`

Question lead-in used before confirmation or free-form interaction.

```text
moma-prompt "Continue with the installation?" --color pink
```

```bash
# Example 1
moma-prompt "Continue with the installation?"

# Example 2
moma-prompt "Select an environment" --color cyan

# Example 3
moma-prompt "Deploy now?" --default "yes" --icon "?"
```

![moma-prompt preview](../.img/moma-prompt.png)

### `moma-label`

Print an input-style decorated label with automatic width, semantic color support, and one blank line below it.

```text
moma-label "TEXT HERE" [--width number] [--color color] [--icon symbol]
```

```bash
# Example 1
moma-label "PROJECT NAME"

# Example 2
moma-label "DEPLOYMENT" --success

# Example 3
moma-label "NOTES" --width 52 --color cyan --icon "→"
```

![moma-label preview](../.img/moma-label.png)

### `moma-rabbit`

Branded activity and completion feedback using Moma's rabbit signature.

```text
moma-rabbit "Preparing workspace" --info
```

```bash
# Example 1
moma-rabbit "Preparing workspace" --info

# Example 2
moma-rabbit "Deployment complete" --success

# Example 3
moma-rabbit "Build needs attention" --warning --icon "!"
```

![moma-rabbit preview](../.img/moma-rabbit.png)

## Interactive components

### `moma-input`

Display or read a field with placeholders, validation, secret masking, and one blank line below each interactive value.

```text
moma-input --title "Project name" --read --required [--secret] [--mask symbol] [--default value]
```

```bash
# Example 1
moma-input --title "Project name" --placeholder "my-project"

# Example 2
project="$(moma-input --title "Project name" --read --required --trim)"

# Example 3
password="$(moma-input --title "Password" --read --secret --required)"
```

![moma-input preview](../.img/moma-input.png)

### `moma-select`

Select one value with the arrow keys, return it through standard output, and leave one blank line below the controls.

```text
moma-select "Development" "Staging" "Production" [--title text] [--initial number]
```

```bash
# Example 1
environment="$(moma-select "Development" "Staging" "Production" --title "Environment")"

# Example 2
environment="$(moma-select "Development" "Staging" "Production" --choose 2)"

# Example 3
region="$(moma-select "US" "EU" "APAC" --title "Region" --initial 2 --color cyan)"
```

![moma-select preview](../.img/moma-select.png)

### `moma-multi-select`

Toggle multiple values below a decorated Moma heading and return every selection on its own line.

```text
moma-multi-select "Docker" "CI" "Tests" [--selected 1,3] [--required]
```

```bash
# Example 1
features="$(moma-multi-select "Docker" "CI" "Tests" --title "Features")"

# Example 2
features="$(moma-multi-select "Docker" "CI" "Tests" --choose 1,3)"

# Example 3
features="$(moma-multi-select "Docker" "CI" "Tests" --selected 1,2 --required)"
```

![moma-multi-select preview](../.img/moma-multi-select.png)

### `moma-confirm`

Select Yes or No with the arrow keys, Enter, or the y and n shortcuts. A successful answer leaves one blank line below the controls.

```text
moma-confirm "Create this project?" [--default yes|no] [--answer yes|no]
```

```bash
# Example 1
moma-confirm "Create this project?" --default yes

# Example 2
moma-confirm "Delete the cache?" --answer no

# Example 3
if moma-confirm "Deploy now?"; then
  moma-msg "Deploying" --info
fi
```

![moma-confirm preview](../.img/moma-confirm.png)

## Workflow helpers

### `moma-spinner`

Display progress while a process is active, then print semantic completion feedback.

```text
moma-spinner pid ["message"] [--delay seconds]
```

```bash
# Example 1
sleep 2 &
moma-spinner "$!" "Waiting"

# Example 2
backup_database &
moma-spinner --pid "$!" --message "Backing up"

# Example 3
build_project &
moma-spinner "$!" "Building" --delay 0.05
```

![moma-spinner preview](../.img/moma-spinner.png)

### `moma-command-check`

Check whether every requested executable is available and return a useful status.

```text
moma-command-check bash curl git [--quiet]
```

```bash
# Example 1
moma-command-check bash curl git

# Example 2
moma-command-check docker --quiet

# Example 3
if ! moma-command-check git; then
  exit 1
fi
```

![moma-command-check preview](../.img/moma-command-check.png)

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
