# Dust-flavor A-site modules

Generated locally by `blender --background --python tools/build_dust_flavor_assets.py`. Editable source: `art_source/dust_flavor.blend`. `architecture.glb` preserves individual coarse geometry pieces; `c4.glb` is an original objective prop. The Godot map wrapper in `scenes/maps/dust_flavor.tscn` stores palette bindings, simplified static collision, baked navigation, patrol markers and C4 objectives. Re-exporting models does not author objective positions.

The A-site structural layout and selected helper functions are adapted from StarKnightt/counter-strike-in-browser, commit `190a277555ff6a1b7112090fc0a2db3189006db8`, MIT. Source: https://github.com/StarKnightt/counter-strike-in-browser . The full copyright/license notice is retained in `tools/vendor/LICENSE-dust2.txt`.

Local changes remove all image textures, backdrop buildings/hills, dense facade details, wires and bolts; preserve doors, long, short, site, pit and CT connection; add a west walking bypass, simple crates/pots/car and an original C4 prop. The tall west connector block and the decorative elevator step were removed to make both routes walkable. Side rails prevent nav paths exiting the pit ramp across an unwalkable lip. Continuous collision replaces stair steps.

Current architecture: 292 mesh pieces, 9,198 triangles, about 636 KB GLB. Original mid/B courtyard, tunnel, return ramp, towers, palms and market dressing are built by `tools/build_dust_expansion.py`. No external texture image files. Godot applies the original SVG plaster surface and A/B markings locally. Flat palette materials are shared `.tres` resources under `assets/materials/`. Geometry is not a complete original Dust2 map and does not claim exact classic dimensions. Model coordinates use Blender X/Y horizontal and Z height; glTF converts to Godot X/Z/-Y.

B/mid coplanar floor overlap is removed by partitioning courtyard floor rectangles and trimming the mid floor. The builder asserts non-overlapping equal-height floor tops.
