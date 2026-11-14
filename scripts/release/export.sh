#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
STAGE="${STAGE:-prod}"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/version.sh"

version="$(version_bump_patch)"
echo "Version bumped to ${version}"

STAGE="${STAGE}" "${PROJECT_DIR}/scripts/build/export-all.sh"
