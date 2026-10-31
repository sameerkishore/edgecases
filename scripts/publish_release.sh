#!/bin/zsh
# Builds the DMG for an existing, pushed tag, signs it for Sparkle, and creates the GitHub release
# with the DMG and appcast.xml attached. The app's SUFeedURL reads the appcast from the latest release.
# Usage: ./scripts/publish_release.sh 0.2.0 "What's new (Markdown: paragraphs, - bullets, **bold**)"
set -euo pipefail
cd "${0:A:h}/.."
tag="${1:?usage: publish_release.sh <tag> [notes]}"
notes="${2:-Small fixes and improvements.}"
repo="sameerkishore/edgecases"

./scripts/make_dmg.sh
app="build/Build/Products/Release/EdgeCases.app"
short=$(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist")
build=$(plutil -extract CFBundleVersion raw "$app/Contents/Info.plist")
[[ "$short" == "$tag" ]] || { echo "App version is $short, not $tag; run bump_version.sh first." >&2; exit 1; }
# Releases must carry the stable signature, or users have to grant Accessibility again.
codesign -d -r- "$app" 2>&1 | grep -q 'certificate leaf = H"b70180326195596800205ac320d4af77290da0d8"' \
  || { echo "App isn't signed with the EdgeCases Signing certificate." >&2; exit 1; }

# The notes are Markdown for GitHub; Sparkle's update window wants HTML (paragraphs, "- " bullets, **bold**).
notes_html=$(print -r -- "$notes" | awk '
  /^- / { if (!list) { print "<ul>"; list = 1 } sub(/^- /, ""); print "<li>" $0 "</li>"; next }
  { if (list) { print "</ul>"; list = 0 } if (length($0)) print "<p>" $0 "</p>" }
  END { if (list) print "</ul>" }' | sed -E 's/\*\*([^*]+)\*\*/<b>\1<\/b>/g; s/_([^_]+)_/<i>\1<\/i>/g')

dmg="build/EdgeCases-$tag.dmg"
mv "build/EdgeCases.dmg" "$dmg"
# Signs with EdgeCases' own EdDSA key, kept in the login Keychain under the "edgecases" account
# (created by Sparkle's generate_keys --account edgecases), separate from other apps' keys.
signature=$(build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update --account edgecases "$dmg")

cat > build/appcast.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>EdgeCases</title>
    <item>
      <title>EdgeCases $tag</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$tag</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[$notes_html]]></description>
      <enclosure url="https://github.com/$repo/releases/download/$tag/EdgeCases-$tag.dmg"
                 type="application/octet-stream" $signature />
    </item>
  </channel>
</rss>
XML

gh release create "$tag" "$dmg" build/appcast.xml -R "$repo" --verify-tag \
  --title "EdgeCases $tag" --notes "$notes

**New here?** Open the DMG and drag EdgeCases onto Applications. It isn't notarized, so the first
time you open it, click Done on the warning, then go to System Settings → Privacy & Security and click
**Open Anyway**. Then allow Accessibility access when asked. After that it updates itself.
Needs an Apple silicon Mac with macOS 14 or later.

© 2026 Sameer Kishore. Made with ❤️ by Sameer (and Claude)."
