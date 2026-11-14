#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

GODOTSTEAM_VERSION="${GODOTSTEAM_VERSION:-v4.17.1}"
STEAMWORKS_TAG="g46-s163-gs4171"
BASE_DIR="${PROJECT_DIR}/third_party/godotsteam/${GODOTSTEAM_VERSION}"

mkdir -p "${BASE_DIR}"
touch "${PROJECT_DIR}/third_party/.gdignore"

download_if_missing() {
  local output_path="$1"
  local url="$2"
  if [[ -f "${output_path}" ]]; then
    echo "Using cached: ${output_path}"
    return
  fi
  echo "Downloading: ${url}"
  curl -fL -o "${output_path}" "${url}"
}

extract_tar_xz() {
  local archive_path="$1"
  local target_dir="$2"
  mkdir -p "${target_dir}"
  tar -xf "${archive_path}" -C "${target_dir}"
}

# Optional: pull all editor archives (linux/windows) for local cache mirroring.
# This is disabled by default because exports only need macOS editor + templates.
if [[ "${DOWNLOAD_ALL_EDITOR_ARCHIVES:-0}" == "1" ]]; then
  download_if_missing "${BASE_DIR}/linux64-${STEAMWORKS_TAG}-editor.tar.xz" "https://codeberg.org/godotsteam/godotsteam/releases/download/${GODOTSTEAM_VERSION}/linux64-${STEAMWORKS_TAG}-editor.tar.xz"
  download_if_missing "${BASE_DIR}/linuxarm64-${STEAMWORKS_TAG}-editor.tar.xz" "https://codeberg.org/godotsteam/godotsteam/releases/download/${GODOTSTEAM_VERSION}/linuxarm64-${STEAMWORKS_TAG}-editor.tar.xz"
  download_if_missing "${BASE_DIR}/win32-${STEAMWORKS_TAG}-editor.tar.xz" "https://codeberg.org/godotsteam/godotsteam/releases/download/${GODOTSTEAM_VERSION}/win32-${STEAMWORKS_TAG}-editor.tar.xz"
  download_if_missing "${BASE_DIR}/win64-${STEAMWORKS_TAG}-editor.tar.xz" "https://codeberg.org/godotsteam/godotsteam/releases/download/${GODOTSTEAM_VERSION}/win64-${STEAMWORKS_TAG}-editor.tar.xz"
fi
download_if_missing "${BASE_DIR}/macos-${STEAMWORKS_TAG}-editor.tar.xz" "https://github.com/GodotSteam/GodotSteam/releases/download/${GODOTSTEAM_VERSION}/macos-${STEAMWORKS_TAG}-editor.tar.xz"
download_if_missing "${BASE_DIR}/godotsteam-${STEAMWORKS_TAG}-templates.tar.xz" "https://github.com/GodotSteam/GodotSteam/releases/download/${GODOTSTEAM_VERSION}/godotsteam-${STEAMWORKS_TAG}-templates.tar.xz"

# Extract only what we need to run locally and export cross-platform builds.
rm -rf "${BASE_DIR}/GodotSteam.app" "${BASE_DIR}/templates"
extract_tar_xz "${BASE_DIR}/macos-${STEAMWORKS_TAG}-editor.tar.xz" "${BASE_DIR}"
extract_tar_xz "${BASE_DIR}/godotsteam-${STEAMWORKS_TAG}-templates.tar.xz" "${BASE_DIR}"

if [[ ! -x "${BASE_DIR}/GodotSteam.app/Contents/MacOS/Godot" ]]; then
  echo "Expected GodotSteam editor binary missing after extraction." >&2
  exit 1
fi

if [[ ! -f "${BASE_DIR}/templates/macos/macos.zip" ]]; then
  echo "Expected templates missing after extraction." >&2
  exit 1
fi

echo "GodotSteam setup complete:"
echo "  Editor: ${BASE_DIR}/GodotSteam.app/Contents/MacOS/Godot"
echo "  Templates: ${BASE_DIR}/templates"
