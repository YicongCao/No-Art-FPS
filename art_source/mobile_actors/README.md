# Web actor mesh consolidation

Rebuild with Blender 5.2.2:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/mobile_actors/build.py
```

Inputs are the existing toy enemy/rusher GLBs. Editable results are `enemy.blend` and `rusher.blend`; runtime outputs are `assets/models/toy/*_mobile.glb`.

Decorative meshes join their nearest articulated or destructible controller. Both actors retain 14 mesh parts, original geometry and gameplay pivots. Vertex RGB stores linear paint colour; UV.x stores roughness, UV2.x metallic and UV2.y emission after glTF V inversion. Do not use vertex alpha for roughness: the exporter can omit constant alpha. The runtime shader converts linear paint to sRGB in Compatibility and combines the old rim into its main lit pass. Rusher flash overrides still use the original orange material.

The native renderer keeps the original actors by default. Web selects these compact exports. Compare original left / compact right in `docs/updates/mobile-performance-2026-11-15/*-geometry-comparison.png`. Run `tests/mobile_actor_check.gd` and `tests/headshot_check.gd -- --mobile-actors` after rebuilding.
