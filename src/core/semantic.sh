# Semantic roles resolved onto the physical palette.
MOMA_COLOR_SUCCESS="${MOMA_COLOR_SUCCESS:-$MOMA_COLOR_GREEN}"
MOMA_COLOR_ERROR="${MOMA_COLOR_ERROR:-$MOMA_COLOR_RED}"
MOMA_COLOR_WARNING="${MOMA_COLOR_WARNING:-$MOMA_COLOR_YELLOW}"
MOMA_COLOR_INFO="${MOMA_COLOR_INFO:-$MOMA_COLOR_CYAN}"

# Resolve a semantic variant to its configured color.
_moma_semantic_color() {
    case "${1:-}" in
        success) printf '%s' "$MOMA_COLOR_SUCCESS" ;;
        error) printf '%s' "$MOMA_COLOR_ERROR" ;;
        warning) printf '%s' "$MOMA_COLOR_WARNING" ;;
        info) printf '%s' "$MOMA_COLOR_INFO" ;;
        *) return 1 ;;
    esac
}

# Resolve a semantic variant to its display icon.
_moma_semantic_icon() {
    case "${1:-}" in
        success) printf '✔' ;;
        error) printf '✖' ;;
        warning) printf '!' ;;
        info) printf '→' ;;
        *) return 1 ;;
    esac
}

# Apply a semantic variant to color and icon variables by name.
_moma_apply_semantic_style() {
    local semantic="${1:-}"
    local color icon

    color="$(_moma_semantic_color "$semantic")" || return 1
    icon="$(_moma_semantic_icon "$semantic")" || return 1
    printf '%s\t%s\n' "$color" "$icon"
}
