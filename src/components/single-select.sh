# Single-selection component with radio-style indicators.
# Render a single-selection menu from normalized arguments.
_moma_render_single_select() {
  local title="$1"
  local selected_index="$2"
  local color="$3"
  local no_color="$4"
  local redraw="$5"
  shift 5
  local -a options=("$@")

  if $redraw; then
    _moma_term_move_up "$((${#options[@]} + 3))"
  fi

  _moma_select_render_header "$title" "$color" "$no_color" "$redraw"

  local index glyph active
  for index in "${!options[@]}"; do
    glyph="○"
    active=false
    if ((index == selected_index)); then
      glyph="◉"
      active=true
    fi
    _moma_select_render_row \
      "$active" "$glyph" "${options[$index]}" "$color" "$no_color" "$redraw"
  done

  _moma_select_render_footer \
    "↑/↓ move · Enter select · q cancel" "$redraw"
}

# Parse single-selection options and return the chosen value on stdout.
moma-single-select() {
  local title="Select an option"
  local color="$MOMA_COLOR_PRIMARY"
  local initial=1
  local choose=""
  local no_color=false
  local -a options=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-single-select "$1"
          return 2
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
          _moma_option_requires_value moma-single-select "$1"
          return 2
        fi
        color="$2"
        shift 2
        ;;
      --color=*)
        color="${1#*=}"
        shift
        ;;
      --initial)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-single-select "$1"
          return 2
        fi
        initial="$2"
        shift 2
        ;;
      --initial=*)
        initial="${1#*=}"
        shift
        ;;
      --choose)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-single-select "$1"
          return 2
        fi
        choose="$2"
        shift 2
        ;;
      --choose=*)
        choose="${1#*=}"
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-single-select "option"... [--title <text>] [--initial <number>] [--choose <number>] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Enter to select, and q or Escape to cancel.
Option numbers are one-based. --choose selects immediately for scripts and tests.
EOF
        return 0
        ;;
      --)
        shift
        options+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-single-select "$1"
        return 2
        ;;
      *)
        options+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#options[@]} -eq 0 ]]; then
    printf 'moma-single-select: provide at least one option\n' >&2
    return 2
  fi
  if ! _moma_is_index_in_range "$initial" "${#options[@]}"; then
    printf 'moma-single-select: invalid initial option: %s\n' "$initial" >&2
    return 2
  fi
  if [[ -n "$choose" ]] &&
    ! _moma_is_index_in_range "$choose" "${#options[@]}"; then
    printf 'moma-single-select: invalid chosen option: %s\n' "$choose" >&2
    return 2
  fi

  local selected_index=$((initial - 1))
  if [[ -n "$choose" ]]; then
    selected_index=$((choose - 1))
    _moma_render_single_select \
      "$title" "$selected_index" "$color" "$no_color" \
      false "${options[@]}"
    printf '\n' >&2
    printf '%s\n' "${options[$selected_index]}"
    return 0
  fi

  if [[ ! -t 0 || ! -t 2 ]]; then
    printf '%s%s\n' \
      'moma-single-select: interactive input requires a terminal; ' \
      'use --choose <number> for automation' >&2
    return 2
  fi

  _moma_render_single_select \
    "$title" "$selected_index" "$color" "$no_color" \
    false "${options[@]}"

  local event transition transition_status
  while true; do
    if ! _moma_term_read_key event; then
      printf '\n' >&2
      return 130
    fi

    transition="$(
      _moma_select_transition "$selected_index" "${#options[@]}" "$event"
    )"
    selected_index="${transition%%$'\t'*}"
    transition_status="${transition#*$'\t'}"
    case "$transition_status" in
      confirm)
        printf '\n' >&2
        printf '%s\n' "${options[$selected_index]}"
        return 0
        ;;
      cancel)
        printf '\n' >&2
        return 130
        ;;
    esac

    _moma_render_single_select \
      "$title" "$selected_index" "$color" "$no_color" \
      true "${options[@]}"
  done
}

# Legacy compatibility alias kept for existing scripts and the `select` CLI
# command. Behavior, arguments, and rendering fully match moma-single-select.
moma-select() {
  moma-single-select "$@"
}
