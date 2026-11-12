"""Shared painted-plastic toy blocks for Blender builds, authored in Godot space (Y up, forward -Z).

Every block is bevelled, then weighted normals keep faces flat while edges catch light.
"""
import bpy
import math
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models/toy'


def reset(out):
    """Empty the scene and send exports to out."""
    global OUT
    OUT = Path(out)
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MATS.clear()
    roots.clear()

# name: (hex, roughness, metallic, emission strength)
PAINT = {
    'toy_shell': ('DED7C6', .38, 0, 0),
    'toy_primary': ('2F5FD6', .32, 0, 0),
    'toy_metal': ('3B4553', .40, .55, 0),
    'toy_rubber': ('232B35', .68, 0, 0),
    'toy_glow': ('3FE2D2', .30, 0, 3.0),
    'toy_accent': ('F4B33E', .34, 0, 0),
    'toy_glove': ('2C3542', .58, 0, 0),
    'toy_sleeve': ('4C8C78', .82, 0, 0),
    'toy_cuff': ('ECE6D6', .5, 0, 0),
    'toy_body': ('2B3447', .40, 0, 0),
    'toy_body_dark': ('1D2431', .50, 0, 0),
    'toy_vest': ('4D5B72', .44, 0, 0),
    'toy_team': ('E0513F', .34, 0, 0),
    'toy_visor': ('FF5A3C', .25, 0, 1.1),
    'toy_gun': ('5B6476', .40, 0, 0),
    'toy_gun_light': ('7C8496', .42, 0, 0),
    'toy_rush': ('E9631D', .36, 0, 0),
    'toy_cream': ('EFE6D2', .40, 0, 0),
    'toy_joint': ('3A3F4A', .50, 0, 0),
    'toy_thrust': ('FFB347', .30, 0, 2.2),
    'toy_blade': ('5FE3F2', .22, 0, .6),
    'toy_water': ('3583CF', .34, 0, 0),
    'toy_tank': ('FFC83D', .30, 0, 0),
    'toy_nozzle': ('F2672E', .34, 0, 0),
    'toy_gold': ('E8B23A', .30, .35, 0),
    'toy_pump': ('5ED08E', .38, 0, 0),
    'toy_navy': ('243A74', .46, 0, 0),
    'toy_aqua': ('8EE8E0', .26, 0, .3),
    'toy_violet': ('9B4FC4', .34, 0, 0),
    'toy_plum': ('5E2C68', .48, 0, 0),
    'toy_lilac': ('C49BEA', .36, 0, 0),
    'toy_mop': ('8FD9A0', .78, 0, 0),
    'toy_sole': ('F2862E', .45, 0, 0),
}
MATS = {}

def linear(c):
    return c / 12.92 if c < .04045 else ((c + .055) / 1.055) ** 2.4

def paint(name):
    if name in MATS:
        return MATS[name]
    code, rough, metal, glow = PAINT[name]
    rgba = tuple(linear(int(code[i:i+2], 16) / 255) for i in (0, 2, 4)) + (1,)
    m = bpy.data.materials.new(name)
    m.diffuse_color = rgba
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = rgba
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    if glow:
        p.inputs['Emission Color'].default_value = rgba
        p.inputs['Emission Strength'].default_value = glow
    MATS[name] = m
    return m

current = None
roots = []

def xyz(p):
    return (p[0], -p[2], p[1])

def begin(name):
    global current
    current = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(current)
    roots.append(current)

def soften(obj, width, segments=3):
    bpy.context.view_layer.objects.active = obj
    if width > 0:
        bevel = obj.modifiers.new('Toy bevel', 'BEVEL')
        bevel.width = width
        bevel.segments = segments
        bevel.limit_method = 'ANGLE'
        bevel.angle_limit = math.radians(40)
        bevel.harden_normals = True
        bevel.use_clamp_overlap = True
        bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.ops.object.shade_smooth()
    weighted = obj.modifiers.new('Flat faces', 'WEIGHTED_NORMAL')
    weighted.keep_sharp = True
    weighted.weight = 100
    bpy.ops.object.modifier_apply(modifier=weighted.name)

def finish(obj, name, material, width, rotation=None):
    obj.name = name
    if rotation:
        obj.rotation_euler = (rotation[0], -rotation[2], rotation[1])
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    soften(obj, width)
    obj.data.materials.append(paint(material))
    obj.parent = current
    return obj

def box(name, p, size, material, width=.012, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(p))
    obj = bpy.context.object
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material, width, rotation)

def attach(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()
    return child

def cyl(name, p, r, depth, material, axis='y', vertices=16, width=.008):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=r, depth=depth, location=xyz(p))
    obj = bpy.context.object
    rotation = {'x': (0, 0, math.pi / 2), 'z': (math.pi / 2, 0, 0)}.get(axis)
    return finish(obj, name, material, width, rotation)

def export(name, merge=True, keep=()):
    if merge:
        for material in list(MATS.values()):
            parts = [o for o in current.children if o.type == 'MESH' and o.data.materials[0] == material
                     and o.name not in keep]
            if len(parts) > 1:
                bpy.ops.object.select_all(action='DESELECT')
                for o in parts:
                    o.select_set(True)
                bpy.context.view_layer.objects.active = parts[0]
                bpy.ops.object.join()
                parts[0].name = name + '_' + material.name
    bpy.ops.object.select_all(action='DESELECT')
    current.select_set(True)
    for o in current.children_recursive:
        o.select_set(True)
    bpy.context.view_layer.objects.active = current
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name + '.glb')), use_selection=True,
                              export_format='GLB', export_yup=True, export_normals=True)
    current.location = ((len(roots) - 1) * 2.5, 0, 0)
    # Later actors reuse gameplay names such as Head; free them inside this .blend.
    for o in current.children_recursive:
        o.name = name + '/' + o.name

def segment(name, a, b, section, material, width=.03):
    a, b = Vector(xyz(a)), Vector(xyz(b))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(a + b) / 2)
    obj = bpy.context.object
    obj.dimensions = (section[0], section[1], (b - a).length)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference((b - a).normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    obj.rotation_mode = 'XYZ'
    return finish(obj, name, material, width)

def ring(name, p, major, minor, material, axis='z'):
    turn = {'z': (math.pi / 2, 0, 0), 'x': (0, math.pi / 2, 0), 'y': (0, 0, 0)}[axis]
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=20,
                                     minor_segments=8, location=xyz(p), rotation=turn)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return finish(bpy.context.object, name, material, 0)

def pivot(obj, p):
    bpy.context.scene.cursor.location = xyz(p)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    return obj

def merge_rigid(main, keep=()):
    """Join attached parts into as few meshes as possible without changing gameplay node names.
    Parts painted like the main mesh join it; every other colour becomes one child mesh."""
    groups = {}
    for o in main.children:
        if o.name in keep:
            continue
        groups.setdefault(o.data.materials[0].name, []).append(o)
    for material, parts in groups.items():
        target = main if main.data.materials[0].name == material else parts[0]
        rest = [o for o in parts if o is not target]
        if not rest:
            continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in rest + [target]:
            o.select_set(True)
        bpy.context.view_layer.objects.active = target
        bpy.ops.object.join()
    return main

