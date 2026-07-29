# Compact message and list components.
# Render one compact marker-and-text line.
_moma_render_dot_line() {
    local text="${1:-}"
    local marker="${2:-▪}"
    local color="${3:-$MOMA_COLOR_PRIMARY}"
    local no_color="${4:-false}"
    local color_code reset

    color_code="$(_moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"
    printf '  %b%s%b   %s\n' "$color_code" "$marker" "$reset" "$text"
}

# Resolve and validate a compact component's semantic color.
_moma_dot_semantic_color() {
    local function_name="$1"
    local variant="$2"
    local semantic_color

    if ! semantic_color="$(_moma_semantic_color "$variant")"; then
        printf '%s: invalid semantic variant: %s\n' "$function_name" "$variant" >&2
        return 1
    fi

    printf '%s' "$semantic_color"
}

# Parse compact-message options and print one message.
moma-msg-simple() {
    local color="$MOMA_COLOR_PRIMARY"
    local marker="▪"
    local no_color=false
    local -a message=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --success | --error | --warning | --info)
                color="$(
                    _moma_dot_semantic_color moma-msg-simple "${1#--}"
                )" || return 1
                shift
                ;;
            --color | -c)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-msg-simple "$1"
                    return 1
                fi
                color="$2"
                shift 2
                ;;
            --color=*)
                color="${1#*=}"
                shift
                ;;
            --marker | -m)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-msg-simple "$1"
                    return 1
                fi
                marker="$2"
                shift 2
                ;;
            --marker=*)
                marker="${1#*=}"
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-msg-simple ["message"] [--success|--error|--warning|--info] [--color <color>] [--marker <marker>] [--no-color]
EOF
                return 0
                ;;
            --)
                shift
                message+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-msg-simple "$1"
                return 1
                ;;
            *)
                message+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#message[@]} -eq 0 ]]; then
        return 0
    fi

    _moma_render_dot_line "${message[*]}" "$marker" "$color" "$no_color"
}

# Parse list options and print each item with a marker.
moma-list() {
    local color="$MOMA_COLOR_PRIMARY"
    local marker="▪"
    local no_color=false
    local -a items=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --success | --error | --warning | --info)
                color="$(_moma_dot_semantic_color moma-list "${1#--}")" || return 1
                shift
                ;;
            --color | -c)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-list "$1"
                    return 1
                fi
                color="$2"
                shift 2
                ;;
            --color=*)
                color="${1#*=}"
                shift
                ;;
            --marker | -m)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-list "$1"
                    return 1
                fi
                marker="$2"
                shift 2
                ;;
            --marker=*)
                marker="${1#*=}"
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-list ["item" ...] [--success|--error|--warning|--info] [--color <color>] [--marker <marker>] [--no-color]
EOF
                return 0
                ;;
            --)
                shift
                items+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-list "$1"
                return 1
                ;;
            *)
                items+=("$1")
                shift
                ;;
        esac
    done

    local item
    for item in "${items[@]}"; do
        _moma_render_dot_line "$item" "$marker" "$color" "$no_color"
    done
}
