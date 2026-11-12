"""Bake sky occlusion and coloured bounce light into the vertex colours of a map's static kits.

Run after the map's build script and after tools/maps/export_bake_placements.gd:
    blender --background --python tools/maps/bake_vertex_light.py -- hogwarts

Every static kit is loaded at its place in the map so walls, roofs and props occlude each other.
Destructible props, doors and anything under "Moving" are left out, so a broken prop never leaves
a baked shadow behind. Large faces in the play space are split first so corners have vertices.

Two modes:
- sky: Cycles bakes the diffuse light a surface receives from a uniform white sky, including
  bounces tinted by neighbouring paint, then divides by what an open surface with the same normal
  would receive. Only occlusion and colour bleed remain. For open-air maps.
- ao: Cycles ambient occlusion limited to a short distance. Ceilings do not darken the floor, only
  wall corners, steps, counters and machine bases do. For interiors and covered streets.

The toy shaders multiply the result into the albedo; sun, shadows and ambient stay real-time.
Re-running is safe: faces already small are not split again and colours are replaced.
"""
import json
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
PLACEMENTS = ROOT / 'tools/maps/bake_placements.json'
# Godot is Y-up; the glTF importer maps (x, y, z) to Blender (x, -z, y).
AXES = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
DEFAULT = {
    'mode': 'sky',
    'distance': 2.0,
    # Refine region in Godot coordinates: radius around the origin, or (xmin, xmax, zmin, zmax).
    'region': 46.0,
    'top': 14.0,
    'ground_edge': 1.5,
    'wall_edge': 2.6,
    'strength': .7,
    'floor': .5,
    'skip': (),
    'clear': ('chalk',),
}
MAPS = {
    'hogwarts': {'skip': ('lake',)},
    'sandgate': {'region': (-31, 39, -33, 28), 'top': 10, 'strength': .72, 'skip': ('cloud',)},
    'snowline': {'region': (-18, 19, -16, 15), 'top': 9, 'strength': .62, 'floor': .55},
    'amusement_park': {'region': (-32, 31, -24, 24), 'top': 8, 'strength': .66},
    'palm_house': {'region': (-19, 20, -16, 16), 'top': 10, 'strength': .6, 'floor': .55,
                   'skip': ('glasshouse_glass',), 'clear': ('glass', 'water', 'water_deep')},
    'last_ferry': {'region': (-20, 22, -45, 15), 'top': 10, 'strength': .66,
                   'clear': ('moonlight',)},
    'rain_market': {'mode': 'ao', 'distance': 2.4, 'region': (-22, 28, -26, 30), 'top': 9,
                    'strength': .62, 'skip': ('harbour_water',),
                    'clear': ('window', 'neon_amber', 'neon_blue', 'neon_cream', 'neon_mint', 'neon_red')},
    'bb_office': {'mode': 'ao', 'distance': 1.8, 'region': (-26, 26, -19, 20), 'top': 4,
                  'strength': .7, 'skip': ('city',), 'clear': ('glass_blue', 'lamp')},
    'night_studio': {'mode': 'ao', 'distance': 2.0, 'region': (-22, 22, -17, 17), 'top': 6,
                     'strength': .68, 'clear': ('lamp',)},
    'baggage_below': {'mode': 'ao', 'distance': 2.0, 'region': (-20, 18, -17, 19), 'top': 7,
                      'strength': .68, 'clear': ('glass', 'skyglass', 'light')},
    'ginza_station': {'mode': 'ao', 'distance': 2.0, 'region': (-22, 22, -80, 20), 'top': 7,
                      'strength': .68, 'clear': ('glass', 'window', 'lamp')},
}
GROUND_BOUNCE = .32
BURIED = .12
SMOOTHING = 2


def settings(name):
    config = dict(DEFAULT)
    if MAPS[name].get('mode') == 'ao':
        # Short-range occlusion changes over metres, not across a whole wall.
        config.update(ground_edge=2.0, wall_edge=3.2)
    config.update(MAPS[name])
    return config


