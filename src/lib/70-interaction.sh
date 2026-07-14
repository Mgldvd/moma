_moma_render_confirm () {
    local question="$1"
    local selected_index="$2"
    local color="$3"
    local no_color="$4"
    local redraw="$5"

    local active_color reset selected_answer prompt_text box_width
    active_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_WARNING" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"
    if (( selected_index == 0 )); then selected_answer=yes; else selected_answer=no; fi
    prompt_text="$question [$selected_answer]"
    box_width=$(( ${#prompt_text} + 6 > 30 ? ${#prompt_text} + 6 : 30 ))

    if $redraw; then printf '\033[6A' >&2; fi
    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '%b\n' "$active_color" >&2

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  ▪  %b%s%b\n' "$reset" "$prompt_text" "$active_color" >&2

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  └%s%b\n' "$(_moma_repeat_char "─" "$box_width")" "$reset" >&2

    if $redraw; then printf '\033[2K\r' >&2; fi
    if (( selected_index == 0 )); then
        printf '  %b▪%b Yes\n' "$active_color" "$reset" >&2
    else
        printf '    Yes\n' >&2
    fi

    if $redraw; then printf '\033[2K\r' >&2; fi
    if (( selected_index == 1 )); then
        printf '  %b▪%b No\n' "$active_color" "$reset" >&2
    else
        printf '    No\n' >&2
    fi

    if $redraw; then printf '\033[2K\r' >&2; fi
    printf '  ↑/↓ move · Enter confirm · y yes · n no\n' >&2
}

moma-confirm () {
    local question=""
    local default_answer="yes"
    local supplied_answer=""
    local color="$MOMA_COLOR_WARNING"
    local no_color=false
    local -a positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --default)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-confirm "$1"; return 2; fi
                default_answer="${2,,}"; shift 2 ;;
            --default=*) default_answer="${1#*=}"; default_answer="${default_answer,,}"; shift ;;
            --answer)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-confirm "$1"; return 2; fi
                supplied_answer="${2,,}"; shift 2 ;;
            --answer=*) supplied_answer="${1#*=}"; supplied_answer="${supplied_answer,,}"; shift ;;
            --color|-c)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-confirm "$1"; return 2; fi
                color="$2"; shift 2 ;;
            --color=*) color="${1#*=}"; shift ;;
            --no-color) no_color=true; shift ;;
            --help|-h)
                cat <<'EOF'
Usage: moma-confirm "<question>" [--default yes|no] [--answer yes|no] [--color <color>] [--no-color]

Use the up and down arrow keys to move, Enter to confirm, y for yes, n for no, and q or Escape to cancel.
Returns 0 for yes, 1 for no, 2 for invalid input, and 130 for cancellation.
EOF
                return 0 ;;
            --) shift; positional+=("$@"); break ;;
            -*) _moma_unknown_option moma-confirm "$1"; return 2 ;;
            *) positional+=("$1"); shift ;;
        esac
    done

    question="${positional[*]}"
    case "$default_answer" in
        y|yes) default_answer=yes ;;
        n|no) default_answer=no ;;
        *) printf 'moma-confirm: invalid default answer: %s\n' "$default_answer" >&2; return 2 ;;
    esac

    local selected_index=0
    [[ "$default_answer" == yes ]] || selected_index=1

    if [[ -n "$supplied_answer" ]]; then
        case "$supplied_answer" in
            y|yes) selected_index=0 ;;
            n|no) selected_index=1 ;;
            *) printf 'moma-confirm: invalid answer: %s\n' "$supplied_answer" >&2; return 2 ;;
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
                y|yes) printf '\n' >&2; return 0 ;;
                n|no) printf '\n' >&2; return 1 ;;
                *) printf '  Enter y or n.\n' >&2 ;;
            esac
        done
    fi

    local key sequence
    while true; do
        if ! IFS= read -r -s -n 1 key; then
            printf '\n' >&2
            return 130
        fi

        case "$key" in
            "") printf '\n' >&2; return "$selected_index" ;;
            y|Y)
                selected_index=0
                _moma_render_confirm "$question" "$selected_index" "$color" "$no_color" true
                printf '\n' >&2
                return 0
                ;;
            n|N)
                selected_index=1
                _moma_render_confirm "$question" "$selected_index" "$color" "$no_color" true
                printf '\n' >&2
                return 1
                ;;
            $'\033')
                sequence=""
                IFS= read -r -s -n 2 -t 0.1 sequence || true
                case "$sequence" in
                    '[A'|'[B') selected_index=$((1 - selected_index)) ;;
                    *) printf '\n' >&2; return 130 ;;
                esac
                ;;
            j|k) selected_index=$((1 - selected_index)) ;;
            q) printf '\n' >&2; return 130 ;;
            *) continue ;;
        esac

        _moma_render_confirm "$question" "$selected_index" "$color" "$no_color" true
    done
}

moma-spinner () {
    local pid=""
    local message="Working"
    local message_set=false
    local delay="0.1"
    local no_color=false
    local -a positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pid)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-spinner "$1"; return 1; fi
                pid="$2"; shift 2 ;;
            --pid=*) pid="${1#*=}"; shift ;;
            --message|-m)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-spinner "$1"; return 1; fi
                message="$2"; message_set=true; shift 2 ;;
            --message=*) message="${1#*=}"; message_set=true; shift ;;
            --delay)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-spinner "$1"; return 1; fi
                delay="$2"; shift 2 ;;
            --delay=*) delay="${1#*=}"; shift ;;
            --no-color) no_color=true; shift ;;
            --help|-h)
                cat <<'EOF'
Usage: moma-spinner <pid> ["message"] [--delay <seconds>] [--no-color]
EOF
                return 0 ;;
            --) shift; positional+=("$@"); break ;;
            -*) _moma_unknown_option moma-spinner "$1"; return 1 ;;
            *) positional+=("$1"); shift ;;
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
    if (( ${#positional[@]} > allowed_positional )); then
        printf 'moma-spinner: unexpected argument: %s\n' "${positional[$allowed_positional]}" >&2
        return 1
    fi

    if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
        printf 'moma-spinner: a numeric process ID is required\n' >&2
        return 1
    fi
    if [[ ! "$delay" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        printf 'moma-spinner: invalid delay: %s\n' "$delay" >&2
        return 1
    fi

    local use_tty=false
    local frames='|/-\'
    local frame=0
    local interrupted=false
    local previous_int=""
    local previous_term=""
    local color reset
    color="$(_moma_resolve_color "$MOMA_COLOR_WARNING" "$MOMA_COLOR_WARNING" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"

    if [[ -t 1 ]] && command -v tput &>/dev/null; then
        use_tty=true
        tput civis
        previous_int="$(trap -p INT)"
        previous_term="$(trap -p TERM)"
        trap 'interrupted=true' INT TERM
    fi

    while kill -0 "$pid" 2>/dev/null; do
        $interrupted && break
        if $use_tty; then
            printf '\r  %b[%s]%b %s' "$color" "${frames:$frame:1}" "$reset" "$message"
            frame=$(( (frame + 1) % ${#frames} ))
        fi
        if ! sleep "$delay"; then
            $interrupted || return 1
        fi
    done

    if $use_tty; then
        tput cnorm
        if [[ -n "$previous_int" ]]; then eval "$previous_int"; else trap - INT; fi
        if [[ -n "$previous_term" ]]; then eval "$previous_term"; else trap - TERM; fi
        printf '\r'
    fi
    if $interrupted; then
        printf '\n'
        return 130
    fi
    local -a message_args=("$message" --success)
    $no_color && message_args+=(--no-color)
    moma-msg "${message_args[@]}"
}
