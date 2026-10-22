#!/bin/bash
# Builds My Charm.app using only the Xcode Command Line Tools.
#   bash build.sh              -> for this Mac's chip
#   bash build.sh --universal  -> Apple Silicon + Intel (used for releases)
set -euo pipefail
cd "$(dirname "$0")"

APP="build/My Charm.app"
BIN="$APP/Contents/MacOS/MyCharm"

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Charms"

if [ "${1:-}" = "--universal" ]; then
  echo "Compiling universal (arm64 + x86_64)..."
  swiftc -O -target arm64-apple-macos13.0  Sources/*.swift -o build/MyCharm-arm64
  swiftc -O -target x86_64-apple-macos13.0 Sources/*.swift -o build/MyCharm-x86_64
  lipo -create build/MyCharm-arm64 build/MyCharm-x86_64 -output "$BIN"
  rm build/MyCharm-arm64 build/MyCharm-x86_64
else
  ARCH="$(uname -m)"
  echo "Compiling for $ARCH..."
  swiftc -O -target "$ARCH-apple-macos13.0" Sources/*.swift -o "$BIN"
fi

cp Info.plist "$APP/Contents/Info.plist"

shopt -s nullglob
for f in Charms/*.png Charms/*.jpg Charms/*.jpeg; do cp "$f" "$APP/Contents/Resources/Charms/"; done

codesign --force --deep --sign - "$APP"

echo ""
echo "Done: $APP"
echo "Run it:      bash charm.sh"
