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
    [ "$status" -eq 0 ]
}

@test "interactive automation keeps controls on stderr and data on stdout" {
    stdout_file="$BATS_TEST_TMPDIR/stdout"
    stderr_file="$BATS_TEST_TMPDIR/stderr"

    NO_COLOR=1 "$MOMA_DIST" select Development Staging --choose 2 \
        >"$stdout_file" 2>"$stderr_file"

    [ "$(<"$stdout_file")" = "Staging" ]
    [[ "$(<"$stderr_file")" == *"Enter select"* ]]
}

@test "unknown CLI commands retain status 1" {
    run "$MOMA_DIST" does-not-exist
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown command"* ]]
}
