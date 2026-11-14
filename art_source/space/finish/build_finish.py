"""Surface finishing, close rocks and ordnance; all textures baked at authoring time."""
import bpy,sys,math,numpy as np,json
from pathlib import Path
from mathutils import Vector,noise
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];sys.path.insert(0,str(HERE.parent/'heroes'))
from geometry import *
OUT=ROOT/'assets/models/space'
size=256;rng=np.random.default_rng(71114)
f=np.fft.fftfreq(size);fy,fx=np.meshgrid(f,f);rad=np.sqrt(fx*fx+fy*fy)
v=np.fft.ifft2(np.fft.fft2(rng.normal(size=(size,size)))/np.maximum(rad,.012)**.9).real;v=(v-v.mean())/v.std()
scratches=np.zeros((size,size),np.float32)
for i in range(340):
 x,y=rng.integers(0,size,2);length=int(rng.integers(2,19));scratches[y,x:min(size,x+length)]=rng.uniform(.25,.85)
height=v*.018-scratches*.09;dy,dx=np.gradient(height)
normal=np.stack([.5-dx*2,.5-dy*2,np.ones_like(v),np.ones_like(v)],-1)
def img(name,pixels):
 im=bpy.data.images.new(name,width=size,height=size);im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(pixels.astype(np.float32).ravel());im.pack();return im
def finish():
 changed=set();shared_normal=None
 for mat in list(bpy.data.materials):
  if not mat.use_nodes:continue
  ns=mat.node_tree.nodes;ls=mat.node_tree.links;p=ns.get('Principled BSDF')
  if not p or any(n.type=='TEX_IMAGE' for n in ns) or p.inputs['Emission Strength'].default_value>0:continue
  base=np.array(p.inputs['Base Color'].default_value[:3]);metal=p.inputs['Metallic'].default_value;rough=p.inputs['Roughness'].default_value
  if rough>.9:continue
  color=base[None,None,:]*np.clip(1+v[:,:,None]*.025,.88,1.035)
  is_paint=metal<.3 and base.max()>.1
  if is_paint:color=color*(1-scratches[:,:,None]*.55)+np.array([.10,.12,.14])*scratches[:,:,None]*.55
  color=np.where(color<=.0031308,color*12.92,1.055*np.maximum(color,0)**(1/2.4)-.055)
  albedo=img(mat.name+' worn paint',np.concatenate([color,np.ones((size,size,1))],-1))
  orm=img(mat.name+' surface response',np.stack([np.clip(1-abs(v)*.015,0,1),np.clip(rough+v*.035-scratches*.13,.18,.98),np.clip(metal+scratches*.7 if is_paint else np.full_like(v,metal),0,1),np.ones_like(v)],-1))
  tex=ns.new('ShaderNodeTexImage');tex.image=albedo;ls.new(tex.outputs['Color'],p.inputs['Base Color'])
  tex=ns.new('ShaderNodeTexImage');tex.image=orm;split=ns.new('ShaderNodeSeparateColor');ls.new(tex.outputs['Color'],split.inputs['Color']);ls.new(split.outputs['Green'],p.inputs['Roughness']);ls.new(split.outputs['Blue'],p.inputs['Metallic'])
  tex=ns.new('ShaderNodeTexImage');tex.image=shared_normal or img('Shared scratches normal',normal);shared_normal=tex.image;n=ns.new('ShaderNodeNormalMap');n.inputs['Strength'].default_value=.35;ls.new(tex.outputs['Color'],n.inputs['Color']);ls.new(n.outputs['Normal'],p.inputs['Normal']);changed.add(mat)
 for ob in bpy.context.scene.objects:
  if ob.type!='MESH' or not any(m in changed for m in ob.data.materials):continue
  uv=ob.data.uv_layers.active or ob.data.uv_layers.new()
  for poly in ob.data.polygons:
   if ob.data.materials[poly.material_index] not in changed:continue
   axis=max(range(3),key=lambda a:abs(poly.normal[a]));axes=[a for a in range(3) if a!=axis]
   for loop in poly.loop_indices:
    p=ob.matrix_world@ob.data.vertices[ob.data.loops[loop].vertex_index].co;uv.data[loop].uv=(p[axes[0]]*1.5,p[axes[1]]*1.5)
