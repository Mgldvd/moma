# Prompt component.
# An interactive free-text prompt: the same "marker + text, underline"
# look as moma-title-sub, followed by a ❯ cursor where the answer is
# typed. The read/resolve/emit machinery is shared with moma-input (see
# input.sh) - the difference between the two components is the look, not
# the capability.

# Render the open prompt (marker + question + underline + cursor) to
# stderr, leaving the cursor ready for the caller to read a response.
_moma_render_prompt_open() {
  local question="$1"
  local detail="${2:-}"
  local color="${3:-$MOMA_COLOR_WARNING}"
  local min_width="${4:-30}"
  local no_color="${5:-false}"
  local width="${6:-}"
  local max_width="${7:-}"
  local icon="${8-▪}"
  local border="${9:-open}"
  local cursor="${10:-❯}"

  question="$(_moma_trim "$question")"
  if [[ ! "$min_width" =~ ^[0-9]+$ ]]; then
    min_width=30
  fi

  local resolved_color reset combined_text box_width
  resolved_color="$(
    _moma_resolve_color "$color" "$MOMA_COLOR_WARNING" "$no_color"
  )"
  reset="$(_moma_reset_color "$no_color")"
  combined_text="$question"
  [[ -n "$detail" ]] && combined_text+=" $detail"
  box_width="$(
    _moma_resolve_decor_width \
      "$((${#combined_text} + 6))" "$min_width" "$width" "$max_width" 8
  )"

  # There's no left box edge to fall back to here (unlike moma-title), so
  # a missing icon is just blank filler, not a │.
  local left_glyph="${icon:- }"

  {
    printf '%b\n' "$resolved_color"
    _moma_render_marker_underline \
      "$question" "$detail" "$resolved_color" "$reset" "$box_width" \
      "$left_glyph" "$border"
    printf '  %b%s%b ' "$resolved_color" "$cursor" "$reset"
  } >&2
}

# Parse prompt options, print the question, and read an answer.
moma-prompt() {
  local question=""
  local color="$MOMA_COLOR_WARNING"
  local default_value=""
  local icon="▪"
  local border="open"
  local cursor="❯"
  local min_width=30
  local width=""
  local max_width=""
  local secret_mask="*"
  local secret=false
  local required=false
  local trim=false
  local no_color=false
  local -a positional=()
  local style

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --success | --error | --warning | --info)
        style="$(_moma_apply_semantic_style "${1#--}")"
        color="${style%%$'\t'*}"
        icon="${style#*$'\t'}"
        shift
        ;;
      --color | -c)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-prompt "$1"
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
          _moma_option_requires_value moma-prompt "$1"
          return 1
        fi
        icon="$2"
        shift 2
        ;;
      --icon=*)
        icon="${1#*=}"
        shift
        ;;
      --no-icon)
        icon=""
        shift
        ;;
      --border)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-prompt "$1"
          return 1
        fi
        border="$2"
        shift 2
        ;;
      --border=*)
        border="${1#*=}"
        shift
        ;;
      --cursor)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-prompt "$1"
          return 1
        fi
        cursor="$2"
        shift 2
        ;;
      --cursor=*)
        cursor="${1#*=}"
        shift
        ;;
      --default)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-prompt "$1"
          return 1
        fi
        default_value="$2"
        shift 2
        ;;
      --default=*)
        default_value="${1#*=}"
        shift
        ;;
      --secret)
        secret=true
        shift
        ;;
      --mask)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-prompt "$1"
          return 1
        fi
        secret_mask="$2"
        shift 2
        ;;
      --mask=*)
        secret_mask="${1#*=}"
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
      --min-width)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-prompt "$1"
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
          _moma_option_requires_value moma-prompt "$1"
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
          _moma_option_requires_value moma-prompt "$1"
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
Usage: moma-prompt "<question>" [--success|--error|--warning|--info] [--color <color>] [--icon <char>] [--no-icon] [--border mirror|line|open] [--cursor <char>] [--default <value>] [--secret] [--mask <char>] [--required] [--trim] [--min-width <n>] [--width <n>] [--max-width <n>] [--no-color]

Prints the question with moma-title-sub's own marker + underline look,
then reads an answer from a ❯ cursor on the line below - the difference
from moma-input is the look, not the capability. --default pre-fills the
answer (shown as "[value]") when Enter is pressed with nothing typed.
EOF
        return 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-prompt "$1"
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  question="${positional[*]}"
  case "$border" in
    mirror | line | open) ;;
    *)
      _moma_usage_error moma-prompt "invalid border: $border (expected mirror, line, or open)"
      return 2
      ;;
  esac
  if [[ -n "$width" ]] && ! _moma_is_positive_int "$width"; then
    _moma_usage_error moma-prompt "invalid width: $width"
    return 2
  fi
  if [[ -n "$max_width" ]] && ! _moma_is_positive_int "$max_width"; then
    _moma_usage_error moma-prompt "invalid max width: $max_width"
    return 2
  fi

  local detail=""
  [[ -n "$default_value" ]] && detail="[$default_value]"

  local response result read_status
  while true; do
    _moma_render_prompt_open \
      "$question" "$detail" "$color" "$min_width" "$no_color" \
      "$width" "$max_width" "$icon" "$border" "$cursor" || return 1

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
        "$response" "$default_value" "" "$trim"
    )"

    if ! $required || [[ -n "$result" ]]; then
      _moma_input_emit_result "$result"
      return 0
    fi

    if ((read_status != 0)); then
      printf 'moma-prompt: value is required\n' >&2
      return 1
    fi

    if declare -F moma-msg >/dev/null; then
      moma-msg "This field is required" --error >&2
    else
      printf 'moma-prompt: value is required\n' >&2
    fi
  done
}
