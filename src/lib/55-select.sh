_moma_render_select () {
    local title="$1"
    local selected_index="$2"
    local color="$3"
    local no_color="$4"
    local redraw="$5"
    shift 5
    local -a options=("$@")
    local marker="▪"

    local active_color reset header_width
    active_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"
    header_width=$(( ${#title} + 6 > 30 ? ${#title} + 6 : 30 ))

    if $redraw; then
        printf '\033[%dA' "$(( ${#options[@]} + 3 ))" >&2
    fi

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  %b▪%b  %s\n' "$active_color" "$reset" "$title" >&2

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  %b└%s%b\n' "$active_color" "$(_moma_repeat_char "─" "$header_width")" "$reset" >&2

    local index
    for index in "${!options[@]}"; do
        if $redraw; then printf '\033[2K\r' >&2; fi
        if (( index == selected_index )); then
            printf '  %b%s%b %s\n' "$active_color" "$marker" "$reset" "${options[$index]}" >&2
        else
            printf '    %s\n' "${options[$index]}" >&2
        fi
    done

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  ↑/↓ move · Enter select · q cancel\n' >&2
}

moma-select () {
    local title="Select an option"
    local color="$MOMA_COLOR_PRIMARY"
    local initial=1
    local choose=""
    local no_color=false
    local -a options=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-select "$1"; return 2; fi
                title="$2"; shift 2 ;;
            --title=*) title="${1#*=}"; shift ;;
            --color|-c)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-select "$1"; return 2; fi
                color="$2"; shift 2 ;;
            --color=*) color="${1#*=}"; shift ;;
            --initial)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-select "$1"; return 2; fi
                initial="$2"; shift 2 ;;
            --initial=*) initial="${1#*=}"; shift ;;
            --choose)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-select "$1"; return 2; fi
                choose="$2"; shift 2 ;;
            --choose=*) choose="${1#*=}"; shift ;;
            --no-color) no_color=true; shift ;;
            --help|-h)
                cat <<'EOF'
