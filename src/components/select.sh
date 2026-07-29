# Single and multiple selection components.
# Render a single-selection menu from normalized arguments.
_moma_render_select() {
  local title="$1"
  local selected_index="$2"
  local color="$3"
  local no_color="$4"
  local redraw="$5"
  shift 5
  local -a options=("$@")
  local marker="▪"

  local active_color reset header_width
  active_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"
  header_width="$(_moma_resolve_decor_width "$((${#title} + 6))" 30 "" "" 8)"

  if $redraw; then
    _moma_term_move_up "$((${#options[@]} + 3))"
  fi

  if $redraw; then _moma_term_clear_line; fi
  printf '  %b▪%b  %s\n' "$active_color" "$reset" "$title" >&2

  if $redraw; then _moma_term_clear_line; fi
  printf '  %b└%s%b\n' \
    "$active_color" "$(_moma_repeat_char "─" "$header_width")" \
    "$reset" >&2

  local index
  for index in "${!options[@]}"; do
    if $redraw; then _moma_term_clear_line; fi
    if ((index == selected_index)); then
      printf '  %b%s%b %s\n' \
        "$active_color" "$marker" "$reset" \
        "${options[$index]}" >&2
    else
      printf '    %s\n' "${options[$index]}" >&2
    fi
  done

  if $redraw; then _moma_term_clear_line; fi
  printf '  ↑/↓ move · Enter select · q cancel\n' >&2
}

# Resolve a single-selection keyboard event to its next state.
_moma_select_transition() {
  local selected_index="$1"
  local option_count="$2"
  local event="$3"
  local result=continue

  case "$event" in
    up | k)
      selected_index=$(((selected_index - 1 + option_count) % option_count))
      ;;
    down | j) selected_index=$(((selected_index + 1) % option_count)) ;;
    enter) result=confirm ;;
    cancel) result=cancel ;;
  esac

  printf '%s\t%s\n' "$selected_index" "$result"
}

# Parse selection options and return the chosen value on stdout.
moma-select() {
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
          _moma_option_requires_value moma-select "$1"
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
          _moma_option_requires_value moma-select "$1"
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
          _moma_option_requires_value moma-select "$1"
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
          _moma_option_requires_value moma-select "$1"
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
Usage: moma-select "option"... [--title <text>] [--initial <number>] [--choose <number>] [--color <color>] [--no-color]

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
        _moma_unknown_option moma-select "$1"
        return 2
        ;;
      *)
        options+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#options[@]} -eq 0 ]]; then
    printf 'moma-select: provide at least one option\n' >&2
    return 2
  fi
  if ! _moma_is_index_in_range "$initial" "${#options[@]}"; then
    printf 'moma-select: invalid initial option: %s\n' "$initial" >&2
    return 2
  fi
  if [[ -n "$choose" ]] &&
    ! _moma_is_index_in_range "$choose" "${#options[@]}"; then
    printf 'moma-select: invalid chosen option: %s\n' "$choose" >&2
    return 2
  fi

  local selected_index=$((initial - 1))
  if [[ -n "$choose" ]]; then
    selected_index=$((choose - 1))
    _moma_render_select \
      "$title" "$selected_index" "$color" "$no_color" \
      false "${options[@]}"
    printf '\n' >&2
    printf '%s\n' "${options[$selected_index]}"
    return 0
  fi

  if [[ ! -t 0 || ! -t 2 ]]; then
    printf '%s%s\n' \
      'moma-select: interactive input requires a terminal; ' \
      'use --choose <number> for automation' >&2
    return 2
  fi

  _moma_render_select \
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

    _moma_render_select \
      "$title" "$selected_index" "$color" "$no_color" \
      true "${options[@]}"
  done
}

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

  local active_color reset checkbox pointer header_width
  active_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"
  header_width="$(_moma_resolve_decor_width "$((${#title} + 6))" 30 "" "" 8)"

  if $redraw; then
    _moma_term_move_up "$((${#options[@]} + 3))"
  fi

  if $redraw; then _moma_term_clear_line; fi
  printf '  %b▪%b  %s\n' "$active_color" "$reset" "$title" >&2

  if $redraw; then _moma_term_clear_line; fi
  printf '  %b└%s%b\n' \
    "$active_color" "$(_moma_repeat_char "─" "$header_width")" \
    "$reset" >&2

  local index
  for index in "${!options[@]}"; do
    if $redraw; then _moma_term_clear_line; fi
    checkbox="▢"
    _moma_multi_is_selected "$selected_state" "$index" && checkbox="▣"
    pointer=" "
    ((index != active_index)) || pointer="›"

    if ((index == active_index)); then
      printf '  %b%s %s %s%b\n' \
        "$active_color" "$pointer" "$checkbox" \
        "${options[$index]}" "$reset" >&2
    else
      printf '  %s %s %s\n' "$pointer" "$checkbox" "${options[$index]}" >&2
    fi
  done

  if $redraw; then _moma_term_clear_line; fi
  printf '  ↑/↓ move · Space toggle · Enter confirm · q cancel\n' >&2
}

# Print selected multiple-choice values on stdout.
_moma_emit_multi_select() {
  local selected_state="$1"
  shift
  local -a options=("$@")
  local index

  for index in "${!options[@]}"; do
    if _moma_multi_is_selected "$selected_state" "$index"; then
      printf '%s\n' "${options[$index]}"
    fi
  done
}

# Return success when an index exists in a selected-state list.
_moma_multi_is_selected() {
  local selected_state="$1"
  local index="$2"
  [[ ",$selected_state," == *",$index,"* ]]
}

# Toggle an index in a selected-state list and print the new list.
_moma_multi_toggle() {
  local selected_state="$1"
  local target_index="$2"
  local value result="" found=false
  local -a values=()

  if [[ -n "$selected_state" ]]; then
    IFS=',' read -r -a values <<<"$selected_state"
  fi
  for value in "${values[@]}"; do
    if [[ "$value" == "$target_index" ]]; then
      found=true
      continue
    fi
    result+="${result:+,}$value"
  done
  if ! $found; then
    result+="${result:+,}$target_index"
  fi
  printf '%s' "$result"
}

# Resolve a multiple-selection keyboard event to its next state.
_moma_multi_select_transition() {
  local active_index="$1"
  local selected_state="$2"
  local option_count="$3"
  local event="$4"
  local result=continue

  case "$event" in
    up | k)
      active_index=$(((active_index - 1 + option_count) % option_count))
      ;;
    down | j) active_index=$(((active_index + 1) % option_count)) ;;
    space)
      selected_state="$(
        _moma_multi_toggle "$selected_state" "$active_index"
      )"
      ;;
    enter) result=confirm ;;
    cancel) result=cancel ;;
  esac

  printf '%s\t%s\t%s\n' "$active_index" "$selected_state" "$result"
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
Each selected value is printed on its own line.
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
