#!/bin/sh
cd "$(dirname "$0")" || exit 1
exec /Applications/Godot.app/Contents/MacOS/Godot --path game --scene res://scenes/harbor.tscn --resolution 1280x800
