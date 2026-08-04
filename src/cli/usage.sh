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
    printf '  %-22s %s\n' "$command" "$description"
  done < <(_moma_command_registry)
  cat <<'EOF'
  themes          List configured color themes.
  preview         Show terminal, Markdown, or browser previews.

Options:
  --theme NAME     Use a configured color theme.
  --version, -v    Print the installed version.
  -h, --help       Show this help.

Example:
  moma msg "Ready" --success

The `moma` command works the same way after sourcing the library or after
installing the executable:
  source dist/moma
  moma msg "Ready" --success

  moma msg "Ready" --success

Backward compatibility:
  Direct moma-* functions (for example moma-msg) remain available after
  sourcing dist/moma for existing scripts.
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
