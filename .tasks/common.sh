#!/bin/bash
#
# Shared repository paths and source-file lists for Task helper scripts.

# shellcheck disable=SC2034
TASKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASKS_REPO_ROOT="$(cd "${TASKS_DIR}/.." && pwd)"
readonly TASKS_DIR
readonly TASKS_REPO_ROOT

# shellcheck disable=SC2034
TASKS_SHELL_FILES=(
    "${TASKS_REPO_ROOT}/build.sh"
    "${TASKS_REPO_ROOT}/generate-screenshots.sh"
    "${TASKS_REPO_ROOT}/example.sh"
    "${TASKS_REPO_ROOT}/tests/smoke.sh"
    "${TASKS_REPO_ROOT}/tests/test_helper/common.bash"
    "${TASKS_DIR}"/*.sh
    "${TASKS_REPO_ROOT}"/src/core/*.sh
    "${TASKS_REPO_ROOT}"/src/components/*.sh
    "${TASKS_REPO_ROOT}"/src/preview/*.sh
    "${TASKS_REPO_ROOT}"/src/cli/*.sh
)
readonly TASKS_SHELL_FILES

# shellcheck disable=SC2034
TASKS_BATS_FILES=(
    "${TASKS_REPO_ROOT}"/tests/unit/*.bats
    "${TASKS_REPO_ROOT}"/tests/integration/*.bats
    "${TASKS_REPO_ROOT}"/tests/contract/*.bats
)
readonly TASKS_BATS_FILES
