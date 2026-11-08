"""Build the editable Sandgate kit, its zone GLBs and the collision layout."""
import json
import math
from pathlib import Path

import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "assets/models/sandgate"
MODELS.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

PALETTE = {
    "sand": "dcaf73", "pale": "f5dbad", "plaster": "e9c795", "shade": "d6ad7d",
    "cap": "fff0ca", "stone": "dfad5e", "teal": "39877f", "purple": "96558f",
    "red": "b75140", "stripe": "c75443", "blue": "2459a0", "blue_light": "3979bf",
    "gold": "e9ac30", "crate": "f2c04f", "wood": "85502f", "wood_light": "a36539",
    "iron": "38414a", "clay": "b75e3e", "clay_light": "d57b4e", "leaf": "698632",
    "leaf_light": "93ab43", "lamp": "ffdb83",
}
MATERIALS = {}
for name, hex_color in PALETTE.items():
    rgb = [int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4)]
    rgba = tuple(c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in rgb) + (1,)
    material = bpy.data.materials.new(name)
    material.diffuse_color = rgba
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = rgba
    shader.inputs["Roughness"].default_value = 1
    shader.inputs["Specular IOR Level"].default_value = 0
    MATERIALS[name] = material

layout = {"zones": [], "boxes": [], "ramps": [], "props": []}
collection = None


def zone(name, fixed=True):
    global collection
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    if fixed:
        layout["zones"].append(name)
    return collection


def mesh(label, vertices, faces, color):
    data = bpy.data.meshes.new(label)
    data.from_pydata([(x, -z, y) for x, y, z in vertices], [], faces)
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(label, data)
    collection.objects.link(obj)
    data.materials.append(MATERIALS[color])


def prism(label, points, offset, color):
    n = len(points)
    upper = [tuple(a + b for a, b in zip(point, offset)) for point in points]
    faces = [tuple(range(n)), tuple(range(n, 2*n))]
    faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
    mesh(label, points + upper, faces, color)


def box(label, x, y, z, w, h, d, color, solid=False, angle=0):
    cos, sin = math.cos(angle), math.sin(angle)
    base = [(x+u*cos+v*sin, y-h/2, z-u*sin+v*cos)
            for u, v in [(-w/2,-d/2),(w/2,-d/2),(w/2,d/2),(-w/2,d/2)]]
    prism(label, base, (0,h,0), color)
    if solid:
        layout["boxes"].append([[x,y,z],[w,h,d],angle])


def slab(label, x0, x1, z0, z1, y=0, color="sand", thick=.5):
    box(label,(x0+x1)/2,y-thick/2,(z0+z1)/2,x1-x0,thick,z1-z0,color,True)


def ramp(label, x0, x1, z0, z1, y0, y1, color="sand", steps=0):
    if steps:
        for i in range(steps):
            a, b = i/steps, (i+1)/steps
            z_a, z_b = z0+(z1-z0)*a, z0+(z1-z0)*b
            top = y0+(y1-y0)*a
            box(label,(x0+x1)/2,top-.14,(z_a+z_b)/2,x1-x0,.28,abs(z_a-z_b),color)
    points = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z1),(x0,y1,z1)]
    if not steps:
        prism(label,points,(0,-.28,0),color)
    layout["ramps"].append(points)


def facade(label, x, z, w, d, h, color="pale", base=None, floor=0, solid=True):
    box(label,x,floor+h/2,z,w,h,d,color,solid)
    box("Roof coping",x,floor+h+.10,z,w+.22,.20,d+.22,"cap")
    if base:
        box("Painted wall skirt",x,floor+.62,z,w+.022,1.24,d+.022,base)


def shutter(x,y,z,angle=0):
    box("Window stone sill",x,y-.46,z,1.18,.14,.25,"cap",angle=angle)
    box("Shutter frame",x,y,z,.96,.85,.12,"blue",angle=angle)
    for i in range(3):
        nx,nz=math.sin(angle)*.069,math.cos(angle)*.069
        box("Shutter louver",x+nx,y-.24+i*.23,z+nz,.70,.105,.045,"blue_light",angle=angle)


