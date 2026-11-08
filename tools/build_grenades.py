"""Build editable grenade models and the first-person throwing glove."""
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/models/grenades"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

PALETTE = {
    "pine": "48715A", "sage": "83A378", "olive": "375043", "violet": "795395",
    "gold": "F2D084", "honey": "B8794A", "caramel": "D69559", "bark": "85533D",
    "shell": "436B5E", "ink": "25323E", "teal": "448879",
}
paints = {}
for name, hex_color in PALETTE.items():
    rgb = [int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4)]
    rgba = (*[v / 12.92 if v < .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb], 1)
    material = bpy.data.materials.new(name)
    material.diffuse_color = rgba
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = rgba
    shader.inputs["Roughness"].default_value = .83
    paints[name] = material


def group(name):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    return root


def paint(root, name, color):
    obj = bpy.context.object
    obj.name = name
    obj.parent = root
    obj.data.materials.append(paints[color])
    return obj


def cylinder(root, name, center, radius, depth, color, vertices=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=center)
    return paint(root, name, color)


def box(root, name, center, size, color, bevel):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = paint(root, name, color)
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("Facets", "BEVEL")
    modifier.width = bevel
    modifier.segments = 1


def profile(root, name, rings, color):
    sides = 10
    points = [
        (x + rx * math.cos(i * math.tau / sides), ry * math.sin(i * math.tau / sides), z)
        for x, z, rx, ry in rings for i in range(sides)
    ]
    faces = [tuple(reversed(range(sides)))]
    for row in range(len(rings) - 1):
        for i in range(sides):
            a = row * sides + i
            b = row * sides + (i + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    faces.append(tuple(range(len(points) - sides, len(points))))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(points, [], faces)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = root
    mesh.materials.append(paints[color])


def pin(root):
    cylinder(root, "Fuse cap", (0, 0, .107), .054, .042, "violet")
    bpy.ops.mesh.primitive_torus_add(major_segments=8, minor_segments=4, major_radius=.029,
                                    minor_radius=.006, location=(.053, -.009, .139),
                                    rotation=(math.pi / 2, .2, 0))
    paint(root, "Pull ring", "gold")


def antenna(root, start, end):
    direction = Vector(end) - Vector(start)
    rod = cylinder(root, "Antenna", (Vector(start) + Vector(end)) * .5,
                   .006, direction.length, "gold", 5)
    rod.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()


def export(root):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in (root, *root.children):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=str(OUT / f"{root.name}.glb"),
                             use_selection=True, export_format="GLB", export_yup=True)


frag = group("frag")
profile(frag, "Fragment shell", [(0, -.115, .064, .064), (0, -.081, .096, .096),
                                 (0, .047, .101, .101), (0, .087, .062, .062)], "pine")
for z, radius, color in [(-.065, .099, "olive"), (-.023, .102, "sage"), (.026, .104, "olive")]:
    cylinder(frag, "Cast seam", (0, 0, z), radius, .012, color, 10)
pin(frag)

stink = group("stink")
profile(stink, "Wide curl", [(0, -.113, .070, .064), (0, -.088, .112, .099),
                             (0, -.041, .110, .096), (.01, -.02, .075, .070)], "bark")
profile(stink, "Middle curl", [(-.01, -.039, .072, .060), (-.014, -.013, .091, .077),
                               (-.012, .026, .083, .073), (0, .043, .051, .045)], "honey")
profile(stink, "Curl tip", [(0, .020, .044, .044), (.016, .05, .059, .052),
                            (.020, .085, .043, .040), (.035, .125, .006, .006)], "caramel")
cylinder(stink, "Purple belt", (0, 0, -.066), .115, .033, "violet", 10)
pin(stink)

roach = group("roach")
profile(roach, "Carapace", [(0, -.125, .035, .03), (0, -.09, .071, .047),
                            (0, .030, .093, .056), (0, .089, .060, .041)], "shell")
for z, radius in [(-.075, .073), (-.038, .088), (.002, .095), (.041, .094)]:
    profile(roach, "Amber plate", [(0, z, radius * .91, .049),
                                    (0, z + .016, radius, .063),
                                    (0, z + .026, radius * .91, .053)], "honey")
box(roach, "Wing seam", (0, -.061, -.016), (.011, .013, .149), "ink", .004)
for sign in (-1, 1):
    start = (sign * .039, 0, .081)
    bend = (sign * .061, -.006, .139)
    end = (sign * .102, -.011, .167)
    antenna(roach, start, bend)
    antenna(roach, bend, end)
pin(roach)

glove = group("glove")
box(glove, "Glove", (0, 0, -.043), (.125, .132, .088), "ink", .024)
box(glove, "Thumb", (.057, -.005, -.003), (.042, .088, .068), "ink", .013)
box(glove, "Sleeve", (-.043, .012, -.127), (.138, .125, .165), "teal", .022)

for index, model in enumerate((frag, stink, roach, glove)):
    export(model)
    model.location.x = index * .55
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "art_source/grenades.blend"), compress=True)
