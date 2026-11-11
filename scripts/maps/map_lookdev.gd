extends Node3D
## Map-owned materials and fixture receivers. Gameplay geometry remains untouched.
const SURFACE = preload("res://assets/shaders/map_surface.gdshader")
const SPILL = preload("res://assets/shaders/fixture_spill.gdshader")
const DETAIL = preload("res://assets/textures/rain_market/surface_noise.png")
const PROFILES = {
 "yard":[.52,.18,.67,"b5ceef",0.0],
 "amusement_park":[.48,.16,.52,"a7bafa",.0013],
 "last_ferry":[.38,.10,.36,"8db5ea",.0020],
 "night_studio":[.38,.08,.34,"a6b9e1",0.0],
 "sandgate":[.48,.12,.57,"a5c4ef",.0011],
 "bb_office":[.42,.10,.46,"c0d5ef",0.0],
 "hogwarts":[.42,.10,.48,"a4bde8",.0028],
 "baggage_below":[.42,.10,.47,"b2c9e4",0.0],
 "snowline":[.40,.08,.58,"b1cfff",.0025],
 "palm_house":[.34,.06,.48,"c4e1df",.0006],
 "ginza_station":[.38,.08,.43,"bccde5",0.0],
}
var arena: Node3D
var cache: Dictionary = {}
var receivers: Array[Dictionary] = []
var fixture_count := 0
var frenzy := false
var mirror: Camera3D
var reflection: SubViewport
var water: ShaderMaterial
const REFLECTION_LAYER = 1 << 19

static func apply(map: Node3D, _environment: Environment) -> void:
 if not PROFILES.has(map.map_id):return
 if map.has_node("MapLookdev"):
  map.get_node("MapLookdev").apply_state(map.game.destroy_active)
  return
 var component = load("res://scripts/maps/map_lookdev.gd").new()
 component.name = "MapLookdev"
 component.arena = map
 map.add_child(component)
 component.setup()

func setup() -> void:
 configure_materials()
 configure_fixtures()
 configure_atmosphere()
 if arena.map_id=="last_ferry" and DisplayServer.get_name()!="headless":configure_reflection()
 arena.set_meta("lookdev_v1",true)
 arena.set_meta("lookdev_materials",cache.size())
 arena.set_meta("lookdev_resources",cache)
 arena.set_meta("lookdev_fixtures",fixture_count)
 apply_state(false)

func apply_state(active: bool) -> void:
 frenzy = active
 var profile: Array = PROFILES[arena.map_id]
 var env: Environment = arena.game.world_environment.environment
 if env:
  env.ambient_light_color = Color(profile[3]) if not active else env.ambient_light_color
  env.ambient_light_energy = profile[2] if not active else minf(env.ambient_light_energy,.55)
  env.ssao_enabled = true
  env.ssao_radius = .48
  env.ssao_intensity = .85
  env.ssao_power = 1.3
  env.ssao_light_affect = .15
  env.glow_enabled = true
  env.glow_intensity = .23
  env.glow_bloom = .025
  env.glow_hdr_threshold = 1.1
  env.fog_enabled = profile[4]>0
  env.fog_density = profile[4]
  env.fog_light_color = Color(profile[3])
  env.fog_light_energy = .65
  env.fog_sky_affect = .12
 if not active:
  if arena.map_id in ["bb_office","night_studio","ginza_station","baggage_below"]:arena.game.sun.light_energy = .18
  elif arena.map_id=="snowline":arena.game.sun.light_energy = .48
 for material in cache.values():
  if material is ShaderMaterial:material.set_shader_parameter("daylight",0.0 if active else 1.0)

func classify(label: String) -> int:
 if label in ["metal","steel","iron","galvanized","copper","bronze","brass","gold","rail","frame","duct_joint"]:return 1
 if label in ["stone","rock","rock_light","flagstone","plaster","concrete","sand","clay","brick","grout","paving","pavement"]:return 2
 if label in ["wood","wood_light","wood_dark","timber","oak","deck","plank","trunk","crate","sleeper"]:return 3
 if label in ["carpet","carpet_dark","carpet_light","cable","rubber"]:return 4
 if label in ["leaf","leaf_light","grass","turf","turf_dark","hedge","hedge_light","palm","palm_light","palm_dark","monstera","banana","lawn","lawn_dark","pine"]:return 5
 if label in ["snow","snow_lit","frost"]:return 6
 if label in ["tile","terrazzo","terrazzo_dark"]:return 7
 if label=="lake":return 8
 return 0

