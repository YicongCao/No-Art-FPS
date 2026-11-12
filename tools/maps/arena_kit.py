"""Editable Blender kits and matching Godot collision recipes."""
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from toy_kit import cambered_canopy, export_toy_parts, tapered_box, stepped_plinth, segmented_coping

ROOT = Path(__file__).resolve().parents[2]


def xyz(p):
    return p[0], -p[2], p[1]


class Kit:
    def __init__(self, name, materials, destination):
        self.name = name
        self.parts = []
        self.materials = materials
        self.destination = destination
        self.collection = bpy.data.collections.new(name)

    def mesh(self, label, points, faces, color):
        self.parts.append((label, points, faces, color))
        origin = sum((Vector(v) for v in points), Vector()) / len(points)
        mesh = bpy.data.meshes.new(label)
        mesh.from_pydata([xyz(Vector(v) - origin) for v in points], [], faces)
        mesh.materials.append(self.materials[color])
        obj = bpy.data.objects.new(label, mesh)
        obj.location = xyz(origin)
        self.collection.objects.link(obj)

    def box(self, label, center, size, color, angle=0, taper=0.0):
        if taper:
            tapered_box(self.mesh, label, center, size, color, angle=angle, taper=taper)
            return
        c, s = math.cos(angle), math.sin(angle)
        points = []
        for x, y, z in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                        (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)):
            x, y, z = x*size[0]/2, y*size[1]/2, z*size[2]/2
            points.append((center[0]+c*x+s*z,center[1]+y,center[2]-s*x+c*z))
        self.mesh(label, points, [(3,2,1,0),(4,5,6,7),(0,1,5,4),
                                  (1,2,6,5),(2,3,7,6),(3,0,4,7)], color)

    def plinth(self, label, center, width, height, depth, color, angle=0.0, flare=0.045):
        stepped_plinth(self.mesh, label, center, width, height, depth, color, angle=angle, flare=flare)

    def coping(self, label, center, width, height, depth, color, angle=0.0, seg_len=1.75):
        segmented_coping(self.mesh, label, center, width, height, depth, color, angle=angle, seg_len=seg_len)

    def canopy(self, origin, width, depth, drop, angle, stripe_a, stripe_b, wood_color, post_h=2.06, posts=True):
        cambered_canopy(self.mesh, origin, width, depth, drop, angle, stripe_a, stripe_b, wood_color,
                        post_h=post_h, posts=posts)

    def rod(self, label, start, finish, radius, color, sides=8, end_radius=None):
        start, finish = Vector(start), Vector(finish)
        axis = (finish-start).normalized()
        tangent = axis.cross(Vector((0, 1, 0)))
        if tangent.length < .01:
            tangent = axis.cross(Vector((1, 0, 0)))
        tangent.normalize()
        bitangent = axis.cross(tangent)
        points = [center + r*(math.cos(i*math.tau/sides)*tangent+math.sin(i*math.tau/sides)*bitangent)
                  for center, r in ((start, radius), (finish, end_radius or radius)) for i in range(sides)]
        faces = [tuple(reversed(range(sides))), tuple(range(sides,2*sides))]
        faces += [(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)]
        self.mesh(label, points, faces, color)

    def export(self):
        bl_parts = [(label, [xyz(p) for p in verts], polys, color)
                    for label, verts, polys, color in self.parts]
        export_toy_parts(
            self.name,
            bl_parts,
            self.materials,
            self.destination / f"{self.name}.glb",
            bevel=self.name not in ("lake", "landscape", "harbour_water", "ridge", "garden_ground"),
            max_bevel=0.028,
            skip_labels=(
                "Individual worn paving block", "Paved lane", "Path surface",
                "Glazed turquoise floor tile", "Service lane paint", "Arrivals guide line",
                "Door threshold hazard mark", "West service route stripe",
                "Apron runway", "Apron stand", "Apron safety",
                "Entrance yellow tactile tile", "Raised tactile stud", "Bus lane road marking",
                "Individual ceramic tile", "Turquoise ceramic tile",
                "Compacted snowcat rut", "Snowcat tread imprint", "Snow pushed up", "Service road tracks",
                "Tactile warning strip", "Bridge tactile guide", "Subdivided banner cloth",
            ),
        )


    def beam(self, label, start, end, width, height, color):
        start, end = Vector(start), Vector(end)
        axis = (end-start).normalized()
        side = axis.cross(Vector((0, 1, 0)))
        if side.length < .001:
            side = Vector((1, 0, 0))
        side = side.normalized()*width/2
        up = side.cross(axis).normalized()*height/2
        points = [p+s*side+t*up for p in (start,end) for s,t in ((-1,-1),(1,-1),(1,1),(-1,1))]
        self.mesh(label, points, [(0,1,2,3),(7,6,5,4),(4,5,1,0),(5,6,2,1),(6,7,3,2),(7,4,0,3)],color)

    def slab(self, label, quad, thickness, color):
        bottom = [(x,y-thickness,z) for x,y,z in quad]
        faces = [(0,1,2,3),(7,6,5,4)]+[(i,i+4,(i+1)%4+4,(i+1)%4) for i in range(4)]
        self.mesh(label, list(quad)+bottom, faces, color)

    def facet(self, label, points, color):
        face = tuple(range(len(points)))
        self.mesh(label, points, [face, face[::-1]], color)


