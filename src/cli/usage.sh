# CLI help rendering.
# Print plain-text CLI help.
_moma_usage_plain() {
  cat <<'EOF'
Moma - terminal UI components for Bash

Usage:
  moma <command> [arguments] [options]
  source dist/moma

Commands:
EOF
  local command _function description
  while IFS=$'\t' read -r command _function description; do
    printf '  %-15s %s\n' "$command" "$description"
  done < <(_moma_command_registry)
  cat <<'EOF'
  themes          List configured color themes.
  preview         Show terminal, Markdown, or browser previews.

Options:
  --theme NAME  Use a configured color theme.
  -h, --help    Show this help.

Library example:
  source dist/moma
  moma-msg "Ready" --success

Binary example:
  ./dist/moma msg "Ready" --success
EOF
}

# Render embedded help with Glow or fall back to plain text.
_moma_usage() {
  local width="${MOMA_HELP_WIDTH:-${COLUMNS:-100}}"

  if [[ ! "$width" =~ ^[0-9]+$ ]] || ((width < 20)); then
    width=100
  fi

  if command -v glow &>/dev/null; then
    if _moma_help_markdown | glow -w "$width" -; then
      return 0
    fi
  fi

  _moma_usage_plain
}
