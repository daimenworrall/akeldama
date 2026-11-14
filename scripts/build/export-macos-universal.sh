#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
STAGE="${STAGE:-prod}"
run_export "macOS Universal" "build/macos/AKELDAMA.app" "${STAGE}"
