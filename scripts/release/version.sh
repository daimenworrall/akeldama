#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
METADATA_JSON_PATH="${PROJECT_DIR}/metadata.json"

version_get() {
  local version
  [[ -f "${METADATA_JSON_PATH}" ]] || {
    echo "ERROR: Missing version source: ${METADATA_JSON_PATH}" >&2
    exit 1
  }
  version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "${METADATA_JSON_PATH}" | head -n 1)"
  if [[ -z "${version}" ]]; then
    echo "ERROR: Failed to read version from ${METADATA_JSON_PATH}" >&2
    exit 1
  fi
  printf '%s\n' "${version}"
}

_write_version_file() {
  local target_path="$1"
  local version="$2"
  printf '{\n    "version": "%s"\n}\n' "${version}" > "${target_path}"
}

version_set() {
  local version="$1"
  _write_version_file "${METADATA_JSON_PATH}" "${version}"
}

version_bump_patch() {
  local current
  current="$(version_get)"
  IFS='.' read -r major minor patch <<< "${current}"
  if [[ -z "${major:-}" || -z "${minor:-}" || -z "${patch:-}" ]]; then
    echo "ERROR: Version '${current}' is not in major.minor.patch format" >&2
    exit 1
  fi
  local next_patch
  next_patch="$(printf '%03d' "$((10#${patch} + 1))")"
  local next_version="${major}.${minor}.${next_patch}"
  version_set "${next_version}"
  printf '%s\n' "${next_version}"
}
