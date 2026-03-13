#!/bin/bash
set -euo pipefail

echo "Generating EdDSA signing keys for Sparkle updates..."
echo ""

# Check if generate_keys is available
if ! command -v generate_keys &>/dev/null; then
    echo "Error: generate_keys not found."
    echo "Install Sparkle tools:"
    echo "  brew install sparkle"
    exit 1
fi

echo "This will generate a new EdDSA key pair for signing Sparkle updates."
echo "The private key will be stored in your Keychain."
echo "The public key should be added to your Info.plist as SUPublicEDKey."
echo ""

generate_keys

echo ""
echo "Done! Add the public key above to your Info.plist:"
echo "  <key>SUPublicEDKey</key>"
echo "  <string>YOUR_PUBLIC_KEY_HERE</string>"
