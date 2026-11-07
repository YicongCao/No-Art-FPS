"""Build editable park collections and matching GLBs with Blender Python.

blender --background --python tools/build_amusement_park.py
Geometry and the layout manifest use Godot coordinates in metres.
"""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/models/park"
OUTPUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

PALETTE = {
    "sand": "E9BD79", "cream": "F4DFB3", "edge": "FFF0CD", "brick": "BB5948",
    "blue": "3154BB", "blue_light": "527CE3", "deep_blue": "253B7D",
    "gold": "F0BC44", "gold_light": "FFD976", "teal": "427E76", "teal_dark": "315D59",
    "purple": "704B87", "ink": "263547", "white": "F5E7CC",
    "leaf": "507C57", "leaf_light": "76A05D", "wood": "AE7047",
    "steel": "ADB1A7", "grout": "D8C097",
}
MATERIALS = {}
for key, rgb in PALETTE.items():
    color = tuple(int(rgb[i:i+2], 16)/255 for i in (0, 2, 4))
    linear = tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in color)
    material = bpy.data.materials.new(key)
    material.diffuse_color = (*linear, 1)
    material.use_nodes = True
    surface = material.node_tree.nodes.get("Principled BSDF")
    surface.inputs["Base Color"].default_value = (*linear, 1)
    surface.inputs["Roughness"].default_value = .86
    MATERIALS[key] = material


def xyz(point):
    x, y, z = point
    return x, -z, y


class Asset:
    def __init__(self, name, group):
        self.name = name
        self.parts = []
        self.collection = bpy.data.collections.new(name)
        if group not in bpy.data.collections:
            bpy.context.scene.collection.children.link(bpy.data.collections.new(group))
        bpy.data.collections[group].children.link(self.collection)

    def part(self, name, vertices, faces, color):
        vertices = [tuple(v) for v in vertices]
        self.parts.append((vertices, faces, color))
        data = bpy.data.meshes.new(name)
        data.from_pydata([xyz(v) for v in vertices], [], faces)
        data.update()
        data.materials.append(MATERIALS[color])
        obj = bpy.data.objects.new(name, data)
        self.collection.objects.link(obj)

    def box(self, name, point, size, color, axes=None):
        axes = axes or (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))
        vertices = [
            Vector(point)+sum((axis*sign*extent/2 for axis, sign, extent in zip(axes, corner, size)), Vector())
            for corner in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                           (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]
        ]
        self.part(name, vertices, [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], color)

    def rod(self, name, a, b, radius, color, sides=8, radius_end=None):
        start, end = Vector(a), Vector(b)
        axis = (end-start).normalized()
        side = axis.cross(Vector((0, 1, 0)))
        if side.length_squared<.01:
            side = axis.cross(Vector((1, 0, 0)))
        side.normalize()
        other = axis.cross(side)
        vertices = []
        for center, r in ((start, radius),(end, radius_end if radius_end is not None else radius)):
            vertices.extend(center+r*(math.cos(i*math.tau/sides)*side+math.sin(i*math.tau/sides)*other)
                            for i in range(sides))
        faces = [tuple(reversed(range(sides))), tuple(range(sides, 2*sides))]
        faces.extend((i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides))
        self.part(name, vertices, faces, color)

    def ellipsoid(self, name, at, size, color):
        vertices = [Vector(at)+Vector((0,-size[1]/2,0))]
        sides = 10
        for j in range(1, 6):
            angle = math.pi*j/6
            for i in range(sides):
                theta = math.tau*i/sides
                vertices.append(Vector(at)+Vector((size[0]/2*math.sin(angle)*math.cos(theta),
                                                   -size[1]/2*math.cos(angle),
                                                   size[2]/2*math.sin(angle)*math.sin(theta))))
        vertices.append(Vector(at)+Vector((0,size[1]/2,0)))
        faces = []
        for i in range(sides):
            a, b = i+1, (i+1)%sides+1
            faces.append((0,a,b))
            for j in range(4):
                k = j*sides
                faces.append((a+k,a+k+sides,b+k+sides,b+k))
            faces.append((a+4*sides,len(vertices)-1,b+4*sides))
        self.part(name, vertices, faces, color)

    def export(self):
        vertices, faces, colors = [], [], []
        for verts, polygons, color in self.parts:
            faces.extend(tuple(len(vertices)+i for i in face) for face in polygons)
            vertices.extend(xyz(v) for v in verts)
            colors.extend([color]*len(polygons))
        data = bpy.data.meshes.new(self.name)
        data.from_pydata(vertices, [], faces)
        data.update()
        used = list(dict.fromkeys(colors))
        for key in used:
            data.materials.append(MATERIALS[key])
        for face, color in zip(data.polygons, colors):
            face.material_index = used.index(color)
        obj = bpy.data.objects.new(self.name, data)
        bpy.context.scene.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.export_scene.gltf(filepath=str(OUTPUT/f"{self.name}.glb"), export_format="GLB",
                                  use_selection=True, export_yup=True)
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(data)


