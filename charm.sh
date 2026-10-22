#!/bin/bash
# Usage: bash charm.sh NAZAR   |   bash charm.sh NIMBU_MIRCH
APP="$(dirname "$0")/build/My Charm.app"
[ -d "/Applications/My Charm.app" ] && APP="/Applications/My Charm.app"
pkill -x MyCharm 2>/dev/null; sleep 0.3
open "$APP" --args --charm "${1:-NAZAR}"
