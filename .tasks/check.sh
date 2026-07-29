#!/bin/bash
#
# Run the complete lint and test workflows.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/lint.sh"
"${SCRIPT_DIR}/test.sh"
