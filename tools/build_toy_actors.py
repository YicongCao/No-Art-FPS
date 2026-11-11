"""Painted-plastic toy actors. Run: blender --background --python tools/build_toy_actors.py

Coordinates are authored in Godot space (Y up, forward -Z). Node names, iron-sight
points and muzzle position match the original actors so gameplay code is unchanged.
Every block is bevelled, then weighted normals keep faces flat while edges catch light.
"""
import bpy
import math
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

# Rifle: rear aperture centre (0,.269,-.17), front post tip (0,.205,-.65), muzzle near z -1.0.
begin('rifle')
box('receiver', (0, 0, 0), (.18, .23, .68), 'toy_primary', .035)
box('top_cover', (0, .108, .02), (.172, .05, .56), 'toy_shell', .02)
for x in (-.094, .094):
    box('side_panel', (x, -.005, -.04), (.014, .13, .40), 'toy_shell', .006)
    box('glow_strip', (x * 1.06, -.052, -.06), (.008, .022, .26), 'toy_glow', .003)
    for i in range(3):
        box('vent', (x * 1.02, .03, -.30 + i * .05), (.012, .045, .022), 'toy_metal', .004)
box('rail', (0, .145, -.13), (.13, .045, .65), 'toy_metal', .01)
for i in range(6):
    box('rail_tooth', (0, .174, -.40 + i * .1), (.15, .022, .04), 'toy_metal', .006)
box('foregrip', (0, .015, -.46), (.15, .18, .32), 'toy_shell', .04)
box('foregrip_band', (0, .015, -.31), (.158, .186, .035), 'toy_primary', .012)
for x in (-.077, .077):
    box('grip_slot', (x, -.01, -.50), (.008, .03, .16), 'toy_rubber', .004)
cyl('barrel', (0, .015, -.77), .04, .3, 'toy_metal', 'z', 16, .006)
cyl('muzzle', (0, .015, -.94), .058, .11, 'toy_primary', 'z', 16, .014)
cyl('muzzle_ring', (0, .015, -.875), .061, .016, 'toy_glow', 'z', 16, .003)
box('stock', (0, -.02, .42), (.15, .21, .28), 'toy_shell', .045)
box('stock_pad', (0, -.025, .57), (.156, .22, .045), 'toy_rubber', .015)
box('magazine', (0, -.25, .02), (.12, .34, .18), 'toy_metal', .025)
box('mag_window', (0, -.22, .02), (.126, .12, .05), 'toy_glow', .006)
box('mag_base', (0, -.42, .02), (.13, .04, .19), 'toy_primary', .014)
box('grip', (0, -.24, .27), (.1, .27, .13), 'toy_rubber', .03, (-.18, 0, 0))
box('trigger_guard', (0, -.14, .17), (.055, .1, .13), 'toy_metal', .012)
for x in (-.062, .062):
    box('sight_side', (x, .265, -.17), (.025, .16, .035), 'toy_metal', .006)
box('sight_top', (0, .345, -.17), (.15, .026, .035), 'toy_metal', .006)
box('sight_base', (0, .188, -.17), (.15, .035, .08), 'toy_shell', .01)
box('post_base', (0, .12, -.65), (.06, .03, .05), 'toy_metal', .008)
box('front_sight', (0, .16, -.65), (.025, .09, .025), 'toy_accent', .005)
box('badge', (.097, .055, .18), (.012, .05, .1), 'toy_accent', .006)
box('left_glove', (-.08, -.16, -.38), (.15, .14, .18), 'toy_glove', .04)
box('left_cuff', (-.17, -.29, -.27), (.19, .07, .21), 'toy_cuff', .025, (.45, 0, .35))
box('left_sleeve', (-.22, -.36, -.19), (.21, .35, .23), 'toy_sleeve', .05)
box('right_glove', (.015, -.23, .3), (.13, .17, .17), 'toy_glove', .04)
box('right_cuff', (.07, -.33, .39), (.18, .06, .2), 'toy_cuff', .022, (.35, 0, -.25))
box('right_sleeve', (.1, -.42, .45), (.2, .34, .23), 'toy_sleeve', .05)
export('rifle')

# Enemy: names and pivots match the original actor. Head hit sphere stays at y 1.70.
begin('enemy')
box('Torso', (0, 1.21, 0), (.46, .54, .26), 'toy_body', .07)
box('Vest', (0, 1.24, -.15), (.36, .34, .08), 'toy_vest', .03)
box('ChestMark', (0, 1.33, -.195), (.16, .05, .02), 'toy_visor', .008)
box('Backpack', (0, 1.22, .17), (.30, .34, .12), 'toy_body_dark', .04)
box('Pelvis', (0, .86, 0), (.32, .17, .24), 'toy_body_dark', .04)
cyl('Neck', (0, 1.52, 0), .075, .12, 'toy_body_dark')
cyl('Head', (0, 1.68, 0), .17, .28, 'toy_body', 'y', 16, .035)
helmet = cyl('Helmet', (0, 1.81, 0), .2, .12, 'toy_body_dark', 'y', 16, .04)
attach(box('Crest', (0, 1.88, .01), (.05, .045, .32), 'toy_team', .015), helmet)
box('Visor', (0, 1.70, -.165), (.28, .065, .04), 'toy_visor', .015)
for side, x in [('Left', -.145), ('Right', .145)]:
    leg = box(side + 'Leg', (x, .46, 0), (.15, .68, .17), 'toy_body', .045)
    attach(box(side + 'Knee', (x, .52, -.095), (.12, .11, .04), 'toy_vest', .015), leg)
    box(side + 'Foot', (x, .09, -.06), (.19, .16, .30), 'toy_body_dark', .05)
for side, x in [('Left', -.30), ('Right', .30)]:
    arm = box(side + 'Arm', (x, 1.17, -.025), (.14, .46, .16), 'toy_body', .045)
    attach(box(side + 'Pad', (x * 1.04, 1.40, -.02), (.18, .11, .21), 'toy_team', .04), arm)
    box(side + 'Hand', (x, 1.02, -.18), (.12, .13, .14), 'toy_rubber', .04)
gun = box('EnemyGun', (.22, 1.12, -.35), (.1, .12, .45), 'toy_metal', .025)
attach(box('GunStripe', (.272, 1.14, -.38), (.006, .025, .24), 'toy_visor', .003), gun)
export('enemy', False)

bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art_source/toy_actors.blend'), compress=True)
