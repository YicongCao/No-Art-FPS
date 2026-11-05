"""Original modular toy-yard models. Run with Blender --background --python.

Author in Godot coordinates (Y up, forward -Z); convert to Blender on creation.
The saved blend presents each asset separately; GLBs retain origin-at-ground.
"""
import bpy
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
COLORS = {
    'ink': '243440', 'dark': '18232E', 'cream': 'E5E0D2', 'yellow': 'E9BA50',
    'red': 'B65745', 'green': '4D7D70', 'purple': '754C87', 'blue': '304F9D',
    'sky': '5B7FC8', 'white': 'FFF1CB', 'leaf': '548876', 'sole': '344550',
}
MATS = {}
def linear(c):
    return c / 12.92 if c < .04045 else ((c + .055) / 1.055) ** 2.4
for name, code in COLORS.items():
    rgba = tuple(linear(int(code[i:i+2], 16)/255) for i in (0, 2, 4)) + (1,)
    m = bpy.data.materials.new(name)
    m.diffuse_color = rgba
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = rgba
    p.inputs['Roughness'].default_value = .88
    p.inputs['Metallic'].default_value = 0
    MATS[name] = m

current = None
roots = []
def xyz(p): return (p[0], -p[2], p[1])
def begin(name):
    global current
    current = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(current)
    roots.append(current)
    return current

def finish_obj(obj, name, color):
    obj.name = name
    obj.data.materials.append(MATS[color])
    obj.parent = current
    return obj

def box(name, p, size, color, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(p))
    obj = bpy.context.object
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Crisp tiny bevel', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish_obj(obj, name, color)

def cyl(name, p, r, depth, color, vertices=8, axis='y'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=r, depth=depth, location=xyz(p))
    obj = bpy.context.object
    if axis == 'z': obj.rotation_euler.x = math.pi/2
    if axis == 'x': obj.rotation_euler.y = math.pi/2
    return finish_obj(obj, name, color)

def export(name, merge=False):
    if merge:
        for color in MATS:
            parts = [o for o in current.children if o.type == 'MESH' and o.data.materials[0] == MATS[color]]
            if len(parts) > 1:
                bpy.ops.object.select_all(action='DESELECT')
                for o in parts: o.select_set(True)
                bpy.context.view_layer.objects.active = parts[0]
                bpy.ops.object.join()
                parts[0].name = name + '_' + color
    bpy.ops.object.select_all(action='DESELECT')
    current.select_set(True)
    for o in current.children_recursive: o.select_set(True)
    bpy.context.view_layer.objects.active = current
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name+'.glb')), use_selection=True, export_format='GLB', export_yup=True)
    index = len(roots)-1
    current.location = (index % 4 * 9, index // 4 * 8, 0)

for color in ('green', 'red', 'cream', 'purple'):
    name = 'container_' + color
    begin(name)
    box('body', (0,1.45,0), (6,2.9,2.8), color)
    for x in (-2.96, 2.96):
        for z in (-1.39,1.39):
            box('corner', (x,1.45,z), (.12,2.9,.12), 'ink')
            for y in (.12,2.78): box('casting',(x,y,z),(.24,.24,.2),'cream')
    for z in (-1.42,1.42):
        for i in range(17):
            box('rib',(-2.7+i*.3375,1.46,z),(.045,2.55,.035),color)
        for y in (.12,2.78):box('rim',(0,y,z),(5.9,.12,.07),'ink')
    for x in (-3.02,3.02):
        box('door_seam',(x,1.45,0),(.03,2.65,.04),'ink')
        for z in (-.78,.78):
            box('locking_bar',(x,1.45,z),(.055,2.45,.045),'cream')
            box('handle',(x,1.35,z),(.1,.12,.27),'ink')
    box('placard',(-1.9,2.24,-1.46),(.8,.27,.035),'yellow')
    export(name,True)

begin('rifle')
box('receiver',(0,0,0),(.18,.23,.68),'blue',.008)
box('foregrip',(0,.015,-.46),(.145,.18,.32),'blue',.006)
box('rail',(0,.145,-.13),(.13,.045,.65),'dark')
for z in range(9):box('rail_tooth',(0,.175,-.42+z*.07),(.16,.023,.022),'cream')
cyl('barrel',(0,.015,-.77),.04,.3,'ink',8,'z')
cyl('muzzle',(0,.015,-.94),.055,.10,'blue',8,'z')
box('stock',(0,-.02,.42),(.15,.21,.28),'dark')
box('magazine',(0,-.25,.02),(.12,.34,.18),'ink',.008)
box('grip',(0,-.24,.26),(.1,.27,.13),'dark',.008)
box('trigger_guard',(0,-.14,.17),(.055,.1,.13),'ink')
for x in (-.062,.062):box('sight_side',(x,.265,-.17),(.025,.16,.035),'dark')
box('sight_top',(0,.345,-.17),(.15,.026,.035),'dark')
box('sight_base',(0,.188,-.17),(.15,.035,.08),'cream')
box('front_sight',(0,.16,-.65),(.025,.09,.025),'yellow')
box('badge',(.096,.045,-.2),(.016,.055,.11),'yellow')
box('left_glove',(-.08,-.16,-.38),(.15,.14,.18),'dark',.015)
box('left_sleeve',(-.22,-.36,-.19),(.21,.35,.23),'green',.015)
box('right_glove',(.015,-.23,.3),(.13,.17,.17),'dark',.015)
box('right_sleeve',(.1,-.42,.45),(.2,.34,.23),'green',.01)
export('rifle',True)

begin('enemy')
box('Torso',(0,1.21,0),(.44,.54,.24),'ink',.025)
box('Vest',(0,1.23,-.145),(.34,.32,.09),'sole',.012)
box('ChestMark',(0,1.32,-.20),(.14,.055,.02),'yellow')
box('Pelvis',(0,.86,0),(.3,.16,.23),'dark',.015)
cyl('Neck',(0,1.52,0),.075,.12,'dark')
cyl('Head',(0,1.68,0),.17,.28,'ink',8)
cyl('Helmet',(0,1.81,0),.195,.11,'dark',8)
box('Visor',(0,1.70,-.16),(.27,.055,.035),'cream')
for side, x in [('Left',-.145),('Right',.145)]:
    box(side+'Leg',(x,.46,0),(.14,.68,.16),'ink',.012)
    box(side+'Foot',(x,.09,-.06),(.18,.16,.29),'dark',.01)
for side,x in [('Left',-.30),('Right',.30)]:
    box(side+'Arm',(x,1.17,-.025),(.13,.46,.15),'ink',.012)
    box(side+'Hand',(x,1.02,-.18),(.12,.13,.14),'dark')
box('EnemyGun',(.22,1.12,-.35),(.1,.12,.45),'dark')
export('enemy')

begin('forklift')
box('base',(0,.48,0),(1.6,.68,2.4),'yellow',.04)
box('rear',(0,1.0,.7),(1.55,.65,.75),'yellow')
for x in (-.82,.82):
    for z in (-.7,.7):
        cyl('wheel',(x,.36,z),.36,.24,'blue',10,'x')
        cyl('hub',(x*1.02,.36,z),.14,.26,'cream',8,'x')
for x in (-.68,.68):
    for z in (-.65,.65):box('cab_post',(x,1.65,z),(.09,1.75,.09),'blue')
box('roof',(0,2.55,0),(1.65,.16,1.7),'yellow')
box('seat',(0,1.05,.2),(.65,.15,.65),'ink')
box('seat_back',(0,1.35,.5),(.65,.6,.12),'ink')
for x in (-.55,.55):
    box('mast',(x,1.2,-1.3),(.15,2.4,.15),'cream')
    box('fork',(x,.16,-1.9),(.14,.12,1.25),'ink')
box('cross',(0,.8,-1.3),(1.2,.15,.15),'cream')
export('forklift',True)

begin('barrel')
cyl('barrel',(0,.6,0),.42,1.2,'cream',10)
for y in (.1,.55,1.1):cyl('band',(0,y,0),.435,.11,'red',10)
cyl('cap',(0,1.21,0),.42,.04,'ink',10)
export('barrel',True)

begin('tree')
cyl('trunk',(0,.9,0),.16,1.8,'ink',6)
for y,r in [(1.7,1.1),(2.5,.85),(3.2,.6)]:
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=r, radius2=0, depth=1.8, location=xyz((0,y,0)))
    finish_obj(bpy.context.object,'foliage','leaf')
