extends Node3D
## Rain-market-only materials, lighting and a shared reflection for the main sloping aisle.
const SURFACE = preload("res://assets/shaders/market_surface.gdshader")
const HALO = preload("res://assets/shaders/market_lamp_halo.gdshader")
const DETAIL = preload("res://assets/textures/rain_market/surface_noise.png")
const REFLECTION_LAYER = 1 << 18
var arena: Node3D
var reflection: SubViewport
var mirror: Camera3D
var reflection_paint: ShaderMaterial
var plane_normal := Vector3(0,1,3.7/36.0).normalized()
var plane_point := Vector3(0,1.878,0)
var elapsed := 0.0
var enabled := true
var cache: Dictionary = {}

func setup(map: Node3D) -> void:
	arena = map
	name = "MarketLookdev"
	arena.puddles.set_shader_parameter("detail_noise",DETAIL)
	configure_materials()
	configure_lighting()
	configure_fixture_halos()
	if DisplayServer.get_name()!="headless":configure_reflection()

func configure_materials() -> void:
	for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh or mesh.material_override:continue
		for surface in range(mesh.mesh.get_surface_count()):
			var original = mesh.get_active_material(surface) as StandardMaterial3D
			if not original or original.emission_enabled or original.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:continue
			# Static kits from tools/maps/bake_vertex_light.py carry occlusion in their vertex colours.
			var baked: bool = mesh.mesh is ArrayMesh and (mesh.mesh as ArrayMesh).surface_get_format(surface)&Mesh.ARRAY_FORMAT_COLOR!=0
			var key := str(original.get_instance_id())+":"+str(baked)
			if not cache.has(key):
				var paint := ShaderMaterial.new()
				paint.shader = SURFACE
				paint.set_shader_parameter("detail_noise",DETAIL)
				paint.set_shader_parameter("base_color",original.albedo_color)
				paint.set_shader_parameter("use_vertex_color",baked)
				var kind := 0
				if original.resource_name in ["metal","steel","ink","gold"]:kind = 1
				elif original.resource_name in ["asphalt","road","concrete","grout","tile"]:kind = 2
				elif original.resource_name=="canvas":kind = 3
				if kind==2 and original.resource_name in ["asphalt","road"]:
					paint.set_shader_parameter("base_color",Color("47556c"))
					paint.set_shader_parameter("ground_surface",true)
				paint.set_shader_parameter("surface_kind",kind)
				paint.set_shader_parameter("canopy_surface",arena.get_node("Architecture/canopy").is_ancestor_of(mesh) and original.resource_name in ["blue","canvas","turq"])
				paint.set_shader_parameter("base_roughness",.43 if kind==1 else (.77 if kind==2 else original.roughness))
				paint.set_shader_parameter("base_metallic",.32 if kind==1 and original.resource_name!="ink" else 0.0)
				cache[key] = paint
			mesh.set_surface_override_material(surface,cache[key])

