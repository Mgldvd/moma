# Resume component.
# Render a colored, titled block from normalized row arguments. Rows are
# either a term/description pair (aligned to the widest term in the block)
# or a plain text line; row order is preserved exactly as supplied.
#
# The title renders as a single open line by default. Setting an icon
# (--icon, --no-icon, or a semantic flag) switches to a boxed header
# instead: a full-width top border, a marker + title line, and a blank
# separator row before the content rows - mirroring moma-title's own
# marker conventions so the two components read consistently.
_moma_render_resume() {
  local title="$1"
  local color="${2:-$MOMA_COLOR_PRIMARY}"
  local no_color="${3:-false}"
  local row_count="$4"
  shift 4
  local -a row_kinds=("${@:1:$row_count}")
  shift "$row_count"
  local -a row_terms=("${@:1:$row_count}")
  shift "$row_count"
  local -a row_values=("${@:1:$row_count}")
  shift "$row_count"
  local icon="$1"
  local header="${2:-false}"
  local border="${3:-mirror}"
  local width="${4:-}"
  local max_width="${5:-}"

  local resolved_color reset bold muted
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"
  bold="" muted=""
  if _moma_color_enabled "$no_color"; then
    bold="$MOMA_STYLE_WHITE_BOLD"
    muted="$MOMA_COLOR_MUTED"
  fi

  local term_width=0 i
  for ((i = 0; i < row_count; i++)); do
    if [[ "${row_kinds[i]}" == item ]] &&
      ((${#row_terms[i]} > term_width)); then
      term_width="${#row_terms[i]}"
    fi
  done

  if [[ "$header" == true ]]; then
    local left_glyph="${icon:-│}"
    local box_width
    box_width="$(
      _moma_resolve_decor_width \
        "$((${#title} + 6))" 35 "$width" "$max_width" 8
    )"
    printf '  %b┌%s┐%b\n' \
      "$resolved_color" "$(_moma_repeat_char "─" "$box_width")" "$reset"
    printf '  %b%s%b  %b%s%b\n' \
      "$resolved_color" "$left_glyph" "$reset" "$bold" "$title" "$reset"
    printf '  %b│%b \n' "$resolved_color" "$reset"
  else
    printf '  %b┌─%b %b%s%b\n' \
      "$resolved_color" "$reset" "$bold" "$title" "$reset"
  fi

  local gap
  for ((i = 0; i < row_count; i++)); do
    printf '  %b│%b  ' "$resolved_color" "$reset"
    if [[ "${row_kinds[i]}" == item ]]; then
      gap=$((term_width - ${#row_terms[i]} + 2))
      printf '%b%s%b%s%b%s%b\n' \
        "$bold" "${row_terms[i]}" "$reset" \
        "$(_moma_repeat_char " " "$gap")" \
        "$muted" "${row_values[i]}" "$reset"
    else
      printf '%s\n' "${row_values[i]}"
    fi
  done

  if [[ "$border" == open ]]; then
    printf '\n'
  else
    printf '  %b└%b\n\n' "$resolved_color" "$reset"
  fi
}

# Parse resume options and print a titled, colored block. Content rows come
# from repeated --item (a bold term next to a muted description, aligned as
# a column) and --text (a plain line) flags, interleaved in the order given.
moma-resume() {
  local title=""
  local color="$MOMA_COLOR_PRIMARY"
  local no_color=false
  local -a row_kinds=()
  local -a row_terms=()
  local -a row_values=()
  local icon=""
  local header=false
  local border="mirror"
  local width=""
  local max_width=""
  local style

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-resume "$1"
          return 1
        fi
        title="$2"
        shift 2
        ;;
      --title=*)
        title="${1#*=}"
        shift
        ;;
      --color | -c)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-resume "$1"
          return 1
        fi
        color="$2"
        shift 2
        ;;
      --color=*)
        color="${1#*=}"
        shift
        ;;
      --success | --error | --warning | --info)
        style="$(_moma_apply_semantic_style "${1#--}")"
        color="${style%%$'\t'*}"
        icon="${style#*$'\t'}"
        header=true
        shift
        ;;
      --icon | -i)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-resume "$1"
          return 1
        fi
        icon="$2"
        header=true
        shift 2
        ;;
      --icon=*)
        icon="${1#*=}"
        header=true
        shift
        ;;
      --no-icon)
        icon=""
        header=true
        shift
        ;;
      --border)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-resume "$1"
          return 1
        fi
        border="$2"
        shift 2
        ;;
      --border=*)
        border="${1#*=}"
        shift
        ;;
      --width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-resume "$1"
          return 1
        fi
        width="$2"
        shift 2
        ;;
      --width=*)
        width="${1#*=}"
        shift
        ;;
      --max-width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-resume "$1"
          return 1
        fi
        max_width="$2"
        shift 2
        ;;
      --max-width=*)
        max_width="${1#*=}"
        shift
        ;;
      --item)
        if [[ $# -lt 3 ]]; then
          printf 'moma-resume: option %s requires a term and a description\n' \
            "$1" >&2
          return 1
        fi
        row_kinds+=(item)
        row_terms+=("$2")
        row_values+=("$3")
        shift 3
        ;;
      --text)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-resume "$1"
          return 1
        fi
        row_kinds+=(text)
        row_terms+=("")
        row_values+=("$2")
        shift 2
        ;;
      --text=*)
        row_kinds+=(text)
        row_terms+=("")
        row_values+=("${1#*=}")
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-resume --title "<text>" [--item "<term>" "<description>"]... [--text "<line>"]... [--success|--error|--warning|--info] [--color <color>] [--icon <char>] [--no-icon] [--border mirror|line|open] [--width <n>] [--max-width <n>] [--no-color]

Rows print in the order their --item and --text flags are given. Every
--item term is aligned to the widest term in the block; --text lines print
as-is with no term column. One blank line follows the block.

The title is a single open line by default. --icon, --no-icon, and the
semantic flags switch to a boxed header instead: a full-width top border,
a marker + title line, and a blank separator row before the content rows.
--border controls the closing edge: mirror and line (default: mirror)
close with └, open leaves the block unclosed.
EOF
        return 0
        ;;
      -*)
        _moma_unknown_option moma-resume "$1"
        return 1
        ;;
      *)
        printf 'moma-resume: unexpected argument: %s\n' "$1" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$title" ]]; then
    _moma_usage_error moma-resume "--title is required"
    return 2
  fi
  case "$border" in
    mirror | line | open) ;;
    *)
      _moma_usage_error moma-resume "invalid border: $border (expected mirror, line, or open)"
      return 2
      ;;
  esac
  if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
    _moma_usage_error moma-resume "invalid width: $width"
    return 2
  fi
  if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
    _moma_usage_error moma-resume "invalid max width: $max_width"
    return 2
  fi

  _moma_render_resume \
    "$title" "$color" "$no_color" "${#row_kinds[@]}" \
    "${row_kinds[@]}" "${row_terms[@]}" "${row_values[@]}" \
    "$icon" "$header" "$border" "$width" "$max_width"
}
