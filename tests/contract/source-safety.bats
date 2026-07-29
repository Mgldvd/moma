#!/usr/bin/env bats

load ../test_helper/common

setup_file() {
    build_moma
}

@test "sourcing is silent and preserves caller shell state" {
    run bash -euo pipefail -c '
        before_pwd="$PWD"
        before_ifs="$(printf %q "$IFS")"
        before_options="$(set +o)"
        before_shopt="$(shopt -p)"
        trap ": consumer-int" INT
        before_int="$(trap -p INT)"
        capture="$(mktemp)"

        source "$1" >"$capture" 2>&1

        [[ ! -s "$capture" ]]
        [[ "$PWD" == "$before_pwd" ]]
        [[ "$(printf %q "$IFS")" == "$before_ifs" ]]
        [[ "$(set +o)" == "$before_options" ]]
        [[ "$(shopt -p)" == "$before_shopt" ]]
        [[ "$(trap -p INT)" == "$before_int" ]]
        rm -f "$capture"
    ' _ "$MOMA_DIST"

    [[ "$status" -eq 0 ]]
}

@test "sourcing does not execute the CLI" {
    run bash -c 'source "$1"' _ "$MOMA_DIST"
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

@test "registry and public API contain the same component functions" {
    run bash -c '
        source "$1"
        registry="$(_moma_command_registry | cut -f2 | LC_ALL=C sort)"
        public="$(compgen -A function | rg "^moma-" | LC_ALL=C sort)"
        [[ "$registry" == "$public" ]]
    ' _ "$MOMA_DIST"
    [[ "$status" -eq 0 ]]
}

@test "spinner leaves a consumer trap unchanged" {
    run bash -c '
        source "$1"
        trap ": consumer-int" INT
        before="$(trap -p INT)"
        sleep 0.01 &
        NO_COLOR=1 moma-spinner "$!" Done --delay 0.005 >/dev/null
        [[ "$(trap -p INT)" == "$before" ]]
    ' _ "$MOMA_DIST"
    [[ "$status" -eq 0 ]]
}