func configure_materials() -> void:
 for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
  if not mesh.mesh or mesh.material_override is ShaderMaterial:continue
  var surfaces: Array = [-1] if mesh.material_override else range(mesh.mesh.get_surface_count())
  for index in surfaces:
   var original = (mesh.material_override if index==-1 else mesh.get_active_material(index)) as StandardMaterial3D
   if not original or original.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or original.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED:continue
   var key := str(original.get_instance_id())+":"+str(mesh.get_path()).get_slice("/",3)
   if not cache.has(key):
    var canopy_bulb: bool = arena.map_id=="amusement_park" and "CarouselCanopy" in str(mesh.get_path()) and original.resource_name=="gold_light"
    if original.emission_enabled or original.albedo_texture or canopy_bulb:
     var copy := original.duplicate() as StandardMaterial3D
     if canopy_bulb:
      copy.emission_enabled=true;copy.emission=Color("ffd18a");copy.emission_energy_multiplier=1.2
     elif copy.emission_enabled:copy.emission_energy_multiplier *= 1.35
     cache[key] = copy
    else:
     var material := ShaderMaterial.new()
     material.shader = SURFACE
     var kind := classify(original.resource_name)
     var context := str(mesh.get_path()).to_lower()
     if arena.map_id=="yard" and ("container" in context or "forklift" in context):kind=1
     if arena.map_id=="amusement_park" and "carousel" in context and original.resource_name in ["gold","gold_light"]:kind=1
     if arena.map_id=="night_studio" and "curtain" in context:kind=4
     var roughness := .64
     var metallic := 0.0
     match kind:
      1:roughness = .28;metallic = .65
      2:roughness = .92
      3:roughness = .67
      4:roughness = .98
      5:roughness = .87
      6:roughness = .94
      8:roughness = .24
      7:roughness = .29
     if arena.map_id=="night_studio" and original.resource_name=="floor":roughness = .36
     if original.resource_name in ["ice","glass","window","display_glass","glass_blue","laptop_glass"]:roughness = .19;metallic = .18
     if original.resource_name=="soil":roughness = .58
     material.set_shader_parameter("base_color",original.albedo_color)
     material.set_shader_parameter("detail_noise",DETAIL)
     material.set_shader_parameter("kind",kind)
     material.set_shader_parameter("roughness_value",roughness)
     material.set_shader_parameter("metallic_value",metallic)
     material.set_shader_parameter("roof_pattern",arena.map_id=="palm_house" and original.resource_name in ["paving","paving_dark","stone","gravel"])
     cache[key] = material
   if index==-1:mesh.material_override=cache[key]
   else:mesh.set_surface_override_material(index,cache[key])

# Extract separate fixture boxes from their original mesh, before material names are replaced.
# Spatial clustering joins duplicated triangle vertices but never merges different lamps.
func fixture_centers(mesh: MeshInstance3D, surface: int) -> Array[Vector3]:
 var arrays := mesh.mesh.surface_get_arrays(surface)
 var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
 var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
 var groups: Dictionary = {}
 var parent: Dictionary = {}
 var keys: Array[Vector3i] = []
 for v in vertices:
  var key := Vector3i((v*1000.0).round())
  keys.append(key)
  parent[key] = key
 for i in range(0,indices.size(),3):
  var a = root_key(parent,keys[indices[i]])
  for j in [1,2]:
   var b = root_key(parent,keys[indices[i+j]])
   parent[b] = a
 for key in parent:
  var r = root_key(parent,key)
  if not groups.has(r):groups[r] = []
  groups[r].append(Vector3(key)/1000.0)
 var result: Array[Vector3] = []
 for group in groups.values():
  var center := Vector3.ZERO
  for v in group:center += v
  result.append(mesh.to_global(center/group.size()))
 return result

