"""Deterministic lunar landscape, exterior modules and breakable equipment."""
import bpy,sys,math,json,numpy as np
from pathlib import Path
from mathutils import Vector,noise
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];sys.path.insert(0,str(HERE.parent/'heroes'))
from geometry import *
OUT=ROOT/'assets/models/space';report={}
def begin():
 bpy.ops.wm.read_factory_settings(use_empty=True)
 global m,root
 m=palette();m['yellow']=material('Safety yellow',(.65,.39,.055),.1,.5);m['glass']=material('Dark blue glazing',(.015,.07,.10),.6,.19)
 root=group('Assembly')
def label(text,p,size,mat,parent=None):
 curve=bpy.data.curves.new('Stencil','FONT');curve.body=text;curve.size=size;curve.extrude=.001;curve.align_x='CENTER'
 ob=bpy.data.objects.new('Stencil '+text,curve);bpy.context.collection.objects.link(ob);ob.location=p;ob.rotation_euler=(math.pi/2,0,math.pi);ob.data.materials.append(mat)
 bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');ob.select_set(False);attach(ob,parent or root)
def export(name,batch=True):
 bpy.ops.wm.save_as_mainfile(filepath=str(HERE/(name+'.blend')))
 if batch:batch_children(root)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB')
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in obs:o.data.calc_loop_triangles()
 report[name]={'triangles':sum(len(o.data.loop_triangles) for o in obs),'meshes':len(obs)}
def pipe(points,r=.12):
 for a,b in zip(points,points[1:]):
  beam('Pipe',a,b,r,m['metal'],root,16)
  va,vb=Vector(a),Vector(b);v=(vb-va).normalized()
  for p in [va+v*.12,vb-v*.12]:beam('Flange',p-v*.035,p+v*.035,r*1.32,m['dark'],root)
def panelbox(p,size):
 box('Equipment frame',p,size,m['dark'],.10,root)
 x,y,z=p;w,d,h=size
 box('Painted panel',(x,y+d*.5+.012,z),(w*.90,.045,h*.83),m['white'],.045,root)
 box('Orange stripe',(x+w*.30,y+d*.5+.04,z),(.13,.018,h*.7),m['orange'],.006,root)
 for sx in [-1,1]:
  for sz in [-1,1]:beam('Fastener',(x+sx*w*.37,y+d*.5+.03,z+sz*h*.32),(x+sx*w*.37,y+d*.5+.06,z+sz*h*.32),.025,m['metal'],root,8)
# Service station, 5 x 4 m footprint, closed exterior.
begin()
box('Plinth',(0,0,.18),(5,4,.36),m['dark'],.12,root)
box('Habitat shell',(0,0,1.75),(4.8,3.8,3.1),m['white'],.32,root)
for x in [-2.25,2.25]:
 for y in [-1.8,1.8]:box('Corner armor',(x,y,1.75),(.28,.3,2.9),m['dark'],.08,root)
box('Roof cap',(0,0,3.26),(5.05,4.05,.24),m['white'],.14,root)
for x in [-1.65,1.65]:
 panelbox((x,1.93,1.55),(1.1,.12,2.25))
 box('Terminal glass',(x,2.02,1.9),(.79,.035,.65),m['glass'],.035,root)
 for z in [1.72,1.87,2.02]:box('Terminal readout',(x,2.045,z),(.48,.015,.024),m['cyan'],.002,root)
box('Airlock frame',(0,1.94,1.45),(1.65,.2,2.65),m['orange'],.16,root)
box('Closed pressure door',(0,2.07,1.46),(1.30,.05,2.35),m['dark'],.1,root)
for x in [-.32,.32]:box('Door leaf',(x,2.105,1.46),(.59,.04,2.17),m['white'],.06,root)
box('Header light',(0,2.09,2.82),(1.3,.15,.08),m['cyan'],.02,root)
label('SERVICE  02',(0,2.14,3.01),.18,m['dark'])
for y in [-1.25,0,1.25]:
 for x in [-2.41,2.41]:
  box('Side inset',(x,y,1.8),(.06,.93,1.9),m['dark'],.06,root)
  for z in [1.1,1.35,1.6,1.85,2.1,2.35]:box('Cooling louver',(x*1.01,y,z),(.07,.8,.09),m['metal'],.016,root)
for x in [-1.35,1.35]:
 panelbox((x,-.35,3.55),(1.55,2.1,.45))
 for y in [-1,-.6,-.2,.2,.6]:box('Radiator fin',(x,y,3.85),(1.35,.065,.26),m['metal'],.008,root)
pipe([(-2,-1.5,.4),(-2,-1.5,3.8),(0,-1.5,3.8)])
beam('Mast',(1.9,-1.4,3.4),(1.9,-1.4,6.3),.075,m['metal'],root)
for z in [4.5,5.1,5.7]:beam('Antenna element',(1.2,-1.4,z),(2.6,-1.4,z),.025,m['dark'],root)
beam('Mast beacon',(1.9,-1.4,6.3),(1.9,-1.4,6.46),.09,m['red'],root)
export('service-station')
# Horizontal oxygen reservoir and supported manifold; mounted behind existing cylinders.
begin()
for x in [-1.6,1.6]:
 box('Tank saddle',(x,0,.7),(.4,2.0,1.4),m['dark'],.08,root)
