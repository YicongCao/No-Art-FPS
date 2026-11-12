"""Build editable park collections and matching GLBs with Blender Python.

blender --background --python tools/build_amusement_park.py
Geometry and the layout manifest use Godot coordinates in metres.
"""
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/maps"))
from toy_kit import (
    cambered_canopy,
    export_toy_parts,
    segmented_coping,
    stepped_plinth,
    tapered_box,
)

from hero_geometry import profile_shell, rounded_profile

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
    surface.inputs["Roughness"].default_value = .42 if key in ("gold", "blue", "brick", "teal", "purple") else .54
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
        self.parts.append((name, vertices, faces, color))
        data = bpy.data.meshes.new(name)
        data.from_pydata([xyz(v) for v in vertices], [], faces)
        data.update()
        data.materials.append(MATERIALS[color])
        obj = bpy.data.objects.new(name, data)
        self.collection.objects.link(obj)

    def box(self, name, point, size, color, axes=None, taper=0.0):
        if taper and axes is None:
            tapered_box(self.part, name, point, size, color, taper=taper)
            return
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
        bl_parts = [(label, [xyz(v) for v in verts], polygons, color)
                    for label, verts, polygons, color in self.parts]
        export_toy_parts(
            self.name,
            bl_parts,
            MATERIALS,
            OUTPUT / f"{self.name}.glb",
            bevel=(self.name != "coaster_track"),
            max_bevel=0.028,
            skip_labels=(
                "Hero curved canopy", "Hero continuous fascia", "Hero booth", "Hero cap", "Paving seam", "Promenade", "Terracotta curb", "Plaza ring",
                "Entrance walk", "Cross walk", "Diamond mesh", "Exterior",
                "Apron", "Bowl", "Walk-in ramp", "Plaza access ramp", "Raised edge",
                "Riding surface", "Side panels", "Bank surface", "Blue sides",
            ),
        )


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
    stepped_plinth(gate.part, "Booth plinth", (x,.15,0), 2.38, .30, 2.58, "brick", flare=.045)
    # Closed booth shell, with genuinely recessed windows on the park and
    # entrance sides. The center backplates preserve the solid collider meaning.
    outer=rounded_profile(2.28,2.52,.20,y=1.40)
    outer_end=rounded_profile(2.12,2.48,.19,y=1.40)
    inner=rounded_profile(1.56,1.14,.12,y=1.65)
    verts=[]
    loops=[(-1.24,outer_end),(-1.16,outer),(1.16,outer),(1.24,outer_end)]
    loops += [(1.25,inner),(.65,inner),(-1.25,inner),(-.65,inner)]
    for depth,loop in loops:
        verts += [(x+u,v,depth) for u,v in loop]
    n=len(outer)
    faces=[]
    for r0,r1 in [(0,1),(1,2),(2,3),(3,4),(4,5),(6,0),(7,6)]:
        faces += [(r0*n+i,r0*n+(i+1)%n,r1*n+(i+1)%n,r1*n+i) for i in range(n)]
    gate.part("Hero booth molded wall",verts,faces,"teal")
    for sign in (-1,1):
        gate.box("Closed window back",(x,1.65,sign*.645),(1.57,1.15,.045),"ink")
        # Four-loop cream reveal: wall, outer lip, inner lip and recessed sill.
        out=rounded_profile(1.79,1.37,.17,y=1.65)
        inside=rounded_profile(1.56,1.14,.12,y=1.65)
        v=[(x+u,y,sign*d) for d,loop in [(1.25,out),(1.33,out),(1.33,inside),(.70,inside)] for u,y in loop]
        f=[(r*n+i,r*n+(i+1)%n,(r+1)*n+(i+1)%n,(r+1)*n+i) for r in range(3) for i in range(n)]
        if sign<0:f=[tuple(reversed(face)) for face in f]
        gate.part("Hero booth deep reveal",v,f,"cream")
        gate.box("Booth sill",(x,1.03,sign*1.27),(1.92,.15,.36),"edge",taper=(.02,.04))
        gate.box("Window head",(x,2.31,sign*1.29),(1.84,.14,.18),"gold")
    profile_shell(gate.part,"Hero cap cornice",(x,2.69,0),[
        (-1.37,rounded_profile(2.50,.12,.05)),
        (-1.22,rounded_profile(2.58,.16,.07)),
        (1.22,rounded_profile(2.58,.16,.07)),
        (1.37,rounded_profile(2.50,.12,.05)),
    ],"gold")
    profile_shell(gate.part,"Hero cap blue roof",(x,2.86,0),[
        (-1.47,rounded_profile(2.62,.21,.095)),
        (-1.28,rounded_profile(2.82,.24,.11)),
        (1.28,rounded_profile(2.82,.24,.11)),
        (1.47,rounded_profile(2.62,.21,.095)),
    ],"blue")
    collider((x,1.35,24),(2.3,2.7,2.5),"Entry")
