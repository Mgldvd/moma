# Shared build paths and helpers for the Moma Bats suites.
MOMA_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
# shellcheck disable=SC2034  # Loaded into each Bats test file.
MOMA_DIST="$MOMA_ROOT/dist/moma"
MOMA_CONFIG_FILE="$MOMA_ROOT/tests/fixtures/not-present.confg"
export MOMA_CONFIG_FILE

# Build the generated Moma artifact for a Bats suite.
build_moma() {
  "$MOMA_ROOT/build.sh" >/dev/null
}
