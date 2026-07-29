#!/bin/bash
#
# Resolve shfmt or download a pinned verified binary for the current platform.

set -euo pipefail

readonly SHFMT_VERSION='3.13.1'
readonly SHFMT_RELEASE_URL="https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}"

# Print the SHA-256 digest of a file.
_tasks_sha256() {
  local file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${file}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${file}" | awk '{print $1}'
  else
    printf '%s\n' 'sha256sum or shasum is required to verify shfmt.' >&2
    return 1
  fi
}

if command -v shfmt >/dev/null 2>&1; then
  command -v shfmt
  exit 0
fi

os="$(uname -s)"
arch="$(uname -m)"

case "${os}/${arch}" in
  Linux/x86_64)
    asset='shfmt_v3.13.1_linux_amd64'
    expected_sha256='fb096c5d1ac6beabbdbaa2874d025badb03ee07929f0c9ff67563ce8c75398b1'
    ;;
  Linux/aarch64 | Linux/arm64)
    asset='shfmt_v3.13.1_linux_arm64'
    expected_sha256='32d92acaa5cd8abb29fc49dac123dc412442d5713967819d8af2c29f1b3857c7'
    ;;
  Darwin/x86_64)
    asset='shfmt_v3.13.1_darwin_amd64'
    expected_sha256='6feedafc72915794163114f512348e2437d080d0047ef8b8fa2ec63b575f12af'
    ;;
  Darwin/arm64)
    asset='shfmt_v3.13.1_darwin_arm64'
    expected_sha256='9680526be4a66ea1ffe988ed08af58e1400fe1e4f4aef5bd88b20bb9b3da33f8'
    ;;
  *)
    printf 'Unsupported platform for automatic shfmt setup: %s/%s\n' \
      "${os}" "${arch}" >&2
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${script_dir}/bin"
shfmt_bin="${bin_dir}/shfmt-${SHFMT_VERSION}"
mkdir -p "${bin_dir}"

if [[ -f "${shfmt_bin}" ]]; then
  actual_sha256="$(_tasks_sha256 "${shfmt_bin}")"
  if [[ "${actual_sha256}" == "${expected_sha256}" ]]; then
    printf '%s\n' "${shfmt_bin}"
    exit 0
  fi

  printf '%s\n' 'Cached shfmt checksum is invalid; downloading it again.' >&2
fi

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' 'curl is required to download shfmt.' >&2
  exit 1
fi

temporary_file="$(mktemp "${bin_dir}/.shfmt.XXXXXX")"
trap 'rm -f "${temporary_file}"' EXIT

printf 'Downloading shfmt %s for %s/%s...\n' \
  "${SHFMT_VERSION}" "${os}" "${arch}" >&2
curl -fsSL --retry 3 \
  "${SHFMT_RELEASE_URL}/${asset}" \
  -o "${temporary_file}"

actual_sha256="$(_tasks_sha256 "${temporary_file}")"
if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
  printf '%s\n' 'Downloaded shfmt checksum verification failed.' >&2
  exit 1
fi

chmod 0755 "${temporary_file}"
mv "${temporary_file}" "${shfmt_bin}"
trap - EXIT

printf '%s\n' "${shfmt_bin}"
