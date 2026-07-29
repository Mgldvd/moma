#!/bin/bash
#
# Build the standalone Moma artifact.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.tasks/common.sh
source "${SCRIPT_DIR}/common.sh"

"${TASKS_REPO_ROOT}/build.sh"
