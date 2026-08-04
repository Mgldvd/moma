#!/usr/bin/env bats

load ../test_helper/common

setup_file() {
  build_moma
}

setup() {
  # The generated artifact path is provided by the shared Bats helper.
  # shellcheck disable=SC1090
  source "$MOMA_DIST"
}

@test "Bash 4.0 satisfies the minimum-version check" {
  run _moma_require_bash_version 4 0
  [[ "$status" -eq 0 ]]
}

@test "an unsupported requested Bash version returns a runtime error" {
  run _moma_require_bash_version 99 0
  [[ "$status" -eq 3 ]]
  [[ "$output" == *"Bash 99.0 or newer is required"* ]]
}

@test "semantic roles resolve to stable icons" {
  run _moma_semantic_icon success
  [[ "$status" -eq 0 ]]
  [[ "$output" == "✔" ]]
}

@test "theme parser loads custom ANSI colors and inherited roles" {
  config="$MOMA_ROOT/tests/fixtures/themes.confg"

  _MOMA_CONFIG_LOAD_ERROR=""
  _moma_load_config "$config"
  _moma_apply_theme night

  [[ "$MOMA_THEME" == "night" ]]
  [[ "$MOMA_COLOR_PRIMARY" == "violet" ]]
  [[ "$MOMA_COLOR_SUCCESS" == "green" ]]

  unset NO_COLOR
  run _moma_resolve_color violet
  [[ "$status" -eq 0 ]]
  [[ "$output" == '\033[38;2;189;147;249m' ]]
}

@test "integer and delay validation are pure" {
  _moma_is_positive_int 3
  run _moma_is_positive_int 0
  [[ "$status" -ne 0 ]]
  _moma_is_delay 0.05
  run _moma_is_delay fast
  [[ "$status" -ne 0 ]]
}

@test "decoration width resolves fixed and maximum values" {
  run _moma_resolve_decor_width 60 30 44 36 8
  [[ "$status" -eq 0 ]]
  [[ "$output" == "44" ]]

  run _moma_resolve_decor_width 60 30 "" 36 8
  [[ "$status" -eq 0 ]]
  [[ "$output" == "36" ]]
}

@test "plain text wraps at word boundaries" {
  run _moma_wrap_text "one two three" 7
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'one two\nthree' ]]
}

@test "select transition wraps without a terminal" {
  run _moma_select_transition 0 3 up
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'2\tcontinue' ]]
}

@test "multi-select transition toggles explicit state" {
  run _moma_multi_select_transition 1 "0,2" 3 space
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'1\t0,2,1\tcontinue' ]]
}

@test "select transition wraps across a flattened group boundary" {
  # Grouped components flatten every option into one selectable list before
  # calling this helper, so a six-option, two-group menu (three options per
  # group) wraps and crosses group boundaries using plain modular arithmetic.
  run _moma_select_transition 2 6 down
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'3\tcontinue' ]]

  run _moma_select_transition 0 6 up
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'5\tcontinue' ]]
}

@test "group validation rejects a group with no options" {
  run _moma_validate_groups moma-single-select-groups 2 0
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"moma-single-select-groups: every group requires at least one --option"* ]]
}

@test "group validation accepts every non-empty group" {
  run _moma_validate_groups moma-single-select-groups 3 2
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}

@test "confirm transition preserves no as an expected negative result" {
  run _moma_confirm_transition 0 n
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'1\tconfirm' ]]
}

@test "browser launcher resolves per officially targeted platform" {
  run _moma_browser_launcher_for_platform Darwin
  [[ "$status" -eq 0 ]]
  [[ "$output" == "open" ]]

  run _moma_browser_launcher_for_platform Linux
  [[ "$status" -eq 0 ]]
  [[ "$output" == "xdg-open" ]]
}

@test "browser launcher rejects an unsupported platform" {
  run _moma_browser_launcher_for_platform Plan9
  [[ "$status" -ne 0 ]]
  [[ -z "$output" ]]
}

@test "moma-version rejects unexpected arguments" {
  run moma-version extra
  [[ "$status" -eq 2 ]]
  [[ "$output" == "moma-version: unexpected argument: extra" ]]
}
