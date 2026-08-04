# Bash runtime compatibility.
MOMA_VERSION="1.2.1"
MOMA_UPDATE_URL="${MOMA_UPDATE_URL:-https://github.com/Mgldvd/moma/releases/latest/download/moma}"

# Verify that the running Bash version meets a requested minimum.
_moma_require_bash_version() {
  local required_major="${1:-4}"
  local required_minor="${2:-0}"
  local current_major="${BASH_VERSINFO[0]:-0}"
  local current_minor="${BASH_VERSINFO[1]:-0}"

  if ((current_major > required_major)) ||
    ((current_major == required_major && current_minor >= required_minor)); then
    return 0
  fi

  printf 'moma: Bash %s.%s or newer is required; found %s.%s\n' \
    "$required_major" "$required_minor" "$current_major" "$current_minor" >&2
  return 3
}

if ! _moma_require_bash_version 4 0; then
  # `return` handles source; the fallback `exit` handles direct execution.
  # shellcheck disable=SC2317
  return 3 2>/dev/null || exit 3
fi

# Print the installed Moma version. This is the single canonical source for
# the `version` command and the top-level `--version`/`-v` flags.
moma-version() {
  if [[ $# -gt 0 ]]; then
    _moma_usage_error moma-version "unexpected argument: $1"
    return 2
  fi
  printf '%s\n' "$MOMA_VERSION"
}

# Download and atomically replace an executable Moma installation.
moma-update() {
  local target_path target_dir temporary_path

  if [[ $# -gt 0 ]]; then
    _moma_usage_error moma-update "unexpected argument: $1"
    return 2
  fi
  if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    _moma_runtime_error moma-update "update requires an executable installation"
    return 3
  fi
  if ! command -v curl &>/dev/null; then
    _moma_runtime_error moma-update "curl is required to download updates"
    return 3
  fi

  target_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  target_dir="$(dirname "$target_path")"
  if [[ ! -w "$target_path" || ! -w "$target_dir" ]]; then
    _moma_runtime_error moma-update "installation is not writable: $target_path"
    return 3
  fi

  if ! temporary_path="$(mktemp "$target_dir/.moma.update.XXXXXX")"; then
    _moma_runtime_error moma-update "could not create update file"
    return 3
  fi
  if ! curl -fsSL "$MOMA_UPDATE_URL" -o "$temporary_path"; then
    rm -f "$temporary_path"
    _moma_runtime_error moma-update "could not download update"
    return 3
  fi
  if ! bash -n "$temporary_path"; then
    rm -f "$temporary_path"
    _moma_runtime_error moma-update "downloaded update is not valid Bash"
    return 3
  fi
  if ! chmod 0755 "$temporary_path" || ! mv "$temporary_path" "$target_path"; then
    rm -f "$temporary_path"
    _moma_runtime_error moma-update "could not replace installation"
    return 3
  fi

  printf 'moma: updated successfully\n'
}