class ArenaKit:
    def __init__(self, key, palette, environment):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.key = key
        self.directory = ROOT / "assets/models" / key
        self.directory.mkdir(parents=True, exist_ok=True)
        self.materials = {}
        self.kits = {}
        self.layout = {"environment": environment, "fixed": [], "boxes": [], "slabs": [],
                       "props": [], "signs": [], "spots": [], "belts": [], "moving": []}
        for name, value in palette.items():
            hex_color, roughness, emission = value if isinstance(value, tuple) else (value,.62,0)
            rgb = [int(hex_color[i:i+2],16)/255 for i in (0,2,4)]
            linear = (*[c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb],1)
            mat = bpy.data.materials.new(name)
            mat.diffuse_color = linear
            mat.use_nodes = True
            shader = mat.node_tree.nodes["Principled BSDF"]
            shader.inputs["Base Color"].default_value = linear
            shader.inputs["Roughness"].default_value = roughness
            shader.inputs["Emission Color"].default_value = linear
            shader.inputs["Emission Strength"].default_value = emission
            self.materials[name] = mat

    def kit(self, name, fixed=False):
        item = Kit(name,self.materials,self.directory)
        self.kits[name] = item
        if fixed:
            self.layout["fixed"].append(name)
            bpy.context.scene.collection.children.link(item.collection)
        return item

    def solid(self, kit, label, at, size, color, angle=0):
        kit.box(label,at,size,color,angle)
        self.layout["boxes"].append([at,size,angle])

    def slab(self, kit, label, quad, thickness, color):
        kit.slab(label,quad,thickness,color)
        self.layout["slabs"].append([quad,thickness])

    def slope(self, kit, label, x0, x1, z0, z1, y0, y1, thickness, color):
        self.slab(kit,label,[(x0,y1,z1),(x1,y1,z1),(x1,y0,z0),(x0,y0,z0)],thickness,color)

    def prop(self, asset, at, size, angle=0, *, name="", effect="", structural=False):
        label = name or f"{asset}_{len(self.layout['props']):02}"
        self.layout["props"].append({"asset":asset,"name":label,"at":at,"size":size,
                                     "angle":angle,"effect":effect,"structural":structural})
        self._preview(asset,label,at,angle)

    def moving(self, asset, at, angle=0):
        self.layout["moving"].append([asset,at,angle])
        self._preview(asset,asset,at,angle)

    def sign(self, label, asset, at, size, angle=0):
        self.layout["signs"].append([label,asset,at,size,angle])

    def spot(self, origin, target, color, energy, reach, angle, sweep=(0,0,0), shaft=False):
        self.layout["spots"].append([origin,target,color,energy,reach,angle,sweep,shaft])

    def _preview(self, asset, label, at, angle):
        obj = bpy.data.objects.new(label,None)
        obj.instance_type = "COLLECTION"
        obj.instance_collection = self.kits[asset].collection
        obj.empty_display_size = .22
        obj.location = xyz(at)
        obj.rotation_euler.z = angle
        bpy.context.scene.collection.objects.link(obj)

    def write(self):
        for kit in self.kits.values():
            kit.export()
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"art_source"/f"{self.key}.blend"),compress=True)
        path = ROOT/"tools/maps"/f"{self.key}_layout.json"
        path.write_text(json.dumps(self.layout,indent=2)+"\n")
