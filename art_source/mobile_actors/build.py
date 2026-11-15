"""Fold cosmetic actor meshes into their articulated part; retain all gameplay pivots."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
KEEP=set('Torso Vest BrokenVest Helmet Head Visor LeftArm RightArm RightHand LeftHand LeftLeg RightLeg EnemyGun BackPlate ChestPlate LeftFin BrokenLeftFin LeftHorn LeftPad LeftPadTrim RightPad'.split())
for actor in ['enemy','rusher']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/toy'/f'{actor}.glb'))
 all_meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 # Blender imports glTF colour factors in linear space. Encode material response
 # into UV and UV2 for one opaque, lit Godot surface per moving part.
 for o in all_meshes:
  color=o.data.color_attributes.get('Color') or o.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
  for layer in list(o.data.uv_layers):o.data.uv_layers.remove(layer)
  o.data.uv_layers.new(name='UVMap')
  o.data.uv_layers.new(name='MaterialResponse')
  for poly in o.data.polygons:
   m=o.data.materials[poly.material_index];p=m.node_tree.nodes.get('Principled BSDF')
   c=p.inputs['Base Color'].default_value;rough=p.inputs['Roughness'].default_value;metal=p.inputs['Metallic'].default_value
   emission=max(p.inputs['Emission Color'].default_value[:3])*p.inputs['Emission Strength'].default_value
   for li in poly.loop_indices:
    color.data[li].color=(*c[:3],1.0)
    # glTF flips V on export; Godot retains that flip for imported UVs.
    o.data.uv_layers[0].data[li].uv=(rough,1.0-min(1,emission))
    o.data.uv_layers[1].data[li].uv=(metal,1.0-min(1,emission))
 groups={}
 for o in all_meshes:
  owner=o
  if o.name not in KEEP:
   owner=o.parent
   while owner and owner.name not in KEEP:owner=owner.parent
  groups.setdefault(owner,[]).append(o)
 # Reparent protected nodes out of decorative parents before joins remove them.
 for o in list(bpy.context.scene.objects):
  if o.name in KEEP and o.parent and o.parent.name not in KEEP:
   parent=o.parent
   while parent and parent.name not in KEEP:parent=parent.parent
   world=o.matrix_world.copy();o.parent=parent;o.matrix_world=world
 common=bpy.data.materials.new('MobileActorVertexPaint');common.use_nodes=True
 vc=common.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='Color';common.node_tree.links.new(vc.outputs['Color'],common.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
 for owner,meshes in groups.items():
  for o in meshes:
   o.data.materials.clear();o.data.materials.append(common)
  bpy.ops.object.select_all(action='DESELECT')
  for o in meshes:o.select_set(True)
  primary=owner if owner in meshes else meshes[0]
  bpy.context.view_layer.objects.active=primary
  keep_name=primary.name if owner else 'BodyDetails'
  if len(meshes)>1:bpy.ops.object.join()
  primary.name=keep_name
 bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).resolve().parent/f'{actor}.blend'))
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/toy'/f'{actor}_mobile.glb'),export_format='GLB',export_yup=True,export_apply=True)
 print('MOBILE_ACTOR',actor,'meshes',sum(o.type=='MESH' for o in bpy.context.scene.objects))
