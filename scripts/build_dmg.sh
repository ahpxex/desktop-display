#!/usr/bin/env bash
set -euo pipefail

# Builds the desktop-display app and packages it into a DMG.
# Usage:
#   ./scripts/build_dmg.sh
# Optional environment overrides:
#   SCHEME - Xcode scheme to build (default: desktop-display)
#   CONFIGURATION - Build configuration (default: Release)
#   DERIVED_DATA - Derived data output directory (default: build/DerivedData)
#   DMG_OUTPUT - Path to the resulting DMG (default: build/desktop-display.dmg)
#   VOLUME_NAME - Name for the DMG volume (default: Desktop Display)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-desktop-display}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"
BUILD_DIR="$ROOT_DIR/build"
DMG_OUTPUT="${DMG_OUTPUT:-$BUILD_DIR/desktop-display.dmg}"
VOLUME_NAME="${VOLUME_NAME:-Desktop Display}"
PROJECT_FILE="$ROOT_DIR/desktop-display.xcodeproj"
APP_NAME="${APP_NAME:-desktop-display}"

echo "Building scheme '$SCHEME' ($CONFIGURATION)..."
xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  clean build

APP_SOURCE="$DERIVED_DATA/Build/Products/$CONFIGURATION/${APP_NAME}.app"

if [[ ! -d "$APP_SOURCE" ]]; then
  echo "Error: Built app not found at $APP_SOURCE" >&2
  exit 1
fi

STAGING_DIR="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

echo "Copying app bundle to staging..."
ditto "$APP_SOURCE" "$STAGING_DIR/${APP_NAME}.app"

mkdir -p "$(dirname "$DMG_OUTPUT")"
rm -f "$DMG_OUTPUT"

echo "Creating DMG at $DMG_OUTPUT..."
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_OUTPUT"

echo "DMG created: $DMG_OUTPUT"
