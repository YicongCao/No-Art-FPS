"""Rigid mechanical articulation and precision attachments on normalized Tripo shells."""
import bpy,bmesh,math,sys,json,numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];INPUTS=HERE/'inputs';OUT=ROOT/'assets/models/space';sys.path.insert(0,str(HERE))
from geometry import *
from build_sensor_heads import replace_head
report={}

def roughen():
 for im in bpy.data.images:
  if 'ORM' in im.name.upper() and im.size[0]:
   a=np.empty(len(im.pixels),dtype=np.float32);im.pixels.foreach_get(a);a[1::4]=np.maximum(a[1::4],.46);im.pixels.foreach_set(a);im.pack()

def piece(source,indices,name):
 obj=source.copy();obj.data=source.data.copy();obj.name=name;bpy.context.collection.objects.link(obj)
 bm=bmesh.new();bm.from_mesh(obj.data);bm.faces.ensure_lookup_table()
 bmesh.ops.delete(bm,geom=[f for i,f in enumerate(bm.faces) if i not in indices],context='FACES')
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS');bm.to_mesh(obj.data);bm.free();obj.data.update()
 return obj

def move_piece(obj,start,end,target_start,target_end):
 start,end,target_start,target_end=map(Vector,[start,end,target_start,target_end])
 v=end-start;t=target_end-target_start;r=v.rotation_difference(t).to_matrix()
 # Stretch only along the mechanical bone, leaving armor width unchanged.
 axis=v.normalized();ratio=t.length/v.length
 for vertex in obj.data.vertices:
  offset=vertex.co-start;offset+=axis*offset.dot(axis)*(ratio-1)
  vertex.co=target_start+r@offset
 obj.data.update()

