"""Deterministic production exports. Editable hybrid source is never overwritten."""
import bpy, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'assets/models/space'; OUT.mkdir(parents=True,exist_ok=True)
def palette_batch(label):
 """Batch opaque constant PBR surfaces; keep textures/emission in separate passes."""
 objects=[];palette=[]
 for o in bpy.context.scene.objects:
  if o.type!='MESH' or len(o.data.materials)!=1:continue
  m=o.data.materials[0];p=m.node_tree.nodes.get('Principled BSDF')
  if not p or any(n.type=='TEX_IMAGE' for n in m.node_tree.nodes):continue
  if p.inputs['Emission Strength'].default_value>0:continue
  if m not in palette:palette.append(m)
  objects.append(o)
 if len(objects)<2:return
 size=max(8,len(palette));pixels=[]
 for y in range(size):
  for x in range(size):
   p=palette[min(x,len(palette)-1)].node_tree.nodes.get('Principled BSDF')
   pixels.extend([1,p.inputs['Roughness'].default_value,p.inputs['Metallic'].default_value,1])
 image=bpy.data.images.new(label+'_PBR',width=size,height=size)
 image.colorspace_settings.name='Non-Color';image.pixels=pixels;image.pack()
 material=bpy.data.materials.new(label+'_Palette');material.use_nodes=True
 nodes=material.node_tree.nodes;links=material.node_tree.links;p=nodes.get('Principled BSDF')
 # glTF base-color images are sRGB; encode constant linear PBR colors explicitly.
 def srgb(v):return 12.92*v if v<=.0031308 else 1.055*v**(1/2.4)-.055
 colors=[]
 for y in range(size):
  for x in range(size):
   col=palette[min(x,len(palette)-1)].node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value
   colors.extend([srgb(col[0]),srgb(col[1]),srgb(col[2]),1])
 color_image=bpy.data.images.new(label+'_Albedo',width=size,height=size)
 color_image.colorspace_settings.name='Non-Color';color_image.pixels=colors;color_image.pack()
 albedo=nodes.new('ShaderNodeTexImage');albedo.image=color_image;albedo.interpolation='Closest'
 links.new(albedo.outputs['Color'],p.inputs['Base Color'])
 tex=nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest'
 split=nodes.new('ShaderNodeSeparateColor');links.new(tex.outputs['Color'],split.inputs['Color'])
 links.new(split.outputs['Green'],p.inputs['Roughness']);links.new(split.outputs['Blue'],p.inputs['Metallic'])
 for o in objects:
  old=o.data.materials[0]
  while o.data.uv_layers:o.data.uv_layers.remove(o.data.uv_layers[0])
  uv=o.data.uv_layers.new(name='MaterialParameters')
  for v in uv.data:v.uv=((palette.index(old)+.5)/size,.5)
  if 'PaintColor' in o.data.color_attributes:o.data.color_attributes.remove(o.data.color_attributes['PaintColor'])
  o.data.materials.clear();o.data.materials.append(material)
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name=label+'_OpaquePalette'

bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_source/space/base-hybrid/base-hybrid.blend'))
# Closed exterior: batch across the original assembly boundaries by material.
for m in list(bpy.data.materials):
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and len(o.data.materials)==1 and o.data.materials[0]==m]
 if not objects:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 if len(objects)>1:bpy.ops.object.join()
 o=objects[0]; world=o.matrix_world.copy();o.parent=None;o.matrix_world=world;o.name='Static_'+m.name
for o in list(bpy.context.scene.objects):
 if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
palette_batch('Base')
bpy.ops.export_scene.gltf(filepath=str(OUT/'base.glb'),export_format='GLB')
for o in bpy.context.scene.objects:
 if o.type=='MESH':o.data.calc_loop_triangles()
