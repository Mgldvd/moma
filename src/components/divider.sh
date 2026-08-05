# Divider component.
# Render a marker-led horizontal rule from normalized arguments. Unlike
# moma-title-sub/moma-sub-title, the rule uses ⎼ instead of ─ and there is
# no box edge on the marker's left, only an optional bare ┌/└ pair framing
# the line above and below when --border draws one.
_moma_render_divider() {
  local color="${1:-$MOMA_COLOR_PRIMARY}"
  local no_color="${2:-false}"
  local width="${3:-}"
  local max_width="${4:-}"
  local min_width="${5:-35}"
  local icon="${6-▪}"
  local border="${7:-open}"

  if [[ ! "$min_width" =~ ^[0-9]+$ ]]; then
    min_width=35
  fi

  local resolved_color reset rule_width
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"
  rule_width="$(
    _moma_resolve_decor_width "0" "$min_width" "$width" "$max_width" 8
  )"

  # There's no left box edge to fall back to here, so a missing icon is
  # just blank filler, not a │.
  local left_glyph="${icon:- }"

  printf '%b\n' "$resolved_color"
  if [[ "$border" != open ]]; then
    printf '  ┌\n'
  fi
  printf '  %s %s\n' "$left_glyph" "$(_moma_repeat_char "⎼" "$rule_width")"
  if [[ "$border" != open ]]; then
    printf '  └\n'
  fi
  printf '%b\n' "$reset"
}

# Parse options and print a marker-led horizontal rule.
moma-divider() {
  local color="$MOMA_COLOR_PRIMARY"
  local no_color=false
  local width=""
  local max_width=""
  local min_width=35
  local icon="▪"
  local border="open"
  local -a positional=()
  local style

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --success | --error | --warning | --info)
        style="$(_moma_apply_semantic_style "${1#--}")"
        color="${style%%$'\t'*}"
        icon="${style#*$'\t'}"
        shift
        ;;
      --color | -c)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-divider "$1"
          return 1
        fi
        color="$2"
        shift 2
        ;;
      --color=*)
        color="${1#*=}"
        shift
        ;;
      --icon | -i)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-divider "$1"
          return 1
        fi
        icon="$2"
        shift 2
        ;;
      --icon=*)
        icon="${1#*=}"
        shift
        ;;
      --no-icon)
        icon=""
        shift
        ;;
      --border)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-divider "$1"
          return 1
        fi
        border="$2"
        shift 2
        ;;
      --border=*)
        border="${1#*=}"
        shift
        ;;
      --min-width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-divider "$1"
          return 1
        fi
        min_width="$2"
        shift 2
        ;;
      --min-width=*)
        min_width="${1#*=}"
        shift
        ;;
      --width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-divider "$1"
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
          _moma_option_requires_value moma-divider "$1"
          return 1
        fi
        max_width="$2"
        shift 2
        ;;
      --max-width=*)
        max_width="${1#*=}"
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-divider [--success|--error|--warning|--info] [--color <color>] [--icon <char>] [--no-icon] [--border mirror|line|open] [--min-width <n>] [--width <n>] [--max-width <n>] [--no-color]

Prints a single marker-led rule (⎼, not ─). --icon sets the left marker
(default ▪); --no-icon replaces it with blank filler. --border open
(default) prints just the rule; line and mirror both frame it with a
bare ┌ above and └ below.
EOF
        return 0
        ;;
      -*)
        _moma_unknown_option moma-divider "$1"
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  if ((${#positional[@]} > 0)); then
    printf 'moma-divider: unexpected argument: %s\n' "${positional[0]}" >&2
    return 1
  fi
  case "$border" in
    mirror | line | open) ;;
    *)
      _moma_usage_error moma-divider "invalid border: $border (expected mirror, line, or open)"
      return 2
      ;;
  esac
  if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
    _moma_usage_error moma-divider "invalid width: $width"
    return 2
  fi
  if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
    _moma_usage_error moma-divider "invalid max width: $max_width"
    return 2
  fi

  _moma_render_divider \
    "$color" "$no_color" "$width" "$max_width" "$min_width" "$icon" "$border"
}
