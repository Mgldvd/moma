# Shared rendering, state, and validation helpers for the selection family:
# moma-single-select, moma-single-select-groups, moma-multi-select, and
# moma-multi-select-groups.
# Render the shared title and horizontal rule above every selection menu.
_moma_select_render_header() {
  local title="$1"
  local color="$2"
  local no_color="$3"
  local redraw="$4"
  local active_color reset header_width

  active_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"
  header_width="$(_moma_resolve_decor_width "$((${#title} + 6))" 30 "" "" 8)"

  if $redraw; then _moma_term_clear_line; fi
  printf '  %b▪%b  %s\n' "$active_color" "$reset" "$title" >&2

  if $redraw; then _moma_term_clear_line; fi
  printf '  %b└%s%b\n' \
    "$active_color" "$(_moma_repeat_char "─" "$header_width")" \
    "$reset" >&2
}

# Render one selectable row with a focus pointer and a state glyph.
_moma_select_render_row() {
  local active="$1"
  local glyph="$2"
  local text="$3"
  local color="$4"
  local no_color="$5"
  local redraw="$6"
  local active_color reset pointer=" "

  if $redraw; then _moma_term_clear_line; fi

  if $active; then
    pointer="›"
    active_color="$(
      _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
    )"
    reset="$(_moma_reset_color "$no_color")"
    printf '  %b%s %s %s%b\n' \
      "$active_color" "$pointer" "$glyph" "$text" "$reset" >&2
  else
    printf '  %s %s %s\n' "$pointer" "$glyph" "$text" >&2
  fi
}

# Render one blank separator line before a group heading.
_moma_select_render_blank() {
  local redraw="$1"
  if $redraw; then _moma_term_clear_line; fi
  printf '\n' >&2
}

# Render a non-selectable group heading line.
_moma_select_render_group_heading() {
  local name="$1"
  local redraw="$2"
  if $redraw; then _moma_term_clear_line; fi
  printf '    %s\n' "$name" >&2
}

# Render the trailing keyboard-control hint line.
_moma_select_render_footer() {
  local text="$1"
  local redraw="$2"
  if $redraw; then _moma_term_clear_line; fi
  printf '  %s\n' "$text" >&2
}

# Resolve a single-selection keyboard event to its next state. Reused by both
# the flat and grouped single-selection components: grouped options are
# already flattened into one selectable list before this helper ever runs.
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

# Resolve a multiple-selection keyboard event to its next state. Reused by
# both the flat and grouped multi-selection components for the same reason.
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

# Print selected multiple-choice values on stdout, in original visual order.
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

# Validate that every already-declared group has at least one option. Callers
# must confirm at least one group exists before calling this helper.
_moma_validate_groups() {
  local context="$1"
  shift
  local -a group_counts=("$@")
  local count

  for count in "${group_counts[@]}"; do
    if ((count == 0)); then
      printf '%s: every group requires at least one --option\n' \
        "$context" >&2
      return 2
    fi
  done
}
