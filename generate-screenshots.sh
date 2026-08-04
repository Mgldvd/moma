#!/bin/bash
#
# Generate browser-preview screenshots for every public Moma component.
#
# The docs site is an Astro project (web/) built for GitHub Pages under
# the /moma/ base path, so its internal asset and script URLs are
# base-prefixed. That means it can no longer be screenshotted by pointing
# Chromium at web/index.html as a file:// URL the way the old hand-written
# static site was - the base-prefixed URLs simply don't resolve against
# the filesystem. Instead this script builds the site and serves the
# build output with `astro preview`, which reproduces the /moma/ base
# path locally, then screenshots it over HTTP.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$ROOT_DIR/web"
WEB_DIST_INDEX="$WEB_DIR/dist/index.html"
OUTPUT_DIR="${1:-$ROOT_DIR/.img}"
SCREENSHOT_WIDTH="${SCREENSHOT_WIDTH:-1200}"
SCREENSHOT_HEIGHT="${SCREENSHOT_HEIGHT:-664}"
SCREENSHOT_TIMEOUT="${SCREENSHOT_TIMEOUT:-30}"
PREVIEW_PORT="${PREVIEW_PORT:-4173}"
PREVIEW_BASE_PATH="${PREVIEW_BASE_PATH:-/moma/}"
PREVIEW_READY_TIMEOUT="${PREVIEW_READY_TIMEOUT:-30}"

if [[ ! "$SCREENSHOT_WIDTH" =~ ^[1-9][0-9]*$ ]] ||
  [[ ! "$SCREENSHOT_HEIGHT" =~ ^[1-9][0-9]*$ ]] ||
  [[ ! "$SCREENSHOT_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
  printf '%s%s\n' \
    'generate-screenshots: width, height, and timeout ' \
    'must be positive integers' >&2
  exit 1
fi

if [[ -n "${CHROMIUM_BIN:-}" ]]; then
  chromium_bin="$CHROMIUM_BIN"
else
  chromium_bin="$(
    command -v chromium ||
      command -v chromium-browser ||
      command -v google-chrome ||
      true
  )"
fi

if [[ -z "$chromium_bin" ]] || [[ ! -x "$chromium_bin" ]]; then
  printf 'generate-screenshots: Chromium was not found; set CHROMIUM_BIN\n' >&2
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  printf '%s\n' \
    'generate-screenshots: python3 is required to validate PNG dimensions' >&2
  exit 1
fi

if ! command -v timeout &>/dev/null; then
  printf '%s\n' \
    'generate-screenshots: timeout is required to limit Chromium runs' >&2
  exit 1
fi

if ! command -v npm &>/dev/null; then
  printf 'generate-screenshots: npm is required to build and serve web/\n' >&2
  exit 1
fi

printf 'Building the docs site...\n'
(cd "$WEB_DIR" && npm run build) >&2

if [[ ! -f "$WEB_DIST_INDEX" ]]; then
  printf 'generate-screenshots: build did not produce %s\n' "$WEB_DIST_INDEX" >&2
  exit 1
fi

mapfile -t components < <(
  rg -o 'data-api="moma-[a-z-]+' "$WEB_DIST_INDEX" |
    cut -d '"' -f 2 |
    awk '!seen[$0]++'
)

if ((${#components[@]} == 0)); then
  printf 'generate-screenshots: no API components found in %s\n' \
    "$WEB_DIST_INDEX" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

browser_profile="$(mktemp -d "${TMPDIR:-/tmp}/moma-screenshots.XXXXXX")"
browser_log="$browser_profile/chromium.log"
preview_log="$browser_profile/astro-preview.log"
preview_pid=""

cleanup() {
  if [[ -n "$preview_pid" ]] && kill -0 "$preview_pid" 2>/dev/null; then
    kill "$preview_pid" 2>/dev/null || true
    wait "$preview_pid" 2>/dev/null || true
  fi
  rm -rf "$browser_profile"
}
trap cleanup EXIT

printf 'Starting preview server on port %s...\n' "$PREVIEW_PORT"
(cd "$WEB_DIR" && npm run preview -- --port "$PREVIEW_PORT" --host 127.0.0.1) \
  >"$preview_log" 2>&1 &
preview_pid=$!

page_url="http://127.0.0.1:${PREVIEW_PORT}${PREVIEW_BASE_PATH}"
ready=0
for _ in $(seq 1 "$PREVIEW_READY_TIMEOUT"); do
  if ! kill -0 "$preview_pid" 2>/dev/null; then
    printf 'generate-screenshots: preview server exited early\n' >&2
    cat "$preview_log" >&2
    exit 1
  fi
  if curl -fsS -o /dev/null "$page_url" 2>/dev/null; then
    ready=1
    break
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  printf 'generate-screenshots: preview server never became ready at %s\n' "$page_url" >&2
  cat "$preview_log" >&2
  exit 1
fi

for component in "${components[@]}"; do
  output_file="$OUTPUT_DIR/$component.png"

  if ! timeout \
    --signal=TERM \
    --kill-after=5 \
    "$SCREENSHOT_TIMEOUT" \
    "$chromium_bin" \
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
    --user-data-dir="$browser_profile/chromium-profile" \
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

path = sys.argv[1]
expected_width = int(sys.argv[2])
expected_height = int(sys.argv[3])
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

  printf 'Generated %s (%sx%s)\n' \
    "$output_file" "$SCREENSHOT_WIDTH" "$SCREENSHOT_HEIGHT"
done

printf 'Generated %d component screenshots in %s\n' \
  "${#components[@]}" "$OUTPUT_DIR"
