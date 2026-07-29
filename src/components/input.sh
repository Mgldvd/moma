# Input component.
# Render a completed input field from normalized arguments.
_moma_render_input() {
    local title="$1"
    local placeholder="$2"
    local default_value="$3"
    local value="$4"
    local width="$5"
    local color="$6"
    local icon="$7"
    local no_color="$8"
    local max_width="${9:-}"

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

    local label_width=${#label}
    local display_width=${#display_value}
    local natural_width=$((label_width + 4))
    if ((display_width + 2 > natural_width)); then
        natural_width=$((display_width + 2))
    fi
    width="$(
        _moma_resolve_decor_width \
            "$natural_width" 40 "$width" "$max_width" 8
    )"
    label="$(_moma_truncate_text "$label" "$((width - 4))")"
    label_width=${#label}

    local resolved_color reset dash_count value_space display_line
    local -a display_lines=()
    mapfile -t display_lines < <(
        _moma_wrap_text "$display_value" "$((width - 2))"
    )
    resolved_color="$(
        _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
    )"
    reset="$(_moma_reset_color "$no_color")"

    if [[ -n "$label" ]]; then
        dash_count=$((width - label_width - 3))
    else
        dash_count=$width
    fi
    if ((dash_count < 1)); then
        dash_count=1
    fi

    if [[ -n "$label" ]]; then
        printf '%b  ┌─ %s %s┐%b\n' \
            "$resolved_color" "$label" \
            "$(_moma_repeat_char "─" "$dash_count")" "$reset"
    else
        printf '%b  ┌%s┐%b\n' \
            "$resolved_color" \
            "$(_moma_repeat_char "─" "$dash_count")" "$reset"
    fi
    for display_line in "${display_lines[@]}"; do
        value_space=$((width - ${#display_line} - 2))
        printf '%b  │ %s%s │%b\n' \
            "$resolved_color" "$display_line" \
            "$(printf '%*s' "$value_space" '')" "$reset"
    done
    printf '%b  └%s┘%b\n\n' \
        "$resolved_color" "$(_moma_repeat_char "─" "$width")" "$reset"
}

# Render an open input field before reading a value.
_moma_render_input_open() {
    local title="$1"
    local placeholder="$2"
    local default_value="$3"
    local value="$4"
    local width="$5"
    local color="$6"
    local icon="$7"
    local prompt_marker="$8"
    local no_color="$9"
    local max_width="${10:-}"

    local label="$title"
    if [[ -n "$icon" && -n "$label" ]]; then
        label="$icon $label"
    elif [[ -n "$icon" ]]; then
        label="$icon"
    fi

    local label_width=${#label}
    local placeholder_width=${#placeholder}
    local default_width=${#default_value}
    local value_width=${#value}
    local natural_width=$((label_width + 4))
    ((placeholder_width + 2 <= natural_width)) ||
        natural_width=$((placeholder_width + 2))
    ((default_width + 2 <= natural_width)) || natural_width=$((default_width + 2))
    ((value_width + 2 <= natural_width)) || natural_width=$((value_width + 2))
    width="$(
        _moma_resolve_decor_width \
            "$natural_width" 40 "$width" "$max_width" 8
    )"
    label="$(_moma_truncate_text "$label" "$((width - 4))")"
    label_width=${#label}

    local resolved_color reset dash_count prompt_text
    resolved_color="$(
        _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
    )"
    reset="$(_moma_reset_color "$no_color")"

    if [[ -n "$label" ]]; then
        dash_count=$((width - label_width - 3))
    else
        dash_count=$width
    fi
    if ((dash_count < 1)); then
        dash_count=1
    fi

    if [[ "$prompt_marker" == *" " ]]; then
        prompt_text="$prompt_marker"
    else
        prompt_text="$prompt_marker "
    fi

    if [[ -n "$label" ]]; then
        printf '%b  ┌─ %s %s┐%b\n' \
            "$resolved_color" "$label" \
            "$(_moma_repeat_char "─" "$dash_count")" "$reset" >&2
    else
        printf '%b  ┌%s┐%b\n' \
            "$resolved_color" \
            "$(_moma_repeat_char "─" "$dash_count")" "$reset" >&2
    fi
    printf '%b  │%s%b' "$resolved_color" "$prompt_text" "$reset" >&2
}

# Read a masked value from the active terminal.
_moma_read_secret() {
    local target_var="$1"
    local mask="${2:-*}"
    local secret_value=""
    local character

    if [[ ! -t 0 ]]; then
        IFS= read -r secret_value || return $?
        printf -v "$target_var" '%s' "$secret_value"
        return 0
    fi

    local read_status
    while true; do
        IFS= read -r -s -n 1 character
        read_status=$?
        if ((read_status != 0)); then
            printf '\n' >&2
            return "$read_status"
        fi

        if [[ -z "$character" ]]; then
            printf '\n' >&2
            break
        fi

        case "$character" in
            $'\177' | $'\b')
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

# Validate an input value against public input constraints.
_moma_input_validate() {
    local width="$1"
    local max_width="${2:-}"
    if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
        printf 'moma-input: invalid width: %s\n' "$width" >&2
        return 1
    fi
    if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
        printf 'moma-input: invalid max width: %s\n' "$max_width" >&2
        return 1
    fi
}

# Resolve the final input value from response and fallback values.
_moma_input_resolve_result() {
    local response="$1"
    local default_value="$2"
    local value="$3"
    local trim="$4"
    local result="$response"

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
    printf '%s' "$result"
}

# Emit an input result on the component's stdout return channel.
_moma_input_emit_result() {
    printf '%s\n' "$1"
}

# Parse input options, render the field, and optionally read a value.
moma-input() {
    local title=""
    local placeholder=""
    local default_value=""
    local value=""
    local width=""
    local max_width=""
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
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                title="$2"
                shift 2
                ;;
            --title=*)
                title="${1#*=}"
                shift
                ;;
            --placeholder)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                placeholder="$2"
                shift 2
                ;;
            --placeholder=*)
                placeholder="${1#*=}"
                shift
                ;;
            --default)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                default_value="$2"
                shift 2
                ;;
            --default=*)
                default_value="${1#*=}"
                shift
                ;;
            --value)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                value="$2"
                shift 2
                ;;
            --value=*)
                value="${1#*=}"
                shift
                ;;
            --width)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                width="$2"
                shift 2
                ;;
            --width=*)
                width="${1#*=}"
                shift
                ;;
            --max-width)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                max_width="$2"
                shift 2
                ;;
            --max-width=*)
                max_width="${1#*=}"
                shift
                ;;
            --color | -c)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                color="$2"
                shift 2
                ;;
            --color=*)
                color="${1#*=}"
                shift
                ;;
            --icon | -i)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                icon="$2"
                shift 2
                ;;
            --icon=*)
                icon="${1#*=}"
                shift
                ;;
            --prompt)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                prompt_marker="$2"
                shift 2
                ;;
            --prompt=*)
                prompt_marker="${1#*=}"
                shift
                ;;
            --mask)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-input "$1"
                    return 1
                fi
                secret_mask="$2"
                shift 2
                ;;
            --mask=*)
                secret_mask="${1#*=}"
                shift
                ;;
            --success | --error | --warning | --info)
                style="$(_moma_apply_semantic_style "${1#--}")"
                color="${style%%$'\t'*}"
                icon="${style#*$'\t'}"
                shift
                ;;
            --read)
                read_mode=true
                shift
                ;;
            --secret)
                secret=true
                shift
                ;;
            --required)
                required=true
                shift
                ;;
            --trim)
                trim=true
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
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
  --max-width <number>
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
                return 0
                ;;
            -*)
                _moma_unknown_option moma-input "$1"
                return 1
                ;;
            *)
                _moma_unknown_option moma-input "$1"
                return 1
                ;;
        esac
    done

    _moma_input_validate "$width" "$max_width" || return $?

    if ! $read_mode; then
        _moma_render_input \
            "$title" "$placeholder" "$default_value" "$value" \
            "$width" "$color" "$icon" "$no_color" "$max_width"
        return $?
    fi

    local response result read_status
    while true; do
        _moma_render_input_open \
            "$title" "$placeholder" "$default_value" "$value" \
            "$width" "$color" "$icon" "$prompt_marker" \
            "$no_color" "$max_width" || return 1

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

        result="$(
            _moma_input_resolve_result \
                "$response" "$default_value" "$value" "$trim"
        )"

        if ! $required || [[ -n "$result" ]]; then
            _moma_input_emit_result "$result"
            return 0
        fi

        if ((read_status != 0)); then
            printf 'moma-input: value is required\n' >&2
            return 1
        fi

        if declare -F moma-msg >/dev/null; then
            moma-msg "This field is required" --error >&2
        else
            printf 'moma-input: value is required\n' >&2
        fi
    done
}