export('tree',True)

begin('cloud')
for p,scale in [((0,0,0),(1.5,.6,.65)),((-.8,-.1,0),(.8,.5,.6)),((.7,.05,0),(.9,.7,.65))]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1, location=xyz(p))
    o=bpy.context.object
    o.scale=(scale[0],scale[2],scale[1])
    finish_obj(o,'puff','cream')
export('cloud',True)

begin('pallet')
for z in [-.55,0,.55]:box('runner',(0,.12,z),(1.3,.24,.15),'yellow')
for x in [-.57,-.28,0,.28,.57]:box('slat',(x,.27,0),(.22,.08,1.4),'cream')
export('pallet',True)

begin('crate')
box('cargo',(0,.55,0),(1.1,1.1,1.1),'yellow',.025)
for y in [.09,1.01]:
    for z in [-.56,.56]:box('brace',(0,y,z),(1.15,.13,.07),'cream')
for x in [-.48,.48]:
    for z in [-.56,.56]:box('strap',(x,.55,z),(.07,1.1,.035),'ink')
box('label',(0,.7,-.58),(.32,.22,.02),'cream')
export('crate',True)

begin('steel_bundle')
for y in [.12,.34,.56]:
    for x in [-.45,-.15,.15,.45]:box('beam',(x,y,0),(.25,.18,3.2),'blue')
for z in [-1.1,1.1]:
    box('strap_top',(0,.67,z),(1.22,.035,.09),'cream')
    for x in [-.62,.62]:box('strap_side',(x,.35,z),(.035,.65,.09),'cream')
export('steel_bundle',True)

begin('traffic_light')
cyl('pole',(0,1.65,0),.07,3.3,'ink',8)
box('foot',(0,.1,0),(.38,.2,.38),'cream',.02)
box('head',(0,3.4,0),(.48,1.30,.32),'ink',.025)
for i,color in enumerate(['red','yellow','green']):
    cyl('lamp_'+color,(0,3.78-i*.38,-.19),.135,.07,color,12,'z')
    box('hood',(0,3.95-i*.38,-.23),(.37,.06,.32),'ink')
export('traffic_light')

bpy.ops.object.select_all(action='DESELECT')
bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene['README']='Original No-Art-FPS kit. Game-space units are meters. Rebuild with tools/build_assets.py.'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art_source/no_art_kit.blend'))
print('NO_ART_ASSETS_OK', len(roots))
