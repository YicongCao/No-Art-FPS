"""Build the BB office's editable Blender kit, GLBs and matching collider layout."""
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/maps"))
from toy_kit import (
    chipped_box,
    export_toy_parts,
    repair_patch_plate,
    segmented_coping,
    slanted_wall_seam,
    stepped_plinth,
    tapered_box,
)
from hero_geometry import profile_shell, rounded_profile

OUT = ROOT / "assets/models/bb_office"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

COLORS = {
    "ink": "202945", "navy": "283753", "slate": "415374", "blue": "3658C5",
    "cobalt": "2446AE", "cyan": "82CFFE", "violet": "764D89", "lilac": "AB77AE",
    "gold": "F6C35B", "amber": "D3903D", "ivory": "FFF0D5", "floor": "D9C6AE",
    "tile": "B9AA9B", "red": "BF5859", "pink": "E48B84", "green": "48816F",
    "mint": "82B9A3", "dark_teal": "305963", "teal": "477B82", "leaf": "72A164",
    "card": "D8A86B", "paper": "FFF9E9", "screen": "92C4DF", "tally": "FF4D4B",
    "carpet": "B2A7AC", "carpet_dark": "9C929F", "carpet_light": "C1B3B5", "carpet_seam": "827E90",
    "soffit": "817D89", "galvanized": "8099A7", "duct_joint": "4B6577",
    "copper": "D89964", "sprinkler": "B8494E", "cable": "2F354B",
    "display_glass": "3E5268", "laptop_glass": "A2C1DA", "wood": "AB6C51", "timber": "E4A17C",
    "screen_dark": "253950", "code": "76DCC3", "white": "F5F3E8",
    "orange": "F48A54", "coffee": "68412F", "facade": "788FA8", "glass_blue": "54809C",
    "lamp": "FFE8AC", "green_screen": "67BA78",
}
materials = {}
for name, hex_color in COLORS.items():
    rgb = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    color = (*[c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in rgb], 1)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = .94 if name.startswith("carpet") else .54
    if name in ("display_glass", "laptop_glass"):
        shader.inputs["Metallic"].default_value = .22
        shader.inputs["Roughness"].default_value = .24
    if name in ("screen_dark", "code", "mint", "blue", "screen"):
        shader.inputs["Roughness"].default_value = .33
    if name in ("code", "screen"):
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = .19
    if name in ("lamp", "tally", "cyan"):
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = .6
    materials[name] = mat


def xyz(p):
    return p[0], -p[2], p[1]


class Kit:
    def __init__(self, name):
        self.name = name
        self.parts = []
        self.collection = bpy.data.collections.new(name)

    def mesh(self, label, points, faces, color):
        self.parts.append((label, points, faces, color))
        origin = sum((Vector(v) for v in points), Vector()) / len(points)
        mesh = bpy.data.meshes.new(label)
        mesh.from_pydata([xyz(Vector(v) - origin) for v in points], [], faces)
        mesh.materials.append(materials[color])
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

    def molded(self, label, center, size, color, angle=0, radius=.09):
        w,h,d = size
        edge = min(.035, d*.22)
        profile_shell(self.mesh, "Molded " + label, center, [
            (-d/2, rounded_profile(w-.025,h-.025,radius)),
            (-d/2+edge, rounded_profile(w,h,radius)),
            (d/2-edge, rounded_profile(w,h,radius)),
            (d/2, rounded_profile(w-.025,h-.025,radius)),
        ], color, angle)

    def export(self):
        bl_parts = [(label, [xyz(p) for p in verts], polys, color)
                    for label, verts, polys, color in self.parts]
        return export_toy_parts(
            self.name,
            bl_parts,
            materials,
            OUT / f"{self.name}.glb",
            bevel=(self.name != "city"),
            max_bevel=0.026,
            skip_labels=("Molded ", "Sculpted ", "Carpet tile", "Syntax token", "Waterfall", "Revenue", "Keyboard key", "Sesame seed"),
        )


layout = {"boxes": [], "glass": [], "props": [], "spots": [], "faults": []}
kits = {}


def kit(name):
    item = kits[name] = Kit(name)
    bpy.context.scene.collection.children.link(item.collection)
    return item


def solid(item, label, center, size, color):
    item.box(label, center, size, color)
    layout["boxes"].append([center, size])


def instance(asset, name, at, bounds, angle=0, impact="", sections=()):
    layout["props"].append(dict(asset=asset, name=name, at=at, bounds=bounds,
                                angle=angle, impact=impact, sections=sections))


def wall_between(item, label, left, right, z, color):
    span = right - left
    cx = (left + right) * 0.5
    layout["boxes"].append([(cx, 1.8, z), (span, 3.6, .22)])
    # Recessed dark spine + modular molded wall panels with 2.6cm vertical seams
    item.box(label + " core", (cx, 1.8, z), (span - .02, 3.56, .17), "navy")
    n_panels = max(1, round(span / 1.65))
    step = span / n_panels
    for i in range(n_panels):
        px = left + (i + 0.5) * step
        tint_p = "lilac" if (n_panels >= 4 and i == n_panels - 2) else color
        item.box(label, (px, 1.82, z), (max(.18, step - .026), 3.16, .22), tint_p)
    if span >= 4.5:
        slanted_wall_seam(item.mesh, (cx - span*.18, 1.35, z - .11), 1.15, .92, math.pi, "navy", "lilac")
        repair_patch_plate(item.mesh, (cx + span*.22, .68, z + .11), .74, .44, 0.0, "galvanized", "navy")
    # Grounding double-sided baseboard plinth + top crown header rail
    stepped_plinth(item.mesh, "Skirting plinth", (cx, .115, z), span, .23, .29, "slate", flare=.022)
    item.box("Skirting lip", (cx, .245, z), (span, .048, .265), "lilac")
    segmented_coping(item.mesh, "Wall crown rail", (cx, 3.50, z), span, .20, .285, "navy", seg_len=1.65, gap=.024, slant=.14, wear=.48)


shell = kit("architecture")
solid(shell, "Floor slab", (0,-.20,0), (54,.4,42), "carpet")
solid(shell, "Exposed concrete slab", (0,3.93,0), (54,.30,42), "soffit")
for z in (-20.9,20.9):
    solid(shell,"Exterior wall",(0,1.8,z),(54,3.6,.22),"slate")
for i in range(14):
    z = -19.5+i*3
    for side in (-1,1):
        x = side*26.86
        shell.box("Curtain wall sill",(x,.16,z),(.34,.32,2.96),"slate",taper=(.06,.01))
        shell.box("Curtain wall sill cap",(x,.34,z),(.38,.075,2.96),"ivory")
        shell.box("Curtain wall header",(x,3.69,z),(.34,.20,2.96),"slate")
        shell.box("Curtain wall mullion",(x,1.92,z-1.5),(.28,3.72,.14),"navy",taper=(.04,.04))
        shell.box("Glass seam rail",(x,.86,z),(.16,.09,2.96),"slate")
for side in (-1,1):
    layout["glass"].append([[side*26.9,1.93,0],[42,3.57],math.pi/2])
    for z in (-17,-8,2,12,19):
        layout["boxes"].append([(side*26.45,1.92,z),(.78,3.84,.76)])
        shell.box("Perimeter column",(side*26.45,1.92,z),(.78,3.48,.76),"navy",taper=(.04,.04))
        stepped_plinth(shell.mesh,"Column plinth",(side*26.45,.18,z),.86,.36,.84,"slate",flare=.04)
        shell.box("Column capital",(side*26.45,3.70,z),(.88,.24,.86),"slate",taper=(-.05,-.05))
