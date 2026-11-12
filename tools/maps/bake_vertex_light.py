"""Bake sky occlusion and coloured bounce light into the vertex colours of a map's static kits.

Run after the map's build script:
    blender --background --python tools/maps/bake_vertex_light.py -- hogwarts

Every static kit is loaded together so walls, roofs and props occlude each other. Cycles bakes the
diffuse light a surface receives from a uniform white sky, including one or more bounces tinted by
neighbouring paint. Dividing by what an open surface with the same normal would receive leaves only
occlusion and colour bleed, which the toy shaders multiply into the albedo. Direct sun, shadows and
ambient stay real-time. Large faces in the play space are split first so corners have vertices.
Re-running is safe: faces already small are not split again and colours are replaced.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
MAPS = {
    # kits, play radius, ground edge, wall edge, strength
    'hogwarts': (['terrain', 'pitch', 'pavilion', 'castle', 'village', 'hut', 'landscape', 'paving'],
                 46.0, 1.5, 2.6, .7),
}
GROUND_BOUNCE = .32
FLOOR = .5
SMOOTHING = 2
CLEAR = {'chalk'}


def load(folder, kits):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objects = {}
    for kit in kits:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=str(folder / f'{kit}.glb'))
        objects[kit] = [o for o in bpy.data.objects if o not in before]
    return objects


def refine(obj, radius, ground_edge, wall_edge):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.transform(obj.matrix_world)
    for _ in range(8):
        long = set()
        for face in bm.faces:
            centre = face.calc_center_median()
            if Vector((centre.x, centre.y)).length > radius:
                continue
            if centre.z > 14:
                continue
            limit = ground_edge if face.normal.z > .5 else wall_edge
            long.update(e for e in face.edges if e.calc_length() > limit)
        if not long:
            break
        bmesh.ops.subdivide_edges(bm, edges=list(long), cuts=1, use_grid_fill=True)
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    bm.transform(obj.matrix_world.inverted())
    bm.to_mesh(obj.data)
    bm.free()


def bake(meshes):
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
    scene.world = world
    # Thin painted markings lie on the turf; let bake rays pass so they do not stain it.
    clear = bpy.data.materials.new('bake_clear')
    clear.use_nodes = True
    nodes = clear.node_tree.nodes
    nodes.remove(nodes['Principled BSDF'])
    nodes.new('ShaderNodeBsdfTransparent')
    clear.node_tree.links.new(nodes['Transparent BSDF'].outputs[0], nodes['Material Output'].inputs[0])
    swapped = []
    for obj in meshes:
        for slot in obj.material_slots:
            if slot.material and slot.material.name.split('.')[0] in CLEAR:
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
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, target='VERTEX_COLORS')
    for slot, material in swapped:
        slot.material = material


def normalise(meshes, strength):
    """Per corner: divide by open-sky light, then average corners that share a position and face
    the same way, and blur along edges to remove per-vertex sampling noise."""
    for obj in meshes:
        mesh = obj.data
        basis = obj.matrix_world.to_3x3().inverted().transposed()
        colours = mesh.color_attributes['Col'].data
        normals = [(basis @ Vector(n.vector)).normalized() for n in mesh.corner_normals]
        loops = mesh.loops
        light = []
        for index, item in enumerate(colours):
            up = normals[index].z
            open_sky = .5 * (1 + up) + .5 * (1 - up) * GROUND_BOUNCE
            light.append(Vector([min(c / open_sky, 1.05) for c in item.color[:3]]))
        groups = {}
        for index, loop in enumerate(loops):
            co = mesh.vertices[loop.vertex_index].co
            key = (round(co.x, 3), round(co.y, 3), round(co.z, 3))
            groups.setdefault(key, []).append(index)
        neighbours = {}
        for polygon in mesh.polygons:
            corners = list(polygon.loop_indices)
            for i, corner in enumerate(corners):
                neighbours.setdefault(corner, []).extend((corners[i - 1], corners[(i + 1) % len(corners)]))
        corner_key = {}
        for key, members in groups.items():
            for index in members:
                corner_key[index] = key
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
            value = [max(c, FLOOR) for c in light[index]]
            item.color = [1 + (c - 1) * strength for c in value] + [1]


def export(folder, objects):
    for kit, parts in objects.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in parts:
            obj.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(folder / f'{kit}.glb'), export_format='GLB',
                                  use_selection=True, export_vertex_color='ACTIVE')


def main():
    name = sys.argv[sys.argv.index('--') + 1]
    kits, radius, ground_edge, wall_edge, strength = MAPS[name]
    folder = ROOT / 'assets/models' / name
    objects = load(folder, kits)
    meshes = [o for parts in objects.values() for o in parts if o.type == 'MESH']
    before = sum(len(o.data.polygons) for o in meshes)
    for obj in meshes:
        refine(obj, radius, ground_edge, wall_edge)
    after = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes)
    print(f'VERTEX_LIGHT refine {before} faces -> {after} triangles')
    for kit, parts in objects.items():
        print('  ', kit, sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in parts if o.type == 'MESH'))
    bake(meshes)
    normalise(meshes, strength)
    export(folder, objects)
    print('VERTEX_LIGHT_DONE', name)


main()
