#!/bin/zsh
set -eu
PROJECT_DIR="${0:A:h}"
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$GODOT_BIN" ]]; then
  print '没有找到 Godot。请安装 Godot 4，或在编辑器中导入 game/project.godot。'
  read '?按回车关闭…'
  exit 1
fi
exec "$GODOT_BIN" --path "$PROJECT_DIR/game"
