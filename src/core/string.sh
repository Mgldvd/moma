# String helpers.
# Remove leading and trailing ASCII whitespace from a string.
_moma_trim() {
  local value="${1:-}"
  value="${value#"${value%%[!$' \t\r\n']*}"}"
  value="${value%"${value##*[!$' \t\r\n']}"}"
  printf '%s' "$value"
}

# Print a character a requested number of times.
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

# Count display columns in a string, independent of the caller's locale.
# `${#value}` counts *bytes* under a non-UTF-8 locale (this library's own
# usual environment, since it never sets one itself) - that overcounts
# every multi-byte glyph moma prints (✔, →, ▪, …, box-drawing corners, ...)
# by however many continuation bytes it has, throwing off any width math
# that includes one. Every glyph moma uses is single-column (see
# screenshots/README.md), so counting UTF-8 lead bytes - forcing the C
# locale locally so the byte-wise slice below is deterministic regardless
# of the caller's locale - gives the right answer everywhere.
_moma_display_width() {
  local value="${1:-}"
  (
    LC_ALL=C
    local byte_len="${#value}"
    local width=0 i byte ord
    for ((i = 0; i < byte_len; i++)); do
      byte="${value:i:1}"
      printf -v ord '%d' "'$byte"
      (((ord & 0xC0) == 0x80)) || width=$((width + 1))
    done
    printf '%s' "$width"
  )
}

# Resolve the inner width used by terminal decorations. A component-specific
# fixed width wins over the library-wide fixed width. Fixed widths win over
# maximum widths so callers can override a global cap for one component.
# Resolve fixed, maximum, natural, and minimum decoration widths.
_moma_resolve_decor_width() {
  local natural_width="${1:-0}"
  local default_min_width="${2:-0}"
  local fixed_width="${3:-}"
  local max_width="${4:-}"
  local hard_min_width="${5:-1}"

  _moma_is_uint "$natural_width" || natural_width=0
  _moma_is_uint "$default_min_width" || default_min_width=0
  _moma_is_positive_int "$hard_min_width" || hard_min_width=1

  if [[ -z "$fixed_width" ]]; then
    fixed_width="${MOMA_WIDTH:-}"
  fi
  if [[ -z "$max_width" ]]; then
    max_width="${MOMA_MAX_WIDTH:-}"
  fi

  local resolved_width="$natural_width"
  if ((resolved_width < default_min_width)); then
    resolved_width="$default_min_width"
  fi

  if _moma_is_positive_int "$fixed_width"; then
    resolved_width="$fixed_width"
  elif _moma_is_positive_int "$max_width" &&
    ((resolved_width > max_width)); then
    resolved_width="$max_width"
  fi

  if ((resolved_width < hard_min_width)); then
    resolved_width="$hard_min_width"
  fi
  printf '%s' "$resolved_width"
}

# Truncate text to a width and append an ellipsis when needed.
_moma_truncate_text() {
  local value="${1:-}"
  local max_width="${2:-0}"

  _moma_is_uint "$max_width" || max_width=0
  if ((${#value} <= max_width)); then
    printf '%s' "$value"
  elif ((max_width == 1)); then
    printf '…'
  elif ((max_width > 1)); then
    printf '%s…' "${value:0:max_width-1}"
  fi
}

# Wrap plain text without external commands. It prefers word boundaries and
# hard-wraps a single word only when that word is wider than the available row.
# Wrap text to a requested width while preserving every word.
_moma_wrap_text() {
  local value="${1:-}"
  local max_width="${2:-0}"

  if ! _moma_is_positive_int "$max_width"; then
    printf '%s\n' "$value"
    return 0
  fi

  local remaining="$value"
  local candidate cut line
  while ((${#remaining} > max_width)); do
    candidate="${remaining:0:max_width}"
    cut="$max_width"
    if [[ "${remaining:max_width:1}" != " " ]]; then
      while ((cut > 0)) && [[ "${candidate:cut-1:1}" != " " ]]; do
        cut=$((cut - 1))
      done
      if ((cut == 0)); then
        cut="$max_width"
      fi
    fi

    line="${remaining:0:cut}"
    line="${line%"${line##*[!$' \t']}"}"
    printf '%s\n' "$line"
    remaining="${remaining:cut}"
    remaining="${remaining#"${remaining%%[!$' \t']*}"}"
  done
  printf '%s\n' "$remaining"
}
