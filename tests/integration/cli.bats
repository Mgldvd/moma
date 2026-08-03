#!/usr/bin/env bats

load ../test_helper/common

setup_file() {
  build_moma
}

@test "CLI and public function produce equivalent message output" {
  # Positional parameters are intentionally expanded by the child Bash process.
  # shellcheck disable=SC2016
  run env NO_COLOR=1 bash -c '
        cli="$($1 msg "Ready" --success)"
        source "$1"
        library="$(moma-msg "Ready" --success)"
        [[ "$cli" == "$library" ]]
    ' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
}

@test "interactive automation keeps controls on stderr and data on stdout" {
  stdout_file="$BATS_TEST_TMPDIR/stdout"
  stderr_file="$BATS_TEST_TMPDIR/stderr"

  NO_COLOR=1 "$MOMA_DIST" select Development Staging --choose 2 \
    >"$stdout_file" 2>"$stderr_file"

  [[ "$(<"$stdout_file")" == "Staging" ]]
  [[ "$(<"$stderr_file")" == *"Enter select"* ]]
}

@test "select remains a compatibility alias for single-select" {
  alias_stdout="$BATS_TEST_TMPDIR/alias-stdout"
  canonical_stdout="$BATS_TEST_TMPDIR/canonical-stdout"

  NO_COLOR=1 "$MOMA_DIST" select Up Down Stop --choose 2 \
    >"$alias_stdout" 2>/dev/null
  NO_COLOR=1 "$MOMA_DIST" single-select Up Down Stop --choose 2 \
    >"$canonical_stdout" 2>/dev/null

  [[ "$(<"$alias_stdout")" == "$(<"$canonical_stdout")" ]]
}

@test "single-select-groups keeps controls on stderr and the value on stdout" {
  stdout_file="$BATS_TEST_TMPDIR/stdout"
  stderr_file="$BATS_TEST_TMPDIR/stderr"

  NO_COLOR=1 "$MOMA_DIST" single-select-groups \
    --title Features \
    --group Docker --option Up --option Down --option Stop \
    --group npm --option install --option "run dev" --option "run deploy" \
    --choose 4 \
    >"$stdout_file" 2>"$stderr_file"

  [[ "$(<"$stdout_file")" == "install" ]]
  [[ "$(<"$stderr_file")" == *"Enter select"* ]]
}

@test "multi-select-groups returns values in visual order and dedups indexes" {
  stdout_file="$BATS_TEST_TMPDIR/stdout"

  NO_COLOR=1 "$MOMA_DIST" multi-select-groups \
    --title Features \
    --group "North America" --option "United States" --option Canada \
    --option Mexico \
    --group "South America" --option Colombia --option Argentina \
    --option Peru \
    --choose 3,1,3 \
    >"$stdout_file" 2>/dev/null

  [[ "$(<"$stdout_file")" == $'United States\nMexico' ]]
}

@test "grouped selection arguments are validated with component-prefixed errors" {
  run env NO_COLOR=1 "$MOMA_DIST" single-select-groups --title Features \
    --option Up
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"moma-single-select-groups:"* ]]

  run env NO_COLOR=1 "$MOMA_DIST" multi-select-groups --title Features \
    --group Docker
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"moma-multi-select-groups: every group requires at least one --option"* ]]
}

@test "unknown CLI commands retain status 1" {
  run "$MOMA_DIST" does-not-exist
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"unknown command"* ]]
}

@test "configured themes are listed and selected globally" {
  config="$MOMA_ROOT/tests/fixtures/themes.confg"

  run env MOMA_CONFIG_FILE="$config" "$MOMA_DIST" themes
  [[ "$status" -eq 0 ]]
  [[ "$output" == $'default (active)\nnight' ]]

  run env -u NO_COLOR MOMA_CONFIG_FILE="$config" \
    "$MOMA_DIST" --theme night msg-simple Ready
  [[ "$status" -eq 0 ]]
  [[ "$output" == *$'\033[38;2;189;147;249m▪\033[0m'* ]]
}

@test "MOMA_THEME applies a configured theme at source time" {
  config="$MOMA_ROOT/tests/fixtures/themes.confg"

  # Positional parameters are expanded by the child Bash process.
  # shellcheck disable=SC2016
  run env -u NO_COLOR MOMA_CONFIG_FILE="$config" MOMA_THEME=night \
    bash -c 'source "$1"; moma-msg-simple Ready' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *$'\033[38;2;189;147;249m▪\033[0m'* ]]
}

@test "invalid theme configuration fails CLI commands" {
  config="$MOMA_ROOT/tests/fixtures/invalid-themes.confg"

  run env MOMA_CONFIG_FILE="$config" "$MOMA_DIST" msg Ready
  [[ "$status" -eq 3 ]]
  [[ "$output" == *"missing required [theme default] section"* ]]
}
