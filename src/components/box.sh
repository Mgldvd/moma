# Box component.
# Render a framed message from normalized box arguments.
_moma_render_box() {
  local text="$1"
  local color="${2:-$MOMA_COLOR_PRIMARY}"
  local icon="${3:-}"
  local width="${4:-}"
  local padding="${5:-1}"
  local no_color="${6:-false}"
  local max_width="${7:-}"

  if [[ ! "$padding" =~ ^[0-9]+$ ]]; then
    padding=1
  fi
  local display_text="$text"
  if [[ -n "$icon" ]]; then
    display_text="$icon $display_text"
  fi

  local natural_width=$((${#display_text} + padding * 2))
  local hard_min_width=$((padding * 2 + 1))
  ((hard_min_width >= 8)) || hard_min_width=8
  local content_width
  content_width="$(_moma_resolve_decor_width \
    "$natural_width" 0 "$width" "$max_width" "$hard_min_width")"

  local left_pad right_pad line
  local text_width=$((content_width - padding * 2))
  local -a lines=()
  mapfile -t lines < <(_moma_wrap_text "$display_text" "$text_width")
  left_pad="$(_moma_repeat_char " " "$padding")"

  local resolved_color reset
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"

  printf '%b' "$resolved_color"
  printf '  ┌%s┐\n' "$(_moma_repeat_char "─" "$content_width")"
  for line in "${lines[@]}"; do
    right_pad="$(
      _moma_repeat_char " " "$((content_width - ${#line} - padding))"
    )"
    printf '  │%s%s%s│\n' "$left_pad" "$line" "$right_pad"
  done
  printf '  └%s┘%b\n' "$(_moma_repeat_char "─" "$content_width")" "$reset"
}

# Parse box options and print a framed message.
moma-box() {
  local text=""
  local color="$MOMA_COLOR_PRIMARY"
  local icon=""
  local width=""
  local max_width=""
  local padding=1
  local no_color=false
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
          _moma_option_requires_value moma-box "$1"
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
          _moma_option_requires_value moma-box "$1"
          return 1
        fi
        icon="$2"
        shift 2
        ;;
      --icon=*)
        icon="${1#*=}"
        shift
        ;;
      --width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-box "$1"
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
          _moma_option_requires_value moma-box "$1"
          return 1
        fi
        max_width="$2"
        shift 2
        ;;
      --max-width=*)
        max_width="${1#*=}"
        shift
        ;;
      --padding)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-box "$1"
          return 1
        fi
        padding="$2"
        shift 2
        ;;
      --padding=*)
        padding="${1#*=}"
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-box "<text>" [--success|--error|--warning|--info] [--color <color>] [--icon <icon>] [--width <n>] [--max-width <n>] [--padding <n>] [--no-color]
EOF
        return 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-box "$1"
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  text="${positional[*]}"
  if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
    _moma_usage_error moma-box "invalid width: $width"
    return 2
  fi
  if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
    _moma_usage_error moma-box "invalid max width: $max_width"
    return 2
  fi
  _moma_render_box \
    "$text" "$color" "$icon" "$width" "$padding" "$no_color" "$max_width"
}
