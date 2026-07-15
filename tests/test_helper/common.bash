MOMA_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
MOMA_DIST="$MOMA_ROOT/dist/moma"

build_moma () {
    "$MOMA_ROOT/build.sh" >/dev/null
}
