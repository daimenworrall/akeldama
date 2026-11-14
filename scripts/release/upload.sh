#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/version.sh"
AKELDAMA_VERSION="$(version_get)" STAGE="${STAGE:-prod}" "${PROJECT_DIR}/scripts/steam/upload.sh"