func root_key(parent: Dictionary, key: Vector3i) -> Vector3i:
 var current := key
 while parent[current]!=current:current = parent[current]
 return current

func configure_fixtures() -> void:
 var id: String = arena.map_id
 if id=="bb_office":
  for x in [-21,-14,-7,0,7,14,21]:
   for z in [-17,-11,-5,1,7,13,18]:add_receiver(Vector3(x,3.39,z),Vector2(3.5,2.5),Color("ffe4bc"),.40)
 elif id=="ginza_station":
  for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
   if not mesh.mesh:continue
   if not "fluorescent_tubes" in str(mesh.get_path()).to_lower():continue
   for surface in range(mesh.mesh.get_surface_count()):
    for at in fixture_centers(mesh,surface):add_receiver(at-Vector3.UP*.10,Vector2(2.0,3.0),Color("fff1d9"),.27,"station")
 elif id=="baggage_below":
  for i in range(arena.airport_power.fixtures.size()):
   add_receiver(arena.airport_power.to_global(arena.airport_power.fixtures[i])-Vector3.UP*.15,Vector2(3.2,2.9),Color("fff0ca"),.35,"airport",i)
 elif id=="amusement_park":
  for i in range(12):
   var angle := TAU*i/12.0
   add_receiver(Vector3(cos(angle)*3.8,3.1,1+sin(angle)*3.8),Vector2(1.9,1.9),Color("ffd08a"),.45)
  for node in arena.find_children("Lamp*","Node3D",true,false):
   if node.get_parent()==arena:add_receiver(node.global_position+Vector3(.2,3.2,0),Vector2(2.4,2.4),Color("ffce8a"),.4)
 else:
  var wanted: Array = {"last_ferry":["lamp"],"hogwarts":["window","amber"],"snowline":["light"],"palm_house":["lamp"]}.get(id,[])
  for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
   if not mesh.mesh or mesh.material_override:continue
   for surface in range(mesh.mesh.get_surface_count()):
    var original := mesh.mesh.surface_get_material(surface)
    if not original or not original.resource_name in wanted:continue
    for at in fixture_centers(mesh,surface):
     if fixture_count>=120:break
     add_receiver(at-Vector3.UP*.2,Vector2(2.8,2.8),Color("ffcb83"),.48)
 # Existing moving spots remain the authoritative source for stage/searchlight illumination.
 for light in arena.find_children("*","SpotLight3D",true,false):
  if id in ["night_studio","last_ferry"]:
   light.light_energy *= 1.65
   light.spot_attenuation = .65

func configure_atmosphere() -> void:
 if arena.map_id!="palm_house":return
 var sweep = preload("res://scripts/maps/sweeping_light.gd")
 for x in [-3.5,3.5]:
  var light = sweep.add_spot(self,"RoofSunshaft",Vector3(x,7,0),Color("fff0cb"),.6,9.0,12,false)
  light.look_at(Vector3(x+2.4,.2,2))
  sweep.add_shaft(light,6.8,.12,5.0,.09)
  receivers.append({"node":light,"mode":"station"})