for x in (-3.38,3.38):
    gate.box("Gate pier", (x,1.82,0), (.48,3.44,.52), "gold", taper=(.09,.09))
    stepped_plinth(gate.part, "Pier foot", (x,.16,0), .66, .32, .70, "cream", flare=.05)
    gate.box("Pier capital", (x,3.42,0), (.62,.20,.66), "cream", taper=(-.06,-.06))
    collider((x,1.8,24),(.42,3.6,.46),"Entry")
gate.box("Gate roof core", (0,3.60,0), (8.2,.28,2.72), "deep_blue")
segmented_coping(gate.part, "Gate roof", (0,3.82,0), 8.46, .24, 2.96, "blue", seg_len=1.68, gap=.028)
gate.box("Cream marquee", (0,3.65,1.44), (7.54,.60,.22), "edge", taper=(.02,.04))
gate.box("Marquee gold frame", (0,3.65,1.38), (7.72,.70,.14), "gold")
for x, sign in ((-3.42,1),(3.42,-1)):
    gate.rod("Flag mast",(x,3.92,0),(x,5.15,0),.072,"blue",8)
    gate.box("Pennant",(x+.32*sign,4.88,0),(.64,.38,.085),"brick",taper=(.06,.04))
cambered_canopy(gate.part, (0,3.44,1.32), 7.6, 1.56, .44, 0.0, "brick", "white", "gold", posts=False)
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
roof.rod("Central spindle",(0,.1,0),(0,5.05,0),.40,"purple",12)
roof.rod("Spindle skirt",(0,.1,0),(0,.74,0),.94,"gold",24,.82)
for y_ring in (1.45, 2.65, 3.65):
    roof.rod("Spindle brass collar",(0,y_ring,0),(0,y_ring+.14,0),.47,"gold",16)
def p(r,h,t):
    return (r*math.cos(t),h,r*math.sin(t))
def canopy_height(t):
    return 3.72 + 1.76*(1-t)**1.72
