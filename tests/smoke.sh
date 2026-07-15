#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOMA_DIST="$ROOT_DIR/dist/moma"

"$ROOT_DIR/build.sh" >/dev/null
bash -n "$ROOT_DIR/build.sh" "$ROOT_DIR"/src/lib/*.sh "$MOMA_DIST"

[[ -x "$MOMA_DIST" ]]
[[ ! -e "$ROOT_DIR/moma.sh" ]]
[[ ! -e "$ROOT_DIR/src/lib/00-colors.sh" ]]

plain_help="$(PATH=/usr/bin:/bin "$MOMA_DIST" --help)"
[[ "$plain_help" == *"Moma - terminal UI components for Bash"* ]]
[[ "$plain_help" == *"confirm, spinner, command-check"* ]]

binary_output="$(NO_COLOR=1 "$MOMA_DIST" msg "Ready" --success)"
[[ "$binary_output" == *"Ready"* ]]

simple_output="$(NO_COLOR=1 "$MOMA_DIST" msg-simple "Package installed")"
[[ "$simple_output" == "  ▪   Package installed" ]]

simple_error_output="$(env -u NO_COLOR "$MOMA_DIST" msg-simple "Package installation failed" --error)"
[[ "$simple_error_output" == *$'\033[31m▪\033[0m   Package installation failed' ]]

list_output="$(NO_COLOR=1 "$MOMA_DIST" list "Clone repository" "Install dependencies")"
[[ "$list_output" == $'  ▪   Clone repository\n  ▪   Install dependencies' ]]

label_output="$(NO_COLOR=1 "$MOMA_DIST" label "TEXT HERE")"
[[ "$label_output" == '  ┌─ TEXT HERE ────────────────────────────┐' ]]

label_semantic_output="$(env -u NO_COLOR "$MOMA_DIST" label "Deployment" --success)"
[[ "$label_semantic_output" == *$'\033[32m  ┌─ ✔ Deployment '* ]]

label_spacing="$({
    NO_COLOR=1 "$MOMA_DIST" label "TEXT HERE"
    printf 'NEXT'
})"
[[ "$label_spacing" == *$'┐\n\nNEXT' ]]

strict_output="$(NO_COLOR=1 bash -euo pipefail -c 'source "$1"; moma-msg "Strict mode" --success' _ "$MOMA_DIST")"
[[ "$strict_output" == *"Strict mode"* ]]

input_output="$(printf '  project  \n' | NO_COLOR=1 "$MOMA_DIST" input --title "Project" --read --trim 2>/dev/null)"
[[ "$input_output" == "project" ]]

input_display_spacing="$(
    NO_COLOR=1 "$MOMA_DIST" input --title "Owner" --value "asdf"
    printf 'NEXT'
)"
[[ "$input_display_spacing" == *$'┘\n\nNEXT' ]]

input_read_spacing="$(
    printf 'asdf\n' | NO_COLOR=1 "$MOMA_DIST" input --title "Owner" --read 2>&1 >/dev/null
    printf 'NEXT'
)"
[[ "$input_read_spacing" == *$'│❯ \n\nNEXT' ]]

select_output="$(NO_COLOR=1 "$MOMA_DIST" select Development Staging Production --title Environment --choose 2 2>/dev/null)"
[[ "$select_output" == "Staging" ]]

select_visual="$(
    NO_COLOR=1 "$MOMA_DIST" select Development Staging Production --title Environment --choose 2 2>&1 >/dev/null
    printf 'NEXT'
)"
[[ "$select_visual" == $'  ▪  Environment\n  └──────────────────────────────\n    Development\n  ▪ Staging\n    Production\n  ↑/↓ move · Enter select · q cancel\n\nNEXT' ]]

multi_select_output="$(NO_COLOR=1 "$MOMA_DIST" multi-select Docker CI Tests --title Features --choose 1,3 2>/dev/null)"
[[ "$multi_select_output" == $'Docker\nTests' ]]

multi_select_visual="$(
    NO_COLOR=1 "$MOMA_DIST" multi-select Docker CI Tests --title Features --choose 1,3 2>&1 >/dev/null
    printf 'NEXT'
)"
[[ "$multi_select_visual" == $'  ▪  Features\n  └──────────────────────────────\n  › ▣ Docker\n    ▢ CI\n    ▣ Tests\n  ↑/↓ move · Space toggle · Enter confirm · q cancel\n\nNEXT' ]]

prompt_visual="$(NO_COLOR=1 "$MOMA_DIST" prompt "Choose the target environment")"
[[ "$prompt_visual" == $'\n  ▪  Choose the target environment\n  └───────────────────────────────────' ]]

prompt_composition="$({
    NO_COLOR=1 "$MOMA_DIST" prompt "Choose the target environment"
    printf 'NEXT'
})"
[[ "$prompt_composition" == *$'└───────────────────────────────────\nNEXT' ]]

rabbit_visual="$(NO_COLOR=1 "$MOMA_DIST" rabbit "Ready")"
[[ "$rabbit_visual" == *$'\n  | Ready\n  /⎺⎺⎺⎺⎺⎺⎺⎺\n\n    (\\(\\\n    (-.-)\n  o_(\")(")' ]]

compact_message_composition="$({
    NO_COLOR=1 "$MOMA_DIST" msg-simple "First"
    NO_COLOR=1 "$MOMA_DIST" msg-simple "Second"
})"
[[ "$compact_message_composition" == $'  ▪   First\n  ▪   Second' ]]

secret_output="$(printf 'secret-value\n' | NO_COLOR=1 "$MOMA_DIST" input --title "Secret" --read --secret 2>/dev/null)"
[[ "$secret_output" == "secret-value" ]]

if command -v script &>/dev/null; then
    masked_output="$(printf $'abc\177d\n' | script -qec "NO_COLOR=1 '$MOMA_DIST' input --title Secret --read --secret" /dev/null)"
    [[ "$masked_output" == *'│❯ ***'* ]]
    [[ "$masked_output" == *$'│❯ ***\r\n\r\n'* ]]
    [[ "$masked_output" == *$'abd\r'* ]]

    select_tty_output="$(printf $'\033[B\n' | script -qec "NO_COLOR=1 '$MOMA_DIST' select Development Staging Production --title Environment" /dev/null)"
    [[ "$select_tty_output" == *'▪ Staging'* ]]
    [[ "$select_tty_output" == *'▪  Environment'* ]]
    [[ "$select_tty_output" == *'└──────────────────────────────'* ]]
    [[ "$select_tty_output" == *$'Staging\r'* ]]

    multi_select_tty_output="$(printf $' \033[B \n' | script -qec "NO_COLOR=1 '$MOMA_DIST' multi-select Docker CI Tests --title Features --required" /dev/null)"
    [[ "$multi_select_tty_output" == *'▪  Features'* ]]
    [[ "$multi_select_tty_output" == *'└──────────────────────────────'* ]]
    [[ "$multi_select_tty_output" == *'▣ Docker'* ]]
    [[ "$multi_select_tty_output" == *'▣ CI'* ]]
    [[ "$multi_select_tty_output" == *$'Docker\r\nCI\r'* ]]

    set +e
    confirm_arrow_output="$(printf $'\033[B\n' | script -qec "NO_COLOR=1 '$MOMA_DIST' confirm 'Create this project?'" /dev/null)"
    confirm_arrow_status=$?
    set -e
    [[ "$confirm_arrow_status" -eq 1 ]]
    [[ "$confirm_arrow_output" == *$'  ▪  Create this project? [no]'* ]]
    [[ "$confirm_arrow_output" == *$'  └────────────────────────────────'* ]]
    [[ "$confirm_arrow_output" == *'▪ No'* ]]

    confirm_y_output="$(printf 'y' | script -qec "NO_COLOR=1 '$MOMA_DIST' confirm 'Create this project?'" /dev/null)"
    [[ "$confirm_y_output" == *'▪  Create this project? [yes]'* ]]

    set +e
    confirm_n_output="$(printf 'n' | script -qec "NO_COLOR=1 '$MOMA_DIST' confirm 'Create this project?'" /dev/null)"
    confirm_n_status=$?
    set -e
    [[ "$confirm_n_status" -eq 1 ]]
    [[ "$confirm_n_output" == *'▪  Create this project? [no]'* ]]
fi

confirm_yes_output="$(NO_COLOR=1 "$MOMA_DIST" confirm "Continue?" --default yes --answer yes 2>&1)"
[[ "$confirm_yes_output" == *$'  ▪  Continue? [yes]'* ]]
[[ "$confirm_yes_output" == *$'  └──────────────────────────────'* ]]
[[ "$confirm_yes_output" == *"▪ Yes"* ]]
[[ "$confirm_yes_output" == *"y yes · n no"* ]]

confirm_spacing_output="$(
    NO_COLOR=1 "$MOMA_DIST" confirm "Continue?" --answer yes 2>&1
    printf 'NEXT'
)"
[[ "$confirm_spacing_output" == *$'y yes · n no\n\nNEXT' ]]

confirm_piped_spacing_output="$(
    printf 'yes\n' | NO_COLOR=1 "$MOMA_DIST" confirm "Continue?" 2>&1
    printf 'NEXT'
)"
[[ "$confirm_piped_spacing_output" == *$'  y/n: \n\nNEXT' ]]

set +e
confirm_no_output="$(NO_COLOR=1 "$MOMA_DIST" confirm "Continue?" --answer no 2>&1)"
confirm_no_status=$?
set -e
[[ "$confirm_no_status" -eq 1 ]]
[[ "$confirm_no_output" == *"▪  Continue? [no]"* ]]
[[ "$confirm_no_output" == *"▪ No"* ]]

sleep 0.02 &
spinner_pid=$!
spinner_output="$(NO_COLOR=1 "$MOMA_DIST" spinner "$spinner_pid" "Finished" --delay 0.01)"
[[ "$spinner_output" == *"Finished"* ]]

command_output="$(NO_COLOR=1 "$MOMA_DIST" command-check bash)"
[[ "$command_output" == *"bash is available"* ]]

set +e
NO_COLOR=1 "$MOMA_DIST" command-check __moma_missing_command__ --quiet
command_status=$?
set -e
[[ "$command_status" -eq 1 ]]

mapfile -t expected_functions <<'EOF'
moma-box
moma-command-check
moma-confirm
moma-input
moma-label
moma-list
moma-msg
moma-msg-simple
moma-multi-select
moma-prompt
moma-rabbit
moma-section
moma-select
moma-spinner
moma-title
moma-title-sub
EOF

mapfile -t actual_functions < <(
    bash -c 'source "$1"; compgen -A function | LC_ALL=C sort' _ "$MOMA_DIST" \
        | rg '^moma-'
)
[[ "${actual_functions[*]}" == "${expected_functions[*]}" ]]

for public_function in "${expected_functions[@]}"; do
    bash -c 'source "$1"; declare -F "$2" >/dev/null' _ "$MOMA_DIST" "$public_function"
    rg -q "data-api=\"$public_function(?: |\")" "$ROOT_DIR/web/index.html"
    rg -q "\\b$public_function\\b" "$ROOT_DIR/src/lib/README.md"
    rg -q "\\b$public_function\\b" "$ROOT_DIR/example.sh"
done

example_output="$(
    printf 'demo-project\nteam@example.com\nsuper-secret\nyes\n' \
        | NO_COLOR=1 "$ROOT_DIR/example.sh" 2>&1
)"
[[ "$example_output" == *"Component showcase"* ]]
[[ "$example_output" == *"All required commands are available."* ]]
[[ "$example_output" == *"┌─ Basic details"* ]]
[[ "$example_output" == *"Choose the target environment"* ]]
[[ "$example_output" == *"Creating project"* ]]
[[ "$example_output" == *"Project configuration accepted"* ]]
[[ "$example_output" != *"super-secret"* ]]

standalone_dir="$(mktemp -d "${TMPDIR:-/tmp}/moma-test.XXXXXX")"
trap 'rm -rf "$standalone_dir"' EXIT
cp "$MOMA_DIST" "$standalone_dir/moma"

standalone_output="$(NO_COLOR=1 bash -c '
    source "$1"
    moma-msg "Standalone" --info
' _ "$standalone_dir/moma")"
[[ "$standalone_output" == *"Standalone"* ]]

fake_bin="$standalone_dir/bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/glow" <<'EOF'
#!/usr/bin/env bash
printf 'glow arguments: %s\n' "$*"
cat
EOF
chmod +x "$fake_bin/glow"

glow_help="$(PATH="$fake_bin:/usr/bin:/bin" MOMA_HELP_WIDTH=72 "$MOMA_DIST" help)"
[[ "$glow_help" == *"glow arguments: -w 72 -"* ]]
[[ "$glow_help" == *"# Moma"* ]]

terminal_preview="$(NO_COLOR=1 "$MOMA_DIST" preview)"
[[ "$terminal_preview" == *"COMPONENT GALLERY"* ]]
[[ "$terminal_preview" == *"moma-title"* ]]
[[ "$terminal_preview" == *"moma-select"* ]]
[[ "$terminal_preview" == *"moma-multi-select"* ]]
[[ "$terminal_preview" == *"moma-label"* ]]
[[ "$terminal_preview" == *"┌─ TEXT HERE"* ]]
[[ "$terminal_preview" == *"▪  Continue with deployment? [yes]"* ]]
[[ "$terminal_preview" == *"moma-command-check"* ]]
[[ "$terminal_preview" == *"Browser docs"* ]]

colored_terminal_preview="$(env -u NO_COLOR "$MOMA_DIST" preview)"
preview_gray=$'\033[38;2;200;200;200m'
preview_yellow=$'\033[33m'
preview_reset=$'\033[0m'
[[ "$colored_terminal_preview" == *"${preview_gray}────────────────"* ]]
[[ "$colored_terminal_preview" == *"  02  Status and feedback"* ]]
[[ "$colored_terminal_preview" == *"${preview_gray}┌─ moma-section"* ]]
[[ "$colored_terminal_preview" == *'$ moma-section "Dependencies ready" --success'* ]]
[[ "$colored_terminal_preview" == *'$ moma-select "Development" "Staging" "Production" --title "Environment"'* ]]
[[ "$colored_terminal_preview" == *"└─ ${preview_yellow}output${preview_reset}:"* ]]

markdown_preview="$(PATH=/usr/bin:/bin "$MOMA_DIST" preview md)"
[[ "$markdown_preview" == *"# Moma Component Reference"* ]]
[[ "$markdown_preview" == *'### `moma-confirm`'* ]]
[[ "$markdown_preview" == *'### `moma-select`'* ]]
[[ "$markdown_preview" == *'### `moma-multi-select`'* ]]
[[ "$markdown_preview" == *"./dist/moma preview web"* ]]

glow_preview="$(PATH="$fake_bin:/usr/bin:/bin" MOMA_PREVIEW_WIDTH=76 "$MOMA_DIST" preview md)"
[[ "$glow_preview" == *"glow arguments: -w 76 -"* ]]

[[ -s "$ROOT_DIR/web/index.html" ]]
[[ -s "$ROOT_DIR/web/styles.css" ]]
[[ -s "$ROOT_DIR/web/app.js" ]]

api_count="$(rg -o 'data-api=' "$ROOT_DIR/web/index.html" | wc -l | tr -d ' ')"
[[ "$api_count" == "16" ]]

printf 'Smoke tests passed.\n'
