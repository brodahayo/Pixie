#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/Build/Products/Release"
APP_PATH="$BUILD_DIR/Pixie.app"
OUTPUT_DIR="$PROJECT_DIR/release"

# Build first
"$SCRIPT_DIR/build.sh"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
echo "Creating release for Pixie v$VERSION..."

mkdir -p "$OUTPUT_DIR"

# Ad-hoc code sign the app (allows running without Apple Developer ID)
# Must sign innermost components first, then outward
echo "Code signing (ad-hoc)..."

# 1. Sign XPC services inside Sparkle
find "$APP_PATH" -type d -name "*.xpc" | while read -r xpc; do
    echo "  Signing XPC: $(basename "$xpc")"
    codesign --force --sign - "$xpc"
done

# 2. Sign Sparkle's embedded executables
find "$APP_PATH/Contents/Frameworks/Sparkle.framework" -type f -perm +111 -not -name ".*" 2>/dev/null | while read -r exe; do
    echo "  Signing exe: $(basename "$exe")"
    codesign --force --sign - "$exe" 2>/dev/null || true
done

# 3. Sign the framework bundle itself
find "$APP_PATH/Contents/Frameworks" -maxdepth 1 -type d -name "*.framework" | while read -r fw; do
    echo "  Signing framework: $(basename "$fw")"
    codesign --force --sign - "$fw"
done

# 4. Sign the main app bundle
echo "  Signing app bundle..."
codesign --force --sign - --entitlements "$PROJECT_DIR/Notchy/Resources/Notchy.entitlements" "$APP_PATH"
echo "  Verifying signature..."
codesign --verify --deep --strict "$APP_PATH" && echo "  Signature OK" || echo "  WARNING: Signature verification failed"

# Remove quarantine attribute so macOS doesn't flag it
xattr -cr "$APP_PATH"

# Create ZIP for Sparkle
ZIP_PATH="$OUTPUT_DIR/Pixie-$VERSION.zip"
echo "Creating ZIP: $ZIP_PATH"
cd "$BUILD_DIR"
ditto -c -k --keepParent Pixie.app "$ZIP_PATH"

# Create DMG
DMG_PATH="$OUTPUT_DIR/Pixie-$VERSION.dmg"
STAGING_DIR=$(mktemp -d)
echo "Creating DMG: $DMG_PATH"

cp -R "$APP_PATH" "$STAGING_DIR/"
xattr -cr "$STAGING_DIR/Pixie.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "Pixie" \
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
