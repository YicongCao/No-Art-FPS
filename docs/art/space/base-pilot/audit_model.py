"""Run in an isolated background Blender; preserve raw source, normalize test copy."""
import bpy, json, sys, math, time
from pathlib import Path
from mathutils import Vector, Matrix
root=Path(__file__).resolve().parent
raw=Path(sys.argv[sys.argv.index('--')+1]).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
t0=time.monotonic()
bpy.ops.import_scene.gltf(filepath=str(raw))
objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
# Observed generated front is +X; rotate to the project contract of -Z in Godot.
rotation=Matrix.Rotation(math.pi/2,4,'Z')
points=[rotation@o.matrix_world@Vector(c) for o in objs for c in o.bound_box]
lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
size=hi-lo
scale=12/size.x
pivot=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
# Bake all transforms into vertices to avoid hierarchy-dependent normalization.
for o in objs:
 world=rotation@o.matrix_world
 o.parent=None
 for v in o.data.vertices:v.co=(world@v.co-pivot)*scale
 o.matrix_world.identity()
 bpy.context.view_layer.objects.active=o
 o.select_set(True)
 o.data.update()
materials=[]
for m in bpy.data.materials:
 nodes=list(m.node_tree.nodes) if m.use_nodes else []
 materials.append({'name':m.name,'nodes':[n.type for n in nodes], 'images':[n.image.name for n in nodes if n.type=='TEX_IMAGE' and n.image]})
meshstats=[]
for o in objs:
 me=o.data;me.calc_loop_triangles()
 adj=[[] for _ in me.vertices]
 for e in me.edges:
  a,b=e.vertices;adj[a].append(b);adj[b].append(a)
 seen=set();groups=[]
 for i in range(len(adj)):
  if i in seen:continue
  stack=[i];seen.add(i);count=0
  while stack:
   a=stack.pop();count+=1
   for b in adj[a]:
    if b not in seen:seen.add(b);stack.append(b)
  groups.append(count)
 import bmesh
 bm=bmesh.new();bm.from_mesh(me)
 meshstats.append({'name':o.name,'vertices':len(me.vertices),'triangles':len(me.loop_triangles),'materials':len(me.materials),'uv_layers':len(me.uv_layers),'connected_components':len(groups),'component_vertex_sizes':sorted(groups,reverse=True)[:20],'boundary_edges':sum(e.is_boundary for e in bm.edges),'nonmanifold_edges':sum(not e.is_manifold for e in bm.edges)})
 bm.free()
images=[{'name':i.name,'size':list(i.size),'channels':i.channels} for i in bpy.data.images if i.size[0]]
report={'oriented_size_blender_xyz':list(size),'front_alignment_blender_z_degrees':90,'normalized_width_m':12,'normalized_size_blender_xyz':[v*scale for v in size],'scale':scale,'meshes':meshstats,'materials':materials,'images':images,'raw_bytes':raw.stat().st_size,'processing_seconds':time.monotonic()-t0,'notes':['Blender Z-up; glTF export converts to Godot Y-up.','Connectivity is geometric, not semantic editable modules.','Boundary count can include intentional seams; requires visual interpretation.']}
(root/'mesh-audit.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
for i in bpy.data.images:
 if i.source=='FILE':
  try:i.pack()
  except RuntimeError:pass
out=root.parents[3]/'art_source/space/base-pilot/base-pilot.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(out))
bpy.ops.export_scene.gltf(filepath=str(root/'lab/model.glb'),export_format='GLB',use_selection=False)
print('PILOT_AUDIT',json.dumps(report,ensure_ascii=False))
