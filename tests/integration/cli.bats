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
