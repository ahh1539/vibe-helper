#!/bin/bash
set -euo pipefail

APP_NAME="Vibe Helper"
BUNDLE_ID="com.vibehelper.app"
VERSION="${1:-1.0.0}"
BUILD_DIR=".build/release"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="VibeHelper-${VERSION}-macOS.dmg"
DMG_DIR=".build/dmg"

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/VibeHelper" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
PLIST

# Generate app icon if iconutil is available
if command -v iconutil &> /dev/null && [ -f "scripts/generate-icon.sh" ]; then
    echo "🎨 Generating app icon..."
    bash scripts/generate-icon.sh
    if [ -f ".build/AppIcon.icns" ]; then
        cp ".build/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    fi
fi

echo "🔏 Code signing..."
SIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
if [ "${SIGN_IDENTITY}" = "-" ]; then
    echo "⚠️  No CODESIGN_IDENTITY set, using ad-hoc signing"
fi
codesign --force --deep --options runtime \
    --sign "${SIGN_IDENTITY}" \
    "${APP_BUNDLE}"
codesign --verify --deep --strict "${APP_BUNDLE}"
echo "✅ Code signing verified"

if [ -n "${SKIP_DMG:-}" ]; then
    echo "⏭️  Skipping DMG creation (SKIP_DMG set)"
    echo "✅ Signed app bundle at: ${APP_BUNDLE}"
    exit 0
fi

echo "💿 Creating DMG..."
rm -rf "${DMG_DIR}"
mkdir -p "${DMG_DIR}"
cp -R "${APP_BUNDLE}" "${DMG_DIR}/"
ln -s /Applications "${DMG_DIR}/Applications"

rm -f ".build/${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    ".build/${DMG_NAME}"

rm -rf "${DMG_DIR}"

echo ""
echo "✅ Done! DMG created at: .build/${DMG_NAME}"
echo ""
echo "To upload to GitHub Releases:"
echo "  gh release create v${VERSION} .build/${DMG_NAME} --title \"v${VERSION}\" --notes \"Vibe Helper v${VERSION}\""
