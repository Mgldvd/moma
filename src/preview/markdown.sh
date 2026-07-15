# Embedded Markdown preview rendering.
_moma_preview_reject_extra_args() {
    local format="$1"
    shift
    if [[ $# -gt 0 ]]; then
        printf 'moma preview %s: unexpected argument: %s\n' "$format" "$1" >&2
        return 1
    fi
}

_moma_preview_markdown() {
    local width="${MOMA_PREVIEW_WIDTH:-${COLUMNS:-100}}"

    if [[ ! "$width" =~ ^[0-9]+$ ]] || ((width < 20)); then
        width=100
    fi

    if command -v glow &>/dev/null; then
        if _moma_docs_markdown_document | glow -w "$width" -; then
            return 0
        fi
    fi

    _moma_docs_markdown_document
}
