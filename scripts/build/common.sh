#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOTSTEAM_VERSION="${GODOTSTEAM_VERSION:-v4.17.1}"
TEMPLATES_DIR="${PROJECT_DIR}/third_party/godotsteam/${GODOTSTEAM_VERSION}/templates"
STEAM_INPUT_MANIFEST_NAME="steam_input_manifest.json"
STEAM_INPUT_MANIFEST_PATH="${PROJECT_DIR}/${STEAM_INPUT_MANIFEST_NAME}"
BUILD_DIR="${PROJECT_DIR}/build"

resolve_godot_bin() {
  local third_party_bin="${PROJECT_DIR}/third_party/godotsteam/${GODOTSTEAM_VERSION}/GodotSteam.app/Contents/MacOS/Godot"

  if [[ -n "${GODOT_BIN:-}" ]]; then
    if [[ ! -x "${GODOT_BIN}" ]]; then
      echo "GODOT_BIN is set but not executable: ${GODOT_BIN}" >&2
      exit 1
    fi
    printf '%s\n' "${GODOT_BIN}"
    return
  fi

  if [[ -x "${third_party_bin}" ]]; then
    printf '%s\n' "${third_party_bin}"
    return
  fi

  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return
  fi

  local default_bin="/Users/daimenworrall/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"
  if [[ -x "${default_bin}" ]]; then
    printf '%s\n' "${default_bin}"
    return
  fi

  echo "Could not find Godot binary. Run 'make setup', set GODOT_BIN, or ensure 'godot' is in PATH." >&2
  exit 1
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

clean_build_dir_if_requested() {
  if [[ "${CLEAN_BUILD:-1}" != "1" ]]; then
    return
  fi

  if [[ -d "${BUILD_DIR}" ]]; then
    echo "Cleaning build directory: ${BUILD_DIR}"
    rm -rf "${BUILD_DIR}"
  fi
}

steam_install_root_for_bin() {
  local godot_bin="$1"
  local app_path
  app_path="$(cd -- "$(dirname -- "${godot_bin}")/../.." && pwd)"
  dirname -- "${app_path}"
}

ensure_editor_data_writable_if_self_contained() {
  local godot_bin="$1"
  local install_root
  install_root="$(steam_install_root_for_bin "${godot_bin}")"

  if [[ ! -f "${install_root}/_sc_" && ! -f "${install_root}/._sc_" ]]; then
    return
  fi

  local temp_dir="${install_root}/editor_data/temp"
  local probe_file="${temp_dir}/.codex_write_probe.$$"

  mkdir -p "${temp_dir}" 2>/dev/null || fail "Godot is running in self-contained mode, but can't create '${temp_dir}'."

  : > "${probe_file}" 2>/dev/null || fail \
    "Godot is running in self-contained mode and cannot write '${temp_dir}'. \
This corrupts export project.binary and causes '.pck missing' at runtime. \
Fix permissions for '${install_root}/editor_data' or use a non-self-contained Godot binary via GODOT_BIN."

  rm -f "${probe_file}" || true
}

run_godot_export() {
  local godot_bin="$1"
  local preset_name="$2"
  local output_abs="$3"
  local stage="${4:-prod}"
  local safe_preset="${preset_name// /_}"
  local export_log="${PROJECT_DIR}/build/export-${safe_preset}.log"

  if ! STAGE="${stage}" "${godot_bin}" --headless --path "${PROJECT_DIR}" --export-release "${preset_name}" "${output_abs}" -- --stage="${stage}" 2>&1 | tee "${export_log}"; then
    fail "Godot export command failed for preset '${preset_name}'. See ${export_log}"
  fi

  if grep -Eq "Couldn't save project\\.binary|Corrupted header in binary project\\.binary|Cannot save file '.*/editor_data/.+editor_settings" "${export_log}"; then
    fail "Godot export logged editor_data write errors that produce a broken .pck. See ${export_log}"
  fi
}

plist_value() {
  local plist_path="$1"
  local key="$2"

  if [[ ! -f "${plist_path}" ]]; then
    return
  fi

  /usr/libexec/PlistBuddy -c "Print :${key}" "${plist_path}" 2>/dev/null || true
}

verify_export_output() {
  local output_abs="$1"

  if [[ "${output_abs}" == *.app ]]; then
    local info_plist="${output_abs}/Contents/Info.plist"
    local exe_name
    exe_name="$(plist_value "${info_plist}" "CFBundleExecutable")"
    if [[ -z "${exe_name}" ]]; then
      exe_name="$(basename -- "${output_abs}" .app)"
    fi

    [[ -x "${output_abs}/Contents/MacOS/${exe_name}" ]] || fail "Missing exported app executable: ${output_abs}/Contents/MacOS/${exe_name}"
    [[ -f "${output_abs}/Contents/Resources/${exe_name}.pck" ]] || fail "Missing exported app pack: ${output_abs}/Contents/Resources/${exe_name}.pck"
    return
  fi

  [[ -f "${output_abs}" ]] || fail "Missing exported binary: ${output_abs}"

  local pck_path="${output_abs%.*}.pck"
  [[ -f "${pck_path}" ]] || fail "Missing exported pack: ${pck_path}"
}

copy_steam_runtime_files() {
  local preset_name="$1"
  local output_abs="$2"

  case "${preset_name}" in
    "Windows x64")
      local src_win64="${TEMPLATES_DIR}/win64/steam_api64.dll"
      local dst_win64
      dst_win64="$(dirname "${output_abs}")/steam_api64.dll"
      [[ -f "${src_win64}" ]] || fail "Missing Steam runtime DLL: ${src_win64}. Run ./scripts/setup/setup-third-party.sh"
      cp -f "${src_win64}" "${dst_win64}"
      ;;
    "Linux x64")
      local src_linux64="${TEMPLATES_DIR}/linux64/libsteam_api.so"
      local dst_linux64
      dst_linux64="$(dirname "${output_abs}")/libsteam_api.so"
      [[ -f "${src_linux64}" ]] || fail "Missing Steam runtime shared library: ${src_linux64}. Run ./scripts/setup/setup-third-party.sh"
      cp -f "${src_linux64}" "${dst_linux64}"
      ;;
    "macOS Universal")
      if [[ "${output_abs}" != *.app ]]; then
        fail "Expected .app output for macOS preset, got: ${output_abs}"
      fi
      local src_macos="${PROJECT_DIR}/third_party/godotsteam/${GODOTSTEAM_VERSION}/GodotSteam.app/Contents/MacOS/libsteam_api.dylib"
      local dst_macos="${output_abs}/Contents/MacOS/libsteam_api.dylib"
      [[ -f "${src_macos}" ]] || fail "Missing Steam runtime dylib: ${src_macos}. Run ./scripts/setup/setup-third-party.sh"
      cp -f "${src_macos}" "${dst_macos}"
      ;;
  esac
}

