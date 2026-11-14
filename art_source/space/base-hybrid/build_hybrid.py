"""Deterministic local replacement on a copy of the Tripo base; no cloud calls."""
import bpy,bmesh,json,math,time,sys
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'docs/art/space/base-hybrid'
recipe=json.loads((HERE/'recipe.json').read_text())
variant='--variant' in sys.argv
if variant:
 recipe['balcony']['post_pitch']=1.8
 recipe['balcony']['height']=1.25
suffix='-variant' if variant else ''
t0=time.perf_counter()
bpy.ops.wm.open_mainfile(filepath=str(ROOT/recipe['source']))
source=next(o for o in bpy.data.objects if o.type=='MESH')
source.name='Base_StaticShell_Tripo'
# Delete imported triangles by explicit local spatial masks, preserving original UVs.
bm=bmesh.new();bm.from_mesh(source.data)
cut=recipe['cut_regions'];counts=dict(balcony_front=0,balcony_return=0,ramp=0,airlock=0)
remove=[]
for f in bm.faces:
 x,y,z=f.calc_center_median()
 a=cut['balcony_front'];b=cut['balcony_return'];c=cut['ramp'];d=cut['airlock']
 kind=None
 if max(v.co.y for v in f.verts)>a[0] and max(v.co.z for v in f.verts)>a[1] and min(v.co.z for v in f.verts)>4.1 and z<a[2] and y>1.65:kind='balcony_front'
 elif abs(x)>b[0] and y>b[1] and b[2]<z<b[3]:kind='balcony_return'
 elif c[0]<x<c[1] and y>c[2] and z<c[3]:kind='ramp'
 elif d[0]<x<d[1] and y>d[2] and d[3]<z<d[4]:kind='airlock'
 if kind:remove.append(f);counts[kind]+=1
bmesh.ops.delete(bm,geom=remove,context='FACES')
bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
bm.to_mesh(source.data);bm.free();source.data.update()
cut_seconds=time.perf_counter()-t0
materials={}
def mat(name,color,rough=.5,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
 bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
 materials[name]=m;return m
white=mat('Space_WarmWhite',(0.62,.58,.50),.55)
dark=mat('Space_Structure',(.065,.085,.105),.55,.25)
yellow=mat('Space_SafetyYellow',(.75,.41,.045),.38)
orange=mat('Space_AirlockOrange',(.68,.16,.035),.43)
rubber=mat('Space_Gasket',(.018,.023,.028),.85)
metal=mat('Space_BareMetal',(.27,.30,.32),.38,.8)
cyan=mat('Space_StatusCyan',(.025,.52,.60),.35)
bs=next(n for n in cyan.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
bs.inputs['Emission Color'].default_value=(.02,.65,.8,1);bs.inputs['Emission Strength'].default_value=1.5
assembly=None
parts=[]
post_positions=set()
def group(name):
 global assembly
 assembly=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(assembly)
 return assembly
def finish(o,name,m,bevel=0):
 o.name=name;o.data.materials.append(m);o.parent=assembly;parts.append(o)
 if bevel:
  mod=o.modifiers.new('Manufactured edge','BEVEL');mod.width=bevel;mod.segments=2
  mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True
 return o
def box(name,loc,size,m,bevel=.02):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(o,name,m,bevel)
def tube(name,a,b,r,m):
 a,b=Vector(a),Vector(b);v=b-a
 bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=r,depth=v.length,location=(a+b)*.5)
 o=bpy.context.object;o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector((0,0,1)).rotation_difference(v)
 for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
 return finish(o,name,m)
def rail(name,a,b,height,pitch,r):
 a,b=Vector(a),Vector(b);run=Vector((b.x-a.x,b.y-a.y,0)).length
 n=max(1,math.ceil(run/pitch))
 unique=0
 for i in range(n+1):
  p=a.lerp(b,i/n)
  key=(assembly.name,*[round(v,5) for v in p])
  if key in post_positions:continue
  post_positions.add(key);unique+=1
  box(name+'_Foot',p+Vector((0,0,.025)),(.16,.16,.05),dark,.012)
  tube(name+'_Post',p,p+Vector((0,0,height)),r,yellow)
 for level in [.50,height]:tube(name+'_Rail',a+Vector((0,0,level)),b+Vector((0,0,level)),r,yellow)
 return unique
def mesh(name,verts,faces,m):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
 o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
 # Ensure consistent outward normals for the closed manufactured solid.
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
 return finish(o,name,m)
def octagon(w,h,c):
 return [(-w/2+c,0),(w/2-c,0),(w/2,c),(w/2,h-c),(w/2-c,h),(-w/2+c,h),(-w/2,h-c),(-w/2,c)]
def ring(name,cx,y,z,w,h,c,border,depth,m):
 outer=octagon(w,h,c);inner=[(x,z0+border) for x,z0 in octagon(w-2*border,h-2*border,max(.1,c-border*.4))]
 vs=[(cx+x,yy,z+zz) for yy in [y-depth,y] for loop in [outer,inner] for x,zz in loop]
 fs=[]
 for i in range(8):
  j=(i+1)%8
  fs.extend([(i,j,j+8,i+8),(16+i,24+i,24+j,16+j),(i,16+i,16+j,j),(8+i,8+j,24+j,24+i)])
 return mesh(name,vs,fs,m)
# Upper railing: repeated straight manufactured sections, with vertical posts.
group('Balcony_Railing')
b=recipe['balcony'];xmin,xmax,y,z=b['x_min'],b['x_max'],b['front_y'],b['deck_z']
box('Balcony_MountingDeck',(0,(y+b['back_y'])/2,z-.065),(11.45,y-b['back_y']+.18,.13),dark,.025)
box('Balcony_Fascia',(0,y+.035,z-.13),(11.45,.14,.20),dark,.025)
posts=rail('Balcony_Front',(xmin,y,z),(xmax,y,z),b['height'],b['post_pitch'],b['radius'])
for x in [xmin,xmax]:posts+=rail('Balcony_Return',(x,b['back_y'],z),(x,y,z),b['height'],b['post_pitch'],b['radius'])
# Ramp is a closed wedge; its top and tread strips follow one analytical slope.
group('Access_Ramp')
r=recipe['ramp'];cx,w=r['center_x'],r['width'];ya,yb,za,zb=r['door_y'],r['foot_y'],r['door_z'],r['foot_z'];t=r['thickness']
v=[(cx+x,y,z0+dz) for dz in [-t,0] for x,y,z0 in [(-w/2,ya,za),(w/2,ya,za),(w/2,yb,zb),(-w/2,yb,zb)]]
mesh('Ramp_Deck',v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],dark)
slope=math.atan2(zb-za,yb-ya)
for x in [cx-w/2+.10,cx+w/2-.10]:
 o=box('Ramp_Stringer',(x,(ya+yb)/2,(za+zb)/2-.10),(.16,math.hypot(yb-ya,zb-za),.20),white,.025);o.rotation_euler.x=slope
