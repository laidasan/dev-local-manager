#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMG_PATH="$PROJECT_DIR/build/DevLocalManager.dmg"

if [ ! -f "$DMG_PATH" ]; then
  echo "Error: DMG not found at $DMG_PATH"
  echo "Run build-dmg.sh first."
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "Error: gh CLI not installed. Install with: brew install gh"
  exit 1
fi

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/deploy-release.sh <version>"
  echo "Example: ./scripts/deploy-release.sh 0.0.1-beta"
  exit 1
fi

TAG="v$VERSION"

echo "==> Creating GitHub Release $TAG..."

EXISTING=$(gh release view "$TAG" 2>&1 || true)
if echo "$EXISTING" | grep -q "title:"; then
  echo "Release $TAG already exists. Deleting and recreating..."
  gh release delete "$TAG" --yes
  git tag -d "$TAG" 2>/dev/null || true
  git push origin --delete "$TAG" 2>/dev/null || true
fi

gh release create "$TAG" \
  "$DMG_PATH" \
  --title "$TAG" \
  --notes "Release $VERSION" \
  --prerelease

echo ""
echo "Done! Release $TAG published."
echo ""

SHA=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
echo "Update homebrew-tap formula:"
echo "  version \"$VERSION\""
echo "  sha256 \"$SHA\""
