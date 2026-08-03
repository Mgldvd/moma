# Explicit CLI dispatcher.
# Dispatch one CLI command without evaluating registry data.
_moma_main() {
  local command="${1:-}"
  local registered_function=""
  local theme_option=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --theme)
        if [[ $# -lt 2 ]]; then
          _moma_option_requires_value moma "$1"
          return $?
        fi
        theme_option="$2"
        shift 2
        ;;
      --theme=*)
        theme_option="${1#*=}"
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  command="${1:-}"
  if [[ $# -gt 0 ]]; then
    shift
  fi

  case "$command" in
    "" | -h | --help | help)
      _moma_usage
      return $?
      ;;
  esac

  if [[ -n "$_MOMA_CONFIG_LOAD_ERROR" ]]; then
    _moma_runtime_error moma "$_MOMA_CONFIG_LOAD_ERROR"
    return $?
  fi

  if [[ -n "$theme_option" ]] &&
    ! _moma_apply_theme "$theme_option"; then
    _moma_usage_error moma "$_MOMA_CONFIG_ERROR"
    return $?
  fi

  if [[ -n "$_MOMA_CONFIG_ERROR" ]]; then
    _moma_runtime_error moma "$_MOMA_CONFIG_ERROR"
    return $?
  fi

  if [[ "$command" == "themes" ]]; then
    _moma_list_themes
    return $?
  fi

  if [[ "$command" == "preview" ]]; then
    _moma_preview "$@"
    return $?
  fi

  if ! registered_function="$(_moma_command_function "$command")"; then
    printf 'moma: unknown command: %s\n\n' "$command" >&2
    _moma_usage >&2
    return 1
  fi

  # Keep dispatch explicit. The registry validates metadata; no input is
  # evaluated or expanded into a command name.
  case "$command" in
    header) moma-header "$@" ;;
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
    single-select) moma-single-select "$@" ;;
    single-select-groups) moma-single-select-groups "$@" ;;
    multi-select) moma-multi-select "$@" ;;
    multi-select-groups) moma-multi-select-groups "$@" ;;
    rabbit) moma-rabbit "$@" ;;
    confirm) moma-confirm "$@" ;;
    spinner) moma-spinner "$@" ;;
    command-check) moma-command-check "$@" ;;
    version) moma-version "$@" ;;
    update) moma-update "$@" ;;
    *)
      _moma_runtime_error \
        moma \
        "registered command has no dispatcher: $registered_function"
      ;;
  esac
}