for i in range(1,16):
 f=i/16;y=ya+(yb-ya)*f;z=za+(zb-za)*f
 o=box('Ramp_Tread',(cx,y,z+.018),(w-.38,.075,.035),metal,.008);o.rotation_euler.x=slope
for x in [cx-w/2+.12,cx+w/2-.12]:rail('Ramp',(x,ya,za),(x,yb,zb),r['rail_height'],r['post_pitch'],r['radius'])
# Visible supports reach ground; independent of the playable ramp surface.
for f in [.12,.48,.8]:
 y=ya+(yb-ya)*f;z=za+(zb-za)*f-t
 for x in [cx-w/2+.22,cx+w/2-.22]:box('Ramp_Support',(x,y,max(z,0)/2),(.18,.22,max(z,.03)),dark,.015)
# Door assembly covers the cut seam with a deliberate mounting surround.
group('Airlock_Frame')
a=recipe['airlock'];cx,y,z,w,h=a['center_x'],a['front_y'],a['bottom_z'],a['width'],a['height']
box('Airlock_Mount',(cx,y-.17,z+h/2),(w+.24,.20,h+.23),white,.04)
box('Airlock_Recess',(cx,y-.04,z+h/2),(w-.12,.16,h-.12),rubber,.06)
ring('Airlock_OuterFrame',cx,y+.12,z,w,h,a['corner'],a['frame_width'],a['frame_depth'],orange)
ring('Airlock_InnerGasket',cx,y+.13,z+.22,w-.44,h-.44,.34,.065,.08,rubber)
# Two named closed leaves, their own parents/pivots for future animation.
innerw=w-.62;innerh=h-.57
for sign in [-1,1]:
 group('Airlock_Leaf_Left' if sign<0 else 'Airlock_Leaf_Right')
 x=cx+sign*innerw/4
 box('Door_Leaf',(x,y+.02,z+.28+innerh/2),(innerw/2-.035,.13,innerh),orange,.055)
 for f in [.25,.75]:box('Door_Inset',(x,y+.10,z+.28+innerh*f),(innerw/2-.22,.035,innerh*.38),orange,.04)
 box('Door_Lock',(cx+sign*.13,y+.16,z+h*.5),(.12,.12,.48),dark,.018)
