# Interactive scenery props

Original low-poly models and synthesized impact audio for the nine active maps.

- Editable models: 27 Blender files in this folder. Geometry uses metres, Z-up in Blender, +Y as the display front; the GLB exporter converts to Godot's Y-up convention.
- `Base` meshes remain after destruction. `TargetN` meshes have independent shot targets; optional `RemnantN` meshes appear after that target breaks. Each part uses one vertex-coloured material surface.
- Model exports: assets/models/interactive_props. No external textures or third-party model assets.
- Authoritative positions: placements.json. write_catalog.py compiles them to scripts/maps/interactive_prop_catalog.gd for reliable Godot exports.
- audio.py synthesizes seven short material impacts at 22050 Hz using a fixed random seed.

Rebuild from the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/interactive_props/build.py
python3 art_source/interactive_props/audio.py
python3 art_source/interactive_props/write_catalog.py
```

The optional tools/maps/place_interactive_props.gd is an offline placement repair utility. Review its moves and rendered results before regenerating the catalog. The shipped game never searches for placement positions or probes floors at runtime.
