# Multiple-selection component with checkbox-style indicators.
# Render a multiple-selection menu from normalized arguments.
_moma_render_multi_select() {
  local title="$1"
  local active_index="$2"
  local selected_state="$3"
  local color="$4"
  local no_color="$5"
  local redraw="$6"
  shift 6
  local -a options=("$@")

  if $redraw; then
    _moma_term_move_up "$((${#options[@]} + 3))"
  fi

  _moma_select_render_header "$title" "$color" "$no_color" "$redraw"

  local index glyph active
  for index in "${!options[@]}"; do
    glyph="□"
    _moma_multi_is_selected "$selected_state" "$index" && glyph="▣"
    active=false
    ((index != active_index)) || active=true
    _moma_select_render_row \
      "$active" "$glyph" "${options[$index]}" "$color" "$no_color" "$redraw"
  done

  _moma_select_render_footer \
    "↑/↓ move · Space toggle · Enter confirm · q cancel" "$redraw"
}

# Parse multiple-selection options and return chosen values on stdout.
moma-multi-select() {
  local title="Select options"
  local color="$MOMA_COLOR_PRIMARY"
  local initial=1
  local selected_spec=""
  local choose_spec=""
  local choose_set=false
  local required=false
  local no_color=false
  local -a options=()
  local selected_state=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-multi-select "$1"
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
          _moma_option_requires_value moma-multi-select "$1"
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
          _moma_option_requires_value moma-multi-select "$1"
          return 2
        fi
        initial="$2"
        shift 2
        ;;
      --initial=*)
        initial="${1#*=}"
        shift
        ;;
      --selected)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-multi-select "$1"
          return 2
        fi
        selected_spec="$2"
        shift 2
        ;;
      --selected=*)
        selected_spec="${1#*=}"
        shift
        ;;
      --choose)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-multi-select "$1"
          return 2
        fi
        choose_spec="$2"
        choose_set=true
        shift 2
        ;;
      --choose=*)
        choose_spec="${1#*=}"
        choose_set=true
        shift
        ;;
      --required)
        required=true
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-multi-select "option"... [--title <text>] [--initial <number>] [--selected <numbers>] [--choose <numbers>] [--required] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Space to toggle, Enter to confirm, and q or Escape to cancel.
Number lists are one-based and comma-separated. --choose selects immediately for scripts and tests.
Each selected value is printed on its own line, in original visual order.
EOF
        return 0
        ;;
      --)
        shift
        options+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-multi-select "$1"
        return 2
        ;;
      *)
        options+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#options[@]} -eq 0 ]]; then
    printf 'moma-multi-select: provide at least one option\n' >&2
    return 2
  fi
  if ! _moma_is_index_in_range "$initial" "${#options[@]}"; then
    printf 'moma-multi-select: invalid initial option: %s\n' "$initial" >&2
    return 2
  fi

  local selection_spec="$selected_spec"
  $choose_set && selection_spec="$choose_spec"
  if [[ -n "$selection_spec" ]]; then
    local -a requested_indices=()
    local requested_index normalized_index
    IFS=',' read -r -a requested_indices <<<"$selection_spec"
    for requested_index in "${requested_indices[@]}"; do
      normalized_index="$(_moma_trim "$requested_index")"
      if ! _moma_is_index_in_range "$normalized_index" "${#options[@]}"; then
        printf 'moma-multi-select: invalid option number: %s\n' \
          "$requested_index" >&2
        return 2
      fi
      normalized_index=$((normalized_index - 1))
      if ! _moma_multi_is_selected "$selected_state" "$normalized_index"; then
        selected_state+="${selected_state:+,}$normalized_index"
      fi
    done
  fi

  local active_index=$((initial - 1))
  if $choose_set; then
    if $required && [[ -z "$selected_state" ]]; then
      printf 'moma-multi-select: select at least one option\n' >&2
      return 2
    fi
    _moma_render_multi_select \
      "$title" "$active_index" "$selected_state" "$color" \
      "$no_color" false "${options[@]}"
    printf '\n' >&2
    _moma_emit_multi_select "$selected_state" "${options[@]}"
    return 0
  fi

  if [[ ! -t 0 || ! -t 2 ]]; then
    printf '%s%s\n' \
      'moma-multi-select: interactive input requires a terminal; ' \
      'use --choose <numbers> for automation' >&2
    return 2
  fi

  _moma_render_multi_select \
    "$title" "$active_index" "$selected_state" "$color" \
    "$no_color" false "${options[@]}"

  local event transition remainder transition_status
  while true; do
    if ! _moma_term_read_key event; then
      printf '\n' >&2
      return 130
    fi

    transition="$(
      _moma_multi_select_transition \
        "$active_index" "$selected_state" "${#options[@]}" "$event"
    )"
    active_index="${transition%%$'\t'*}"
    remainder="${transition#*$'\t'}"
    selected_state="${remainder%%$'\t'*}"
    transition_status="${remainder#*$'\t'}"
    case "$transition_status" in
      confirm)
        if $required && [[ -z "$selected_state" ]]; then
          printf '\a' >&2
          continue
        fi
        printf '\n' >&2
        _moma_emit_multi_select "$selected_state" "${options[@]}"
        return 0
        ;;
      cancel)
        printf '\n' >&2
        return 130
        ;;
    esac

    _moma_render_multi_select \
      "$title" "$active_index" "$selected_state" "$color" \
      "$no_color" true "${options[@]}"
  done
}
