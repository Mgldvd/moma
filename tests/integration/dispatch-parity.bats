#!/usr/bin/env bats
#
# Registry-driven parity between the sourced `moma` shell function and the
# `./dist/moma` executable. Both invocation modes call the same explicit
# dispatcher (_moma_main), so their stdout, stderr, and exit status must be
# byte-for-byte identical for every registered command and for top-level
# help, version, theme, and preview routing.

load ../test_helper/common

setup_file() {
  build_moma
}

# Populate the global ARGS array with deterministic, non-interactive
# arguments for one registered command. Interactive controls use --choose
# or --answer so no test depends on a live TTY.
fixture_args_for() {
  local command="$1"
  case "$command" in
    header) ARGS=("Type Something") ;;
    title) ARGS=("Moma" "Installer") ;;
    title-sub) ARGS=("Deploy" "Production") ;;
    section) ARGS=("Dependencies ready" --success) ;;
    msg) ARGS=("Package installed" --success) ;;
    msg-simple) ARGS=("Package installed") ;;
    list) ARGS=("Clone repository" "Install dependencies") ;;
    box) ARGS=("Configuration is ready." --success) ;;
    prompt) ARGS=("Choose the target environment") ;;
    label) ARGS=("TEXT HERE") ;;
    input) ARGS=(--title "Project name" --value "demo") ;;
    select | single-select)
      ARGS=("Development" "Staging" "Production" --title Environment --choose 2)
      ;;
    single-select-groups)
      ARGS=(
        --title Features
        --group Docker --option Up --option Down --option Stop
        --group npm --option install --option "run dev" --option "run deploy"
        --choose 4
      )
      ;;
    multi-select) ARGS=("Docker" "CI" "Tests" --title Features --choose "1,3") ;;
    multi-select-groups)
      ARGS=(
        --title Features
        --group "North America" --option "United States" --option Canada
        --option Mexico
        --group "South America" --option Colombia --option Argentina
        --option Peru
        --choose "1,3"
      )
      ;;
    rabbit) ARGS=("Ready") ;;
    confirm) ARGS=("Continue?" --answer yes) ;;
    command-check) ARGS=(bash) ;;
    version) ARGS=() ;;
    *)
      printf 'fixture_args_for: no fixture for command: %s\n' "$command" >&2
      return 1
      ;;
  esac
}

# Compare stdout, stderr, and exit status between the installed executable
# and the sourced `moma` function for one invocation.
assert_dispatch_parity() {
  local exec_stdout exec_stderr exec_status=0
  local source_stdout source_stderr source_status=0

  exec_stdout="$(NO_COLOR=1 "$MOMA_DIST" "$@" 2>"$BATS_TEST_TMPDIR/exec.err")" ||
    exec_status=$?
  exec_stderr="$(<"$BATS_TEST_TMPDIR/exec.err")"

  source_stdout="$(
    NO_COLOR=1 bash -c '
      source "$1"
      shift
      moma "$@"
    ' _ "$MOMA_DIST" "$@" 2>"$BATS_TEST_TMPDIR/source.err"
  )" || source_status=$?
  source_stderr="$(<"$BATS_TEST_TMPDIR/source.err")"

  [[ "$exec_stdout" == "$source_stdout" ]]
  [[ "$exec_stderr" == "$source_stderr" ]]
  [[ "$exec_status" == "$source_status" ]]
}

@test "sourcing dist/moma defines moma as a shell function" {
  run bash -c 'source "$1"; declare -F moma >/dev/null' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
}

@test "moma is not automatically exported to child shells" {
  run bash -c '
        source "$1"
        bash -c "declare -F moma" >/dev/null 2>&1
    ' _ "$MOMA_DIST"
  [[ "$status" -ne 0 ]]
}

