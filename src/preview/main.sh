# Terminal preview and preview dispatcher.
# Print terminal-preview usage information.
_moma_preview_usage() {
  cat <<'EOF'
Moma component preview

Usage:
  moma preview
  moma preview md
  moma preview web

Options:
  -h, --help   Show this help.
EOF
}

# Parse terminal-preview options into dynamically scoped state.
_moma_preview_parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        _moma_preview_usage
        return 2
        ;;
      *)
        printf 'moma preview: unknown option: %s\n\n' "$1" >&2
        _moma_preview_usage >&2
        return 1
        ;;
    esac
  done
}

# Print the resolved terminal-preview width.
_moma_preview_width() {
  local width
  width="$(_moma_term_width 88)"
  if ((width < 56)); then
    width=56
  elif ((width > 100)); then
    width=100
  fi
  printf '%s' "$width"
}

# Print a rule spanning the terminal-preview width.
_moma_preview_line() {
  _moma_repeat_char "${1:--}" "$_moma_preview_width_value"
}

# Print the terminal-preview header and semantic legend.
_moma_preview_header() {
  if [[ -t 1 ]]; then
    clear 2>/dev/null || true
  fi
  printf '\n%b%s\n' "$MOMA_COLOR_GRAY" "$(_moma_preview_line '━')"
  printf '  MOMA  COMPONENT GALLERY\n'
  printf '  Visual reference for the public terminal UI API\n'
  printf '%s\n\n' "$(_moma_preview_line '━')"
  printf '  Legend  %b● success%b  %b● error%b  %b● warning%b  %b● info%b\n\n' \
    "$(_moma_resolve_color "$MOMA_COLOR_SUCCESS")" "$MOMA_COLOR_RESET" \
    "$(_moma_resolve_color "$MOMA_COLOR_ERROR")" "$MOMA_COLOR_RESET" \
    "$(_moma_resolve_color "$MOMA_COLOR_WARNING")" "$MOMA_COLOR_RESET" \
    "$(_moma_resolve_color "$MOMA_COLOR_INFO")" "$MOMA_COLOR_RESET"
}

# Print one numbered terminal-preview section heading.
_moma_preview_section() {
  local index="$1"
  local title="$2"
  local description="$3"
  printf '\n%b%s\n' "$MOMA_COLOR_GRAY" "$(_moma_preview_line '─')"
  printf '  %s  %s\n' "$index" "$title"
  printf '      %s\n' "$description"
  printf '%s%b\n\n' "$(_moma_preview_line '─')" "$MOMA_COLOR_RESET"
}

# Print one component example and invoke its renderer.
_moma_preview_component() {
  local name="$1"
  local example="$2"
  local renderer="$3"

  printf '%b┌─ %s\n' "$MOMA_COLOR_GRAY" "$name"
  printf '│  %b$%b %s\n' "$MOMA_COLOR_PINK" "$MOMA_COLOR_GRAY" "$example"
  printf '└─ %boutput%b:\n\n' "$MOMA_COLOR_GRAY" "$MOMA_COLOR_RESET"
  "$renderer"
  printf '\n\n'
}

# Render the primary-title examples.
_moma_preview_render_title() {
  moma-title "Moma" "Terminal UI library"
  moma-title "Backup" "Nightly job" --success --border line
  moma-title "Moma" "Terminal UI library" --no-icon --border open
}

# Render Pagga ASCII header examples.
_moma_preview_render_header() {
  moma-header "Moma" --color cyan --margin-top 0 --margin-bottom 0
}

# Render the secondary-title examples.
_moma_preview_render_title_sub() {
  moma-title-sub "Deployment" "Production environment"
  moma-title-sub "Tests" "Running suite" --border mirror
  moma-title-sub "Cleanup" --no-icon --border line
}

# Render the rule-first secondary-title examples.
_moma_preview_render_sub_title() {
  moma-sub-title "Deployment" "Production environment"
  moma-sub-title "Moma" "Terminal UI library" --border line
  moma-sub-title "Moma" "Terminal UI library" --no-icon --border open
}

# Render the section-heading examples.
_moma_preview_render_sections() {
  moma-section "Dependencies ready" --success
  moma-section "Configuration failed" --error
  moma-section "Review required" --warning
  moma-section "Next step" --info
}

# Render the semantic-message examples.
_moma_preview_render_messages() {
  moma-msg "Package installed" --success
  moma-msg "Connection refused" --error
  moma-msg "Using cached version" --warning
  moma-msg "Downloading metadata" --info
  moma-msg "Custom presentation" --icon "◆" --color pink
}

# Render the compact-message examples.
_moma_preview_render_simple_message() {
  moma-msg-simple "Package installed"
  moma-msg-simple "Package installation failed" --error
}

# Render the list examples.
_moma_preview_render_list() {
  moma-list "Clone repository" "Install dependencies" "Start application"
  moma-list "Database ready" "Cache ready" --success
}

