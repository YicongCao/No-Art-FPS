extends Node3D
## Four original 9:16 pixel illustrations on solid office walls, outside doorway bounds.
const ART = [
 preload("res://assets/art/office_posters/sky_courier.png"),
 preload("res://assets/art/office_posters/arena_guardians.png"),
 preload("res://assets/art/office_posters/citrus_racers.png"),
 preload("res://assets/art/office_posters/lantern_observatory.png"),
]
const PLACEMENTS = [Vector3(-20.1,1.93,-11.94),Vector3(-3.78,1.93,-11.94),Vector3(3.78,1.93,-11.94),Vector3(10,1.93,16.09)]
func _ready() -> void:
 name="OfficePosters"
 var border := StandardMaterial3D.new()
 border.albedo_color=Color("222b43")
 border.roughness=.8
 for i in range(ART.size()):
  var mount:=Node3D.new()
  mount.name="Poster%d"%i
  mount.position=PLACEMENTS[i]
  if i==3:mount.rotation.y=PI
  add_child(mount)
  var frame:=MeshInstance3D.new()
  var box:=BoxMesh.new();box.size=Vector3(1.2,2.075,.045)
  frame.mesh=box;frame.position.z=-.015;frame.material_override=border
  mount.add_child(frame)
  var face:=MeshInstance3D.new()
  face.name="Illustration"
  var quad:=QuadMesh.new();quad.size=Vector2(1.125,2.0)
  face.mesh=quad;face.position.z=.012
  var paint:=StandardMaterial3D.new()
  paint.albedo_texture=ART[i]
  paint.roughness=1.0
  paint.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
  face.material_override=paint
  face.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  mount.add_child(face)
