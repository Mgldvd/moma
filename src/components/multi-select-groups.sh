# Multiple-selection component split across named groups, each with its own
# "All" toggle and a top-level "Select All" toggle. Group headings remain
# display-only, but the All rows are real, focusable, toggleable rows.
# Render a multiple-selection menu split across named groups from normalized
# arguments. Group headings and blank separators cost extra lines that vary
# with where the list scrolls, so when windowed and the full layout would
# not fit the terminal, this switches to a compact layout instead: headings
# and blank separators are dropped, each group's All row is labeled with its
# group name inline, and every navigable row costs exactly one line, which
# lets a fixed-size scrolling window (the same math as moma-multi-select)
# stay correct regardless of scroll position.
_moma_render_multi_select_groups() {
  local title="$1"
  local active_row="$2"
  local selected_state="$3"
  local color="$4"
  local no_color="$5"
  local redraw="$6"
  local windowed="$7"
  local num_groups="$8"
  shift 8
  local -a group_names=("${@:1:$num_groups}")
  shift "$num_groups"
  local -a group_counts=("${@:1:$num_groups}")
  shift "$num_groups"
  local -a options=("$@")
  local total_options="${#options[@]}"
  local row_count=$((1 + num_groups + total_options))
  local full_lines=$((total_options + num_groups * 3 + 5))

  local compact=false window_start=0 window_count="$row_count" \
    indicator_lines=0
  if $windowed; then
    local term_height max_visible
    term_height="$(_moma_term_height)"
    if ((full_lines > term_height)); then
      compact=true
      max_visible=$((term_height - 4))
      ((max_visible < 1)) && max_visible=1
      if ((max_visible < row_count)); then
        indicator_lines=1
        local window
        window="$(_moma_select_window "$active_row" "$row_count" "$max_visible")"
        window_start="${window%%$'\t'*}"
        window_count="${window#*$'\t'}"
      fi
    fi
  fi

  if $compact; then
    if $redraw; then
      _moma_term_move_up "$((window_count + indicator_lines + 3))"
    fi

    _moma_select_render_header "$title" "$color" "$no_color" "$redraw"

    if ((indicator_lines > 0)); then
      _moma_select_render_scroll_indicator \
        "$window_start" "$((row_count - window_start - window_count))" \
        "$redraw"
    fi

    local row resolved kind payload glyph label active offset
    for ((row = window_start; row < window_start + window_count; row++)); do
      resolved="$(
        _moma_multi_groups_resolve_row "$row" "$num_groups" "${group_counts[@]}"
      )"
      kind="${resolved%% *}"
      payload="${resolved#* }"
      active=false
      ((row != active_row)) || active=true
      case "$kind" in
        selectall)
          glyph="$(
            _moma_multi_groups_range_glyph "$selected_state" 0 "$total_options"
          )"
          label="Select All"
          ;;
        group)
          offset="$(
            _moma_multi_groups_group_offset "$payload" "$num_groups" \
              "${group_counts[@]}"
          )"
          glyph="$(
            _moma_multi_groups_range_glyph \
              "$selected_state" "$offset" "${group_counts[$payload]}"
          )"
          label="All · ${group_names[$payload]}"
          ;;
        option)
          glyph="□"
          _moma_multi_is_selected "$selected_state" "$payload" && glyph="▣"
          label="${options[$payload]}"
          ;;
      esac
      _moma_select_render_row \
        "$active" "$glyph" "$label" "$color" "$no_color" "$redraw"
    done

    _moma_select_render_footer \
      "↑/↓ move · Space toggle · Enter confirm · q cancel" "$redraw"
    return
  fi

  if $redraw; then
    _moma_term_move_up "$full_lines"
  fi

  _moma_select_render_header "$title" "$color" "$no_color" "$redraw"

  local glyph active row_index=0
  glyph="$(_moma_multi_groups_range_glyph "$selected_state" 0 "$total_options")"
  active=false
  ((row_index != active_row)) || active=true
  _moma_select_render_blank "$redraw"
  _moma_select_render_row \
    "$active" "$glyph" "Select All" "$color" "$no_color" "$redraw"
  row_index=$((row_index + 1))

  local group_index offset=0 row glyph_range flat_index
  for group_index in "${!group_names[@]}"; do
    _moma_select_render_blank "$redraw"
    _moma_select_render_group_heading "${group_names[$group_index]}" "$redraw"

    glyph_range="$(
      _moma_multi_groups_range_glyph \
        "$selected_state" "$offset" "${group_counts[$group_index]}"
    )"
    active=false
    ((row_index != active_row)) || active=true
    _moma_select_render_row \
      "$active" "$glyph_range" "All" "$color" "$no_color" "$redraw"
    row_index=$((row_index + 1))

    for ((row = 0; row < group_counts[group_index]; row++)); do
      flat_index=$((offset + row))
      glyph="□"
      _moma_multi_is_selected "$selected_state" "$flat_index" && glyph="▣"
      active=false
      ((row_index != active_row)) || active=true
      _moma_select_render_row \
        "$active" "$glyph" "${options[$flat_index]}" \
        "$color" "$no_color" "$redraw"
      row_index=$((row_index + 1))
    done
    offset=$((offset + group_counts[group_index]))
  done

  _moma_select_render_footer \
    "↑/↓ move · Space toggle · Enter confirm · q cancel" "$redraw"
}

