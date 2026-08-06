#!/bin/bash
#
# Exercise Moma's build, library, CLI, preview, and standalone contracts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOMA_DIST="$ROOT_DIR/dist/moma"
MOMA_CONFIG_FILE="$ROOT_DIR/tests/fixtures/not-present.confg"
export MOMA_CONFIG_FILE

"$ROOT_DIR/build.sh" >/dev/null
bash -n \
  "$ROOT_DIR/build.sh" \
  "$ROOT_DIR"/src/core/*.sh \
  "$ROOT_DIR"/src/components/*.sh \
  "$ROOT_DIR"/src/preview/*.sh \
  "$ROOT_DIR"/src/cli/*.sh \
  "$MOMA_DIST"

deterministic_copy="$(mktemp "${TMPDIR:-/tmp}/moma-build.XXXXXX")"
cp "$MOMA_DIST" "$deterministic_copy"
"$ROOT_DIR/build.sh" >/dev/null
cmp -s "$deterministic_copy" "$MOMA_DIST"
rm -f "$deterministic_copy"

[[ -x "$MOMA_DIST" ]]
[[ ! -e "$ROOT_DIR/moma.sh" ]]

plain_help="$(PATH=/usr/bin:/bin "$MOMA_DIST" --help)"
[[ "$plain_help" == *"Moma - terminal UI components for Bash"* ]]
[[ "$plain_help" == *"confirm"* ]]
[[ "$plain_help" == *"spinner"* ]]
[[ "$plain_help" == *"command-check"* ]]
[[ "$plain_help" == *"version"* ]]
[[ "$plain_help" == *"update"* ]]
[[ "$plain_help" == *"--version, -v"* ]]

version_output="$("$MOMA_DIST" version)"
[[ "$version_output" == "1.3.0" ]]

version_flag_output="$("$MOMA_DIST" --version)"
[[ "$version_flag_output" == "$version_output" ]]

short_version_flag_output="$("$MOMA_DIST" -v)"
[[ "$short_version_flag_output" == "$version_output" ]]

version_status=0
"$MOMA_DIST" version >/dev/null 2>/dev/null || version_status=$?
[[ "$version_status" -eq 0 ]]
version_flag_status=0
"$MOMA_DIST" --version >/dev/null 2>/dev/null || version_flag_status=$?
[[ "$version_flag_status" -eq 0 ]]
short_version_flag_status=0
"$MOMA_DIST" -v >/dev/null 2>/dev/null || short_version_flag_status=$?
[[ "$short_version_flag_status" -eq 0 ]]

version_stderr="$("$MOMA_DIST" version 2>&1 >/dev/null)"
[[ -z "$version_stderr" ]]
version_flag_stderr="$("$MOMA_DIST" --version 2>&1 >/dev/null)"
[[ -z "$version_flag_stderr" ]]
short_version_flag_stderr="$("$MOMA_DIST" -v 2>&1 >/dev/null)"
[[ -z "$short_version_flag_stderr" ]]

set +e
"$MOMA_DIST" --version extra >/dev/null 2>&1
version_flag_extra_status=$?
"$MOMA_DIST" -v extra >/dev/null 2>&1
short_version_flag_extra_status=$?
set -e
[[ "$version_flag_extra_status" -eq 2 ]]
[[ "$short_version_flag_extra_status" -eq 2 ]]

set +e
component_dash_v_output="$(
  NO_COLOR=1 "$MOMA_DIST" msg "hi" -v 2>&1 >/dev/null
)"
set -e
[[ "$component_dash_v_output" == *"moma-msg: unknown option: -v"* ]]

binary_output="$(NO_COLOR=1 "$MOMA_DIST" msg "Ready" --success)"
[[ "$binary_output" == *"Ready"* ]]

simple_output="$(NO_COLOR=1 "$MOMA_DIST" msg-simple "Package installed")"
[[ "$simple_output" == "  ▪   Package installed" ]]

simple_error_output="$(
  env -u NO_COLOR \
    "$MOMA_DIST" msg-simple "Package installation failed" --error
)"
[[ "$simple_error_output" == *$'\033[31m▪\033[0m   Package installation failed' ]]

theme_config="$ROOT_DIR/examples/moma.confg"
theme_list="$(MOMA_CONFIG_FILE="$theme_config" "$MOMA_DIST" themes)"
[[ "$theme_list" == $'default (active)\nnight' ]]

config_home="$(mktemp -d "${TMPDIR:-/tmp}/moma-config.XXXXXX")"
mkdir -p "$config_home/.config/momaui"
cp "$theme_config" "$config_home/.config/momaui/moma.confg"
default_path_output="$(
  env -u NO_COLOR \
    -u MOMA_CONFIG_FILE \
    -u XDG_CONFIG_HOME \
    HOME="$config_home" \
    MOMA_THEME=night \
    "$MOMA_DIST" msg-simple "Default path"
)"
rm -rf "$config_home"
[[ "$default_path_output" == *$'\033[38;2;189;147;249m▪\033[0m   Default path' ]]

night_output="$(
  env -u NO_COLOR \
    MOMA_CONFIG_FILE="$theme_config" \
    MOMA_THEME=night \
    "$MOMA_DIST" msg-simple "Night"
)"
[[ "$night_output" == *$'\033[38;2;189;147;249m▪\033[0m   Night' ]]

theme_option_output="$(
  env -u NO_COLOR \
    MOMA_CONFIG_FILE="$theme_config" \
    "$MOMA_DIST" --theme night msg-simple "Option"
)"
[[ "$theme_option_output" == *$'\033[38;2;189;147;249m▪\033[0m   Option' ]]

custom_color_output="$(
  env -u NO_COLOR \
    MOMA_CONFIG_FILE="$theme_config" \
    "$MOMA_DIST" msg-simple "Custom" --color orange
)"
[[ "$custom_color_output" == *$'\033[38;2;255;184;108m▪\033[0m   Custom' ]]

override_output="$(
  env -u NO_COLOR \
    MOMA_CONFIG_FILE="$theme_config" \
    MOMA_THEME=night \
    MOMA_COLOR_PRIMARY='\033[34m' \
    "$MOMA_DIST" msg-simple "Override"
)"
[[ "$override_output" == *$'\033[34m▪\033[0m   Override' ]]

list_output="$(
  NO_COLOR=1 "$MOMA_DIST" list \
    "Clone repository" "Install dependencies"
)"
[[ "$list_output" == $'  ▪   Clone repository\n  ▪   Install dependencies' ]]

label_output="$(NO_COLOR=1 "$MOMA_DIST" label "TEXT HERE")"
[[ "$label_output" == '  ┌─ TEXT HERE ───────────────────────┐' ]]

header_output="$(NO_COLOR=1 "$MOMA_DIST" header "Type Something")"
expected_header=$'\n░▀█▀░█░█░█▀█░█▀▀░░░█▀▀░█▀█░█▄█░█▀▀░▀█▀░█░█░▀█▀░█▀█░█▀▀\n'
expected_header+=$'░░█░░░█░░█▀▀░█▀▀░░░▀▀█░█░█░█░█░█▀▀░░█░░█▀█░░█░░█░█░█░█\n'
expected_header+='░░▀░░░▀░░▀░░░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀'
[[ "$header_output" == "$expected_header" ]]

header_margin_spacing="$({
  printf 'PREVIOUS\n'
  NO_COLOR=1 "$MOMA_DIST" header "A"
  printf 'NEXT'
})"
[[ "$header_margin_spacing" == $'PREVIOUS\n\n░█▀█\n░█▀█\n░▀░▀\n\n\nNEXT' ]]

header_no_margin_spacing="$({
  NO_COLOR=1 "$MOMA_DIST" header "A" --margin-top 0 --margin-bottom 0
  printf 'NEXT'
})"
[[ "$header_no_margin_spacing" == $'░█▀█\n░█▀█\n░▀░▀\nNEXT' ]]

header_left_margin="$(
  NO_COLOR=1 "$MOMA_DIST" header "A" \
    --margin-top 0 --margin-bottom 0 --margin-left 3
)"
[[ "$header_left_margin" == $'   ░█▀█\n   ░█▀█\n   ░▀░▀' ]]

header_color_output="$(env -u NO_COLOR "$MOMA_DIST" header "Moma" --color red)"
[[ "$header_color_output" == *$'\033[31m'*$'\033[0m'* ]]

label_semantic_output="$(
  env -u NO_COLOR "$MOMA_DIST" label "Deployment" --success
)"
[[ "$label_semantic_output" == *$'\033[32m  ┌─ ✔ Deployment '* ]]

label_spacing="$({
  NO_COLOR=1 "$MOMA_DIST" label "TEXT HERE"
  printf 'NEXT'
})"
[[ "$label_spacing" == *$'┐\n\nNEXT' ]]

resume_output="$(
  NO_COLOR=1 "$MOMA_DIST" resume \
    --title "Shells" \
    --item "Bash" "GNU shell." \
    --item "Zsh" "Interactive shell." \
    --text "Plain note."
)"
[[ "$resume_output" == $'  ┌─ Shells\n  │  Bash  GNU shell.\n  │  Zsh   Interactive shell.\n  │  Plain note.\n  └' ]]

resume_spacing="$({
  NO_COLOR=1 "$MOMA_DIST" resume --title "One" --text "First."
  printf 'NEXT'
})"
[[ "$resume_spacing" == $'  ┌─ One\n  │  First.\n  └\n\nNEXT' ]]

resume_semantic_output="$(
  env -u NO_COLOR "$MOMA_DIST" resume --title "Review" --warning --text "Check"
)"
[[ "$resume_semantic_output" == *$'\033[33m!\033[0m  \033[1;37mReview'* ]]
[[ "$resume_semantic_output" == *'└'* ]]

resume_boxed_open="$(
  NO_COLOR=1 "$MOMA_DIST" resume --title "Moma Terminal UI library" \
    --icon "▪" --border open --text "element 1"
)"
[[ "$resume_boxed_open" == *$'\n  ▪  Moma Terminal UI library\n  │ \n  │  element 1'* ]]
[[ "$resume_boxed_open" != *'└'* ]]

resume_no_icon="$(
  NO_COLOR=1 "$MOMA_DIST" resume --title "Moma Terminal UI library" \
    --no-icon --text "element 1"
)"
[[ "$resume_no_icon" == *$'\n  │  Moma Terminal UI library\n  │ \n  │  element 1\n  └'* ]]

set +e
resume_bad_border="$(
  NO_COLOR=1 "$MOMA_DIST" resume --title "x" --border sideways 2>&1
)"
resume_bad_border_status=$?
set -e
[[ "$resume_bad_border_status" -eq 2 ]]
[[ "$resume_bad_border" == *"invalid border"* ]]

set +e
resume_missing_title="$(NO_COLOR=1 "$MOMA_DIST" resume --text "x" 2>&1)"
resume_missing_title_status=$?
set -e
[[ "$resume_missing_title_status" -eq 2 ]]
[[ "$resume_missing_title" == *"--title is required"* ]]

divider_default="$(NO_COLOR=1 "$MOMA_DIST" divider)"
[[ "$divider_default" == $'\n  ▪ '*'—'* ]]
[[ "$divider_default" != *'┌'* ]]
[[ "$divider_default" != *'└'* ]]

divider_framed="$(NO_COLOR=1 "$MOMA_DIST" divider --border line)"
[[ "$divider_framed" == $'\n  ┌\n  ▪ '*'—'*$'\n  └'* ]]

divider_semantic="$(env -u NO_COLOR "$MOMA_DIST" divider --success --border line)"
[[ "$divider_semantic" == *$'\033[32m'*'✔'* ]]

divider_no_icon="$(NO_COLOR=1 "$MOMA_DIST" divider --no-icon)"
[[ "$divider_no_icon" == $'\n    —'* ]]

set +e
divider_bad_border="$(NO_COLOR=1 "$MOMA_DIST" divider --border sideways 2>&1)"
divider_bad_border_status=$?
set -e
[[ "$divider_bad_border_status" -eq 2 ]]
[[ "$divider_bad_border" == *"invalid border"* ]]

set +e
divider_stray_arg="$(NO_COLOR=1 "$MOMA_DIST" divider stray 2>&1)"
divider_stray_arg_status=$?
set -e
[[ "$divider_stray_arg_status" -eq 1 ]]
[[ "$divider_stray_arg" == *"unexpected argument"* ]]

fixed_boxes="$({
  NO_COLOR=1 MOMA_WIDTH=50 \
    "$MOMA_DIST" box "Your configuration is ready." --success
  NO_COLOR=1 MOMA_WIDTH=50 \
    "$MOMA_DIST" box "Back up your files before continuing." --warning
})"
fixed_border='  ┌──────────────────────────────────────────────────┐'
[[ "$(rg -Fxc "$fixed_border" <<<"$fixed_boxes")" == "2" ]]
[[ "$fixed_boxes" == *'│ ✔ Your configuration is ready.                   │'* ]]
[[ "$fixed_boxes" == *'│ ! Back up your files before continuing.          │'* ]]

capped_box="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" box \
  "This long notice wraps inside its border." --info)"
[[ "$capped_box" == *'  ┌────────────────────────┐'* ]]
[[ "$capped_box" == *$'│ → This long notice     │\n  │ wraps inside its       │'* ]]

fixed_prompt="$(
  printf 'answer\n' | NO_COLOR=1 MOMA_WIDTH=46 "$MOMA_DIST" prompt "Short" 2>&1 >/dev/null
)"
[[ "$fixed_prompt" == *$'  └──────────────────────────────────────────────\n'* ]]

shared_width=46
shared_rule='──────────────────────────────────────────────'
fixed_title="$(
  NO_COLOR=1 MOMA_WIDTH="$shared_width" \
    "$MOMA_DIST" title "Short"
)"
[[ "$fixed_title" == *"  ┌${shared_rule}┐"* ]]
[[ "$fixed_title" == *"  └${shared_rule}┘"* ]]

title_markers="$(
  NO_COLOR=1 "$MOMA_DIST" title "Moma" "Terminal UI library"
)"
[[ "$title_markers" == *$'\n  ▪  Moma Terminal UI library         ▪\n'* ]]

title_no_icon="$(
  NO_COLOR=1 "$MOMA_DIST" title "Moma" "Terminal UI library" --no-icon
)"
[[ "$title_no_icon" == *$'\n  │  Moma Terminal UI library         │\n'* ]]

title_open="$(
  NO_COLOR=1 "$MOMA_DIST" title "Moma" "Terminal UI library" \
    --no-icon --border open
)"
[[ "$title_open" == *$'\n  │  Moma Terminal UI library\n'* ]]

title_line="$(
  NO_COLOR=1 "$MOMA_DIST" title "Moma" "Terminal UI library" --border line
)"
[[ "$title_line" == *$'\n  ▪  Moma Terminal UI library         │\n'* ]]

title_semantic="$(
  env -u NO_COLOR "$MOMA_DIST" title "Moma" "Terminal UI library" --success
)"
[[ "$title_semantic" == *$'✔  \033[32mMoma'* ]]
[[ "$title_semantic" == *'         ✔'* ]]
[[ "$title_semantic" == *$'\033[32m'* ]]

set +e
title_bad_border="$(
  NO_COLOR=1 "$MOMA_DIST" title "Moma" --border sideways 2>&1
)"
title_bad_border_status=$?
set -e
[[ "$title_bad_border_status" -eq 2 ]]
[[ "$title_bad_border" == *"invalid border"* ]]

fixed_title_sub="$(
  NO_COLOR=1 MOMA_WIDTH="$shared_width" \
    "$MOMA_DIST" title-sub "Short"
)"
[[ "$fixed_title_sub" == *"  └${shared_rule}"* ]]

title_sub_no_icon="$(
  NO_COLOR=1 "$MOMA_DIST" title-sub "Dependencies" "Installing packages" \
    --no-icon
)"
[[ "$title_sub_no_icon" == *$'\n     Dependencies Installing packages\n  └'* ]]
[[ "$title_sub_no_icon" != *'┘'* ]]

title_sub_line="$(
  NO_COLOR=1 "$MOMA_DIST" title-sub "Dependencies" "Installing packages" \
    --border line
)"
[[ "$title_sub_line" == *$'\n  ▪  Dependencies Installing packages\n  └'*'┘'* ]]

title_sub_mirror="$(
  NO_COLOR=1 "$MOMA_DIST" title-sub "Dependencies" "Installing packages" \
    --border mirror
)"
[[ "$title_sub_mirror" == *$'Installing packages   ▪\n  └'*'┘'* ]]

set +e
title_sub_bad_border="$(
  NO_COLOR=1 "$MOMA_DIST" title-sub "x" --border sideways 2>&1
)"
title_sub_bad_border_status=$?
set -e
[[ "$title_sub_bad_border_status" -eq 2 ]]
[[ "$title_sub_bad_border" == *"invalid border"* ]]

sub_title_default="$(
  NO_COLOR=1 "$MOMA_DIST" sub-title "Moma" "Terminal UI library"
)"
[[ "$sub_title_default" == $'\n  ┌───────────────────────────────────┐\n  ▪  Moma Terminal UI library         ▪'* ]]

sub_title_open_no_icon="$(
  NO_COLOR=1 "$MOMA_DIST" sub-title "Moma" "Terminal UI library" \
    --no-icon --border open
)"
[[ "$sub_title_open_no_icon" == $'\n  ┌────────────────────────────────────\n     Moma Terminal UI library'* ]]
[[ "$sub_title_open_no_icon" != *'┐'* ]]

sub_title_line="$(
  NO_COLOR=1 "$MOMA_DIST" sub-title "Moma" "Terminal UI library" \
    --border line
)"
[[ "$sub_title_line" == $'\n  ┌───────────────────────────────────┐\n  ▪  Moma Terminal UI library'* ]]
[[ "$sub_title_line" != *'▪  Moma Terminal UI library'*'▪'* ]]

set +e
sub_title_bad_border="$(
  NO_COLOR=1 "$MOMA_DIST" sub-title "x" --border sideways 2>&1
)"
sub_title_bad_border_status=$?
set -e
[[ "$sub_title_bad_border_status" -eq 2 ]]
[[ "$sub_title_bad_border" == *"invalid border"* ]]

fixed_label="$(
  NO_COLOR=1 MOMA_WIDTH="$shared_width" \
    "$MOMA_DIST" label "Short"
)"
[[ "$fixed_label" == "  ┌─ Short ──────────────────────────────────────┐" ]]

label_top_open="$(NO_COLOR=1 "$MOMA_DIST" label "PROJECT NAME" --border open)"
[[ "$label_top_open" == "  ┌─ PROJECT NAME ─────────────────────" ]]

label_top_closed="$(NO_COLOR=1 "$MOMA_DIST" label "PROJECT NAME")"
[[ "$label_top_closed" == "  ┌─ PROJECT NAME ────────────────────┐" ]]

label_bottom_closed="$(NO_COLOR=1 "$MOMA_DIST" label "PROJECT NAME" --edge bottom)"
[[ "$label_bottom_closed" == "  └─ PROJECT NAME ────────────────────┘" ]]

label_bottom_open="$(
  NO_COLOR=1 "$MOMA_DIST" label "PROJECT NAME" --edge bottom --border open
)"
[[ "$label_bottom_open" == "  └─ PROJECT NAME ─────────────────────" ]]

[[ "${#label_top_open}" -eq "${#label_top_closed}" ]]
[[ "${#label_top_closed}" -eq "${#label_bottom_closed}" ]]
[[ "${#label_bottom_closed}" -eq "${#label_bottom_open}" ]]

set +e
label_bad_edge="$(NO_COLOR=1 "$MOMA_DIST" label "x" --edge sideways 2>&1)"
label_bad_edge_status=$?
label_bad_border="$(NO_COLOR=1 "$MOMA_DIST" label "x" --border sideways 2>&1)"
label_bad_border_status=$?
set -e
[[ "$label_bad_edge_status" -eq 2 ]]
[[ "$label_bad_edge" == *"invalid edge"* ]]
[[ "$label_bad_border_status" -eq 2 ]]
[[ "$label_bad_border" == *"invalid border"* ]]

fixed_input="$(
  NO_COLOR=1 MOMA_WIDTH="$shared_width" \
    "$MOMA_DIST" input --title "Short" --value "Value"
)"
[[ "$fixed_input" == *"  └${shared_rule}┘"* ]]

prompt_answer="$(printf 'Yes, continue\n' | NO_COLOR=1 "$MOMA_DIST" prompt "Continue?" 2>/dev/null)"
[[ "$prompt_answer" == "Yes, continue" ]]

prompt_chrome="$(printf 'Yes, continue\n' | NO_COLOR=1 "$MOMA_DIST" prompt "Continue?" 2>&1 >/dev/null)"
[[ "$prompt_chrome" == *$'\n  ▪  Continue?'* ]]
[[ "$prompt_chrome" == *$'\n  └'* ]]
[[ "$prompt_chrome" == *'❯ '* ]]

prompt_default="$(printf '\n' | NO_COLOR=1 "$MOMA_DIST" prompt "Deploy now?" --default yes 2>/dev/null)"
[[ "$prompt_default" == "yes" ]]
prompt_default_chrome="$(printf '\n' | NO_COLOR=1 "$MOMA_DIST" prompt "Deploy now?" --default yes 2>&1 >/dev/null)"
[[ "$prompt_default_chrome" == *"Deploy now? [yes]"* ]]

prompt_trim="$(printf '  padded  \n' | NO_COLOR=1 "$MOMA_DIST" prompt "Name?" --trim 2>/dev/null)"
[[ "$prompt_trim" == "padded" ]]

prompt_required="$(printf '\nok\n' | NO_COLOR=1 "$MOMA_DIST" prompt "Name?" --required 2>/dev/null)"
[[ "$prompt_required" == "ok" ]]

prompt_mirror="$(printf 'yes\n' | NO_COLOR=1 "$MOMA_DIST" prompt "Continue?" --border mirror 2>&1 >/dev/null)"
[[ "$prompt_mirror" == *'Continue?'*'▪'* ]]
[[ "$prompt_mirror" == *$'\n  └'*'┘'* ]]

set +e
prompt_bad_border="$(NO_COLOR=1 "$MOMA_DIST" prompt "x" --border sideways 2>&1 </dev/null)"
prompt_bad_border_status=$?
set -e
[[ "$prompt_bad_border_status" -eq 2 ]]
[[ "$prompt_bad_border" == *"invalid border"* ]]

fixed_select="$(NO_COLOR=1 MOMA_WIDTH="$shared_width" "$MOMA_DIST" \
  select One Two --title "Short" --choose 1 2>&1 >/dev/null)"
[[ "$fixed_select" == *"  └${shared_rule}"* ]]

fixed_multi_select="$(NO_COLOR=1 MOMA_WIDTH="$shared_width" "$MOMA_DIST" \
  multi-select One Two --title "Short" --choose 1 2>&1 >/dev/null)"
[[ "$fixed_multi_select" == *"  └${shared_rule}"* ]]

fixed_single_select_groups="$(NO_COLOR=1 MOMA_WIDTH="$shared_width" \
  "$MOMA_DIST" single-select-groups --title "Short" \
  --group G --option One --option Two --choose 1 2>&1 >/dev/null)"
[[ "$fixed_single_select_groups" == *"  └${shared_rule}"* ]]

fixed_multi_select_groups="$(NO_COLOR=1 MOMA_WIDTH="$shared_width" \
  "$MOMA_DIST" multi-select-groups --title "Short" \
  --group G --option One --option Two --choose 1 2>&1 >/dev/null)"
[[ "$fixed_multi_select_groups" == *"  └${shared_rule}"* ]]

fixed_confirm="$(NO_COLOR=1 MOMA_WIDTH="$shared_width" "$MOMA_DIST" \
  confirm "Short" --answer yes 2>&1 >/dev/null)"
[[ "$fixed_confirm" == *"  └${shared_rule}"* ]]

local_width="$(NO_COLOR=1 MOMA_WIDTH=50 "$MOMA_DIST" box "Override" --width 20)"
[[ "$local_width" == *'  ┌────────────────────┐'* ]]

local_max_width="$(NO_COLOR=1 "$MOMA_DIST" box \
  "Local maximum width wraps this notice." --max-width 24)"
[[ "$local_max_width" == *'  ┌────────────────────────┐'* ]]

minimum_width="$(NO_COLOR=1 MOMA_WIDTH=1 "$MOMA_DIST" box "Long value")"
[[ "$minimum_width" == *'  ┌────────┐'* ]]
[[ "$minimum_width" == *$'  │ Long   │\n  │ value  │'* ]]

capped_rule='────────────────────────'
capped_title="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  title "A title that is longer than the maximum")"
[[ "$capped_title" == *"  ┌${capped_rule}┐"* ]]

capped_prompt="$(printf 'answer\n' | NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  prompt "A prompt longer than the maximum" 2>&1 >/dev/null)"
[[ "$capped_prompt" == *"  └${capped_rule}"* ]]

capped_label="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  label "A label longer than the maximum")"
[[ "$capped_label" == '  ┌─ A label longer than… ─┐' ]]

capped_input="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  input --title "A long input title" \
  --value "A value longer than the maximum width")"
[[ "$capped_input" == *"  └${capped_rule}┘"* ]]

capped_select="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  select One Two \
  --title "A selector title longer than the maximum" \
  --choose 1 2>&1 >/dev/null)"
[[ "$capped_select" == *"  └${capped_rule}"* ]]

capped_multi_select="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  multi-select One Two \
  --title "A multi selector title longer than the maximum" \
  --choose 1 2>&1 >/dev/null)"
[[ "$capped_multi_select" == *"  └${capped_rule}"* ]]

capped_single_select_groups="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  single-select-groups \
  --title "A grouped selector title longer than the maximum" \
  --group G --option One --option Two \
  --choose 1 2>&1 >/dev/null)"
[[ "$capped_single_select_groups" == *"  └${capped_rule}"* ]]

capped_multi_select_groups="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  multi-select-groups \
  --title "A grouped multi selector title longer than the maximum" \
  --group G --option One --option Two \
  --choose 1 2>&1 >/dev/null)"
[[ "$capped_multi_select_groups" == *"  └${capped_rule}"* ]]

capped_confirm="$(NO_COLOR=1 MOMA_MAX_WIDTH=24 "$MOMA_DIST" \
  confirm "A confirmation question longer than the maximum" \
  --answer yes 2>&1 >/dev/null)"
[[ "$capped_confirm" == *"  └${capped_rule}"* ]]

strict_output="$(
  NO_COLOR=1 bash -euo pipefail \
    -c 'source "$1"; moma-msg "Strict mode" --success' \
    _ "$MOMA_DIST"
)"
[[ "$strict_output" == *"Strict mode"* ]]

bash -euo pipefail -c '
    before_pwd="$PWD"
    before_ifs="$(printf %q "$IFS")"
    before_options="$(set +o)"
    before_shopt="$(shopt -p)"
    trap ": consumer-int" INT
    before_int="$(trap -p INT)"
    capture="$(mktemp)"
    trap '\''rm -f "$capture"'\'' EXIT

    source "$1" >"$capture" 2>&1

    [[ ! -s "$capture" ]]
    [[ "$PWD" == "$before_pwd" ]]
    [[ "$(printf %q "$IFS")" == "$before_ifs" ]]
    [[ "$(set +o)" == "$before_options" ]]
    [[ "$(shopt -p)" == "$before_shopt" ]]
    [[ "$(trap -p INT)" == "$before_int" ]]
' _ "$MOMA_DIST"

bash -c '
    source "$1"
    [[ "$(_moma_select_transition 0 3 up)" == $'\''2\tcontinue'\'' ]]
    transition="$(_moma_multi_select_transition 1 "0,2" 3 space)"
    [[ "$transition" == $'\''1\t0,2,1\tcontinue'\'' ]]
    [[ "$(_moma_confirm_transition 0 n)" == $'\''1\tconfirm'\'' ]]
    _moma_require_bash_version 4 0
' _ "$MOMA_DIST"

# Unified `moma <command>` dispatcher: sourcing defines the function, it is
# not auto-exported, repeated sourcing stays idempotent, and it produces
# byte-identical stdout, stderr, and exit status to the executable for
# representative commands. See tests/integration/dispatch-parity.bats for
# the full registry-driven matrix.
bash -c '
    source "$1"
    declare -F moma >/dev/null
' _ "$MOMA_DIST"

not_exported_status=0
bash -c '
    source "$1"
    bash -c "declare -F moma" >/dev/null 2>&1
' _ "$MOMA_DIST" || not_exported_status=$?
[[ "$not_exported_status" -ne 0 ]]

idempotent_source_output="$(
  bash -euo pipefail -c '
    source "$1"
    source "$1"
    declare -F moma | wc -l | tr -d " "
    NO_COLOR=1 moma msg-simple "twice"
  ' _ "$MOMA_DIST"
)"
[[ "$idempotent_source_output" == $'1\n  ▪   twice' ]]

compare_dispatch_parity() {
  local description="$1"
  shift
  local exec_stdout exec_stderr exec_status
  local source_stdout source_stderr source_status
  local exec_stdout_file exec_stderr_file source_stdout_file source_stderr_file
  exec_stdout_file="$(mktemp)"
  exec_stderr_file="$(mktemp)"
  source_stdout_file="$(mktemp)"
  source_stderr_file="$(mktemp)"

  set +e
  env NO_COLOR=1 "$MOMA_DIST" "$@" \
    >"$exec_stdout_file" 2>"$exec_stderr_file"
  exec_status=$?
  # Positional parameters are intentionally expanded by the child Bash process.
  # shellcheck disable=SC2016
  env NO_COLOR=1 bash -c '
      source "$1"
      shift
      moma "$@"
  ' _ "$MOMA_DIST" "$@" >"$source_stdout_file" 2>"$source_stderr_file"
  source_status=$?
  set -e

  exec_stdout="$(<"$exec_stdout_file")"
  exec_stderr="$(<"$exec_stderr_file")"
  source_stdout="$(<"$source_stdout_file")"
  source_stderr="$(<"$source_stderr_file")"
  rm -f \
    "$exec_stdout_file" "$exec_stderr_file" \
    "$source_stdout_file" "$source_stderr_file"

  if [[ "$exec_stdout" != "$source_stdout" ]] ||
    [[ "$exec_stderr" != "$source_stderr" ]] ||
    [[ "$exec_status" != "$source_status" ]]; then
    printf 'smoke: dispatch parity mismatch for %s\n' "$description" >&2
    printf 'exec status=%s stdout=%q stderr=%q\n' \
      "$exec_status" "$exec_stdout" "$exec_stderr" >&2
    printf 'source status=%s stdout=%q stderr=%q\n' \
      "$source_status" "$source_stdout" "$source_stderr" >&2
    exit 1
  fi
}

compare_dispatch_parity "msg-simple" msg-simple "Package installed"
compare_dispatch_parity "msg-simple with empty argument" msg-simple ""
compare_dispatch_parity "msg-simple with whitespace and glob text" \
  msg-simple "  spaced *.sh value  "
compare_dispatch_parity "msg-simple with a leading-dash-like value" \
  msg-simple -- "--not-an-option"
compare_dispatch_parity "single-select --choose" \
  single-select "Development" "Staging" "Production" \
  --title Environment --choose 2
compare_dispatch_parity "confirm --answer yes" \
  confirm "Continue?" --answer yes
compare_dispatch_parity "confirm --answer no" \
  confirm "Continue?" --answer no
compare_dispatch_parity "unknown command" does-not-exist
compare_dispatch_parity "missing required argument" single-select-groups \
  --title Features --group Docker
compare_dispatch_parity "help" --help
compare_dispatch_parity "version" version
compare_dispatch_parity "version flag" --version
compare_dispatch_parity "short version flag" -v
compare_dispatch_parity "themes" themes

theme_config_parity="$ROOT_DIR/examples/moma.confg"
exec_theme_stdout="$(
  env -u NO_COLOR MOMA_CONFIG_FILE="$theme_config_parity" \
    "$MOMA_DIST" --theme night msg-simple "Themed"
)"
source_theme_stdout="$(
  # Positional parameters are intentionally expanded by the child Bash process.
  # shellcheck disable=SC2016
  env -u NO_COLOR MOMA_CONFIG_FILE="$theme_config_parity" bash -c '
      source "$1"
      moma --theme night msg-simple "Themed"
  ' _ "$MOMA_DIST"
)"
[[ "$exec_theme_stdout" == "$source_theme_stdout" ]]

legacy_output="$(NO_COLOR=1 bash -c '
    source "$1"
    moma-msg-simple "Package installed"
' _ "$MOMA_DIST")"
canonical_output="$(NO_COLOR=1 bash -c '
    source "$1"
    moma msg-simple "Package installed"
' _ "$MOMA_DIST")"
[[ "$legacy_output" == "$canonical_output" ]]

input_output="$(
  printf '  project  \n' |
    NO_COLOR=1 "$MOMA_DIST" input \
      --title "Project" --read --trim 2>/dev/null
)"
[[ "$input_output" == "project" ]]

input_display_spacing="$(
  NO_COLOR=1 "$MOMA_DIST" input --title "Owner" --value "asdf"
  printf 'NEXT'
)"
[[ "$input_display_spacing" == *$'┘\n\nNEXT' ]]

input_read_spacing="$(
  printf 'asdf\n' |
    NO_COLOR=1 "$MOMA_DIST" input \
      --title "Owner" --read 2>&1 >/dev/null
  printf 'NEXT'
)"
[[ "$input_read_spacing" == *$'│❯ \n\nNEXT' ]]

select_output="$(
  NO_COLOR=1 "$MOMA_DIST" select \
    Development Staging Production \
    --title Environment --choose 2 2>/dev/null
)"
[[ "$select_output" == "Staging" ]]

select_visual="$(
  NO_COLOR=1 "$MOMA_DIST" select \
    Development Staging Production \
    --title Environment --choose 2 2>&1 >/dev/null
  printf 'NEXT'
)"
[[ "$select_visual" == $'  ▪  Environment\n  └──────────────────────────────\n    ○ Development\n  › ◉ Staging\n    ○ Production\n  ↑/↓ move · Enter select · q cancel\n\nNEXT' ]]

single_select_output="$(
  NO_COLOR=1 "$MOMA_DIST" single-select \
    Development Staging Production \
    --title Environment --choose 2 2>/dev/null
)"
[[ "$single_select_output" == "$select_output" ]]

single_select_visual="$(
  NO_COLOR=1 "$MOMA_DIST" single-select \
    Up Down Stop --title Features --choose 1 2>&1 >/dev/null
)"
[[ "$single_select_visual" == $'  ▪  Features\n  └──────────────────────────────\n  › ◉ Up\n    ○ Down\n    ○ Stop\n  ↑/↓ move · Enter select · q cancel' ]]

single_select_groups_output="$(
  NO_COLOR=1 "$MOMA_DIST" single-select-groups \
    --title Features \
    --group Docker --option Up --option Down --option Stop \
    --group npm --option install --option "run dev" --option "run deploy" \
    --choose 4 2>/dev/null
)"
[[ "$single_select_groups_output" == "install" ]]

single_select_groups_visual="$(
  NO_COLOR=1 "$MOMA_DIST" single-select-groups \
    --title Features \
    --group Docker --option Up --option Down --option Stop \
    --group npm --option install --option "run dev" --option "run deploy" \
    --choose 1 2>&1 >/dev/null
)"
expected_single_groups=$'  ▪  Features\n  └──────────────────────────────\n\n'
expected_single_groups+=$'    Docker\n  › ◉ Up\n    ○ Down\n    ○ Stop\n\n'
expected_single_groups+=$'    npm\n    ○ install\n    ○ run dev\n    ○ run deploy\n'
expected_single_groups+='  ↑/↓ move · Enter select · q cancel'
[[ "$single_select_groups_visual" == "$expected_single_groups" ]]

multi_select_output="$(
  NO_COLOR=1 "$MOMA_DIST" multi-select \
    Docker CI Tests --title Features --choose 1,3 2>/dev/null
)"
[[ "$multi_select_output" == $'Docker\nTests' ]]

multi_select_visual="$(
  NO_COLOR=1 "$MOMA_DIST" multi-select \
    Docker CI Tests --title Features --choose 1,3 2>&1 >/dev/null
  printf 'NEXT'
)"
[[ "$multi_select_visual" == $'  ▪  Features\n  └──────────────────────────────\n  › ▣ Docker\n    □ CI\n    ▣ Tests\n  ↑/↓ move · Space toggle · Enter confirm · q cancel\n\nNEXT' ]]

multi_select_groups_output="$(
  NO_COLOR=1 "$MOMA_DIST" multi-select-groups \
    --title Features \
    --group "North America" --option "United States" --option Canada \
    --option Mexico \
    --group "South America" --option Colombia --option Argentina \
    --option Peru \
    --choose 1,3 2>/dev/null
)"
[[ "$multi_select_groups_output" == $'United States\nMexico' ]]

[[ "$single_select_groups_output" != *"Docker"* ]]
[[ "$single_select_groups_output" != *"npm"* ]]
[[ "$multi_select_groups_output" != *"North America"* ]]
[[ "$multi_select_groups_output" != *"South America"* ]]

multi_select_groups_dedup_output="$(
  NO_COLOR=1 "$MOMA_DIST" multi-select-groups \
    --title Features \
    --group "North America" --option "United States" --option Canada \
    --option Mexico \
    --group "South America" --option Colombia --option Argentina \
    --option Peru \
    --choose 3,1,3 2>/dev/null
)"
[[ "$multi_select_groups_dedup_output" == "$multi_select_groups_output" ]]

multi_select_groups_visual="$(
  NO_COLOR=1 "$MOMA_DIST" multi-select-groups \
    --title Features \
    --group "North America" --option "United States" --option Canada \
    --option Mexico \
    --group "South America" --option Colombia --option Argentina \
    --option Peru \
    --choose 1,3 2>&1 >/dev/null
)"
expected_multi_groups=$'  ▪  Features\n  └──────────────────────────────\n\n    ▨ Select All\n\n'
expected_multi_groups+=$'    North America\n    ▨ All\n  › ▣ United States\n    □ Canada\n    ▣ Mexico\n\n'
expected_multi_groups+=$'    South America\n    □ All\n    □ Colombia\n    □ Argentina\n    □ Peru\n'
expected_multi_groups+='  ↑/↓ move · Space toggle · Enter confirm · q cancel'
[[ "$multi_select_groups_visual" == "$expected_multi_groups" ]]

set +e
NO_COLOR=1 "$MOMA_DIST" single-select-groups --title Features \
  --option Up >/dev/null 2>&1
option_before_group_status=$?
set -e
[[ "$option_before_group_status" -eq 2 ]]

set +e
NO_COLOR=1 "$MOMA_DIST" single-select-groups --title Features \
  --group Docker >/dev/null 2>&1
empty_group_status=$?
set -e
[[ "$empty_group_status" -eq 2 ]]

set +e
NO_COLOR=1 "$MOMA_DIST" single-select-groups --title Features >/dev/null 2>&1
no_group_status=$?
set -e
[[ "$no_group_status" -eq 2 ]]

set +e
NO_COLOR=1 "$MOMA_DIST" single-select-groups --title Features \
  --group Docker --option >/dev/null 2>&1
missing_option_value_status=$?
set -e
[[ "$missing_option_value_status" -eq 2 ]]

set +e
NO_COLOR=1 "$MOMA_DIST" single-select-groups --title Features \
  --group Docker --option Up --choose 9 >/dev/null 2>&1
out_of_range_status=$?
set -e
[[ "$out_of_range_status" -eq 2 ]]

set +e
multi_groups_required_output="$(
  NO_COLOR=1 "$MOMA_DIST" multi-select-groups --title Features \
    --group Docker --option Up --required --choose "" 2>&1 >/dev/null
)"
multi_groups_required_status=$?
set -e
[[ "$multi_groups_required_status" -eq 2 ]]
[[ "$multi_groups_required_output" == *"select at least one option"* ]]

prompt_visual="$(
  printf 'answer\n' | NO_COLOR=1 "$MOMA_DIST" prompt \
    "Choose the target environment" 2>&1 >/dev/null
)"
[[ "$prompt_visual" == $'\n  ▪  Choose the target environment \n  └───────────────────────────────────'* ]]

rabbit_visual="$(NO_COLOR=1 "$MOMA_DIST" rabbit "Ready")"
[[ "$rabbit_visual" == *$'\n  | Ready\n  /⎺⎺⎺⎺⎺⎺⎺⎺\n\n    (\\(\\\n    (-.-)\n  o_(\")(")' ]]

compact_message_composition="$({
  NO_COLOR=1 "$MOMA_DIST" msg-simple "First"
  NO_COLOR=1 "$MOMA_DIST" msg-simple "Second"
})"
[[ "$compact_message_composition" == $'  ▪   First\n  ▪   Second' ]]

secret_output="$(
  printf 'secret-value\n' |
    NO_COLOR=1 "$MOMA_DIST" input \
      --title "Secret" --read --secret 2>/dev/null
)"
[[ "$secret_output" == "secret-value" ]]

if [[ "${MOMA_TEST_TTY:-1}" == "1" ]] && command -v script &>/dev/null; then
  state_check="bash -c 'before=\"\$(stty -g)\"; "
  state_check+="source \"$MOMA_DIST\"; "
  state_check+="after=\"\$(stty -g)\"; "
  state_check+="[[ \"\$before\" == \"\$after\" ]]'"
  script -qec "$state_check" /dev/null >/dev/null

  masked_output="$(
    printf $'abc\177d\n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' input --title Secret --read --secret" \
        /dev/null
  )"
  [[ "$masked_output" == *'│❯ ***'* ]]
  [[ "$masked_output" == *$'│❯ ***\r\n\r\n'* ]]
  [[ "$masked_output" == *$'abd\r'* ]]

  select_tty_output="$(
    printf $'\033[B\n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' select Development Staging Production \
--title Environment" /dev/null
  )"
  [[ "$select_tty_output" == *'◉ Staging'* ]]
  [[ "$select_tty_output" == *'▪  Environment'* ]]
  [[ "$select_tty_output" == *'└──────────────────────────────'* ]]
  [[ "$select_tty_output" == *$'Staging\r'* ]]

  set +e
  select_cancel_output="$(
    printf 'q' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' select Development Staging Production \
--title Environment" /dev/null
  )"
  select_cancel_status=$?
  set -e
  [[ "$select_cancel_status" -eq 130 ]]
  [[ "$select_cancel_output" == *'Enter select'* ]]

  single_select_groups_tty_output="$(
    printf $'\033[B\033[B\033[B\n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' single-select-groups --title Features \
--group Docker --option Up --option Down --option Stop \
--group npm --option install --option 'run dev' --option 'run deploy'" \
        /dev/null
  )"
  [[ "$single_select_groups_tty_output" == *'    Docker'* ]]
  [[ "$single_select_groups_tty_output" == *'    npm'* ]]
  [[ "$single_select_groups_tty_output" == *'◉ install'* ]]
  [[ "$single_select_groups_tty_output" == *$'install\r'* ]]

  multi_select_groups_tty_output="$(
    printf $' \033[B\033[B \033[B\n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' multi-select-groups --title Features \
--group Docker --option Up --option Down --option Stop \
--group npm --option install --option 'run dev' --option 'run deploy' \
--required" /dev/null
  )"
  [[ "$multi_select_groups_tty_output" == *'▣ Up'* ]]
  [[ "$multi_select_groups_tty_output" == *'▣ Stop'* ]]
  [[ "$multi_select_groups_tty_output" == *$'Up\r\nStop\r'* ]]

  multi_select_groups_all_tty_output="$(
    printf $'\033[A \033[B\033[B\033[B\033[B \n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' multi-select-groups --title Features \
--group Docker --option Up --option Down --option Stop \
--group npm --option install --option 'run dev' --option 'run deploy' \
--required" /dev/null
  )"
  [[ "$multi_select_groups_all_tty_output" == *'▣ All'* ]]
  [[ "$multi_select_groups_all_tty_output" == *$'Up\r\nDown\r\nStop\r\ninstall\r\nrun dev\r\nrun deploy\r'* ]]

  multi_select_tty_output="$(
    printf $' \033[B \n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' multi-select Docker CI Tests \
--title Features --required" /dev/null
  )"
  [[ "$multi_select_tty_output" == *'▪  Features'* ]]
  [[ "$multi_select_tty_output" == *'└──────────────────────────────'* ]]
  [[ "$multi_select_tty_output" == *'▣ Docker'* ]]
  [[ "$multi_select_tty_output" == *'▣ CI'* ]]
  [[ "$multi_select_tty_output" == *$'Docker\r\nCI\r'* ]]

  # A list taller than the terminal must scroll a fixed-size window instead
  # of losing track of the active row: every redraw moves the cursor up by
  # the same, bounded line count (never the full, ever-growing option
  # count), and the active pointer stays inside the window at every step.
  multi_select_overflow_tty_output="$(
    printf $'\033[B\033[B\033[B\033[B\033[B\033[B\033[B\033[B\033[B\033[B\033[B\033[B \n' |
      script -qec \
        "LINES=10 NO_COLOR=1 '$MOMA_DIST' multi-select \
Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa \
Lambda Mu Nu Xi Omicron --title Options" /dev/null
  )"
  [[ "$multi_select_overflow_tty_output" == *'more above'* ]]
  [[ "$multi_select_overflow_tty_output" == *'more below'* ]]
  [[ "$multi_select_overflow_tty_output" == *$'\033[10A'* ]]
  [[ "$multi_select_overflow_tty_output" != *$'\033[18A'* ]]
  [[ "$multi_select_overflow_tty_output" == *$'Nu\r'* ]]

  # The same fix, grouped: 3 groups / 12 options (row_count 16, full_lines
  # 26) must scroll a bounded compact window rather than the unwindowed
  # 26-line layout. The compact window reserves 1 row of prompt headroom
  # below LINES, so its move_up count is a session-constant 9 (LINES - 1),
  # never the unwindowed 26, and a row deep inside a scrolled-out group
  # (Peru, row 8) must stay individually selectable, not just reachable via
  # Select All.
  multi_select_groups_overflow_tty_output="$(
    printf $'\033[B\033[B\033[B\033[B\033[B\033[B \n' |
      script -qec \
        "LINES=10 NO_COLOR=1 '$MOMA_DIST' multi-select-groups --title Overflow \
--group NorthAmerica --option UnitedStates --option Canada --option Mexico \
--group SouthAmerica --option Colombia --option Argentina --option Peru \
--option Chile --option Brazil \
--group Europe --option Spain --option France --option Germany --option Italy" \
        /dev/null
  )"
  [[ "$multi_select_groups_overflow_tty_output" == *'more below'* ]]
  [[ "$multi_select_groups_overflow_tty_output" == *$'\033[9A'* ]]
  [[ "$multi_select_groups_overflow_tty_output" != *$'\033[26A'* ]]
  [[ "$multi_select_groups_overflow_tty_output" == *'All · SouthAmerica'* ]]
  # A bare, unindented "Peru" line is the emitted stdout value; every
  # rendered row instead has "  " plus a pointer and glyph before the name,
  # so this also proves Peru (scrolled well past the initial window) was
  # actually selectable, not just visible via Select All.
  [[ "$multi_select_groups_overflow_tty_output" == *$'\nPeru\r'* ]]
  [[ "$multi_select_groups_overflow_tty_output" != *$'\nUnitedStates'* ]]

  set +e
  confirm_arrow_output="$(
    printf $'\033[B\n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' confirm 'Create this project?'" \
        /dev/null
  )"
  confirm_arrow_status=$?
  set -e
  [[ "$confirm_arrow_status" -eq 1 ]]
  [[ "$confirm_arrow_output" == *$'  ▪  Create this project? [no]'* ]]
  [[ "$confirm_arrow_output" == *$'  └────────────────────────────────'* ]]
  [[ "$confirm_arrow_output" == *'▪ No'* ]]

  confirm_y_output="$(
    printf 'y' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' confirm 'Create this project?'" \
        /dev/null
  )"
  [[ "$confirm_y_output" == *'▪  Create this project? [yes]'* ]]

  set +e
  confirm_n_output="$(
    printf 'n' |
      script -qec \
        "NO_COLOR=1 '$MOMA_DIST' confirm 'Create this project?'" \
        /dev/null
  )"
  confirm_n_status=$?
  set -e
  [[ "$confirm_n_status" -eq 1 ]]
  [[ "$confirm_n_output" == *'▪  Create this project? [no]'* ]]
fi

confirm_yes_output="$(
  NO_COLOR=1 "$MOMA_DIST" confirm \
    "Continue?" --default yes --answer yes 2>&1
)"
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
confirm_no_output="$(
  NO_COLOR=1 "$MOMA_DIST" confirm "Continue?" --answer no 2>&1
)"
confirm_no_status=$?
set -e
[[ "$confirm_no_status" -eq 1 ]]
[[ "$confirm_no_output" == *"▪  Continue? [no]"* ]]
[[ "$confirm_no_output" == *"▪ No"* ]]

sleep 0.02 &
spinner_pid=$!
spinner_output="$(
  NO_COLOR=1 "$MOMA_DIST" spinner \
    "$spinner_pid" "Finished" --delay 0.01
)"
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
moma-divider
moma-header
moma-input
moma-label
moma-list
moma-msg
moma-msg-simple
moma-multi-select
moma-multi-select-groups
moma-prompt
moma-rabbit
moma-resume
moma-section
moma-select
moma-single-select
moma-single-select-groups
moma-spinner
moma-sub-title
moma-title
moma-title-sub
moma-update
moma-version
EOF

mapfile -t actual_functions < <(
  bash -c 'source "$1"; compgen -A function | LC_ALL=C sort' _ "$MOMA_DIST" |
    rg '^moma-'
)
[[ "${actual_functions[*]}" == "${expected_functions[*]}" ]]

mapfile -t registered_functions < <(
  bash -c 'source "$1"; _moma_command_registry' _ "$MOMA_DIST" |
    cut -f 2 |
    LC_ALL=C sort
)
[[ "${registered_functions[*]}" == "${expected_functions[*]}" ]]

for public_function in "${expected_functions[@]}"; do
  bash -c \
    'source "$1"; declare -F "$2" >/dev/null' \
    _ "$MOMA_DIST" "$public_function"
  if [[ "$public_function" == "moma-single-select" ]]; then
    # moma-select is a pure, zero-difference alias (single-select.sh: `moma-select() { moma-single-select "$@"; }`)
    # - the docs site merges the two into one "select" card rather than
    # documenting an identical duplicate, and mentions this alias in its
    # own description instead of getting a separate id: 'moma-single-select'.
    rg -q 'moma single-select' "$ROOT_DIR/web/src/data/apiEntries.ts"
  else
    rg -q "id: '$public_function'" "$ROOT_DIR/web/src/data/apiEntries.ts"
  fi
  rg -q "\\b$public_function\\b" "$ROOT_DIR/src/lib/README.md"
  # example.sh uses the canonical `moma <command>` form; either that or the
  # literal moma-* function name satisfies this cross-file contract.
  canonical_command="${public_function#moma-}"
  rg -q "\\bmoma $canonical_command\\b|\\b$public_function\\b" \
    "$ROOT_DIR/example.sh"
done

example_output="$(
  printf 'demo-project\nTICKET-123\nteam@example.com\nsuper-secret\nyes\n' |
    NO_COLOR=1 "$ROOT_DIR/example.sh" 2>&1
)"
[[ "$example_output" == *"Component showcase"* ]]
[[ "$example_output" == *"All required commands are available."* ]]
[[ "$example_output" == *"┌─ Basic details"* ]]
[[ "$example_output" == *"Deployment ticket reference"* ]]
[[ "$example_output" == *"TICKET-123"* ]]
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

update_candidate="$standalone_dir/latest-moma"
cat >"$update_candidate" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == "version" ]]; then
  printf '9.9.9\n'
fi
EOF
chmod 0755 "$update_candidate"

fake_update_bin="$standalone_dir/update-bin"
mkdir -p "$fake_update_bin"
cat >"$fake_update_bin/curl" <<'EOF'
#!/bin/bash
cp "$MOMA_UPDATE_FIXTURE" "${!#}"
EOF
chmod 0755 "$fake_update_bin/curl"

PATH="$fake_update_bin:$PATH" \
  MOMA_UPDATE_FIXTURE="$update_candidate" \
  MOMA_UPDATE_URL="https://updates.example.test/moma" \
  "$standalone_dir/moma" update
[[ "$("$standalone_dir/moma" version)" == "9.9.9" ]]

fake_bin="$standalone_dir/bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/glow" <<'EOF'
#!/usr/bin/env bash
printf 'glow arguments: %s\n' "$*"
cat
EOF
chmod +x "$fake_bin/glow"

glow_help="$(
  PATH="$fake_bin:/usr/bin:/bin" \
    MOMA_HELP_WIDTH=72 "$MOMA_DIST" help
)"
[[ "$glow_help" == *"glow arguments: -w 72 -"* ]]
[[ "$glow_help" == *"# Moma"* ]]

browser_stub_dir="$(mktemp -d "${TMPDIR:-/tmp}/moma-browser.XXXXXX")"
browser_capture="$browser_stub_dir/capture.txt"
docs_website_url="https://mgldvd.github.io/moma/"

cat >"$browser_stub_dir/uname" <<'EOF'
#!/bin/bash
[[ "$1" == "-s" ]] && printf '%s\n' "$STUB_PLATFORM"
EOF
chmod +x "$browser_stub_dir/uname"

cat >"$browser_stub_dir/open" <<'EOF'
#!/bin/bash
printf '%s\n' "$#" "$@" >"$STUB_CAPTURE"
exit "${STUB_EXIT:-0}"
EOF
chmod +x "$browser_stub_dir/open"
cp "$browser_stub_dir/open" "$browser_stub_dir/xdg-open"

macos_preview_web_out="$(
  env -u NO_COLOR STUB_PLATFORM=Darwin STUB_CAPTURE="$browser_capture" \
    PATH="$browser_stub_dir" "$MOMA_DIST" preview web
)"
macos_preview_web_status=$?
[[ "$macos_preview_web_status" -eq 0 ]]
[[ -z "$macos_preview_web_out" ]]
[[ "$(<"$browser_capture")" == $'1\n'"$docs_website_url" ]]
rm -f "$browser_capture"

linux_preview_web_out="$(
  env -u NO_COLOR STUB_PLATFORM=Linux STUB_CAPTURE="$browser_capture" \
    PATH="$browser_stub_dir" "$MOMA_DIST" preview web
)"
linux_preview_web_status=$?
[[ "$linux_preview_web_status" -eq 0 ]]
[[ -z "$linux_preview_web_out" ]]
[[ "$(<"$browser_capture")" == $'1\n'"$docs_website_url" ]]
rm -f "$browser_capture"

# MOMA_PREVIEW_PORT is obsolete for the hosted-website launcher and must be
# ignored rather than rejected or acted upon.
port_ignored_out="$(
  env -u NO_COLOR STUB_PLATFORM=Linux STUB_CAPTURE="$browser_capture" \
    MOMA_PREVIEW_PORT=not-a-port \
    PATH="$browser_stub_dir" "$MOMA_DIST" preview web
)"
port_ignored_status=$?
[[ "$port_ignored_status" -eq 0 ]]
[[ -z "$port_ignored_out" ]]
rm -f "$browser_capture"

set +e
launcher_failure_err="$(
  env -u NO_COLOR STUB_PLATFORM=Linux STUB_CAPTURE="$browser_capture" \
    STUB_EXIT=5 PATH="$browser_stub_dir" \
    "$MOMA_DIST" preview web 2>&1 >/dev/null
)"
launcher_failure_status=$?
set -e
[[ "$launcher_failure_status" -eq 5 ]]
[[ "$launcher_failure_err" == *"xdg-open"*"$docs_website_url"* ]]

uname_only_dir="$browser_stub_dir/uname-only"
mkdir -p "$uname_only_dir"
cp "$browser_stub_dir/uname" "$uname_only_dir/uname"

set +e
missing_launcher_err="$(
  env -u NO_COLOR STUB_PLATFORM=Linux \
    PATH="$uname_only_dir" \
    "$MOMA_DIST" preview web 2>&1 >/dev/null
)"
missing_launcher_status=$?
set -e
[[ "$missing_launcher_status" -eq 127 ]]
[[ "$missing_launcher_err" == *"xdg-open"*"$docs_website_url"* ]]

set +e
unsupported_platform_err="$(
  env -u NO_COLOR STUB_PLATFORM=Plan9 \
    PATH="$browser_stub_dir" "$MOMA_DIST" preview web 2>&1 >/dev/null
)"
unsupported_platform_status=$?
set -e
[[ "$unsupported_platform_status" -ne 0 ]]
[[ "$unsupported_platform_err" == *"$docs_website_url"* ]]

no_local_server_output="$(
  env -u NO_COLOR STUB_PLATFORM=Linux STUB_CAPTURE="$browser_capture" \
    PATH="$browser_stub_dir" "$MOMA_DIST" preview web 2>&1
)"
[[ "$no_local_server_output" != *"127.0.0.1"* ]]
[[ "$no_local_server_output" != *"http://"* ]]
[[ "$no_local_server_output" != *"Press Ctrl+C"* ]]
rm -f "$browser_capture"

rm -rf "$browser_stub_dir"

terminal_preview="$(NO_COLOR=1 "$MOMA_DIST" preview)"
[[ "$terminal_preview" == *"COMPONENT GALLERY"* ]]
[[ "$terminal_preview" == *"moma-header"* ]]
[[ "$terminal_preview" == *"moma-title"* ]]
[[ "$terminal_preview" == *"moma-select"* ]]
[[ "$terminal_preview" == *"moma-single-select-groups"* ]]
[[ "$terminal_preview" == *"moma-multi-select"* ]]
[[ "$terminal_preview" == *"moma-multi-select-groups"* ]]
[[ "$terminal_preview" == *"moma-label"* ]]
[[ "$terminal_preview" == *"┌─ TEXT HERE"* ]]
[[ "$terminal_preview" == *"▪  Continue with deployment? [yes]"* ]]
[[ "$terminal_preview" == *"moma-command-check"* ]]
[[ "$terminal_preview" == *"Browser docs"* ]]

colored_terminal_preview="$(env -u NO_COLOR "$MOMA_DIST" preview)"
preview_gray=$'\033[38;2;200;200;200m'
preview_pink=$'\033[38;2;255;144;231m'
preview_green=$'\033[32m'
preview_red=$'\033[31m'
preview_yellow=$'\033[33m'
preview_cyan=$'\033[36m'
preview_reset=$'\033[0m'
expected_legend="  Legend  ${preview_green}● success${preview_reset}"
expected_legend+="  ${preview_red}● error${preview_reset}"
expected_legend+="  ${preview_yellow}● warning${preview_reset}"
expected_legend+="  ${preview_cyan}● info${preview_reset}"
[[ "$colored_terminal_preview" == *"$expected_legend"* ]]
[[ "$colored_terminal_preview" == *"${preview_gray}▍"* ]]
[[ "$colored_terminal_preview" == *"▍ 01  Visual"* ]]
[[ "$colored_terminal_preview" == *"${preview_gray}┌─ moma-section"* ]]
[[ "$colored_terminal_preview" == *"${preview_pink}\$${preview_gray} moma section \"Dependencies ready\" --success"* ]]
[[ "$colored_terminal_preview" == *"${preview_pink}\$${preview_gray} moma select \"Development\" \"Staging\" \"Production\" --title \"Environment\""* ]]
[[ "$colored_terminal_preview" == *"└─ ${preview_gray}output${preview_reset}:"* ]]

markdown_preview="$(PATH=/usr/bin:/bin "$MOMA_DIST" preview md)"
[[ "$markdown_preview" == *"# Moma Documentation"* ]]
confirm_heading="### \`moma-confirm\`"
select_heading="### \`moma-select\`"
single_select_heading="### \`moma-single-select\`"
single_select_groups_heading="### \`moma-single-select-groups\`"
multi_select_heading="### \`moma-multi-select\`"
multi_select_groups_heading="### \`moma-multi-select-groups\`"
[[ "$markdown_preview" == *"$confirm_heading"* ]]
[[ "$markdown_preview" == *"$select_heading"* ]]
[[ "$markdown_preview" == *"$single_select_heading"* ]]
[[ "$markdown_preview" == *"$single_select_groups_heading"* ]]
[[ "$markdown_preview" == *"$multi_select_heading"* ]]
[[ "$markdown_preview" == *"$multi_select_groups_heading"* ]]
[[ "$markdown_preview" == *"moma preview web"* ]]

glow_preview="$(
  PATH="$fake_bin:/usr/bin:/bin" \
    MOMA_PREVIEW_WIDTH=76 "$MOMA_DIST" preview md
)"
[[ "$glow_preview" == *"glow arguments: -w 76 -"* ]]

# f2ab874 replaced the old hand-rolled static site (web/index.html +
# web/styles.css + web/app.js) with an Astro project rooted at web/src.
# Nothing in this suite (or in .github/workflows/release.yml) runs
# `npm run build`, so these checks validate the Astro *source* rather than
# a dist/ build artifact that may not even exist on disk.
web_src="$ROOT_DIR/web/src"

for web_source_file in \
  "$web_src/pages/index.astro" \
  "$web_src/layouts/BaseLayout.astro" \
  "$web_src/data/site.ts" \
  "$web_src/data/apiEntries.ts" \
  "$web_src/data/functionRows.ts" \
  "$web_src/components/Hero/Hero.data.ts" \
  "$web_src/components/DocsNav/DocsNav.data.ts" \
  "$web_src/components/DocsNav/DocsNav.client.ts" \
  "$web_src/components/Header/Header.astro" \
  "$web_src/components/TerminalWindow/TerminalWindow.astro" \
  "$web_src/styles/pages/index-screenshot.scss"; do
  [[ -s "$web_source_file" ]]
done

# The quick-start commands (raw-GitHub preview/load/install one-liners) live
# in Hero.data.ts, one group per rendered "quick-start" block.
hero_data="$web_src/components/Hero/Hero.data.ts"
rg -Fq 'bash <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma) preview' "$hero_data"
rg -Fq 'source <(curl -fsSL https://raw.githubusercontent.com/Mgldvd/moma/master/dist/moma)' "$hero_data"
rg -Fq 'moma msg "Ready" --success' "$hero_data"
[[ "$(rg -c "label: '" "$hero_data")" == "3" ]]
rg -Fq "label: 'Preview'" "$hero_data"
rg -Fq "label: 'Load'" "$hero_data"
rg -Fq "label: 'Install'" "$hero_data"

if rg -q 'Load from GitHub' "$web_src"; then
  printf 'smoke: obsolete "Load from GitHub" copy remains under web/src\n' >&2
  exit 1
fi

# The status badges ("Stable", "Interactive", "4 variants", ...) carried no
# information the surrounding content didn't already state and are retired.
if rg -q 'class="status' "$web_src"; then
  printf 'smoke: obsolete .status badge markup remains under web/src\n' >&2
  exit 1
fi

# The website's displayed version badge must match the library's actual
# version so the two never silently drift apart. Header.astro renders it
# from a `version` prop index.astro feeds from SITE.version.
site_version="$(rg -o "version: '([^']+)'" -r '$1' "$web_src/data/site.ts")"
[[ "$site_version" == "$("$MOMA_DIST" version)" ]]
rg -Fq 'data-moma-version={version}' "$web_src/components/Header/Header.astro"
rg -Fq 'v{version}' "$web_src/components/Header/Header.astro"

# Every API entry becomes one <ApiEntry> card (data-api attribute). Derive
# the count from the data file instead of hardcoding it, and make sure the
# page renders the *entire* array rather than a filtered subset.
api_entries_file="$web_src/data/apiEntries.ts"
mapfile -t api_entry_ids < <(rg -o "^    id: '([a-z0-9-]+)'" -r '$1' "$api_entries_file")
((${#api_entry_ids[@]} > 0))
api_entry_count="${#api_entry_ids[@]}"
unique_api_entry_count="$(printf '%s\n' "${api_entry_ids[@]}" | sort -u | wc -l | tr -d ' ')"
[[ "$unique_api_entry_count" == "$api_entry_count" ]]
# Every API entry renders in exactly one of the six ApiSections below,
# derived from its own `group` field (see apiEntries.ts) rather than a
# slice boundary - inserting, reordering, or regrouping an entry there is
# enough on its own to move it, with nothing here to keep in sync.
mapfile -t entry_groups < <(rg -o "^    group: '([a-z]+)'" -r '$1' "$api_entries_file")
[[ "${#entry_groups[@]}" == "$api_entry_count" ]]
for entry_group in "${entry_groups[@]}"; do
  case "$entry_group" in
    visual | interactive | selection | decorative | utils | self) ;;
    *)
      printf 'smoke: unknown API entry group: %s\n' "$entry_group" >&2
      exit 1
      ;;
  esac
done
for group_var in visualEntries interactiveEntries selectionEntries decorativeEntries utilsEntries selfEntries; do
  rg -Fq "${group_var}.map((entry) => <ApiEntry {...entry} />)" "$web_src/pages/index.astro"
done
for group_name in visual interactive selection decorative utils self; do
  rg -Fq "entry.group === \"$group_name\"" "$web_src/pages/index.astro"
done

# Output previews are real terminal screenshots (screenshots.ts, looked up
# by id from web/src/assets/screenshots/<id>.png) for every entry except
# moma-update (a real network install), moma-preview, and moma-help (whose
# real output runs taller than the screenshot tool's fixed capture canvas -
# see screenshots/README.md), which keep hand-authored TerminalWindow
# wireframe fallbacks instead.
rg -Fq "import.meta.glob" "$web_src/data/screenshots.ts"
rg -Fq "'../assets/screenshots/*.png'" "$web_src/data/screenshots.ts"
rg -Fq 'getScreenshot' "$web_src/components/ApiEntry/ApiEntry.astro"
rg -Fq 'from "../../data/screenshots"' "$web_src/components/ApiEntry/ApiEntry.astro"
rg -Fq 'import { Image } from "astro:assets"' "$web_src/components/ApiEntry/ApiEntry.astro"

screenshots_dir="$web_src/assets/screenshots"
[[ -d "$screenshots_dir" ]]
mapfile -t screenshot_ids < <(
  find "$screenshots_dir" -maxdepth 1 -name '*.png' -printf '%f\n' |
    sed 's/\.png$//' | sort
)
mapfile -t entries_without_wireframe_fallback < <(
  printf '%s\n' "${api_entry_ids[@]}" |
    grep -vE '^(moma-update|moma-preview|moma-help)$' | sort
)
if [[ "$(printf '%s\n' "${screenshot_ids[@]}")" != "$(printf '%s\n' "${entries_without_wireframe_fallback[@]}")" ]]; then
  printf 'smoke: web/src/assets/screenshots/*.png does not exactly match every API entry except moma-update/moma-preview/moma-help\n' >&2
  exit 1
fi

# moma-update, moma-preview, and moma-help are the only entries keeping a
# hand-authored wireframe.
wireframe_count="$(rg -c "^    wireframe: \{" "$api_entries_file")"
[[ "$wireframe_count" == "3" ]]
rg -Fq "id: 'moma-preview'" "$api_entries_file"
rg -Fq "id: 'moma-help'" "$api_entries_file"
rg -Fq "id: 'moma-update'" "$api_entries_file"

# Terminal-preview structure: one reusable component, used solely by
# moma-update's fallback, with obsolete per-system visual classes retired.
terminal_window_astro="$web_src/components/TerminalWindow/TerminalWindow.astro"
[[ "$(rg -Fc '<div class="terminal-window" role="group"' "$terminal_window_astro")" == "1" ]]
[[ "$(rg -Fc '<div class="terminal-window__chrome" aria-hidden="true">' "$terminal_window_astro")" == "1" ]]
[[ "$(rg -Fc 'class="terminal-window__body"' "$terminal_window_astro")" == "1" ]]

mapfile -t terminal_window_users < <(rg -l '<TerminalWindow' "$web_src")
[[ "${#terminal_window_users[@]}" == "1" ]]
[[ "${terminal_window_users[0]}" == *"/ApiEntry/ApiEntry.astro" ]]

# Every screenshot is wrapped in a clickable [data-lightbox-trigger], and
# exactly one shared Lightbox instance (used by index.astro) discovers all
# of them for keyboard/click arrow navigation.
lightbox_dir="$web_src/components/Lightbox"
for lightbox_file in \
  "$lightbox_dir/Lightbox.astro" \
  "$lightbox_dir/Lightbox.scss" \
  "$lightbox_dir/Lightbox.client.ts"; do
  [[ -s "$lightbox_file" ]]
done
rg -Fq 'data-lightbox-trigger' "$web_src/components/ApiEntry/ApiEntry.astro"
rg -Fq 'data-lightbox-caption={name}' "$web_src/components/ApiEntry/ApiEntry.astro"
mapfile -t lightbox_page_users < <(rg -l '<Lightbox' "$web_src/pages")
[[ "${#lightbox_page_users[@]}" == "1" ]]
rg -Fq "querySelectorAll<HTMLButtonElement>('[data-lightbox-trigger]')" "$lightbox_dir/Lightbox.client.ts"
rg -Fq "'ArrowLeft'" "$lightbox_dir/Lightbox.client.ts"
rg -Fq "'ArrowRight'" "$lightbox_dir/Lightbox.client.ts"
rg -Fq "'Escape'" "$lightbox_dir/Lightbox.client.ts"
# Wraps around at either end instead of dead-ending, and the modal traps
# focus (Tab) among just its own close/prev/next controls while open.
rg -Fq '(index + triggers.length) % triggers.length' "$lightbox_dir/Lightbox.client.ts"
rg -Fq "'Tab'" "$lightbox_dir/Lightbox.client.ts"
rg -Fq "setAttribute('aria-modal', 'true')" "$lightbox_dir/Lightbox.client.ts"

if rg -q 'class="(terminal-art|semantic-list|terminal-lines|dot-lines|select-list)' "$web_src"; then
  printf 'smoke: obsolete terminal preview classes remain under web/src\n' >&2
  exit 1
fi

# Decorative window controls must sit inside the aria-hidden chrome, so
# assistive tech never announces them.
chrome_open_line="$(rg -n 'class="terminal-window__chrome" aria-hidden="true">' "$terminal_window_astro" | cut -d: -f1)"
controls_line="$(rg -n 'class="terminal-window__controls">' "$terminal_window_astro" | cut -d: -f1)"
body_line="$(rg -n 'terminal-window__body' "$terminal_window_astro" | head -1 | cut -d: -f1)"
((controls_line > chrome_open_line))
((body_line > controls_line))
[[ "$(rg -c 'terminal-window__control--(success|warning|error)' "$terminal_window_astro")" == "3" ]]

# Sidebar links are entirely derived from API_ENTRIES and FUNCTION_ROWS
# (targetId: entry.id / row.id, not a hand-maintained id list - see
# DocsNav.data.ts's own header comment), so every entry automatically gets
# exactly one sidebar link with nothing here to keep in sync. There's no
# literal id left in that file to reverse-extract; confirm the derivation
# itself instead - that it covers every entry (targetId: entry.id/row.id)
# under exactly the six groups apiEntries.ts's entries can have.
docs_nav_data="$web_src/components/DocsNav/DocsNav.data.ts"
rg -Fq 'targetId: entry.id' "$docs_nav_data"
rg -Fq 'targetId: row.id' "$docs_nav_data"
rg -Fq "GROUP_ORDER: ApiEntryGroup[] = ['visual', 'interactive', 'selection', 'decorative', 'utils', 'self']" \
  "$docs_nav_data"

# Ids must be unique across the API entries, CLI function rows, and
# top-level sections they can target.
mapfile -t function_row_ids < <(rg -o "id: '([a-z0-9-]+)'" -r '$1' "$web_src/data/functionRows.ts")
mapfile -t section_ids < <(rg -o 'id="(colors|visual|interactive|selection|decorative|utils|self|cli)"' -r '$1' "$web_src/pages/index.astro")
mapfile -t all_page_ids < <(printf '%s\n' "${api_entry_ids[@]}" "${function_row_ids[@]}" "${section_ids[@]}")
unique_all_page_id_count="$(printf '%s\n' "${all_page_ids[@]}" | sort -u | wc -l | tr -d ' ')"
[[ "$unique_all_page_id_count" == "${#all_page_ids[@]}" ]]

# Mobile navigation trigger accessibility contract.
header_astro="$web_src/components/Header/Header.astro"
rg -Fq 'class="nav-toggle"' "$header_astro"
rg -Fq 'type="button"' "$header_astro"
rg -Fq 'aria-expanded="false"' "$header_astro"
rg -Fq 'aria-controls="docs-nav"' "$header_astro"
rg -Fq 'class="docs-nav"' "$web_src/components/DocsNav/DocsNav.astro"
rg -Fq 'id="docs-nav"' "$web_src/components/DocsNav/DocsNav.astro"

# Active-navigation implementation uses aria-current, driven by a scroll spy.
docs_nav_client="$web_src/components/DocsNav/DocsNav.client.ts"
rg -Fq "setAttribute('aria-current', 'location')" "$docs_nav_client"
rg -Fq 'IntersectionObserver' "$docs_nav_client"

# Filtering hides matching sidebar entries and empty groups, driven by the
# same entry-visibility event ApiEntry/ApiSection/EmptyState/DocsIndex use.
rg -Fq 'navGroupEls.forEach' "$docs_nav_client"
rg -Fq 'item.hidden = !visible' "$docs_nav_client"
events_file="$web_src/utils/events.ts"
rg -Fq "FILTER_EVENT = 'moma:filter'" "$events_file"
rg -Fq "ENTRY_VISIBILITY_EVENT = 'moma:entry-visibility'" "$events_file"
rg -Fq 'searchText.includes(query)' "$web_src/components/ApiEntry/ApiEntry.client.ts"

# Screenshot mode hides the sidebar, mobile trigger, and terminal chrome.
screenshot_styles="$web_src/styles/pages/index-screenshot.scss"
rg -Fq '.nav-toggle,' "$screenshot_styles"
rg -Fq '.docs-nav,' "$screenshot_styles"
rg -Fq '.terminal-window__chrome,' "$screenshot_styles"

# No external runtime dependency: only relative/bundled assets and
# well-known documentation asset URLs.
if rg -q '(href|src)="https?://' "$web_src"; then
  printf 'smoke: web/src references an external stylesheet, font, or script URL\n' >&2
  exit 1
fi

# Every component's compiled styles and client-side behavior must actually
# be wired into its markup, not left as an orphaned, unimported file.
mapfile -t client_scripts < <(find "$web_src/components" -name '*.client.ts')
for client_script in "${client_scripts[@]}"; do
  component_dir="$(dirname "$client_script")"
  component_name="$(basename "$client_script" .client.ts)"
  component_astro="$component_dir/$component_name.astro"
  rg -Fq "import \"./$component_name.client\"" "$component_astro"
done

mapfile -t component_styles < <(find "$web_src/components" -name '*.scss')
for component_style in "${component_styles[@]}"; do
  component_dir="$(dirname "$component_style")"
  component_name="$(basename "$component_style" .scss)"
  component_astro="$component_dir/$component_name.astro"
  rg -Fq "import \"./$component_name.scss\"" "$component_astro"
done

rg -Fq 'import "../styles/reset.scss"' "$web_src/layouts/BaseLayout.astro"
rg -Fq 'import "../styles/global.scss"' "$web_src/layouts/BaseLayout.astro"
rg -Fq 'import "../styles/pages/index.scss"' "$web_src/pages/index.astro"
rg -Fq 'import "../styles/pages/index-screenshot.scss"' "$web_src/pages/index.astro"

printf 'Smoke tests passed.\n'
