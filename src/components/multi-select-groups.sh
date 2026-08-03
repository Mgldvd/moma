# Multiple-selection component split across named, non-selectable groups.
# Render a multiple-selection menu split across named groups from normalized
# arguments. Group headings are display-only and never receive focus.
_moma_render_multi_select_groups() {
  local title="$1"
  local active_index="$2"
  local selected_state="$3"
  local color="$4"
  local no_color="$5"
  local redraw="$6"
  local num_groups="$7"
  shift 7
  local -a group_names=("${@:1:$num_groups}")
  shift "$num_groups"
  local -a group_counts=("${@:1:$num_groups}")
  shift "$num_groups"
  local -a options=("$@")

  if $redraw; then
    _moma_term_move_up "$((${#options[@]} + num_groups * 2 + 3))"
  fi

  _moma_select_render_header "$title" "$color" "$no_color" "$redraw"

  local group_index offset=0 row glyph active flat_index
  for group_index in "${!group_names[@]}"; do
    _moma_select_render_blank "$redraw"
    _moma_select_render_group_heading "${group_names[$group_index]}" "$redraw"

    for ((row = 0; row < group_counts[group_index]; row++)); do
      flat_index=$((offset + row))
      glyph="□"
      _moma_multi_is_selected "$selected_state" "$flat_index" && glyph="▣"
      active=false
      ((flat_index != active_index)) || active=true
      _moma_select_render_row \
        "$active" "$glyph" "${options[$flat_index]}" \
        "$color" "$no_color" "$redraw"
    done
    offset=$((offset + group_counts[group_index]))
  done

  _moma_select_render_footer \
    "↑/↓ move · Space toggle · Enter confirm · q cancel" "$redraw"
}

# Parse grouped multiple-selection options and return chosen values on
# stdout, in original visual order. Option numbers are one-based, global,
# and exclude group headings.
moma-multi-select-groups() {
  local title="Select options"
  local color="$MOMA_COLOR_PRIMARY"
  local initial=1
  local selected_spec=""
  local choose_spec=""
  local choose_set=false
  local required=false
  local no_color=false
  local -a group_names=()
  local -a group_counts=()
  local -a options=()
  local selected_state=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-multi-select-groups "$1"
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
          _moma_option_requires_value moma-multi-select-groups "$1"
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
          _moma_option_requires_value moma-multi-select-groups "$1"
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
          _moma_option_requires_value moma-multi-select-groups "$1"
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
          _moma_option_requires_value moma-multi-select-groups "$1"
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
      --group)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-multi-select-groups "$1"
          return 2
        fi
        group_names+=("$2")
        group_counts+=(0)
        shift 2
        ;;
      --group=*)
        group_names+=("${1#*=}")
        group_counts+=(0)
        shift
        ;;
      --option)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-multi-select-groups "$1"
          return 2
        fi
        if ((${#group_names[@]} == 0)); then
          printf 'moma-multi-select-groups: %s\n' \
            '--option must follow a --group' >&2
          return 2
        fi
        options+=("$2")
        group_counts[${#group_counts[@]} - 1]=$(( \
          group_counts[${#group_counts[@]} - 1] + 1))
        shift 2
        ;;
      --option=*)
        if ((${#group_names[@]} == 0)); then
          printf 'moma-multi-select-groups: %s\n' \
            '--option must follow a --group' >&2
          return 2
        fi
        options+=("${1#*=}")
        group_counts[${#group_counts[@]} - 1]=$(( \
          group_counts[${#group_counts[@]} - 1] + 1))
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-multi-select-groups --title <text> (--group <name> --option <value>...)... [--initial <number>] [--selected <numbers>] [--choose <numbers>] [--required] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Space to toggle, Enter to confirm, and q or Escape to cancel.
Group headings are display-only: they never receive focus and are never printed on stdout.
Number lists are one-based, comma-separated, count only options, and follow visual order across every group.
--choose selects immediately for scripts and tests. Each selected value is printed on its own line, in original visual order.
EOF
        return 0
        ;;
      -*)
        _moma_unknown_option moma-multi-select-groups "$1"
        return 2
        ;;
      *)
        printf 'moma-multi-select-groups: unexpected argument: %s\n' "$1" >&2
        return 2
        ;;
    esac
  done

  if ((${#group_names[@]} == 0)); then
    printf 'moma-multi-select-groups: provide at least one --group\n' >&2
    return 2
  fi
  _moma_validate_groups moma-multi-select-groups "${group_counts[@]}" ||
    return 2

  local total_options="${#options[@]}"
  if ! _moma_is_index_in_range "$initial" "$total_options"; then
    printf 'moma-multi-select-groups: invalid initial option: %s\n' \
      "$initial" >&2
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
      if ! _moma_is_index_in_range "$normalized_index" "$total_options"; then
        printf 'moma-multi-select-groups: invalid option number: %s\n' \
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
      printf 'moma-multi-select-groups: select at least one option\n' >&2
      return 2
    fi
    _moma_render_multi_select_groups \
      "$title" "$active_index" "$selected_state" "$color" "$no_color" false \
      "${#group_names[@]}" "${group_names[@]}" "${group_counts[@]}" \
      "${options[@]}"
    printf '\n' >&2
    _moma_emit_multi_select "$selected_state" "${options[@]}"
    return 0
  fi

  if [[ ! -t 0 || ! -t 2 ]]; then
    printf '%s%s\n' \
      'moma-multi-select-groups: interactive input requires a terminal; ' \
      'use --choose <numbers> for automation' >&2
    return 2
  fi

  _moma_render_multi_select_groups \
    "$title" "$active_index" "$selected_state" "$color" "$no_color" false \
    "${#group_names[@]}" "${group_names[@]}" "${group_counts[@]}" \
    "${options[@]}"

  local event transition remainder transition_status
  while true; do
    if ! _moma_term_read_key event; then
      printf '\n' >&2
      return 130
    fi

    transition="$(
      _moma_multi_select_transition \
        "$active_index" "$selected_state" "$total_options" "$event"
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

    _moma_render_multi_select_groups \
      "$title" "$active_index" "$selected_state" "$color" "$no_color" true \
      "${#group_names[@]}" "${group_names[@]}" "${group_counts[@]}" \
      "${options[@]}"
  done
}
