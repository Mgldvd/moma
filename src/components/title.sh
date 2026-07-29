# Title components.
# Render a primary title from normalized arguments.
_moma_render_title() {
    local title="$1"
    local subtitle="${2:-}"
    local primary="${3:-$MOMA_COLOR_PRIMARY}"
    local accent="${4:-$MOMA_COLOR_ACCENT}"
    local min_width="${5:-35}"
    local no_color="${6:-false}"
    local width="${7:-}"
    local max_width="${8:-}"

    title="$(_moma_trim "$title")"
    subtitle="$(_moma_trim "$subtitle")"
    if [[ ! "$min_width" =~ ^[0-9]+$ ]]; then
        min_width=35
    fi

    local primary_color accent_color reset
    primary_color="$(
        _moma_resolve_color "$primary" "$MOMA_COLOR_PRIMARY" "$no_color"
    )"
    accent_color="$(
        _moma_resolve_color "$accent" "$MOMA_COLOR_ACCENT" "$no_color"
    )"
    reset="$(_moma_reset_color "$no_color")"

    local text_length=${#title}
    if [[ -n "$subtitle" ]]; then
        text_length=$((text_length + ${#subtitle} + 1))
    fi

    local box_width
    box_width="$(
        _moma_resolve_decor_width \
            "$((text_length + 6))" "$min_width" "$width" "$max_width" 8
    )"
    local padding=$((box_width - text_length - 4))

    printf '%b\n' "$primary_color"
    printf '  ┌%s┐\n' "$(_moma_repeat_char "─" "$box_width")"
    if ((padding < 0)); then
        local combined_text="$title"
        local wrapped_line wrapped_padding
        local -a wrapped_lines=()
        [[ -z "$subtitle" ]] || combined_text+=" $subtitle"
        mapfile -t wrapped_lines < <(
            _moma_wrap_text "$combined_text" "$((box_width - 4))"
        )
        for wrapped_line in "${wrapped_lines[@]}"; do
            wrapped_padding=$((box_width - ${#wrapped_line} - 4))
            printf '  ▪  %b%s%b%s  ▪\n' \
                "$primary_color" "$wrapped_line" "$primary_color" \
                "$(printf '%*s' "$wrapped_padding" '')"
        done
    elif [[ -n "$subtitle" ]]; then
        printf '  ▪  %b%s%b %b%s%b%s  ▪\n' \
            "$primary_color" "$title" "$primary_color" \
            "$accent_color" "$subtitle" "$primary_color" \
            "$(printf '%*s' "$padding" '')"
    else
        printf '  ▪  %b%s%b%s  ▪\n' \
            "$primary_color" "$title" "$primary_color" \
            "$(printf '%*s' "$padding" '')"
    fi
    printf '  └%s┘%b\n' "$(_moma_repeat_char "─" "$box_width")" "$reset"
}

# Parse title options and print a primary title component.
moma-title() {
    local title=""
    local subtitle=""
    local primary="$MOMA_COLOR_PRIMARY"
    local accent="$MOMA_COLOR_ACCENT"
    local min_width=35
    local width=""
    local max_width=""
    local no_color=false
    local -a positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --primary)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title "$1"
                    return 1
                fi
                primary="$2"
                shift 2
                ;;
            --primary=*)
                primary="${1#*=}"
                shift
                ;;
            --accent)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title "$1"
                    return 1
                fi
                accent="$2"
                shift 2
                ;;
            --accent=*)
                accent="${1#*=}"
                shift
                ;;
            --min-width)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title "$1"
                    return 1
                fi
                min_width="$2"
                shift 2
                ;;
            --min-width=*)
                min_width="${1#*=}"
                shift
                ;;
            --width)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title "$1"
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
                    _moma_option_requires_value moma-title "$1"
                    return 1
                fi
                max_width="$2"
                shift 2
                ;;
            --max-width=*)
                max_width="${1#*=}"
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-title "<title>" ["subtitle"] [--primary <color>] [--accent <color>] [--min-width <n>] [--width <n>] [--max-width <n>] [--no-color]
EOF
                return 0
                ;;
            --)
                shift
                positional+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-title "$1"
                return 1
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    title="${positional[0]:-}"
    subtitle="${positional[1]:-}"
    if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
        _moma_usage_error moma-title "invalid width: $width"
        return 2
    fi
    if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
        _moma_usage_error moma-title "invalid max width: $max_width"
        return 2
    fi
    _moma_render_title \
        "$title" "$subtitle" "$primary" "$accent" \
        "$min_width" "$no_color" "$width" "$max_width"
}