beam('Pressure tank',(-2.4,0,2),(2.4,0,2),1.05,m['white'],root,40)
for x in [-2.1,-1,1,2.1]:beam('Tank band',(x-.045,0,2),(x+.045,0,2),1.08,m['dark'],root,40)
box('Label plate',(0,1.015,2),(1.8,.05,.72),m['white'],.05,root);label('O2',(0,1.06,1.74),.65,m['dark'])
pipe([(-2.4,0,2),(-3,0,2),(-3,0,4.5),(0,0,4.5),(0,0,3)],.17)
for x in [-2.8,2.8]:box('Pipe support',(x,0,1.5),(.15,.4,3),m['dark'],.025,root)
export('oxygen-reservoir')
# Boundary module, landing lamps and panelized deck surfaces.
begin();box('Wall footing',(0,0,.14),(4,.6,.28),m['dark'],.05,root)
box('Wall armor',(0,0,.75),(3.95,.34,1.0),m['white'],.08,root)
for x in [-1.85,0,1.85]:box('Wall rib',(x,0,.78),(.12,.47,1.25),m['dark'],.025,root)
box('Safety band',(0,.185,.93),(3.65,.025,.14),m['orange'],.006,root)
root.scale.z=1.5
export('perimeter-wall')
begin();box('Lamp foot',(0,0,.09),(.5,.5,.18),m['dark'],.04,root);box('Lamp stem',(0,0,.46),(.23,.23,.65),m['dark'],.03,root)
box('Lamp diffuser',(0,0,.78),(.30,.30,.28),material('Warm landing light',(.95,.5,.16),0,.5,1.2),.025,root)
box('Lamp cap',(0,0,.96),(.39,.39,.08),m['metal'],.02,root);export('landing-lamp')
# Cargo cover: distinct latches, recessed panels, corners and lift sockets.
begin();panelbox((0,0,.65),(1.6,1.25,1.3))
box('Rear panel',(0,-.637,.65),(1.35,.045,1.05),m['white'],.04,root)
box('Rear stripe',(.40,-.665,.65),(.13,.015,.85),m['orange'],.006,root)
for x in [-.79,.79]:box('Side armor',(x,0,.65),(.04,.97,.88),m['white'],.035,root)
for side in [-1,1]:
 for y in [-.54,.54]:box('Corner protector',(side*.72,y,.65),(.16,.18,1.3),m['dark'],.04,root)
 for z in [.16,1.14]:box('Band',(side*.79,0,z),(.04,1.1,.13),m['metal'],.015,root)
 for y in [-.4,0,.4]:box('Side seam',(side*.80,y,.65),(.025,.045,.75),m['dark'],.005,root)
for x in [-.5,.5]:
 box('Lid latch',(x,.66,1.10),(.18,.10,.26),m['metal'],.025,root)
 box('Lift socket',(x,-.63,.25),(.31,.04,.18),m['rubber'],.025,root)
box('Lid',(0,0,1.31),(1.5,1.15,.09),m['white'],.05,root)
for x in [-.52,.52]:box('Lid rib',(x,0,1.37),(.07,1.05,.04),m['dark'],.01,root)
label('CARGO',(0,.665,.53),.16,m['dark']);export('cargo-crate')
# A solar/radiator array can be placed outside movement corridors.
begin()
for x in [-1.9,1.9]:beam('Array support',(x,0,0),(x,0,2.3),.10,m['metal'],root)
box('Array frame',(0,0,2.4),(4.8,2.5,.13),m['dark'],.04,root)
for x in [-1.8,-.6,.6,1.8]:
 for y in [-.6,.6]:
  box('Photovoltaic panel',(x,y,2.49),(1.12,1.1,.035),m['glass'],.015,root)
  for dx in [-.36,-.12,.12,.36]:box('Cell trace',(x+dx,y,2.513),(.012,1.02,.005),m['metal'],0,root)
