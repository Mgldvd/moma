# String helpers.
_moma_trim() {
    local value="${1:-}"
    value="${value#"${value%%[!$' \t\r\n']*}"}"
    value="${value%"${value##*[!$' \t\r\n']}"}"
    printf '%s' "$value"
}

_moma_repeat_char() {
    local char="${1:-}"
    local count="${2:-0}"

    if [[ -z "$char" || ! "$count" =~ ^[0-9]+$ || "$count" -le 0 ]]; then
        return 0
    fi

    local output
    printf -v output '%*s' "$count" ''
    printf '%s' "${output// /$char}"
}
