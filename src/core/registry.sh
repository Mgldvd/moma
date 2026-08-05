# command<TAB>function<TAB>description
# Print the canonical public command registry.
_moma_command_registry() {
  cat <<'EOF'
header	moma-header	Print a Pagga ASCII heading.
title	moma-title	Print a title and subtitle.
title-sub	moma-title-sub	Print a secondary title.
sub-title	moma-sub-title	Print a rule-first secondary title.
section	moma-section	Print a section heading.
msg	moma-msg	Print a styled message.
msg-simple	moma-msg-simple	Print a compact message.
list	moma-list	Print an unordered list.
box	moma-box	Print a boxed message.
resume	moma-resume	Print a titled, colored content block.
divider	moma-divider	Print a marker-led horizontal rule.
prompt	moma-prompt	Print a prompt.
label	moma-label	Print a decorated label.
input	moma-input	Print or read an input field.
select	moma-select	Select one value (alias for single-select).
single-select	moma-single-select	Select one value.
single-select-groups	moma-single-select-groups	Select one value across named groups.
multi-select	moma-multi-select	Select multiple values.
multi-select-groups	moma-multi-select-groups	Select multiple values across named groups.
rabbit	moma-rabbit	Print the Moma rabbit.
confirm	moma-confirm	Select Yes or No.
spinner	moma-spinner	Follow a process.
command-check	moma-command-check	Check executable dependencies.
version	moma-version	Print the installed version.
update	moma-update	Download and install the latest version.
EOF
}

# Resolve a command name to its public function name.
_moma_command_function() {
  local requested="$1"
  local command function _description
  while IFS=$'\t' read -r command function _description; do
    if [[ "$command" == "$requested" ]]; then
      printf '%s' "$function"
      return 0
    fi
  done < <(_moma_command_registry)
  return 1
}