export('solar-array')
# Breakable assemblies: each Target mesh has a matched Remnant with preserved origin.
for family in ['battery-rack','pressure-valves','control-console','supply-case']:
 begin()
 if family=='battery-rack':
  panelbox((0,0,.45),(1.7,.8,.9));positions=[(-.5,0,1.15),(0,0,1.15),(.5,0,1.15)]
 elif family=='pressure-valves':
  pipe([(-.8,0,.3),(-.8,0,1.0),(.8,0,1.0),(.8,0,.3)],.12);positions=[(-.5,0,1.3),(0,0,1.3),(.5,0,1.3)]
 elif family=='control-console':
  panelbox((0,0,.7),(1.5,.65,1.4));positions=[(-.37,.36,1.25),(.37,.36,1.25)]
 else:
  panelbox((0,0,.45),(1.4,.85,.9));positions=[(-.35,.44,.53),(.35,.44,.53)]
 # Batch static chassis first; target components must stay independent for hit testing.
 batch_children(root)
 for i,p in enumerate(positions):
  if family=='battery-rack':
   target=box('Target'+str(i),p,(.30,.38,.62),m['orange'],.055,root)
   box('Remnant'+str(i),(p[0],p[1],p[2]-.12),(.25,.35,.30),m['dark'],.025,root)
  elif family=='pressure-valves':
   target=box('Target'+str(i),p,(.26,.30,.33),m['orange'],.045,root)
   box('Remnant'+str(i),(p[0],p[1],p[2]-.10),(.13,.18,.13),m['metal'],.02,root)
  else:
   target=box('Target'+str(i),p,(.59,.055,.44),m['glass'] if family=='control-console' else m['orange'],.025,root)
   box('Remnant'+str(i),p,(.55,.06,.39),m['dark'],.005,root)
  if family=='battery-rack':
   box('Charge strip',(p[0],p[1]+.198,p[2]),(.055,.016,.36),m['cyan'],.006,target)
   box('Cell cap',(p[0],p[1],p[2]+.32),(.26,.34,.055),m['metal'],.015,target)
  elif family=='pressure-valves':
   bpy.ops.mesh.primitive_torus_add(major_radius=.14,minor_radius=.025,major_segments=16,minor_segments=6,location=(p[0],p[1]+.18,p[2]),rotation=(math.pi/2,0,0))
   wheel=bpy.context.object;wheel.name='Valve wheel';wheel.data.materials.append(m['yellow']);attach(wheel,target)
   beam('Valve cross',(p[0]-.12,p[1]+.18,p[2]),(p[0]+.12,p[1]+.18,p[2]),.016,m['metal'],target)
  elif family=='control-console':
   for j in range(4):box('Readout',(p[0]-.04,p[1]+.034,p[2]-.12+j*.075),(.36-j*.035,.008,.014),m['cyan'],.002,target)
  else:box('Hatch handle',(p[0],p[1]+.06,p[2]),(.22,.07,.05),m['metal'],.01,target)
  # Remnants hidden at runtime; both states authored in the source.
 export(family,False)
# Continuous lunar ridges: sculpted geometry and a reusable baked mineral surface.
begin();rock=material('Lunar basalt',(.26,.28,.31),0,.96)
size=512
rng=np.random.default_rng(61105)
f=np.fft.fftfreq(size);fy,fx=np.meshgrid(f,f);freq=np.sqrt(fx*fx+fy*fy);freq[0,0]=1
v=np.fft.ifft2(np.fft.fft2(rng.normal(size=(size,size)))/np.maximum(freq,.008)**1.15).real
v=(v-v.mean())/v.std();base=np.clip(.38+v*.035,.26,.50)
pixels=np.stack([base*.94,base*.97,base,np.ones_like(base)],-1)
im=bpy.data.images.new('Moon mineral albedo',width=size,height=size);im.pixels.foreach_set(pixels.astype(np.float32).ravel());im.pack()
matnode=rock.node_tree.nodes.new('ShaderNodeTexImage');matnode.image=im;rock.node_tree.links.new(matnode.outputs['Color'],rock.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
verts=[];N=201
for j in range(N):
 for i in range(N):
  x=-110+i*1.1;y=-110+j*1.1;d=max(abs(x)-22,abs(y)-24);fade=min(1,max(0,d/17))
  n=noise.fractal(Vector((x*.035,y*.035,7.3)),1.0,2,4)
  ridge=abs(math.sin(math.atan2(y,x)*6+.6))*5+9
  h=fade*(ridge+9*n+1.8*noise.noise(Vector((x*.3,y*.3,2))))
  h*=max(.15,1-max(0,d-55)/65)
  verts.append((x,y,h-.35))
faces=[]
for j in range(N-1):
 for i in range(N-1):
  x=-110+(i+.5)*1.1;y=-110+(j+.5)*1.1
  if abs(x)<22 and abs(y)<24:continue
  a=j*N+i;faces.extend([(a,a+1,a+N+1),(a,a+N+1,a+N)])
me=bpy.data.meshes.new('Ridged crater rim');me.from_pydata(verts,[],faces);me.materials.append(rock);me.update();ob=bpy.data.objects.new('Continuous lunar terrain',me);bpy.context.collection.objects.link(ob);attach(ob,root)
uv=me.uv_layers.new()
for poly in me.polygons:
 for loop in poly.loop_indices:
  p=me.vertices[me.loops[loop].vertex_index].co;uv.data[loop].uv=(p.x/17,p.y/17)
export('lunar-terrain')
(HERE/'asset-stats.json').write_text(json.dumps(report,indent=2)+'\n');print('ENVIRONMENT_ASSETS_PASS',report)