stats={'base_triangles':sum(len(o.data.loop_triangles) for o in bpy.context.scene.objects if o.type=='MESH'),'base_meshes':len([o for o in bpy.context.scene.objects if o.type=='MESH'])}
bpy.ops.wm.read_factory_settings(use_empty=True)
# Six surface families. Wear is subordinate to the saturated design colors.
def material(name,color,metal=0,rough=.55,emission=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 return m
white=material('Ceramic paint',(.48,.47,.43),.05,.58)
dark=material('Graphite chassis',(.055,.075,.10),.7,.42)
orange=material('Safety orange',(.70,.14,.045),.05,.5)
metal=material('Machined alloy',(.28,.32,.35),.85,.3)
cyan=material('Status cyan',(.06,.65,.8),0,.35,2)
rubber=material('Polymer',(.018,.023,.027),0,.88)
def box(name,p,size,mat,bevel=.04):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 if bevel:
  b=o.modifiers.new('Manufactured edges','BEVEL');b.width=bevel;b.segments=2;bpy.ops.object.modifier_apply(modifier=b.name)
 return o
def cyl(name,p,r,depth,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=depth,location=p);o=bpy.context.object;o.name=name;o.data.materials.append(mat)
 b=o.modifiers.new('Rim bevel','BEVEL');b.width=.035;b.segments=2;bpy.ops.object.modifier_apply(modifier=b.name)
 for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
 return o
def export(name):
 for m in [white,dark,orange,metal,cyan,rubber]:
  obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials[0]==m]
  if not obs:continue
  bpy.ops.object.select_all(action='DESELECT')
  for o in obs:o.select_set(True)
  bpy.context.view_layer.objects.active=obs[0]
  if len(obs)>1:bpy.ops.object.join()
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/space/trial'/(name+'.blend')))
 palette_batch(name)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB')
 for o in list(bpy.context.scene.objects):bpy.data.objects.remove(o,do_unlink=True)
box('Crate chassis',(0,0,.65),(1.45,1.10,1.06),dark,.09)
box('Shell',(0,0,.67),(1.53,1.18,1.12),white,.07)
for x in [-.58,.58]:
 box('Load straps',(x,0,.68),(.13,1.28,1.36),dark,.025)
 for y in [-.65,.65]:box('Latch',(x,y,.67),(.22,.07,.28),metal,.025)
for y in [-.605,.605]:
 box('Recess handle',(0,y,.94),(.45,.035,.11),dark,.025)
 box('Orange marking',(.25,y,.40),(.32,.025,.43),orange,.01)
 box('Status',(-.35,y,.40),(.15,.03,.045),cyan,.01)
export('crate')
for x in [-.64,.64]:box('Oxygen feet',(x,0,.14),(.24,1.1,.28),dark)
cyl('Tank barrel',(0,0,1.12),.58,1.7,white)
for z in [.35,1.7]:cyl('Tank band',(0,0,z),.62,.15,dark)
cyl('Shoulder',(0,0,2),.42,.22,metal);cyl('Valve',(0,0,2.2),.15,.2,orange)
cyl('Status collar',(0,0,1.82),.59,.045,cyan)
box('Service panel',(0,-.58,1.1),(.42,.08,.55),orange)
export('oxygen')
# Industrial tower: visible silhouette, supported vertical vessels, large flanges.
for x in [-1.2,1.2]:
 for y in [-.8,.8]:box('Tower leg',(x,y,1.6),(.24,.24,3.2),dark)
for z in [.3,2.7]:box('Frame',(0,0,z),(3,2.2,.22),metal)
for x in [-.77,.77]:
 cyl('Pressure vessel',(x,0,4.6),.64,4.0,white)
 for z in [2.8,4.2,6.2]:cyl('Flange',(x,0,z),.69,.15,dark)
 cyl('Signal band',(x,0,5.8),.655,.055,cyan)
 cyl('End cap',(x,0,6.65),.45,.16,metal)
 box('Identity stripe',(x,-.635,4.9),(.19,.025,1.2),orange,.01)
export('industrial')
(ROOT/'docs/art/space/review-a/asset-build.json').write_text(json.dumps(stats,indent=2)+'\n')
print('SPACE_ASSETS_READY',stats)
