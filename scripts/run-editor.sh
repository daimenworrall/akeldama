#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EDITOR_DIR="${PROJECT_DIR}/tools/akeldama_editor"
GODOT_BIN="${GODOT_BIN:-${PROJECT_DIR}/third_party/godotsteam/v4.17.1/GodotSteam.app/Contents/MacOS/Godot}"
if [[ ! -x "${GODOT_BIN}" ]]; then
  GODOT_BIN="$(command -v godot)"
fi
# Share game content and resource types directly; never copy authored content.
for shared in assets features; do
  if [[ ! -e "${EDITOR_DIR}/${shared}" ]]; then
    ln -s "../../${shared}" "${EDITOR_DIR}/${shared}"
  fi
done
"${GODOT_BIN}" --headless --path "${EDITOR_DIR}" --editor --import --quit > /tmp/akeldama-editor-import.log 2>&1
exec "${GODOT_BIN}" --path "${EDITOR_DIR}" "$@"