def godot_matrix(values):
    basis = Matrix(((values[0], values[3], values[6], values[9]),
                    (values[1], values[4], values[7], values[10]),
                    (values[2], values[5], values[8], values[11]),
                    (0, 0, 0, 1)))
    return AXES @ basis @ AXES.inverted()


def load(name, config):
    """Import baked kits once each at their map placement, plus occluder-only copies."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    placements = [p for p in json.loads(PLACEMENTS.read_text())[name] if p['static']]
    skip = set(config['skip'])
    counts = {}
    for place in placements:
        counts[place['kit']] = counts.get(place['kit'], 0) + 1
    baked, occluders, restore = {}, [], {}
    for place in placements:
        kit = Path(place['kit']).stem
        if kit in skip:
            continue
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=str(ROOT / place['kit']))
        parts = [o for o in bpy.data.objects if o not in before]
        offset = godot_matrix(place['transform'])
        for obj in parts:
            if obj.parent is None:
                restore[obj] = obj.matrix_world.copy()
                obj.matrix_world = offset @ obj.matrix_world
        # A kit placed more than once cannot hold one bake; it only casts occlusion.
        if counts[place['kit']] == 1:
            baked[place['kit']] = parts
        else:
            occluders.extend(parts)
    return baked, occluders, restore


def inside(centre, config):
    x, z = centre.x, -centre.y
    region = config['region']
    if isinstance(region, (int, float)):
        return Vector((x, z)).length <= region
    return region[0] <= x <= region[1] and region[2] <= z <= region[3]


def refine(obj, config):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.transform(obj.matrix_world)
    for _ in range(8):
        long = set()
        for face in bm.faces:
            centre = face.calc_center_median()
            if centre.z > config['top'] or not inside(centre, config):
                continue
            if config['mode'] == 'ao' and face.normal.z < -.5:
                continue
            limit = config['ground_edge'] if face.normal.z > .5 else config['wall_edge']
            long.update(e for e in face.edges if e.calc_length() > limit)
        if not long:
            break
        bmesh.ops.subdivide_edges(bm, edges=list(long), cuts=1, use_grid_fill=True)
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    bm.transform(obj.matrix_world.inverted())
    bm.to_mesh(obj.data)
    bm.free()


def bake(meshes, config):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'METAL'
    prefs.get_devices()
    for device in prefs.devices:
        device.use = True
    scene.cycles.device = 'GPU'
    scene.cycles.samples = 256
    scene.cycles.max_bounces = 3
    scene.cycles.diffuse_bounces = 2
    world = bpy.data.worlds.new('white_sky')
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (1, 1, 1, 1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value = 1
    world.light_settings.distance = config['distance']
    scene.world = world
    # Thin markings, glass and light panels let bake rays pass so they do not stain what is behind.
    clear = bpy.data.materials.new('bake_clear')
    clear.use_nodes = True
    nodes = clear.node_tree.nodes
    nodes.remove(nodes['Principled BSDF'])
    nodes.new('ShaderNodeBsdfTransparent')
    clear.node_tree.links.new(nodes['Transparent BSDF'].outputs[0], nodes['Material Output'].inputs[0])
    swapped = []
    for obj in meshes:
        for slot in obj.material_slots:
            if slot.material and slot.material.name.split('.')[0] in config['clear']:
                swapped.append((slot, slot.material))
                slot.material = clear
    for obj in meshes:
        mesh = obj.data
        for attr in list(mesh.color_attributes):
            mesh.color_attributes.remove(attr)
        mesh.color_attributes.new('Col', 'BYTE_COLOR', 'CORNER')
        mesh.color_attributes.active_color = mesh.color_attributes['Col']
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if config['mode'] == 'ao':
        bpy.ops.object.bake(type='AO', target='VERTEX_COLORS')
    else:
        bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, target='VERTEX_COLORS')
    for slot, material in swapped:
        slot.material = material


def normalise(meshes, config):
    """Per corner: divide by open-sky light (sky mode), then average corners that share a position
    and face the same way, and blur along edges to remove per-vertex sampling noise."""
    for obj in meshes:
        mesh = obj.data
        basis = obj.matrix_world.to_3x3().inverted().transposed()
        colours = mesh.color_attributes['Col'].data
        normals = [(basis @ Vector(n.vector)).normalized() for n in mesh.corner_normals]
        loops = mesh.loops
        light = []
        for index, item in enumerate(colours):
            if config['mode'] == 'ao':
                open_sky = 1.0
            else:
                up = normals[index].z
                open_sky = .5 * (1 + up) + .5 * (1 - up) * GROUND_BOUNCE
            light.append(Vector([min(c / open_sky, 1.05) for c in item.color[:3]]))
        # Corners buried under an overlapping layer (a rug on a floor, a slab on a slab) read black.
        # Nobody sees them, but they would bleed into the visible part of the triangle, so they
        # take the value of their unburied neighbours instead.
        buried = {i for i, value in enumerate(light) if max(value) < BURIED}
        groups = {}
        for index, loop in enumerate(loops):
            co = mesh.vertices[loop.vertex_index].co
            key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
            groups.setdefault(key, []).append(index)
        corner_key = {index: key for key, members in groups.items() for index in members}
        neighbours = {}
        for polygon in mesh.polygons:
            corners = list(polygon.loop_indices)
            for i, corner in enumerate(corners):
                neighbours.setdefault(corner, []).extend((corners[i - 1], corners[(i + 1) % len(corners)]))
        for _ in range(6):
            if not buried:
                break
            resolved = {}
            for index in buried:
                near = [n for n in neighbours.get(index, ()) if n not in buried]
                near += [m for m in groups[corner_key[index]] if m not in buried and normals[m].dot(normals[index]) > .7]
                if near:
                    resolved[index] = sum((light[n] for n in near), Vector()) / len(near)
            for index, value in resolved.items():
                light[index] = value
            buried -= set(resolved)
        for index in buried:
            light[index] = Vector((1, 1, 1))
        for _ in range(SMOOTHING):
            pooled = list(light)
            for key, members in groups.items():
                for index in members:
                    same = [m for m in members if normals[m].dot(normals[index]) > .7]
                    near = [n for m in same for n in neighbours.get(m, ())
                            if normals[n].dot(normals[index]) > .7]
                    total = sum((light[m] for m in same), Vector()) * 2 + sum((light[n] for n in near), Vector())
                    pooled[index] = total / (2 * len(same) + len(near))
            light = pooled
        for index, item in enumerate(colours):
            # Ceilings in covered maps are lit by their fixtures, not by what hangs below them.
            if config['mode'] == 'ao' and normals[index].z < -.5:
                light[index] = Vector((1, 1, 1))
            value = [max(c, config['floor']) for c in light[index]]
            item.color = [1 + (c - 1) * config['strength'] for c in value] + [1]


def export(baked, restore):
    for obj, matrix in restore.items():
        obj.matrix_world = matrix
    for kit, parts in baked.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in parts:
            obj.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(ROOT / kit), export_format='GLB',
                                  use_selection=True, export_vertex_color='ACTIVE')


def triangles(objects):
    return sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objects if o.type == 'MESH')


def main():
    name = sys.argv[sys.argv.index('--') + 1]
    config = settings(name)
    baked, occluders, restore = load(name, config)
    meshes = [o for parts in baked.values() for o in parts if o.type == 'MESH']
    before = triangles(meshes)
    for obj in meshes:
        refine(obj, config)
    print(f'VERTEX_LIGHT {name} {config["mode"]} refine {before} -> {triangles(meshes)} triangles')
    for kit, parts in baked.items():
        print('  ', Path(kit).stem, triangles(parts))
    # Occluder-only copies take part in the render but are not baked or exported.
    bake(meshes, config)
    normalise(meshes, config)
    for obj in occluders:
        restore.pop(obj, None)
        bpy.data.objects.remove(obj)
    export(baked, restore)
    print('VERTEX_LIGHT_DONE', name)


main()