verify_steam_runtime_files() {
  local preset_name="$1"
  local output_abs="$2"

  case "${preset_name}" in
    "Windows x64")
      [[ -f "$(dirname "${output_abs}")/steam_api64.dll" ]] || fail "Missing steam_api64.dll next to exported EXE."
      ;;
    "Linux x64")
      [[ -f "$(dirname "${output_abs}")/libsteam_api.so" ]] || fail "Missing libsteam_api.so next to exported Linux binary."
      ;;
    "macOS Universal")
      [[ -f "${output_abs}/Contents/MacOS/libsteam_api.dylib" ]] || fail "Missing libsteam_api.dylib inside exported app bundle."
      ;;
  esac
}

copy_steam_input_manifest() {
  local preset_name="$1"
  local output_abs="$2"

  [[ -f "${STEAM_INPUT_MANIFEST_PATH}" ]] || fail "Missing ${STEAM_INPUT_MANIFEST_NAME} at project root: ${STEAM_INPUT_MANIFEST_PATH}"

  case "${preset_name}" in
    "Windows x64"|"Linux x64")
      local dst
      dst="$(dirname "${output_abs}")/${STEAM_INPUT_MANIFEST_NAME}"
      cp -f "${STEAM_INPUT_MANIFEST_PATH}" "${dst}"
      ;;
    "macOS Universal")
      if [[ "${output_abs}" != *.app ]]; then
        fail "Expected .app output for macOS preset, got: ${output_abs}"
      fi
      local dst_macos_bin="${output_abs}/Contents/MacOS/${STEAM_INPUT_MANIFEST_NAME}"
      local dst_macos_resources="${output_abs}/Contents/Resources/${STEAM_INPUT_MANIFEST_NAME}"
      cp -f "${STEAM_INPUT_MANIFEST_PATH}" "${dst_macos_bin}"
      cp -f "${STEAM_INPUT_MANIFEST_PATH}" "${dst_macos_resources}"
      ;;
  esac
}

verify_steam_input_manifest() {
  local preset_name="$1"
  local output_abs="$2"

  case "${preset_name}" in
    "Windows x64"|"Linux x64")
      [[ -f "$(dirname "${output_abs}")/${STEAM_INPUT_MANIFEST_NAME}" ]] || fail "Missing ${STEAM_INPUT_MANIFEST_NAME} next to exported binary."
      ;;
    "macOS Universal")
      [[ -f "${output_abs}/Contents/MacOS/${STEAM_INPUT_MANIFEST_NAME}" ]] || fail "Missing ${STEAM_INPUT_MANIFEST_NAME} in app Contents/MacOS."
      [[ -f "${output_abs}/Contents/Resources/${STEAM_INPUT_MANIFEST_NAME}" ]] || fail "Missing ${STEAM_INPUT_MANIFEST_NAME} in app Contents/Resources."
      ;;
  esac
}

run_export() {
  local preset_name="$1"
  local output_rel_path="$2"
  local stage="${3:-prod}"
  local godot_bin
  godot_bin="$(resolve_godot_bin)"

  clean_build_dir_if_requested
  mkdir -p "${BUILD_DIR}"
  mkdir -p "$(dirname "${PROJECT_DIR}/${output_rel_path}")"
  local output_abs="${PROJECT_DIR}/${output_rel_path}"

  echo "Exporting preset: ${preset_name}"
  echo "Output: ${output_abs}"
  echo "Stage: ${stage}"

  ensure_editor_data_writable_if_self_contained "${godot_bin}"
  run_godot_export "${godot_bin}" "${preset_name}" "${output_abs}" "${stage}"
  verify_export_output "${output_abs}"
  copy_steam_runtime_files "${preset_name}" "${output_abs}"
  verify_steam_runtime_files "${preset_name}" "${output_abs}"
  copy_steam_input_manifest "${preset_name}" "${output_abs}"
  verify_steam_input_manifest "${preset_name}" "${output_abs}"

  echo "Export complete: ${output_abs}"
}
