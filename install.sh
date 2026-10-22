#!/bin/bash
# My Charm installer
#
#   curl -fsSL https://raw.githubusercontent.com/VaibhavBeriwal14/My-Charm-For-Mac/main/install.sh | bash
#
# Optional: start with a specific charm
#   curl -fsSL https://raw.githubusercontent.com/VaibhavBeriwal14/My-Charm-For-Mac/main/install.sh | bash -s -- NIMBU_MIRCH
#
# What it does: downloads the latest prebuilt app into a temporary folder,
# installs it into Applications, turns on Launch at Login, starts it, and
# deletes the temporary folder. Nothing is left in Downloads.
# If no prebuilt app is available it builds from source instead
# (needs Apple's Command Line Tools).

set -euo pipefail

REPO="VaibhavBeriwal14/My-Charm-For-Mac"
APP_NAME="My Charm.app"
CHARM="${1:-}"

say()  { printf "\033[1;35m✦\033[0m %s\n" "$1"; }
fail() { printf "\033[1;31m✗\033[0m %s\n" "$1" >&2; exit 1; }

# --- checks -----------------------------------------------------------------
[ "$(uname)" = "Darwin" ] || fail "My Charm only runs on macOS."
ver="$(sw_vers -productVersion)"
[ "${ver%%.*}" -ge 13 ] || fail "My Charm needs macOS 13 Ventura or later (you have $ver)."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

DEST="/Applications"
if [ ! -w "$DEST" ]; then
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
fi

# --- get the app ------------------------------------------------------------
say "Downloading My Charm..."
BUILT=""
if curl -fsSL "https://github.com/$REPO/releases/latest/download/MyCharm.zip" -o "$TMP/MyCharm.zip" 2>/dev/null; then
  ditto -x -k "$TMP/MyCharm.zip" "$TMP/out"
  BUILT="$TMP/out/$APP_NAME"
else
  say "No prebuilt version found, building from source instead..."
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install >/dev/null 2>&1 || true
    fail "Building needs Apple's Command Line Tools. An install window should have opened. When it finishes, run this command again."
  fi
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP"
  SRC="$(find "$TMP" -maxdepth 1 -type d -name 'My-Charm-For-Mac-*' | head -n 1)"
  (cd "$SRC" && bash build.sh >/dev/null)
  BUILT="$SRC/build/$APP_NAME"
fi
[ -d "$BUILT" ] || fail "Something went wrong: the app wasn't found after downloading."

# --- install ----------------------------------------------------------------
say "Installing to $DEST..."
pkill -x MyCharm 2>/dev/null || true
sleep 0.5
rm -rf "$DEST/$APP_NAME"
ditto "$BUILT" "$DEST/$APP_NAME"
xattr -dr com.apple.quarantine "$DEST/$APP_NAME" 2>/dev/null || true

# --- launch -----------------------------------------------------------------
say "Starting My Charm..."
if [ -n "$CHARM" ]; then
  open "$DEST/$APP_NAME" --args --enable-login-item --charm "$CHARM"
else
  open "$DEST/$APP_NAME" --args --enable-login-item
fi

echo ""
say "Done! Your charm is hanging from the top of the screen."
echo "   Click the ✦ icon in the menu bar to change charms, string, size and more."
echo "   It will start automatically when you log in (turn off via ✦ → Launch at Login)."
