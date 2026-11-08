extends SceneTree

const Arena = preload("res://scripts/maps/concept_arena.gd")
const Prop = preload("res://scripts/maps/concept_prop.gd")
const Barrel = preload("res://scripts/explosive_barrel.gd")
const BELT_SHADER = preload("res://assets/shaders/baggage_belt.gdshader")
const SIGN_FOLDER = "res://assets/art/arena_signs/"
var arena: Node3D
var models: Dictionary = {}

func _initialize() -> void:
	build.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func add(parent: Node, node: Node, label: String) -> Node:
	node.name = label
	parent.add_child(node)
	node.owner = arena
	return node

func model(parent: Node3D, asset: String, label: String) -> Node3D:
	if not models.has(asset):
		models[asset] = load("res://assets/models/%s/%s.glb"%[arena.map_id,asset])
	return add(parent,models[asset].instantiate(),label)

func body_with_shape(parent: Node3D, shape: Shape3D, at: Vector3, angle: float) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = at
	body.rotation.y = angle
	body.collision_mask = 0
	add(parent,body,"Body%d"%parent.get_child_count())
	var collider = CollisionShape3D.new()
	collider.shape = shape
	add(body,collider,"Collision")
	return body

func box(parent: Node3D, center: Vector3, size: Vector3, angle: float = 0.0) -> StaticBody3D:
	var shape = BoxShape3D.new()
	shape.size = size
	return body_with_shape(parent,shape,center,angle)

func slab(parent: Node3D, corners: Array, thickness: float) -> void:
	var points = PackedVector3Array()
	for corner in corners:
		var point = vec(corner)
		points.append(point)
		points.append(point-Vector3.UP*thickness)
	var shape = ConvexPolygonShape3D.new()
	shape.points = points
	body_with_shape(parent,shape,Vector3.ZERO,0)

func props(items: Array) -> void:
	var parent = add(arena,Node3D.new(),"Props")
	for item in items:
		var part = Prop.new()
		part.position = vec(item.at)
		part.rotation.y = item.angle
		part.scenery = not item.structural
		part.structural_section = item.structural
		part.local_bounds = true
		part.impact_kind = item.effect
		part.palette = Color("df815a") if arena.map_id=="rain_market" else Color("7696b8")
		add(parent,part,item.name)
		var render_node = model(part,item.asset,"Model")
		var size = vec(item.size)
		var collider = box(part,Vector3.UP*size.y*.5,size)
		part.bounds = AABB(Vector3(-size.x*.5,0,-size.z*.5),size)
		part.saved_parts.assign([part.get_path_to(render_node),part.get_path_to(collider)])
		arena.structure_paths.append(arena.get_path_to(part))

func quad(parent: Node3D, label: String, at: Vector3, size: Array, angle: float, paint: Material) -> void:
	var mesh = QuadMesh.new()
	mesh.size = Vector2(size[0],size[1])
	var panel = MeshInstance3D.new()
	panel.mesh = mesh
	panel.material_override = paint
	panel.position = at
	panel.rotation.y = angle
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add(parent,panel,label)

func marks(parent: Node3D, label: String, points: Array) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for i in range(points.size()):
		var marker = Marker3D.new()
		marker.position = vec(points[i])
		if label=="Opening":
			marker.set_meta("fast",i>=6)
		add(parent,marker,label+str(i))
		paths.append(arena.get_path_to(marker))
	return paths

