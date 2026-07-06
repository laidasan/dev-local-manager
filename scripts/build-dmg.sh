#!/bin/bash
set -euo pipefail

APP_NAME="DevLocalManager"
SCHEME="DevLocalManager"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Resolving Swift packages..."
xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$SCHEME" \
  -resolvePackageDependencies \
  -quiet

echo "==> Archiving..."
xcodebuild archive \
  -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$SCHEME" \
  -archivePath "$ARCHIVE_PATH" \
  -quiet

echo "==> Exporting .app..."
mkdir -p "$EXPORT_DIR"
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_DIR/"

echo "==> Creating .dmg..."
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$EXPORT_DIR/$APP_NAME.app" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "==> Cleaning up intermediates..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"

echo ""
echo "Done! DMG is at: $DMG_PATH"