# Render the framed-box examples.
_moma_preview_render_boxes() {
  moma-box "Your configuration is ready." --success
  moma-box "Back up your files before continuing." --warning
  moma-box "Connection refused." --error
}

# Render the resume examples.
_moma_preview_render_resumes() {
  moma-resume --title "Shells" --color blue \
    --item "Bash" "GNU command shell and scripting environment." \
    --item "Zsh" "Interactive shell with advanced completion."
  moma-resume --title "Review" --warning \
    --item "Environment" "production" \
    --text "Confirm the target before deploying."
  moma-resume --title "Notes" --no-icon --border open \
    --text "Freeform text without a definition list."
}

# Render the divider examples.
_moma_preview_render_dividers() {
  moma-divider
  moma-divider --success --border line
  moma-divider --icon "★" --border line
}

# Render the label examples.
_moma_preview_render_label() {
  moma-label "TEXT HERE"
  moma-label "DEPLOYMENT" --success
  moma-label "END OF REPORT" --edge bottom --border open
}

# Render the input-field examples.
_moma_preview_render_inputs() {
  moma-input --title "Project name" --placeholder "my-project"
  moma-input --title "Environment" --value "production" --info
  moma-input --title "Danger zone" --warning --color yellow
}

# Render the prompt examples.
_moma_preview_render_prompt() {
  printf 'Yes, continue\n' | moma-prompt "Continue with the installation?" 2>&1
  printf '\n' | moma-prompt "Deploy now?" --default "yes" 2>&1
}

# Render the single-selection examples.
_moma_preview_render_select() {
  {
    moma-single-select \
      "Development" "Staging" "Production" \
      --title "Environment" --choose 2 >/dev/null
  } 2>&1
}

# Render the grouped single-selection examples.
_moma_preview_render_single_select_groups() {
  {
    moma-single-select-groups \
      --title "Features" \
      --group "Docker" --option "Up" --option "Down" --option "Stop" \
      --group "npm" --option "install" --option "run dev" \
      --option "run deploy" \
      --choose 4 >/dev/null
  } 2>&1
}

# Render the multiple-selection examples.
_moma_preview_render_multi_select() {
  {
    moma-multi-select \
      "Docker" "CI" "Tests" \
      --title "Features" --choose 1,3 >/dev/null
  } 2>&1
}

# Render the grouped multiple-selection examples.
_moma_preview_render_multi_select_groups() {
  {
    moma-multi-select-groups \
      --title "Features" \
      --group "North America" \
      --option "United States" --option "Canada" --option "Mexico" \
      --group "South America" \
      --option "Colombia" --option "Argentina" --option "Peru" \
      --choose 1,3 >/dev/null
  } 2>&1
}

# Render the rabbit examples.
_moma_preview_render_rabbits() {
  moma-rabbit "Preparing workspace" --info
  printf '\n'
  moma-rabbit "Task completed" --success
  printf '\n'
  moma-rabbit "Build needs attention" --warning
}

# Render the confirmation examples.
_moma_preview_render_confirm() {
  moma-confirm "Continue with deployment?" --default yes --answer yes 2>&1
}

# Render the process-spinner examples.
_moma_preview_render_spinner() {
  sleep 0.05 &
  local pid=$!
  moma-spinner "$pid" "Preparing workspace" --delay 0.01
}

# Render the command-availability examples.
_moma_preview_render_command_check() {
  moma-command-check bash curl
}

# Print terminal-preview follow-up commands.
_moma_preview_footer() {
  printf '%b%s\n' "$MOMA_COLOR_GRAY" "$(_moma_preview_line '━')"
  printf '  Browser docs  moma preview web\n'
  printf '  Markdown docs  moma preview md\n'
  printf '  Library help  moma help\n'
  printf '%s%b\n\n' "$(_moma_preview_line '━')" "$MOMA_COLOR_RESET"
}

