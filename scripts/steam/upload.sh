#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_PATH="${PROJECT_DIR}/config/steam_targets.cfg"
BUILD_DIR="${PROJECT_DIR}/build"
VDF_DIR="${BUILD_DIR}/steam/vdf"
STAGE="${STAGE:-prod}"
STEAM_GUARD_CODE="${STEAM_GUARD_CODE:-}"
STEAM_SETLIVE_BRANCH="${STEAM_SETLIVE_BRANCH:-alpha}"
AKELDAMA_VERSION="${AKELDAMA_VERSION:-}"
STEAMCMD_TIMEOUT_SEC="${STEAMCMD_TIMEOUT_SEC:-180}"

WIN_CONTENT_DIR="${BUILD_DIR}/windows"
LINUX_CONTENT_DIR="${BUILD_DIR}/linux"
MACOS_CONTENT_DIR="${BUILD_DIR}/macos"

read_cfg_value() {
  local section="$1"
  local key="$2"
  awk -F= -v target_section="${section}" -v target_key="${key}" '
    BEGIN { in_section = 0 }
    /^[[:space:]]*\[/ {
      section = $0
      gsub(/^[[:space:]]*\[/, "", section)
      gsub(/\][[:space:]]*$/, "", section)
      in_section = (section == target_section)
      next
    }
    in_section {
      k = $1
      v = $2
      gsub(/[[:space:]]/, "", k)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      if (k == target_key) {
        print v
        exit
      }
    }
  ' "${CONFIG_PATH}"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

find_timeout_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    printf '%s\n' "timeout"
    return
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    printf '%s\n' "gtimeout"
    return
  fi
  printf '%s\n' ""
}

require_dir() {
  local path="$1"
  [[ -d "${path}" ]] || fail "Missing build directory: ${path}. Run exports first."
}

decode_base64() {
  local encoded="$1"
  if printf '%s' "${encoded}" | base64 --decode >/dev/null 2>&1; then
    printf '%s' "${encoded}" | base64 --decode
    return
  fi
  if printf '%s' "${encoded}" | base64 -D >/dev/null 2>&1; then
    printf '%s' "${encoded}" | base64 -D
    return
  fi
  return 1
}

ensure_stage() {
  if [[ "${STAGE}" != "dev" && "${STAGE}" != "prod" ]]; then
    fail "Invalid STAGE='${STAGE}'. Use STAGE=dev or STAGE=prod."
  fi
}

write_depot_vdf() {
  local depot_id="$1"
  local content_root="$2"
  local output_path="$3"
  cat > "${output_path}" <<EOF
"DepotBuildConfig"
{
  "DepotID" "${depot_id}"
  "ContentRoot" "${content_root}"
  "FileMapping"
  {
    "LocalPath" "*"
    "DepotPath" "."
    "recursive" "1"
  }
  "FileExclusion" "*.DS_Store"
}
EOF
}

write_app_vdf() {
  local app_id="$1"
  local depot_win_vdf="$2"
  local depot_macos_vdf="$3"
  local depot_linux_vdf="$4"
  local depot_win_id="$5"
  local depot_macos_id="$6"
  local depot_linux_id="$7"
  local output_path="$8"
  local build_desc="Akeldama ${STAGE} build $(date '+%Y-%m-%d %H:%M:%S')"
  if [[ -n "${AKELDAMA_VERSION}" ]]; then
    build_desc="Akeldama ${STAGE} ${AKELDAMA_VERSION} build $(date '+%Y-%m-%d %H:%M:%S')"
  fi
  cat > "${output_path}" <<EOF
"appbuild"
{
  "appid" "${app_id}"
  "desc" "${build_desc}"
  "setlive" "${STEAM_SETLIVE_BRANCH}"
  "buildoutput" "${BUILD_DIR}/steam/output"
  "contentroot" "${PROJECT_DIR}"
  "preview" "0"
  "local" ""

  "depots"
  {
    "${depot_win_id}" "${depot_win_vdf}"
    "${depot_macos_id}" "${depot_macos_vdf}"
    "${depot_linux_id}" "${depot_linux_vdf}"
  }
}
EOF
}

run_steamcmd() {
  local timeout_cmd="$1"
  shift
  echo "  Running steamcmd login/upload"
  if [[ -n "${timeout_cmd}" ]]; then
    echo "  steamcmd timeout: ${STEAMCMD_TIMEOUT_SEC}s"
    "${timeout_cmd}" "${STEAMCMD_TIMEOUT_SEC}" steamcmd "$@" || fail "steamcmd failed or timed out during login/upload."
    return
  fi
  echo "  steamcmd timeout: unavailable (install coreutils 'timeout' for bounded waits)"
  steamcmd "$@" || fail "steamcmd failed during login/upload."
}

main() {
  require_cmd steamcmd
  [[ -f "${CONFIG_PATH}" ]] || fail "Config not found: ${CONFIG_PATH}"
  ensure_stage

  require_dir "${WIN_CONTENT_DIR}"
  require_dir "${MACOS_CONTENT_DIR}"
  require_dir "${LINUX_CONTENT_DIR}"

  local app_id
  local depot_windows
  local depot_macos
  local depot_linux
  app_id="$(read_cfg_value "${STAGE}" "app_id")"
  depot_windows="$(read_cfg_value "${STAGE}" "depot_windows")"
  depot_macos="$(read_cfg_value "${STAGE}" "depot_macos")"
  depot_linux="$(read_cfg_value "${STAGE}" "depot_linux")"

  [[ "${app_id}" =~ ^[1-9][0-9]*$ ]] || fail "Missing app_id for [${STAGE}] in ${CONFIG_PATH}"
  [[ "${depot_windows}" =~ ^[1-9][0-9]*$ ]] || fail "Missing depot_windows for [${STAGE}] in ${CONFIG_PATH}"
  [[ "${depot_macos}" =~ ^[1-9][0-9]*$ ]] || fail "Missing depot_macos for [${STAGE}] in ${CONFIG_PATH}"
  [[ "${depot_linux}" =~ ^[1-9][0-9]*$ ]] || fail "Missing depot_linux for [${STAGE}] in ${CONFIG_PATH}"

  local username="${STEAM_USERNAME:-}"
  local password="${STEAM_PASSWORD:-}"
  if [[ -z "${password}" && -n "${STEAM_PASSWORD_B64:-}" ]]; then
    password="$(decode_base64 "${STEAM_PASSWORD_B64}")" || fail "STEAM_PASSWORD_B64 is not valid base64."
  fi
  [[ -n "${username}" ]] || fail "Set STEAM_USERNAME in environment."
  local timeout_cmd
  timeout_cmd="$(find_timeout_cmd)"

  mkdir -p "${VDF_DIR}" "${BUILD_DIR}/steam/output"

  local depot_win_vdf="${VDF_DIR}/depot_${depot_windows}.vdf"
  local depot_macos_vdf="${VDF_DIR}/depot_${depot_macos}.vdf"
  local depot_linux_vdf="${VDF_DIR}/depot_${depot_linux}.vdf"
  local app_vdf="${VDF_DIR}/app_${app_id}.vdf"

  write_depot_vdf "${depot_windows}" "${WIN_CONTENT_DIR}" "${depot_win_vdf}"
  write_depot_vdf "${depot_macos}" "${MACOS_CONTENT_DIR}" "${depot_macos_vdf}"
  write_depot_vdf "${depot_linux}" "${LINUX_CONTENT_DIR}" "${depot_linux_vdf}"
  write_app_vdf "${app_id}" "${depot_win_vdf}" "${depot_macos_vdf}" "${depot_linux_vdf}" "${depot_windows}" "${depot_macos}" "${depot_linux}" "${app_vdf}"

  echo "Uploading to Steam..."
  echo "  Stage: ${STAGE}"
  echo "  App ID: ${app_id}"
  echo "  Depots: windows=${depot_windows} macos=${depot_macos} linux=${depot_linux}"
  echo "  Steam user: ${username}"
  echo "  Steam guard code provided: $([[ -n "${STEAM_GUARD_CODE}" ]] && printf '%s' "yes" || printf '%s' "no")"
  echo "  Password provided: $([[ -n "${password}" ]] && printf '%s' "yes" || printf '%s' "no")"

  if [[ -n "${password}" ]]; then
    if [[ -n "${STEAM_GUARD_CODE}" ]]; then
      run_steamcmd "${timeout_cmd}" +login "${username}" "${password}" "${STEAM_GUARD_CODE}" +run_app_build "${app_vdf}" +quit
    else
      run_steamcmd "${timeout_cmd}" +login "${username}" "${password}" +run_app_build "${app_vdf}" +quit
    fi
  else
    run_steamcmd "${timeout_cmd}" +login "${username}" +run_app_build "${app_vdf}" +quit
  fi

  echo "Upload complete."
  if [[ -d "${BUILD_DIR}" ]]; then
    echo "Cleaning build directory: ${BUILD_DIR}"
    rm -rf "${BUILD_DIR}"
  fi
}

main "$@"