func build() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size()!=1 or args[0] not in ["rain_market","baggage_below","snowline"]:
		push_error("Pass rain_market, baggage_below, or snowline after --")
		quit(1)
		return
	var key = args[0]
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/%s_layout.json"%key))
	arena = Arena.new()
	arena.name = key.to_pascal_case()
	arena.map_id = key
	arena.fall_limit = -3.0
	var config: Dictionary = layout.environment
	arena.sun_color = Color(config.sun)
	arena.sun_energy = config.sun_energy
	arena.sun_rotation_degrees = vec(config.sun_rotation)
	arena.normal_sky = Color(config.sky)
	var environment = Environment.new()
	environment.resource_local_to_scene = true
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = arena.normal_sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(config.ambient)
	environment.ambient_light_energy = config.energy
	arena.environment_override = environment
	arena.spot_specs = layout.spots
	arena.awning_specs = layout.get("awnings",[])
	arena.comedy_site = Vector4(layout.comedy[0],layout.comedy[1],layout.comedy[2],layout.comedy[3])
	var fixed = add(arena,Node3D.new(),"Architecture")
	for asset in layout.fixed:
		model(fixed,asset,asset)
	for entry in layout.boxes:
		box(fixed,vec(entry[0]),vec(entry[1]),entry[2])
	for entry in layout.slabs:
		slab(fixed,entry[0],entry[1])
	for entry in layout.signs:
		var paint = StandardMaterial3D.new()
		paint.albedo_texture = load(SIGN_FOLDER+entry[1]+".svg")
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		quad(fixed,entry[0],vec(entry[2]),entry[3],entry[4],paint)
	var glass_paint = StandardMaterial3D.new()
	glass_paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_paint.albedo_color = Color(.39,.75,.94,.12)
	glass_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	for entry in layout.get("glass",[]):
		quad(fixed,"ApronGlass%d"%fixed.get_child_count(),vec(entry[0]),entry[1],entry[2],glass_paint)
	props(layout.props)
	var moving = add(arena,Node3D.new(),"Moving")
	for entry in layout.moving:
		var mesh_node = model(moving,entry[0],entry[0])
		mesh_node.position = vec(entry[1])
		mesh_node.rotation.y = entry[2]
	var belts = add(arena,Node3D.new(),"Belts")
	for entry in layout.belts:
		var size = vec(entry[1])
		var body = box(belts,vec(entry[0]),size)
		var surface = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = size
		surface.mesh = mesh
		var paint = ShaderMaterial.new()
		paint.shader = BELT_SHADER
		paint.resource_local_to_scene = true
		surface.material_override = paint
		add(body,surface,"Surface")
		arena.belt_directions.append(int(entry[2]))
	for at in layout.barrels:
		var barrel = Barrel.new()
		barrel.position = vec(at)
		add(arena,barrel,"Barrel%d"%arena.barrel_paths.size())
		arena.barrel_paths.append(arena.get_path_to(barrel))
	var route = add(arena,Node3D.new(),"Markers")
	arena.start_path = marks(route,"Start",[layout.start])[0]
	arena.get_node(arena.start_path).rotation.y = layout.heading
	arena.opening_paths = marks(route,"Opening",layout.opening)
	arena.reinforcement_paths = marks(route,"Reinforcement",layout.spawns)
	arena.respawn_paths = marks(route,"Respawn",layout.respawns)
	arena.route_paths = marks(route,"Tour",layout.route)

	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius = .50
	mesh.agent_height = 1.75
	mesh.agent_max_climb = .25
	mesh.cell_size = .25
	mesh.cell_height = .25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = key+"_navigation"
	mesh.filter_baking_aabb = AABB(Vector3(-24,-.52,-25),Vector3(48,8.38,51))
	nav.navigation_mesh = mesh
	add(arena,nav,"Navigation")
	arena.navigation_path = arena.get_path_to(nav)
	arena.add_to_group(mesh.geometry_source_group_name,true)
	root.add_child(arena)
	nav.bake_navigation_mesh(false)
	assert(mesh.get_polygon_count()>0)
	for _tick in range(60):
		await physics_frame
		var world_map = nav.get_navigation_map()
		if NavigationServer3D.map_get_iteration_id(world_map)>0 and NavigationServer3D.map_get_closest_point_owner(world_map,arena.player_start().origin)==nav.get_rid():
			break
	if not arena.validate_navigation():
		quit(1)
		return
	for node in arena.find_children("*","",true,false):
		if node.has_meta("structure"):
			node.remove_meta("structure")
	var scene = PackedScene.new()
	assert(scene.pack(arena)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/maps/%s.tscn"%key)==OK)
	print("ARENA_SCENE_READY ",key," ",mesh.get_polygon_count()," navigation polygons")
	quit()
