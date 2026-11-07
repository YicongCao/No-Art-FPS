extends SceneTree

const Park = preload("res://scripts/maps/amusement_park.gd")
const Destructible = preload("res://scripts/destructible.gd")
const Barrel = preload("res://scripts/explosive_barrel.gd")
const PARK_MODELS = "res://assets/models/park/"
var park: Node3D
var groups: Dictionary = {}

func _initialize() -> void:
	generate.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func add(parent: Node, child: Node, label: String) -> Node:
	child.name = label
	parent.add_child(child)
	child.owner = park
	return child

func group(label: String) -> Node3D:
	if not groups.has(label):
		var scenery = Destructible.new()
		scenery.local_bounds = true
		scenery.scenery = true
		scenery.palette = Color("e9ba50") if label in ["Carousel","Coaster","Station"] else Color("4d7d70")
		add(park,scenery,label)
		groups[label] = scenery
		park.structure_paths.append(park.get_path_to(scenery))
	return groups[label]

func model(parent: Node3D, name: String, asset: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	var path = "res://assets/models/"+asset.trim_prefix("../") if asset.begins_with("../") else PARK_MODELS+asset
	var node = load(path+".glb").instantiate()
	add(parent,node,name)
	node.position = at
	node.rotation.y = yaw
	return node

func box(parent: Node3D, at: Vector3, size: Vector3, yaw: float, layer: int) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = at
	body.rotation.y = yaw
	body.collision_layer = layer
	body.collision_mask = 0
	add(parent,body,"Body%d"%parent.get_child_count())
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	add(body,collision,"Collision")
	return body

func marker(parent: Node3D, name: String, at: Vector3) -> Marker3D:
	var node = Marker3D.new()
	add(parent,node,name)
	node.position = at
	return node

func sky() -> Environment:
	var sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://assets/shaders/park_sunset.gdshader")
	var dome = Sky.new()
	dome.sky_material = sky_material
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = dome
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e0def9")
	env.ambient_light_energy = .67
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	return env

func generate() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/amusement_park_layout.json"))
	park = Park.new()
	park.name = "AmusementPark"
	park.map_id = "amusement_park"
	park.sun_rotation_degrees = Vector3(-16,145,0)
	park.sun_color = Color("ffd094")
	park.sun_energy = .44
	park.sun_shadow_bias = .36
	park.environment_override = sky()
	park.process_mode = Node.PROCESS_MODE_DISABLED
	# Populate before adding to the tree. The runtime scene then owns its normal
	# bindings while this tool saves only authored nodes and baked navigation.
	for item in layout.instances:
		var parent = group(item.group) if item.has("group") else park
		var node = model(parent,item.name,item.asset,vec(item.at),item.yaw)
		if item.get("shoot",false):
			var bounds = AABB()
			for mesh in node.find_children("*","MeshInstance3D",true,false):
				var local_box: AABB = node.transform*mesh.transform*mesh.get_aabb()
				bounds = bounds.merge(local_box) if bounds.has_volume() else local_box
			if bounds.has_volume():box(parent,bounds.get_center(),bounds.size,0,16)
	for item in layout.colliders:
		box(group(item.group) if not item.group.is_empty() else park,vec(item.at),vec(item.size),item.yaw,int(item.layer))
	for item in layout.surfaces:
		var parent = group(item.group) if not item.group.is_empty() else park
		var body = StaticBody3D.new()
		body.collision_mask = 0
		add(parent,body,"Surface%d"%parent.get_child_count())
		var collision = CollisionShape3D.new()
		var shape = ConcavePolygonShape3D.new()
		var faces = PackedVector3Array()
		for i in range(0,item.triangles.size(),3):
			faces.append(vec(item.triangles[i]))
			faces.append(vec(item.triangles[i+2]))
			faces.append(vec(item.triangles[i+1]))
		shape.set_faces(faces)
		collision.shape = shape
		add(body,collision,"Surface")

	var carousel = Node3D.new()
	carousel.position = Vector3(0,0,1)
	add(group("Carousel"),carousel,"Turntable")
	park.carousel_path = park.get_path_to(carousel)
	model(carousel,"Deck","carousel_deck",Vector3.ZERO)
	for i in range(8):
		var angle = i*TAU/8
		var horse = model(carousel,"Horse%d"%i,"horse_blue" if i%2==0 else "horse_brick",
			Vector3(cos(angle)*3,0,sin(angle)*3),PI-angle)
		park.horse_paths.append(park.get_path_to(horse))
	# Low solid barriers on the platform edge keep the turntable separate from the plaza.
	for i in range(12):
		var angle = i*TAU/12
		box(group("Carousel"),Vector3(cos(angle)*4.33,.36,1+sin(angle)*4.33),Vector3(.18,.72,2.38),-angle,1)

	var track = Path3D.new()
	track.curve = Curve3D.new()
	track.curve.bake_interval = .22
	for point in layout.track:track.curve.add_point(vec(point))
	track.curve.closed = true
	add(group("Coaster"),track,"RailPath")
	for i in range(3):
		var car = PathFollow3D.new()
		car.rotation_mode = PathFollow3D.ROTATION_ORIENTED
		car.cubic_interp = false
		add(track,car,"Car%d"%i)
		model(car,"Wagon","coaster_car",Vector3.ZERO)
		park.car_paths.append(park.get_path_to(car))

	for label in groups:
		var scenery = groups[label]
		var bounds = AABB()
		for node in scenery.get_children():
			scenery.saved_parts.append(scenery.get_path_to(node))
			if node is StaticBody3D and node.get_child(0).shape is BoxShape3D:
				var size: Vector3 = node.get_child(0).shape.size
				var extent: AABB = node.transform*AABB(-size/2,size)
				bounds = bounds.merge(extent) if bounds.has_volume() else extent
		scenery.bounds = bounds if bounds.has_volume() else AABB(Vector3(-1,0,-1),Vector3(2,2,2))

	for i in range(layout.barrels.size()):
		var barrel = Barrel.new()
		barrel.position = vec(layout.barrels[i])
		add(park,barrel,"Barrel%d"%i)
		park.barrel_paths.append(park.get_path_to(barrel))
	var markers = add(park,Node3D.new(),"Markers")
	park.start_path = park.get_path_to(marker(markers,"PlayerStart",vec(layout.start)))
	for i in range(layout.opening.size()):
		var spawn = marker(markers,"Opening%d"%i,vec(layout.opening[i]))
		spawn.set_meta("fast",i>=6)
		park.opening_paths.append(park.get_path_to(spawn))
	for i in range(layout.spawns.size()):
		park.reinforcement_paths.append(park.get_path_to(marker(markers,"Reinforcement%d"%i,vec(layout.spawns[i]))))
	for i in range(layout.respawns.size()):
		park.respawn_paths.append(park.get_path_to(marker(markers,"Respawn%d"%i,vec(layout.respawns[i]))))
	for i in range(layout.waypoints.size()):
		park.tour_paths.append(park.get_path_to(marker(markers,"Tour%d"%i,vec(layout.waypoints[i]))))
	for i in range(layout.crossings.size()):
		for j in range(2):
			park.tour_paths.append(park.get_path_to(marker(markers,"Shortcut%d_%d"%[i,j],vec(layout.crossings[i][j]))))

	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius = .5
	mesh.agent_height = 2
	mesh.agent_max_climb = .25
	mesh.agent_max_slope = 40
	mesh.cell_size = .25
	mesh.cell_height = .25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = "park_navigation"
	nav.navigation_mesh = mesh
	add(park,nav,"Navigation")
	park.navigation_path = park.get_path_to(nav)
	park.add_to_group("park_navigation",true)
	root.add_child(park)
	nav.bake_navigation_mesh(false)
	assert(mesh.get_polygon_count()>0,"Park navigation bake is empty")
	park.process_mode = Node.PROCESS_MODE_INHERIT
	for node in park.find_children("*","",true,false):
		# Keep the GLB roots as scene instances and author all other local nodes.
		if node.has_meta("structure"):node.remove_meta("structure")
	var packed = PackedScene.new()
	assert(packed.pack(park)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/maps/amusement_park.tscn")==OK)
	print("PARK_SCENE_READY ",mesh.get_polygon_count()," navigation polygons")
	quit()
