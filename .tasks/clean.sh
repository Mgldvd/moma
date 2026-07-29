#!/bin/bash
#
# Remove the generated standalone Moma artifact.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.tasks/common.sh
source "${SCRIPT_DIR}/common.sh"

rm -f "${TASKS_REPO_ROOT}/dist/moma"
