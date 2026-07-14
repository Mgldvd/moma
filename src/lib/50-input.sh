_moma_render_input () {
    local title="$1"
    local placeholder="$2"
    local default_value="$3"
    local value="$4"
    local width="$5"
    local color="$6"
    local icon="$7"
    local no_color="$8"

    local label="$title"
    if [[ -n "$icon" && -n "$label" ]]; then
        label="$icon $label"
    elif [[ -n "$icon" ]]; then
        label="$icon"
    fi

    local display_value=""
    if [[ -n "$value" ]]; then
        display_value="$value"
    elif [[ -n "$default_value" ]]; then
        display_value="$default_value"
    elif [[ -n "$placeholder" ]]; then
        display_value="$placeholder"
    fi

    if [[ ! "$width" =~ ^[0-9]+$ ]]; then
        printf 'moma-input: invalid width: %s\n' "$width" >&2
        return 1
    fi
    if (( width < 20 )); then
        width=20
    fi

    local label_width=${#label}
    local display_width=${#display_value}
    if (( label_width + 4 > width )); then
        width=$((label_width + 4))
    fi
    if (( display_width + 2 > width )); then
        width=$((display_width + 2))
    fi

    local resolved_color reset dash_count value_space
    resolved_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"

    if [[ -n "$label" ]]; then
        dash_count=$((width - label_width - 3))
    else
        dash_count=$width
    fi
    if (( dash_count < 1 )); then
        dash_count=1
    fi

    value_space=$((width - display_width - 2))
    if (( value_space < 0 )); then
        value_space=0
    fi

    if [[ -n "$label" ]]; then
        printf '%b  ┌─ %s %s┐%b\n' "$resolved_color" "$label" "$(_moma_repeat_char "─" "$dash_count")" "$reset"
    else
        printf '%b  ┌%s┐%b\n' "$resolved_color" "$(_moma_repeat_char "─" "$dash_count")" "$reset"
    fi
    printf '%b  │ %s%s │%b\n' "$resolved_color" "$display_value" "$(printf '%*s' "$value_space" '')" "$reset"
    printf '%b  └%s┘%b\n\n' "$resolved_color" "$(_moma_repeat_char "─" "$width")" "$reset"
}

_moma_render_input_open () {
    local title="$1"
    local placeholder="$2"
    local default_value="$3"
    local value="$4"
    local width="$5"
    local color="$6"
    local icon="$7"
    local prompt_marker="$8"
    local no_color="$9"

    local label="$title"
    if [[ -n "$icon" && -n "$label" ]]; then
        label="$icon $label"
    elif [[ -n "$icon" ]]; then
        label="$icon"
    fi

    if [[ ! "$width" =~ ^[0-9]+$ ]]; then
        printf 'moma-input: invalid width: %s\n' "$width" >&2
        return 1
    fi
    if (( width < 20 )); then
        width=20
    fi

    local label_width=${#label}
    local placeholder_width=${#placeholder}
    local default_width=${#default_value}
    local value_width=${#value}
    if (( label_width + 4 > width )); then
        width=$((label_width + 4))
    fi
    if (( placeholder_width + 2 > width )); then
        width=$((placeholder_width + 2))
    fi
    if (( default_width + 2 > width )); then
        width=$((default_width + 2))
    fi
    if (( value_width + 2 > width )); then
        width=$((value_width + 2))
    fi

    local resolved_color reset dash_count prompt_text
    resolved_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color")"
    reset="$(_moma_reset_color "$no_color")"

    if [[ -n "$label" ]]; then
        dash_count=$((width - label_width - 3))
    else
        dash_count=$width
    fi
    if (( dash_count < 1 )); then
        dash_count=1
    fi

    if [[ "$prompt_marker" == *" " ]]; then
        prompt_text="$prompt_marker"
    else
        prompt_text="$prompt_marker "
    fi

    if [[ -n "$label" ]]; then
        printf '%b  ┌─ %s %s┐%b\n' "$resolved_color" "$label" "$(_moma_repeat_char "─" "$dash_count")" "$reset" >&2
    else
        printf '%b  ┌%s┐%b\n' "$resolved_color" "$(_moma_repeat_char "─" "$dash_count")" "$reset" >&2
    fi
    printf '%b  │%s%b' "$resolved_color" "$prompt_text" "$reset" >&2
}

_moma_read_secret () {
    local target_var="$1"
    local mask="${2:-*}"
    local secret_value=""
    local character

    if [[ ! -t 0 ]]; then
        IFS= read -r secret_value || return $?
        printf -v "$target_var" '%s' "$secret_value"
        return 0
    fi

    while true; do
        if ! IFS= read -r -s -n 1 character; then
            printf '\n' >&2
            return 1
        fi

        if [[ -z "$character" ]]; then
            printf '\n' >&2
            break
        fi

        case "$character" in
            $'\177'|$'\b')
                if [[ -n "$secret_value" ]]; then
                    secret_value="${secret_value%?}"
                    printf '\b \b' >&2
                fi
                ;;
            *)
                secret_value+="$character"
                printf '%s' "$mask" >&2
                ;;
        esac
    done

    printf -v "$target_var" '%s' "$secret_value"
}

moma-input () {
    local title=""
    local placeholder=""
    local default_value=""
    local value=""
    local width=40
    local color="$MOMA_COLOR_PRIMARY"
    local icon=""
    local prompt_marker="❯"
    local secret_mask="*"
    local read_mode=false
    local secret=false
    local required=false
    local trim=false
    local no_color=false
    local style

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                title="$2"; shift 2 ;;
            --title=*)
                title="${1#*=}"; shift ;;
            --placeholder)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                placeholder="$2"; shift 2 ;;
            --placeholder=*)
                placeholder="${1#*=}"; shift ;;
            --default)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                default_value="$2"; shift 2 ;;
            --default=*)
                default_value="${1#*=}"; shift ;;
            --value)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                value="$2"; shift 2 ;;
            --value=*)
                value="${1#*=}"; shift ;;
            --width)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                width="$2"; shift 2 ;;
            --width=*)
                width="${1#*=}"; shift ;;
            --color|-c)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                color="$2"; shift 2 ;;
            --color=*)
                color="${1#*=}"; shift ;;
            --icon|-i)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                icon="$2"; shift 2 ;;
            --icon=*)
                icon="${1#*=}"; shift ;;
            --prompt)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                prompt_marker="$2"; shift 2 ;;
            --prompt=*)
                prompt_marker="${1#*=}"; shift ;;
            --mask)
                if [[ $# -lt 2 ]]; then _moma_option_requires_value moma-input "$1"; return 1; fi
                secret_mask="$2"; shift 2 ;;
            --mask=*)
                secret_mask="${1#*=}"; shift ;;
            --success|--error|--warning|--info)
                style="$(_moma_apply_semantic_style "${1#--}")"
                color="${style%%$'\t'*}"
                icon="${style#*$'\t'}"
                shift ;;
            --read)
                read_mode=true; shift ;;
            --secret)
                secret=true; shift ;;
            --required)
                required=true; shift ;;
            --trim)
                trim=true; shift ;;
            --no-color)
                no_color=true; shift ;;
            --help|-h)
                cat <<'EOF'
