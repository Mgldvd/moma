# Pagga ASCII header component.
_moma_pagga_glyph() {
  # The Q glyph's backslashes below are literal pixels, not escaped quotes.
  # A disable directive cannot target a single case branch, so this covers
  # the whole case statement.
  # shellcheck disable=SC1003
  case "$1" in
    0) printf '%s\n' '░▄▀▄' '░█/█' '░░▀░' ;;
    1) printf '%s\n' '░▀█░' '░░█░' '░▀▀▀' ;;
    2) printf '%s\n' '░▀▀▄' '░▄▀░' '░▀▀▀' ;;
    3) printf '%s\n' '░▀▀█' '░░▀▄' '░▀▀░' ;;
    4) printf '%s\n' '░█░█' '░░▀█' '░░░▀' ;;
    5) printf '%s\n' '░█▀▀' '░▀▀▄' '░▀▀░' ;;
    6) printf '%s\n' '░▄▀▀' '░█▀▄' '░░▀░' ;;
    7) printf '%s\n' '░▀▀█' '░▄▀░' '░▀░░' ;;
    8) printf '%s\n' '░▄▀▄' '░▄▀▄' '░░▀░' ;;
    9) printf '%s\n' '░▄▀▄' '░░▀█' '░▀▀░' ;;
    A) printf '%s\n' '░█▀█' '░█▀█' '░▀░▀' ;;
    B) printf '%s\n' '░█▀▄' '░█▀▄' '░▀▀░' ;;
    C) printf '%s\n' '░█▀▀' '░█░░' '░▀▀▀' ;;
    D) printf '%s\n' '░█▀▄' '░█░█' '░▀▀░' ;;
    E) printf '%s\n' '░█▀▀' '░█▀▀' '░▀▀▀' ;;
    F) printf '%s\n' '░█▀▀' '░█▀▀' '░▀░░' ;;
    G) printf '%s\n' '░█▀▀' '░█░█' '░▀▀▀' ;;
    H) printf '%s\n' '░█░█' '░█▀█' '░▀░▀' ;;
    I) printf '%s\n' '░▀█▀' '░░█░' '░▀▀▀' ;;
    J) printf '%s\n' '░▀▀█' '░░░█' '░▀▀░' ;;
    K) printf '%s\n' '░█░█' '░█▀▄' '░▀░▀' ;;
    L) printf '%s\n' '░█░░' '░█░░' '░▀▀▀' ;;
    M) printf '%s\n' '░█▄█' '░█░█' '░▀░▀' ;;
    N) printf '%s\n' '░█▀█' '░█░█' '░▀░▀' ;;
    O) printf '%s\n' '░█▀█' '░█░█' '░▀▀▀' ;;
    P) printf '%s\n' '░█▀█' '░█▀▀' '░▀░░' ;;
    Q) printf '%s\n' '░▄▀▄' '░█\█' '░░▀\' ;;
    R) printf '%s\n' '░█▀▄' '░█▀▄' '░▀░▀' ;;
    S) printf '%s\n' '░█▀▀' '░▀▀█' '░▀▀▀' ;;
    T) printf '%s\n' '░▀█▀' '░░█░' '░░▀░' ;;
    U) printf '%s\n' '░█░█' '░█░█' '░▀▀▀' ;;
    V) printf '%s\n' '░█░█' '░▀▄▀' '░░▀░' ;;
    W) printf '%s\n' '░█░█' '░█▄█' '░▀░▀' ;;
    X) printf '%s\n' '░█░█' '░▄▀▄' '░▀░▀' ;;
    Y) printf '%s\n' '░█░█' '░░█░' '░░▀░' ;;
    Z) printf '%s\n' '░▀▀█' '░▄▀░' '░▀▀▀' ;;
    ' ') printf '%s\n' '░░' '░░' '░░' ;;
    *) printf '%s\n' '░?░' '░?░' '░?░' ;;
  esac
}

# Render a Pagga ASCII header from normalized arguments.
_moma_render_header() {
  local text="$1"
  local color="${2:-$MOMA_COLOR_PRIMARY}"
  local no_color="${3:-false}"
  local margin_top="${4:-1}"
  local margin_bottom="${5:-2}"
  local margin_left="${6:-0}"
  local index character resolved_color reset left_padding
  local -a glyph=()
  local row_one=""
  local row_two=""
  local row_three=""

  text="${text^^}"
  for ((index = 0; index < ${#text}; index++)); do
    character="${text:index:1}"
    mapfile -t glyph < <(_moma_pagga_glyph "$character")
    row_one+="${glyph[0]}"
    row_two+="${glyph[1]}"
    row_three+="${glyph[2]}"
  done

  resolved_color="$(_moma_resolve_color "$color" "$MOMA_COLOR_PRIMARY" "$no_color")"
  reset="$(_moma_reset_color "$no_color")"
  left_padding="$(printf '%*s' "$margin_left" '')"
  for ((index = 0; index < margin_top; index++)); do
    printf '\n'
  done
  printf '%s%b%s%b\n' "$left_padding" "$resolved_color" "$row_one" "$reset"
  printf '%s%b%s%b\n' "$left_padding" "$resolved_color" "$row_two" "$reset"
  printf '%s%b%s%b\n' "$left_padding" "$resolved_color" "$row_three" "$reset"
  for ((index = 0; index < margin_bottom; index++)); do
    printf '\n'
  done
}

# Parse header options and print a Pagga ASCII heading.
moma-header() {
  local text=""
  local color="$MOMA_COLOR_PRIMARY"
  local margin_top=1
  local margin_bottom=2
  local margin_left=0
  local no_color=false
  local -a positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --color | -c)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-header "$1"
          return 1
        fi
        color="$2"
        shift 2
        ;;
      --color=*)
        color="${1#*=}"
        shift
        ;;
      --margin-top)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-header "$1"
          return 1
        fi
        margin_top="$2"
        shift 2
        ;;
      --margin-top=*)
        margin_top="${1#*=}"
        shift
        ;;
      --margin-bottom | --margin | -m)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-header "$1"
          return 1
        fi
        margin_bottom="$2"
        shift 2
        ;;
      --margin-bottom=* | --margin=*)
        margin_bottom="${1#*=}"
        shift
        ;;
      --margin-left)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma-header "$1"
          return 1
        fi
        margin_left="$2"
        shift 2
        ;;
      --margin-left=*)
        margin_left="${1#*=}"
        shift
        ;;
      --no-color)
        no_color=true
        shift
        ;;
      --help | -h)
        cat <<'EOF'
Usage: moma-header "<text>" [--color <color>] [--margin-top <number>] [--margin-bottom <number>] [--margin-left <number>] [--no-color]
EOF
        return 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        _moma_unknown_option moma-header "$1"
        return 1
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  text="${positional[*]}"
  if ! _moma_is_uint "$margin_top"; then
    _moma_usage_error moma-header "invalid top margin: $margin_top"
    return 2
  fi
  if ! _moma_is_uint "$margin_bottom"; then
    _moma_usage_error moma-header "invalid bottom margin: $margin_bottom"
    return 2
  fi
  if ! _moma_is_uint "$margin_left"; then
    _moma_usage_error moma-header "invalid left margin: $margin_left"
    return 2
  fi
  margin_top="$((10#$margin_top))"
  margin_bottom="$((10#$margin_bottom))"
  margin_left="$((10#$margin_left))"
  _moma_render_header \
    "$text" "$color" "$no_color" \
    "$margin_top" "$margin_bottom" "$margin_left"
}
