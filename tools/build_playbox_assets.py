"""Editable original interactive props. blender --background --python tools/build_playbox_assets.py"""
import bpy
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
COLORS = {'paint':'B65745','ink':'243440','cream':'E5E0D2','gold':'E9BA50',
          'steel':'A9C8CB','edge':'F7F4DE','grip':'273C48','leaf':'548876',
          'leaf_light':'8BAB64','trunk':'A97C4B','blue':'304F9D','teal':'53B9B6'}
MATS = {}
for name, code in COLORS.items():
    def linear(v): return v / 12.92 if v < .04045 else ((v+.055)/1.055)**2.4
    rgba = tuple(linear(int(code[i:i+2],16)/255) for i in (0,2,4))+(1,)
    m=bpy.data.materials.new(name)
    m.diffuse_color=rgba
    m.use_nodes=True
    p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=rgba
    p.inputs['Roughness'].default_value=.85
    MATS[name]=m
roots=[]
current=None

def xyz(p): return (p[0],-p[2],p[1])
def begin(name):
    global current
    current=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(current)
    roots.append(current)

def finish(obj,name,color):
    obj.name=name
    obj.data.materials.append(MATS[color])
    obj.parent=current
    return obj

def box(name,p,size,color,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(p))
    o=bpy.context.object
    o.dimensions=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Edge','BEVEL');mod.width=bevel;mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,color)

def mesh(name,vertices,faces,color):
    data=bpy.data.meshes.new(name)
    data.from_pydata([xyz(p) for p in vertices],[],faces)
    data.update()
    o=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(o)
    return finish(o,name,color)

def beam(name,a,b,r,color,vertices=8):
    start,end=Vector(xyz(a)),Vector(xyz(b))
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=(end-start).length,location=(start+end)/2)
    o=bpy.context.object
    o.rotation_euler=(end-start).to_track_quat('Z','Y').to_euler()
    return finish(o,name,color)

def pivot(name,p,objects):
    o=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(o)
    o.parent=current
    o.location=xyz(p)
    bpy.context.view_layer.update()
    for child in objects:
        matrix=child.matrix_world.copy()
        child.parent=o
        child.matrix_world=matrix
    return o

def export(name):
    bpy.ops.object.select_all(action='DESELECT')
    current.select_set(True)
    for o in current.children_recursive:o.select_set(True)
    bpy.context.view_layer.objects.active=current
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,export_format='GLB',export_yup=True)
    current.location=(len(roots)*9,0,0)

begin('container_openable')
box('Floor',(0,-.035,0),(6,.07,2.8),'ink')
box('Roof',(0,2.85,0),(6,.10,2.8),'paint')
box('Back',(-2.95,1.4,0),(.10,2.8,2.8),'paint')
for z in [-1.35,1.35]:
    box('Wall',(0,1.4,z),(6,2.8,.10),'paint')
    for i in range(17):box('Rib',(-2.7+i*.3375,1.4,z+(.07 if z>0 else -.07)),(.045,2.55,.035),'paint')
    for y in [.10,2.75]:box('Rail',(0,y,z),(6,.12,.15),'ink')
for x in [-2.95,2.95]:
    for z in [-1.34,1.34]:
        box('Corner',(x,1.4,z),(.13,2.8,.13),'ink')
        for y in [.10,2.78]:box('Casting',(x,y,z),(.22,.20,.20),'cream')
for sign,name in [(-1,'DoorLeft'),(1,'DoorRight')]:
    before=set(current.children)
    z=sign*.665
    box('DoorPanel',(3,1.4,z),(.12,2.66,1.31),'paint')
    for y in [.14,2.66]:box('DoorEdge',(3.08,y,z),(.05,.10,1.28),'ink')
    for dz in [-.3,.3]:
        box('LockBar',(3.09,1.4,z+dz),(.065,2.45,.055),'cream')
        box('Handle',(3.15,1.3,z+dz),(.10,.10,.26),'ink')
    for y in [.5,2.25]:box('Hinge',(3.08,y,sign*1.31),(.18,.20,.16),'cream')
    pivot(name,(3,0,sign*1.34),[o for o in current.children if o not in before])
export('container_openable')

begin('knife')
# Origin at the hand; blade points along local +Y for a readable raised chop.
box('Handle',(0,0,0),(.085,.23,.09),'grip',.008)
for y in [-.08,0,.08]:box('GripBand',(0,y,0),(.094,.025,.10),'ink')
box('Guard',(0,.14,0),(.23,.045,.11),'gold',.008)
vertices=[(-.075,.16,-.025),(.075,.16,-.025),(.07,.50,-.025),(-.04,.69,0),
          (-.075,.16,.025),(.075,.16,.025),(.07,.50,.025)]
blade=mesh('Blade',vertices,[(0,1,2,3),(4,3,6,5),(0,4,5,1),(1,5,6,2),(2,6,3),(0,3,4)],'steel')
box('BladeHighlight',(-.061,.34,-.029),(.018,.34,.008),'edge')
export('knife')

bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene['README']='Original interactive container and knife. Rebuild with tools/build_playbox_assets.py.'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/playbox_props.blend'))
print('PLAYBOX_ASSETS_OK',len(roots))
