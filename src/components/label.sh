# Label component.
_moma_render_label() {
    local text="$1"
    local width="${2:-40}"
    local color="${3:-$MOMA_COLOR_PRIMARY}"
    local icon="${4:-}"
    local no_color="${5:-false}"

    local label="$text"
    if [[ -n "$icon" && -n "$label" ]]; then
        label="$icon $label"
    elif [[ -n "$icon" ]]; then
        label="$icon"
    fi

    if [[ ! "$width" =~ ^[0-9]+$ ]]; then
        printf 'moma-label: invalid width: %s\n' "$width" >&2
        return 1
    fi
    if ((width < 20)); then
        width=20
    fi
    if ((${#label} + 4 > width)); then
        width=$((${#label} + 4))
    fi

    local dash_count resolved_color reset
    dash_count=$((width - ${#label} - 3))
    resolved_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"

    printf '%b  ┌─ %s %s┐%b\n\n' \
        "$resolved_color" "$label" "$(_moma_repeat_char "─" "$dash_count")" "$reset"
}

moma-label() {
    local text=""
    local width=40
    local color="$MOMA_COLOR_PRIMARY"
    local icon=""
    local no_color=false
    local -a positional=()
    local style

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --width)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-label "$1"
                    return 1
                fi
                width="$2"
                shift 2
                ;;
            --width=*)
                width="${1#*=}"
                shift
                ;;
            --color | -c)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-label "$1"
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
                    _moma_option_requires_value moma-label "$1"
                    return 1
                fi
                icon="$2"
                shift 2
                ;;
            --icon=*)
                icon="${1#*=}"
                shift
                ;;
            --success | --error | --warning | --info)
                style="$(_moma_apply_semantic_style "${1#--}")"
                color="${style%%$'\t'*}"
                icon="${style#*$'\t'}"
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-label "<text>" [--width <number>] [--color <color>] [--icon <symbol>] [--success|--error|--warning|--info] [--no-color]
EOF
                return 0
                ;;
            --)
                shift
                positional+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-label "$1"
                return 1
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    text="${positional[*]}"
    _moma_render_label "$text" "$width" "$color" "$icon" "$no_color"
}
