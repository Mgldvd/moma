# Hosted browser documentation preview.
# Resolve the default-browser launcher command for a `uname -s` platform
# name. Prints the launcher name on success; returns failure when the
# platform is not one of the operating systems Moma officially targets.
_moma_browser_launcher_for_platform() {
  case "$1" in
    Darwin) printf 'open' ;;
    Linux) printf 'xdg-open' ;;
    *) return 1 ;;
  esac
}

# Open a URL with the platform's default-browser launcher. The URL is
# passed as a single argument through an array so it is never re-split,
# re-expanded, or interpreted by a shell.
_moma_open_url() {
  local url="$1"
  local platform launcher status
  local -a launch_cmd

  platform="$(uname -s 2>/dev/null)"
  if ! launcher="$(_moma_browser_launcher_for_platform "$platform")"; then
    printf 'moma: unsupported platform for opening a browser: %s\n' \
      "${platform:-unknown}" >&2
    printf 'moma: open %s manually\n' "$url" >&2
    return 1
  fi

  if ! command -v "$launcher" &>/dev/null; then
    printf 'moma: %s is required to open %s\n' "$launcher" "$url" >&2
    return 127
  fi

  launch_cmd=("$launcher" "$url")
  "${launch_cmd[@]}" >/dev/null 2>&1
  status=$?
  if ((status != 0)); then
    printf 'moma: %s could not open %s\n' "$launcher" "$url" >&2
    return "$status"
  fi
}

# Open the hosted Moma documentation website in the default browser.
_moma_preview_web() {
  _moma_open_url 'https://mgldvd.github.io/moma/'
}
