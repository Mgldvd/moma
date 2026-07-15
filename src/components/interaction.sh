# Confirmation and spinner components.
_moma_render_confirm() {
    local question="$1"
    local selected_index="$2"
    local color="$3"
    local no_color="$4"
    local redraw="$5"

    local active_color reset selected_answer prompt_text box_width
    active_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_WARNING" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"
    if ((selected_index == 0)); then selected_answer=yes; else selected_answer=no; fi
    prompt_text="$question [$selected_answer]"
    box_width=$((${#prompt_text} + 6 > 30 ? ${#prompt_text} + 6 : 30))

    if $redraw; then _moma_term_move_up 6; fi
    if $redraw; then _moma_term_clear_line; fi
    printf '%b\n' "$active_color" >&2

    if $redraw; then _moma_term_clear_line; fi
    printf '  ▪  %b%s%b\n' "$reset" "$prompt_text" "$active_color" >&2

    if $redraw; then _moma_term_clear_line; fi
    printf '  └%s%b\n' "$(_moma_repeat_char "─" "$box_width")" "$reset" >&2

    if $redraw; then _moma_term_clear_line; fi
    if ((selected_index == 0)); then
        printf '  %b▪%b Yes\n' "$active_color" "$reset" >&2
    else
        printf '    Yes\n' >&2
    fi

    if $redraw; then _moma_term_clear_line; fi
    if ((selected_index == 1)); then
        printf '  %b▪%b No\n' "$active_color" "$reset" >&2
    else
        printf '    No\n' >&2
    fi

    if $redraw; then _moma_term_clear_line; fi
    printf '  ↑/↓ move · Enter confirm · y yes · n no\n' >&2
}

_moma_confirm_transition() {
    local selected_index="$1"
    local event="$2"
    local result=continue

    case "$event" in
        up | down | j | k) selected_index=$((1 - selected_index)) ;;
        y | Y)
            selected_index=0
            result=confirm
            ;;
        n | N)
            selected_index=1
            result=confirm
            ;;
        enter) result=confirm ;;
        cancel) result=cancel ;;
    esac

    printf '%s\t%s\n' "$selected_index" "$result"
}

moma-confirm() {
    local question=""
    local default_answer="yes"
    local supplied_answer=""
    local color="$MOMA_COLOR_WARNING"
    local no_color=false
    local -a positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --default)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-confirm "$1"
                    return 2
                fi
                default_answer="${2,,}"
                shift 2
                ;;
            --default=*)
                default_answer="${1#*=}"
                default_answer="${default_answer,,}"
                shift
                ;;
            --answer)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-confirm "$1"
                    return 2
                fi
                supplied_answer="${2,,}"
                shift 2
                ;;
            --answer=*)
                supplied_answer="${1#*=}"
                supplied_answer="${supplied_answer,,}"
                shift
                ;;
            --color | -c)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-confirm "$1"
                    return 2
                fi
                color="$2"
                shift 2
                ;;
            --color=*)
                color="${1#*=}"
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-confirm "<question>" [--default yes|no] [--answer yes|no] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Enter to confirm, y for yes, n for no, and q or Escape to cancel.
Returns 0 for yes, 1 for no, 2 for invalid input, and 130 for cancellation.
EOF
                return 0
                ;;
            --)
                shift
                positional+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-confirm "$1"
                return 2
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    question="${positional[*]}"
    case "$default_answer" in
        y | yes) default_answer=yes ;;
        n | no) default_answer=no ;;
        *)
            printf 'moma-confirm: invalid default answer: %s\n' "$default_answer" >&2
            return 2
            ;;
    esac

    local selected_index=0
    [[ "$default_answer" == yes ]] || selected_index=1

    if [[ -n "$supplied_answer" ]]; then
        case "$supplied_answer" in
            y | yes) selected_index=0 ;;
            n | no) selected_index=1 ;;
            *)
                printf 'moma-confirm: invalid answer: %s\n' "$supplied_answer" >&2
                return 2
                ;;
        esac
        _moma_render_confirm "$question" "$selected_index" "$color" "$no_color" false
        printf '\n' >&2
        return "$selected_index"
    fi

    _moma_render_confirm "$question" "$selected_index" "$color" "$no_color" false

    if [[ ! -t 0 || ! -t 2 ]]; then
        local response
        while true; do
            printf '  y/n: ' >&2
            IFS= read -r response || return 2
            [[ -t 0 ]] || printf '\n' >&2
            response="${response,,}"
            [[ -n "$response" ]] || response="$default_answer"
            case "$response" in
                y | yes)
                    printf '\n' >&2
                    return 0
                    ;;
                n | no)
                    printf '\n' >&2
                    return 1
                    ;;
                *) printf '  Enter y or n.\n' >&2 ;;
            esac
        done
    fi

    local event transition transition_status
    while true; do
        if ! _moma_term_read_key event; then
            printf '\n' >&2
            return 130
        fi

        transition="$(_moma_confirm_transition "$selected_index" "$event")"
        selected_index="${transition%%$'\t'*}"
        transition_status="${transition#*$'\t'}"
        case "$transition_status" in
            confirm)
                _moma_render_confirm "$question" "$selected_index" "$color" "$no_color" true
                printf '\n' >&2
                return "$selected_index"
                ;;
            cancel)
                printf '\n' >&2
                return 130
                ;;
        esac

        _moma_render_confirm "$question" "$selected_index" "$color" "$no_color" true
    done
}

