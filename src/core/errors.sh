# Error channels and public status-code conventions.
# Print a contextual error and return its requested status.
_moma_error() {
  local status="${1:-3}"
  local context="${2:-moma}"
  local message="${3:-unknown error}"

  printf '%s: %s\n' "$context" "$message" >&2
  return "$status"
}

# Print a command-usage error.
_moma_usage_error() {
  _moma_error 2 "$1" "$2"
}

# Print a command-runtime error.
_moma_runtime_error() {
  _moma_error 3 "$1" "$2"
}

# Report an unsupported command option.
_moma_unknown_option() {
  _moma_usage_error "$1" "unknown option: $2"
}

# Report a command option that is missing its value.
_moma_option_requires_value() {
  _moma_usage_error "$1" "option $2 requires a value"
}