func configure_lighting() -> void:
	arena.sun_color = Color("ffcb8e")
	arena.sun_energy = .15
	arena.game.sun.light_color = arena.sun_color
	arena.game.sun.light_energy = arena.sun_energy
	var env: Environment = arena.environment_override
	env.ambient_light_color = Color("a7c7ff")
	env.ambient_light_energy = .36
	env.ssao_enabled = true
	env.ssao_radius = .38
	env.ssao_intensity = .65
	env.ssao_power = 1.25
	env.ssao_light_affect = .12
	env.glow_enabled = true
	env.glow_intensity = .26
	env.glow_bloom = .06
	env.glow_hdr_threshold = .85
	env.fog_enabled = true
	env.fog_light_color = Color("d1b398")
	env.fog_light_energy = .65
	env.fog_density = .0015
	env.fog_sky_affect = .12
	preload("res://scripts/maps/toy_palette.gd").apply(arena.map_id,env,arena.game.sun,false)
	preload("res://scripts/maps/toy_look.gd").apply(env)
	for light in arena.find_children("*","SpotLight3D",true,false):
		if light in arena.frenzy_lights:continue
		light.light_color = Color("ffd08c")
		light.light_energy *= 2.0
		light.spot_attenuation = .7
	# Fill the gaps between existing practical lights without adding shadow passes.
	for z in [-10.0,0.0,10.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(0,(18-z)*3.7/36.0+3.45,z)
		light.light_color = Color("ffcc86")
		light.light_energy = 1.1
		light.omni_range = 6.0
		light.omni_attenuation = 1.4
		add_child(light)
	# Chrome WebGL rejects the probe cube capture depth blit on this renderer.
	# The independent planar viewport remains enabled on Web.
	if OS.has_feature("web"):return
	var probe := ReflectionProbe.new()
	probe.name = "MarketEnvironment"
	probe.position = Vector3(0,4.3,0)
	probe.size = Vector3(37,12,39)
	probe.origin_offset = Vector3(0,0,0)
	probe.intensity = .55
	probe.interior = true
	probe.box_projection = true
	probe.cull_mask = REFLECTION_LAYER
	add_child(probe)

func configure_fixture_halos() -> void:
	# Soft fixture glow works in Compatibility without a full-screen bloom pass.
	var paint := ShaderMaterial.new()
	paint.shader = HALO
	var positions: Array[Vector3] = []
	for z in [-15.0,-10.0,-5.0,0.0,5.0,10.0,15.0]:
		positions.append(Vector3(0,(18-z)*3.7/36.0+3.60,z))
	for x in [-6.2,6.2]:
		for z in [-12.0,-8.0,-1.0,3.0,9.0,13.0,16.0]:
			positions.append(Vector3(x,(18-z)*3.7/36.0+2.52,z))
	for at in positions:
		var glow := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(1.8,1.2) if is_zero_approx(at.x) else Vector2(1.2,1.2)
		glow.mesh = quad
		glow.material_override = paint
		glow.position = at
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(glow)

func configure_reflection() -> void:
	# Keep ground, transparent weather, viewmodel and screen effects out of the mirror.
	for mesh: MeshInstance3D in arena.find_children("*","MeshInstance3D",true,false):
		if mesh.is_in_group("market_wet_film"):continue
		if arena.get_node("Architecture/street").is_ancestor_of(mesh):continue
		if mesh.material_override is ShaderMaterial and mesh.material_override.shader in [arena.RAIN_SHADER,arena.HARBOUR_SHADER,arena.PIPE_SPRAY_SHADER]:continue
		mesh.layers |= REFLECTION_LAYER
	reflection = SubViewport.new()
	reflection.name = "AisleReflection"
	reflection.size = Vector2i(640,360)
	reflection.world_3d = get_viewport().world_3d
	reflection.transparent_bg = false
	reflection.render_target_update_mode = SubViewport.UPDATE_DISABLED
	reflection.msaa_3d = Viewport.MSAA_DISABLED
	reflection.own_world_3d = false
	add_child(reflection)
	mirror = Camera3D.new()
	mirror.cull_mask = REFLECTION_LAYER
	mirror.far = 80
	mirror.near = .08
	var env := arena.environment_override.duplicate() as Environment
	env.ssao_enabled = false
	env.glow_enabled = false
	mirror.environment = env
	reflection.add_child(mirror)
	mirror.current = true
	reflection_paint = arena.puddles
	reflection_paint.set_shader_parameter("reflection_tex",reflection.get_texture())

func _process(delta: float) -> void:
	if not mirror:return
	var camera := get_viewport().get_camera_3d()
	if not camera:return
	elapsed += delta
	var mobile: bool = arena.game.touch_mode
	var width := 384 if mobile else 640
	var aspect := get_viewport().get_visible_rect().size.aspect()
	var size := Vector2i(width,roundi(width/aspect))
	if reflection.size!=size:reflection.size = size
	# Refresh together with the projection matrix to avoid sliding during camera motion.
	if elapsed < (1.0/20.0 if mobile else 1.0/30.0):return
	elapsed = 0.0
	var distance := plane_normal.dot(camera.global_position-plane_point)
	var central := absf(camera.global_position.x)<18.5 and camera.global_position.z>-19.0 and camera.global_position.z<19.5
	var active := enabled and central and distance>.15 and camera.projection==Camera3D.PROJECTION_PERSPECTIVE
	reflection_paint.set_shader_parameter("reflection_enabled",active)
	if not active:return
	mirror.global_position = camera.global_position-2.0*distance*plane_normal
	var forward := (-camera.global_basis.z).bounce(plane_normal)
	var up := camera.global_basis.y.bounce(plane_normal)
	mirror.look_at(mirror.global_position+forward,up)
	mirror.fov = camera.fov
	mirror.keep_aspect = camera.keep_aspect
	var projection := mirror.get_camera_projection()
	reflection_paint.set_shader_parameter("reflection_matrix",projection*Projection(mirror.global_transform.affine_inverse()))
	reflection.render_target_update_mode = SubViewport.UPDATE_ONCE
