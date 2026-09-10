#!/bin/zsh
cd "${0:A:h}"
exec /Applications/Godot.app/Contents/MacOS/Godot --path game --rendering-method forward_plus --rendering-driver metal res://scenes/harbor_v3.tscn
