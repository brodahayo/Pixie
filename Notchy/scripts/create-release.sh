#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/Build/Products/Release"
APP_PATH="$BUILD_DIR/Notchy.app"
VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
OUTPUT_DIR="$PROJECT_DIR/release"

echo "Creating release for Notchy v$VERSION..."

# Build first
"$SCRIPT_DIR/build.sh"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Create ZIP for Sparkle
ZIP_PATH="$OUTPUT_DIR/Notchy-$VERSION.zip"
echo "Creating ZIP: $ZIP_PATH"
cd "$BUILD_DIR"
ditto -c -k --keepParent Notchy.app "$ZIP_PATH"

# Create DMG
DMG_PATH="$OUTPUT_DIR/Notchy-$VERSION.dmg"
STAGING_DIR=$(mktemp -d)
echo "Creating DMG: $DMG_PATH"

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "Notchy" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo ""
echo "Release artifacts:"
echo "  ZIP: $ZIP_PATH"
echo "  DMG: $DMG_PATH"

# Sign for Sparkle if generate_appcast is available
if command -v generate_appcast &>/dev/null; then
    echo ""
    echo "Generating appcast..."
    generate_appcast "$OUTPUT_DIR"
    echo "Appcast generated at $OUTPUT_DIR/appcast.xml"
else
    echo ""
    echo "Note: Install Sparkle's generate_appcast to create appcast.xml"
    echo "  brew install sparkle"
fi