for i in range(16):
    a,b=i*math.tau/16,(i+1)*math.tau/16
    radial,angular=12,4
    verts=[]
    for underside in (0,1):
        for j in range(radial+1):
            t=j/radial
            for k in range(angular+1):
                theta=a+(b-a)*k/angular
                # Broad curved radial profile and a restrained rise between ribs.
                y=canopy_height(t)+.065*math.sin(math.pi*k/angular)*math.sin(math.pi*t)-underside*.10
                verts.append(p(.28+4.08*t,y,theta))
    layer=(radial+1)*(angular+1)
    faces=[]
    for j in range(radial):
        for k in range(angular):
            q=j*(angular+1)+k
            faces += [(q,q+1,q+angular+2,q+angular+1),
                      (layer+q+angular+1,layer+q+angular+2,layer+q+1,layer+q)]
    # Adjacent stripes share boundaries; no internal side walls between colors.
    for k in range(angular):
        q=radial*(angular+1)+k
        faces += [(k,layer+k,layer+k+1,k+1),(q+1,layer+q+1,layer+q,q)]
    roof.part("Hero curved canopy cloth",verts,faces,"brick" if i%2==0 else "white")
    for j in range(6):
        t0,t1=j/6,(j+1)/6
        roof.rod("Curved canopy rib",p(.28+4.08*t0,canopy_height(t0)+.028,a),
                 p(.28+4.08*t1,canopy_height(t1)+.028,a),.035,"gold",6)
    # A continuous scalloped rim with thickness; the inset follows its curve.
    for radius,color,top,bottom,thick in [(4.36,"gold",3.77,3.19,.12),(4.385,"blue",3.64,3.33,.025)]:
        steps=8
        trim=.023 if color=="blue" else 0
        pts=[]
        for back in (0,1):
            for k in range(steps+1):
                t=k/steps;theta=a+trim+(b-a-2*trim)*t
                pts += [p(radius-back*thick,top,theta),p(radius-back*thick,bottom-.17*math.sin(math.pi*t),theta)]
        layer=2*(steps+1);fs=[]
        for k in range(steps):
            q=2*k
            fs += [(q,q+2,q+3,q+1),(layer+q+1,layer+q+3,layer+q+2,layer+q),
                   (q,layer+q,layer+q+2,q+2),(q+3,layer+q+3,layer+q+1,q+1)]
        fs += [(0,1,layer+1,layer),(2*steps+1,2*steps,layer+2*steps,layer+2*steps+1)]
        roof.part("Hero continuous fascia",pts,fs,color)
    roof.ellipsoid("Fascia bulb",p(4.44,3.46,(a+b)/2),(.23,.23,.23),"gold_light")
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
stepped_plinth(platform.part, "Station plinth", (25.6,.18,1), 5.42, .36, 10.12, "brick", flare=.05)
platform.box("Platform core",(25.6,1.12,1),(5.22,1.62,9.88),"purple",taper=(.03,.02))
for z_pil in (-3.6, 1.0, 5.6):
    for sx in (-1, 1):
        platform.box("Station pilaster",(25.6+sx*2.56,1.12,z_pil),(.26,1.66,.34),"deep_blue",taper=(.05,.05))
platform.box("Platform floor",(25.6,2.02,1),(5.34,.36,10.04),"purple")
platform.box("Platform top",(25.6,2.202,1),(5.22,.024,9.92),"cream")
segmented_coping(platform.part,"Gold fascia",(22.94,2.04,1),.22,.36,10.12,"gold",seg_len=1.68,gap=.026)
collider((25.6,1.97,1),(5.3,.46,10))
platform.export()
place("StationFoundation","station_foundation")
for direction,z0,sign in (("South",6,1),("North",-4,-1)):
    name = f"{direction}StationStairs"
    asset = f"station_stairs_{direction.lower()}"
    stairs = Asset(asset,"06 Station")
    ramp=[(24.08,2.2,z0),(27.12,2.2,z0),(27.12,0,z0+sign*7.8),(24.08,0,z0+sign*7.8)]
    surface(ramp,[(3,2,1,0) if sign==1 else (0,1,2,3)],name)
    for i in range(14):
        step_height=2.2*(1-i/14)
        stairs.box("Visible stair",(25.6,step_height-.08,z0+sign*(i+.5)*7.8/14),(3.04,.16,7.8/14),"gold" if i%2==0 else "gold_light")
    for x in (24.03,27.17):
        stairs.rod("Ramp rail",(x,3.23,z0),(x,1.03,z0+sign*7.8),.062,"purple",8)
        for i in range(5):
            t=i/4
            stairs.rod("Ramp post",(x,2.2*(1-t),z0+sign*t*7.8),(x,2.2*(1-t)+1.03,z0+sign*t*7.8),.058,"purple",8)
        collider((x,1.65,z0+sign*3.9),(.12,3.3,7.8),name)
    stairs.export()
    place(name,asset,group=name,shoot=False)

