"""Painted-plastic toy actors. Run: blender --background --python tools/build_toy_actors.py

Coordinates are authored in Godot space (Y up, forward -Z). Node names, iron-sight
points and muzzle position match the original actors so gameplay code is unchanged.
Every block is bevelled, then weighted normals keep faces flat while edges catch light.
"""
import bpy
import math
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models/toy'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

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

def export(name, merge=True):
    if merge:
        for material in list(MATS.values()):
            parts = [o for o in current.children if o.type == 'MESH' and o.data.materials[0] == material]
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

def ring(name, p, major, minor, material):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=20,
                                     minor_segments=8, location=xyz(p), rotation=(math.pi / 2, 0, 0))
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return finish(bpy.context.object, name, material, 0)

def pivot(obj, p):
    bpy.context.scene.cursor.location = xyz(p)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    return obj

def merge_rigid(main):
    """Join attached parts into as few meshes as possible without changing gameplay node names.
    Parts painted like the main mesh join it; every other colour becomes one child mesh."""
    groups = {}
    for o in main.children:
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

# Rifle: rear aperture centre (0,.269,-.17), front post tip (0,.205,-.65), muzzle near z -1.0.
# Layout follows docs/art/toy/concepts/tripo/player-rifle: blue receiver, cream handguard and
# stock, one smooth top rail, ring aperture on a short stem.
begin('rifle')
box('receiver', (0, 0, 0), (.19, .24, .60), 'toy_primary', .035)
for x in (-.097, .097):
    box('side_panel', (x, -.005, -.02), (.014, .12, .36), 'toy_shell', .006)
    box('glow_strip', (x * 1.07, -.02, -.02), (.008, .026, .24), 'toy_glow', .003)
    box('guard_slot', (x * .87, .01, -.50), (.008, .035, .17), 'toy_rubber', .004)
box('badge', (.098, .075, .14), (.012, .045, .075), 'toy_accent', .006)
box('handguard', (0, .01, -.50), (.165, .19, .42), 'toy_shell', .04)
cyl('barrel', (0, .01, -.80), .038, .2, 'toy_metal', 'z', 16, .006)
cyl('muzzle_ring', (0, .01, -.905), .05, .025, 'toy_glow', 'z', 16, .004)
cyl('muzzle', (0, .01, -.955), .058, .09, 'toy_primary', 'z', 16, .016)
box('stock', (0, 0, .45), (.17, .22, .30), 'toy_shell', .045)
box('stock_pad', (0, 0, .615), (.18, .235, .05), 'toy_rubber', .015)
box('rail', (0, .145, -.06), (.125, .05, .50), 'toy_metal', .014)
box('sight_base', (0, .19, -.17), (.05, .045, .05), 'toy_shell', .01)
ring('sight_ring', (0, .269, -.17), .058, .013, 'toy_metal')
box('post_base', (0, .12, -.65), (.05, .03, .05), 'toy_metal', .008)
box('front_sight', (0, .165, -.65), (.022, .08, .022), 'toy_accent', .005)
box('magazine', (0, -.25, .02), (.12, .34, .18), 'toy_metal', .025)
box('mag_window', (0, -.22, .02), (.126, .13, .045), 'toy_glow', .006)
box('mag_base', (0, -.42, .02), (.13, .04, .19), 'toy_primary', .014)
box('grip', (0, -.24, .27), (.1, .27, .13), 'toy_rubber', .03, (-.18, 0, 0))
box('trigger_guard', (0, -.14, .17), (.055, .1, .13), 'toy_metal', .012)
box('left_glove', (-.08, -.16, -.38), (.15, .14, .18), 'toy_glove', .04)
box('left_cuff', (-.17, -.29, -.27), (.19, .07, .21), 'toy_cuff', .025, (.45, 0, .35))
box('left_sleeve', (-.22, -.36, -.19), (.21, .35, .23), 'toy_sleeve', .05)
box('right_glove', (.015, -.23, .3), (.13, .17, .17), 'toy_glove', .04)
box('right_cuff', (.07, -.33, .39), (.18, .06, .2), 'toy_cuff', .022, (.35, 0, -.25))
box('right_sleeve', (.1, -.42, .45), (.2, .34, .23), 'toy_sleeve', .05)
export('rifle')