Usage: moma-select "option"... [--title <text>] [--initial <number>] [--choose <number>] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Enter to select, and q or Escape to cancel.
Option numbers are one-based. --choose selects immediately for scripts and tests.
EOF
                return 0 ;;
            --) shift; options+=("$@"); break ;;
            -*) _moma_unknown_option moma-select "$1"; return 2 ;;
            *) options+=("$1"); shift ;;
        esac
    done

    if [[ ${#options[@]} -eq 0 ]]; then
        printf 'moma-select: provide at least one option\n' >&2
        return 2
    fi
    if [[ ! "$initial" =~ ^[0-9]+$ ]] || (( initial < 1 || initial > ${#options[@]} )); then
        printf 'moma-select: invalid initial option: %s\n' "$initial" >&2
        return 2
    fi
    if [[ -n "$choose" ]] && { [[ ! "$choose" =~ ^[0-9]+$ ]] || (( choose < 1 || choose > ${#options[@]} )); }; then
        printf 'moma-select: invalid chosen option: %s\n' "$choose" >&2
        return 2
    fi

    local selected_index=$((initial - 1))
    if [[ -n "$choose" ]]; then
        selected_index=$((choose - 1))
        _moma_render_select "$title" "$selected_index" "$color" "$no_color" false "${options[@]}"
        printf '\n' >&2
        printf '%s\n' "${options[$selected_index]}"
        return 0
    fi

    if [[ ! -t 0 || ! -t 2 ]]; then
        printf 'moma-select: interactive input requires a terminal; use --choose <number> for automation\n' >&2
        return 2
    fi

    _moma_render_select "$title" "$selected_index" "$color" "$no_color" false "${options[@]}"

    local key sequence
    while true; do
        if ! IFS= read -r -s -n 1 key; then
            printf '\n' >&2
            return 130
        fi

        case "$key" in
            "")
                printf '\n' >&2
                printf '%s\n' "${options[$selected_index]}"
                return 0
                ;;
            $'\033')
                sequence=""
                IFS= read -r -s -n 2 -t 0.1 sequence || true
                case "$sequence" in
                    '[A') selected_index=$(( (selected_index - 1 + ${#options[@]}) % ${#options[@]} )) ;;
                    '[B') selected_index=$(( (selected_index + 1) % ${#options[@]} )) ;;
                    *) printf '\n' >&2; return 130 ;;
                esac
                ;;
            k) selected_index=$(( (selected_index - 1 + ${#options[@]}) % ${#options[@]} )) ;;
            j) selected_index=$(( (selected_index + 1) % ${#options[@]} )) ;;
            q) printf '\n' >&2; return 130 ;;
            *) continue ;;
        esac

        _moma_render_select "$title" "$selected_index" "$color" "$no_color" true "${options[@]}"
    done
}

_moma_render_multi_select () {
    local title="$1"
    local active_index="$2"
    local color="$3"
    local no_color="$4"
    local redraw="$5"
    shift 5
    local -a options=("$@")

    local active_color reset checkbox pointer header_width
    active_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"
    header_width=$(( ${#title} + 6 > 30 ? ${#title} + 6 : 30 ))

    if $redraw; then
        printf '\033[%dA' "$(( ${#options[@]} + 3 ))" >&2
    fi

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  %b▪%b  %s\n' "$active_color" "$reset" "$title" >&2

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  %b└%s%b\n' "$active_color" "$(_moma_repeat_char "─" "$header_width")" "$reset" >&2

    local index
    for index in "${!options[@]}"; do
        if $redraw; then printf '\033[2K\r' >&2; fi
        checkbox="▢"
        [[ -z "${selected_indices[$index]+x}" ]] || checkbox="▣"
        pointer=" "
        (( index != active_index )) || pointer="›"

        if (( index == active_index )); then
            printf '  %b%s %s %s%b\n' "$active_color" "$pointer" "$checkbox" "${options[$index]}" "$reset" >&2
        else
            printf '  %s %s %s\n' "$pointer" "$checkbox" "${options[$index]}" >&2
        fi
    done

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  ↑/↓ move · Space toggle · Enter confirm · q cancel\n' >&2
}

_moma_emit_multi_select () {
    local -a options=("$@")
    local index

    for index in "${!options[@]}"; do
        if [[ -n "${selected_indices[$index]+x}" ]]; then
            printf '%s\n' "${options[$index]}"
        fi
    done
}

moma-multi-select () {
    local title="Select options"
    local color="$MOMA_COLOR_PRIMARY"
    local initial=1
    local selected_spec=""
    local choose_spec=""
    local choose_set=false
    local required=false
    local no_color=false
    local -a options=()
    local -A selected_indices=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-multi-select "$1"; return 2; fi
                title="$2"; shift 2 ;;
            --title=*) title="${1#*=}"; shift ;;
            --color|-c)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-multi-select "$1"; return 2; fi
                color="$2"; shift 2 ;;
            --color=*) color="${1#*=}"; shift ;;
            --initial)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-multi-select "$1"; return 2; fi
                initial="$2"; shift 2 ;;
            --initial=*) initial="${1#*=}"; shift ;;
            --selected)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-multi-select "$1"; return 2; fi
                selected_spec="$2"; shift 2 ;;
            --selected=*) selected_spec="${1#*=}"; shift ;;
            --choose)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-multi-select "$1"; return 2; fi
                choose_spec="$2"; choose_set=true; shift 2 ;;
            --choose=*) choose_spec="${1#*=}"; choose_set=true; shift ;;
            --required) required=true; shift ;;
            --no-color) no_color=true; shift ;;
            --help|-h)
                cat <<'EOF'
Usage: moma-multi-select "option"... [--title <text>] [--initial <number>] [--selected <numbers>] [--choose <numbers>] [--required] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Space to toggle, Enter to confirm, and q or Escape to cancel.
Number lists are one-based and comma-separated. --choose selects immediately for scripts and tests.
Each selected value is printed on its own line.
EOF
                return 0 ;;
            --) shift; options+=("$@"); break ;;
            -*) _moma_unknown_option moma-multi-select "$1"; return 2 ;;
            *) options+=("$1"); shift ;;
        esac
    done

    if [[ ${#options[@]} -eq 0 ]]; then
        printf 'moma-multi-select: provide at least one option\n' >&2
        return 2
    fi
    if [[ ! "$initial" =~ ^[0-9]+$ ]] || (( initial < 1 || initial > ${#options[@]} )); then
        printf 'moma-multi-select: invalid initial option: %s\n' "$initial" >&2
        return 2
    fi

    local selection_spec="$selected_spec"
    $choose_set && selection_spec="$choose_spec"
    if [[ -n "$selection_spec" ]]; then
        local -a requested_indices=()
        local requested_index normalized_index
        IFS=',' read -r -a requested_indices <<< "$selection_spec"
        for requested_index in "${requested_indices[@]}"; do
            normalized_index="$(_moma_trim "$requested_index")"
            if [[ ! "$normalized_index" =~ ^[0-9]+$ ]] || (( normalized_index < 1 || normalized_index > ${#options[@]} )); then
                printf 'moma-multi-select: invalid option number: %s\n' "$requested_index" >&2
                return 2
            fi
            selected_indices[$((normalized_index - 1))]=1
        done
    fi

    local active_index=$((initial - 1))
    if $choose_set; then
        if $required && (( ${#selected_indices[@]} == 0 )); then
            printf 'moma-multi-select: select at least one option\n' >&2
            return 2
        fi
        _moma_render_multi_select "$title" "$active_index" "$color" "$no_color" false "${options[@]}"
        printf '\n' >&2
        _moma_emit_multi_select "${options[@]}"
        return 0
    fi

    if [[ ! -t 0 || ! -t 2 ]]; then
        printf 'moma-multi-select: interactive input requires a terminal; use --choose <numbers> for automation\n' >&2
        return 2
    fi

    _moma_render_multi_select "$title" "$active_index" "$color" "$no_color" false "${options[@]}"

    local key sequence
    while true; do
        if ! IFS= read -r -s -n 1 key; then
            printf '\n' >&2
            return 130
        fi

        case "$key" in
            "")
                if $required && (( ${#selected_indices[@]} == 0 )); then
                    printf '\a' >&2
                    continue
                fi
                printf '\n' >&2
                _moma_emit_multi_select "${options[@]}"
                return 0
                ;;
            " ")
                if [[ -n "${selected_indices[$active_index]+x}" ]]; then
                    unset 'selected_indices[$active_index]'
                else
                    selected_indices[$active_index]=1
                fi
                ;;
            $'\033')
                sequence=""
                IFS= read -r -s -n 2 -t 0.1 sequence || true
                case "$sequence" in
                    '[A') active_index=$(( (active_index - 1 + ${#options[@]}) % ${#options[@]} )) ;;
                    '[B') active_index=$(( (active_index + 1) % ${#options[@]} )) ;;
                    *) printf '\n' >&2; return 130 ;;
                esac
                ;;
            k) active_index=$(( (active_index - 1 + ${#options[@]}) % ${#options[@]} )) ;;
            j) active_index=$(( (active_index + 1) % ${#options[@]} )) ;;
            q) printf '\n' >&2; return 130 ;;
            *) continue ;;
        esac

        _moma_render_multi_select "$title" "$active_index" "$color" "$no_color" true "${options[@]}"
    done
}
