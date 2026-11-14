extends SceneTree

var arena: Node3D
var grey = "--grey" in OS.get_cmdline_user_args()
var rng = RandomNumberGenerator.new()
var batches: Dictionary = {}
var materials: Dictionary = {}

func _initialize() -> void:
	build.call_deferred()

func add(parent: Node, node: Node, label: String) -> Node:
	node.name = label
	parent.add_child(node,true)
	node.owner = arena
	return node

func mat(key: String, color: String, metallic: float = 0, roughness: float = .6) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.metallic = metallic
	m.roughness = roughness
	materials[key] = m
	return m

func body(at: Vector3, size: Vector3, angle: float = 0) -> void:
	var b = StaticBody3D.new()
	b.position = at
	b.rotation.x = angle
	b.collision_mask = 0
	add(arena,b,"Collision")
	var c = CollisionShape3D.new()
	var s = BoxShape3D.new()
	s.size = size
	c.shape = s
	add(b,c,"Shape")

func geometry(mesh: Mesh, transform: Transform3D, material: Material) -> void:
	if not batches.has(material):batches[material] = SurfaceTool.new();batches[material].begin(Mesh.PRIMITIVE_TRIANGLES)
	batches[material].append_from(mesh,0,transform)

func box(at: Vector3, size: Vector3, material: Material, solid = true, angle = 0.0) -> void:
	var mesh = BoxMesh.new()
	mesh.size = size
	geometry(mesh,Transform3D(Basis(Vector3.RIGHT,angle),at),material)
	if solid:body(at,size,angle)

func model(asset: String, at: Vector3, angle: float = 0) -> Node3D:
	var n = load("res://assets/models/space/"+asset+".glb").instantiate()
	n.position = at
	n.rotation.y = angle
	add(arena,n,asset.capitalize())
	return n

func marker_paths(label: String, entries: Array) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for i in entries.size():
		var marker = Marker3D.new()
		marker.position = entries[i]
		if label=="Opening" and i%3==1:marker.set_meta("fast",true)
		add(arena,marker,label+str(i))
		paths.append(arena.get_path_to(marker))
	return paths