# Enemy rifleman, after docs/art/toy/concepts/tripo/rifleman: big helmet, coral pads, boots.
# Gameplay names stay; limbs pivot at shoulder and hip. Head hit sphere stays at y 1.70,
# the shot origin at (.22, 1.12, -.58) is the blaster's front opening.
begin('enemy')
torso = box('Torso', (0, 1.30, 0), (.56, .38, .32), 'toy_body', .08)
attach(box('Backpack', (0, 1.29, .22), (.38, .36, .14), 'toy_body_dark', .04), torso)
attach(box('PackPlate', (0, 1.30, .295), (.18, .08, .02), 'toy_vest', .01), torso)
attach(box('Belt', (0, 1.11, 0), (.48, .08, .33), 'toy_vest', .02), torso)
attach(box('Pelvis', (0, 1.0, 0), (.40, .17, .27), 'toy_body_dark', .04), torso)
attach(cyl('Neck', (0, 1.51, 0), .075, .10, 'toy_body_dark'), torso)
merge_rigid(torso)
vest = box('Vest', (0, 1.32, -.165), (.44, .30, .07), 'toy_vest', .03)
attach(box('ChestMark', (0, 1.36, -.203), (.15, .045, .02), 'toy_visor', .008), vest)
head = box('Head', (0, 1.68, 0), (.36, .29, .33), 'toy_body', .07)
for side, x in [('Left', -.195), ('Right', .195)]:
    attach(cyl(side + 'Ear', (x, 1.68, .01), .075, .05, 'toy_body_dark', 'x', 16, .012), head)
merge_rigid(head)
helmet = box('Helmet', (0, 1.835, .01), (.39, .11, .37), 'toy_body_dark', .045)
attach(box('Crest', (0, 1.915, 0), (.08, .075, .38), 'toy_team', .025), helmet)
box('Visor', (0, 1.70, -.167), (.28, .08, .04), 'toy_visor', .015)
for side, x in [('Left', -.16), ('Right', .16)]:
    leg = pivot(box(side + 'Leg', (x, .81, 0), (.20, .32, .22), 'toy_body', .05), (x, .98, 0))
    attach(box(side + 'Shin', (x, .38, .01), (.22, .40, .24), 'toy_body', .055), leg)
    attach(cyl(side + 'KneeJoint', (x, .62, 0), .08, .17, 'toy_body_dark', 'x', 12, .01), leg)
    attach(box(side + 'Knee', (x, .60, -.13), (.19, .15, .06), 'toy_vest', .025), leg)
    attach(box(side + 'Foot', (x, .095, -.05), (.26, .19, .37), 'toy_body_dark', .05), leg)
    merge_rigid(leg)
hands = {'Left': (.20, 1.07, -.50), 'Right': (.25, 1.03, -.24)}
elbows = {'Left': (-.30, 1.17, -.27), 'Right': (.40, 1.20, -.04)}
for side, s in [('Left', -1), ('Right', 1)]:
    shoulder = (.37 * s, 1.43, 0)
    arm = pivot(segment(side + 'Arm', shoulder, elbows[side], (.18, .19), 'toy_body', .05), shoulder)
    attach(segment(side + 'Forearm', elbows[side], hands[side], (.16, .17), 'toy_body', .05), arm)
    attach(cyl(side + 'Elbow', elbows[side], .088, .17, 'toy_body_dark', 'x', 12, .01), arm)
    attach(box(side + 'Pad', (.39 * s, 1.47, 0), (.25, .16, .27), 'toy_team', .06), arm)
    merge_rigid(arm)
    box(side + 'Hand', hands[side], (.14, .14, .15), 'toy_rubber', .045)
G = (.22, 1.12, -.36)
def gp(x, y, z):
    return (G[0] + x, G[1] + y, G[2] + z)
gun = box('EnemyGun', G, (.10, .11, .34), 'toy_gun', .022)
for part in [
    box('GunMuzzle', gp(0, .005, -.205), (.078, .078, .08), 'toy_body_dark', .016),
    box('GunBore', gp(0, .005, -.246), (.038, .038, .012), 'toy_rubber', 0),
    box('GunStock', gp(0, 0, .215), (.112, .125, .09), 'toy_gun_light', .022),
    box('GunTop', gp(0, .073, -.03), (.05, .04, .08), 'toy_body_dark', .01),
    box('GunRear', gp(0, .066, .12), (.04, .025, .04), 'toy_body_dark', .006),
    box('GunClip', gp(0, -.11, -.06), (.05, .13, .08), 'toy_gun_light', .012),
    box('GunGrip', gp(0, -.10, .09), (.045, .12, .06), 'toy_body_dark', .012, (-.3, 0, 0)),
    box('GunStripe', gp(-.052, .012, -.02), (.006, .022, .22), 'toy_visor', .003),
    box('GunStripe', gp(.052, .012, -.02), (.006, .022, .22), 'toy_visor', .003),
]:
    attach(part, gun)
merge_rigid(gun)
export('enemy', False)

bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art_source/toy_actors.blend'), compress=True)
