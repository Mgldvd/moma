#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_INDEX="$ROOT_DIR/web/index.html"
OUTPUT_DIR="${1:-$ROOT_DIR/.img}"
SCREENSHOT_WIDTH="${SCREENSHOT_WIDTH:-1200}"
SCREENSHOT_HEIGHT="${SCREENSHOT_HEIGHT:-664}"
SCREENSHOT_TIMEOUT="${SCREENSHOT_TIMEOUT:-30}"

if [[ ! "$SCREENSHOT_WIDTH" =~ ^[1-9][0-9]*$ ]] || [[ ! "$SCREENSHOT_HEIGHT" =~ ^[1-9][0-9]*$ ]] || [[ ! "$SCREENSHOT_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
    printf 'generate-screenshots: width, height, and timeout must be positive integers\n' >&2
    exit 1
fi

if [[ ! -f "$WEB_INDEX" ]]; then
    printf 'generate-screenshots: missing web source: %s\n' "$WEB_INDEX" >&2
    exit 1
fi

if [[ -n "${CHROMIUM_BIN:-}" ]]; then
    chromium_bin="$CHROMIUM_BIN"
else
    chromium_bin="$(command -v chromium || command -v chromium-browser || command -v google-chrome || true)"
fi

if [[ -z "$chromium_bin" ]] || [[ ! -x "$chromium_bin" ]]; then
    printf 'generate-screenshots: Chromium was not found; set CHROMIUM_BIN\n' >&2
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    printf 'generate-screenshots: python3 is required to validate PNG dimensions\n' >&2
    exit 1
fi

if ! command -v timeout &>/dev/null; then
    printf 'generate-screenshots: timeout is required to limit Chromium runs\n' >&2
    exit 1
fi

mapfile -t components < <(
    rg -o 'data-api="moma-[a-z-]+' "$WEB_INDEX" \
        | cut -d '"' -f 2 \
        | awk '!seen[$0]++'
)

if (( ${#components[@]} == 0 )); then
    printf 'generate-screenshots: no API components found in %s\n' "$WEB_INDEX" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
page_url="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$WEB_INDEX")"
browser_profile="$(mktemp -d "${TMPDIR:-/tmp}/moma-screenshots.XXXXXX")"
browser_log="$browser_profile/chromium.log"
trap 'rm -rf "$browser_profile"' EXIT

for component in "${components[@]}"; do
    output_file="$OUTPUT_DIR/$component.png"

    if ! timeout --signal=TERM --kill-after=5 "$SCREENSHOT_TIMEOUT" "$chromium_bin" \
        --headless=new \
        --disable-dev-shm-usage \
        --disable-extensions \
        --disable-gpu \
        --force-device-scale-factor=1 \
        --hide-scrollbars \
        --log-level=3 \
        --no-default-browser-check \
        --no-first-run \
        --run-all-compositor-stages-before-draw \
        --user-data-dir="$browser_profile" \
        --virtual-time-budget=1000 \
        --window-size="$SCREENSHOT_WIDTH,$SCREENSHOT_HEIGHT" \
        --screenshot="$output_file" \
        "$page_url?component=$component" \
        2>"$browser_log"; then
        cat "$browser_log" >&2
        exit 1
    fi

    python3 - "$output_file" "$SCREENSHOT_WIDTH" "$SCREENSHOT_HEIGHT" <<'PY'
import struct
import sys

path, expected_width, expected_height = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
with open(path, "rb") as png_file:
    header = png_file.read(24)

if header[:8] != b"\x89PNG\r\n\x1a\n":
    raise SystemExit(f"generate-screenshots: invalid PNG: {path}")

actual_size = struct.unpack(">II", header[16:24])
expected_size = (expected_width, expected_height)
if actual_size != expected_size:
    raise SystemExit(
        f"generate-screenshots: {path} is {actual_size[0]}x{actual_size[1]}, "
        f"expected {expected_width}x{expected_height}"
    )
PY

    printf 'Generated %s (%sx%s)\n' "$output_file" "$SCREENSHOT_WIDTH" "$SCREENSHOT_HEIGHT"
done

printf 'Generated %d component screenshots in %s\n' "${#components[@]}" "$OUTPUT_DIR"