_moma_spinner_follow() (
    local pid="$1"
    local message="$2"
    local delay="$3"
    local no_color="$4"
    local frames="|/-\\"
    local frame=0
    local color reset

    color="$(_moma_resolve_color "$MOMA_COLOR_WARNING" "$MOMA_COLOR_WARNING" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"

    trap '_moma_term_show_cursor' EXIT
    trap 'exit 130' INT TERM
    _moma_term_hide_cursor

    while kill -0 "$pid" 2>/dev/null; do
        if _moma_term_is_tty 2; then
            printf '\r  %b[%s]%b %s' "$color" "${frames:$frame:1}" "$reset" "$message" >&2
            frame=$(((frame + 1) % ${#frames}))
        fi
        sleep "$delay" || return 1
    done

    if _moma_term_is_tty 2; then
        _moma_term_clear_line
    fi
)

moma-spinner() {
    local pid=""
    local message="Working"
    local message_set=false
    local delay="0.1"
    local no_color=false
    local -a positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pid)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-spinner "$1"
                    return 1
                fi
                pid="$2"
                shift 2
                ;;
            --pid=*)
                pid="${1#*=}"
                shift
                ;;
            --message | -m)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-spinner "$1"
                    return 1
                fi
                message="$2"
                message_set=true
                shift 2
                ;;
            --message=*)
                message="${1#*=}"
                message_set=true
                shift
                ;;
            --delay)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-spinner "$1"
                    return 1
                fi
                delay="$2"
                shift 2
                ;;
            --delay=*)
                delay="${1#*=}"
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-spinner <pid> ["message"] [--delay <seconds>] [--no-color]
EOF
                return 0
                ;;
            --)
                shift
                positional+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-spinner "$1"
                return 1
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    local message_index=0
    if [[ -z "$pid" ]]; then
        pid="${positional[0]:-}"
        message_index=1
    fi
    if ! $message_set && [[ ${#positional[@]} -gt message_index ]]; then
        message="${positional[$message_index]}"
    fi
    local allowed_positional=$message_index
    $message_set || allowed_positional=$((allowed_positional + 1))
    if ((${#positional[@]} > allowed_positional)); then
        printf 'moma-spinner: unexpected argument: %s\n' "${positional[$allowed_positional]}" >&2
        return 1
    fi

    if ! _moma_is_uint "$pid"; then
        printf 'moma-spinner: a numeric process ID is required\n' >&2
        return 1
    fi
    if ! _moma_is_delay "$delay"; then
        printf 'moma-spinner: invalid delay: %s\n' "$delay" >&2
        return 1
    fi

    local follow_status=0
    _moma_spinner_follow "$pid" "$message" "$delay" "$no_color" || follow_status=$?
    if ((follow_status == 130)); then
        printf '\n' >&2
        return 130
    elif ((follow_status != 0)); then
        _moma_runtime_error moma-spinner 'failed while waiting for the process'
        return 1
    fi
    local -a message_args=("$message" --success)
    $no_color && message_args+=(--no-color)
    moma-msg "${message_args[@]}"
}
