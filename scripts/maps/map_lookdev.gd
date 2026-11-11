extends RefCounted
## First-pass material and light direction. Preserve each map's geometry and special shaders.
const DETAIL = preload("res://assets/textures/rain_market/dry_roughness.png")
const PROFILES = {
 "yard":["ffe2ae","acc9f4",.90,1.06],
 "amusement_park":["ffd39c","b5c3ff",.86,1.12],
 "last_ferry":["ffd39b","9bbde9",.82,1.16],
 "night_studio":["ffd8ab","adb6ef",.82,1.13],
 "sandgate":["ffe0a8","b6cbe8",.92,1.06],
 "bb_office":["ffe6c0","c1d6ec",.88,1.07],
 "hogwarts":["ffcf99","9eb9ed",.86,1.13],
 "baggage_below":["ffe1b2","b7d3e9",.86,1.10],
 "snowline":["ffd6b4","a8ccff",.91,1.08],
 "palm_house":["ffe0a0","b6d8df",.90,1.12],
 "ginza_station":["ffe6bf","afcde9",.86,1.12],
}
static func apply(arena: Node3D, environment: Environment) -> void:
 if arena.map_id=="rain_market" or arena.has_meta("lookdev_v1"):return
 if not PROFILES.has(arena.map_id):return
 arena.set_meta("lookdev_v1",true)
 var profile: Array = PROFILES[arena.map_id]
 arena.sun_color = arena.sun_color.lerp(Color(profile[0]),.45)
 if arena.game:arena.game.sun.light_color = arena.sun_color
 if environment:
  environment.ambient_light_color = environment.ambient_light_color.lerp(Color(profile[1]),.40)
  environment.ambient_light_energy *= profile[2]
 var materials: Dictionary = {}
 for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh or mesh.material_override:continue
  for index in range(mesh.mesh.get_surface_count()):
   var original = mesh.get_active_material(index) as StandardMaterial3D
   if not original or original.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or original.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED:continue
   var key := original.get_instance_id()
   if not materials.has(key):
    var paint := original.duplicate() as StandardMaterial3D
    if original.emission_enabled:
     paint.emission_energy_multiplier *= profile[3]
    else:
     var color := paint.albedo_color
     paint.albedo_color = Color.from_hsv(color.h,minf(color.s*1.09,1.0),color.v,color.a)
     if not paint.roughness_texture and not paint.albedo_texture:
      paint.roughness_texture = DETAIL
      paint.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
      paint.roughness = clampf(paint.roughness*1.35,.28,1.0)
      paint.uv1_scale = Vector3(3,3,3)
    materials[key] = paint

   mesh.set_surface_override_material(index,materials[key])
 for light in arena.find_children("*","Light3D",true,false):
  # Leave authored alarm and animated stage-light controllers in control.
  if light is OmniLight3D and not light.shadow_enabled:light.light_energy *= 1.08
 arena.set_meta("lookdev_materials",materials.size())
 arena.set_meta("lookdev_resources",materials)
