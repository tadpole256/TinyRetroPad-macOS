#!/bin/bash
set -euo pipefail

APP_NAME="TinyRetroPad"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "=== Building $APP_NAME ==="

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Compile Swift
echo "→ Compiling..."
swiftc \
    -o "$MACOS_DIR/$APP_NAME" \
    -target arm64-apple-macos13.0 \
    -O \
    -whole-module-optimization \
    -framework Cocoa \
    "$PROJECT_DIR/main.swift"

BIN_SIZE=$(stat -f%z "$MACOS_DIR/$APP_NAME")
echo "  Binary: $BIN_SIZE bytes"

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$CONTENTS/Info.plist"

# Generate PkgInfo
echo -n 'APPL????' > "$CONTENTS/PkgInfo"

# Generate a proper Notepad-style app icon
echo "→ Creating Notepad icon..."
ICONSET="$RESOURCES_DIR/AppIcon.iconset"
python3 "$PROJECT_DIR/gen_icon.py" "$ICONSET" 2>&1

# Convert iconset to .icns
iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET"
echo "  Icon created"

# Ad-hoc code sign
echo "→ Signing..."
codesign --force --sign - "$APP_BUNDLE" 2>/dev/null && echo "  Signed" || echo "  Skipped (OK for local use)"

echo ""
echo "═══════════════════════════════════════"
echo "  Build complete!"
echo "  App: $APP_BUNDLE"
echo ""
echo "  Run:   open '$APP_BUNDLE'"
echo "  Install: cp -R '$APP_BUNDLE' /Applications/"
echo "═══════════════════════════════════════"
