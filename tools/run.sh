#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ -n "${GODOT_BIN:-}" ]; then
  godot_bin="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
  godot_bin=godot
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
  godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
else
  echo 'Godot 4.7.2 is required. Open project.godot in Godot to play.' >&2
  exit 127
fi
# Imported resources are local caches and must be refreshed after a pull.
"$godot_bin" --headless --path . --editor --import
exec "$godot_bin" --path . "$@"
