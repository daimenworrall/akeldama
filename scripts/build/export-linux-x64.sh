#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
STAGE="${STAGE:-prod}"
run_export "Linux x64" "build/linux/AKELDAMA.x86_64" "${STAGE}"