def canopy(x,z,y,width,angle=0,accent="stripe",depth=1.45):
    cos,sin=math.cos(angle),math.sin(angle)
    def pt(u,v,w):
        return (x+u*cos+w*sin,y+v,z-u*sin+w*cos)
    for i in range(7):
        a,b = -width/2+width*i/7,-width/2+width*(i+1)/7
        tone = accent if i%2==0 else "cap"
        prism("Canvas stripe",[pt(a,0,0),pt(b,0,0),pt(b,-.41,depth),pt(a,-.41,depth)],(0,-.055,0),tone)
        xx,yy,zz=pt((a+b)/2,-.54,depth)
        box("Canvas valance",xx,yy,zz,b-a,.22,.06,tone,angle=angle)
    for side in [-1,1]:
        xx,yy,zz=pt(side*(width/2-.16),-1.43,depth-.10)
        box("Market post",xx,yy,zz,.12,2.06,.12,"wood",angle=angle)


def lathe(label,x,y,z,profile,color,segments=10):
    vertices = [(x+r*math.cos(i*math.tau/segments),y+h,z+r*math.sin(i*math.tau/segments))
                for r,h in profile for i in range(segments)]
    faces = [tuple(range(segments))]
    for j in range(len(profile)-1):
        for i in range(segments):
            a=j*segments+i
            b=j*segments+(i+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces.append(tuple(range(len(vertices)-segments,len(vertices))))
    mesh(label,vertices,faces,color)


def pot(x,z,scale=1,y=0):
    profile=[(.22,0),(.30,.08),(.38,.41),(.25,.62),(.24,.70),(.29,.72),(.29,.78),(.19,.78),(.17,.62)]
    lathe("Terra cotta jar",x,y,z,[(r*scale,h*scale) for r,h in profile],"clay",9)


def cactus(x,z,y=0):
    box("Cactus planter",x,y+.10,z,1.58,.20,1.12,"cap")
    lathe("Cactus trunk",x,y+.17,z,[(.19,0),(.23,.2),(.21,1.68),(.12,1.84)],"leaf",7)
    for side,h in [(-1,.86),(1,1.11)]:
        box("Cactus elbow",x+side*.28,y+h,z,.49,.23,.22,"leaf_light")
        lathe("Cactus arm",x+side*.49,y+h,z,[(.12,0),(.13,.46),(.08,.54)],"leaf",7)


def arch(label,x,z,y,r=1.75,spring=2.12,thick=.42,depth=.62,side=1.55,solid=True,angle=0):
    cos,sin=math.cos(angle),math.sin(angle)
    def at(u,v,w=0):
        return (x+u*cos+w*sin,y+v,z-u*sin+w*cos)
    for sign in [-1,1]:
        xx,yy,zz=at(sign*(r+side/2),spring/2)
        box(label+" pier",xx,yy,zz,side,spring,depth,"pale",solid,angle)
        xx,yy,zz=at(sign*(r+thick/2),spring/2,depth*.11)
        box("Arch jamb",xx,yy,zz,thick,spring,depth*1.15,"stone",angle=angle)
    n=11
    top=spring+r+thick+.52
    for i in range(n):
        a,b=i*math.pi/n,(i+1)*math.pi/n
        def ring(t,d):
            return (d*math.cos(t),spring+d*math.sin(t))
        ua,va=ring(a,r)
        ub,vb=ring(b,r)
        uo,vo=ring(b,r+thick)
        up,vp=ring(a,r+thick)
        prism("Arch voussoir",[at(u,v,-depth*.55) for u,v in [(ua,va),(ub,vb),(uo,vo),(up,vp)]],
              (sin*depth*1.10,0,cos*depth*1.10),"stone" if i%3!=0 else "plaster")
        prism("Arch spandrel",[at(u,v,-depth*.5) for u,v in [(up,vp),(uo,vo),(uo,top),(up,top)]],
              (sin*depth,0,cos*depth),"pale")
    xx,yy,zz=at(0,top-.16)
    box("Gate cap",xx,yy,zz,2*(r+side),.32,depth+.20,"cap",solid,angle)
    for sign in [-1,1]:
        xx,yy,zz=at(sign*(r+side/2),top/2)
        box("Upper gate pier",xx,yy+.98,zz,side-.05,top-1.96,depth,"pale",angle=angle)


def arch_recess(x,y,z,angle=0,r=.42,h=.75):
    cos,sin=math.cos(angle),math.sin(angle)
    def point(u,v,depth):
        return (x+u*cos+depth*sin,y+v,z-u*sin+depth*cos)
    outline=[(-r,0),(r,0)]+[(r*math.cos(i*math.pi/8),h+r*math.sin(i*math.pi/8)) for i in range(9)]
    prism("Recessed arch shade",[point(u,v,.015) for u,v in outline],(sin*.028,0,cos*.028),"wood")
    for side in [-1,1]:
        xx,yy,zz=point(side*(r+.045),h/2,.07)
        box("Recess stone jamb",xx,yy,zz,.09,h,.13,"shade",angle=angle)
    for i in range(8):
        a,b=i*math.pi/8,(i+1)*math.pi/8
        points=[point(radius*math.cos(t),h+radius*math.sin(t),.045)
                for t,radius in [(a,r),(b,r),(b,r+.10),(a,r+.10)]]
        prism("Recess arch stones",points,(sin*.07,0,cos*.07),"shade")
    xx,yy,zz=point(0,-.06,.10)
    box("Recess stone sill",xx,yy,zz,r*2+.29,.13,.25,"cap",angle=angle)


def gate_leaf(label,hinge_x,z,width,height,angle):
    cos,sin=math.cos(angle),math.sin(angle)
    def pos(u,v,depth=0):
        return (hinge_x+u*cos+depth*sin,v,z-u*sin+depth*cos)
    for i in range(6):
        a=(i+.5)*width/6
        board_height=height+.80*math.sin((i+.5)*math.pi/12)
        x,y,zz=pos(a,board_height/2)
        box(label,x,y,zz,abs(width)/6-.018,board_height,.20,"wood" if i%3==0 else "wood_light",angle=angle)
    x,y,zz=pos(width/2,height/2)
    layout["boxes"].append([[x,y,zz],[abs(width),height,.21],angle])
    for face in [-1,1]:
        for yy in [.37,1.56,height-.24]:
            x,y,zz=pos(width/2,yy,face*.12)
            box("Iron door strap",x,y,zz,abs(width),.14,.07,"iron",angle=angle)
            for ratio in [.17,.50,.83]:
                x,y,zz=pos(width*ratio,yy,face*.176)
                box("Iron rivet",x,y,zz,.09,.075,.055,"cap",angle=angle)
        for i in range(8):
            a,b=i*math.tau/8,(i+1)*math.tau/8
            points=[pos(width*.82+r*math.cos(t),1.14+r*math.sin(t),face*.15)
                    for t,r in [(a,.11),(b,.11),(b,.165),(a,.165)]]
            prism("Wrought pull ring",points,(sin*face*.07,0,cos*face*.07),"iron")


def crate(x,y,z,w=1.65,h=1.15,d=1.4):
    box("Market freight crate",x,y+h/2,z,w,h,d,"gold")
    box("Recessed face",x,y+h/2,z+d/2+.009,w-.18,h-.27,.028,"crate")
    box("Recessed side",x-w/2-.009,y+h/2,z,.028,h-.27,d-.18,"crate")
    for level in [y+.085,y+h-.085]:
        box("Ivory crate binding",x,level,z,w+.06,.135,d+.06,"cap")
    for dx in [-1,1]:
        box("Corner cleat",x+dx*(w/2-.065),y+h/2,z+d/2+.025,.095,h-.19,.06,"wood_light")


def prop(name,kind,x,y,z,w,h,d,angle=0):
    zone(name,False)
    if kind=="crate":
        crate(0,0,0,w,h,d)
    elif kind=="stack":
        crate(0,0,0,w,h*.57,d)
        crate(.10,h*.57,-.08,w*.77,h*.43,d*.79)
    elif kind=="stall":
        box("Painted counter",0,.47,0,w,.94,d,"gold")
        box("Counter top",0,.99,0,w+.16,.12,d+.14,"cap")
        canopy(0,-d*.5,h-.12,w+.18,depth=d+.34)
        pot(-.56,.18,.63,1.05)
        pot(.36,.14,.83,1.05)
    elif kind=="wall":
        facade("Market partition",0,0,w,d,h,"plaster","red",solid=False)
        shutter(-.86,2.16,d*.5+.10)
        shutter(.86,2.16,d*.5+.10)
    layout["props"].append({"name":name,"kind":kind,"at":[x,y,z],"size":[w,h,d],"angle":angle})


zone("ground")
# The pit is cut out of the street grid. Each surface meets its neighbour.
slab("West foundation",-24,16,-20,20)
slab("East street north",16,24,-20,3)
slab("East street south",16,24,13,20)
slab("Pit floor",16,22.5,7,13,-1.35,"plaster")
slab("Pit east walkway",22.5,24,3,13)
ramp("Pit approach",16,22.5,3,7,0,-1.35,"plaster")
box("South pit retaining",19.25,-.63,12.95,6.5,1.27,.21,"purple",True)
box("West pit retaining",16.04,-.63,9.8,.18,1.27,6.35,"purple",True)
box("Pit coping",16.02,.20,9.65,.34,.40,6.8,"cap",True)
box("South pit coping",19.25,.23,12.93,6.47,.46,.32,"cap",True)
box("Pit rim at outer edge",22.5,.18,9.8,.27,.36,6.4,"cap",True)
slab("Raised A square",9.7,23.8,-17.7,-8.0,2.4,"pale",2.4)
ramp("A Long ramp",12.1,22.8,-8,-2.0,2.4,0,"sand")
box("A platform parapet",10.0,2.79,-12.15,.32,.78,7.6,"cap",True)
box("A side ramp wall",11.83,.58,-5.23,.40,1.16,5.45,"plaster",True)
slab("A Short landing",5.6,9.7,-13.0,-8.3,2.4,"pale",2.4)
slab("A Short elevated lane",5.6,9.55,-8.3,-2.8,2.4,"pale",2.4)
ramp("Short steps",5.6,9.55,2.4,-2.8,0,2.4,"plaster",steps=12)
box("Short teal retaining wall",5.57,1.17,-5.45,.13,2.34,5.45,"teal")
box("Short parapet",5.60,2.75,-5.60,.34,.7,5.7,"cap",True)
box("Short landing parapet",5.62,2.75,-10.62,.34,.7,4.45,"cap",True)
prism("Short stair teal cheek",[(5.51,0,2.39),(5.51,0,-2.79),(5.51,2.4,-2.79)],(.12,0,0),"teal")
prism("Short stair rising coping",[(5.45,.21,2.39),(5.76,.21,2.39),(5.76,2.61,-2.79),(5.45,2.61,-2.79)],(0,-.18,0),"cap")
for z,top in [(.85,.72),(-.85,1.5),(-2.51,2.28)]:
    box("Short stair stone post",5.52,top+.28,z,.33,.56,.34,"cap",True)
# Perimeter collider is also the navigation boundary.
for x,z,w,d in [(-24.4,0,.8,40),(24.4,0,.8,40),(0,-20.4,48,.8),(0,20.4,48,.8)]:
    layout["boxes"].append([[x,2.8,z],[w,6,d],0])

zone("a_long")
arch("Long gate",16.3,15.2,0,r=2.52,spring=2.27,depth=.85,side=2.4)
gate_leaf("Long gate left",13.78,15.46,2.17,3.06,-1.32)
gate_leaf("Long gate right",18.82,15.46,-2.17,3.06,1.32)
facade("Long gate wing",10.74,15.18,3.9,.83,4.85,"pale","red")
facade("Long gate outer wing",22.58,15.18,2.5,.83,4.85,"pale","red")
facade("Long market house",10.75,9.3,2.1,8.8,5.95,"pale","teal")
facade("Long corner house",10.75,-.55,2.1,5.05,5.6,"pale","teal")
facade("Pit boundary houses",23.56,5.4,.82,18.8,5.55,"pale",None)
box("Lavender pit wall",23.12,.6,8.5,.12,2.7,6.7,"purple")
box("Pit wall cream lintel",23.07,2.04,8.5,.22,.16,6.76,"cap")
for z in [8.13,9.43,10.73]:
    arch_recess(11.84,4.17,z,math.pi/2,.39,.66)
for z in [12.4,9.15,6.8,1.05,-1.28]:
    shutter(11.84,3.6,z,math.pi/2)
for z in [8.35,11.15]:
    shutter(23.07,.44,z,-math.pi/2)
facade("A ramp backdrop",23.4,-10.0,1.05,13,7.5,"plaster",None)
facade("A high court rear",16.68,-17.68,14.8,.60,4.42,"pale","red",floor=2.4)
arch("A lookout",17.7,-16.98,2.4,r=1.24,spring=1.91,side=1.25,solid=False)
for x in [10.1,11.6,13.1,22.1]:
    box("A parapet merlon",x,6.98,-17.6,.55,.38,.65,"cap")
canopy(18.75,-15.85,5.4,3.7)
facade("A lookout upper crown",18.56,-17.36,4.75,.70,1.90,"plaster",None,floor=6.48,solid=False)
for x in [17.32,18.50,19.68]:
    box("Lookout slit",x,7.41,-16.98,.32,.80,.065,"wood")
pot(20.1,-14.8,.75,2.4)
cactus(11.05,-15.65,2.4)
box("A wall ledge",11.9,2.79,-10.4,.3,.78,4.15,"cap",True)
# Small buttresses articulate the long elevations without obstructing the lane.
for z in [4.95,8.45,11.95]:
    box("Market corbel",11.94,4.6,z,.5,.24,.26,"wood")
for z in [-3.05,.28,3.61]:
    arch_recess(23.10,3.0,z,-math.pi/2,.34,.62)
for z in [-4.8,-1.2,2.4,6.0,9.6,13.2]:
    box("Outer coping corbel",22.98,4.9,z,.33,.24,.30,"cap")
pot(12.0,12.4,1.03)
pot(12.3,11.8,.58)
cactus(12.23,-1.94)

zone("mid")
arch("Mid double-door arch",0,1.55,0,r=2.08,spring=2.15,depth=.76,side=1.35)
gate_leaf("Mid gate left",-2.08,1.62,1.37,2.76,-.33)
gate_leaf("Mid gate right",2.08,1.62,-1.37,2.76,.33)
facade("Mid east wing",4.57,1.55,2.30,.76,4.42,"pale","teal")
for x in [-2.91,2.91]:
    facade("Mid gate tower crown",x,1.55,.95,.83,.88,"plaster",None,floor=4.86,solid=False)
    arch_recess(x,5.03,1.99,0,.105,.35)
facade("Mid left jamb",-4.02,1.55,1.31,.76,4.42,"pale","teal")
arch("Mid B side arch",-6.7,1.55,0,r=1.48,spring=1.89,depth=.8,side=.84)
for x in [-2.9,-1.9,-.9,.1,1.1,2.1,3.1]:
    box("Mid gate crenellation",x,5.02,1.55,.54,.48,.80,"cap")
facade("Central market front",-5.82,8.5,4.8,5.7,5.7,"pale","teal")
facade("Central market upper",-6.4,8.55,3.38,4.1,1.32,"plaster",None,floor=5.6)
for z in [6.9,8.9,10.45]:
    shutter(-3.35,3.16,z,math.pi/2)
    box("Central market beam end",-3.31,4.55,z,.32,.20,.26,"wood")
canopy(-3.32,7.0,2.73,3.0,math.pi/2,"teal")
facade("North connecting court",-.7,-16.65,12.55,.65,5.16,"plaster","teal")
facade("Inner north corner",3.95,-11.88,1.1,4.9,5.9,"pale","teal")
shutter(3.32,3.75,-10.9,-math.pi/2)
facade("Short houses",9.77,5.26,.42,1.0,4.78,"pale","teal")
shutter(9.51,3.34,5.25,-math.pi/2)
for x in [-5.1,-1.55,2.0]:
    arch("Upper market arcade",x,-16.16,0,r=1.38,spring=2.28,thick=.26,depth=.56,side=.39,solid=False)
for x in [-6.2,-2.8,.75,4.2]:
    box("Arcade coping brace",x,4.46,-15.83,.27,.21,.44,"wood")
cactus(5.05,3.03)
pot(-2.73,3.83,.74)
pot(-3.02,4.4,.53)

zone("b_court")
# B Window sits above a low shelf. The sightline stays open to the rear court.
arch("B north side doorway",-20.18,-10.75,0,r=1.53,spring=2.03,side=.65,depth=.68)
gate_leaf("B return left",-21.71,-10.67,.65,2.02,-.42)
gate_leaf("B return right",-18.65,-10.67,-.65,2.02,.42)
facade("B window left pier",-17.98,-10.75,1.10,.67,5.19,"pale","purple")
facade("B purple window east",-11.73,-10.75,5.2,.67,5.19,"pale","purple")
box("B Window lower wall",-15.90,.85,-10.75,3.60,1.70,.67,"purple",True)
box("B Window lintel",-15.90,4.65,-10.75,3.60,1.09,.67,"pale",True)
box("B window sill",-15.90,1.78,-10.18,3.94,.20,.77,"cap",True)
for x in [-17.79,-14.01]:
    box("B window painted jamb",x,2.90,-10.34,.28,2.42,.19,"purple")
box("B window painted head",-15.90,4.12,-10.34,4.05,.34,.19,"purple")
box("B purple east reveal",-13.43,2.69,-10.39,.94,2.80,.09,"purple")
box("B purple west reveal",-18.29,2.69,-10.39,.62,2.80,.09,"purple")
for x in [-17.23,-14.57]:
    box("Stone shelf bracket",x,1.48,-10.05,.25,.41,.43,"shade")
box("B Window roof coping",-15.90,5.28,-10.75,3.8,.21,.87,"cap")
for x in [-17.85,-16.55,-15.25,-13.95,-12.65]:
    box("B roof corbel",x,4.82,-10.29,.27,.24,.46,"cap")
facade("B western court wall",-23.55,-6.7,.85,8.0,5.22,"pale","teal")
facade("B south court west",-21.5,1.15,4.1,.63,4.55,"pale","purple")
facade("B south court return",-12.1,1.15,5.3,.63,4.55,"pale","teal")
arch("B tunnel portal",-17.75,1.15,0,r=1.69,spring=2.0,side=1.01,depth=.72)
arch("B exit",-8.2,-5.4,0,r=1.40,spring=1.92,side=.77,depth=.65,angle=math.pi/2)
facade("B connector north",-8.2,-10.0,.64,4.8,4.75,"pale","teal")
facade("B connector south",-8.2,-.95,.64,4.7,4.75,"pale","teal")
facade("B rear court wall",-16.85,-17.5,13.0,.74,2.55,"plaster","purple")
facade("B rear side tower",-21.8,-17.51,2.6,2.3,5.40,"pale","purple")
shutter(-18.04,3.64,-10.34)
shutter(-11.35,3.46,-10.36)
shutter(-13.42,3.03,.77,math.pi)
cactus(-10.0,-9.20)
pot(-10.61,-9.35,1.1)
pot(-21.71,-8.87,.91)
box("B display plinth",-17.40,.44,-9.10,3.19,.88,2.48,"pale",True)
lathe("Ochre tower",-20.3,0,-15.15,[(1.38,0),(1.38,6.98),(1.54,7.07),(1.54,7.41)],"gold",10)
lathe("Faceted tower dome",-20.3,7.41,-15.15,[(1.55,0),(1.53,.45),(1.22,.98),(.62,1.34),(.12,1.43)],"cap",10)
lathe("Tower finial",-20.3,8.8,-15.15,[(.085,0),(.074,1.01)],"wood",8)
for i in range(5):
    angle=i*math.tau/5
    box("Tower inset slit",-20.3+math.sin(angle)*1.39,6.45,-15.15+math.cos(angle)*1.39,.24,.95,.05,"wood",angle=angle)

zone("b_tunnel")
for x in [-20.36,-15.14]:
    facade("Tunnel abutment",x,5.32,1.21,7.45,3.06,"shade",None)
box("Tunnel roof", -17.75,3.87,5.3,6.53,.71,7.89,"plaster",True)
for z in [2.55,5.4,8.36]:
    arch("Tunnel rib",-17.75,z,0,r=1.86,spring=1.88,thick=.21,depth=.30,side=.71,solid=False)
facade("Tunnel left rear wall",-22.4,10.65,3.4,.80,5.0,"pale","purple")
facade("Tunnel end house",-13.01,10.5,3.15,.80,4.95,"pale","teal")
shutter(-13.12,3.27,10.96)
pot(-19.45,1.96,.86)

zone("skyline")
# Unreachable roofs shape the silhouette without adding playable obstructions.
for x,z,w,d,h in [(-23,-19,5,3,7.0),(-13.35,-19,3.0,2.5,4.0),(-6.5,-19,6.5,2.3,7.1),
                    (1.8,-19,4.0,2.4,6.1),(8,-18.8,5.8,2.0,8.2),(22,-19.3,5.6,2.4,7.0),
                    (-24,5.0,2.5,10.3,6.4),(24,13,1.2,7.1,5.3),(-22,17,3.8,4.1,4.5)]:
    facade("Skyline house",x,z,w,d,h,"plaster" if h>6.2 else "pale",None,solid=False)
    shutter(x,h-1.18,z+d/2+.09)
    for offset in [-.28,.28]:
        box("Roof beam end",x+w*offset,h-.70,z+d/2+.08,.23,.19,.30,"wood")
for x,z,w,d in [(-8.6,15.7,4.5,4.4),(2.5,15.85,5.0,2.90)]:
    facade("Arrival court house",x,z,w,d,4.38,"pale","red")
    shutter(x,3.05,z+d/2+.08)
    shutter(x,3.05,z-d/2-.08,math.pi)

prop("a_stall_south","stall",12.17,0,9.25,2.76,2.83,1.20,math.pi/2)
prop("a_stall_north","stall",12.03,0,5.95,2.68,2.79,1.17,math.pi/2)
prop("a_cross_wall","wall",10.74,0,3.0,2.95,3.25,.61,math.pi/2)
prop("a_platform_box","stack",20.10,2.4,-13.23,1.91,1.83,1.56)
prop("a_ramp_box","crate",14.12,2.4,-10.62,1.67,1.06,1.28)
prop("pit_box","stack",19.94,-1.35,10.3,1.38,1.38,1.28)
prop("short_box","crate",8.59,2.4,-5.15,1.31,.98,1.15)
prop("mid_gate_box","stack",2.93,0,2.71,1.27,1.29,1.18)
prop("mid_return_box","crate",-4.39,0,-3.58,1.75,1.07,1.16)
prop("b_stall","stall",-22.46,0,-4.03,2.98,2.77,1.2,math.pi/2)
prop("b_crate_wall","stack",-13.34,0,-6.62,2.30,1.88,1.66)
prop("b_crate_low","crate",-15.58,0,-6.65,1.86,.94,1.65)
prop("b_platform_box","stack",-17.98,.88,-9.04,1.92,1.91,1.46)
prop("b_window_box","crate",-14.90,0,-9.65,1.65,.88,1.32)
prop("tunnel_box","crate",-19.04,0,6.54,1.17,.99,1.14)

layout["start"] = [15.73,.05,17.48]
layout["opening"] = [
    [14.23,0,8.42,False],[21.05,2.4,-11.65,False],[7.28,2.4,-6.67,False],
    [1.35,0,-3.8,False],[-5.30,0,-8.92,False],[-11.51,0,-8.05,True],
    [-19.49,0,-5.25,False],[-17.80,0,5.64,True],
]
layout["spawns"] = [
    [12.34,0,17.83],[19.1,0,17.65],[14.00,0,12.15],[21.85,2.4,-14.65],
    [12.54,2.4,-14.55],[7.24,2.4,-11.61],[3.14,0,-14.67],[1.77,0,-5.87],
    [-5.8,0,-13.1],[-10.4,0,-14.2],[-21.14,0,-8.56],[-11.22,0,-4.1],
    [-18.26,0,8.6],[-20.38,0,13.6],[-4.49,0,12.50],[4.61,0,10.20],
]
layout["respawns"] = [[15.83,0,17.7],[14.28,0,7.54],[7.11,2.4,-11.02],
                      [1.80,0,8.82],[-17.1,0,-4.42],[-17.22,0,10.04],[-5.18,0,-11.95]]
layout["barrels"] = [[13.22,0,4.34],[3.14,0,3.80],[-14.35,0,-5.38],[-20.56,0,-5.70]]
layout["routes"] = [[15.77,0,14.06],[17.34,-1.35,9.07],[18.2,2.4,-11.35],[7.2,2.4,-6.8],
                    [7.31,0,2.8],[0.0,0,1.56],[-4.9,0,-5.36],[-12.05,0,-4.98],
                    [-19.85,0,-7.0],[-17.7,0,4.5],[-17.42,0,10.2]]
layout["clouds"] = [[-31,10,-31],[-7,8,-33],[14,8,-33],[32,13,-29],[39,15,28]]

bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "art_source/sandgate.blend"))