@test "repeated sourcing is silent and moma keeps working" {
  run bash -euo pipefail -c '
        source "$1"
        source "$1"
        [[ "$(declare -F moma | wc -l)" -eq 1 ]]
        NO_COLOR=1 moma msg-simple "still works"
    ' _ "$MOMA_DIST"
  [[ "$status" -eq 0 ]]
  [[ "$output" == "  ▪   still works" ]]
}

@test "moma dispatches every registered command identically to the executable" {
  local -a commands
  mapfile -t commands < <(
    bash -c 'source "$1"; _moma_command_registry' _ "$MOMA_DIST" | cut -f1
  )
  [[ "${#commands[@]}" -gt 0 ]]

  for command in "${commands[@]}"; do
    [[ "$command" == "update" ]] && continue

    if [[ "$command" == "spinner" ]]; then
      sleep 0.01 &
      exec_pid=$!
      exec_stdout="$(NO_COLOR=1 "$MOMA_DIST" spinner "$exec_pid" Done --delay 0.005)"
      sleep 0.01 &
      source_pid=$!
      source_stdout="$(
        NO_COLOR=1 bash -c '
          source "$1"
          moma spinner "$2" Done --delay 0.005
        ' _ "$MOMA_DIST" "$source_pid"
      )"
      [[ "$exec_stdout" == "$source_stdout" ]]
      continue
    fi

    ARGS=()
    fixture_args_for "$command"
    assert_dispatch_parity "$command" "${ARGS[@]}"
  done
}

@test "moma routes top-level help, version, and themes identically" {
  assert_dispatch_parity --help
  assert_dispatch_parity -h
  assert_dispatch_parity help
  assert_dispatch_parity version
  assert_dispatch_parity --version
  assert_dispatch_parity -v
  assert_dispatch_parity themes
}

@test "moma routes terminal and Markdown previews identically" {
  PATH=/usr/bin:/bin assert_dispatch_parity preview
  PATH=/usr/bin:/bin assert_dispatch_parity preview md
}

@test "unknown command handling is identical" {
  assert_dispatch_parity does-not-exist
}

@test "missing and malformed argument handling is identical" {
  assert_dispatch_parity single-select-groups --title Features --group Docker
  assert_dispatch_parity single-select-groups --title Features
  assert_dispatch_parity multi-select-groups --title Features \
    --group Docker --option Up --required --choose ""
  assert_dispatch_parity --version extra
}

@test "cancellation-equivalent negative results are identical" {
  assert_dispatch_parity confirm "Continue?" --answer no
}

@test "arguments preserve spaces, empty strings, and glob characters identically" {
  assert_dispatch_parity msg-simple ""
  assert_dispatch_parity msg-simple "  spaced value  "
  assert_dispatch_parity msg-simple "*.sh literal-not-expanded"
  assert_dispatch_parity list "" "second"
}

@test "arguments beginning with a dash and Unicode text are preserved identically" {
  assert_dispatch_parity msg-simple -- "--looks-like-an-option"
  assert_dispatch_parity msg-simple "héllo wörld — 日本語 🐇"
}

@test "single-select keeps controls on stderr and the value on stdout in both modes" {
  exec_stdout="$(
    NO_COLOR=1 "$MOMA_DIST" single-select Development Staging Production \
      --choose 2 2>/dev/null
  )"
  source_stdout="$(
    NO_COLOR=1 bash -c '
      source "$1"
      moma single-select Development Staging Production --choose 2
    ' _ "$MOMA_DIST" 2>/dev/null
  )"
  [[ "$exec_stdout" == "Staging" ]]
  [[ "$source_stdout" == "Staging" ]]

  exec_stderr="$(
    NO_COLOR=1 "$MOMA_DIST" single-select Development Staging Production \
      --choose 2 2>&1 >/dev/null
  )"
  source_stderr="$(
    NO_COLOR=1 bash -c '
      source "$1"
      moma single-select Development Staging Production --choose 2
    ' _ "$MOMA_DIST" 2>&1 >/dev/null
  )"
  [[ "$exec_stderr" == "$source_stderr" ]]
  [[ "$exec_stderr" == *"Enter select"* ]]
}