func build() -> void:
	rng.seed = 61105
	arena = load("res://scripts/maps/moonbase.gd").new()
	arena.name = "Moonbase"
	arena.map_id = "moonbase_trial"
	arena.sun_rotation_degrees = Vector3(-32,-35,0)
	arena.sun_energy = .65
	arena.sun_color = Color("fff2df")
	arena.sun_shadow_bias = .04
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("080d15")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8eacc9")
	env.ambient_light_energy = .30
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	arena.environment_override = env
	var ground = mat("regolith","9b9ea2",0,.96)
	var rock = mat("rock","6d737c",0,.98)
	var white = mat("paint","c4c2b8",.05,.56)
	var dark = mat("chassis","263445",.65,.45)
	var orange = mat("marking","d85c38",.02,.54)
	var rail = mat("rail","dcb04c",.1,.5)
	var alloy = mat("alloy","697582",.8,.35)
	var cyan = mat("light","70cfdf",0,.4)
	cyan.emission_enabled = true
	cyan.emission = Color("70cfdf")
	cyan.emission_energy_multiplier = 1.3
	if not grey:
		# Generate once at authoring time, never run noise per pixel in the game.
		var noise = FastNoiseLite.new()
		noise.seed = 61105
		noise.frequency = .035
		noise.fractal_octaves = 4
		var image = noise.get_seamless_image(512,512,false,false)
		image.save_png("res://assets/models/space/regolith-height.png")
		var normal = image.duplicate()
		normal.bump_map_to_normal_map(.8)
		normal.save_png("res://assets/models/space/regolith-normal.png")
		for y in image.get_height():
			for x in image.get_width():
				var value = .82+image.get_pixel(x,y).r*.14
				image.set_pixel(x,y,Color(value,value,value))
		image.generate_mipmaps()
		normal.generate_mipmaps()
		ground.albedo_texture = ImageTexture.create_from_image(image)
		ground.normal_enabled = true
		ground.normal_texture = ImageTexture.create_from_image(normal)
		ground.normal_scale = .28
		ground.uv1_scale = Vector3(22,24,1)
	box(Vector3(0,-.25,0),Vector3(44,.5,48),ground)
	# Physical boundary is separate from the horizon artwork.
	for x in [-22.4,22.4]:box(Vector3(x,1,0),Vector3(.8,2,49),dark)
	for z in [-24.4,24.4]:box(Vector3(0,1,z),Vector3(44,2,.8),dark)
	# Base front faces the player's southern approach. Interior remains closed.
	if grey:box(Vector3(4,3.6,-19),Vector3(12,7.2,9),white,false)
	else:model("base",Vector3(4,0,-18),PI)
	body(Vector3(4,3.7,-20),Vector3(12,7.4,8))
	# The generated entry ramp (x = +2.22 after rotation) receives a matching collision proxy.
	var ramp_angle = atan2(.94,4.6)
	body(Vector3(6.22,.48,-14.05),Vector3(3.55,.14,4.695),ramp_angle)
	# Independent accessible service deck, two true walkable ramps and a loop below.
	box(Vector3(-7,2.25,-18),Vector3(8,.3,6),dark)
	for x in [-10.6,-3.4]:
		for z in [-20.5,-15.5]:box(Vector3(x,1.1,z),Vector3(.3,2.2,.3),alloy)
	for x in [-9.5,-4.5]:
		box(Vector3(x,1.14,-11),Vector3(2.4,.16,sqrt(64+5.76)),alloy,true,atan2(2.4,8.0))
		for side in [-1,1]:
			for z in range(-15,-6,2):
				var h = (-7-z)*.3
				box(Vector3(x+side*1.17,h+.5,z),Vector3(.06,1,.06),rail,false)
			box(Vector3(x+side*1.17,2.2,-11),Vector3(.055,.055,8.35),rail,false,atan2(2.4,8.0))
	for z in [-20.8,-15.2]:
		for x in range(-11,-2,2):box(Vector3(x,2.9,z),Vector3(.06,1,.06),rail,false)
		if z<-20:box(Vector3(-7,3.4,z),Vector3(8,.06,.06),rail,false)
	# Ship stays inside the approved landing-pad envelope; service station remains a proxy.
	var pad = CylinderMesh.new()
	pad.top_radius = 6;pad.bottom_radius = 6;pad.height = .2;pad.radial_segments = 48
	geometry(pad,Transform3D(Basis.IDENTITY,Vector3(-13,.1,2)),dark)
	if grey:
		box(Vector3(-13,1.5,2),Vector3(5,1.4,8),white)
		box(Vector3(-13,1.4,2.5),Vector3(11,.25,3),dark)
		for x in [-15,-11]:box(Vector3(x,2.8,4),Vector3(.22,2.2,2),orange,false)
	else:
		var ship = model("interceptor",Vector3(-13,.2,2))
		var hull = ship.find_child("Hull",true,false) as MeshInstance3D
		assert(hull != null)
		var collision = StaticBody3D.new()
		collision.collision_mask = 0
		add(hull,collision,"HullCollision")
		var shape = CollisionShape3D.new()
		shape.shape = hull.mesh.create_trimesh_shape()
		add(collision,shape,"Shape")
		var pad_body = StaticBody3D.new()
		pad_body.position = Vector3(-13,.1,2)
		add(arena,pad_body,"LandingPadCollision")
		var pad_shape = CollisionShape3D.new()
		var cylinder = CylinderShape3D.new()
		cylinder.radius=6; cylinder.height=.2
		pad_shape.shape=cylinder
		add(pad_body,pad_shape,"Shape")
	box(Vector3(10,1.6,16),Vector3(5,3.2,4),white)
	# High quality oxygen/industrial corner.
	if grey:box(Vector3(16,3.3,-12),Vector3(3,6.6,2.2),white,false)
	else:model("industrial",Vector3(16,0,-12))
	body(Vector3(16,3.3,-12),Vector3(3,6.6,2.2))
	for at in [Vector3(12,0,-5),Vector3(14,0,-5),Vector3(9,0,-9)]:
		if grey:box(at+Vector3.UP,Vector3(1.2,2,1.2),white,false)
		else:model("oxygen",at)
		body(at+Vector3.UP,Vector3(1.2,2.2,1.2))
	for at in [Vector3(2,0,-7),Vector3(0,0,-6),Vector3(12,0,1),Vector3(-5,0,9),Vector3(7,0,7),Vector3(-16,0,14)]:
		if grey:box(at+Vector3.UP*.65,Vector3(1.6,1.3,1.25),white,false)
		else:model("crate",at)
		body(at+Vector3.UP*.65,Vector3(1.6,1.3,1.25))
	# Overhead industrial feed, supported at both ends.
	for x in [10,16]:box(Vector3(x,3.5,-14),Vector3(.22,7,.22),alloy)
	box(Vector3(13,7,-14),Vector3(6,.45,.45),alloy,false)
	for x in range(10,17):box(Vector3(x,7,-14),Vector3(.10,.58,.58),dark,false)
	if not grey:
		var probe = ReflectionProbe.new()
		probe.position = Vector3(7,3,-9)
		probe.size = Vector3(28,14,28)
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.intensity = .55
		probe.enable_shadows = false
		add(arena,probe,"CornerReflection")
		for i in 42:
			var mesh = SphereMesh.new()
			mesh.radial_segments = 7;mesh.rings = 3;mesh.radius = 1;mesh.height = 2
			var angle = TAU*i/42.0
			var at = Vector3(cos(angle)*rng.randf_range(39,49),rng.randf_range(1,5),sin(angle)*rng.randf_range(40,52))
			geometry(mesh,Transform3D(Basis.IDENTITY.scaled(Vector3(rng.randf_range(6,12),rng.randf_range(4,10),rng.randf_range(6,12))),at),rock)
		for i in 90:
			var mesh = SphereMesh.new();mesh.radial_segments=5;mesh.rings=2
			var at = Vector3(rng.randf_range(-21,21),-.04,rng.randf_range(-23,23))
			geometry(mesh,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*rng.randf_range(.12,.38)),at),rock)
		for at in [Vector3(10,2.2,-14),Vector3(2,2.2,-14)]:
			var lamp = OmniLight3D.new()
			lamp.position=at;lamp.light_color=Color("ffd5a1");lamp.light_energy=1.2;lamp.omni_range=5;lamp.shadow_enabled=false
			add(arena,lamp,"EntryLight")
		for x in [-18,-8,1,12,19]:
			box(Vector3(x,.3,10),Vector3(.18,.6,.18),dark,false)
			box(Vector3(x,.62,10),Vector3(.2,.12,.2),cyan,false)
	for material in batches:
		var mesh = batches[material].commit()
		mesh.surface_set_material(0,material)
		var instance = MeshInstance3D.new();instance.mesh=mesh
		add(arena,instance,"StaticBatch")
	arena.start_path = marker_paths("Start",[Vector3(2,.05,13)])[0]
	arena.get_node(arena.start_path).rotation.y = .30
	arena.opening_paths = marker_paths("Opening",[Vector3(1,.05,0),Vector3(8,.05,-2),Vector3(-4,.05,1),Vector3(17,.05,4),Vector3(-19,.05,-6),Vector3(0,.05,18),Vector3(16,.05,19),Vector3(-16,.05,19)])
	arena.reinforcement_paths = marker_paths("Spawn",[Vector3(-19,.05,-10),Vector3(0,.05,-10),Vector3(19,.05,-10),Vector3(-19,.05,10),Vector3(19,.05,10),Vector3(0,.05,20),Vector3(-17,.05,20),Vector3(17,.05,20),Vector3(-4,.05,-3),Vector3(7,.05,1),Vector3(17,.05,-4),Vector3(-10,.05,14)])
	arena.respawn_paths = marker_paths("Respawn",[Vector3(-19,.05,18),Vector3(19,.05,18),Vector3(0,.05,20),Vector3(-19,.05,-12),Vector3(19,.05,-18),Vector3(0,.05,-10)])
	arena.route_paths = marker_paths("Route",[Vector3(-9.5,2.45,-17),Vector3(-4.5,2.45,-17),Vector3(-20,.05,0),Vector3(20,.05,0)])
	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius=.5;mesh.agent_height=2.0;mesh.agent_max_climb=.25;mesh.agent_max_slope=37
	mesh.cell_size=.25;mesh.cell_height=.25
	mesh.geometry_parsed_geometry_type=NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_source_geometry_mode=NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name="moonbase_navigation"
	mesh.filter_baking_aabb=AABB(Vector3(-22,-.4,-24),Vector3(44,4,48))
	nav.navigation_mesh=mesh
	add(arena,nav,"Navigation")
	arena.navigation_path=arena.get_path_to(nav)
	arena.add_to_group("moonbase_navigation",true)
	root.add_child(arena)
	nav.bake_navigation_mesh(false)
	for i in 30:await physics_frame
	if not arena.validate_navigation():quit(1);return
	var scene = PackedScene.new()
	assert(scene.pack(arena)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/maps/moonbase_trial.tscn")==OK)
	print("MOONBASE_BUILD_PASS grey=",grey," polygons=",mesh.get_polygon_count())
	quit()
