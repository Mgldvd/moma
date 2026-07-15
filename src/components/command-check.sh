# Command availability component.
moma-command-check() {
    local quiet=false
    local no_color=false
    local -a commands=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet | -q)
                quiet=true
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-command-check <command>... [--quiet] [--no-color]

Returns 0 when every command is available and 1 when any command is missing.
EOF
                return 0
                ;;
            --)
                shift
                commands+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-command-check "$1"
                return 2
                ;;
            *)
                commands+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#commands[@]} -eq 0 ]]; then
        printf 'moma-command-check: provide at least one command\n' >&2
        return 2
    fi

    local command
    local status=0
    for command in "${commands[@]}"; do
        local -a message_args=()
        $no_color && message_args+=(--no-color)
        if command -v "$command" &>/dev/null; then
            $quiet || moma-msg-simple "$command is available" --success "${message_args[@]}"
        else
            $quiet || moma-msg-simple "$command is missing" --error "${message_args[@]}"
            status=1
        fi
    done

    return "$status"
}
