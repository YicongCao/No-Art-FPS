#!/bin/sh
set -eu
cd "$(dirname "$0")"
if command -v godot >/dev/null 2>&1; then
  exec godot --path .
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path .
else
  echo 'Godot 4.7.2 is required. Open project.godot in Godot to play.'
  read -r unused
fi
