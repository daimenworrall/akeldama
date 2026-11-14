#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAGE="${STAGE:-prod}"
CLEAN_BUILD=1 STAGE="${STAGE}" "${SCRIPT_DIR}/export-macos-universal.sh"
CLEAN_BUILD=0 STAGE="${STAGE}" "${SCRIPT_DIR}/export-windows-x64.sh"
CLEAN_BUILD=0 STAGE="${STAGE}" "${SCRIPT_DIR}/export-linux-x64.sh"
