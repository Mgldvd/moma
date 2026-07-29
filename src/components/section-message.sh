# Section and message components.
# Render a semantic section heading from normalized arguments.
_moma_render_section() {
  local text="$1"
  local color="${2:-$MOMA_COLOR_PRIMARY}"
  local icon="${3:-}"
  local no_color="${4:-false}"

  local resolved_color reset
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"

  printf '%b\n' "$resolved_color"
  printf '  ┌\n'
  if [[ -n "$icon" ]]; then
    printf '  ▪ %s %s\n' "$icon" "$text"
  else
    printf '  ▪ %s\n' "$text"
  fi
  printf '  └ %b\n' "$reset"
}

# Parse section options and print a semantic heading.
moma-section() {
  local text=""
  local color="$MOMA_COLOR_PRIMARY"
  local icon=""
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
          _moma_option_requires_value moma-section "$1"
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
          _moma_option_requires_value moma-section "$1"
          return 1
        fi
        icon="$2"
        shift 2
        ;;
      --icon=*)
        icon="${1#*=}"
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-section "<text>" [--success|--error|--warning|--info] [--color <color>] [--icon <icon>] [--no-color]
EOF
        return 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-section "$1"
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  text="${positional[*]}"
  _moma_render_section "$text" "$color" "$icon" "$no_color"
}

# Render a semantic message from normalized arguments.
_moma_render_msg() {
  local text="$1"
  local color="${2:-$MOMA_COLOR_PRIMARY}"
  local icon="${3:-}"
  local variant="${4:-default}"
  local no_color="${5:-false}"

  local resolved_color reset
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"

  case "$variant" in
    plain)
      if [[ -n "$icon" ]]; then
        printf '%b  %s%b %s\n' "$resolved_color" "$icon" "$reset" "$text"
      else
        printf '  %s\n' "$text"
      fi
      ;;
    *)
      if [[ -n "$icon" ]]; then
        printf '%b  ▪ %s %b%s %b %s %b\n' \
          "$resolved_color" "$icon" "$reset" "$text" \
          "$resolved_color" "$icon" "$reset"
      else
        printf '%b  ▪ %b%s%b\n' "$resolved_color" "$reset" "$text" "$reset"
      fi
      ;;
  esac
}

# Parse message options and print a semantic message.
moma-msg() {
  local text=""
  local color="$MOMA_COLOR_PRIMARY"
  local icon=""
  local variant="default"
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
      --plain)
        variant=plain
        shift
        ;;
      --color | -c)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-msg "$1"
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
          _moma_option_requires_value moma-msg "$1"
          return 1
        fi
        icon="$2"
        shift 2
        ;;
      --icon=*)
        icon="${1#*=}"
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-msg "<text>" [--success|--error|--warning|--info] [--color <color>] [--icon <icon>] [--plain] [--no-color]
EOF
        return 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-msg "$1"
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  text="${positional[*]}"
  _moma_render_msg "$text" "$color" "$icon" "$variant" "$no_color"
}
