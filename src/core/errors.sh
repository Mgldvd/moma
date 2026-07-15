# Error channels and public status-code conventions.
_moma_error() {
    local status="${1:-3}"
    local context="${2:-moma}"
    local message="${3:-unknown error}"

    printf '%s: %s\n' "$context" "$message" >&2
    return "$status"
}

_moma_usage_error() {
    _moma_error 2 "$1" "$2"
}

_moma_runtime_error() {
    _moma_error 3 "$1" "$2"
}

_moma_unknown_option() {
    _moma_usage_error "$1" "unknown option: $2"
}

_moma_option_requires_value() {
    _moma_usage_error "$1" "option $2 requires a value"
}