def export(name,batch=False):
 selected=next((arg.split('=',1)[1] for arg in sys.argv if arg.startswith('--asset=')),None)
 if selected and name!=selected:return
 finish();bpy.ops.wm.save_as_mainfile(filepath=str(HERE/(name+'.blend')))
 if batch:
  roots=[o for o in bpy.context.scene.objects if o.parent is None and o.type=='EMPTY']
  for root in roots:batch_children(root)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB')
for path in sorted((HERE.parent/'environment').glob('*.blend')):
 bpy.ops.wm.open_mainfile(filepath=str(path))
 if path.stem=='lunar-terrain':
  for ob in bpy.context.scene.objects:
   if ob.type=='MESH':
    for p in ob.data.polygons:p.use_smooth=True
 export(path.stem,path.stem not in ['battery-rack','pressure-valves','control-console','supply-case'])
# Preserve headroom on first-person white paint under the camera key/rim lights.
bpy.ops.wm.open_mainfile(filepath=str(HERE.parent/'heroes/ion-rifle.blend'))
for mat in bpy.data.materials:
 p=mat.node_tree.nodes.get('Principled BSDF') if mat.use_nodes else None
 if p and mat.name.startswith('Lunar ceramic'):p.inputs['Base Color'].default_value=(.30,.29,.26,1)
 if p and mat.name.startswith('Machined alloy'):p.inputs['Roughness'].default_value=.5
export('ion-rifle',True)
for name in ['oxygen','industrial']:
 bpy.ops.wm.open_mainfile(filepath=str(HERE.parent/'trial'/(name+'.blend')));export(name,True)
# Armored grenade and separate throwing hand use the original throw timing and physics.
bpy.ops.wm.read_factory_settings(use_empty=True);m=palette();root=group('LunarGrenade')
beam('Core',(0,0,-.08),(0,0,.13),.095,m['dark'],root,16)
for i in range(8):
 a=i*math.tau/8;ob=box('Armor',(math.cos(a)*.079,math.sin(a)*.079,.01),(.065,.045,.18),m['white'],.012,root);ob.rotation_euler.z=a+math.pi/2
beam('Charge ring',(0,0,.10),(0,0,.12),.101,m['cyan'],root,24)
box('Safety lever',(0,.025,.15),(.07,.18,.035),m['orange'],.008,root)
beam('Fuse cap',(0,0,.13),(0,0,.16),.046,m['metal'],root);export('lunar-grenade',True)
bpy.ops.wm.read_factory_settings(use_empty=True);m=palette();root=group('ThrowGlove')
box('Palm',(0,0,0),(.14,.12,.09),m['rubber'],.035,root)
for i in range(4):
 x=-.05+i*.034
 box('Finger base',(x,.075,.015),(.026,.075,.045),m['rubber'],.012,root)
 box('Curled finger',(x,.09,.06),(.026,.035,.065),m['rubber'],.012,root)
 box('Finger tip',(x,.065,.095),(.026,.045,.025),m['rubber'],.01,root)
box('Thumb',(.095,.015,.01),(.055,.09,.045),m['rubber'],.016,root)
beam('Forearm',(0,-.06,-.02),(.03,-.45,-.13),.075,m['dark'],root)
box('Gauntlet',(.025,-.25,-.05),(.15,.27,.10),m['white'],.025,root)
box('Gauntlet stripe',(.025,-.25,.01),(.12,.07,.015),m['orange'],.005,root);export('lunar-glove',True)
for seed in range(4):
 bpy.ops.wm.read_factory_settings(use_empty=True);root=group('LunarRock');bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3,radius=1);ob=bpy.context.object;ob.name='Fractured basalt';attach(ob,root)
 mat=material('Basalt',(.16,.18,.21),0,.89);ob.data.materials.append(mat)
 for vert in ob.data.vertices:
  p=vert.co.copy();p*=1+noise.noise(p*3+Vector((seed*7,2,4)))*.22;p.z=max(0,p.z*.7+.3);vert.co=p
 for p in ob.data.polygons:p.use_smooth=True
 export('rock-'+str(seed))
print('SURFACE_FINISH_PASS')
