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
    'toy_body': ('222A3A', .38, .08, 0),
    'toy_body_dark': ('151A24', .52, .12, 0),
    'toy_vest': ('4E5D75', .40, .10, 0),
    'toy_team': ('DF3F35', .32, 0, 0),
    'toy_visor': ('FF4D30', .22, 0, 1.8),
    'toy_gun': ('4E5769', .38, .15, 0),
    'toy_gun_light': ('788296', .40, .10, 0),
    'toy_rush': ('EE641C', .34, 0, 0),
    'toy_cream': ('F0E7D4', .38, 0, 0),
    'toy_joint': ('29303C', .50, .12, 0),
    'toy_thrust': ('FFA834', .26, 0, 2.5),
    'toy_blade': ('4CE8F8', .20, 0, 1.45),
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

def soften(obj, width, segments=3, angle_deg=40):
    bpy.context.view_layer.objects.active = obj
    if width > 0:
        bevel = obj.modifiers.new('Toy bevel', 'BEVEL')
        bevel.width = width
        bevel.segments = segments
        bevel.limit_method = 'ANGLE'
        bevel.angle_limit = math.radians(angle_deg)
        bevel.harden_normals = True
        bevel.use_clamp_overlap = True
        bpy.ops.object.modifier_apply(modifier=bevel.name)
    bpy.ops.object.shade_smooth()
    weighted = obj.modifiers.new('Flat faces', 'WEIGHTED_NORMAL')
    weighted.keep_sharp = True
    weighted.weight = 100
    bpy.ops.object.modifier_apply(modifier=weighted.name)

def finish(obj, name, material, width, rotation=None, segments=3, angle_deg=40):
    obj.name = name
    if rotation:
        obj.rotation_euler = (rotation[0], -rotation[2], rotation[1])
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    soften(obj, width, segments=segments, angle_deg=angle_deg)
    obj.data.materials.append(paint(material))
    obj.parent = current
    return obj

def box(name, p, size, material, width=.012, rotation=None, segments=2):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(p))
    obj = bpy.context.object
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material, width, rotation, segments=segments)

def attach(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()
    return child

def cyl(name, p, r, depth, material, axis='y', vertices=16, width=.008, segments=2):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=r, depth=depth, location=xyz(p))
    obj = bpy.context.object
    rotation = {'x': (0, 0, math.pi / 2), 'z': (math.pi / 2, 0, 0)}.get(axis)
    return finish(obj, name, material, width, rotation, segments=segments)

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


def wedge(name, p, bottom_size, top_size, height, material, width=.015, top_shift=(0.0, 0.0), rotation=None):
    """Tapered 8-vertex mecha armor block with origin at `p` and crisp beveled facets."""
    import bmesh
    bw, bd = bottom_size
    tw, td = top_size
    sx, sz = top_shift
    hy = height * 0.5
    local_pts = [
        (-bw * .5, -hy, -bd * .5), (bw * .5, -hy, -bd * .5),
        (bw * .5, -hy, bd * .5), (-bw * .5, -hy, bd * .5),
        (-tw * .5 + sx, hy, -td * .5 + sz), (tw * .5 + sx, hy, -td * .5 + sz),
        (tw * .5 + sx, hy, td * .5 + sz), (-tw * .5 + sx, hy, td * .5 + sz),
    ]
    faces = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([xyz(v) for v in local_pts], [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = xyz(p)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    return finish(obj, name, material, width, rotation=rotation, segments=2, angle_deg=26)


def plate_profile(name, p, points_2d, thickness, material, width=.010, plane='xy', rotation=None):
    """Extruded 2D polygon centered at `p` along `plane` ('xy' front, 'zy' side, 'xz' top)."""
    import bmesh
    half = thickness * 0.5
    verts = []
    for layer in (-half, half):
        for u, v in points_2d:
            if plane == 'xy':
                pt = (u, v, layer)
            elif plane == 'zy':
                pt = (layer, v, u)
            else:
                pt = (u, layer, v)
            verts.append(xyz(pt))
    n = len(points_2d)
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = xyz(p)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    return finish(obj, name, material, width, rotation=rotation, segments=2, angle_deg=28)


def taper_limb(name, a, b, sec_a, sec_b, material, width=.020):
    """Tapered rectangular mecha limb segment from Godot point `a` to `b`."""
    import bmesh
    va, vb = Vector(xyz(a)), Vector(xyz(b))
    mid = (va + vb) * 0.5
    length = (vb - va).length
    hl = length * 0.5
    wa, da = sec_a[0] * 0.5, sec_a[1] * 0.5
    wb, db = sec_b[0] * 0.5, sec_b[1] * 0.5
    verts = [
        (-wa, -da, -hl), (wa, -da, -hl), (wa, da, -hl), (-wa, da, -hl),
        (-wb, -db, hl), (wb, -db, hl), (wb, db, hl), (-wb, db, hl),
    ]
    faces = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = mid
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference((vb - va).normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    obj.rotation_mode = 'XYZ'
    return finish(obj, name, material, width, segments=2, angle_deg=26)


def joint_drum(name, p, r, length, parent, drum_mat='toy_body_dark', cap_mat='toy_cream', axis='x'):
    """Exposed action-figure mechanical hinge drum with contrasting circular snap-fit end caps."""
    drum = cyl(name, p, r, length, drum_mat, axis=axis, vertices=16, width=.008)
    attach(drum, parent)
    if cap_mat:
        cap = cyl(name + 'Disc', p, r * 0.62, length + 0.018, cap_mat, axis=axis, vertices=14, width=.005)
        attach(cap, parent)
    return drum


def sculpt_loft(name, p, sections, material, axis='y', exponent=.68, sides=16, rotation=None):
    """Curved superellipse armor shell lofted through local `(pos, shift_x, shift_z, w, d)` sections,
    with object origin strictly at `p` so shaders and pivots stay centred."""
    import bmesh
    verts = []
    for pos, sx, sz, w, d in sections:
        for i in range(sides):
            ang = math.tau * i / sides
            ca, sa = math.cos(ang), math.sin(ang)
            u = math.copysign(abs(ca) ** exponent, ca) * (w * 0.5) + sx
            v = math.copysign(abs(sa) ** exponent, sa) * (d * 0.5) + sz
            pt = (u, pos, v) if axis == 'y' else (u, v, pos)
            verts.append(xyz(pt))
    faces = [tuple(reversed(range(sides)))]
    for j in range(len(sections) - 1):
        base = j * sides
        for i in range(sides):
            nxt = (i + 1) % sides
            faces.append((base + i, base + nxt, base + sides + nxt, base + sides + i))
    top_base = (len(sections) - 1) * sides
    faces.append(tuple(range(top_base, top_base + sides)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = xyz(p)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    return finish(obj, name, material, .008, rotation=rotation, segments=1, angle_deg=42)



