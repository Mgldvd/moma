# Shared build paths and helpers for the Moma Bats suites.
MOMA_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
# shellcheck disable=SC2034  # Loaded into each Bats test file.
MOMA_DIST="$MOMA_ROOT/dist/moma"

# Build the generated Moma artifact for a Bats suite.
build_moma() {
    "$MOMA_ROOT/build.sh" >/dev/null
}