# Classify a flat option index range as fully selected, partially selected,
# or empty. Prints "all", "some", or "none".
_moma_multi_groups_range_state() {
  local selected_state="$1"
  local start="$2"
  local count="$3"
  local i selected_count=0

  for ((i = start; i < start + count; i++)); do
    _moma_multi_is_selected "$selected_state" "$i" &&
      selected_count=$((selected_count + 1))
  done

  if ((count == 0 || selected_count == 0)); then
    printf 'none'
  elif ((selected_count == count)); then
    printf 'all'
  else
    printf 'some'
  fi
}

# Render the checkbox glyph for an option range: filled when every option is
# selected, hatched for a partial selection, empty otherwise.
_moma_multi_groups_range_glyph() {
  case "$(_moma_multi_groups_range_state "$@")" in
    all) printf '▣' ;;
    some) printf '▨' ;;
    *) printf '□' ;;
  esac
}

# Toggle every option in a flat index range as one unit: clear the range once
# every option in it is already selected, otherwise select whatever in the
# range is still unselected.
_moma_multi_groups_toggle_range() {
  local selected_state="$1"
  local start="$2"
  local count="$3"
  local i

  if [[ "$(
    _moma_multi_groups_range_state "$selected_state" "$start" "$count"
  )" == all ]]; then
    local -a values=()
    local value result=""
    [[ -n "$selected_state" ]] && IFS=',' read -r -a values <<<"$selected_state"
    for value in "${values[@]}"; do
      ((value >= start && value < start + count)) ||
        result+="${result:+,}$value"
    done
    printf '%s' "$result"
    return
  fi

  for ((i = start; i < start + count; i++)); do
    _moma_multi_is_selected "$selected_state" "$i" ||
      selected_state+="${selected_state:+,}$i"
  done
  printf '%s' "$selected_state"
}

# Resolve the flat option offset (0-based) at which a group's options begin.
_moma_multi_groups_group_offset() {
  local group_index="$1"
  local num_groups="$2"
  shift 2
  local -a group_counts=("${@:1:$num_groups}")
  local offset=0 g

  for ((g = 0; g < group_index; g++)); do
    offset=$((offset + group_counts[g]))
  done
  printf '%s' "$offset"
}

# Resolve a flat option index (0-based) to the group index that contains it.
_moma_multi_groups_group_of_flat_index() {
  local flat_index="$1"
  local num_groups="$2"
  shift 2
  local -a group_counts=("${@:1:$num_groups}")
  local group_index offset=0

  for group_index in "${!group_counts[@]}"; do
    if ((flat_index < offset + group_counts[group_index])); then
      printf '%s' "$group_index"
      return
    fi
    offset=$((offset + group_counts[group_index]))
  done
}

# Resolve a navigable row index to its kind: "selectall", "group
# <group_index>", or "option <flat_index>". Navigable rows are, in visual
# order, one Select All row, then per group one All row followed by its
# option rows.
_moma_multi_groups_resolve_row() {
  local row_index="$1"
  local num_groups="$2"
  shift 2
  local -a group_counts=("${@:1:$num_groups}")

  if ((row_index == 0)); then
    printf 'selectall'
    return
  fi

  local remaining=$((row_index - 1)) group_index block_size flat_offset=0
  for group_index in "${!group_counts[@]}"; do
    block_size=$((1 + group_counts[group_index]))
    if ((remaining < block_size)); then
      if ((remaining == 0)); then
        printf 'group %s' "$group_index"
      else
        printf 'option %s' "$((flat_offset + remaining - 1))"
      fi
      return
    fi
    remaining=$((remaining - block_size))
    flat_offset=$((flat_offset + group_counts[group_index]))
  done
}

# Resolve a grouped multiple-selection keyboard event to its next state.
# active_row and row_count span every navigable row: the Select All row,
# every group's All row, and every option row.
_moma_multi_select_groups_transition() {
  local active_row="$1"
  local selected_state="$2"
  local row_count="$3"
  local total_options="$4"
  local num_groups="$5"
  shift 5
  local -a group_counts=("${@:1:$num_groups}")
  shift "$num_groups"
  local event="$1"
  local result=continue

  case "$event" in
    up | k)
      active_row=$(((active_row - 1 + row_count) % row_count))
      ;;
    down | j)
      active_row=$(((active_row + 1) % row_count))
      ;;
    space)
      local resolved kind payload offset
      resolved="$(
        _moma_multi_groups_resolve_row "$active_row" "$num_groups" \
          "${group_counts[@]}"
      )"
      kind="${resolved%% *}"
      payload="${resolved#* }"
      case "$kind" in
        selectall)
          selected_state="$(
            _moma_multi_groups_toggle_range \
              "$selected_state" 0 "$total_options"
          )"
          ;;
        group)
          offset="$(
            _moma_multi_groups_group_offset "$payload" "$num_groups" \
              "${group_counts[@]}"
          )"
          selected_state="$(
            _moma_multi_groups_toggle_range \
              "$selected_state" "$offset" "${group_counts[$payload]}"
          )"
          ;;
        option)
          selected_state="$(_moma_multi_toggle "$selected_state" "$payload")"
          ;;
      esac
      ;;
    enter) result=confirm ;;
    cancel) result=cancel ;;
  esac

  printf '%s\t%s\t%s\n' "$active_row" "$selected_state" "$result"
}

