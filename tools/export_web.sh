#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
mkdir -p builds/web
touch builds/.gdignore
"$GODOT_BIN" --headless --path . --editor --import
"$GODOT_BIN" --headless --path . --export-release Web builds/web/index.html
cp web/icon.svg web/gyro.js web/gyro-setup.js builds/web/
cp assets/fonts/OFL.txt builds/web/FONT-LICENSE.txt
cp web/GODOT-LICENSE.txt web/GODOT-COPYRIGHT.txt builds/web/
cp tools/vendor/LICENSE-dust2.txt builds/web/DUST-LICENSE.txt
# The custom shell uses our SVG, not Godot's generated splash/icon.
python3 - <<'PY'
from pathlib import Path
for name in ('index.png', 'index.png.import', 'icon.svg.import'):
    (Path('builds/web') / name).unlink(missing_ok=True)
PY
python3 tools/verify_web.py
