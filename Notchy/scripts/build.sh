#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building Pixie..."

cd "$PROJECT_DIR"

# Generate project if needed
if command -v xcodegen &>/dev/null; then
    xcodegen generate
fi

# Build
xcodebuild \
    -project Pixie.xcodeproj \
    -scheme Pixie \
    -configuration Release \
    -derivedDataPath build \
    build

echo "Build complete: build/Build/Products/Release/Pixie.app"