def export(name):
 bpy.context.view_layer.update()
 for o in bpy.data.objects:
  if o.type=='MESH':o.data.calc_loop_triangles()
 report[name]={'triangles':sum(len(o.data.loop_triangles) for o in bpy.data.objects if o.type=='MESH'),'meshes':sum(o.type=='MESH' for o in bpy.data.objects),'materials':len({m.name for o in bpy.data.objects if o.type=='MESH' for m in o.data.materials})}
 bpy.ops.wm.save_as_mainfile(filepath=str(HERE/(name+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB')

for name,slim in [('rifle-mech',False),('assault-mech',True)]:
 bpy.ops.wm.open_mainfile(filepath=str(INPUTS/(name+'.blend')));roughen();source=next(o for o in bpy.context.scene.objects if o.type=='MESH');m=palette();root=group('AssaultMech' if slim else 'RifleMech')
 w=.75 if slim else 1.0;cut=1.07
 buckets={}
 for f in source.data.polygons:
  c=f.center;x,y,z=c
  side='Right' if x>=0 else 'Left'
  arm=abs(x)>w*(.25+max(0,1.40-z)*.23) and z>.85
  if arm:
   part=side+('UpperArmMesh' if z>1.29 else 'ForearmMesh' if z>1.055 else 'CloudHand')
  elif z>1.62:part='Helmet'
  elif z<cut:part=side+('ThighMesh' if z>.69 else 'ShinMesh' if z>.18 else 'FootMesh')
  else:part='Torso'
  buckets.setdefault(part,set()).add(f.index)
 parts={k:piece(source,v,k) for k,v in buckets.items() if not k.endswith('CloudHand')}
 bpy.data.objects.remove(source,do_unlink=True)
 torso=parts.pop('Torso')
 for v in torso.data.vertices:v.co.z-=1.35
 torso.location.z=1.35;attach(torso,root)
 head=group('Head',(0,0,1.70),root);helmet=parts.pop('Helmet')
 for v in helmet.data.vertices:v.co.z-=1.70
 helmet.location.z=1.70;attach(helmet,head)
 helmet=replace_head(head,helmet,slim)
 beam('Neck',(0,0,1.57),(0,0,1.70),.055,m['dark'],head)
 # Real emissive core, hidden under the removable helmet until a headshot.
 beam('Head core',(0,0,1.67),(0,0,1.76),.058,m['dark'],head)
 for side,sign in [('Left',-1),('Right',1)]:
  leg=group(side+'Leg',(sign*.155,0,cut),root)
  knee=group(side+'Knee',(sign*.155,0,.69),leg)
  foot=group(side+'Foot',(sign*.155,0,.15),knee)
  for suffix,parent in [('ThighMesh',leg),('ShinMesh',knee),('FootMesh',foot)]:
   attach(parts.pop(side+suffix),parent)
  beam('Hip socket',(sign*.11,0,cut),(sign*.21,0,cut),.075,m['dark'],leg)
  shoulder=Vector((sign*.32*w,0,1.55));elbow=Vector((sign*.44*w,0,1.29));wrist=Vector((sign*.54*w,.02,1.055))
  if slim:
   target_elbow=Vector((sign*.28,-.025,1.25));target_wrist=Vector((sign*.29,.16,1.04))
  elif sign>0:
   target_elbow=Vector((.33,-.025,1.25));target_wrist=Vector((.18,.04,1.17))
  else:
   target_elbow=Vector((-.29,.18,1.25));target_wrist=Vector((.04,.43,1.20))
  arm=group(side+'Arm',shoulder,root);fore=group(side+'Forearm',target_elbow,arm)
  upper=parts.pop(side+'UpperArmMesh');move_piece(upper,shoulder,elbow,shoulder,target_elbow);attach(upper,arm)
  lower=parts.pop(side+'ForearmMesh');move_piece(lower,elbow,wrist,target_elbow,target_wrist);attach(lower,fore)
  beam('Elbow socket',target_elbow-Vector((.05,0,0)),target_elbow+Vector((.05,0,0)),.06,m['dark'],fore)
  hand=group(side+'Hand',target_wrist,fore)
  box('Mechanical palm',target_wrist+Vector((0,.035,-.035)),(.095,.10,.08),m['dark'],.018,hand)
  for j in range(4):
   box('Finger',target_wrist+Vector((-.035+j*.023,.075,-.07)),(.018,.068,.022),m['metal'],.006,hand)
  box('Knuckle armor',target_wrist+Vector((0,.02,.005)),(.10,.07,.025),m['white'],.008,hand)
  if slim and sign>0:
   blade=group('MeleeBlade',target_wrist,hand)
   beam('Blade handle',target_wrist-Vector((0,.03,.06)),target_wrist+Vector((0,.16,-.06)),.024,m['dark'],blade)
   # Ceramic spine and cyan edge; actual mesh, not a billboard.
   yz=[(target_wrist.y+.14,target_wrist.z-.08),(target_wrist.y+.49,target_wrist.z-.04),(target_wrist.y+.55,target_wrist.z+.02),(target_wrist.y+.14,target_wrist.z+.01)]
   panel('Blade',target_wrist.x,.025,yz,m['metal'],blade)
   beam('Powered edge',(target_wrist.x,target_wrist.y+.16,target_wrist.z-.075),(target_wrist.x,target_wrist.y+.49,target_wrist.z-.035),.007,m['cyan'],blade)
 if parts:raise RuntimeError('Unassigned articulation parts '+str(parts.keys()))
 if not slim:
  existing=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(OUT/'mech-rifle.glb'))
  imported=[o for o in bpy.data.objects if o not in existing and o.parent is None]
  gun=group('EnemyGun',(.12,.18,1.25),root)
  for o in imported:o.parent=gun;o.location=(0,0,0)
 # Leave cut limbs/aliases distinct. Small new joint pieces merge only within their pivot.
 batch_children(root)
 # The torso itself must retain its gameplay alias after optional detail batching.
 torso.name='Torso';helmet.name='Helmet'
 export(name)

bpy.ops.wm.open_mainfile(filepath=str(INPUTS/'interceptor.blend'));roughen();m=palette();root=group('Interceptor')
for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
 for v in o.data.vertices:v.co.z+=1.15
 o.name='Hull';attach(o,root)
for i,(x,y) in enumerate([(-2.5,-1.6),(2.5,-1.6),(0,2.6)]):
 gear=group('LandingGear'+str(i),(x,y,0),root);out=x+(math.copysign(.35,x) if x else 0)
 beam('Gear shock',(x,y,1.65),(out,y+.2,.32),.11,m['dark'],gear)
 beam('Exposed piston',(x+.13,y,1.55),(out+.10,y+.2,.44),.045,m['metal'],gear)
 beam('Gear brace',(x,y-.4,1.35),(out,y+.2,.35),.055,m['metal'],gear)
 box('Landing pad',(out,y+.2,.13),(.85,.72,.24),m['dark'],.07,gear)
 box('Pad plating',(out,y+.2,.25),(.70,.58,.045),m['white'],.025,gear)
for side in [-1,1]:
 x=side*3.6;mount=group('WingMount'+str(side),(x,0,0),root)
 box('Cannon support',(x,.25,1.75),(.45,1.1,.24),m['dark'],.04,mount)
 box('Cannon armor',(x,.25,1.96),(.43,.90,.27),m['white'],.045,mount)
 beam('Cannon barrel',(x,.6,1.94),(x,2.8,1.94),.065,m['metal'],mount)
 for y in [.8,1.15,1.5,1.85,2.2]:beam('Cannon collar',(x,y,1.94),(x,y+.09,1.94),.09,m['dark'],mount)
 beam('Muzzle',(x,2.7,1.94),(x,2.9,1.94),.10,m['dark'],mount)
 beam('Muzzle core',(x,2.9,1.94),(x,2.915,1.94),.06,m['cyan'],mount)
 pod=group('RocketPod'+str(side),(side*4.1,-1,2.1),root)
 box('Rocket armor',(side*4.1,-1,2.1),(.74,1.15,.6),m['white'],.07,pod)
 box('Rocket face',(side*4.1,-.40,2.1),(.65,.04,.51),m['dark'],.018,pod)
 for dx in [-.18,0,.18]:
  for z in [1.97,2.23]:beam('Rocket port',(side*4.1+dx,-.40,z),(side*4.1+dx,-.35,z),.067,m['rubber'],pod,12)
box('Hull beacon',(0,-2.5,2.1),(.14,.22,.07),m['cyan'],.018,root)
batch_children(root);export('interceptor')
(ROOT/'docs/art/space/review-b/asset-build.json').write_text(json.dumps(report,indent=2)+'\n')
print('HEROES_READY',report)
