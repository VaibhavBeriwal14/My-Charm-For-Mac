#!/bin/bash
# Usage: bash charm.sh NAZAR   |   bash charm.sh NIMBU_MIRCH
# Runs the newest build. If you keep a copy in /Applications, it is refreshed
# automatically whenever build/ has a newer version.
DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD="$DIR/build/My Charm.app"
INSTALLED="/Applications/My Charm.app"
APP="$BUILD"

if [ -d "$INSTALLED" ]; then
  if [ -d "$BUILD" ] && [ "$BUILD/Contents/MacOS/MyCharm" -nt "$INSTALLED/Contents/MacOS/MyCharm" ]; then
    echo "Updating /Applications with the new build..."
    pkill -x MyCharm 2>/dev/null; sleep 0.3
    rm -rf "$INSTALLED" && cp -R "$BUILD" "$INSTALLED"
  fi
  APP="$INSTALLED"
fi

if [ ! -d "$APP" ]; then echo "App not built yet. Run: bash build.sh"; exit 1; fi

pkill -x MyCharm 2>/dev/null; sleep 0.3
open "$APP" --args --charm "${1:-NAZAR}"
echo "Running: $APP"
