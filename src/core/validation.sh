# Pure validation helpers.
# Return success when the argument is an unsigned integer.
_moma_is_uint() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

# Return success when the argument is a positive integer.
_moma_is_positive_int() {
  _moma_is_uint "${1:-}" && (($1 > 0))
}

# Return success when a one-based index is within the supplied count.
_moma_is_index_in_range() {
  local candidate="${1:-}"
  local count="${2:-0}"
  _moma_is_positive_int "$candidate" &&
    _moma_is_positive_int "$count" &&
    ((candidate <= count))
}

# Return success when the argument is a non-negative numeric delay.
_moma_is_delay() {
  [[ "${1:-}" =~ ^[0-9]+([.][0-9]+)?$ ]]
}