# Retain separate editable objects in Blender. Export only one mesh per zone
# and material, so the browser does not pay a draw call for every corbel.
def export(source):
    batch = bpy.data.collections.new("Export")
    bpy.context.scene.collection.children.link(batch)
    bpy.ops.object.select_all(action="DESELECT")
    combined = {}
    for obj in source.objects:
        color = obj.data.materials[0]
        vertices, faces = combined.setdefault(color, ([],[]))
        offset = len(vertices)
        vertices.extend(tuple(v.co) for v in obj.data.vertices)
        faces.extend(tuple(offset+i for i in f.vertices) for f in obj.data.polygons)
    data = bpy.data.meshes.new(source.name)
    vertices, faces, slots = [], [], []
    for i, (color, (points, polygons)) in enumerate(combined.items()):
        offset = len(vertices)
        vertices.extend(points)
        faces.extend(tuple(offset+j for j in f) for f in polygons)
        slots.extend([i]*len(polygons))
    data.from_pydata(vertices, [], faces)
    for color in combined:data.materials.append(color)
    for polygon, slot in zip(data.polygons, slots):polygon.material_index = slot
    obj = bpy.data.objects.new(source.name, data)
    batch.objects.link(obj)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=str(MODELS / (source.name + ".glb")), use_selection=True, export_format="GLB")
    bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(batch)

for name in layout["zones"] + [item["name"] for item in layout["props"]]:
    export(bpy.data.collections[name])
(ROOT / "tools/maps/sandgate_layout.json").write_text(json.dumps(layout, separators=(",",":")) + "\n")
print("SANDGATE_KIT_READY", len(layout["zones"]), "zones and", len(layout["props"]), "destructible props")
