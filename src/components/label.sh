# Label component.
# Render a decorated label from normalized arguments.
_moma_render_label() {
  local text="$1"
  local width="${2:-}"
  local color="${3:-$MOMA_COLOR_PRIMARY}"
  local icon="${4:-}"
  local no_color="${5:-false}"
  local max_width="${6:-}"
  local min_width="${7:-35}"
  local edge="${8:-top}"
  local border="${9:-line}"

  # Measured separately from the text (never merged into the same string
  # before it's truncated) so a multi-byte icon like ✔ never throws off
  # the width math - see _moma_display_width.
  local icon_prefix="" icon_width=0
  if [[ -n "$icon" ]]; then
    if [[ -n "$text" ]]; then
      icon_prefix="$icon "
      icon_width=$(($(_moma_display_width "$icon") + 1))
    else
      icon_prefix="$icon"
      icon_width="$(_moma_display_width "$icon")"
    fi
  fi

  if [[ ! "$min_width" =~ ^[0-9]+$ ]]; then
    min_width=35
  fi

  local text_display_width
  text_display_width="$(_moma_display_width "$text")"
  width="$(
    _moma_resolve_decor_width \
      "$((text_display_width + icon_width + 4))" \
      "$min_width" "$width" "$max_width" 8
  )"
  local text_budget=$((width - 4 - icon_width))
  ((text_budget > 0)) || text_budget=0
  text="$(_moma_truncate_text "$text" "$text_budget")"
  local label="${icon_prefix}${text}"
  local label_width
  label_width="$(_moma_display_width "$label")"

  local corner_left corner_right dash_count resolved_color reset
  if [[ "$edge" == bottom ]]; then
    corner_left="└"
    corner_right="┘"
  else
    corner_left="┌"
    corner_right="┐"
  fi
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"

  if [[ "$border" == open ]]; then
    dash_count=$((width - label_width - 2))
    printf '%b  %s─ %s %s%b\n\n' \
      "$resolved_color" "$corner_left" "$label" \
      "$(_moma_repeat_char "─" "$dash_count")" "$reset"
  else
    dash_count=$((width - label_width - 3))
    printf '%b  %s─ %s %s%s%b\n\n' \
      "$resolved_color" "$corner_left" "$label" \
      "$(_moma_repeat_char "─" "$dash_count")" "$corner_right" "$reset"
  fi
}

# Parse label options and print a decorated label.
moma-label() {
  local text=""
  local width=""
  local max_width=""
  local min_width=35
  local color="$MOMA_COLOR_PRIMARY"
  local icon=""
  local edge="top"
  local border="line"
  local no_color=false
  local -a positional=()
  local style

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-label "$1"
          return 1
        fi
        width="$2"
        shift 2
        ;;
      --width=*)
        width="${1#*=}"
        shift
        ;;
      --min-width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-label "$1"
          return 1
        fi
        min_width="$2"
        shift 2
        ;;
      --min-width=*)
        min_width="${1#*=}"
        shift
        ;;
      --edge)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-label "$1"
          return 1
        fi
        edge="$2"
        shift 2
        ;;
      --edge=*)
        edge="${1#*=}"
        shift
        ;;
      --border)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-label "$1"
          return 1
        fi
        border="$2"
        shift 2
        ;;
      --border=*)
        border="${1#*=}"
        shift
        ;;
      --max-width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-label "$1"
          return 1
        fi
        max_width="$2"
        shift 2
        ;;
      --max-width=*)
        max_width="${1#*=}"
        shift
        ;;
      --color | -c)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-label "$1"
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
          _moma_option_requires_value moma-label "$1"
          return 1
        fi
        icon="$2"
        shift 2
        ;;
      --icon=*)
        icon="${1#*=}"
        shift
        ;;
      --success | --error | --warning | --info)
        style="$(_moma_apply_semantic_style "${1#--}")"
        color="${style%%$'\t'*}"
        icon="${style#*$'\t'}"
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-label "<text>" [--width <number>] [--min-width <number>] [--max-width <number>] [--color <color>] [--icon <symbol>] [--edge top|bottom] [--border line|open] [--success|--error|--warning|--info] [--no-color]

--edge picks which corner the rule uses: top (default) draws ┌/┐, bottom
draws └/┘. --border controls the right end: line (default) closes it
with the matching corner, open leaves it as a bare rule instead.
EOF
        return 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-label "$1"
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  text="${positional[*]}"
  case "$edge" in
    top | bottom) ;;
    *)
      _moma_usage_error moma-label "invalid edge: $edge (expected top or bottom)"
      return 2
      ;;
  esac
  case "$border" in
    line | open) ;;
    *)
      _moma_usage_error moma-label "invalid border: $border (expected line or open)"
      return 2
      ;;
  esac
  if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
    _moma_usage_error moma-label "invalid width: $width"
    return 2
  fi
  if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
    _moma_usage_error moma-label "invalid max width: $max_width"
    return 2
  fi
  _moma_render_label \
    "$text" "$width" "$color" "$icon" "$no_color" "$max_width" \
    "$min_width" "$edge" "$border"
}
