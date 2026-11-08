"""Build the Last Ferry Blender source and material-batched GLBs."""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/models/ferry"
LAYOUT = json.loads((ROOT / "tools/maps/last_ferry_layout.json").read_text())
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)


def xyz(p):
    return (p[0], -p[2], p[1])


def material(name, rgb, glow=0):
    srgb = [int(rgb[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    color = (*[c / 12.92 if c < .04045 else ((c + .055) / 1.055) ** 2.4 for c in srgb], 1)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = .86
    if glow:
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = glow
    return mat


palette = {name: material(name, color, glow) for name, color, glow in (
    ("deck", "CDA477", 0), ("plank", "BA8C5C", 0), ("cream", "F4E5BD", 0),
    ("green", "2D8A6C", 0), ("green_dark", "225B52", 0), ("metal", "24344F", 0),
    ("blue", "3F68CD", 0), ("blue_light", "6C97E0", 0), ("violet", "784991", 0),
    ("teal", "3AA091", 0), ("coral", "DE7657", 0), ("gold", "E9B34E", 0),
    ("lamp", "FFCB77", .85), ("glass", "5D86A2", 0), ("moonlight", "FFE5AD", 1.1),
    ("shore", "2A4265", 0), ("shore_light", "526888", 0),
)}


class Kit:
    def __init__(self, name, location=(0, 0, 0)):
        self.name = name
        self.location = location
        self.parts = []
        self.collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(self.collection)

    def mesh(self, label, vertices, faces, color):
        self.parts.append((vertices, faces, color))
        data = bpy.data.meshes.new(label)
        data.from_pydata([xyz(v) for v in vertices], [], faces)
        data.update()
        data.materials.append(palette[color])
        obj = bpy.data.objects.new(label, data)
        self.collection.objects.link(obj)

    def box(self, label, center, size, color):
        x, y, z = center
        dx, dy, dz = (n / 2 for n in size)
        vertices = [(x + sx * dx, y + sy * dy, z + sz * dz)
                    for sx, sy, sz in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                                       (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
        self.mesh(label, vertices, [(3,2,1,0),(4,5,6,7),(0,1,5,4),
                                    (1,2,6,5),(2,3,7,6),(3,0,4,7)], color)

    def rod(self, label, start, end, radius, color, sides=8, top=None):
        start, end = Vector(start), Vector(end)
        axis = (end - start).normalized()
        tangent = axis.cross(Vector((0, 1, 0)))
        if tangent.length < .01:
            tangent = axis.cross(Vector((1, 0, 0)))
        tangent.normalize()
        bitangent = axis.cross(tangent)
        vertices = []
        for center, r in ((start, radius), (end, radius if top is None else top)):
            vertices.extend(center + r * (math.cos(i * math.tau / sides) * tangent
                                          + math.sin(i * math.tau / sides) * bitangent)
                            for i in range(sides))
        faces = [tuple(reversed(range(sides))), tuple(range(sides, sides * 2))]
        for i in range(sides):
            j = (i + 1) % sides
            faces.append((i, j, j + sides, i + sides))
        self.mesh(label, vertices, faces, color)

    def loft(self, label, points, rings, color, cap=True):
        count = len(points)
        vertices = [(x * scale, y, z * scale) for y, scale in rings for x, z in points]
        faces = [(ring * count + i, (ring + 1) * count + i, (ring + 1) * count + (i + 1) % count,
                  ring * count + (i + 1) % count) for ring in range(len(rings) - 1) for i in range(count)]
        if cap:
            faces += [tuple(range(count)), tuple(reversed(range(len(vertices) - count, len(vertices))))]
        self.mesh(label, vertices, faces, color)

    def export(self):
        vertices, faces, colors = [], [], []
        for points, polygons, color in self.parts:
            faces.extend(tuple(len(vertices) + i for i in face) for face in polygons)
            vertices.extend(xyz(p) for p in points)
            colors.extend([color] * len(polygons))
        data = bpy.data.meshes.new(self.name)
        data.from_pydata(vertices, [], faces)
        data.update()
        keys = list(dict.fromkeys(colors))
        for key in keys:
            data.materials.append(palette[key])
        for face, color in zip(data.polygons, colors):
            face.material_index = keys.index(color)
        obj = bpy.data.objects.new(self.name, data)
        bpy.context.scene.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.export_scene.gltf(filepath=str(OUT / f"{self.name}.glb"), export_format="GLB", use_selection=True)
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(data)


def railing(kit, a, b, color="cream"):
    a, b = Vector(a), Vector(b)
    for level in (.47, 1.02):
        height = Vector((0, level, 0))
        kit.rod("Rail", a + height, b + height, .052, color, 6)
    count = math.ceil((b - a).length / 2.2)
    for i in range(count):
        post = a.lerp(b, i / count)
        kit.rod("Post", post, post + Vector((0, 1.05, 0)), .062, color, 6)


kits = []
deck = Kit("deck")
kits.append(deck)
outline = LAYOUT["outline"]
deck.loft("Green hull", outline, [(-4.35, .77), (-2.2, .965), (-.52, 1)], "green")
deck.loft("Waterline", outline, [(-3.25, .876), (-2.96, .903)], "green_dark", False)
deck.loft("Ivory gunwale", outline, [(-.52, 1), (-.13, 1.005)], "cream", False)
deck.loft("Timber deck", outline, [(-.13, 1.005), (0, 1)], "deck")
for side in (-1, 1):
    for z in range(-12, 22, 3):
        deck.box("Passenger window frame", (side * 13.36, -1.21, z), (.14, .92, 2.12), "green_dark")
        deck.box("Passenger window", (side * 13.445, -1.21, z), (.04, .72, 1.88), "lamp")
for z in range(-26, 25):
    edges = []
    for (x0, z0), (x1, z1) in zip(outline, outline[1:] + outline[:1]):
        if min(z0, z1) <= z < max(z0, z1):
            edges.append(x0 + (x1 - x0) * (z - z0) / (z1 - z0))
    if len(edges) == 2:
        width = abs(edges[0] - edges[1]) - .45
        deck.box("Deck seam", (0, .006, z), (width, .01, .025), "plank")
for i, (x, z) in enumerate(outline):
    x2, z2 = outline[(i + 1) % len(outline)]
    railing(deck, (x * .981, 0, z * .985), (x2 * .981, 0, z2 * .985))
for side in (-1, 1):
    for z in (-16, -6, 4, 14):
        x = side * 12.45
        deck.rod("Lamp pole", (x, 0, z), (x, 2.5, z), .09, "blue")
        deck.box("Lamp shade", (x, 2.50, z), (.48, .15, .37), "blue")
        deck.box("Warm lamp", (x, 2.37, z), (.36, .14, .26), "lamp")
    for z in (-21, 7, 20):
        x = side * (10.7 if z < -20 else 13.06)
        for index in range(12):
            angle = math.tau * index / 12
            next_angle = angle + math.tau / 12
            a = (x, .73 + math.cos(angle)*.33, z + math.sin(angle)*.33)
            b = (x, .73 + math.cos(next_angle)*.33, z + math.sin(next_angle)*.33)
            deck.rod("Lifebuoy",a,b,.076,"cream" if index%3==0 else "coral",6)

bridge = Kit("bridge")
kits.append(bridge)
b = LAYOUT["bridge"]
x, h, half, ramp_width, end = (b[k] for k in ("x","height","end","ramp_width","ramp_end"))
bridge_outline = b["outline"]
bridge.loft("Observation deck", [(x + px, z) for px, z in bridge_outline], [(h-.36,1),(h,1)], "blue")
for (px, z), (qx, w) in zip(bridge_outline, bridge_outline[1:] + bridge_outline[:1]):
    if z != w or abs(z) < half:
        railing(bridge, (x + px, h, z), (x + qx, h, w), "blue_light")
for side in (-1, 1):
    for z in (-2.15, 2.15):
        bridge.box("Support", (x + side*3.5, 1.15, z), (.36, 2.3, .36), "gold")
    ramp = Kit("bridge_ramp_fore" if side < 0 else "bridge_ramp_aft")
    kits.append(ramp)
    za, zb = half * side, end * side
    left, right = x - ramp_width / 2, x + ramp_width / 2
    vertices = [(left,h,za),(right,h,za),(right,0,zb),(left,0,zb),
                (left,h-.24,za),(right,h-.24,za),(right,-.24,zb),(left,-.24,zb)]
    faces = [(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
    ramp.mesh("Ramp", vertices, faces if side < 0 else [tuple(reversed(f)) for f in faces], "blue")
    for edge in (left + .08, right - .08):
        railing(ramp, (edge, h, za), (edge, 0, zb), "blue_light")

cabin = Kit("deckhouse", LAYOUT["deckhouse"])
kits.append(cabin)
cabin.box("Wheelhouse", (0, 1.3, 0), (5.8, 2.6, 5.2), "cream")
cabin.box("Green trim", (0, .38, 0), (5.86, .76, 5.26), "green")
cabin.box("Roof", (0, 2.72, 0), (6.28, .3, 5.7), "green_dark")
for side in (-1, 1):
    for offset in (-1.65, 0, 1.65):
        cabin.box("Window frame", (offset, 1.74, side * 2.621), (1.4, .93, .08), "metal")
        cabin.box("Warm window", (offset, 1.74, side * 2.669), (1.24, .75, .025), "lamp")
        cabin.box("Side window", (side * 2.918, 1.74, offset), (.08, .84, 1.17), "lamp")
cabin.rod("Funnel", (0, 2.85, .65), (0, 4.65, .65), .72, "green", 10, .58)
cabin.rod("Funnel rim", (0, 4.62, .65), (0, 4.8, .65), .61, "cream", 10)

mast = Kit("mast", LAYOUT["mast"])
kits.append(mast)
mast.rod("Mast", (0, 0, 0), (0, 12, 0), .34, "cream", 10, .13)
mast.rod("Foot", (0, 0, 0), (0, 1.5, 0), .46, "gold", 10)
mast.rod("Yardarm", (-3.5, 8.2, 0), (3.5, 8.2, 0), .14, "gold", 8, .1)
for side in (-1, 1):
    mast.rod("Stay", (0, 11.4, 0), (side * 6, 1, -8.4), .037, "metal", 5)
    mast.rod("Arm stay", (0, 11.4, 0), (side * 3.45, 8.22, 0), .038, "metal", 5)
    mast.box("Deck spotlight", (side * 2.95, 7.95, 0), (.52, .24, .38), "lamp")
for i, color in enumerate(("coral","cream","teal","gold","violet")):
    z = -2.0 - 1.05 * i
    y = 11.4 + z * 1.238
    x = -z * .714
    mast.mesh("Pennant", [(x,y,z),(x+.23,y-.97,z-.30),(x+.46,y-.8,z-.65)], [(0,1,2),(2,1,0)], color)

for name, color in (("crates_teal","teal"), ("crates_purple","violet"), ("locker","gold"), ("lifeboat","coral")):
    kit = Kit(name)
    kits.append(kit)
    if name == "lifeboat":
        skiff = [(-.6,2.25),(-.9,1.32),(-.9,-1.3),(-.55,-2.0),(0,-2.45),(.55,-2),(.9,-1.3),(.9,1.32),(.6,2.25)]
        kit.loft("Boat", skiff, [(.31, .65), (.91,1)], "coral")
        kit.loft("Canvas", skiff, [(.91,1),(1.07,.93)], "cream")
        for z in (-1.48,1.48):
            kit.box("Cradle", (0,.16,z), (1.3,.32,.36), "metal")
    else:
        dimensions = (2.75,1.34,2.08) if name.startswith("crates") else (1.65,1.95,1.35)
        w, height, d = dimensions
        kit.box("Shell", (0,height/2,0), dimensions, color)
        for side in (-1,1):
            kit.box("Corner straps", (side * w*.32,height/2,0), (.16,height+.06,d+.05), "cream")
        kit.box("Low plinth", (0,.08,0), (w+.08,.16,d+.08), "metal")
        kit.box("Latch", (0,height*.54,d*.51), (.36,.16,.06), "metal")

light = Kit("lighthouse", LAYOUT["lighthouse"])
kits.append(light)
light.rod("Breakwater", (0,-.55,0), (0,.2,0), 5.3, "shore", 8, 4.1)
light.rod("Tower base", (0,0,0), (0,3,0), 1.65, "cream", 10, 1.36)
light.rod("Red belt", (0,3,0), (0,5.5,0), 1.36, "coral", 10, 1.11)
light.rod("Tower top", (0,5.5,0), (0,10.5,0), 1.11, "cream", 10, .85)
light.rod("Gallery", (0,10.38,0), (0,10.78,0), 1.29, "green_dark", 12)
light.rod("Lens", (0,10.78,0), (0,12.05,0), .82, "moonlight", 10)
light.rod("Roof", (0,12.05,0), (0,13.05,0), 1.08, "coral", 10, .12)

pier = Kit("pier", LAYOUT["pier"])
kits.append(pier)
pier.box("Quay", (0,.31,0), (33,1.5,13), "shore")
pier.box("Terminal", (0,2.6,-.75), (16.5,4.4,6.2), "shore_light")
pier.box("Terminal roof", (0,4.94,-.75), (18.1,.33,7), "green_dark")
for i in range(8):
    pier.box("Terminal windows", ((i-3.5)*1.87,2.7,2.385), (1.47,1.38,.12), "lamp")
for x in (-14,-9,9,14):
    pier.rod("Harbor lamp", (x,.9,4.6),(x,4.05,4.6),.12,"metal")
    pier.box("Harbor light", (x,4.03,4.6),(.55,.25,.43),"moonlight")
for i, height in enumerate((9,13,17,9,15,11,21,15,8,17,12)):
    x = (i-5)*6.3
    z = -11 - (i % 3)*4.7
    pier.box("Harbor silhouette", (x,height/2,z), (4.8,height,5), "shore")
    for level in range(3, height-1, 3):
        for column in (-1.25, 1.25):
            if (i + level + int(column)) % 3:
                pier.box("Distant light", (x+column,level,z+2.52), (.67,.54,.09), "lamp")

for kit in kits:
    kit.export()

bpy.context.scene.name = "Ferry Asset Library"
preview = bpy.data.scenes.new("Last Ferry Layout")
for kit in kits:
    positions = [item["at"] for item in LAYOUT["props"] if item["asset"] == kit.name] or [kit.location]
    for pos in positions:
        obj = bpy.data.objects.new(kit.name, None)
        obj.instance_type = "COLLECTION"
        obj.instance_collection = kit.collection
        obj.location = xyz(pos)
        preview.collection.objects.link(obj)
camera_data = bpy.data.cameras.new("Ferry overview")
camera_data.type = "ORTHO"
camera_data.ortho_scale = 79
camera = bpy.data.objects.new("Ferry overview", camera_data)
camera.location = xyz((36, 62, 39))
camera.rotation_euler = (Vector(xyz((0,0,-4))) - camera.location).to_track_quat("-Z","Y").to_euler()
preview.collection.objects.link(camera)
preview.camera = camera
bpy.context.window.scene = preview
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "art_source/last_ferry.blend"), compress=True)
print("FERRY_ASSETS_READY", len(kits))
