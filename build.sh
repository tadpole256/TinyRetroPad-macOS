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

# Generate a simple app icon (16x16 through 512x512 PNGs + icns)
echo "→ Creating icon..."
ICONSET="$RESOURCES_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"

# Use a macOS-native method: create a solid-color PNG with sips
# Start with a 1024x1024 base, then resize down
python3 -c "
import struct, zlib, os

def png_chunk(ctype, data):
    c = ctype + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

def solid_png(size, r, g, b, a=255):
    # BGRA pixel data
    raw = b''
    for y in range(size):
        raw += b'\x00'  # filter none
        for x in range(size):
            raw += bytes([r, g, b, a])
    idat = png_chunk(b'IDAT', zlib.compress(raw))
    return (b'\\x89PNG\\r\\n\\x1a\\n'
            + png_chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
            + idat
            + png_chunk(b'IEND', b''))

# Retro dark slate color
r, g, b = 60, 70, 90

sizes = {
    'icon_16x16.png': 16,       'icon_16x16@2x.png': 32,
    'icon_32x32.png': 32,       'icon_32x32@2x.png': 64,
    'icon_128x128.png': 128,    'icon_128x128@2x.png': 256,
    'icon_256x256.png': 256,    'icon_256x256@2x.png': 512,
    'icon_512x512.png': 512,    'icon_512x512@2x.png': 1024,
}

for name, size in sizes.items():
    path = os.path.join('$ICONSET', name)
    with open(path, 'wb') as f:
        f.write(solid_png(size, r, g, b))
" 2>&1

# Convert iconset to .icns
iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || \
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
