_moma_usage_plain () {
    cat <<'EOF'
Moma - terminal UI components for Bash

Usage:
  moma <command> [arguments] [options]
  source dist/moma

Commands:
  title, title-sub, section, msg, msg-simple, list, box, prompt, label, input, select, multi-select, rabbit
  confirm, spinner, command-check
  preview

Options:
  -h, --help       Show this help.
  -v, --version    Show the Moma version.

Library example:
  source dist/moma
  moma-msg "Ready" --success

Binary example:
  ./dist/moma msg "Ready" --success
EOF
}

_moma_usage () {
    local width="${MOMA_HELP_WIDTH:-${COLUMNS:-100}}"

    if [[ ! "$width" =~ ^[0-9]+$ ]] || (( width < 20 )); then
        width=100
    fi

    if command -v glow &>/dev/null; then
        if _moma_help_markdown | glow -w "$width" -; then
            return 0
        fi
    fi

    _moma_usage_plain
}

_moma_main () {
    local command="${1:-}"
    if [[ $# -gt 0 ]]; then
        shift
    fi

    case "$command" in
        ""|-h|--help|help) _moma_usage ;;
        -v|--version|version) printf 'moma %s\n' "$MOMA_VERSION" ;;
        title) moma-title "$@" ;;
        title-sub) moma-title-sub "$@" ;;
        section) moma-section "$@" ;;
        msg) moma-msg "$@" ;;
        msg-simple) moma-msg-simple "$@" ;;
        list) moma-list "$@" ;;
        box) moma-box "$@" ;;
        prompt) moma-prompt "$@" ;;
        label) moma-label "$@" ;;
        input) moma-input "$@" ;;
        select) moma-select "$@" ;;
        multi-select) moma-multi-select "$@" ;;
        rabbit) moma-rabbit "$@" ;;
        confirm) moma-confirm "$@" ;;
        spinner) moma-spinner "$@" ;;
        command-check) moma-command-check "$@" ;;
        preview) _moma_preview "$@" ;;
        *)
            printf 'moma: unknown command: %s\n\n' "$command" >&2
            _moma_usage >&2
            return 1
            ;;
    esac
}
