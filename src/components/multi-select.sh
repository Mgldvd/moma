# Multiple-selection component with checkbox-style indicators.
# Render a multiple-selection menu from normalized arguments. When windowed
# and the terminal is shorter than the full option list, only a scrolling
# slice around active_index is drawn, with a "more above/below" indicator,
# so a redraw always rewrites the same number of lines regardless of list
# length. Non-interactive callers (--choose) pass windowed=false so their
# output stays complete and deterministic.
_moma_render_multi_select() {
  local title="$1"
  local active_index="$2"
  local selected_state="$3"
  local color="$4"
  local no_color="$5"
  local redraw="$6"
  local windowed="$7"
  shift 7
  local -a options=("$@")
  local total="${#options[@]}"

  local window_start=0 window_count="$total" indicator_lines=0
  if $windowed; then
    local term_height max_visible window
    term_height="$(_moma_term_height)"
    max_visible=$((term_height - 4))
    if ((max_visible > 0 && max_visible < total)); then
      indicator_lines=1
      window="$(_moma_select_window "$active_index" "$total" "$max_visible")"
      window_start="${window%%$'\t'*}"
      window_count="${window#*$'\t'}"
    fi
  fi

  if $redraw; then
    _moma_term_move_up "$((window_count + indicator_lines + 3))"
  fi

  _moma_select_render_header "$title" "$color" "$no_color" "$redraw"

  if ((indicator_lines > 0)); then
    _moma_select_render_scroll_indicator \
      "$window_start" "$((total - window_start - window_count))" "$redraw"
  fi

  local row flat_index glyph active
  for ((row = 0; row < window_count; row++)); do
    flat_index=$((window_start + row))
    glyph="□"
    _moma_multi_is_selected "$selected_state" "$flat_index" && glyph="▣"
    active=false
    ((flat_index != active_index)) || active=true
    _moma_select_render_row \
      "$active" "$glyph" "${options[$flat_index]}" \
      "$color" "$no_color" "$redraw"
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
      "$no_color" false false "${options[@]}"
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
    "$no_color" false true "${options[@]}"

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
      "$no_color" true true "${options[@]}"
  done
}
