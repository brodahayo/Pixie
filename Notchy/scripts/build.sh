#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building Notchy..."

cd "$PROJECT_DIR"

# Generate project if needed
if command -v xcodegen &>/dev/null; then
    xcodegen generate
fi

# Build
xcodebuild \
    -project Notchy.xcodeproj \
    -scheme Notchy \
    -configuration Release \
    -derivedDataPath build \
    build

echo "Build complete: build/Build/Products/Release/Notchy.app"
