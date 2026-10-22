#!/bin/bash
# Builds My Charm.app using only the Xcode Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/My Charm.app"
ARCH="$(uname -m)"   # arm64 (Apple Silicon) or x86_64 (Intel)

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Charms"

echo "Compiling for $ARCH..."
swiftc -O -target "$ARCH-apple-macos13.0" Sources/*.swift -o "$APP/Contents/MacOS/MyCharm"

cp Info.plist "$APP/Contents/Info.plist"

shopt -s nullglob
for f in Charms/*.png Charms/*.jpg Charms/*.jpeg; do cp "$f" "$APP/Contents/Resources/Charms/"; done

codesign --force --deep --sign - "$APP"

echo ""
echo "Done: $APP"
echo "Run it:      open \"$APP\""
echo "Install it:  mv \"$APP\" /Applications/"