for col in range(18):
    for row in range(14):
        x, z = -25.5+col*3, -19.5+row*3
        tint = ("carpet_dark","carpet","carpet_light")[(col*7+row*5+row//3)%3]
        if abs(x)>19 and -14<z<13:
            tint = "carpet_dark"
        shell.box("Carpet tile",(x,.003,z),(2.988,.006,2.988),tint)
for x in (-21,-14,-7,0,7,14,21):
    shell.box("Suspended ceiling beam",(x,3.78,0),(.34,.25,42),"slate")
for z in (-18,-12,-6,0,6,12,18):
    shell.box("Cross ceiling beam",(0,3.78,z),(54,.23,.31),"slate")
for x in (-21,-14,-7,0,7,14,21):
    for z in (-17,-11,-5,1,7,13,18):
        shell.box("Suspended linear light housing",(x,3.53,z),(3.66,.19,.24),"slate",taper=(.02,.08))
        for end in (-1, 1):
            shell.box("Light fixture end cap",(x+end*1.84,3.52,z),(.09,.21,.26),"navy")
        shell.box("Strip diffuser",(x,3.428,z),(3.56,.05,.15),"lamp")
        for end in (-1,1):
            shell.rod("Pendant support",(x+end*1.47,3.61,z),(x+end*1.47,3.79,z),.032,"navy",8)

services = kit("building_services")
# Route the mechanical mains beside the light tracks and cross the room over the aisle ends.
for x in (-9.4,9.4):
    services.box("Central supply duct",(x,3.47,-.9),(.98,.52,23.8),"galvanized")
    services.box("Insulated duct spine",(x,3.72,-.9),(.88,.14,23.8),"duct_joint")
    for z in range(-12,12,2):
        services.box("Flanged duct joint",(x,3.47,z),(1.18,.70,.14),"duct_joint")
        services.box("Flange gasket band",(x,3.47,z),(1.21,.73,.055),"ivory")
        for sx in (-1, 1):
            for sy in (-1, 1):
                services.box("Duct flange bolt lug",(x+sx*.57,3.47+sy*.32,z),(.10,.10,.19),"gold")
    for z in (-9.2,-3.15,2.85,8.85):
        for target_x in (x-4.05,x+4.05):
            low_run=z==2.85
            direction=math.copysign(1,target_x-x)
            elbow_x=x+direction*1.02
            duct_y=3.06 if low_run else 3.51
            diffuser_y=duct_y-.22
            if low_run:
                services.box("Upper branch takeoff",(x+direction*.53,3.51,z),(1.06,.34,.54),"galvanized")
                services.box("Two-level duct drop elbow",(elbow_x,3.27,z),(.49,.78,.58),"galvanized")
                for y in (3.42,3.13):
                    services.box("Elbow flange",(elbow_x,y,z),(.55,.069,.64),"duct_joint")
                services.box("Lower duct hanger saddle",(target_x-direction*.67,2.87,z),(.10,.078,.71),"duct_joint")
                for shift in (-.32,.32):
                    services.rod("Lower branch threaded hanger",(target_x-direction*.67,2.87,z+shift),
                                 (target_x-direction*.67,3.79,z+shift),.026,"slate",7)
            start=elbow_x if low_run else x
            services.box("Rectangular branch duct",((start+target_x)*.5,duct_y,z),
                         (abs(start-target_x),.36,.56),"galvanized")
            services.box("Branch duct collar",((start+target_x)*.5,duct_y,z),
                         (.10,.44,.64),"duct_joint")
            services.box("Ceiling diffuser",(target_x,diffuser_y,z),(.82,.13,.80),"ivory",taper=(-.06,-.06))
            for offset in (-.23,-.115,0,.115,.23):
                services.box("Diffuser grille",(target_x+offset,diffuser_y-.068,z),(.052,.034,.62),"duct_joint")
        for shift in (-.65,.65):
            services.rod("Galvanized hanger rod",(x+shift,3.48,z),(x+shift,3.77,z),.026,"slate",6)
        services.box("Duct hanger rail",(x,3.185,z),(1.42,.056,.07),"slate")
    for offset,color in ((-.94,"sprinkler"),(-1.25,"copper"),(-1.54,"blue")):
        at=x+offset
        services.rod("Exposed service pipe",(at,3.60,-12.6),(at,3.60,11.0),.065,color,8)
        for z in (-11,-5,1,7):
            services.rod("Service pipe union",(at,3.6,z-.08),(at,3.6,z+.08),.088,"galvanized",8)
            if color=="sprinkler":
                services.rod("Sprinkler head drop",(at,3.6,z),(at,3.26,z),.035,color,7)
                services.rod("Sprinkler deflector",(at,3.22,z),(at,3.27,z),.077,"gold",8)

for z in (-10.65,-4.65,1.35,7.35,12.35):
    for x in (-14,0,14):
        services.box("Open cable ladder rail",(x,3.67,z-.23),(7.8,.084,.056),"duct_joint")
        services.box("Open cable ladder rail",(x,3.67,z+.23),(7.8,.084,.056),"duct_joint")
        for i in range(13):
            services.box("Cable ladder rung",(x+(i-6)*.58,3.64,z),(.055,.065,.49),"galvanized")
        for offset,color in ((-.15,"cable"),(-.045,"blue"),(.09,"copper"),(.16,"cable")):
            services.rod("Bundled power and network line",(x-3.86,3.60,z+offset),
                         (x+3.86,3.60,z+offset),.024,color,6)
        if z in (-4.65,7.35):
            services.box("Junction box with lid",(x+.2,3.52,z),(.58,.24,.50),"duct_joint")
            services.box("Junction box service lid",(x+.20,3.382,z),(.51,.042,.43),"galvanized")
            for shift,color in ((-.05,"cable"),(.10,"sprinkler")):
                drop=[(x+.08,3.53,z+shift),(x+.31,3.29,z+shift),(x+.66,3.29,z+shift),(x+.83,3.55,z+shift)]
                for first,last in zip(drop,drop[1:]):
                    services.rod("Loose junction cable",first,last,.031,color,7)
            layout["faults"].append([[x+.31,3.29,z-.05],[x+.66,3.29,z+.10]])
        if z in (-10.65,1.35,12.35):
            services.rod("Wireless AP mounting stem",(x,3.36,z+.57),(x,3.62,z+.57),.061,"slate",8)
            services.rod("Ceiling wireless access point",(x,3.26,z+.57),(x,3.38,z+.57),.19,"ivory",12,.22)
            services.rod("Wireless AP status LED",(x+.08,3.245,z+.57),(x+.08,3.265,z+.57),.029,"code",8)

city = kit("city")
for side in (-1,1):
    for row in range(2):
        for i in range(12):
            x = side*(33+row*9+(i%3)*2.3)
            z = -34+i*6.2+(row%2)*2
            top = [-.3,3.0,7.2,1.8,5.3,9.3,2.9,4.8][(i+side+row*2)%8]
            width = 4.6+(i%4)*.55
            city.box("City tower",(x,(top-22)/2,z),(4.3,top+22,width),
                     ("slate","facade","glass_blue","carpet_dark")[(i+row)%4])
            if row==0:
                for floor in range(-8,int(top),2):
                    city.box("Window bands",(x-side*2.17,floor,z),(.045,.47,width-.48),
                             ("screen","glass_blue","ivory")[(i+floor)%3])
for x in (-14,0,14):
    for z in (.8,12.8):
        shell.box("Recessed projector housing",(x,3.57,z),(.30,.26,.28),"navy")
        layout["spots"].append([[x,3.41,z],[x,1.12,z-3.1]])

reception = kit("reception")
solid(reception,"Company feature wall",(0,1.85,20.55),(16,3.5,.38),"violet")
stepped_plinth(reception.mesh,"Feature wall plinth",(0,.13,20.52),16.16,.26,.46,"slate",flare=.03)
segmented_coping(reception.mesh,"Feature wall crown",(0,3.52,20.52),16.20,.20,.48,"navy",seg_len=2.0,gap=.026)
reception.box("Company wall inset",(0,1.91,20.33),(13.0,2.78,.085),"navy")
for x in (-6.78,6.78):
    reception.box("Logo wall accent",(x,1.89,20.28),(.12,2.74,.11),"gold")
for left,right in ((-18,-3.25),(3.25,18)):
    wall_between(reception,"Entrance wall return",left,right,16.25,"violet")
for x in (-3.25,3.25):
    reception.box("Glazed entry jamb",(x,1.77,16.25),(.19,3.54,.32),"navy",taper=(.03,.03))
    stepped_plinth(reception.mesh,"Glazed entry foot",(x,.13,16.25),.25,.26,.36,"slate",flare=.025)
reception.box("Entrance header",(0,3.44,16.25),(6.75,.34,.34),"navy")
for side in (-1,1):
    x=side*2.47
    # Fixed leaves are framed as an already-open doorway with a wide center passage.
    layout["glass"].append([[x,1.54,16.25],[1.48,3.05],0])
    for dx in (-.75,.75):
        reception.box("Glass leaf stile",(x+dx,1.54,16.25),(.095,3.08,.105),"slate")
    for y in (.07,3.06):
        reception.box("Glass leaf rail",(x,y,16.25),(1.54,.095,.105),"slate")
    reception.box("Door pull",(x-side*.51,1.22,16.11),(.075,.52,.14),"gold")
layout["boxes"].append([(-9.5,.25,19.22),(3.6,.5,1.02)])
stepped_plinth(reception.mesh,"Lobby bench plinth",(-9.5,.09,19.22),3.48,.18,.92,"slate",flare=.025)
for bx in (-11.38, -9.5, -7.62):
    reception.box("Lobby bench cushion",(bx,.34,19.22),(1.16,.32,1.02),"pink",taper=(.05,.05))

rooms = kit("rooms")
for x in (-22,-12,-5.5,5.5,12,22):
    layout["boxes"].append([(x,1.8,-16.5),(.22,3.6,8.8)])
    rooms.box("Room party wall core",(x,1.8,-16.5),(.17,3.56,8.78),"navy")
    for p_idx in range(5):
        pz = -20.02 + p_idx * 1.76
        rooms.box("Room party wall",(x,1.82,pz),(.22,3.16,1.734),"violet")
    stepped_plinth(rooms.mesh,"Party wall plinth",(x,.115,-16.5),.29,.23,8.8,"slate",flare=.022)
    segmented_coping(rooms.mesh,"Party wall crown",(x,3.50,-16.5),.285,.20,8.8,"navy",seg_len=1.76,gap=.024)
for left,right in ((-22,-18.25),(-15.75,-12),(-12,-5.5),(-5.5,-2.05),(2.05,5.5),(5.5,12),(12,15.75),(18.25,22)):
    # Outside the conference and manager rooms, the inset alcoves remain open.
    if (left,right) in ((-12,-5.5),(5.5,12)):
        continue
    if (left,right) in ((-15.75,-12),(18.25,22)):
        window = (left+right)/2
        wall_between(rooms,"Sidelight side",left,window-.83,-12.1,"violet")
        wall_between(rooms,"Sidelight side",window+.83,right,-12.1,"violet")
        solid(rooms,"Sidelight knee wall",(window,.52,-12.1),(1.66,1.04,.22),"violet")
        stepped_plinth(rooms.mesh,"Sidelight plinth",(window,.115,-12.1),1.70,.23,.29,"slate",flare=.022)
        solid(rooms,"Sidelight header",(window,3.16,-12.1),(1.66,.88,.22),"violet")
        layout["glass"].append([[window,1.88,-12.1],[1.66,1.68],0])
        rooms.box("Sidelight chunky sill",(window,1.04,-12.1),(1.82,.12,.36),"ivory",taper=(.02,.04))
        rooms.box("Sidelight head casing",(window,2.73,-12.1),(1.82,.12,.33),"slate")
        for side in (-1, 1):
            rooms.box("Sidelight jamb casing",(window+side*.84,1.88,-12.1),(.11,1.68,.32),"slate")
    else:
        wall_between(rooms,"North corridor partition",left,right,-12.1,"violet")
for x in (-17,0,17):
    span = 4.1 if x==0 else 2.5
    solid(rooms,"Portal lintel",(x,3.39,-12.1),(span,.42,.22),"slate")
    rooms.box("Portal lintel cap",(x,3.52,-12.1),(span+.28,.16,.33),"navy")
    for side in (-1,1):
        rooms.box("Portal lining",(x+side*span/2,1.68,-12.1),(.15,3.36,.32),"navy",taper=(.03,.03))
        stepped_plinth(rooms.mesh,"Portal plinth block",(x+side*span/2,.13,-12.1),.20,.26,.36,"slate",flare=.025)
rooms.box("Open meeting-room door",(1.99,1.57,-13.13),(.11,3.12,2.05),"wood")
layout["boxes"].append([[1.99,1.57,-13.13],[.11,3.12,2.05]])
for z in (-13.8,-12.55):
    rooms.box("Meeting door timber inset",(1.926,1.55,z),(.038,2.86,.54),"timber")
rooms.box("Open door handle",(1.92,1.22,-13.9),(.13,.10,.25),"gold")
rooms.box("Projection screen wall cassette",(-5.35,2.99,-16.85),(.19,.18,4.7),"ink")
rooms.box("Pulldown projector screen",(-5.29,2.07,-16.85),(.08,1.7,4.55),"white")
rooms.box("Ceiling projector",(0,3.3,-17.4),(.56,.24,.50),"white")
rooms.rod("Projector lens",(-.28,3.31,-17.4),(-.34,3.31,-17.4),.089,"screen",10)
rooms.box("Conference television housing",(0,2.02,-20.65),(4.45,2.15,.14),"ink")
rooms.box("Conference television panel",(0,2.02,-20.55),(4.22,1.93,.08),"screen_dark")
for i in range(5):
    rooms.box("TV standby pattern",(-1.47+i*.69,1.99+(i%2)*.18,-20.50),(.49,.055,.02),"slate")

door = kit("manager_door")
door.box("Timber slab",(0,1.53,0),(2.35,3.04,.16),"wood")
for x in (-.70,0,.70):
    door.box("Raised door panel",(x,1.56,.096),(.58,2.76,.07),"timber")
door.box("Door lock",(.82,1.18,.162),(.15,.26,.058),"navy")
door.box("Lever handle",(.71,1.22,.22),(.31,.07,.11),"gold")
for i,x in enumerate((-17,17)):
    instance("manager_door",f"ManagerDoor{i}",(x,0,-12.1),(2.35,3.06,.25),impact="wood")

phone = kit("phone_booth")
for x in (-.83,.83):
    phone.box("Phone booth acoustic side",(x,1.26,0),(.13,2.52,1.76),"teal")
phone.box("Phone booth back",(0,1.26,-.81),(1.63,2.52,.13),"slate")
phone.box("Acoustic booth canopy",(0,2.55,0),(1.83,.17,1.83),"navy")
phone.box("Phone shelf",(0,1.09,-.56),(1.52,.09,.44),"ivory")
phone.box("Handset",(-.45,1.19,-.59),(.25,.105,.18),"ink")
phone.box("Phone booth lamp",(0,2.44,-.38),(.8,.048,.22),"lamp")
phone.box("Acoustic booth stool",(0,.5,-.24),(.62,.16,.56),"orange")
phone.rod("Stool stem",(0,.02,-.24),(0,.45,-.24),.065,"slate",8)
for z in (-.85,.85):
    phone.box("Door side trim",(.78,1.24,z),(.11,2.49,.075),"navy")
for i,x in enumerate((-9,9)):
    instance("phone_booth",f"PhoneBooth{i}",(x,0,-14.14),(1.83,2.63,1.83))
    layout["glass"].append([[x+.44,1.24,-13.22],[.59,2.36],0])

chair = kit("chair")
def seat(item,x,z,angle=0):
    ca,sa=math.cos(angle),math.sin(angle)
    def pt(u,v,w):
        return (x+ca*u+sa*w,v,z-sa*u+ca*w)
    def emit(label,points,faces,color):
        item.mesh(label,[pt(*v) for v in points],faces,color)
    # A continuous compound-curved shell: narrow lumbar waist, broad shoulders,
    # swept upper corners and a bowed face. Rear structure is visible from aisles.
    rows=[(.53,.23),(.61,.30),(.76,.25),(.94,.31),(1.04,.28),(1.075,.20)]
    points=[]
    cols=9
    for depth in (-.045,.045):
        for v,width in rows:
            for j in range(cols):
                u=width*(2*j/(cols-1)-1)
                points.append((u,v,-.24+.065*(u/.31)**2-.07*((v-.53)/.545)+depth))
    layer=len(rows)*cols
    faces=[]
    for row in range(len(rows)-1):
        for j in range(cols-1):
            q=row*cols+j
            faces.extend([(q,q+cols,q+cols+1,q+1),
                          (layer+q+1,layer+q+cols+1,layer+q+cols,layer+q)])
    boundary=list(range(cols)) + [r*cols+cols-1 for r in range(1,len(rows))]
    boundary += list(range(layer-2,layer-cols-1,-1)) + [r*cols for r in range(len(rows)-2,0,-1)]
    for i,a in enumerate(boundary):
        b=boundary[(i+1)%len(boundary)]
        faces.append((a,b,layer+b,layer+a))
    emit("Sculpted ergonomic chair back",points,faces,"dark_teal")
    item.molded("Chair shoulder cap",pt(0,1.07,-.31),(.49,.10,.19),"orange",angle,.04)
    item.molded("Chair cushion",pt(0,.46,.025),(.64,.14,.57),"slate",angle,.065)
    item.molded("Chair lumbar pad",pt(0,.68,-.165),(.46,.18,.095),"teal",angle,.075)
    for side in (-1,1):
        item.rod("Chair back suspension",pt(side*.10,.40,-.29),pt(side*.17,.87,-.345),.033,"ink",7)
        item.rod("Chair arm stalk",pt(side*.28,.44,-.12),pt(side*.31,.61,-.06),.028,"ink",7)
        item.molded("Chair arm pad",pt(side*.31,.635,.015),(.085,.065,.33),"ink",angle,.03)
    item.rod("Pedestal",pt(0,.10,0),pt(0,.40,0),.062,"galvanized",8)
    for i in range(5):
        a=i*math.tau/5
        u,w=.27*math.cos(a),.27*math.sin(a)
        item.rod("Caster base",pt(0,.16,0),pt(u,.085,w),.035,"ink",6)
        item.rod("Caster wheel",pt(u-.037,.065,w),pt(u+.037,.065,w),.06,"ink",8)
seat(chair,0,0)

meeting = kit("meeting_table")
meeting.box("Conference table",(0,.85,0),(2.20,.15,4.58),"ivory",taper=(-.02,-.01))
meeting.box("Conference table apron",(0,.75,0),(1.92,.09,4.28),"teal")
for z in (-1.71,1.71):
    meeting.box("Conference table pedestal",(0,.40,z),(1.12,.76,.24),"slate",taper=(.10,.08))
    stepped_plinth(meeting.mesh,"Conference table foot",(0,.06,z),1.26,.12,.36,"navy",flare=.03)
for x in (-1.48,1.48):
    for z in (-1.58,-.56,.56,1.58):
        seat(meeting,x,z,-math.copysign(math.pi/2,x))
for z in (-1.55,.28,1.3):
    meeting.box("Meeting notes",(.32,.93,z),(.45,.024,.33),"paper",z*.3)
instance("meeting_table","ConferenceTable",(0,0,-16.8),(3.56,1.1,4.55),impact="paper")

def desk(item,width=2.4):
    item.molded("Laminate work surface",(0,.855,0),(width,.145,.96),"ivory",radius=.065)
    item.box("Desk bumper rail",(0,.785,0),(width-.06,.055,.90),"teal")
    for x in (-width*.44,width*.44):
        # Open cast A-frame rather than a solid slab under each desk.
        for side in (-1,1):
            item.rod("Desk splayed frame",(x,.08,side*.35),(x,.77,side*.18),.064,"slate",8)
        item.molded("Desk sled foot",(x,.065,0),(.15,.11,.88),"navy",radius=.05)
        item.box("Desk upper joint",(x,.76,0),(.17,.13,.51),"teal")
    item.box("Cable tray",(0,.68,-.33),(width*.82,.20,.16),"teal")
    item.box("Document stack",(-width*.37,.936,.19),(.31,.032,.22),"paper")
    item.box("Note",(-width*.36,.958,.17),(.15,.013,.11),"gold",.16)
    item.box("Rolling three-drawer pedestal",(width*.36,.34,-.04),(.43,.66,.72),"slate",taper=(.03,.03))
    for y in (.17,.37,.56):
        item.box("Drawer face",(width*.36,y,.33),(.38,.172,.055),"carpet_dark")
        item.box("Inset drawer handle",(width*.36,y+.037,.368),(.14,.042,.034),"ink")
    item.box("Mouse mat",(.46,.938,.25),(.28,.024,.25),"dark_teal")
    item.rod("Wireless mouse",(.46,.956,.25),(.46,1.004,.25),.066,"slate",8,.050)
    item.rod("Steel travel mug",(-width*.43,.928,.35),(-width*.43,1.115,.35),.066,"galvanized",10,.060)
    item.rod("Travel mug lid",(-width*.43,1.113,.35),(-width*.43,1.135,.35),.070,"ink",10)
    seat(item,0,.93,math.pi)

def penguin(item,x,y,z,s):
    item.rod("Penguin belly silhouette",(x,y,z),(x,y+s*.72,z),s*.29,"ink",10,s*.22)
    item.rod("Penguin tummy",(x,y+s*.27,z+s*.14),(x,y+s*.27,z+s*.29),s*.205,"white",10)
    item.rod("Penguin head",(x,y+s*.62,z),(x,y+s*.93,z),s*.24,"ink",10,s*.16)
    item.box("Red scarf",(x,y+s*.59,z+s*.12),(s*.49,s*.105,s*.39),"red")
    for sign in (-1,1):
        item.box("White eye",(x+sign*s*.081,y+s*.76,z+s*.205),(s*.076,s*.092,s*.044),"white")
        item.box("Pupil",(x+sign*s*.077,y+s*.76,z+s*.231),(s*.034,s*.054,s*.013),"ink")
        item.box("Penguin foot",(x+sign*s*.13,y+s*.045,z+s*.16),(s*.17,s*.086,s*.24),"orange")
    item.box("Beak",(x,y+s*.67,z+s*.245),(s*.19,s*.085,s*.13),"gold")

def screen(item,x,y,z,w,h,kind):
    # Rounded front surround and a single lofted rear casing, without layered blocks.
    profile_shell(item.mesh,"Molded display rear shell",(x,y,z),[
        (-.245,rounded_profile(w*.58,h*.60,.07)),
        (-.18,rounded_profile(w*.84,h*.90,.095)),
        (-.055,rounded_profile(w+.10,h+.10,.075)),
        (.005,rounded_profile(w+.10,h+.10,.075)),
    ],"teal")
    for vy in (-.055, .015, .085):
        item.box("Display rear vent",(x,y+vy,z-.249),(w*.36,.022,.018),"ink")
    # A ring with a real recessed glass opening, rather than a solid front slab.
    outer=rounded_profile(w+.11,h+.11,.075)
    inner=rounded_profile(w+.012,h+.012,.028)
    points=[(x+u,y+v,z+depth) for depth,loop in ((.035,outer),(.081,outer),(.081,inner),(.018,inner)) for u,v in loop]
    n=len(outer)
    faces=[]
    for ring in range(3):
        faces += [(ring*n+i,ring*n+(i+1)%n,(ring+1)*n+(i+1)%n,(ring+1)*n+i) for i in range(n)]
    item.mesh("Molded display surround",points,faces,"ivory")
    item.box("Display inner shadow",(x,y,z+.024),(w+.02,h+.02,.032),"ink")
    item.box("Lit display",(x,y,z+.041),(w,h,.018),"laptop_glass" if kind=="waterfall" else "display_glass")
    item.box("Power LED",(x+w*.42,y-h*.5-.022,z+.080),(.036,.022,.026),"code")
    f=z+.054
    if kind=="code":
        for row in range(8):
            indent=(0,1,1,2,2,1,2,0)[row]
            a=x-w*.42+indent*w*.095
            v=y+h*(.34-row*.094)
            for word in range(2+row%2):
                length=w*(.14+((row+word*3)%4)*.043)
                item.box("Syntax token",(a+length*.5,v,f),(length,h*.038,.011),
                         ("code","screen","lilac","gold")[(row+word)%4])
                a += length+w*.045
    elif kind=="waterfall":
        for i in range(5):
            a=x+w*(-.33+i*.165)
            v=y+h*(.30-i*.146)
            item.box("Waterfall stage",(a,v,f),(w*.23,h*.12,.013),("screen","blue","code","lilac","gold")[i])
            if i<4:
                item.box("Waterfall connector",(a+w*.10,v-h*.091,f),(w*.025,h*.105,.012),"white")
    else:
        for i in range(6):
            h_bar=h*(.17+i*.105)
            item.box("Revenue growth bar",(x+w*(-.36+i*.143),y-h*.38+h_bar*.5,f),(w*.101,h_bar,.013),"code")
        for i in range(5):
            a=(x+w*(-.36+i*.143),y+h*(-.17+i*.105),f+.009)
            b=(a[0]+w*.143,a[1]+h*.105,a[2])
            item.rod("Ascending revenue line",a,b,.012,"gold",5)

programmer = kit("programmer")
pm = kit("project_manager")
executive = kit("executive")
for item in (programmer,pm,executive):
    desk(item,3.1 if item==executive else 2.4)
programmer.rod("Monitor arm clamp and riser",(0,.93,-.36),(0,1.35,-.36),.064,"slate",8)
for x in (-.70,0,.70):
    if x:
        programmer.rod("Articulated display arm",(0,1.26,-.36),(x,1.26,-.36),.042,"slate",7)
    programmer.box("Monitor arm mounting plate",(x,1.27,-.324),(.14,.16,.075),"navy")
    screen(programmer,x,1.28,-.26,.61,.39,"code")
programmer.box("Mechanical keyboard",(0,.958,.21),(.64,.065,.23),"ink")
for x in range(-6,7):
    for z in range(3):
        programmer.box("Keyboard key",(x*.043,1.001,.145+z*.059),(.034,.022,.044),"carpet_dark")
penguin(programmer,-.99,.925,-.05,.26)
programmer.box("Link boots",(.98,.955,-.12),(.14,.065,.083),"wood")
programmer.box("Link tunic",(.98,1.05,-.12),(.135,.15,.094),"green")
programmer.box("Link hair",(.98,1.16,-.11),(.14,.09,.1),"gold")
programmer.rod("Pointed green cap",(.98,1.18,-.11),(.98,1.24,-.18),.077,"leaf",6,.012)
programmer.box("Link shield",(1.04,1.063,-.045),(.11,.13,.039),"blue",.23)
programmer.box("Link sword",(.891,1.08,-.07),(.025,.23,.026),"white")
pm.box("Notebook computer keyboard",(0,.957,.025),(.78,.045,.54),"slate")
screen(pm,0,1.205,-.22,.73,.44,"waterfall")
pm.box("Laptop docking station",(.47,.957,-.30),(.25,.059,.20),"navy")
pm.rod("Dock connection lead",(.41,.974,-.21),(.34,.974,-.14),.015,"ink",6)
pm.box("Sports car body",(.79,.99,.01),(.45,.095,.22),"red",.11)
pm.box("Sports car canopy",(.77,1.066,.01),(.24,.075,.17),"screen_dark",.11)
for x in (.65,.91):
    pm.rod("Sports car axle", (x,.964,-.118),(x,.964,.133),.057,"ink",10)
pm.box("Meeting notebook",(-.51,.946,.28),(.27,.047,.22),"lilac",.23)
pm.box("Notebook page block",(-.51,.968,.28),(.25,.022,.20),"paper",.23)
pm.box("Employee badge",(-.76,.941,-.14),(.125,.013,.20),"screen",.42)
pm.rod("Employee badge lanyard",(-.76,.946,-.21),(-.51,.95,-.30),.014,"blue",6)
programmer.rod("Headphone stand",(.86,.92,.27),(.86,1.14,.27),.034,"slate",8)
for dx in (-.082,.082):
    programmer.rod("Headphone ear cup",(.86+dx,1.05,.27),(.86+dx,1.11,.27),.048,"ink",8)
programmer.rod("Padded headset band",(.78,1.137,.27),(.94,1.137,.27),.027,"ink",7)
executive.box("Tablet kickstand",(.26,1.018,-.19),(.42,.17,.16),"slate")
screen(executive,.26,1.205,-.07,.69,.47,"revenue")

def lunch_variant(station):
    item=kit(station.name+"_lunch")
    item.parts.extend(station.parts)
    for obj in station.collection.objects:
        item.collection.objects.link(obj.copy())
    x,y,z=-.82,.92,-.29
    item.box("Kraft takeaway bag",(x,y+.176,z),(.31,.35,.225),"card")
    item.box("Folded paper gusset",(x,y+.351,z),(.31,.065,.16),"ivory")
    item.box("Red printed bag panel",(x,y+.155,z+.114),(.246,.15,.013),"red")
    for offset in (-.045,.045):
        arc=[(x+offset+.045*math.cos(i*math.pi/8),
              y+.120+.071*math.sin(i*math.pi/8),z+.124) for i in range(9)]
        for start,end in zip(arc,arc[1:]):
            item.rod("Gold arch print",start,end,.008,"gold",5)
    x,z=.60,.29
    item.box("Opened burger wrapper",(x,y+.008,z),(.41,.016,.31),"paper",.17)
    item.rod("Toasted bottom bun",(x,y+.016,z),(x,y+.054,z),.112,"amber",10,.137)
    item.rod("Beef patty",(x,y+.055,z),(x,y+.080,z),.130,"coffee",10)
    item.box("Cheese corner",(x,y+.081,z),(.196,.015,.196),"gold",.34)
    item.rod("Lettuce layer",(x,y+.087,z),(x,y+.102,z),.135,"leaf",10)
    item.rod("Burger bun dome",(x,y+.103,z),(x,y+.159,z),.135,"amber",12,.090)
    for dx,dz in ((-.045,.02),(.008,-.044),(.049,.033),(-.013,.051),(.036,-.018)):
        item.box("Sesame seed",(x+dx,y+.162,z+dz),(.020,.009,.008),"ivory",dx*12)
    return item.name

lunch_assets={item.name:lunch_variant(item) for item in (programmer,pm)}
programmer.box("Takeaway lunch bag",(-.82,1.025,-.30),(.22,.215,.16),"card")
programmer.box("Folded takeaway bag top",(-.82,1.146,-.30),(.217,.043,.089),"ivory")

partition_assets=("partition","partition_low","partition_storage")
partition_wings=((1.02,1.18,.13),(.74,.88,.13),(.65,1.30,.42))
for variant,asset in enumerate(partition_assets):
    partition=kit(asset)
    # Recessed frame spine + 3 modular molded acoustic panels + chunky top coping + splayed feet
    partition.box("Partition spine core",(0,.96,0),(5.04,1.34,.085),"navy")
    stepped_plinth(partition.mesh,"Partition base rail",(0,.14,0),5.06,.24,.175,"slate",flare=.022)
    for bay_x in (-1.64, 0.0, 1.64):
        partition.molded("Teal fabric baffle",(bay_x,1.00,0),(1.54,1.20,.145),"teal",radius=.18)
    partition.molded("Acoustic cap",(0,1.66,0),(5.18,.10,.195),"ivory",radius=.045)
    for x in (-2.46,-0.82,0.82,2.46):
        partition.box("Baffle post",(x,.86,0),(.105,1.68,.195),"slate",taper=(.04,.04))
        if abs(x) > 2.0:
            stepped_plinth(partition.mesh,"Baffle post foot",(x,.055,0),.18,.11,.36,"navy",flare=.025)
    for x in (-1.75,-.72,.83,1.82):
        for side in (-1,1):
            partition.box("Pinned sprint note",(x,1.46,side*.082),(.18,.21,.016),"gold" if x<0 else "paper",.09)
    for x in (-2.49,2.49):
        if variant==0:
            partition.box("Privacy wing core",(x,.82,0),(.09,1.52,2.92),"navy")
            stepped_plinth(partition.mesh,"Wing base plinth",(x,.09,0),.24,.18,2.98,"slate",flare=.03)
            for bz in (-.73, .73):
                partition.molded("Privacy wing lower panel",(x,.64,bz),(1.34,.86,.16),"dark_teal",math.pi/2,.16)
                partition.molded("Wing inset accent",(x,.64,bz),(1.12,.62,.185),"teal",math.pi/2,.14)
                partition.box("Frosted upper window",(x,1.38,bz),(.08,.42,1.32),"screen")
            partition.box("Wing window sill",(x,1.14,0),(.24,.095,2.98),"ivory")
            for z in (-1.45,0.0,1.45):
                partition.box("Frosted screen stile",(x,.85,z),(.23,1.60,.13),"slate",taper=(.05,.04))
                if abs(z) > 1.0:
                    stepped_plinth(partition.mesh,"Wing end foot",(x,.06,z),.34,.12,.26,"navy",flare=.03)
                    partition.box("Wing post cap",(x,1.67,z),(.25,.12,.16),"gold")
            segmented_coping(partition.mesh,"Window frame rail",(x,1.63,0),.25,.11,3.00,"ivory",seg_len=1.48,gap=.026)
        elif variant==1:
            # Continuous molded wing with rounded shoulders, without the old
            # square stiles breaking its outline into six small blocks.
            partition.molded("Low wing shell",(x,.67,0),(2.98,1.12,.23),"violet",math.pi/2,.23)
            stepped_plinth(partition.mesh,"Low wing plinth",(x,.09,0),.24,.18,2.98,"slate",flare=.03)
            for bz in (-.72,.72):
                partition.molded("Low wing cushion panel",(x,.66,bz),(1.30,.77,.255),"lilac",math.pi/2,.19)
            for z in (-1.30,1.30):
                partition.molded("Low wing end sleeve",(x,.35,z),(.30,.56,.22),"slate",radius=.08)
                stepped_plinth(partition.mesh,"Low wing end foot",(x,.06,z),.34,.12,.26,"navy",flare=.03)
            # Ivory rail follows the rounded shoulder profile.
            for side in (-1,1):
                for j in range(4):
                    a0=j*math.pi/8; a1=(j+1)*math.pi/8
                    partition.rod("Rounded wing cap",(x,1.00+.23*math.cos(a0),side*(1.26+.23*math.sin(a0))),
                                  (x,1.00+.23*math.cos(a1),side*(1.26+.23*math.sin(a1))),.043,"ivory",6)
            partition.rod("Continuous wing cap",(x,1.23,-1.26),(x,1.23,1.26),.043,"ivory",8)
        else:
            stepped_plinth(partition.mesh,"Cabinet plinth",(x,.08,0),.48,.16,2.98,"slate",flare=.03)
            partition.molded("End-of-row storage cabinet",(x,.68,0),(2.92,1.14,.42),"dark_teal",math.pi/2,.19)
            segmented_coping(partition.mesh,"Laminate cabinet worktop",(x,1.31,0),.50,.11,3.00,"ivory",seg_len=1.48,gap=.026)
            for z in (-1.04,-.36,.36,1.04):
                face=x+math.copysign(.224,x)
                partition.box("Locker door reveal",(face,.70,z),(.058,.96,.59),"teal")
                partition.box("Inset locker pull",(face+math.copysign(.036,x),1.01,z),(.044,.095,.19),"gold")

leaf = kit("shade_leaf")
leaf.rod("Leaf clamp stem",(0,0,0),(0,1.52,0),.045,"green",8)
outline=[(0,1.64,-.19),(.49,1.68,.06),(.92,1.66,.55),(.92,1.62,1.05),
         (.49,1.59,1.52),(0,1.56,1.77),(-.49,1.59,1.52),(-.92,1.62,1.05),
         (-.92,1.66,.55),(-.49,1.68,.06)]
for i, point in enumerate(outline):
    next_point=outline[(i+1)%len(outline)]
    leaf.mesh("Leaf facet",[(0,1.81,.68),point,next_point],[(0,1,2),(2,1,0)],"leaf" if i<5 else "green")
    if i%2==0:
        leaf.rod("Leaf vein",(0,1.82,.68),point,.015,"mint",5)

cot = kit("camp_cot")
cot.box("Canvas camp bed",(0,.37,0),(.83,.12,1.94),"mint")
for x in (-.4,.4):
    cot.rod("Camp bed rail",(x,.35,-.99),(x,.35,.99),.036,"slate",6)
    for z in (-.71,.71):
        cot.rod("Folding cot leg",(x,.07,z-.18),(x,.33,z+.18),.03,"slate",6)
        cot.rod("Crossed cot leg",(x,.07,z+.18),(x,.33,z-.18),.03,"slate",6)
penguin(cot,0,.43,-.55,.42)
cot.box("Folded blanket",(0,.455,.65),(.80,.06,.55),"violet")

for row,z in enumerate((-8,-2,4,10)):
    for col,x in enumerate((-14,0,14)):
        pod=f"{row}{col}"
        variant=(row+col)%len(partition_assets)
        center_y,wing_height,wing_width=partition_wings[variant]
        instance(partition_assets[variant],"Partition"+pod,(x,0,z),(5.16,1.7,.16),
                 sections=[[[end*2.49,center_y,0],[wing_width,wing_height,2.94]] for end in (-1,1)])
        for side in (-1,1):
            pos=x+side*1.25
            station="project_manager" if (row+col+side)%3==0 else "programmer"
            meal=(row,col,side) in ((0,2,-1),(1,0,-1),(2,1,1),(3,2,1))
            station_model=lunch_assets[station] if meal else station
            instance(station_model,("PM" if station=="project_manager" else "Programmer")+pod+("L" if side<0 else "R"),
                     (pos,0,z+.63),(2.39,.94,.95),impact="keys" if station=="programmer" else "paper",
                     sections=[[[0,1.2,-.22],[2.02,.54,.16]],[[0,.52,.85],[.60,1.0,.68]]])
            back_station="project_manager" if (row+col+side+1)%3==0 else "programmer"
            instance(back_station,"BackDesk"+pod+("L" if side<0 else "R"),
                     (pos,0,z-.63),(2.39,.94,.95),math.pi,
                     impact="keys" if back_station=="programmer" else "paper",
                     sections=[[[0,1.2,-.22],[2.02,.54,.16]],[[0,.52,.85],[.60,1.0,.68]]])
        if (row+col)%2==0:
            instance("shade_leaf","Shade"+pod,(x-1.17,.74,z+.30),(0,0,0),
                     impact="leaf",sections=[[[0,1.65,.72],[1.83,.19,1.90]]])
        if (row,col) in ((0,0),(1,2),(2,1),(3,0)):
            instance("camp_cot","CampCot"+pod,(x+3.37,0,z+.51),(.90,.52,2.02))
for i,x in enumerate((-17,17)):
    instance("executive",f"Executive{i}",(x,0,-17.9),(3.1,1.43,.99),impact="paper")
    instance("chair",f"VisitorChair{i}",(x+.68,0,-15.7),(.64,1.02,.64))

pantry = kit("pantry_counter")
pantry.box("Pantry teal cabinetry",(0,.48,0),(4.7,.96,.94),"teal")
pantry.box("Laminated countertop",(0,1,0),(4.8,.13,1.0),"ivory")
for x in (-1.9,-1,-.1,.8,1.7):
    pantry.box("Cabinet pull",(x,.75,.5),(.24,.043,.067),"gold")
pantry.box("Espresso machine",(-1.35,1.41,-.09),(1.13,.72,.67),"navy")
pantry.box("Espresso brew recess",(-1.35,1.23,.269),(.91,.31,.036),"ink")
pantry.box("Espresso brushed front",(-1.35,1.52,.273),(1.11,.29,.05),"slate")
pantry.box("Espresso silver lip",(-1.35,1.41,.309),(1.12,.06,.10),"carpet_dark")
pantry.box("Espresso drip tray",(-1.35,1.09,.40),(1.13,.065,.31),"slate")
for x in (-1.74,-.97):
    pantry.box("Espresso controls",(x,1.58,.307),(.07,.079,.025),"gold")
pantry.box("Espresso steam display",(-1.35,1.62,.293),(.40,.085,.02),"screen")
for x in (-1.6,-1.12):
    pantry.rod("Coffee spout",(x,1.39,.28),(x,1.29,.39),.047,"ink",8)
    pantry.rod("Coffee cup",(x,1.07,.36),(x,1.24,.36),.087,"ivory",9,.104)
    pantry.rod("Coffee surface",(x,1.242,.36),(x,1.252,.36),.083,"coffee",9)
pantry.box("Stainless sink rim",(1.18,1.074,0),(1.02,.026,.68),"carpet_dark")
pantry.box("Recessed sink",(1.18,1.091,0),(.83,.012,.52),"screen_dark")
pantry.rod("Faucet stem",(1.18,1.08,-.34),(1.18,1.43,-.34),.039,"carpet_dark",8)
pantry.rod("Faucet bend",(1.18,1.43,-.34),(1.18,1.43,-.05),.039,"carpet_dark",8)
pantry.rod("Faucet head",(1.18,1.43,-.05),(1.18,1.36,-.05),.042,"carpet_dark",8)
instance("pantry_counter","CoffeeAndSink",(-20.5,0,13.9),(4.80,1.79,1.0),impact="coffee")

snacks = kit("snack_rack")
for x in (-1.44,1.44):
    snacks.box("Snack rack post",(x,1.02,0),(.09,2.04,.64),"slate")
snacks.box("Rack back",(0,1.02,-.32),(2.89,2.04,.08),"teal")
for row,y in enumerate((.21,.72,1.23,1.73)):
    snacks.box("Snack shelf",(0,y,0),(2.92,.092,.72),"ivory")
    for i in range(7):
        if (i+row*2)%7==6:continue
        x=-1.16+i*.38
        snacks.box("Potato chip bag",(x,y+.17,.09),(.25,.24,.14),("orange","lilac","blue","green","red")[(i+row)%5])
        snacks.box("Bag crimp seal",(x,y+.29,.09),(.25,.047,.047),"white")
        snacks.rod("Chip illustration",(x,y+.16,.17),(x,y+.16,.181),.069,"gold",6)
instance("snack_rack","ChipRack",(-24.25,0,13.4),(2.92,2.05,.74),math.pi/2,impact="chips")
instance("meeting_table","SnackTable",(-21.6,0,18.3),(3.56,1.1,4.55),math.pi/2,impact="paper")

plant = kit("planter")
plant.rod("Ceramic pot",(0,0,0),(0,.56,0),.26,"ivory",8,.35)
plant.rod("Soil",(0,.554,0),(0,.572,0),.31,"coffee",8)
for i in range(7):
    a=i*math.tau/7
    direction=Vector((math.cos(a),0,math.sin(a)))
    tangent=Vector((-direction.z,0,direction.x))
    start=Vector((0,.50,0))
    elbow=Vector((0,.96+(i%3)*.06,0))+direction*.29
    tip=Vector((0,1.08+(i%2)*.13,0))+direction*.54
    plant.rod("Plant stem",start,elbow,.023,"green",5)
    verts=[elbow-direction*.18,elbow+tangent*.13,tip,elbow-tangent*.13,elbow+Vector((0,.10,0))]
    faces=[(j,(j+1)%4,4) for j in range(4)]
    plant.mesh("Plant leaf",verts,faces+[tuple(reversed(face)) for face in faces],"leaf" if i%2 else "green")
for i,(x,z) in enumerate(((-24.5,-12.3),(24.5,-12.3),(-25,7),(25,7),(-6.8,19.5),(6.8,19.5),
                          (-11.0,-7.7),(3.0,4.1),(11.2,10.4))):
    instance("planter",f"Planter{i}",(x,0,z),(.72,1.22,.72),impact="leaf")

cooler = kit("water_cooler")
cooler.molded("Water cooler lower cabinet",(0,.30,0),(.63,.60,.59),"ivory",radius=.11)
cooler.molded("Water cooler crown",(0,.96,0),(.63,.14,.59),"ivory",radius=.06)
cooler.molded("Dispenser recess back",(0,.75,-.15),(.48,.34,.19),"navy",radius=.07)
for side in (-1,1):
    cooler.molded("Dispenser side cheek",(side*.267,.76,0),(.096,.34,.59),"ivory",radius=.04)
cooler.molded("Drip tray",(0,.59,.215),(.47,.055,.28),"galvanized",radius=.025)
for x,color in ((-.13,"blue"),(.13,"red")):
    cooler.box("Hot or cold tap",(x,.84,.08),(.104,.071,.105),color)
    cooler.rod("Tap spout",(x,.83,.13),(x,.77,.13),.028,"galvanized",7)
cooler.rod("Blue refill bottle neck",(0,.96,0),(0,1.14,0),.095,"blue",10)
cooler.rod("Refill bottle shoulder",(0,1.14,0),(0,1.29,0),.12,"screen",10,.236)
cooler.rod("Refill bottle body",(0,1.28,0),(0,1.73,0),.236,"laptop_glass",10,.218)
for y in (1.34,1.52,1.65):
    cooler.rod("Molded bottle rib",(0,y,0),(0,y+.03,0),.238,"screen",10)
cooler.rod("Stacked paper cups",(.22,1.02,.26),(.22,1.25,.26),.059,"paper",9,.073)
for i,(x,z,angle) in enumerate(((-24.1,10.8,math.pi/2),(24.1,-4.3,-math.pi/2),(9.35,13.9,0))):
    instance("water_cooler",f"WaterCooler{i}",(x,0,z),(.70,1.75,.77),angle,impact="water")

copy = kit("copy_station")
copy.molded("Printer lower casting",(0,.40,-.015),(1.44,.78,.74),"slate",radius=.13)
copy.molded("Copier rear bridge",(0,1.03,-.22),(1.41,.50,.32),"ivory",radius=.12)
for side in (-1,1):
    copy.molded("Copier side pier",(side*.60,1.00,.09),(.21,.48,.53),"ivory",radius=.08)
copy.molded("Scanner crown",(0,1.28,0),(1.41,.19,.76),"ivory",radius=.08)
profile_shell(copy.mesh,"Molded document feeder",(0,0,-.10),[
    (-.27,rounded_profile(1.19,.12,.05,y=1.40)),
    (.08,rounded_profile(1.19,.12,.05,y=1.40)),
    (.27,rounded_profile(1.02,.065,.025,y=1.37)),
],"carpet_dark")
copy.molded("Recessed output bed",(0,.82,.095),(1.03,.065,.58),"ink",radius=.03)
copy.box("Paper inside output well",(.16,.861,.17),(.41,.021,.30),"paper")
copy.molded("Copier control console",(-.48,1.27,.37),(.32,.18,.12),"slate",radius=.05)
copy.molded("Copier control display",(-.48,1.28,.435),(.25,.105,.015),"screen",radius=.025)
for y in (.17,.40,.63):
    copy.molded("Copy paper drawer",(0,y,.372),(1.25,.20,.067),"galvanized",radius=.065)
    copy.molded("Inset drawer grip",(0,y+.025,.408),(.30,.045,.018),"slate",radius=.02)
copy.box("Paper carton",(-.98,.24,.05),(.43,.48,.51),"card")
copy.box("Carton tape",(-.98,.486,.05),(.086,.018,.52),"paper")
for i,(x,z) in enumerate(((-7.45,6.15),(7.65,-5.95))):
    instance("copy_station",f"CopyStation{i}",(x,0,z),(1.51,1.48,.95),impact="paper",
             sections=[[[-.98,.24,.05],[.43,.48,.51]]])

huddle = kit("huddle_table")
huddle.box("Standing huddle counter",(0,1.02,0),(2.28,.13,.88),"ivory")
for x in (-.92,.92):
    huddle.box("Standing counter leg",(x,.49,0),(.16,.98,.73),"dark_teal")
huddle.box("Notebook from the stand-up meeting",(-.56,1.10,.12),(.34,.03,.25),"violet",.21)
for i in range(4):
    huddle.box("Sticky note cluster",(i*.23-.27,1.097,-.19),(.17,.018,.16),"gold" if i%2 else "pink",.07*i)
huddle.rod("Takeaway coffee cup",(.77,1.08,.13),(.77,1.24,.13),.064,"card",8,.075)
huddle.rod("Takeaway cup lid",(.77,1.24,.13),(.77,1.26,.13),.078,"ink",8)
huddle.box("Low cable brace",(0,.28,-.28),(1.85,.14,.10),"slate")
for i,(x,z) in enumerate(((-7.1,11.4),(7.35,-2.95))):
    instance("huddle_table",f"HuddleTable{i}",(x,0,z),(2.30,1.27,.90),impact="paper")

storage = kit("locker")
storage.box("Employee locker bank",(0,.96,0),(1.87,1.92,.54),"slate")
for i in range(4):
    x=(i-1.5)*.45
    storage.box("Locker door",(x,.99,.29),(.424,1.77,.058),"teal" if i%2==0 else "galvanized")
    for y in (1.53,1.62,1.71):
        storage.box("Locker ventilation slot",(x,y,.327),(.23,.026,.014),"ink")
    storage.box("Nameplate without text",(x,1.28,.326),(.18,.063,.016),"paper")
    storage.box("Locker handle",(x+.13,.99,.347),(.061,.23,.053),"navy")
storage.box("Delivery parcel",(0,2.055,-.02),(.49,.25,.37),"card")
storage.box("Parcel tape",(0,2.184,-.02),(.102,.018,.38),"paper")
for i,(x,z,angle) in enumerate(((-19.5,-8.4,math.pi/2),(19.45,-2.9,-math.pi/2),(19.45,7.35,-math.pi/2))):
    instance("locker",f"LockerBank{i}",(x,0,z),(1.87,2.19,.62),angle,impact="paper")

layout.update({
    "fixed": ["architecture","building_services","city","reception","rooms"],
    "start": [7,.05,14.7],
    "opening": [[7,.05,7.8],[-6,.05,7.4],[22,.05,7.2],[-21,.05,.8],
                [7,.05,-5],[-6,.05,-9.7],[17.7,.05,11.1],[-5,.05,-2]],
    "spawns": [[-22,.05,6],[-22,.05,0],[-22,.05,-8],[-24,.05,-16],
               [22,.05,12],[22,.05,6],[22,.05,0],[22,.05,-8],[24,.05,-16],
               [7,.05,-9.4],[-7,.05,-9.4],[-6,.05,13.5],[7,.05,1.1],[4,.05,-15.5]],
    "respawns": [[7,.05,14.7],[-21,.05,9],[21,.05,11],[22,.05,-10],
                 [-22,.05,-10],[-6,.05,4],[6,.05,-6]],
    "route": [[-22,.05,-9],[22,.05,-9],[-22,.05,10],[22,.05,10],
              [0,.05,18.4],[3.85,.05,-15.5],[-20,.05,15.7],[0,.05,-10.55],
              [6.6,.05,1.1],[-6.5,.05,1.1],[2.1,.05,6.6],[-2.1,.05,6.6]],
    "barrels": [[10,.05,3.1],[-18,.05,-3],[18,.05,-10.3]],
})

# The exports share a local origin. The editable file arranges their collections
# in a separate component yard so individual workstations remain easy to edit.
total_tris = 0
for item in kits.values():
    total_tris += item.export()
for index,item in enumerate(kits.values()):
    if item.name in layout["fixed"]:
        continue
    offset = Vector((34+(index%5)*7, -42-(index//5)*7, 0))
    for obj in item.collection.objects:
        obj.location += offset
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"art_source/bb_office.blend"),compress=True)
(ROOT/"tools/maps/bb_office_layout.json").write_text(json.dumps(layout,indent=2)+"\n")
print("BB_OFFICE_KIT_READY", len(kits), "kits,", total_tris, "exported kit triangles")
