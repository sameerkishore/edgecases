#!/bin/zsh
# Builds a Release copy and installs it to /Applications, so Open at Login points at a stable app.
set -euo pipefail
cd "${0:A:h}/.."
CONFIG=Release ./scripts/build.sh
pkill -x EdgeCases 2>/dev/null || true
sleep 0.5
rm -rf /Applications/EdgeCases.app
cp -R build/Build/Products/Release/EdgeCases.app /Applications/
echo "Installed: /Applications/EdgeCases.app"
open /Applications/EdgeCases.app
