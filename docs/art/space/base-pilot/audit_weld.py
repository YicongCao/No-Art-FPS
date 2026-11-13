"""Read-only topology diagnostic on a temporary welded BMesh copy."""
import bpy,bmesh,json
from pathlib import Path
p=Path(__file__).resolve().parent
r=json.loads((p/'mesh-audit.json').read_text())
for o in [o for o in bpy.data.objects if o.type=='MESH']:
 bm=bmesh.new();bm.from_mesh(o.data)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.00001)
 seen=set();groups=[]
 for v in bm.verts:
  if v in seen:continue
  seen.add(v);stack=[v];n=0
  while stack:
   a=stack.pop();n+=1
   for e in a.link_edges:
    b=e.other_vert(a)
    if b not in seen:seen.add(b);stack.append(b)
  groups.append(n)
 r['welded_diagnostic']={'tolerance_m':0.00001,'vertices':len(bm.verts),'faces':len(bm.faces),'components':len(groups),'largest_components_vertices':sorted(groups,reverse=True)[:20],'boundary_edges':sum(e.is_boundary for e in bm.edges),'nonmanifold_edges':sum(not e.is_manifold for e in bm.edges),'note':'Temporary copy only; UV seams split raw topology. Not a cleanup or a semantic decomposition.'}
 bm.free()
(p/'mesh-audit.json').write_text(json.dumps(r,indent=2,ensure_ascii=False))
print(r['welded_diagnostic'])
