#!/bin/bash
#
# Format all Shell and Bats source files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.tasks/common.sh
source "${SCRIPT_DIR}/common.sh"

shfmt_bin="$("${SCRIPT_DIR}/ensure_shfmt.sh")"

"${shfmt_bin}" -w -i 2 -ci "${TASKS_SHELL_FILES[@]}"
"${shfmt_bin}" -w -ln bats -i 2 -ci "${TASKS_BATS_FILES[@]}"