station=Asset("station_roof","06 Station")
for x in (22.8,28.16):
    for z in (-3.4,5.4):
        station.box("Roof support",(x,3.6,z),(.26,2.8,.26),"purple",taper=(.08,.08))
        stepped_plinth(station.part,"Support base",(x,2.30,z),.38,.20,.38,"gold",flare=.025)
        station.box("Support capital",(x,4.88,z),(.38,.18,.38),"gold",taper=(-.06,-.06))
        collider((x,3.6,z),(.22,2.8,.22),"Station")
for x in (23.03,28.22):
    for y in (2.66,3.19):
        station.rod("Platform rail",(x,y,-3.9),(x,y,5.9),.056,"purple",8)
    for z in (-3.9,-1.45,1,3.45,5.9):
        station.rod("Platform post",(x,2.2,z),(x,3.2,z),.055,"purple",8)
    collider((x,2.7,1),(.13,1.0,9.8),"Station")
for x in (18.7,20.2,21.7):
    for z in (1.8,3.7,5.6):
        station.rod("Queue post",(x,0,z),(x,.92,z),.056,"purple",8)
        stepped_plinth(station.part,"Queue foot",(x,.05,z),.18,.10,.18,"gold",flare=.02)
    station.rod("Queue rail",(x,.86,1.8),(x,.86,5.6),.050,"purple",8)
    collider((x,.45,3.7),(.11,.9,3.8),"Station")
c_top = [(22.10,5.38,-4.30),(28.84,4.96,-4.30),(28.84,4.96,6.30),(22.10,5.38,6.30)]
c_bot = [(22.10,5.20,-4.30),(28.84,4.78,-4.30),(28.84,4.78,6.30),(22.10,5.20,6.30)]
station.part("Blue canopy", c_top + c_bot,
             [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], "blue")
for z_rib in (-3.4, -1.2, 1.0, 3.2, 5.4):
    station.rod("Canopy rafter",(22.2,5.18,z_rib),(28.75,4.77,z_rib),.065,"gold",6)
segmented_coping(station.part,"Roof fascia",(28.82,4.86,1),.26,.26,10.65,"gold",seg_len=1.75,gap=.026)
segmented_coping(station.part,"Roof high fascia",(22.12,5.28,1),.26,.26,10.65,"gold",seg_len=1.75,gap=.026)
station.export()
place("StationCanopy","station_roof",group="Station",shoot=False)
collider((25.5,5.02,1),(6.5,.35,10.5),"Station",layer=16)

kiosk=Asset("kiosk","07 Park props")
stepped_plinth(kiosk.part,"Kiosk plinth",(0,.13,0),2.44,.26,2.04,"brick",flare=.04)
kiosk.box("Kiosk body",(0,1.12,0),(2.32,1.96,1.92),"teal",taper=(.04,.04))
for sx in (-1, 1):
    for sz in (-1, 1):
        kiosk.box("Kiosk corner post",(sx*1.11,1.12,sz*.91),(.16,1.94,.16),"cream",taper=(.05,.05))
kiosk.box("Open window",(0,1.47,.94),(1.76,.78,.09),"ink")
for sx in (-1, 1):
    kiosk.box("Kiosk window jamb",(sx*.92,1.47,.99),(.11,.84,.14),"cream")
kiosk.box("Counter",(0,1.03,1.08),(2.06,.16,.44),"cream",taper=(.02,.04))
for sx in (-1, 1):
    kiosk.box("Counter bracket",(sx*.72,.90,1.04),(.13,.14,.30),"gold")
