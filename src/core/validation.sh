# Pure validation helpers.
_moma_is_uint() {
    [[ "${1:-}" =~ ^[0-9]+$ ]]
}

_moma_is_positive_int() {
    _moma_is_uint "${1:-}" && (($1 > 0))
}

_moma_is_index_in_range() {
    local candidate="${1:-}"
    local count="${2:-0}"
    _moma_is_positive_int "$candidate" && _moma_is_positive_int "$count" && ((candidate <= count))
}

_moma_is_delay() {
    [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]
}