func add_receiver(at: Vector3, extent: Vector2, tint: Color, strength: float, mode: String="normal", fixture: int=-1) -> void:
 var space := get_world_3d().direct_space_state
 var vertices := PackedVector3Array()
 var uv := PackedVector2Array()
 var colors := PackedColorArray()
 var steps := 10
 var samples: Array = []
 for z in range(steps+1):
  for x in range(steps+1):
   var tex := Vector2(float(x)/steps,float(z)/steps)
   var target := at+Vector3((tex.x*2-1)*extent.x,-12,(tex.y*2-1)*extent.y)
   var top := Vector3(target.x,at.y,target.z)
   var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top,target,1))
   if not hit.is_empty():
    var obstruction := space.intersect_ray(PhysicsRayQueryParameters3D.create(at,hit.position+hit.normal*.025,1))
    if not obstruction.is_empty() and obstruction.position.distance_to(hit.position)>.10:hit = {}
   samples.append({"uv":tex,"hit":hit})
 for z in range(steps):
  for x in range(steps):
   var a := z*(steps+1)+x
   for triangle in [[a,a+steps+1,a+1],[a+1,a+steps+1,a+steps+2]]:
    var valid := true
    var low := 999.0
    var high := -999.0
    for i in triangle:
     var h: Dictionary = samples[i].hit
     if h.is_empty() or h.normal.y<.65:valid=false;break
     low = minf(low,h.position.y);high=maxf(high,h.position.y)
    if not valid or high-low>.3:continue
    for i in triangle:
     var h: Dictionary = samples[i].hit
     vertices.append(h.position+h.normal*.014)
     uv.append(samples[i].uv)
     colors.append(Color(1,1,1,1))
 if vertices.is_empty():return
 var arrays := [];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_COLOR]=colors
 var normals := PackedVector3Array();normals.resize(vertices.size());normals.fill(Vector3.UP);arrays[Mesh.ARRAY_NORMAL]=normals
 var shape := ArrayMesh.new();shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var paint := ShaderMaterial.new();paint.shader=SPILL
 paint.set_shader_parameter("tint",tint);paint.set_shader_parameter("strength",strength)
 paint.set_shader_parameter("fixture_position",at)
 paint.set_shader_parameter("polish",0.65 if arena.map_id=="ginza_station" else (.25 if arena.map_id=="last_ferry" else 0.0))
 var receiver := MeshInstance3D.new();receiver.mesh=shape;receiver.material_override=paint
 receiver.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(receiver)
 receivers.append({"node":receiver,"paint":paint,"mode":mode,"fixture":fixture,"strength":strength})
 fixture_count+=1
 if fixture_count<=2:
  var light := OmniLight3D.new();light.position=at;light.light_color=tint;light.light_energy=1.0;light.omni_range=5
  add_child(light)
  receivers[-1]["light"]=light

func configure_reflection() -> void:
 var sea := arena.get_node_or_null("HarborWater") as MeshInstance3D
 if not sea:return
 water=sea.material_override
 if not water:return
 for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
  if mesh==sea:continue
  if mesh.material_override is ShaderMaterial and mesh.material_override.shader!=SURFACE:continue
  mesh.layers |= REFLECTION_LAYER
 reflection=SubViewport.new();reflection.size=Vector2i(640,360)
 reflection.world_3d=get_viewport().world_3d
 reflection.render_target_update_mode=SubViewport.UPDATE_DISABLED
 add_child(reflection)
 mirror=Camera3D.new();mirror.cull_mask=REFLECTION_LAYER;mirror.far=250;mirror.near=.1
 reflection.add_child(mirror);mirror.current=true
 water.set_shader_parameter("reflection_tex",reflection.get_texture())

func _process(_delta: float) -> void:
 for entry in receivers:
  if entry.mode=="station":
   entry.node.visible=not frenzy
   if entry.has("light"):entry.light.visible=not frenzy
  elif entry.mode=="airport":
   var color: Color = arena.airport_power.ceiling.get_instance_color(entry.fixture)
   var brightness := clampf((color.r-.204)/.796,0,1)
   entry.paint.set_shader_parameter("strength",entry.strength*brightness)
   if entry.has("light"):entry.light.light_energy=brightness
 if not mirror:return
 var camera := get_viewport().get_camera_3d()
 if not camera:return
 var aspect := get_viewport().get_visible_rect().size.aspect()
 reflection.size=Vector2i(640,roundi(640/aspect))
 mirror.global_position=camera.global_position-Vector3.UP*2.0*(camera.global_position.y+3.72)
 mirror.look_at(mirror.global_position+(-camera.global_basis.z).bounce(Vector3.UP),camera.global_basis.y.bounce(Vector3.UP))
 mirror.fov=camera.fov;mirror.keep_aspect=camera.keep_aspect
 water.set_shader_parameter("harbor_capture_active",true)
 reflection.render_target_update_mode=SubViewport.UPDATE_ONCE
