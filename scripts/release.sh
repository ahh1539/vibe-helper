#!/bin/bash
set -euo pipefail

# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 2.1.0
#
# First-time setup (run once):
#   xcrun notarytool store-credentials "vibe-helper" \
#     --apple-id "your@apple-id.com" \
#     --password "app-specific-password" \
#     --team-id "2HRL368U74"

VERSION="${1:?Usage: $0 <version>}"
APP_NAME="Vibe Helper"
APP_BUNDLE=".build/release/${APP_NAME}.app"
ZIP_PATH=".build/VibeHelper-${VERSION}.zip"
DMG_PATH=".build/VibeHelper-${VERSION}-macOS.dmg"
DMG_DIR=".build/dmg"
NOTARY_PROFILE="vibe-helper"
export CODESIGN_IDENTITY="Developer ID Application: Alexander Hurley (2HRL368U74)"

# Preflight checks
if ! command -v gh &>/dev/null; then
    echo "❌ GitHub CLI not found. Install with: brew install gh"
    exit 1
fi

if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" &>/dev/null 2>&1; then
    echo "❌ Notarytool profile '${NOTARY_PROFILE}' not found."
    echo ""
    echo "Run this once to set it up:"
    echo "  xcrun notarytool store-credentials \"${NOTARY_PROFILE}\" \\"
    echo "    --apple-id \"your@apple-id.com\" \\"
    echo "    --password \"app-specific-password\" \\"
    echo "    --team-id \"2HRL368U74\""
    exit 1
fi

echo "🔨 Building and signing v${VERSION}..."
SKIP_DMG=1 bash scripts/build-dmg.sh "$VERSION"

echo ""
echo "📤 Notarizing the app bundle..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo ""
echo "📎 Stapling notarization ticket to the .app..."
xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"
rm -f "$ZIP_PATH"

echo ""
echo "💿 Building DMG with stapled .app..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"
rm -rf "$DMG_DIR"

echo ""
echo "📤 Notarizing the DMG..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo ""
echo "📎 Stapling notarization ticket to DMG..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

echo ""
echo "✅ Verifying Gatekeeper acceptance of .app..."
spctl -a -vvv --type execute "$APP_BUNDLE"

echo ""
echo "🚀 Creating GitHub release v${VERSION}..."
gh release create "v${VERSION}" \
    --title "v${VERSION}" \
    --generate-notes

echo ""
echo "📦 Uploading DMG..."
gh release upload "v${VERSION}" "$DMG_PATH" --clobber

echo ""
echo "🔎 Verifying upload matches local DMG..."
LOCAL_HASH=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
TMP_DOWNLOAD=$(mktemp -t vibe-helper-verify).dmg
gh release download "v${VERSION}" -O "$TMP_DOWNLOAD" --clobber
REMOTE_HASH=$(shasum -a 256 "$TMP_DOWNLOAD" | awk '{print $1}')
rm -f "$TMP_DOWNLOAD"
if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    echo "❌ Hash mismatch! Local: $LOCAL_HASH  Remote: $REMOTE_HASH"
    exit 1
fi
echo "✅ Hash match: $LOCAL_HASH"

echo ""
echo "✅ Done! Release v${VERSION} is live."
