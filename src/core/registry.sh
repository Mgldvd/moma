# command<TAB>function<TAB>description
# Print the canonical public command registry.
_moma_command_registry() {
    cat <<'EOF'
title	moma-title	Print a title and subtitle.
title-sub	moma-title-sub	Print a secondary title.
section	moma-section	Print a section heading.
msg	moma-msg	Print a styled message.
msg-simple	moma-msg-simple	Print a compact message.
list	moma-list	Print an unordered list.
box	moma-box	Print a boxed message.
prompt	moma-prompt	Print a prompt.
label	moma-label	Print a decorated label.
input	moma-input	Print or read an input field.
select	moma-select	Select one value.
multi-select	moma-multi-select	Select multiple values.
rabbit	moma-rabbit	Print the Moma rabbit.
confirm	moma-confirm	Select Yes or No.
spinner	moma-spinner	Follow a process.
command-check	moma-command-check	Check executable dependencies.
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
