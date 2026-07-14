# ANSI palette and theme defaults.
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

MOMA_COLOR_SUCCESS="${MOMA_COLOR_SUCCESS:-$MOMA_COLOR_GREEN}"
MOMA_COLOR_ERROR="${MOMA_COLOR_ERROR:-$MOMA_COLOR_RED}"
MOMA_COLOR_WARNING="${MOMA_COLOR_WARNING:-$MOMA_COLOR_YELLOW}"
MOMA_COLOR_INFO="${MOMA_COLOR_INFO:-$MOMA_COLOR_CYAN}"
MOMA_COLOR_PRIMARY="${MOMA_COLOR_PRIMARY:-$MOMA_COLOR_CYAN}"
MOMA_COLOR_ACCENT="${MOMA_COLOR_ACCENT:-$MOMA_COLOR_YELLOW}"
MOMA_COLOR_MUTED="${MOMA_COLOR_MUTED:-$MOMA_COLOR_GRAY}"

_moma_trim () {
    local value="${1:-}"
    value="${value#"${value%%[!$' \t\r\n']*}"}"
    value="${value%"${value##*[!$' \t\r\n']}"}"
    printf '%s' "$value"
}

_moma_repeat_char () {
    local char="${1:-}"
    local count="${2:-0}"

    if [[ -z "$char" || ! "$count" =~ ^[0-9]+$ || "$count" -le 0 ]]; then
        return 0
    fi

    local output
    printf -v output '%*s' "$count" ''
    printf '%s' "${output// /$char}"
}

_moma_color_enabled () {
    [[ "${1:-false}" != "true" && -z "${NO_COLOR:-}" ]]
}

_moma_resolve_color () {
    local candidate="${1:-}"
    local fallback="${2:-$MOMA_COLOR_RESET}"
    local no_color="${3:-false}"

    _moma_color_enabled "$no_color" || return 0
    [[ -n "$candidate" ]] || candidate="$fallback"

    case "${candidate,,}" in
        black) printf '%s' "$MOMA_COLOR_BLACK" ;;
        red) printf '%s' "$MOMA_COLOR_RED" ;;
        green) printf '%s' "$MOMA_COLOR_GREEN" ;;
        yellow|warning|warn) printf '%s' "$MOMA_COLOR_YELLOW" ;;
        blue) printf '%s' "$MOMA_COLOR_BLUE" ;;
        purple) printf '%s' "$MOMA_COLOR_PURPLE" ;;
        cyan|info) printf '%s' "$MOMA_COLOR_CYAN" ;;
        white) printf '%s' "$MOMA_COLOR_WHITE" ;;
        pink) printf '%s' "$MOMA_COLOR_PINK" ;;
        gray|grey|muted) printf '%s' "$MOMA_COLOR_GRAY" ;;
        reset|default) printf '%s' "$MOMA_COLOR_RESET" ;;
        none|no|false) return 0 ;;
        *) printf '%s' "$candidate" ;;
    esac
}

_moma_reset_color () {
    if _moma_color_enabled "${1:-false}"; then
        printf '%s' "$MOMA_COLOR_RESET"
    fi
    return 0
}

_moma_semantic_color () {
    case "${1:-}" in
        success) printf '%s' "$MOMA_COLOR_SUCCESS" ;;
        error) printf '%s' "$MOMA_COLOR_ERROR" ;;
        warning) printf '%s' "$MOMA_COLOR_WARNING" ;;
        info) printf '%s' "$MOMA_COLOR_INFO" ;;
        *) return 1 ;;
    esac
}

_moma_semantic_icon () {
    case "${1:-}" in
        success) printf '✔' ;;
        error) printf '✖' ;;
        warning) printf '!' ;;
        info) printf '→' ;;
        *) return 1 ;;
    esac
}

_moma_apply_semantic_style () {
    local semantic="${1:-}"
    local color icon

    color="$(_moma_semantic_color "$semantic")" || return 1
    icon="$(_moma_semantic_icon "$semantic")" || return 1
    printf '%s\t%s\n' "$color" "$icon"
}

_moma_option_requires_value () {
    printf '%s: option %s requires a value\n' "$1" "$2" >&2
    return 1
}

_moma_unknown_option () {
    printf '%s: unknown option: %s\n' "$1" "$2" >&2
    return 1
}
