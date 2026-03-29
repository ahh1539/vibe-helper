#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE="${PROJECT_DIR}/assets/icon-original.png"
ICONSET="${PROJECT_DIR}/.build/AppIcon.iconset"
OUTPUT="${PROJECT_DIR}/.build/AppIcon.icns"

if ! command -v sips &> /dev/null; then
    echo "Error: sips is required (ships with macOS)"
    exit 1
fi

echo "Generating icon sizes from ${SOURCE}..."
rm -rf "${ICONSET}"
mkdir -p "${ICONSET}"

# macOS icon sizes: 16, 32, 128, 256, 512 (each with @2x)
sips -z 16 16     "${SOURCE}" --out "${ICONSET}/icon_16x16.png"      > /dev/null
sips -z 32 32     "${SOURCE}" --out "${ICONSET}/icon_16x16@2x.png"   > /dev/null
sips -z 32 32     "${SOURCE}" --out "${ICONSET}/icon_32x32.png"      > /dev/null
sips -z 64 64     "${SOURCE}" --out "${ICONSET}/icon_32x32@2x.png"   > /dev/null
sips -z 128 128   "${SOURCE}" --out "${ICONSET}/icon_128x128.png"    > /dev/null
sips -z 256 256   "${SOURCE}" --out "${ICONSET}/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "${SOURCE}" --out "${ICONSET}/icon_256x256.png"    > /dev/null
sips -z 512 512   "${SOURCE}" --out "${ICONSET}/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "${SOURCE}" --out "${ICONSET}/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "${SOURCE}" --out "${ICONSET}/icon_512x512@2x.png" > /dev/null

echo "Creating .icns file..."
iconutil -c icns "${ICONSET}" -o "${OUTPUT}"
rm -rf "${ICONSET}"

echo "Icon created at ${OUTPUT}"
