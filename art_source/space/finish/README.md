# Moonbase finishing sources

Deterministic offline finishing over the accepted source assets. `build_finish.py` opens the original `.blend` files in `../environment`, `../trial`, and `../heroes`, saves editable finished copies here, and exports to `assets/models/space`. Existing image-based materials are retained. Use Blender's bundled NumPy; `-- --asset=<name>` limits export to one asset.

`build_regolith.py` writes ground color and normal PNGs. `build_ui_audio.py` subsets the locally retained official fonts and synthesizes original PCM audio; Python dependencies: numpy, fonttools, brotli. Font licensing is retained in `assets/fonts/space` and the design plan. `check_ui_audio.py` checks glyph coverage and file integrity.

Output sources are committed so running the game never depends on the local font originals, a network service, or a new paid generation. Do not feed the finished files back as inputs: start from the original stage sources to avoid compounding wear.
