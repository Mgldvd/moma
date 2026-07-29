# Physical ANSI palette and component theme defaults.
MOMA_COLOR_RESET="${MOMA_COLOR_RESET:-\033[0m}"
MOMA_COLOR_BLACK="${MOMA_COLOR_BLACK:-\033[30m}"
MOMA_COLOR_RED="${MOMA_COLOR_RED:-\033[31m}"
MOMA_COLOR_GREEN="${MOMA_COLOR_GREEN:-\033[32m}"
MOMA_COLOR_YELLOW="${MOMA_COLOR_YELLOW:-\033[33m}"
MOMA_COLOR_BLUE="${MOMA_COLOR_BLUE:-\033[34m}"
MOMA_COLOR_PURPLE="${MOMA_COLOR_PURPLE:-\033[35m}"
MOMA_COLOR_CYAN="${MOMA_COLOR_CYAN:-\033[36m}"
MOMA_COLOR_WHITE="${MOMA_COLOR_WHITE:-\033[37m}"
MOMA_COLOR_PINK="${MOMA_COLOR_PINK:-\033[38;2;255;144;231m}"
MOMA_COLOR_GRAY="${MOMA_COLOR_GRAY:-\033[38;2;200;200;200m}"

MOMA_STYLE_WHITE_BOLD="${MOMA_STYLE_WHITE_BOLD:-\033[1;37m}"
MOMA_STYLE_CYAN_BOLD="${MOMA_STYLE_CYAN_BOLD:-\033[1;36m}"

MOMA_COLOR_PRIMARY="${MOMA_COLOR_PRIMARY:-$MOMA_COLOR_CYAN}"
MOMA_COLOR_ACCENT="${MOMA_COLOR_ACCENT:-$MOMA_COLOR_YELLOW}"
MOMA_COLOR_MUTED="${MOMA_COLOR_MUTED:-$MOMA_COLOR_GRAY}"

# Return success when colored output is enabled.
_moma_color_enabled() {
    [[ "${1:-false}" != "true" && -z "${NO_COLOR:-}" ]]
}

# Resolve a named or literal color while honoring color suppression.
_moma_resolve_color() {
    local candidate="${1:-}"
    local fallback="${2:-$MOMA_COLOR_RESET}"
    local no_color="${3:-false}"

    _moma_color_enabled "$no_color" || return 0
    [[ -n "$candidate" ]] || candidate="$fallback"

    case "${candidate,,}" in
        black) printf '%s' "$MOMA_COLOR_BLACK" ;;
        red) printf '%s' "$MOMA_COLOR_RED" ;;
        green) printf '%s' "$MOMA_COLOR_GREEN" ;;
        yellow | warning | warn) printf '%s' "$MOMA_COLOR_YELLOW" ;;
        blue) printf '%s' "$MOMA_COLOR_BLUE" ;;
        purple) printf '%s' "$MOMA_COLOR_PURPLE" ;;
        cyan | info) printf '%s' "$MOMA_COLOR_CYAN" ;;
        white) printf '%s' "$MOMA_COLOR_WHITE" ;;
        pink) printf '%s' "$MOMA_COLOR_PINK" ;;
        gray | grey | muted) printf '%s' "$MOMA_COLOR_GRAY" ;;
        reset | default) printf '%s' "$MOMA_COLOR_RESET" ;;
        none | no | false) return 0 ;;
        *) printf '%s' "$candidate" ;;
    esac
}

# Print the reset sequence when colored output is enabled.
_moma_reset_color() {
    if _moma_color_enabled "${1:-false}"; then
        printf '%s' "$MOMA_COLOR_RESET"
    fi
    return 0
}
