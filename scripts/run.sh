#!/bin/zsh
# Builds, quits any running copy, and launches the app.
set -euo pipefail
cd "${0:A:h}/.."
./scripts/build.sh
pkill -x EdgeCases 2>/dev/null || true
sleep 0.5
open "build/Build/Products/${CONFIG:-Debug}/EdgeCases.app"
