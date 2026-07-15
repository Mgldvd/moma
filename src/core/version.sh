# Bash runtime compatibility.
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