@test "grouped selection headings never appear on stdout in either mode" {
  exec_stdout="$(
    NO_COLOR=1 "$MOMA_DIST" single-select-groups --title Features \
      --group Docker --option Up --option Down --option Stop \
      --group npm --option install --option "run dev" --option "run deploy" \
      --choose 4 2>/dev/null
  )"
  source_stdout="$(
    NO_COLOR=1 bash -c '
      source "$1"
      moma single-select-groups --title Features \
        --group Docker --option Up --option Down --option Stop \
        --group npm --option install --option "run dev" --option "run deploy" \
        --choose 4
    ' _ "$MOMA_DIST" 2>/dev/null
  )"
  [[ "$exec_stdout" == "install" ]]
  [[ "$source_stdout" == "install" ]]
  [[ "$exec_stdout" != *"Docker"* ]]
  [[ "$source_stdout" != *"Docker"* ]]
}

@test "NO_COLOR=1 output is identical between moma and the executable" {
  NO_COLOR=1 assert_dispatch_parity msg "Ready" --success
  NO_COLOR=1 assert_dispatch_parity single-select \
    "Development" "Staging" "Production" --choose 2
}

@test "colored output (NO_COLOR unset) is identical between moma and the executable" {
  exec_out="$(env -u NO_COLOR "$MOMA_DIST" msg "Ready" --success)"
  # Positional parameters are intentionally expanded by the child Bash process.
  # shellcheck disable=SC2016
  source_out="$(
    env -u NO_COLOR bash -c '
      source "$1"
      moma msg "Ready" --success
    ' _ "$MOMA_DIST"
  )"
  [[ "$exec_out" == "$source_out" ]]
  [[ "$exec_out" == *$'\033[32m'* ]]
}

@test "configured theme output is identical between moma and the executable" {
  config="$MOMA_ROOT/tests/fixtures/themes.confg"
  exec_stdout="$(
    env -u NO_COLOR MOMA_CONFIG_FILE="$config" \
      "$MOMA_DIST" --theme night msg-simple "Themed"
  )"
  # Positional parameters are intentionally expanded by the child Bash process.
  # shellcheck disable=SC2016
  source_stdout="$(
    env -u NO_COLOR MOMA_CONFIG_FILE="$config" bash -c '
      source "$1"
      moma --theme night msg-simple "Themed"
    ' _ "$MOMA_DIST"
  )"
  [[ "$exec_stdout" == "$source_stdout" ]]
  [[ "$exec_stdout" == *$'\033[38;2;189;147;249m▪\033[0m'* ]]
}

@test "legacy moma-* functions remain callable and match canonical moma <command>" {
  local -a functions
  mapfile -t functions < <(
    bash -c 'source "$1"; _moma_command_registry' _ "$MOMA_DIST" | cut -f2
  )
  [[ "${#functions[@]}" -gt 0 ]]

  for function_name in "${functions[@]}"; do
    [[ "$function_name" == "moma-update" ]] && continue
    command_name="${function_name#moma-}"
    [[ "$command_name" == "spinner" ]] && continue

    ARGS=()
    fixture_args_for "$command_name"

    legacy_stdout="$(
      NO_COLOR=1 bash -c '
        source "$1"
        function_name="$2"
        shift 2
        "$function_name" "$@"
      ' _ "$MOMA_DIST" "$function_name" "${ARGS[@]}" 2>/dev/null
    )"
    canonical_stdout="$(
      NO_COLOR=1 bash -c '
        source "$1"
        command_name="$2"
        shift 2
        moma "$command_name" "$@"
      ' _ "$MOMA_DIST" "$command_name" "${ARGS[@]}" 2>/dev/null
    )"
    [[ "$legacy_stdout" == "$canonical_stdout" ]]
  done
}
