# Single-selection component split across named, non-selectable groups.
# Render a single-selection menu split across named groups from normalized
# arguments. Group headings are display-only and never receive focus.
_moma_render_single_select_groups() {
  local title="$1"
  local selected_index="$2"
  local color="$3"
  local no_color="$4"
  local redraw="$5"
  local num_groups="$6"
  shift 6
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
      glyph="○"
      active=false
      if ((flat_index == selected_index)); then
        glyph="◉"
        active=true
      fi
      _moma_select_render_row \
        "$active" "$glyph" "${options[$flat_index]}" \
        "$color" "$no_color" "$redraw"
    done
    offset=$((offset + group_counts[group_index]))
  done

  _moma_select_render_footer \
    "↑/↓ move · Enter select · q cancel" "$redraw"
}

# Parse grouped single-selection options and return the chosen value on
# stdout. Option numbers are one-based, global, and exclude group headings.
moma-single-select-groups() {
  local title="Select an option"
  local color="$MOMA_COLOR_PRIMARY"
  local initial=1
  local choose=""
  local no_color=false
  local -a group_names=()
  local -a group_counts=()
  local -a options=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-single-select-groups "$1"
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
          _moma_option_requires_value moma-single-select-groups "$1"
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
          _moma_option_requires_value moma-single-select-groups "$1"
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
          _moma_option_requires_value moma-single-select-groups "$1"
          return 2
        fi
        choose="$2"
        shift 2
        ;;
      --choose=*)
        choose="${1#*=}"
        shift
        ;;
      --group)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-single-select-groups "$1"
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
          _moma_option_requires_value moma-single-select-groups "$1"
          return 2
        fi
        if ((${#group_names[@]} == 0)); then
          printf 'moma-single-select-groups: %s\n' \
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
          printf 'moma-single-select-groups: %s\n' \
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
Usage: moma-single-select-groups --title <text> (--group <name> --option <value>...)... [--initial <number>] [--choose <number>] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Enter to select, and q or Escape to cancel.
Group headings are display-only: they never receive focus and are never printed on stdout.
Option numbers are one-based, count only options, and follow visual order across every group.
--choose selects immediately for scripts and tests.
EOF
        return 0
        ;;
      -*)
        _moma_unknown_option moma-single-select-groups "$1"
        return 2
        ;;
      *)
        printf 'moma-single-select-groups: unexpected argument: %s\n' "$1" >&2
        return 2
        ;;
    esac
  done

  if ((${#group_names[@]} == 0)); then
    printf 'moma-single-select-groups: provide at least one --group\n' >&2
    return 2
  fi
  _moma_validate_groups moma-single-select-groups "${group_counts[@]}" ||
    return 2

  local total_options="${#options[@]}"
  if ! _moma_is_index_in_range "$initial" "$total_options"; then
    printf 'moma-single-select-groups: invalid initial option: %s\n' \
      "$initial" >&2
    return 2
  fi
  if [[ -n "$choose" ]] &&
    ! _moma_is_index_in_range "$choose" "$total_options"; then
    printf 'moma-single-select-groups: invalid chosen option: %s\n' \
      "$choose" >&2
    return 2
  fi

  local selected_index=$((initial - 1))
  if [[ -n "$choose" ]]; then
    selected_index=$((choose - 1))
    _moma_render_single_select_groups \
      "$title" "$selected_index" "$color" "$no_color" false \
      "${#group_names[@]}" "${group_names[@]}" "${group_counts[@]}" \
      "${options[@]}"
    printf '\n' >&2
    printf '%s\n' "${options[$selected_index]}"
    return 0
  fi

  if [[ ! -t 0 || ! -t 2 ]]; then
    printf '%s%s\n' \
      'moma-single-select-groups: interactive input requires a terminal; ' \
      'use --choose <number> for automation' >&2
    return 2
  fi

  _moma_render_single_select_groups \
    "$title" "$selected_index" "$color" "$no_color" false \
    "${#group_names[@]}" "${group_names[@]}" "${group_counts[@]}" \
    "${options[@]}"

  local event transition transition_status
  while true; do
    if ! _moma_term_read_key event; then
      printf '\n' >&2
      return 130
    fi

    transition="$(
      _moma_select_transition "$selected_index" "$total_options" "$event"
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

    _moma_render_single_select_groups \
      "$title" "$selected_index" "$color" "$no_color" true \
      "${#group_names[@]}" "${group_names[@]}" "${group_counts[@]}" \
      "${options[@]}"
  done
}
