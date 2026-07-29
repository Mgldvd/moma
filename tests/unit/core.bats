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

@test "confirm transition preserves no as an expected negative result" {
  run _moma_confirm_transition 0 n
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'1\tconfirm' ]]
}
