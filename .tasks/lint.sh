#!/bin/bash
#
# Build Moma and run syntax, ShellCheck, and formatting checks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.tasks/common.sh
source "${SCRIPT_DIR}/common.sh"

"${TASKS_REPO_ROOT}/build.sh"
bash -n "${TASKS_SHELL_FILES[@]}" "${TASKS_REPO_ROOT}/dist/moma"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x "${TASKS_SHELL_FILES[@]}"
  shellcheck -s bash "${TASKS_BATS_FILES[@]}"
else
  printf '%s\n' 'ShellCheck not installed; skipped lint.'
fi

shfmt_bin="$("${SCRIPT_DIR}/ensure_shfmt.sh")"
"${shfmt_bin}" -d -i 2 -ci "${TASKS_SHELL_FILES[@]}"
"${shfmt_bin}" -d -ln bats -i 2 -ci "${TASKS_BATS_FILES[@]}"
