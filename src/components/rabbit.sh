# Rabbit component.
# Render the Moma rabbit and its semantic message.
_moma_render_rabbit() {
  local message="$1"
  local color="${2:-}"
  local icon="${3:-}"
  local no_color="${4:-false}"

  local output=""
  local display_message="$message"
  if [[ -n "$icon" && -n "$display_message" ]]; then
    display_message="$icon $display_message"
  elif [[ -n "$icon" ]]; then
    display_message="$icon"
  fi

  if [[ -n "$display_message" ]]; then
    local max_width=40
    local lines=()
    local line
    while IFS= read -r line; do
      while [[ ${#line} -gt $max_width ]]; do
        lines+=("${line:0:$max_width}")
        line="${line:$max_width}"
      done
      lines+=("$line")
    done <<<"$display_message"

    for line in "${lines[@]}"; do
      output+="  | $line"$'\n'
    done

    local last_index=$((${#lines[@]} - 1))
    local last_line_width
    last_line_width="$(_moma_display_width "${lines[$last_index]}")"
    local tail_length=$((last_line_width + 3))
    output+="  /$(_moma_repeat_char "⎺" "$tail_length")"$'\n'
  fi

  output+='
    (\(\
    (-.-)
  o_(")(")'

  printf '\n'
  if [[ "$no_color" == "true" || -n "${NO_COLOR:-}" ]]; then
    printf '%s\n' "$output"
    return 0
  fi

  local resolved_color reset
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"
  printf '%b%s\n%b' "$resolved_color" "$output" "$reset"
}

# Parse rabbit options and print the Moma rabbit component.
moma-rabbit() {
  local color=""
  local icon=""
  local no_color=false
  local -a message=()
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
          _moma_option_requires_value moma-rabbit "$1"
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
          _moma_option_requires_value moma-rabbit "$1"
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
Usage: moma-rabbit ["message"] [--success|--error|--warning|--info] [--color <color>] [--icon <icon>] [--no-color]
EOF
        return 0
        ;;
      --)
        shift
        message+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-rabbit "$1"
        return 1
        ;;
      *)
        message+=("$1")
        shift
        ;;
    esac
  done

  _moma_render_rabbit "${message[*]}" "$color" "$icon" "$no_color"
}
