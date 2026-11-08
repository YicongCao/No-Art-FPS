"""Build the Night Studio's editable Blender kit, GLBs and matching collider layout."""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/models/studio"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

COLORS = {
    "ink": "202945", "navy": "283753", "slate": "415374", "blue": "3658C5",
    "cobalt": "2446AE", "cyan": "82CFFE", "violet": "764D89", "lilac": "AB77AE",
    "gold": "F6C35B", "amber": "D3903D", "ivory": "FFF0D5", "floor": "D9C6AE",
    "tile": "B9AA9B", "red": "BF5859", "pink": "E48B84", "green": "48816F",
    "mint": "82B9A3", "dark_teal": "305963", "teal": "477B82", "leaf": "72A164",
    "card": "D8A86B", "paper": "FFF9E9", "screen": "92C4DF", "tally": "FF4D4B",
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
    shader.inputs["Roughness"].default_value = .87
    if name in ("lamp", "tally", "screen", "cyan"):
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
        self.parts.append((points, faces, color))
        origin = sum((Vector(v) for v in points), Vector()) / len(points)
        mesh = bpy.data.meshes.new(label)
        mesh.from_pydata([xyz(Vector(v) - origin) for v in points], [], faces)
        mesh.materials.append(materials[color])
        obj = bpy.data.objects.new(label, mesh)
        obj.location = xyz(origin)
        self.collection.objects.link(obj)

    def box(self, label, center, size, color, angle=0):
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

    def export(self):
        points, faces, colors = [], [], []
        for verts, polys, color in self.parts:
            faces.extend(tuple(len(points)+i for i in face) for face in polys)
            points.extend(xyz(p) for p in verts)
            colors.extend([color]*len(polys))
        mesh = bpy.data.meshes.new(self.name)
        mesh.from_pydata(points, [], faces)
        keys = list(dict.fromkeys(colors))
        for key in keys:
            mesh.materials.append(materials[key])
        for polygon, color in zip(mesh.polygons, colors):
            polygon.material_index = keys.index(color)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.export_scene.gltf(filepath=str(OUT/f"{self.name}.glb"),export_format="GLB",use_selection=True)
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(mesh)


layout = {"boxes": [], "ramps": [], "props": [], "spots": []}
kits = {}
scene = bpy.context.scene


def kit(name, fixed=False):
    item = kits[name] = Kit(name)
    if fixed:
        scene.collection.children.link(item.collection)
    return item


def solid(item, label, center, size, color):
    item.box(label, center, size, color)
    layout["boxes"].append([center, size])


def wall(label, center, size, color, baffles=()):
    x,y,z = center
    w,h,d = size
    dimensions = "_".join(str(round(value*100)) for value in size)
    asset = f"wall_{label.lower()}" if baffles else f"wall_{color}_{dimensions}"
    if asset not in kits:
        item = kit(asset)
        item.box("Wall", (0,h/2,0), size, color)
        # Extend the trim across the thickness, leaving adjacent panels flush.
        trim_x,trim_z = (.045,0) if d>w else (0,.045)
        item.box("Dark baseboard",(0,.11,0),(w+trim_x,.22,d+trim_z),"navy")
        item.box("Header trim",(0,h-.12,0),(w+trim_x,.21,d+trim_z),"slate")
        for offset in baffles:
            item.box("Acoustic sound baffle",(offset,3.67,-.26),(2.2,2.8,.14),"slate")
            item.box("Baffle lower edge",(offset,2.33,-.37),(2.2,.09,.09),"violet")
    instance(asset,label,(x,y-h/2,z),size,structural=True,section=True)


def door(item, x, z, span=3.3):
    for side in (-1,1):
        item.box("Door jamb",(x+side*span/2,1.55,z),(.16,3.1,.43),"slate")
    item.box("Portal header",(x,3.12,z),(span+.2,.23,.46),"navy")
    item.box("Red studio light",(x,3.26,z+.25),(.48,.12,.065),"tally")


def rails(item, x1, x2, z, y=2.7):
    for h in (.54,1.05):
        item.rod("Guard rail",(x1,y+h,z),(x2,y+h,z),.045,"gold",6)
    for i in range(math.ceil((x2-x1)/1.6)+1):
        x = min(x2,x1+i*1.6)
        item.rod("Rail upright",(x,y,z),(x,y+1.05,z),.052,"navy",6)
    layout["boxes"].append([((x1+x2)/2,y+.57,z),(x2-x1,1.18,.10)])


def instance(asset, label, at, size, rotation=0, paper=False, structural=False, shoot_only=False, section=False):
    obj = bpy.data.objects.new(label, None)
    obj.instance_type = "COLLECTION"
    obj.instance_collection = kits[asset].collection
    obj.location = xyz(at)
    obj.rotation_euler.z = rotation
    scene.collection.objects.link(obj)
    layout["props"].append(dict(asset=asset,name=label,at=at,size=size,angle=rotation,
                                paper=paper,structural=structural,shoot_only=shoot_only,section=section))


# Warm stage floor, perimeter, back corridor and ceiling. All dimensions are in Godot axes.
shell = kit("shell", True)
solid(shell,"Foundation",(0,-.25,0),(44,.5,34),"floor")
for center,size,color in [
    ((-16,.012,-7),(11.4,.02,13.2),"slate"),((-16,.012,8.7),(11.4,.02,14.7),"ivory"),
    ((16.4,.012,-7),(10.8,.02,13.2),"dark_teal"),((16.5,.012,8.6),(10.8,.02,14.7),"tile"),
    ((0,.012,-14.5),(43.7,.02,4.9),"slate"),
]:
    shell.box("Zoned flooring",center,size,color)
for side,z_label,x_label in ((-1,"North","West"),(1,"South","East")):
    for i in range(4):
        center = -16.5+i*11
        baffles = [x-center for x in range(-9,10,3) if side==1 and center-5.5<=x<center+5.5]
        wall(f"{z_label}Wall{i}",(center,4.2,side*17),(11,8.4,.38),"navy",baffles)
        wall(f"{x_label}Wall{i}",(side*22,4.2,-12.75+i*8.5),(.38,8.4,8.5),"navy")
    layout["boxes"].append([(0,4.2,side*17.32),(44.8,8.4,.14)])
    layout["boxes"].append([(side*22.32,4.2,0),(.14,8.4,34.8)])
for x in (-10.64,10.64):
    for z in (-9.9,2.2,12.3):
        shell.box("Soundstage service trim",(x,1.05,z),(.13,.24,1.4),"slate")
ceiling = kit("ceiling", True)
solid(ceiling,"High soundstage roof",(0,8.44,0),(44,.35,34),"ink")
for z in range(-15,17,5):
    ceiling.box("Blue roof beam",(0,8.12,z),(43,.32,.24),"blue")
for x in (-20,-10,10,20):
    for z in (-16.5,15.8):
        shell.box("Column",(x,4,z),(.36,8,.42),"slate")
for x in (-16.5,16.5):
    ceiling.box("Suspended side-room ceiling",(x,4.32,0),(10.75,.21,33.5),"slate")
    for z in range(-15,16,3):
        ceiling.box("Suspended ceiling grid",(x,4.206,z),(10.75,.026,.031),"navy")
    for dx in (-3,0,3):
        ceiling.box("Suspended ceiling grid",(x+dx,4.205,0),(.032,.026,33.5),"navy")
    for z in (-12,-5,5,12):
        ceiling.box("Utility luminaire",(x,4.19,z),(3,.12,.44),"navy")
        ceiling.box("Warm diffuser",(x,4.11,z),(2.8,.09,.34),"lamp")

for x in (-11,11):
    for z, length in [(-10.4,4.4),(-3.3,2.2),(2.0,2.6),(11.5,5.2)]:
        wall(f"Acoustic{int(x+11)}_{int((z+11)*10)}",(x,2.1,z),(.34,4.2,length),"violet" if x<0 else "slate")
    for z in (-6.5, -.75, 6.0):
        shell.box("Portal header",(x,3.24,z),(.48,.24,3.0),"navy")
        shell.box("Portal pilot",(x+(.25 if x<0 else -.25),3.39,z),(.07,.15,.48),"tally")
for x in (-17.8,17.8):
    wall("NewsroomWall" if x<0 else "ArchiveWall",(x,2.0,1),(8.15,4,.33),"green" if x<0 else "dark_teal")
for x in (-14.1,14.1):
    door(shell,x,1,2.8)

# Central stage, technical walkway and risers. Broad colliders follow the stage floor and ramps.
stage = kit("stage", True)
solid(stage,"Stage deck",(0,.14,-5.1),(14.4,.28,6.8),"gold")
stage.box("Ivory stage top",(0,.285,-5.1),(14.25,.02,6.65),"ivory")
stage.box("Lower fascia",(0,.09,-1.67),(14.4,.12,.10),"amber")
stage.box("Gold apron",(0,.044,-1.55),(13.4,.085,.23),"gold")
apron = [(-6.7,.28,-1.72),(6.7,.28,-1.72),(6.7,0,-.65),(-6.7,0,-.65)]
stage.mesh("Sloped stage entrance",apron,[(3,2,1,0)],"gold")
layout["ramps"].append(apron)
for i in range(14):
    stage.box("Stage apron bulb",(-6.48+i*.99,.15,-1.61),(.16,.10,.055),"lamp")
for x in (-6.65,6.65):
    stage.box("Purple side panel",(x,1.83,-7.85),(1.15,3.1,.30),"violet")
    stage.box("Luminous panel edge",(x+.46,1.83,-7.66),(.065,3,.05),"gold")
    stage.box("Marquee leg",(x,1.68,-7.8),(.5,2.8,.44),"gold")
for i in range(17):
    angle = i*math.pi/16
    at = (6.65*math.cos(angle),3.06+2.31*math.sin(angle),-7.8)
    if i:
        stage.rod("Faceted marquee arch",previous,at,.28,"gold",6)
    stage.rod("Marquee bulb",at,(at[0],at[1],at[2]+.29),.091,"lamp",8)
    previous = at
planter = kit("stage_planter")
planter.rod("Planter",(0,0,0),(0,.48,0),.28,"amber",8,.38)
planter.rod("Plant trunk",(0,.48,0),(0,1.98,0),.082,"card",7)
for i in range(6):
    a = i*math.tau/6
    tip = (math.cos(a)*.76,1.65,math.sin(a)*.76)
    planter.rod("Stylized plant frond",(0,1.99,0),tip,.16,"leaf",5,.035)
for label,x in (("Left",-5.55),("Right",5.75)):
    instance("stage_planter",f"StagePlanter{label}",(x,.29,-5.78),(1.52,2.10,1.40),shoot_only=True)

access = kit("technical_access")
z0,z1,top = -3.55,3.55,2.62
left,right = -1.05,1.05
points = [(left,top,z0),(right,top,z0),(right,0,z1),(left,0,z1)]
# Match the authored collision slope and give it a solid underside to shoot.
access.mesh("Technical access ramp",points,[(3,2,1,0)],"slate")
bottom = [(x,y-.23,z) for x,y,z in points]
access.mesh("Ramp underside",bottom,[(0,1,2,3)],"slate")
for i in range(4):
    j = (i+1)%4
    access.mesh("Ramp edge",[points[i],points[j],bottom[j],bottom[i]],[(0,1,2,3)],"slate")
ramp_rails = []
for side in (left,right):
    for h in (.48,1.01):
        access.rod("Ramp railing",(side,top+h,z0),(side,h,z1),.046,"gold")
    for i in range(6):
        t = i/5
        z,y = z0+(z1-z0)*t,top*(1-t)
        access.rod("Ramp stanchion",(side,y,z),(side,y+1.04,z),.052,"navy",6)
    ramp_rails.append([(side,top,z0),(side,0,z1)])
for label,x in (("WestAccessRamp",-8.75),("EastAccessRamp",8.75)):
    instance("technical_access",label,(x,0,-6.55),(2.2,3.75,7.1),structural=True,section=True)
    layout["props"][-1].update(ramp=points,rails=ramp_rails)
solid(stage,"Lighting catwalk",(0,2.49,-11.25),(19.6,.26,2.3),"slate")
rails(stage,-9.78,9.78,-12.33,2.62)
rails(stage,-7.65,7.65,-10.13,2.62)
for x in (-9.5,-5.2,5.2,9.5):
    solid(stage,"Catwalk post",(x,1.18,-12.23),(.24,2.36,.24),"navy")

seats = kit("seat_row")
for i in range(7):
    x = (i-3)*1.15
    seats.box("Seat cushion",(x,.38,0),(.87,.16,.62),"red")
    seats.box("Seat back",(x,.67,.27),(.85,.55,.13),"pink")
    seats.box("Seat leg",(x,.16,0),(.18,.32,.36),"navy")
    seats.box("Armrest",(x+.49,.51,.02),(.078,.081,.51),"navy")
for row in range(3):
    z,y = 4.5+row*1.52,.14+row*.17
    solid(stage,"Seating riser",(2.45,y/2,z),(8.5,y,1.50),"violet")
    instance("seat_row",f"Seats{row}",(2.45,y,z),(7.86,.96,.67))
for z in (-.72,8.86):
    stage.box("Camera track",(-1,.023,z),(17,.035,.12),"navy")
    for x in range(-9,8):
        stage.box("Floor tape",(x,.044,z+.14),(.45,.009,.09),"gold")
for x,z in [(-3,1.4),(6.7,.3),(-5.3,5)]:
    stage.box("Cable crossover",(x,.033,z),(1.6,.065,.29),"navy")
    stage.box("Cable ramp stripe",(x,.069,z),(1.53,.009,.12),"gold")

# Ring and suspended barn-door lanterns.
rig = kit("lighting", True)
ring = [(8.25*math.cos(i*math.tau/20),-2.6+5.1*math.sin(i*math.tau/20)) for i in range(20)]
for i, (x,z) in enumerate(ring):
    a,b = ring[(i+1)%len(ring)]
    for y in (6.25,6.59):
        rig.rod("Oval truss chord",(x,y,z),(a,y,b),.071,"blue",6)
    rig.rod("Cross brace",(x,6.25,z),(a,6.59,b),.043,"blue",6)
    if i%4==0:
        rig.rod("Rig suspension",(x,6.6,z),(x,8.15,z),.046,"slate")
    if i%2==0:
        toward = Vector((0,1,-3))-Vector((x,6.1,z))
        angle = math.atan2(toward.x,toward.z)
        rig.box("Spotlight housing",(x,6.06,z),(.66,.48,.60),"ink",angle)
        rig.box("Spotlight lens",(x,5.8,z),(.51,.06,.45),"lamp",angle)
        for side in (-1,1):
            rig.box("Barn door",(x+side*.285,5.74,z),(.09,.22,.65),"navy")
        if i in (0,4,8,14,18):
            layout["spots"].append([[x,5.76,z],[x*.45,.12,-3+(z+2.6)*.5]])

# Television scenery and removable flats.
flat = kit("stage_flat")
flat.box("Backdrop panel",(0,2.18,0),(4.48,4.36,.42),"violet")
for i in range(5):
    flat.box("Radiating inset",(-1.75+i*.875,2.25,.24),(.72,3.75,.08),
             "lilac" if i%2==0 else "ivory")
flat.box("Panel foot",(0,.13,0),(4.57,.26,.52),"navy")
for x in (-4.6,0,4.6):
    instance("stage_flat",f"VarietyFlat{int(x+5)}",(x,.29,-8.19),(4.45,4.45,.44),structural=True)

couch = kit("sofa")
couch.box("Upholstered base",(0,.28,0),(2.45,.47,1.03),"red")
couch.box("Seat cushion",(0,.54,.10),(2.04,.18,.74),"pink")
couch.box("Upholstered back",(0,.76,-.37),(2.36,.65,.25),"red")
for x in (-1.12,1.12):
    couch.box("Armrest",(x,.61,.02),(.24,.33,.87),"red")
    for z in (-.32,.38):
        couch.box("Couch foot",(x,.08,z),(.13,.16,.14),"navy")
instance("sofa","GuestSofa",(-3.5,.29,-5.7),(2.45,1.08,1.03))
instance("sofa","GuestLoveseat",(-1.4,.29,-5.4),(2.45,1.08,1.03),-.17)

floor_monitor = kit("floor_monitor")
floor_monitor.box("Monitor speaker cabinet",(0,.23,0),(.85,.46,.58),"navy")
floor_monitor.box("Speaker grille",(0,.36,-.08),(.74,.24,.45),"slate")
for x in (-.22,0,.22):
    floor_monitor.box("Grille vent",(x,.49,-.08),(.045,.024,.36),"ink")
floor_monitor.box("Power LED",(.35,.22,.30),(.06,.08,.025),"tally")
for label,x in (("Left",-4.7),("Right",5.9)):
    instance("floor_monitor",f"StageMonitor{label}",(x,.29,-3.53),(.85,.52,.64),x*.045,shoot_only=True)

news = kit("news", True)
solid(news,"News plinth",(-16,.055,-8.8),(9.6,.11,7.0),"ivory")
backdrop = kit("news_backdrop")
backdrop.box("Blue broadcast backdrop",(0,2.14,0),(8.25,4.27,.18),"cobalt")
backdrop.box("News ribbon",(0,.56,.13),(8.1,.19,.08),"cyan")
for x in (1.10,2.05,3.0):
    backdrop.box("Blue screen slat",(x,2.42,.13),(.55,2.4,.06),"blue")
for radius,ratio in ((1.42,1),(1.42,.5)):
    points = [(-1.3+radius*ratio*math.cos(i*math.tau/24),2.35+radius*math.sin(i*math.tau/24),.15)
              for i in range(24)]
    for i, p in enumerate(points):
        backdrop.rod("Globe grid",p,points[(i+1)%24],.025,"cyan",5)
for y in (1.7,2.35,3.0):
    half = math.sqrt(1.42**2-(y-2.35)**2)
    backdrop.rod("Globe latitude",(-1.3-half,y,.15),(-1.3+half,y,.15),.026,"cyan",5)
instance("news_backdrop","NewsBackdrop",(-16,.11,-11.85),(8.25,4.27,.24),structural=True)
monitor = kit("control_monitor")
monitor.box("Monitor casing",(0,.475,0),(1.66,.95,.22),"ink")
monitor.box("Monitor glass",(0,.475,.14),(1.43,.73,.08),"screen")
switcher = kit("control_switcher")
switcher.box("Switcher console",(0,.07,0),(1.78,.14,.65),"navy")
for i in range(5):
    switcher.box("Switcher key",(-.58+i*.26,.16,.10),(.13,.06,.14),("cyan","tally","lamp")[i%3])
for i,x in enumerate((-20,-18.1,-16.2,-14.3)):
    instance("control_monitor",f"ControlMonitor{i}",(x,1.375,-15.94),(1.66,.95,.29),shoot_only=True)
    instance("control_switcher",f"ControlSwitcher{i}",(x,.82,-15.35),(1.78,.20,.65),shoot_only=True)
control_partition = kit("control_partition")
for x in (-21.5,-19,-16.5,-14):
    control_partition.box("Control room window upright",(x+17.8,1.83,0),(.09,2.11,.12),"slate")
for y in (.81,2.87):
    control_partition.box("Control room window frame",(.05,y,0),(7.6,.13,.13),"slate")
control_partition.box("Control room sill",(0,.42,0),(7.7,.84,.20),"navy")
control_partition.box("Control room fascia",(0,3.05,0),(7.7,.31,.21),"navy")
instance("control_partition","ControlPartition",(-17.8,0,-14.24),(7.7,.84,.20),structural=True,section=True)
layout["props"][-1]["window"] = [[.05,1.83,0],[7.53,1.96],3.21]

desk = kit("broadcast_desk")
desk.box("Curved console center",(0,.52,0),(3.4,.86,.82),"blue")
desk.box("Worktop",(0,1,0),(3.65,.13,.93),"ivory")
for side in (-1,1):
    desk.box("Faceted console wing",(side*1.84,.52,-.17),(.79,.86,.75),"cobalt",side*.38)
    desk.box("Console wing top",(side*1.84,1,-.17),(.92,.13,.87),"ivory",side*.38)
    desk.box("Mic base",(side*.69,1.09,.12),(.18,.06,.14),"ink")
    desk.rod("Desk microphone",(side*.69,1.11,.13),(side*.69,1.31,-.02),.027,"ink",6)
instance("broadcast_desk","NewsDesk",(-16,.11,-8.4),(4.45,1.05,.99))
instance("broadcast_desk","HostDesk",(3.85,.29,-5.6),(4.45,1.05,.99),-.13)

camera = kit("camera")
camera.rod("Pedestal",(0,.18,0),(0,1.46,0),.11,"ink")
camera.box("Dolly base",(0,.16,0),(.86,.13,.65),"navy")
for x in (-.32,.32):
    for z in (-.23,.23):
        camera.rod("Dolly caster",(x-.09,.09,z),(x+.09,.09,z),.09,"ink")
camera.box("Broadcast camera",(0,1.54,0),(.67,.47,.62),"ink")
camera.box("Side battery",(.34,1.53,.06),(.13,.28,.37),"slate")
camera.box("Teleprompter hood",(0,1.56,-.43),(.81,.42,.27),"navy")
camera.box("Teleprompter glass",(0,1.58,-.58),(.58,.24,.03),"screen")
camera.box("Record tally",(0,1.84,-.03),(.25,.12,.19),"tally")
camera.rod("Pan handle",(.15,1.34,.15),(.39,1.22,.58),.04,"ink",6)
for i,(x,z,angle) in enumerate([(-5.3,1.6,.29),(5.7,1.3,-.38),(-16,-4.2,0),(.6,8.6,0)]):
    instance("camera",f"Camera{i}",(x,0,z),(.88,1.94,1.16),angle)

chair = kit("chair")
chair.rod("Swivel column",(0,.12,0),(0,.49,0),.055,"slate")
for i in range(5):
    a = i*math.tau/5
    end = (.29*math.cos(a),.12,.29*math.sin(a))
    chair.rod("Caster arm",(0,.12,0),end,.035,"ink",6)
    chair.rod("Caster wheel",(end[0]-.045,.071,end[2]),(end[0]+.045,.071,end[2]),.065,"ink",6)
chair.box("Chair seat",(0,.50,0),(.55,.13,.53),"dark_teal")
chair.box("Chair back",(0,.82,.23),(.53,.49,.13),"green")
for side in (-1,1):
    chair.box("Chair arm",(side*.29,.67,.01),(.07,.07,.35),"navy")

office = kit("office_island")
office.box("Work island top",(0,.84,0),(2.98,.14,1.43),"ivory")
for x in (-1.25,1.25):
    office.box("Desk plinth",(x,.39,0),(.45,.78,1.28),"green")
    for y in (.23,.46,.69):
        office.box("Drawer face",(x,y,.66),(.37,.18,.05),"mint")
office.box("Acoustic screen",(0,1.05,0),(2.93,.38,.09),"mint")
for x,side in ((-.82,1),(.79,-1)):
    office.box("Monitor stand",(x,.96,side*.25),(.32,.08,.28),"ink")
    office.box("CRT monitor",(x,1.22,side*.26),(.62,.48,.46),"ivory")
    office.box("CRT display",(x,1.23,side*.5),(.47,.34,.03),"screen")
    office.box("Keyboard",(x,.937,side*.63),(.46,.044,.13),"navy")
    office.box("Desk telephone",(x+.62,.98,side*.37),(.26,.12,.25),"navy")
    office.box("News rundown",(x-.43,.929,side*.62),(.28,.026,.21),"paper",.21*side)
    office.box("Folder stack",(x+.40,.952,side*.29),(.25,.070,.31),"card")
for i,(x,z) in enumerate([(-17.7,4.9),(-15.3,9.1),(-18.2,13.0)]):
    instance("office_island",f"NewsroomIsland{i}",(x,0,z),(3,1.02,1.45),paper=True)
    for j,(dx,dz,angle) in enumerate([(-.6,1.04,.11),(.69,-1.02,math.pi-.15)]):
        instance("chair",f"NewsroomChair{i}_{j}",(x+dx,0,z+dz),(.56,1.08,.58),angle)

details = kit("newsroom")
for x in (-20.9,-18.4,-15.9,-13.4):
    details.box("Glass divider frame",(x+17.15,1.52,0),(.09,2.65,.10),"green")
for y in (.66,2.81):
    details.box("Glass divider crossbar",(0,y,0),(7.6,.09,.10),"green")
details.box("Divider knee wall",(0,.32,0),(7.6,.64,.16),"mint")
instance("newsroom","NewsroomPartition",(-17.15,0,14.78),(7.6,.64,.16),structural=True,section=True)
layout["props"][-1]["window"] = [[0,1.73,0],[7.48,2.06],2.86]

bulletin = kit("bulletin_board")
bulletin.box("Cork and frame",(0,.475,0),(1.50,.95,.12),"card")
for i in range(5):
    bulletin.box("Pinned assignment",(-.47+i*.24,.485+(i%2)*.12,.08),(.18,.22,.02),"paper")
instance("bulletin_board","AssignmentBoard",(-20.9,1.125,2.33),(1.50,.95,.19),paper=True,shoot_only=True)

patch_bay = kit("patch_bay")
patch_bay.box("Patch bay cabinet",(0,1.04,0),(.92,2.08,.62),"navy")
for i in range(8):
    patch_bay.box("Patch bay strip",(0,.38+i*.17,.32),(.76,.075,.04),"slate")
    for j in range(4):
        patch_bay.box("Patch bay LED",(-.25+j*.16,.38+i*.17,.35),(.06,.047,.019),("tally","cyan","lamp")[j%3])
instance("patch_bay","PatchBay",(-12.3,0,12.77),(.92,2.08,.67),shoot_only=True)

archive = kit("archive_rack")
for x in (-1.29,1.29):
    for z in (-.40,.40):
        archive.box("Perforated shelf upright",(x,1.28,z),(.085,2.56,.085),"teal")
        for j in range(9):
            archive.box("Upright slot",(x, .26+j*.24,z+.049),(.037,.082,.01),"ink")
for y in (.14,.76,1.38,2.0,2.56):
    archive.box("Shelf board",(0,y,0),(2.68,.085,.86),"dark_teal")
    archive.box("Shelf lip",(0,y,.451),(2.68,.055,.04),"teal")
for row,y in enumerate((.19,.81,1.43,2.05)):
    for i in range(7):
        x = -1.13+i*.34
        if i in (2,5) and row in (1,2):
            archive.box("Open Betacam cassette",(x,y+.15,.24),(.33,.27,.11),"ink")
            for reel in (-.081,.081):
                archive.rod("Visible tape reel",(x+reel,y+.17,.303),(x+reel,y+.17,.319),.055,"ivory")
                archive.rod("Reel core",(x+reel,y+.17,.319),(x+reel,y+.17,.324),.020,"slate")
        elif (i+row)%4==0:
            archive.box("Cardboard records box",(x,y+.19,.02),(.30,.36,.60),"card")
            archive.box("Box handle",(x,y+.24,.327),(.095,.048,.018),"ink")
        else:
            h = .41+(i%3)*.04
            archive.box("Tape case or file binder",(x,y+h/2,.12),(.25,h,.44),
                        ("navy","slate","card","ivory")[(i+row)%4])
            archive.box("Spine label",(x,y+.30,.348),(.19,.082,.02),"paper")
for i,(x,z,a) in enumerate([(14.0,-11.4,0),(18.3,-11.4,0),(14,-7.9,0),(18.3,-7.9,0),
                            (14,-4.4,0),(18.3,-4.4,0),(20.75,-6.1,-math.pi/2)]):
    instance("archive_rack",f"ArchiveRack{i}",(x,0,z),(2.69,2.60,.94),a,paper=True)

cart = kit("road_case")
cart.box("Road case shell",(0,.48,0),(1.35,.79,.84),"navy")
for x in (-.69,.69):
    cart.box("Aluminum corner",(x,.48,0),(.055,.80,.86),"slate")
    for z in (-.3,.3):
        cart.rod("Road case wheel",(x-.045,.091,z),(x+.045,.091,z),.09,"ink",7)
for y in (.15,.8):
    cart.box("Metal edge rail",(0,y,.435),(1.35,.055,.03),"slate")
for x in (-.44,.44):
    cart.box("Case latch",(x,.59,.447),(.115,.21,.035),"ivory")
cart.box("Recessed handle",(0,.39,.448),(.26,.11,.034),"ink")
for i,(x,z) in enumerate([(14.1,4.4),(20.5,10.8),(11.9,13.3),(-6.4,10.7),
                            (-13.9,-13.2),(8.2,-15.0),(16.5,11.2)]):
    instance("road_case",f"RoadCase{i}",(x,0,z),(1.41,.9,.9),i*.22)

backstage = kit("backstage", True)
cyc = kit("green_cyc")
cyc.box("Green-screen cyc",(0,1.55,0),(4.7,3.1,.30),"green_screen")
backstage.box("Green-screen floor",(19.25,.041,7.25),(4.7,.02,2.8),"green_screen")
for x in (-2.2,2.2):
    cyc.rod("Backdrop stand",(x,0,-.2),(x,3.45,-.2),.071,"navy")
    for sign in (-1,1):
        cyc.rod("Stand foot",(x,.05,-.2),(x+sign*.46,.06,.14),.048,"navy")
instance("green_cyc","WeatherCyc",(19.25,0,5.9),(4.7,3.1,.36))
backstage.box("Set door marker",(20.2,2.62,16.8),(.47,.13,.12),"tally")
backstage.box("Aperture of service lift",(20.1,1.41,16.78),(2.9,2.82,.12),"slate")
backstage.box("Service lift join",(20.1,1.41,16.71),(.04,2.81,.02),"ink")
for x in (-8,0,8):
    backstage.box("Corridor ceiling light",(x,3.68,-14.7),(1.76,.13,.39),"lamp")
for x in (-9.6,9.6):
    backstage.box("Backstage floor mark",(x,.036,-13.3),(.14,.02,3.8),"gold")

layout.update({
    "fixed": ["shell","ceiling","stage","lighting","news","newsroom","backstage"],
    "start": [-7.1,.05,8.9],
    "opening": [[0,.05,-.8],[4,.05,-14.4],[-15.4,.05,-5.8],[16.8,.05,-9.9],
                [-15,.05,6.7],[16,.05,3.4],[8.9,.05,9.8],[-6,.05,-.4]],
    "spawns": [[-16,.05,-3],[-19.6,.05,-13],[-16,.05,3],[-20.1,.05,10.6],[-12.6,.05,14.8],
               [12.4,.05,8.8],[16.4,.05,-6.1],[20.2,.05,-13],[14.1,.05,-2.1],[18.8,.05,13.7],
               [1,.05,-14.5],[-3,.05,12.1],[.1,2.67,-11.3],[6,.05,.6]],
    "respawns": [[-7.1,.05,8.9],[8.6,.05,13.8],[-16.7,.05,-2],[-19.8,.05,6.6],
                 [16,.05,-2.7],[18.5,.05,10.2],[-3.2,.05,-14.9]],
    "route": [[-.5,.34,-3.7],[-17.4,.05,-3.5],[-15.8,.05,7.0],[16.2,.05,-6.1],
              [14.7,.05,8.7],[-8.75,2.67,-10.65],[0,2.67,-11.4],[8.75,2.67,-10.65],
              [0,.05,-14.9]],
})

for item in kits.values():
    item.export()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"art_source/night_studio.blend"),compress=True)
(ROOT/"tools/maps/night_studio_layout.json").write_text(json.dumps(layout,indent=2)+"\n")
