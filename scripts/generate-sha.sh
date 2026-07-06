#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMG_PATH="$PROJECT_DIR/build/DevLocalManager.dmg"

if [ ! -f "$DMG_PATH" ]; then
  echo "Error: DMG not found at $DMG_PATH"
  echo "Run build-dmg.sh first."
  exit 1
fi

SHA=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

echo "SHA256: $SHA"
echo ""
echo "To update homebrew-tap formula:"
echo "  sha256 \"$SHA\""
