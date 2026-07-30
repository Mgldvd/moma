# Theme configuration loading.
_MOMA_CONFIG_COLOR_NAMES=()
_MOMA_CONFIG_COLOR_VALUES=()
_MOMA_CONFIG_THEME_KEYS=()
_MOMA_CONFIG_THEME_VALUES=()
_MOMA_CONFIG_THEME_SEEN=()
_MOMA_CONFIG_THEME_ORDER=("default")

_MOMA_CONFIG_PATH=""
_MOMA_CONFIG_LOAD_ERROR=""
_MOMA_CONFIG_ERROR=""

_MOMA_ENV_COLOR_PRIMARY_SET="${MOMA_COLOR_PRIMARY+x}"
_MOMA_ENV_COLOR_ACCENT_SET="${MOMA_COLOR_ACCENT+x}"
_MOMA_ENV_COLOR_MUTED_SET="${MOMA_COLOR_MUTED+x}"
_MOMA_ENV_COLOR_SUCCESS_SET="${MOMA_COLOR_SUCCESS+x}"
_MOMA_ENV_COLOR_ERROR_SET="${MOMA_COLOR_ERROR+x}"
_MOMA_ENV_COLOR_WARNING_SET="${MOMA_COLOR_WARNING+x}"
_MOMA_ENV_COLOR_INFO_SET="${MOMA_COLOR_INFO+x}"

# Reset parsed configuration while retaining the built-in default theme.
_moma_config_reset() {
  _MOMA_CONFIG_COLOR_NAMES=()
  _MOMA_CONFIG_COLOR_VALUES=()
  _MOMA_CONFIG_THEME_KEYS=()
  _MOMA_CONFIG_THEME_VALUES=()
  _MOMA_CONFIG_THEME_SEEN=()
  _MOMA_CONFIG_THEME_ORDER=("default")
  _MOMA_CONFIG_ERROR=""
}

