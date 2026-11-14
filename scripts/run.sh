#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
GODOTSTEAM_VERSION="${GODOTSTEAM_VERSION:-v4.17.1}"
THIRD_PARTY_GODOT_BIN="${PROJECT_DIR}/third_party/godotsteam/${GODOTSTEAM_VERSION}/GodotSteam.app/Contents/MacOS/Godot"
STEAM_TARGETS_CFG="${PROJECT_DIR}/config/steam_targets.cfg"
LOG_DIR="${PROJECT_DIR}/.godot/logs"
LOG_FILE="${LOG_DIR}/run.log"

read_stage_app_id() {
  local stage="$1"
  if [[ ! -f "${STEAM_TARGETS_CFG}" ]]; then
    return
  fi
  awk -F= -v target_section="${stage}" '
    BEGIN { in_section = 0 }
    /^[[:space:]]*\[/ {
      section = $0
      gsub(/^[[:space:]]*\[/, "", section)
      gsub(/\][[:space:]]*$/, "", section)
      in_section = (section == target_section)
      next
    }
    in_section && $1 ~ /^[[:space:]]*app_id[[:space:]]*$/ {
      value = $2
      gsub(/[[:space:]]/, "", value)
      print value
      exit
    }
  ' "${STEAM_TARGETS_CFG}"
}

DEV_APP_ID="$(read_stage_app_id dev || true)"
if [[ -n "${DEV_APP_ID}" ]]; then
  printf '%s\n' "${DEV_APP_ID}" > "${PROJECT_DIR}/steam_appid.txt"
fi

needs_import_cache() {
  if [[ ! -d "${PROJECT_DIR}/.godot/imported" ]]; then
    return 0
  fi

  if ! compgen -G "${PROJECT_DIR}/.godot/imported/*.ctex" >/dev/null; then
    return 0
  fi

  return 1
}

run_import_cache() {
  local godot_bin="$1"
  echo "Import cache missing; running one-time Godot import..."
  "${godot_bin}" --headless --path "${PROJECT_DIR}" --log-file "${LOG_FILE}" --import >/dev/null
}

export SHELL_SESSIONS_DISABLE=1
mkdir -p "${LOG_DIR}"
if [[ -x "${THIRD_PARTY_GODOT_BIN}" ]]; then
  if needs_import_cache; then
    run_import_cache "${THIRD_PARTY_GODOT_BIN}"
  fi

  env STAGE=dev "${THIRD_PARTY_GODOT_BIN}" --path "${PROJECT_DIR}" --log-file "${LOG_FILE}" -- --stage=dev "$@" 2>&1 \
    | sed -E '/Inputs found [0-9]+ controllers\./d'
  exit "${PIPESTATUS[0]}"
fi

zsh -ic 'STAGE=dev godot --path "$1" --log-file "$2" -- --stage=dev "${@:3}"' _ "$PROJECT_DIR" "$LOG_FILE" "$@" 2>&1 \
  | sed -E '/Inputs found [0-9]+ controllers\./d'
exit "${PIPESTATUS[0]}"
