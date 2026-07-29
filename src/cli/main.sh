# Explicit CLI dispatcher.
# Dispatch one CLI command without evaluating registry data.
_moma_main() {
    local command="${1:-}"
    local registered_function=""
    if [[ $# -gt 0 ]]; then
        shift
    fi

    case "$command" in
        "" | -h | --help | help)
            _moma_usage
            return $?
            ;;
        preview)
            _moma_preview "$@"
            return $?
            ;;
    esac

    if ! registered_function="$(_moma_command_function "$command")"; then
        printf 'moma: unknown command: %s\n\n' "$command" >&2
        _moma_usage >&2
        return 1
    fi

    # Keep dispatch explicit. The registry validates metadata; no input is
    # evaluated or expanded into a command name.
    case "$command" in
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
        *)
            _moma_runtime_error \
                moma \
                "registered command has no dispatcher: $registered_function"
            ;;
    esac
}
