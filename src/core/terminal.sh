# Terminal operations.
# Every helper is a no-op when the selected channel is not a TTY.
# Return success when a file descriptor is attached to a terminal.
_moma_term_is_tty() {
    local fd="${1:-2}"
    [[ -t "$fd" ]]
}

# Print the terminal width or a supplied fallback width.
_moma_term_width() {
    local fallback="${1:-80}"
    local width="${COLUMNS:-}"
    if ! _moma_is_positive_int "$width" && command -v tput &>/dev/null; then
        width="$(tput cols 2>/dev/null || true)"
    fi
    _moma_is_positive_int "$fallback" || fallback=80
    _moma_is_positive_int "$width" || width="$fallback"
    printf '%s' "$width"
}

# Hide the cursor on a terminal output channel.
_moma_term_hide_cursor() {
    _moma_term_is_tty 2 || return 0
    printf '\033[?25l' >&2
}

# Restore the cursor on a terminal output channel.
_moma_term_show_cursor() {
    _moma_term_is_tty 2 || return 0
    printf '\033[?25h' >&2
}

# Clear the current terminal line.
_moma_term_clear_line() {
    _moma_term_is_tty 2 || return 0
    printf '\033[2K\r' >&2
}

# Move the cursor upward by a requested number of terminal lines.
_moma_term_move_up() {
    local count="${1:-1}"
    _moma_term_is_tty 2 || return 0
    _moma_is_positive_int "$count" || return 0
    printf '\033[%dA' "$count" >&2
}

# Read one normalized keyboard event from a terminal.
_moma_term_read_key() {
    local target_var="$1"
    local raw=""
    local sequence=""

    if ! IFS= read -r -s -n 1 raw; then
        printf -v "$target_var" '%s' cancel
        return 130
    fi

    case "$raw" in
        "") raw=enter ;;
        " ") raw=space ;;
        q | Q) raw=cancel ;;
        $'\033')
            IFS= read -r -s -n 2 -t 0.1 sequence || true
            case "$sequence" in
                '[A') raw=up ;;
                '[B') raw=down ;;
                *) raw=cancel ;;
            esac
            ;;
    esac

    printf -v "$target_var" '%s' "$raw"
}
