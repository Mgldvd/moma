#!/bin/bash
#
# Run the smoke suite and every available Bats suite.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.tasks/common.sh
source "${SCRIPT_DIR}/common.sh"

"${TASKS_REPO_ROOT}/build.sh"
"${TASKS_REPO_ROOT}/tests/smoke.sh"

if command -v bats >/dev/null 2>&1; then
    bats "${TASKS_BATS_FILES[@]}"
else
    printf '%s\n' 'Bats not installed; skipped Bats suites.'
fi