# Resolve the user configuration path.
_moma_config_path() {
  if [[ -n "${MOMA_CONFIG_FILE:-}" ]]; then
    printf '%s' "$MOMA_CONFIG_FILE"
  elif [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    printf '%s/momaui/moma.confg' "$XDG_CONFIG_HOME"
  elif [[ -n "${HOME:-}" ]]; then
    printf '%s/.config/momaui/moma.confg' "$HOME"
  else
    return 1
  fi
}

# Return success for a textual or expanded ANSI SGR sequence.
_moma_config_is_sgr() {
  local value="${1:-}"
  local parameters=""

  if [[ "${value:0:5}" == '\033[' && "${value: -1}" == "m" ]]; then
    parameters="${value:5:${#value}-6}"
  elif [[ "${value:0:2}" == $'\033[' && "${value: -1}" == "m" ]]; then
    parameters="${value:2:${#value}-3}"
  else
    return 1
  fi

  [[ "$parameters" =~ ^[0-9]+(\;[0-9]+)*$ ]]
}

# Store a custom color by name.
_moma_config_set_color() {
  local name="$1"
  local value="$2"
  local index

  for ((index = 0; index < ${#_MOMA_CONFIG_COLOR_NAMES[@]}; index++)); do
    if [[ "${_MOMA_CONFIG_COLOR_NAMES[$index]}" == "$name" ]]; then
      _MOMA_CONFIG_COLOR_VALUES[index]="$value"
      return 0
    fi
  done

  _MOMA_CONFIG_COLOR_NAMES+=("$name")
  _MOMA_CONFIG_COLOR_VALUES+=("$value")
}

# Print a custom color value by name.
_moma_config_color_value() {
  local name="${1,,}"
  local index

  for ((index = 0; index < ${#_MOMA_CONFIG_COLOR_NAMES[@]}; index++)); do
    if [[ "${_MOMA_CONFIG_COLOR_NAMES[$index]}" == "$name" ]]; then
      printf '%s' "${_MOMA_CONFIG_COLOR_VALUES[$index]}"
      return 0
    fi
  done
  return 1
}

# Return success for a built-in color name or alias.
_moma_config_is_builtin_color() {
  case "${1,,}" in
    black | red | green | yellow | blue | purple | cyan | white | pink | \
      gray | grey | muted | warning | warn | info | reset | default | none | \
      no | false)
      return 0
      ;;
  esac
  return 1
}

# Return success for a built-in or configured color name.
_moma_config_color_exists() {
  _moma_config_is_builtin_color "$1" ||
    _moma_config_color_value "$1" >/dev/null
}

# Return success when a theme section was parsed.
_moma_config_theme_is_seen() {
  local requested="$1"
  local theme
  for theme in "${_MOMA_CONFIG_THEME_SEEN[@]}"; do
    if [[ "$theme" == "$requested" ]]; then
      return 0
    fi
  done
  return 1
}

# Record a theme name once while retaining configuration-file order.
_moma_config_add_theme() {
  local name="$1"
  if _moma_config_theme_is_seen "$name"; then
    return 0
  fi

  _MOMA_CONFIG_THEME_SEEN+=("$name")
  if [[ "$name" != "default" ]]; then
    _MOMA_CONFIG_THEME_ORDER+=("$name")
  fi
}

# Store a configured theme role.
_moma_config_set_theme_value() {
  local key="$1"
  local value="$2"
  local index

  for ((index = 0; index < ${#_MOMA_CONFIG_THEME_KEYS[@]}; index++)); do
    if [[ "${_MOMA_CONFIG_THEME_KEYS[$index]}" == "$key" ]]; then
      _MOMA_CONFIG_THEME_VALUES[index]="$value"
      return 0
    fi
  done

  _MOMA_CONFIG_THEME_KEYS+=("$key")
  _MOMA_CONFIG_THEME_VALUES+=("$value")
}

# Print a configured theme role.
_moma_config_theme_value() {
  local key="$1"
  local index

  for ((index = 0; index < ${#_MOMA_CONFIG_THEME_KEYS[@]}; index++)); do
    if [[ "${_MOMA_CONFIG_THEME_KEYS[$index]}" == "$key" ]]; then
      printf '%s' "${_MOMA_CONFIG_THEME_VALUES[$index]}"
      return 0
    fi
  done
  return 1
}

# Store a parser error without writing during library initialization.
_moma_config_fail() {
  local line_number="$1"
  local message="$2"
  _MOMA_CONFIG_ERROR="${_MOMA_CONFIG_PATH}:${line_number}: ${message}"
  return 1
}

# Validate all custom colors and theme roles after parsing.
_moma_config_validate() {
  local index key role value
  local -a roles=(
    primary
    accent
    muted
    success
    error
    warning
    info
  )

  if ! _moma_config_theme_is_seen default; then
    _moma_config_fail 0 "missing required [theme default] section"
    return 1
  fi

  for ((index = 0; index < ${#_MOMA_CONFIG_COLOR_NAMES[@]}; index++)); do
    if ! _moma_config_is_sgr "${_MOMA_CONFIG_COLOR_VALUES[$index]}"; then
      _moma_config_fail 0 \
        "color '${_MOMA_CONFIG_COLOR_NAMES[$index]}' must be an ANSI SGR sequence"
      return 1
    fi
  done

  for role in "${roles[@]}"; do
    key="default.$role"
    if ! value="$(_moma_config_theme_value "$key")" ||
      [[ -z "$value" ]]; then
      _moma_config_fail 0 \
        "theme 'default' is missing the '$role' role"
      return 1
    fi
  done

  for value in "${_MOMA_CONFIG_THEME_VALUES[@]}"; do
    if ! _moma_config_color_exists "$value" &&
      ! _moma_config_is_sgr "$value"; then
      _moma_config_fail 0 \
        "theme color '$value' is not defined"
      return 1
    fi
  done
}

# Parse a declarative Moma color and theme configuration.
_moma_load_config() {
  local path="$1"
  local raw_line line section="" name key value theme_name
  local line_number=0
  local saved_error=""

  _moma_config_reset
  _MOMA_CONFIG_PATH="$path"

  if [[ ! -r "$path" ]]; then
    _moma_config_fail 0 "configuration file is not readable"
    return 1
  fi

  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line_number=$((line_number + 1))
    line="$(_moma_trim "$raw_line")"

    if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
      continue
    fi

    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
      section="$(_moma_trim "${BASH_REMATCH[1]}")"
      if [[ "$section" == "colors" ]]; then
        continue
      fi
      if [[ "$section" =~ ^theme[[:space:]]+([a-zA-Z0-9_-]+)$ ]]; then
        theme_name="${BASH_REMATCH[1],,}"
        section="theme:$theme_name"
        _moma_config_add_theme "$theme_name"
        continue
      fi
      _moma_config_fail "$line_number" "unknown section [$section]"
      return 1
    fi

    if [[ "$line" != *=* ]]; then
      _moma_config_fail "$line_number" "expected name = value"
      return 1
    fi

    key="$(_moma_trim "${line%%=*}")"
    value="$(_moma_trim "${line#*=}")"
    if [[ -z "$key" || -z "$value" ]]; then
      _moma_config_fail "$line_number" "name and value cannot be empty"
      return 1
    fi

    case "$section" in
      colors)
        name="${key,,}"
        if [[ ! "$name" =~ ^[a-z][a-z0-9_-]*$ ]]; then
          _moma_config_fail "$line_number" "invalid color name '$key'"
          return 1
        fi
        if _moma_config_is_builtin_color "$name"; then
          _moma_config_fail "$line_number" \
            "color name '$name' is reserved"
          return 1
        fi
        _moma_config_set_color "$name" "$value"
        ;;
      theme:*)
        theme_name="${section#theme:}"
        key="${key,,}"
        case "$key" in
          primary | accent | muted | success | error | warning | info)
            _moma_config_set_theme_value "$theme_name.$key" "$value"
            ;;
          *)
            _moma_config_fail "$line_number" \
              "unknown theme role '$key'"
            return 1
            ;;
        esac
        ;;
      *)
        _moma_config_fail "$line_number" \
          "define values inside [colors] or [theme name]"
        return 1
        ;;
    esac
  done <"$path"

  if ! _moma_config_validate; then
    saved_error="$_MOMA_CONFIG_ERROR"
    _moma_config_reset
    _MOMA_CONFIG_ERROR="$saved_error"
    return 1
  fi
}

# Resolve one role from a selected theme with default-theme inheritance.
_moma_theme_role() {
  local theme="$1"
  local role="$2"
  local selected_key="$theme.$role"
  local default_key="default.$role"
  local value=""

  if value="$(_moma_config_theme_value "$selected_key")"; then
    printf '%s' "$value"
    return 0
  fi
  _moma_config_theme_value "$default_key"
}

# Apply a configured theme while preserving explicit environment overrides.
_moma_apply_theme() {
  local theme="${1:-default}"
  local primary accent muted success error warning info
  theme="${theme,,}"

  if [[ -n "$_MOMA_CONFIG_LOAD_ERROR" ]]; then
    _MOMA_CONFIG_ERROR="$_MOMA_CONFIG_LOAD_ERROR"
    return 1
  fi
  if [[ "$theme" != "default" ]] &&
    ! _moma_config_theme_is_seen "$theme"; then
    _MOMA_CONFIG_ERROR="theme '$theme' is not defined in $_MOMA_CONFIG_PATH"
    return 1
  fi

  if _moma_config_theme_is_seen default; then
    primary="$(_moma_theme_role "$theme" primary)"
    accent="$(_moma_theme_role "$theme" accent)"
    muted="$(_moma_theme_role "$theme" muted)"
    success="$(_moma_theme_role "$theme" success)"
    error="$(_moma_theme_role "$theme" error)"
    warning="$(_moma_theme_role "$theme" warning)"
    info="$(_moma_theme_role "$theme" info)"

    if [[ -z "$_MOMA_ENV_COLOR_PRIMARY_SET" ]]; then
      MOMA_COLOR_PRIMARY="$primary"
    fi
    if [[ -z "$_MOMA_ENV_COLOR_ACCENT_SET" ]]; then
      MOMA_COLOR_ACCENT="$accent"
    fi
    if [[ -z "$_MOMA_ENV_COLOR_MUTED_SET" ]]; then
      MOMA_COLOR_MUTED="$muted"
    fi
    if [[ -z "$_MOMA_ENV_COLOR_SUCCESS_SET" ]]; then
      MOMA_COLOR_SUCCESS="$success"
    fi
    if [[ -z "$_MOMA_ENV_COLOR_ERROR_SET" ]]; then
      MOMA_COLOR_ERROR="$error"
    fi
    if [[ -z "$_MOMA_ENV_COLOR_WARNING_SET" ]]; then
      MOMA_COLOR_WARNING="$warning"
    fi
    if [[ -z "$_MOMA_ENV_COLOR_INFO_SET" ]]; then
      MOMA_COLOR_INFO="$info"
    fi
  fi

  MOMA_THEME="$theme"
  _MOMA_CONFIG_ERROR=""
}

# Print all available themes and mark the active selection.
_moma_list_themes() {
  local theme suffix
  for theme in "${_MOMA_CONFIG_THEME_ORDER[@]}"; do
    suffix=""
    if [[ "$theme" == "${MOMA_THEME:-default}" ]]; then
      suffix=" (active)"
    fi
    printf '%s%s\n' "$theme" "$suffix"
  done
}

# Load the configuration without producing output when the library is sourced.
_moma_initialize_config() {
  local saved_error=""
  MOMA_THEME="${MOMA_THEME:-default}"

  if ! _MOMA_CONFIG_PATH="$(_moma_config_path)"; then
    _MOMA_CONFIG_PATH="<home>/.config/momaui/moma.confg"
  fi

  if [[ -f "$_MOMA_CONFIG_PATH" ]]; then
    if ! _moma_load_config "$_MOMA_CONFIG_PATH"; then
      _MOMA_CONFIG_LOAD_ERROR="$_MOMA_CONFIG_ERROR"
      return 1
    fi
  fi

  if ! _moma_apply_theme "$MOMA_THEME"; then
    saved_error="$_MOMA_CONFIG_ERROR"
    _MOMA_CONFIG_ERROR="$saved_error"
    return 1
  fi
}

_moma_initialize_config || :
