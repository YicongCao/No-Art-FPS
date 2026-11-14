"""Normalize original cloud meshes into the project's Z-up authoring convention."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[3]
LOCAL=ROOT/'artifacts/local/space-review-b'
report={}
for name in ['rifle-mech','assault-mech','interceptor']:
 raw=next((LOCAL/name).rglob('model.glb'))
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(raw))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 # Tripo's canonical front is +X for this generation family; inspect both views.
 rotation=Matrix.Rotation(math.pi/2,4,'Z')
 points=[rotation@o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 lo=Vector([min(p[i] for p in points) for i in range(3)]);hi=Vector([max(p[i] for p in points) for i in range(3)]);size=hi-lo
 factor=min(11.0/size.x,11.0/size.y) if name=='interceptor' else 1.95/size.z
 pivot=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
 for o in meshes:
  transform=rotation@o.matrix_world;o.parent=None
  for v in o.data.vertices:v.co=(transform@v.co-pivot)*factor
  o.matrix_world=Matrix.Identity(4);o.name=name;o.data.update()
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
 bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=meshes[0]
 if len(meshes)>1:bpy.ops.object.join()
 source=bpy.context.object;source.data.calc_loop_triangles()
 for im in bpy.data.images:
  if im.source=='FILE':im.pack()
 bpy.ops.wm.save_as_mainfile(filepath=str(LOCAL/(name+'-normalized.blend')))
 bpy.ops.export_scene.gltf(filepath=str(LOCAL/(name+'-normalized.glb')),export_format='GLB')
 report[name]={'normalized_size_xyz':[v*factor for v in size],'rotation_z':90,'triangles':len(source.data.loop_triangles),'materials':len(source.data.materials)}
(LOCAL/'normalization.json').write_text(json.dumps(report,indent=2)+'\n');print('NORMALIZED',report)