kiosk.box("Roof cornice",(0,2.14,0),(2.52,.11,2.12),"gold",taper=(-.04,-.04))
segmented_coping(kiosk.part,"Roof",(0,2.30,0),2.72,.24,2.32,"edge",seg_len=1.35,gap=.024)
cambered_canopy(kiosk.part,(0,2.16,.98),2.48,.76,.30,0.0,"gold","white","brick",posts=False)
kiosk.export()
for i,(x,z,yaw) in enumerate([(-15,15,.1),(14,15,-.1),(-13,-13,0),(15,-12,.3),(-28,12,1.1),(30,13,-.8)]):
    name=f"Kiosk{i}"
    place(name,"kiosk",(x,0,z),yaw,group=name)
    collider((x,1.05,z),(2.35,2.1,1.95),name,yaw)

bench=Asset("bench","07 Park props")
for x in (-.81,.81):
    stepped_plinth(bench.part,"Bench leg foot",(x,.05,0),.20,.10,.68,"cream",flare=.02)
    bench.box("Bench legs",(x,.28,0),(.17,.48,.62),"blue",taper=(.08,.06))
    bench.box("Back support",(x,.66,-.28),(.15,.68,.15),"blue",taper=(.08,.08))
    bench.box("Bench armrest",(x,.64,.02),(.16,.09,.56),"cream")
for z in (-.19,0,.19):
    bench.box("Seat slat",(0,.53,z),(2.14,.13,.165),"gold")
for y in (.78,.96):
    bench.box("Back slat",(0,y,-.29),(2.14,.13,.155),"gold")
bench.export()
planter=Asset("planter","07 Park props")
stepped_plinth(planter.part,"Planter foot",(0,.08,0),2.06,.16,1.06,"cream",flare=.03)
planter.box("Pot",(0,.26,0),(1.98,.36,.98),"brick",taper=(-.05,-.05))
segmented_coping(planter.part,"Pot rim",(0,.47,0),2.14,.14,1.14,"cream",seg_len=1.06,gap=.022)
for i in range(5):
    x=(i-2)*.34
    planter.ellipsoid("Hedge",(x,.68+.05*(i%3),.07*(i%2)),(.63,.57,.77),"leaf" if i%2 else "leaf_light")
planter.export()
lamp=Asset("lamp","07 Park props")
stepped_plinth(lamp.part,"Lamp foot",(0,.12,0),.38,.24,.38,"cream",flare=.04)
lamp.rod("Post collar",(0,.24,0),(0,.44,0),.12,"gold",8,.09)
lamp.rod("Post",(0,.22,0),(0,3.45,0),.078,"blue",8,.058)
lamp.box("Light housing",(.20,3.49,0),(.62,.19,.34),"blue",taper=(.06,.08))
lamp.box("Housing cap",(.20,3.60,0),(.46,.08,.26),"gold")
lamp.box("Lens",(.2,3.38,0),(.46,.055,.26),"edge")
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
        stepped_plinth(asset.part,"Brick plinth",p+Vector((0,.16,0)),.38,.32,.38,"brick",flare=.035)
        asset.box("Plinth cap",p+Vector((0,.34,0)),(.42,.08,.42),"cream")
        asset.rod("Steel post",p+Vector((0,.36,0)),p+Vector((0,1.78,0)),.084,"blue",8,.068)
        asset.box("Post finial",p+Vector((0,1.82,0)),(.15,.09,.15),"gold")
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
layout["spawns"]=[(-30,0,17),(-30,0,-12),(-18,.43,-5.8),(-18,0,14),(-10,0,-16),(-4,0,13),
                  (8,0,-16),(12,0,5),(20,0,17),(30,0,9),(29,0,-17),(26,2.2,-2.8),
                  (-30,0,8),(0,0,-6),(16,0,14),(18,0,-16)]
layout["respawns"]=[(0,0,21),(-27,0,15),(-29,0,-10.5),(-9,0,-16),(29,0,-14),(28,0,16.5)]
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
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"art_source/amusement_park.blend"), compress=True)
print("PARK_ASSETS_READY",len(layout["instances"]),len(track),len(layout["colliders"]))