# Render a secondary title from normalized arguments.
_moma_render_title_sub() {
    local text="$1"
    local detail="${2:-}"
    local color="${3:-$MOMA_COLOR_PRIMARY}"
    local message="${4:-}"
    local min_width="${5:-30}"
    local no_color="${6:-false}"
    local width="${7:-}"
    local max_width="${8:-}"

    text="$(_moma_trim "$text")"
    detail="$(_moma_trim "$detail")"
    message="$(_moma_trim "$message")"
    if [[ ! "$min_width" =~ ^[0-9]+$ ]]; then
        min_width=30
    fi

    local resolved_color reset combined_text box_width
    resolved_color="$(
        _moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color"
    )"
    reset="$(_moma_reset_color "$no_color")"
    combined_text="$text"
    if [[ -n "$detail" ]]; then
        combined_text+=" $detail"
    fi
    box_width="$(
        _moma_resolve_decor_width \
            "$((${#combined_text} + 6))" \
            "$min_width" "$width" "$max_width" 8
    )"

    printf '%b\n' "$resolved_color"
    if [[ -n "$detail" ]]; then
        printf '  ▪  %b%s %b%s\n' "$reset" "$text" "$resolved_color" "$detail"
    else
        printf '  ▪  %b%s %b\n' "$reset" "$text" "$resolved_color"
    fi
    printf '  └%s\n' "$(_moma_repeat_char "─" "$box_width")"
    if [[ -n "$message" ]]; then
        printf '\n'
        printf '     %b%s\n' "$reset" "$message"
    fi
    printf '%b\n' "$reset"
}

# Parse title options and print a secondary title component.
moma-title-sub() {
    local text=""
    local detail=""
    local color="$MOMA_COLOR_PRIMARY"
    local message=""
    local min_width=30
    local width=""
    local max_width=""
    local no_color=false
    local -a positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --color | -c)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title-sub "$1"
                    return 1
                fi
                color="$2"
                shift 2
                ;;
            --color=*)
                color="${1#*=}"
                shift
                ;;
            --message)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title-sub "$1"
                    return 1
                fi
                message="$2"
                shift 2
                ;;
            --message=*)
                message="${1#*=}"
                shift
                ;;
            --min-width)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title-sub "$1"
                    return 1
                fi
                min_width="$2"
                shift 2
                ;;
            --min-width=*)
                min_width="${1#*=}"
                shift
                ;;
            --width)
                if [[ $# -lt 2 ]]; then
                    _moma_option_requires_value moma-title-sub "$1"
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
                    _moma_option_requires_value moma-title-sub "$1"
                    return 1
                fi
                max_width="$2"
                shift 2
                ;;
            --max-width=*)
                max_width="${1#*=}"
                shift
                ;;
            --no-color)
                no_color=true
                shift
                ;;
            --help | -h)
                cat <<'EOF'
Usage: moma-title-sub "<text>" ["detail"] [--color <color>] [--message <text>] [--min-width <n>] [--width <n>] [--max-width <n>] [--no-color]
EOF
                return 0
                ;;
            --)
                shift
                positional+=("$@")
                break
                ;;
            -*)
                _moma_unknown_option moma-title-sub "$1"
                return 1
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    text="${positional[0]:-}"
    detail="${positional[1]:-}"
    if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
        _moma_usage_error moma-title-sub "invalid width: $width"
        return 2
    fi
    if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
        _moma_usage_error moma-title-sub "invalid max width: $max_width"
        return 2
    fi
    _moma_render_title_sub \
        "$text" "$detail" "$color" "$message" \
        "$min_width" "$no_color" "$width" "$max_width"
}