group('Airlock_Service')
for sign in [-1,1]:
 x=cx+sign*(w/2-.12)
 box('Status_Housing',(x,y+.18,z+h*.53),(.16,.12,.52),dark,.02)
 box('Status_Lens',(x,y+.25,z+h*.53),(.065,.025,.33),cyan,.008)
box('Door_Threshold',(cx,y+.12,z-.025),(w-.65,.42,.10),metal,.02)
# Bake modifiers; join within assembly and material to limit draw surfaces, retaining door leaves.
for o in parts:
 bpy.context.view_layer.objects.active=o
 for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
parents=[o for o in bpy.data.objects if o.type=='EMPTY']
for parent in parents:
 for material in materials.values():
  members=[o for o in list(parent.children) if o.type=='MESH' and o.data.materials[0]==material]
  if len(members)<2:continue
  bpy.ops.object.select_all(action='DESELECT')
  for o in members:o.select_set(True)
  bpy.context.view_layer.objects.active=members[0];bpy.ops.object.join()
  members[0].name=parent.name+'_'+material.name
# Set door group origins at each leaf hinge without moving meshes.
for parent in parents:
 if parent.name.startswith('Airlock_Leaf'):
  sign=-1 if parent.name.endswith('Left') else 1
  bpy.context.view_layer.update()
  world={o:o.matrix_world.copy() for o in parent.children};parent.location=(cx+sign*innerw/2,y,z+.28)
  bpy.context.view_layer.update()
  for o,m in world.items():o.matrix_world=m
bpy.context.view_layer.update()
# Structural checks on evaluated coordinates; do not confuse these with player collision tests.
for name in ['Airlock_Leaf_Left','Airlock_Leaf_Right']:
 parent=bpy.data.objects[name]
 coords=[o.matrix_world@Vector(v) for o in parent.children if o.type=='MESH' for v in o.bound_box]
 assert coords and min(v.z for v in coords)>a['bottom_z']-.1
 assert max(v.z for v in coords)<a['bottom_z']+a['height']+.1
 assert max(abs(v.x-a['center_x']) for v in coords)<a['width']/2+.1
assert abs(r['door_z']-a['bottom_z'])<1e-6
assert abs(math.degrees(slope))<15
for o in bpy.data.objects:
 if o.type=='MESH':
  assert all(math.isfinite(v) for vertex in o.data.vertices for v in vertex.co)
stats=[]
for o in bpy.data.objects:
 if o.type=='MESH':o.data.calc_loop_triangles();stats.append({'name':o.name,'triangles':len(o.data.loop_triangles),'materials':len(o.data.materials)})
blend_out=ROOT/'artifacts/local/space-base-hybrid/variant.blend' if variant else HERE/'base-hybrid.blend'
glb_out=ROOT/'artifacts/local/space-base-hybrid/variant.glb' if variant else ROOT/'docs/art/space/base-pilot/lab/hybrid.glb'
blend_out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(blend_out))
bpy.ops.export_scene.gltf(filepath=str(glb_out),export_format='GLB')
report={'removed_triangles_by_mask':counts,'remaining_source_triangles':len(source.data.polygons),'meshes':stats,'total_triangles':sum(o['triangles'] for o in stats),'mesh_count':len(stats),'material_count':len({m.name for o in bpy.data.objects if o.type=='MESH' for m in o.data.materials if m}),'upper_railing_unique_post_count':posts,'ramp_slope_degrees':abs(math.degrees(slope)),'cut_and_load_seconds':cut_seconds,'total_build_export_seconds':time.perf_counter()-t0,'source_preserved':True,'variant':variant,'balcony_height':b['height'],'balcony_pitch':b['post_pitch'],'structural_checks':'finite coordinates; closed door bounds; ramp slope and threshold match passed','note':'Script time is not engineering labor; masks are manually fitted to this mesh. No full collision/gameplay integration.'}
OUT.mkdir(parents=True,exist_ok=True);(OUT/('build-stats'+suffix+'.json')).write_text(json.dumps(report,indent=2)+'\n')
print('HYBRID_RESULT',json.dumps(report))
