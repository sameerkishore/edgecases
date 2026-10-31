#!/bin/zsh
# Builds a Release app and packages it as build/EdgeCases.dmg for sharing.
# The app is self-signed, not notarized: recipients approve it once in
# System Settings → Privacy & Security → Open Anyway (see the note inside the DMG).
set -euo pipefail
cd "${0:A:h}/.."
CONFIG=Release ./scripts/build.sh

app="build/Build/Products/Release/EdgeCases.app"
stage="build/dmg"
dmg="build/EdgeCases.dmg"
rm -rf "$stage" "$dmg"
mkdir -p "$stage"
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
cat > "$stage/How to open.txt" <<'NOTE'
EdgeCases isn't from the App Store, so macOS asks you to approve it once.

1. Drag EdgeCases onto the Applications folder.
2. Open it from Applications. macOS says it can't verify the app; click Done.
3. Open System Settings → Privacy & Security, scroll down, and click
   "Open Anyway" next to EdgeCases. Enter your password.
4. EdgeCases then asks for Accessibility access, which it needs to press the
   brightness and volume keys for you. Turn it on in the list that opens.

From then on it opens normally and updates itself. It lives in the menu bar,
not the Dock. Needs an Apple silicon Mac with macOS 14 (Sonoma) or later.
NOTE

hdiutil create -volname "EdgeCases" -srcfolder "$stage" -fs HFS+ -format UDZO -ov "$dmg" -quiet
rm -rf "$stage"
echo "Created: $dmg ($(du -h "$dmg" | cut -f1 | xargs))"
