#!/bin/bash
#
# Build Moma and run the required Bats suites.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.tasks/common.sh
source "${SCRIPT_DIR}/common.sh"

"${TASKS_REPO_ROOT}/build.sh"

if ! command -v bats >/dev/null 2>&1; then
  printf '%s\n' 'Bats is required.' >&2
  exit 1
fi

bats "${TASKS_BATS_FILES[@]}"
