#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_PATH="${PROJECT_DIR}/build/macos/AKELDAMA.app"
INFO_PLIST="${APP_PATH}/Contents/Info.plist"

if [[ ! -f "${INFO_PLIST}" ]]; then
  echo "Missing app Info.plist: ${INFO_PLIST}" >&2
  echo "Run ./scripts/build/export-macos-universal.sh first." >&2
  exit 1
fi

EXE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "${INFO_PLIST}" 2>/dev/null || true)"
if [[ -z "${EXE_NAME}" ]]; then
  EXE_NAME="$(basename -- "${APP_PATH}" .app)"
fi

BIN_PATH="${APP_PATH}/Contents/MacOS/${EXE_NAME}"
PCK_PATH="${APP_PATH}/Contents/Resources/${EXE_NAME}.pck"

if [[ ! -x "${BIN_PATH}" ]]; then
  echo "Missing exported binary: ${BIN_PATH}" >&2
  echo "Run ./scripts/build/export-macos-universal.sh first." >&2
  exit 1
fi

if [[ ! -f "${PCK_PATH}" ]]; then
  echo "Missing exported pack: ${PCK_PATH}" >&2
  echo "Re-run ./scripts/build/export-macos-universal.sh and check for export errors." >&2
  exit 1
fi

# Run from inside the app bundle so the exported game resolves its own .pck.
cd "${APP_PATH}/Contents/MacOS"
exec env STAGE=prod "${BIN_PATH}" --stage=prod "$@"
