# Embedded browser preview server.
# Materialize embedded web assets and serve them from a temporary directory.
_moma_preview_web() {
  local port="${MOMA_PREVIEW_PORT:-4173}"

  if [[ ! "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
    printf 'moma preview web: invalid MOMA_PREVIEW_PORT: %s\n' "$port" >&2
    return 1
  fi
  if ! command -v python3 &>/dev/null; then
    printf 'moma preview web: python3 is required\n' >&2
    return 1
  fi

  local preview_dir
  preview_dir="$(mktemp -d "${TMPDIR:-/tmp}/moma-web.XXXXXX")" || return 1
  _moma_preview_web_index >"$preview_dir/index.html"
  _moma_preview_web_styles >"$preview_dir/styles.css"
  _moma_preview_web_script >"$preview_dir/app.js"

  (
    trap 'rm -rf "$preview_dir"' EXIT
    cd "$preview_dir" || exit 1
    python3 - "$port" <<'PY'
import errno
import http.server
import sys

requested_port = int(sys.argv[1])
last_port = min(requested_port + 100, 65535)
server = None

for candidate_port in range(requested_port, last_port + 1):
    try:
        server = http.server.ThreadingHTTPServer(
            ("127.0.0.1", candidate_port),
            http.server.SimpleHTTPRequestHandler,
        )
        break
    except OSError as error:
        if error.errno != errno.EADDRINUSE:
            print(f"moma preview web: {error}", file=sys.stderr)
            raise SystemExit(1) from None

if server is None:
    print(
        f"moma preview web: no free port from {requested_port} to {last_port}",
        file=sys.stderr,
    )
    raise SystemExit(1)

selected_port = server.server_address[1]
if selected_port != requested_port:
    print(
        f"Port {requested_port} is already in use; "
        f"using {selected_port} instead.",
        flush=True,
    )

print(f"Moma web preview: http://127.0.0.1:{selected_port}", flush=True)
print("Press Ctrl+C to stop.", flush=True)

try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
PY
  )
}
