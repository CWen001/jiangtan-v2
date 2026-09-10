#!/bin/sh
set -eu
cd "$(dirname "$0")"
if lsof -nP -iTCP:9876 -sTCP:LISTEN >/dev/null 2>&1; then
    echo 'Port 9876 is already in use. Reuse the current project Blender instance; do not start a second one.' >&2
    exit 1
fi
export DISABLE_TELEMETRY=true
exec /Applications/Blender.app/Contents/MacOS/Blender --factory-startup --python "$PWD/bootstrap_addon.py"