# Dispatch Markdown, browser, and terminal previews.
_moma_preview() {
  case "${1:-}" in
    md)
      shift
      _moma_preview_reject_extra_args md "$@" || return 1
      _moma_preview_markdown
      return 0
      ;;
    web)
      shift
      _moma_preview_reject_extra_args web "$@" || return 1
      _moma_preview_web
      return $?
      ;;
  esac

  local _moma_preview_width_value
  _moma_preview_width_value="$(_moma_preview_width)"

  if [[ -n "${NO_COLOR:-}" ]]; then
    # Previewed components consume these locals through Bash dynamic scope.
    # shellcheck disable=SC2034
    local \
      MOMA_COLOR_RESET="" \
      MOMA_STYLE_WHITE_BOLD="" \
      MOMA_STYLE_CYAN_BOLD="" \
      MOMA_COLOR_GRAY="" \
      MOMA_COLOR_PINK="" \
      MOMA_COLOR_CYAN="" \
      MOMA_COLOR_GREEN="" \
      MOMA_COLOR_RED="" \
      MOMA_COLOR_YELLOW="" \
      MOMA_COLOR_SUCCESS="" \
      MOMA_COLOR_ERROR="" \
      MOMA_COLOR_WARNING="" \
      MOMA_COLOR_INFO="" \
      MOMA_COLOR_PRIMARY="" \
      MOMA_COLOR_ACCENT="" \
      MOMA_COLOR_MUTED=""
  fi

  local parse_status=0
  _moma_preview_parse_args "$@" || parse_status=$?
  if ((parse_status == 2)); then
    return 0
  elif ((parse_status != 0)); then
    return "$parse_status"
  fi

  _moma_preview_header

  # Section grouping and order mirror the website's own (see
  # DocsNav.data.ts's GROUP_ORDER/GROUP_HEADINGS, derived from each
  # apiEntries.ts entry's `group` field) so the terminal and browser
  # previews read as the same catalogue. "self" (moma talking about
  # itself - update/version/preview/help) has no visual output worth
  # previewing here and is intentionally left out.
  _moma_preview_section \
    "01" "Visual" \
    "Print-only components for structure, status, and layout."
  _moma_preview_component \
    "moma-header" \
    'moma header "Moma" --color cyan --margin-top 0 --margin-bottom 0' \
    _moma_preview_render_header
  _moma_preview_component \
    "moma-title" \
    'moma title "Moma" "Terminal UI library"' \
    _moma_preview_render_title
  _moma_preview_component \
    "moma-title-sub" \
    'moma title-sub "Deployment" "Production environment"' \
    _moma_preview_render_title_sub
  _moma_preview_component \
    "moma-sub-title" \
    'moma sub-title "Deployment" "Production environment"' \
    _moma_preview_render_sub_title
  _moma_preview_component \
    "moma-section" \
    'moma section "Dependencies ready" --success' \
    _moma_preview_render_sections
  _moma_preview_component \
    "moma-msg" \
    'moma msg "Package installed" --success' \
    _moma_preview_render_messages
  _moma_preview_component \
    "moma-msg-simple" \
    'moma msg-simple "Package installed"' \
    _moma_preview_render_simple_message
  _moma_preview_component \
    "moma-list" \
    'moma list "Clone repository" "Install dependencies"' \
    _moma_preview_render_list
  _moma_preview_component \
    "moma-box" \
    'moma box "Your configuration is ready." --success' \
    _moma_preview_render_boxes
  _moma_preview_component \
    "moma-resume" \
    'moma resume --title "Shells" --item "Bash" "GNU command shell." ...' \
    _moma_preview_render_resumes
  _moma_preview_component \
    "moma-divider" \
    'moma divider --success --border line' \
    _moma_preview_render_dividers
  _moma_preview_component \
    "moma-label" \
    'moma label "TEXT HERE"' \
    _moma_preview_render_label

  _moma_preview_section \
    "02" "Interactive" \
    "Components that read a value or a choice back from the user."
  _moma_preview_component \
    "moma-input" \
    'moma input --title "Project name" --placeholder "my-project"' \
    _moma_preview_render_inputs
  _moma_preview_component \
    "moma-prompt" \
    'answer="$(moma prompt "Continue?")"' \
    _moma_preview_render_prompt
  _moma_preview_component \
    "moma-confirm" \
    'moma confirm "Continue?" --default yes' \
    _moma_preview_render_confirm

  _moma_preview_section \
    "03" "Selection" \
    "Arrow-key pickers for one or more choices."
  _moma_preview_component \
    "moma-select" \
    'moma select "Development" "Staging" "Production" --title "Environment"' \
    _moma_preview_render_select
  _moma_preview_component \
    "moma-single-select-groups" \
    'moma single-select-groups --title "Features" --group "Docker" --option "Up" ...' \
    _moma_preview_render_single_select_groups
  _moma_preview_component \
    "moma-multi-select" \
    'moma multi-select "Docker" "CI" "Tests"' \
    _moma_preview_render_multi_select
  _moma_preview_component \
    "moma-multi-select-groups" \
    'moma multi-select-groups --title "Features" --group "North America" --option "United States" ...' \
    _moma_preview_render_multi_select_groups

  _moma_preview_section \
    "04" "Decorative" \
    "Branded flourishes with no functional role."
  _moma_preview_component \
    "moma-rabbit" \
    'moma rabbit "Preparing workspace" --info' \
    _moma_preview_render_rabbits

  _moma_preview_section \
    "05" "Utils" \
    "Process and environment helpers for Bash workflows."
  local spinner_example="moma spinner \"\$pid\" \"Preparing workspace\""
  _moma_preview_component \
    "moma-spinner" \
    "$spinner_example" \
    _moma_preview_render_spinner
  _moma_preview_component \
    "moma-command-check" \
    'moma command-check bash curl' \
    _moma_preview_render_command_check

  _moma_preview_footer
}