def smooth_loop(points, step):
    points = [Vector(p) for p in points]
    samples = []
    for i, b in enumerate(points):
        a, c, d = points[i-1], points[(i+1)%len(points)], points[(i+2)%len(points)]
        for j in range(max(2, math.ceil((c-b).length/step))):
            t = j/max(2, math.ceil((c-b).length/step))
            samples.append(.5*(2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    return samples


def strip(asset, name, samples, width, color):
    vertices = []
    for i, point in enumerate(samples):
        tangent = samples[(i+1)%len(samples)]-samples[i-1]
        side = Vector((tangent.z,0,-tangent.x)).normalized()*width/2
        vertices.extend((point-side, point+side))
    faces = [(2*i,2*j,2*j+1,2*i+1) for i in range(len(samples)) for j in [(i+1)%len(samples)]]
    if (vertices[faces[0][1]]-vertices[faces[0][0]]).cross(vertices[faces[0][2]]-vertices[faces[0][0]]).y<0:
        faces = [tuple(reversed(face)) for face in faces]
    asset.part(name, vertices, faces, color)


layout = {"instances": [], "colliders": [], "surfaces": [], "props": []}


def place(name, asset, at=(0, 0, 0), yaw=0, size=None, group=None, shoot=True):
    item = {"name": name, "asset": asset, "at": at, "yaw": yaw}
    if size:
        item["size"] = size
    if group:
        item["group"] = group
        item["shoot"] = shoot
    layout["instances"].append(item)


def collider(at, size, group=None, yaw=0, layer=1):
    layout["colliders"].append({"at":at, "size":size, "group":group or "", "yaw":yaw, "layer":layer})


def surface(vertices, faces, group=""):
    triangles = []
    for face in faces:
        for i in range(1, len(face)-1):
            triangles.extend(tuple(vertices[j]) for j in (face[0], face[i], face[i+1]))
    layout["surfaces"].append({"triangles":triangles,"group":group})


# Grounds. The skate footprint has its own continuous sloped collision surface.
ground = Asset("grounds", "01 Grounds")
for x, z, w, d in ((0,-17,68,18),(0,18,68,16),(-31.5,1,5,18),(12.5,1,43,18)):
    ground.box("Ground slab", (x,-.2,z), (w,.4,d), "sand")
    collider((x,-.2,z),(w,.4,d))
ground.box("Exterior", (0,-1.8,0), (144,.3,124), "sand")
walk = smooth_loop([(0,.018,19),(-21,.018,16),(-31,.018,7),(-31,.018,-10),
                    (-22,.018,-14),(-8,.018,-11),(7,.018,-11),(19,.018,-15),
                    (30,.018,-11),(31,.018,7),(22,.018,17)], .65)
strip(ground, "Terracotta curb", walk, 4.45, "brick")
strip(ground, "Promenade", [p+Vector((0,.009,0)) for p in walk], 4.02, "cream")
for i in range(0, len(walk), 4):
    p = walk[i]
    forward = (walk[(i+1)%len(walk)]-walk[i-1]).normalized()
    right = Vector((forward.z,0,-forward.x))
    ground.box("Paving seam", p+Vector((0,.013,0)), (3.96,.004,.025), "grout",
               (right,Vector((0,1,0)),forward))
ring = [Vector((8.0*math.cos(i*math.tau/80),.039,1+8.0*math.sin(i*math.tau/80))) for i in range(80)]
strip(ground, "Plaza ring edge", ring, 4.6, "brick")
strip(ground, "Plaza ring paving", [p+Vector((0,.009,0)) for p in ring], 4.15, "cream")
ground.box("Entrance walk edge", (0,.036,17.5), (5.8,.018,17), "brick")
ground.box("Entrance walk", (0,.05,17.5), (5.4,.015,17), "cream")
for x, length in ((-9,6),(15,15)):
    ground.box("Cross walk edge", (x,.048,1), (length,.018,4.4), "brick")
    ground.box("Cross walk", (x,.063,1), (length,.015,4.0), "cream")
ground.export()
place("Grounds","grounds")

gate = Asset("entry", "02 Entrance")
for x in (-5,5):
    gate.box("Ticket booth", (x,1.35,0), (2.3,2.7,2.5), "teal")
    gate.box("Inset booth window", (x,1.65,.01+1.25), (1.62,1.18,.075), "teal_dark")
    gate.box("Booth sill", (x,1.03,1.29), (1.76,.12,.29), "edge")
    gate.box("Booth cap", (x,2.79,0), (2.75,.24,2.89), "blue")
    gate.box("Gold fascia", (x,2.66,1.45), (2.75,.19,.06), "gold")
    collider((x,1.35,24),(2.3,2.7,2.5),"Entry")
for x in (-3.38,3.38):
    gate.box("Gate pier", (x,1.8,0), (.42,3.6,.46), "gold")
    gate.box("Pier foot", (x,.14,0), (.62,.28,.65), "cream")
    collider((x,1.8,24),(.42,3.6,.46),"Entry")
gate.box("Gate roof", (0,3.66,0), (8.3,.38,2.8), "blue")
gate.box("Cream marquee", (0,3.65,1.43), (7.5,.56,.17), "edge")
for x, sign in ((-3.42,1),(3.42,-1)):
    gate.rod("Flag mast",(x,3.85,0),(x,5.1,0),.065,"blue",6)
    gate.box("Pennant",(x+.30*sign,4.88,0),(.60,.36,.065),"brick")
for i in range(16):
    x = (i-7.5)*.475
    gate.part("Striped canopy",[(x-.2375,3.42,1.32),(x+.2375,3.42,1.32),
                               (x+.2375,2.99,2.85),(x-.2375,2.99,2.85)],[(3,2,1,0)],"brick" if i%2==0 else "white")
    gate.box("Canopy valance", (x,2.9,2.85), (.475,.18,.13), "brick" if i%2==0 else "white")
gate.export()
place("Entrance","entry",(0,0,24),group="Entry",shoot=False)
collider((0,3.62,24),(8.4,.68,3.0),"Entry",layer=16)

# Kidney bowl, flat apron and two open banks. Exact surface drives collision.
skate = Asset("skate", "03 Skatepark")
vertices = []
sides = 64
for level in range(6):
    for i in range(sides):
        a = i*math.tau/sides
        cx, sz = math.cos(a), math.sin(a)
        rim = Vector((6.0*cx,.43,3.9*sz+.48*math.cos(2*a)))
        if level==0:
            distance = min(10/max(abs(cx),.0001),9/max(abs(sz),.0001))
            vertices.append((distance*cx,.43,distance*sz))
        else:
            t = (level-1)/4
            inset = .59 if abs(sz)>.58 else .48
            vertices.append((rim.x*(1-inset*t),.43-1.28*t,rim.z*(1-inset*t)))
for level in range(5):
    faces = [(level*sides+i, (level+1)*sides+i, (level+1)*sides+(i+1)%sides, level*sides+(i+1)%sides)
             for i in range(sides)]
    skate.part("Apron" if level==0 else "Bowl panels",vertices,faces,"cream" if level==0 else ("blue_light" if level==1 else "blue"))
    surface([(x-19,y,z+1) for x,y,z in vertices], faces)
floor = [tuple(reversed(range(5*sides,6*sides)))]
skate.part("Bowl floor", vertices, floor, "deep_blue")
surface([(x-19,y,z+1) for x,y,z in vertices], floor)
for a in range(sides):
    b=(a+1)%sides
    p=vertices[a];q=vertices[b]
    skate.part("Raised edge",[p,q,(q[0],0,q[2]),(p[0],0,p[2])],[(0,1,2,3)],"brick")
for side in (-1,1):
    z=8.99*side
    ramp=[(-2.0,.43,z),(2.0,.43,z),(2.0,0,z+side*2.2),(-2.0,0,z+side*2.2)]
    face=[(3,2,1,0) if side==1 else (0,1,2,3)]
    skate.part("Walk-in ramp",ramp,face,"gold")
    surface([(x-19,y,z+1) for x,y,z in ramp],face)
side_entry=[(10,.43,-2.75),(10,.43,2.75),(12.2,0,2.75),(12.2,0,-2.75)]
skate.part("Plaza access ramp",side_entry,[(0,1,2,3)],"cream")
surface([(x-19,y,z+1) for x,y,z in side_entry],[(0,1,2,3)])
for a,b in [((-9.85,-8.95),(-2,-8.95)),((2,-8.95),(9.85,-8.95)),
            ((-9.85,8.95),(-2,8.95)),((2,8.95),(9.85,8.95)),
            ((-9.85,-8.95),(-9.85,8.95)),((9.85,-8.95),(9.85,-2.75)),((9.85,2.75),(9.85,8.95))]:
    start,end=Vector((a[0],.43,a[1])),Vector((b[0],.43,b[1]))
    for y in (.4,.9):
        skate.rod("Apron rail",start+Vector((0,y,0)),end+Vector((0,y,0)),.045,"purple",6)
    count=math.ceil((end-start).length/2.6)
    for i in range(count+1):
        p=start.lerp(end,i/count)
        skate.rod("Apron post",p,p+Vector((0,.92,0)),.05,"purple",6)
skate.export()
place("SkateApron","skate",(-19,0,1))
collider((-28.9,.61,1),(.22,1.22,18))
for z in (-4.875,6.875):
    collider((-9.1,.61,z),(.22,1.22,6.25))
for z in (-7.95,9.95):
    for x in (-25,-13):
        collider((x,.61,z),(8,1.22,.22))

quarter = Asset("quarter_pipe", "03 Skatepark")
curve = [(2.0*(1-math.cos(i*math.pi/16)),.43+2.15*(1-math.sin(i*math.pi/16))) for i in range(9)]
curve = [(0,2.58)]+curve[1:]
verts = [(x,y,z) for z,y in curve for x in (-2.55,2.55)]
quarter.part("Riding surface",verts,[(2*i,2*i+2,2*i+3,2*i+1) for i in range(8)],"gold")
for side in (-1,1):
    x=side*2.55
    v=[(x,y,z) for z,y in curve]+[(x,.43,0)]
    quarter.part("Side panels",v,[tuple(range(len(v))) if side==1 else tuple(reversed(range(len(v))))],"blue")
quarter.box("Deck",(0,2.49,-.46),(5.12,.18,.94),"blue")
quarter.rod("Coping",(-2.6,2.58,0),(2.6,2.58,0),.065,"edge")
for x in (-2.35,0,2.35):
    quarter.rod("Guard post",(x,2.55,-.85),(x,3.36,-.85),.052,"purple")
quarter.rod("Guard rail",(-2.35,3.36,-.85),(2.35,3.36,-.85),.06,"purple")
quarter.export()
for x,z,yaw in ((-25,-4.5,0),(-13,-4.5,0)):
    group=f"Quarter{x}"
    place(group,"quarter_pipe",(x,0,z),yaw,group=group)
    collider((x,1.38,z-.45),(5.1,1.9,.95),group)
    surface([(x+vx,vy,z+vz) for vx,vy,vz in verts],[(2*i,2*i+2,2*i+3,2*i+1) for i in range(8)],group)
bank = Asset("skate_bank", "03 Skatepark")
v=[(-2,.43,1.6),(2,.43,1.6),(-2,1.15,-1.6),(2,1.15,-1.6)]
bank.part("Bank surface",v,[(0,1,3,2)],"gold")
bank.part("Blue sides",v+[(-2,.43,-1.6),(2,.43,-1.6)],[(0,2,4),(1,5,3),(2,3,5,4)],"blue")
bank.export()
place("SkateBank","skate_bank",(-13,0,7),group="SkateBank")
surface([(x-13,y,z+7) for x,y,z in v],[(0,1,3,2)],"SkateBank")
grind=Asset("grind_rail","03 Skatepark")
grind.box("Grind base",(0,.12,0),(3.5,.24,.9),"blue")
grind.box("Grind pad",(0,.3,0),(3.55,.13,.96),"gold")
for x in (-1.4,1.4):
    grind.rod("Grind leg",(x,.32,0),(x,.88,0),.063,"purple")
grind.rod("Grind bar",(-1.7,.88,0),(1.7,.88,0),.063,"purple")
grind.export()
place("GrindRail","grind_rail",(-22,.43,7),group="GrindRail")
collider((-22,.59,7),(3.5,.32,.9),"GrindRail")

# Carousel parts are exported independently so animation only moves the deck.
roof = Asset("carousel_roof", "04 Carousel")
roof.rod("Central spindle",(0,.1,0),(0,5.05,0),.38,"purple",12)
roof.rod("Spindle skirt",(0,.1,0),(0,.72,0),.9,"gold",24)
for i in range(16):
    a,b=i*math.tau/16,(i+1)*math.tau/16
    p=lambda r,h,t:(r*math.cos(t),h,r*math.sin(t))
    roof.part("Canopy wedge",[p(.28,5.46,a),p(4.35,3.69,a),p(4.35,3.69,b),p(.28,5.46,b)],
              [(3,2,1,0)],"brick" if i%2==0 else "white")
    roof.part("Scalloped fascia",[p(4.34,3.77,a),p(4.34,3.77,b),p(4.34,3.19,b),
                                  p(4.34,3.03,(a+b)/2),p(4.34,3.19,a)],[(0,1,2,3,4)],"gold")
    roof.part("Blue inset",[p(4.36,3.65,a+.025),p(4.36,3.65,b-.025),
                            p(4.36,3.32,b-.025),p(4.36,3.15,(a+b)/2),p(4.36,3.32,a+.025)],[(0,1,2,3,4)],"blue")
    roof.ellipsoid("Fascia bulb",p(4.42,3.46,(a+b)/2),(.22,.22,.22),"gold_light")
roof.ellipsoid("Finial",(0,5.67,0),(.62,.68,.62),"gold_light")
for i in range(24):
    a,b=i*math.tau/24,(i+1)*math.tau/24
    for y in (.43,.89):
        roof.rod("Plaza fence rail",p(4.43,y,a),p(4.43,y,b),.047,"purple",6)
    roof.rod("Plaza fence post",p(4.43,.06,a),p(4.43,.96,a),.065,"purple",6)
roof.export()
place("CarouselCanopy","carousel_roof",(0,0,1),group="Carousel",shoot=False)
collider((0,1.55,1),(.85,3.1,.85),"Carousel")
collider((0,4.02,1),(8.35,1.25,8.35),"Carousel",layer=16)

deck=Asset("carousel_deck","04 Carousel")
deck.rod("Turntable",(0,.07,0),(0,.41,0),4.18,"purple",48)
deck.rod("Brass deck edge",(0,.29,0),(0,.42,0),4.24,"gold",48)
deck.rod("Floor",(0,.41,0),(0,.46,0),4.10,"gold_light",48)
deck.export()
for accent in ("blue","brick"):
    horse=Asset("horse_"+accent,"04 Carousel")
    horse.ellipsoid("Body",(0,1.2,0),(.59,.67,1.35),"white")
    horse.rod("Raised neck",(0,1.24,-.34),(0,1.99,-.68),.235,"white",9,.173)
    horse.ellipsoid("Head",(0,1.99,-.77),(.37,.38,.58),"white")
    horse.ellipsoid("Muzzle",(0,1.88,-1.03),(.32,.25,.34),"cream")
    for side in (-1,1):
        horse.rod("Ear",(side*.12,2.11,-.72),(side*.14,2.35,-.73),.07,"white",5,.021)
        horse.ellipsoid("Eye",(side*.177,2.025,-.86),(.047,.071,.077),"ink")
        for z, shift in ((-.4,-.38),(.43,.30)):
            x=side*.20
            horse.rod("Upper leg",(x,1.09,z),(x,.78,z+shift*.65),.10,"white",7,.075)
            horse.rod("Lower leg",(x,.78,z+shift*.65),(x,.52,z+shift),.074,"white",7,.063)
            horse.ellipsoid("Hoof",(x,.49,z+shift),(.19,.16,.24),"ink")
    horse.rod("Mane",(0,1.44,-.18),(0,2.10,-.58),.15,accent,7,.115)
    horse.rod("Tail",(0,1.33,.56),(0,.88,1.02),.132,accent,7,.052)
    horse.ellipsoid("Saddle",(0,1.51,.08),(.65,.26,.65),accent)
    horse.rod("Brass pole",(0,.38,0),(0,3.32,0),.047,"gold_light")
    horse.export()

# Shared path samples build the swept rails, and the runtime Path3D.
track = smooth_loop([(22,2.2,6),(22,2.2,1),(22,2.2,-4),(23,4.8,-10),
                     (24,8.3,-16),(20,10.4,-21),(13,8.6,-22),(7,4.8,-22),
                     (-2,6.7,-22),(-11,4.45,-22),(-23,4.6,-21),(-29,4.2,-16),
                     (-24,3.55,-11),(-13,3.65,-10),(-2,4.4,-9),(10,3.55,-9),
                     (16,2.95,-6),(16,2.35,1),(17,2.2,6),(19.5,2.2,8.5)], .45)
track_asset=Asset("coaster_track","05 Roller coaster")
sides=8
for rail_side in (-1,1):
    vertices=[]
    for i, point in enumerate(track):
        tangent=(track[(i+1)%len(track)]-track[i-1]).normalized()
        side=Vector((tangent.z,0,-tangent.x)).normalized()
        up=tangent.cross(side).normalized()
        center=point+side*.63*rail_side
        vertices.extend(center+.105*(math.cos(j*math.tau/sides)*side+math.sin(j*math.tau/sides)*up) for j in range(sides))
    faces=[(i*sides+j, i*sides+(j+1)%sides, k*sides+(j+1)%sides, k*sides+j)
           for i in range(len(track)) for k in [(i+1)%len(track)] for j in range(sides)]
    track_asset.part("Swept rail",vertices,faces,"blue")
for i, p in enumerate(track):
    tangent=(track[(i+1)%len(track)]-track[i-1]).normalized()
    side=Vector((tangent.z,0,-tangent.x)).normalized()
    up=tangent.cross(side).normalized()
    if i%2==0:
        track_asset.box("Crosstie",p-up*.12,(1.6,.13,.16),"deep_blue",(side,up,tangent))
    if i%4==0:
        collider(tuple(p),(1.55,.36,2.0),"Coaster",math.atan2(tangent.x,tangent.z),16)
    if i%11==0 and p.y>3.15:
        for sign in (-1,1):
            foot=p+side*sign*1.44
            foot.y=.12
            track_asset.box("Pier footing",(foot.x,.13,foot.z),(.62,.26,.62),"cream")
            track_asset.rod("A frame leg",foot,p+side*sign*.36-up*.16,.205,"gold",6,.13)
            collider((foot.x,.6,foot.z),(.53,1.2,.53),"Coaster")
        track_asset.rod("Cross beam",p-side*.9-up*.22,p+side*.9-up*.22,.09,"gold",6)
track_asset.export()
place("CoasterTrack","coaster_track",group="Coaster",shoot=False)
layout["track"]=[tuple(round(v,4) for v in p) for p in track]

car=Asset("coaster_car","05 Roller coaster")
car.box("Chassis",(0,.23,0),(1.37,.33,1.63),"deep_blue")
car.box("Nose",(0,.49,-.68),(1.42,.54,.36),"gold")
car.box("Tail",(0,.53,.65),(1.42,.60,.23),"gold")
for x in (-.64,.64):
    car.box("Side shell",(x,.45,0),(.20,.49,1.65),"gold")
    car.box("Side stripe",(x,.35,0),(.215,.085,1.58),"blue")
    for z in (-.53,.53):
        car.rod("Guide wheel",(x-.12,.13,z),(x+.12,.13,z),.15,"ink")
for x in (-.29,.29):
    car.box("Seat base",(x,.47,.04),(.49,.19,.67),"purple")
    car.box("Seat back",(x,.77,.3),(.49,.53,.18),"purple")
car.rod("Restraint",(-.58,.83,-.18),(.58,.83,-.18),.048,"steel")
car.export()

platform=Asset("station_foundation","06 Station")
platform.box("Platform floor",(25.6,1.97,1),(5.3,.46,10),"purple")
platform.box("Platform top",(25.6,2.202,1),(5.25,.016,9.96),"cream")
platform.box("Gold fascia",(22.95,2.01,1),(.13,.35,10),"gold")
collider((25.6,1.97,1),(5.3,.46,10))
for z0,sign in ((6,1),(-4,-1)):
    ramp=[(24.08,2.2,z0),(27.12,2.2,z0),(27.12,0,z0+sign*7.8),(24.08,0,z0+sign*7.8)]
    surface(ramp,[(3,2,1,0) if sign==1 else (0,1,2,3)])
    for i in range(14):
        step_height=2.2*(1-i/14)
        platform.box("Visible stair",(25.6,step_height-.08,z0+sign*(i+.5)*7.8/14),(3.04,.16,7.8/14),"gold" if i%2==0 else "gold_light")
    for x in (24.03,27.17):
        platform.rod("Ramp rail",(x,3.23,z0),(x,1.03,z0+sign*7.8),.054,"purple")
        for i in range(5):
            t=i/4
            platform.rod("Ramp post",(x,2.2*(1-t),z0+sign*t*7.8),(x,2.2*(1-t)+1.03,z0+sign*t*7.8),.05,"purple")
        collider((x,1.65,z0+sign*3.9),(.12,3.3,7.8))
platform.export()
place("StationFoundation","station_foundation")

station=Asset("station_roof","06 Station")
for x in (22.8,28.16):
    for z in (-3.4,5.4):
        station.box("Roof support",(x,3.6,z),(.22,2.8,.22),"purple")
        collider((x,3.6,z),(.22,2.8,.22),"Station")
for x in (23.03,28.22):
    for y in (2.66,3.19):
        station.rod("Platform rail",(x,y,-3.9),(x,y,5.9),.049,"purple",6)
    for z in (-3.9,-1.45,1,3.45,5.9):
        station.rod("Platform post",(x,2.2,z),(x,3.2,z),.047,"purple",6)
    collider((x,2.7,1),(.13,1.0,9.8),"Station")
for x in (18.7,20.2,21.7):
    for z in (1.8,3.7,5.6):
        station.rod("Queue post",(x,0,z),(x,.92,z),.048,"purple",6)
    station.rod("Queue rail",(x,.86,1.8),(x,.86,5.6),.045,"purple",6)
    collider((x,.45,3.7),(.11,.9,3.8),"Station")
station.part("Blue canopy",[(22.13,5.32,-4.25),(28.8,4.91,-4.25),
                            (28.8,4.91,6.25),(22.13,5.32,6.25)],[(3,2,1,0)],"blue")
station.box("Roof fascia",(28.8,4.81,1),(.21,.22,10.5),"deep_blue")
station.export()
place("StationCanopy","station_roof",group="Station",shoot=False)
collider((25.5,5.02,1),(6.5,.35,10.5),"Station",layer=16)

kiosk=Asset("kiosk","07 Park props")
kiosk.box("Kiosk body",(0,1.05,0),(2.35,2.1,1.95),"teal")
kiosk.box("Open window",(0,1.47,.99),(1.82,.79,.07),"teal_dark")
kiosk.box("Counter",(0,1.03,1.05),(1.98,.14,.4),"cream")
kiosk.box("Roof",(0,2.26,0),(2.65,.27,2.23),"edge")
for i in range(10):
    x=(i-4.5)*.256
    kiosk.part("Awning stripe",[(x-.128,2.17,1.03),(x+.128,2.17,1.03),(x+.128,1.87,1.66),(x-.128,1.87,1.66)],
               [(3,2,1,0)],"gold" if i%2==0 else "white")
    kiosk.box("Scallop",(x,1.79,1.65),(.256,.18,.12),"gold" if i%2==0 else "white")
kiosk.export()
for i,(x,z,yaw) in enumerate([(-15,15,.1),(14,15,-.1),(-13,-13,0),(15,-12,.3),(-28,12,1.1),(30,13,-.8)]):
    name=f"Kiosk{i}"
    place(name,"kiosk",(x,0,z),yaw,group=name)
    collider((x,1.05,z),(2.35,2.1,1.95),name,yaw)

bench=Asset("bench","07 Park props")
for x in (-.81,.81):
    bench.box("Bench legs",(x,.26,0),(.15,.51,.62),"blue")
    bench.box("Back support",(x,.65,-.28),(.13,.67,.13),"blue")
for z in (-.19,0,.19):
    bench.box("Seat slat",(0,.53,z),(2.12,.13,.155),"gold")
for y in (.78,.96):
    bench.box("Back slat",(0,y,-.29),(2.12,.125,.15),"gold")
bench.export()
planter=Asset("planter","07 Park props")
planter.box("Pot",(0,.22,0),(2.0,.44,1.0),"brick")
planter.box("Pot rim",(0,.44,0),(2.08,.14,1.08),"cream")
for i in range(5):
    x=(i-2)*.34
    planter.ellipsoid("Hedge",(x,.68+.05*(i%3),.07*(i%2)),(.61,.55,.75),"leaf" if i%2 else "leaf_light")
planter.export()
lamp=Asset("lamp","07 Park props")
lamp.box("Lamp foot",(0,.1,0),(.31,.2,.31),"cream")
lamp.rod("Post",(0,.1,0),(0,3.45,0),.066,"blue",6)
lamp.box("Light housing",(.20,3.48,0),(.57,.16,.30),"blue")
lamp.box("Lens",(.2,3.39,0),(.43,.045,.24),"edge")
lamp.export()
for i,(x,z) in enumerate([(-10,13),(-6,10),(6,10),(10,13),(-10,-4),(-6,-8),(6,-8),(10,-4),(-28,12),(29,15),(-25,-13),(26,-13)]):
    place(f"Bench{i}","bench",(x,0,z),group=f"Bench{i}")
    place(f"Planter{i}","planter",(x+1.65,0,z+.47),group=f"Planter{i}")
    place(f"Lamp{i}","lamp",(x-1.65,0,z+.58),group=f"Lamp{i}")
    collider((x,.27,z),(2.1,.54,.61),f"Bench{i}")
    collider((x+1.65,.27,z+.47),(2.0,.54,1.0),f"Planter{i}")
for i,(x,z) in enumerate([(-29,18),(-20,19),(19,19),(31,19),(-32,-11),(-22,-22),(0,-24),(15,-24),(30,-20),(-9,-13),(10,-12)]):
    name=f"Palm{i}"
    place(name,"../palm",(x,0,z),i*.67,group=name,shoot=False)
    collider((x,1.72,z),(.45,3.44,.45),name)
    collider((x,4.05,z),(4.5,1.12,4.5),name,layer=16)

def fence_asset(name,a,b):
    asset=Asset(name,"08 Fences")
    start,end=Vector(a),Vector(b)
    tangent=(end-start).normalized()
    normal=Vector((-tangent.z,0,tangent.x))
    length=(end-start).length
    count=math.ceil(length/3.0)
    step=length/count
    for i in range(count+1):
        p=start+tangent*(i*step)
        asset.box("Brick plinth",p+Vector((0,.15,0)),(.32,.3,.32),"brick")
        asset.rod("Steel post",p+Vector((0,.22,0)),p+Vector((0,1.76,0)),.077,"blue",6)
    for i in range(count):
        p=start+tangent*(i*step)
        q=p+tangent*step
        for y in (.33,1.54):
            asset.rod("Frame",p+Vector((0,y,0)),q+Vector((0,y,0)),.041,"blue",6)
        for sign in (-1,1):
            for j in range(-4,math.ceil(step/.26)):
                x=j*.26
                lo=max(0,-x/1.1); hi=min(1,(step-x)/1.1)
                if hi<=lo: continue
                def endpoint(t):
                    return p+tangent*(x+1.1*t)+Vector((0,.37+1.14*(t if sign==1 else 1-t),0))
                asset.rod("Diamond mesh",endpoint(lo),endpoint(hi),.012,"ink",4)
    asset.export()
    place(name,name,group=name,shoot=False)
    # The solid park limit is independent of the visible fence panels.
    collider(tuple((start+end)/2+Vector((0,2,0))),(length,4,.16),yaw=-math.atan2(tangent.z,tangent.x))
    collider(tuple((start+end)/2+Vector((0,.89,0))),(length,1.8,.25),name,-math.atan2(tangent.z,tangent.x),16)

border=[(-6.25,0,25.5),(-29,0,25.5),(-33.5,0,21),(-33.5,0,-21),(-29,0,-25.5),
        (29,0,-25.5),(33.5,0,-21),(33.5,0,21),(29,0,25.5),(6.25,0,25.5)]
for i in range(len(border)-1):
    fence_asset(f"fence_{i}",border[i],border[i+1])
collider((0,2,26),(12.5,4,.18))

layout["start"]=(0,.05,20.6)
layout["opening"]=[(-23,.43,4),(-15,.43,-1),(-8,0,7),(7,0,5),(19,0,-5),(26,2.2,4),(-17,0,12),(16,0,13)]
layout["spawns"]=[(-30,0,17),(-27,0,-11),(-18,.43,-5.8),(-12,0,12),(-8,0,-15),(-4,0,13),
                  (8,0,-16),(12,0,5),(20,0,17),(30,0,9),(29,0,-17),(26,2.2,-2.8)]
layout["respawns"]=[(0,0,21),(-27,0,15),(-29,0,-12),(-9,0,-16),(29,0,-14),(28,0,15)]
layout["barrels"]=[(-11,0,9),(7,0,8),(-7,0,-8),(13,0,-8),(21,0,9),(29,0,-6)]
layout["waypoints"]=[(0,0,20),(-19,0,15),(-19,.43,9.5),(-19,-.85,1),(-19,.43,-8),
                     (-31,0,5),(-22,0,-13),(-8,0,-11),(8,0,-11),(25.6,2.2,1),
                     (25.6,0,-12),(25.6,0,14),(22,0,17),(0,0,20)]
layout["crossings"]=[[(-12,.43,1),(-6,0,1)],[(6,0,1),(21,0,1)]]
(ROOT/"tools/maps/amusement_park_layout.json").write_text(json.dumps(layout,separators=(",",":"))+"\n")

bpy.context.scene.name = "Park Asset Library"
preview = bpy.data.scenes.new("Amusement Park Layout")

def preview_instance(name, asset, at, yaw=0):
    collection = bpy.data.collections.get(asset)
    if collection is None:return
    obj = bpy.data.objects.new(name,None)
    obj.instance_type = "COLLECTION"
    obj.instance_collection = collection
    obj.location = xyz(at)
    obj.rotation_euler.z = yaw
    preview.collection.objects.link(obj)

for item in layout["instances"]:
    preview_instance(item["name"],item["asset"],item["at"],item["yaw"])
preview_instance("Turntable","carousel_deck",(0,0,1))
for i in range(8):
    angle = i*math.tau/8
    preview_instance(f"Horse {i+1}","horse_blue" if i%2==0 else "horse_brick",
                     (3.0*math.cos(angle),0,1+3.0*math.sin(angle)),math.pi-angle)
for i in range(3):
    preview_instance(f"Car {i+1}","coaster_car",(22,2.2,3.7-i*1.78))
camera_data = bpy.data.cameras.new("Park overview")
camera_data.type = "ORTHO"
camera_data.ortho_scale = 78
camera = bpy.data.objects.new("Park overview",camera_data)
camera.location = xyz((0,55,33))
camera.rotation_euler = (Vector(xyz((0,0,-2)))-camera.location).to_track_quat("-Z","Y").to_euler()
preview.collection.objects.link(camera)
preview.camera = camera
bpy.context.window.scene = preview
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"art_source/amusement_park.blend"), compress=True)
print("PARK_ASSETS_READY",len(layout["instances"]),len(track),len(layout["colliders"]))