# Parse grouped multiple-selection options and return chosen values on
# stdout, in original visual order. Option numbers are one-based, global,
# and exclude group headings and the Select All / All toggle rows.
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
Each group has a focusable "All" row above its options that toggles every option in that group, and a "Select All" row above every group toggles every option across all groups. Both fill when every option in their scope is selected, show a hatched glyph when only some are, and are never counted as options or printed on stdout.
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

  local num_groups="${#group_names[@]}"
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
  local initial_group_index
  initial_group_index="$(
    _moma_multi_groups_group_of_flat_index \
      "$active_index" "$num_groups" "${group_counts[@]}"
  )"
  local active_row=$((active_index + initial_group_index + 2))
  local row_count=$((1 + num_groups + total_options))

  if $choose_set; then
    if $required && [[ -z "$selected_state" ]]; then
      printf 'moma-multi-select-groups: select at least one option\n' >&2
      return 2
    fi
    _moma_render_multi_select_groups \
      "$title" "$active_row" "$selected_state" "$color" "$no_color" false \
      false "$num_groups" "${group_names[@]}" "${group_counts[@]}" \
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
    "$title" "$active_row" "$selected_state" "$color" "$no_color" false \
    true "$num_groups" "${group_names[@]}" "${group_counts[@]}" \
    "${options[@]}"

  local event transition remainder transition_status
  while true; do
    if ! _moma_term_read_key event; then
      printf '\n' >&2
      return 130
    fi

    transition="$(
      _moma_multi_select_groups_transition \
        "$active_row" "$selected_state" "$row_count" "$total_options" \
        "$num_groups" "${group_counts[@]}" "$event"
    )"
    active_row="${transition%%$'\t'*}"
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
      "$title" "$active_row" "$selected_state" "$color" "$no_color" true \
      true "$num_groups" "${group_names[@]}" "${group_counts[@]}" \
      "${options[@]}"
  done
}