Usage:
  moma-input --title "Name"
  moma-input --title "Name" --placeholder "Your name"
  moma-input --title "Name" --read
  moma-input --title "Password" --read --secret
  moma-input --title "Email" --read --required --trim
  moma-input --title "Project" --read --default "moma"

Options:
  --title <text>
  --placeholder <text>
  --default <text>
  --value <text>
  --width <number>
  --color, -c <color>
  --icon, -i <symbol>
  --prompt <symbol>
  --mask <symbol>
  --success
  --error
  --warning
  --info
  --read
  --secret
  --required
  --trim
  --no-color
  --help, -h

EOF
                return 0 ;;
            -*)
                _moma_unknown_option moma-input "$1"; return 1 ;;
            *)
                _moma_unknown_option moma-input "$1"; return 1 ;;
        esac
    done

    if [[ ! "$width" =~ ^[0-9]+$ ]]; then
        printf 'moma-input: invalid width: %s\n' "$width" >&2
        return 1
    fi

    if ! $read_mode; then
        _moma_render_input "$title" "$placeholder" "$default_value" "$value" "$width" "$color" "$icon" "$no_color"
        return $?
    fi

    local response result read_status
    while true; do
        _moma_render_input_open "$title" "$placeholder" "$default_value" "$value" "$width" "$color" "$icon" "$prompt_marker" "$no_color" || return 1

        if $secret; then
            if _moma_read_secret response "$secret_mask"; then
                read_status=0
            else
                read_status=$?
            fi
        else
            IFS= read -r response
            read_status=$?
        fi

        if [[ -t 0 ]]; then
            printf '\n' >&2
        else
            printf '\n\n' >&2
        fi

        result="$response"
        if $trim; then
            result="$(_moma_trim "$result")"
        fi
        if [[ -z "$result" && -n "$default_value" ]]; then
            result="$default_value"
        fi
        if [[ -z "$result" && -n "$value" ]]; then
            result="$value"
        fi
        if $trim; then
            result="$(_moma_trim "$result")"
        fi

        if ! $required || [[ -n "$result" ]]; then
            printf '%s\n' "$result"
            return 0
        fi

        if (( read_status != 0 )); then
            printf 'moma-input: value is required\n' >&2
            return 1
        fi

        if declare -F moma-msg > /dev/null; then
            moma-msg "This field is required" --error >&2
        else
            printf 'moma-input: value is required\n' >&2
        fi
    done
}
