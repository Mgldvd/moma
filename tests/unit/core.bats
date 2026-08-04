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

@test "terminal height honors a LINES override before falling back" {
  # Positional parameters are intentionally expanded by the child Bash process.
  # shellcheck disable=SC2016
  run env LINES=15 bash -c 'source "$1"; _moma_term_height' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "15" ]]

  # A tput that reports nothing exercises the fallback; tput itself is
  # shadowed with a function since command -v already treats a real tput
  # binary on PATH as available.
  # shellcheck disable=SC2016
  run env -u LINES bash -c '
        tput() { return 1; }
        source "$1"
        _moma_term_height 40
    ' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "40" ]]
}

@test "select window shows every row when the full list already fits" {
  run _moma_select_window 0 5 5
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'0\t5' ]]

  run _moma_select_window 3 5 10
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'0\t5' ]]

  run _moma_select_window 0 5 0
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'0\t5' ]]
}

@test "select window scrolls to keep the active row visible" {
  # Top of the list: the window starts at 0 without scrolling past it.
  run _moma_select_window 0 20 5
  [[ "$output" == $'0\t5' ]]
  run _moma_select_window 4 20 5
  [[ "$output" == $'0\t5' ]]

  # Middle of the list: the window trails the active row by max_visible - 1.
  run _moma_select_window 10 20 5
  [[ "$output" == $'6\t5' ]]

  # Bottom of the list: the window clamps so it never scrolls past the end.
  run _moma_select_window 19 20 5
  [[ "$output" == $'15\t5' ]]
}

@test "multi-select render windows a list taller than the terminal" {
  # 15 options, active_index 10 (Lambda): max_visible is LINES(10) - 4 = 6,
  # so the window scrolls to [5..10] (Zeta..Lambda), 5 rows hidden above and
  # 4 hidden below.
  # shellcheck disable=SC2016
  run env LINES=10 NO_COLOR=1 bash -c '
        source "$1"
        _moma_render_multi_select \
          "Options" 10 "" "" false false true \
          Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa \
          Lambda Mu Nu Xi Omicron
    ' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
  # 2 header lines + 1 scroll indicator + 6 option rows + 1 footer.
  [[ "$(printf '%s\n' "$output" | wc -l)" -eq 10 ]]
  [[ "$output" == *"5 more above"* ]]
  [[ "$output" == *"4 more below"* ]]
  [[ "$output" == *"› □ Lambda"* ]]
  [[ "$output" != *"Alpha"* ]]
  [[ "$output" != *"Omicron"* ]]
}

@test "multi-select render stays unwindowed for non-interactive callers" {
  # windowed=false (the --choose path) always renders the complete list,
  # even on a terminal too short to show it without scrolling, so scripted
  # and documented output stays deterministic.
  # shellcheck disable=SC2016
  run env LINES=10 NO_COLOR=1 bash -c '
        source "$1"
        _moma_render_multi_select \
          "Options" 0 "" "" false false false \
          Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa \
          Lambda Mu Nu Xi Omicron
    ' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
  [[ "$output" != *"more above"* ]]
  [[ "$output" != *"more below"* ]]
  [[ "$output" == *"Alpha"* ]]
  [[ "$output" == *"Omicron"* ]]
}

@test "multi-select-groups render switches to a compact window when the full layout would not fit" {
  # 3 groups (3/5/4 options: row_count 16, full_lines 26), active_row 8
  # (Peru). LINES(10) is reserved down by 1 row of prompt headroom first
  # (term_height 9), so content_budget is 9 - 3 = 6; row_count + the
  # constant full_blank_count (4) is 20, over budget, so rows_budget is
  # 6 - 1 (for the indicator) = 5. The row-count-only window [4..9) would
  # cost 5 rows + 1 blank (the SouthAmerica boundary) = 6, over
  # rows_budget, so it shrinks by that 1 to [5..9) (the SouthAmerica All
  # row..Peru): 4 rows + 1 blank fits exactly in 5, with no padding needed.
  # This also proves the two-pass budget correction (blank separators can
  # push a window over budget) works.
  # shellcheck disable=SC2016
  visual="$(
    env LINES=10 NO_COLOR=1 bash -c '
        source "$1"
        _moma_render_multi_select_groups \
          "Options" 8 "" "" false false true 3 \
          NorthAmerica SouthAmerica Europe \
          3 5 4 \
          UnitedStates Canada Mexico \
          Colombia Argentina Peru Chile Brazil \
          Spain France Germany Italy
    ' _ "$MOMA_DIST" 2>&1
  )"
  # 2 header lines + 1 scroll indicator + 4 rows + 1 blank separator + 1 footer.
  [[ "$(printf '%s\n' "$visual" | wc -l)" -eq 9 ]]
  [[ "$visual" == *"5 more above"* ]]
  [[ "$visual" == *"7 more below"* ]]
  [[ "$visual" == *"All · SouthAmerica"* ]]
  [[ "$visual" == *"› □ Peru"* ]]
  [[ "$visual" != *"Select All"* ]]
  [[ "$visual" != *"UnitedStates"* ]]
  [[ "$visual" != *"Mexico"* ]]
  [[ "$visual" != *"NorthAmerica"* ]]
  [[ "$visual" != *"Spain"* ]]
}

@test "multi-select-groups render stays unwindowed for non-interactive callers" {
  # windowed=false (the --choose path) keeps the full layout, headings and
  # all, even on a terminal too short to show it without scrolling.
  # shellcheck disable=SC2016
  run env LINES=10 NO_COLOR=1 bash -c '
        source "$1"
        _moma_render_multi_select_groups \
          "Options" 0 "" "" false false false 3 \
          NorthAmerica SouthAmerica Europe \
          3 5 4 \
          UnitedStates Canada Mexico \
          Colombia Argentina Peru Chile Brazil \
          Spain France Germany Italy
    ' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
  [[ "$output" != *"more above"* ]]
  [[ "$output" != *"more below"* ]]
  [[ "$output" == *"Select All"* ]]
  [[ "$output" == *"NorthAmerica"* ]]
  [[ "$output" == *"Spain"* ]]
}
