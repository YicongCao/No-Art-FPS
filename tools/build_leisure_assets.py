"""Original pool terrace props. blender --background --python tools/build_leisure_assets.py"""
import bpy
import math
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from toy_bevel import toy_soften
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
    p.inputs['Roughness'].default_value=.54
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
    toy_soften(o,min(size),bevel)
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
    depth=(end-start).length
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=(start+end)/2)
    o=bpy.context.object
    o.rotation_euler=(end-start).to_track_quat('Z','Y').to_euler()
    toy_soften(o,min(2*r,depth))
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

begin('palm')
# Faceted, gently leaning trunk and seven broad tapered fronds.
for i in range(7):
    a=(.045*i*i/7,i*.58,0)
    b=(.045*(i+1)*(i+1)/7,(i+1)*.58,0)
    beam('Trunk',a,b,.19-i*.011,'trunk',7)
    beam('TrunkRing',(a[0],a[1]+.02,0),(a[0],a[1]+.07,0),.20-i*.011,'cream',7)
center=(.315,4.06,0)
for n in range(8):
    angle=n*math.tau/8
    vertices=[]
    for i in range(5):
        t=i/4
        radius=t*2.7
        y=4.12+math.sin(t*math.pi)*.7-t*.9
        width=math.sin(t*math.pi)*.45+.015
        for sign in [-1,1]:
            vertices.append((center[0]+math.cos(angle)*radius+math.sin(angle)*width*sign,y,math.sin(angle)*radius-math.cos(angle)*width*sign))
    faces=[]
    for i in range(4):faces.extend([(2*i,2*i+1,2*i+3),(2*i,2*i+3,2*i+2)])
    leaf=mesh('PalmFrond',vertices,faces,'leaf' if n%2 else 'leaf_light')
    mod=leaf.modifiers.new('Leaf thickness','SOLIDIFY');mod.thickness=.035
    bpy.context.view_layer.objects.active=leaf
    bpy.ops.object.modifier_apply(modifier=mod.name)
for i in range(3):
    angle=i*math.tau/3
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.19,location=xyz((center[0]+math.cos(angle)*.2,3.92,math.sin(angle)*.2)))
    finish(bpy.context.object,'Coconut','trunk')
export('palm')

begin('lounger')
for x in [-.38,.38]:
    beam('Frame',(x,.45,-.75),(x,.45,.85),.035,'cream')
    beam('RearLeg',(x,0,.7),(x,.50,.55),.04,'cream')
    beam('FrontLeg',(x,0,-.65),(x,.48,-.50),.04,'cream')
    beam('BackFrame',(x,.45,-.55),(x,1.06,-1.10),.035,'cream')
box('Seat',(0,.45,.12),(.72,.07,1.40),'cream',.015)
for i in range(5):box('SeatStripe',(-.29+i*.145,.49,.12),(.075,.012,1.36),'teal')
back=box('Back',(0,.75,-.84),(.72,.07,.84),'cream',.015)
back.rotation_euler.x=math.radians(48)
for i in range(5):
    stripe=box('BackStripe',(-.29+i*.145,.779,-.819),(.075,.013,.83),'teal')
    stripe.rotation_euler.x=math.radians(48)
box('Pillow',(0,1.0,-1.00),(.50,.12,.20),'gold',.04)
export('lounger')

begin('parasol')
beam('Pole',(0,0,0),(0,2.65,0),.052,'cream')
box('Base',(0,.06,0),(.72,.12,.72),'cream',.03)
box('BaseCollar',(0,.16,0),(.26,.10,.26),'gold',.02)
beam('Finial',(0,2.72,0),(0,2.88,0),.065,'gold')
vertices=[(0,2.76,0)]+[(math.cos(i*math.tau/8)*1.52,2.25,math.sin(i*math.tau/8)*1.52) for i in range(8)]
for i in range(8):
    p1, p2 = vertices[i+1], vertices[(i+1)%8+1]
    cloth=mesh('Canopy',[vertices[0],p1,p2],[(0,1,2)],'cream' if i%2 else 'blue')
    mod=cloth.modifiers.new('Thickness','SOLIDIFY');mod.thickness=.045
    bpy.context.view_layer.objects.active=cloth
    bpy.ops.object.modifier_apply(modifier=mod.name)
    toy_soften(cloth,.04,.008,1)
    mid=((p1[0]+p2[0])*.5, 2.15, (p1[2]+p2[2])*.5)
    ang=math.atan2(p2[0]-p1[0], p2[2]-p1[2])
    val=box('Valance',mid,(math.hypot(p2[0]-p1[0],p2[2]-p1[2])-.03,.18,.055),'cream' if i%2 else 'blue',.012)
    val.rotation_euler.z=ang-math.pi/2
    beam('Rib',vertices[0],p1,.030,'cream')
export('parasol')

begin('pool')
box('BasinFloor',(0,-.53,0),(6,.12,7),'teal')
for x in [-2.83,2.83]:
    box('BasinSide',(x,-.24,0),(.36,.6,7),'cream')
    box('CopingRim',(x,.08,0),(.44,.08,7.08),'cream',.018)
    box('BlueTile',(x,.03,0),(.38,.04,7),'blue')
for z in [-3.33,3.33]:
    box('BasinEnd',(0,-.24,z),(5.65,.6,.36),'cream')
    box('CopingEnd',(0,.08,z),(5.74,.08,.44),'cream',.018)
    box('BlueTile',(0,.03,z),(5.65,.04,.38),'blue')
for x in [-1.5,0,1.5]:box('Lane',(x,-.459,0),(.055,.008,5.8),'blue')
for x in [-2.82,2.82]:
    for z in [-3,-2,-1,0,1,2,3]:box('TileJoint',(x,.073,z),(.35,.008,.025),'cream')
# Broad shallow entrance steps at the south end; physics uses a smooth ramp.
for i in range(4):
    y=-.46+(i+1)*.115
    z=1.96+i*.32
    box('EntryStep',(0,(y-.53)/2,z),(1.8,y+.53,.32),'cream')
export('pool')

bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene['README']='Original low-poly palms, loungers, parasol and pool. Rebuild with tools/build_leisure_assets.py.'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/leisure_props.blend'))
print('LEISURE_ASSETS_OK',len(roots))
