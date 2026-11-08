extends SceneTree

const Office = preload("res://scripts/maps/bb_office.gd")
const Destructible = preload("res://scripts/destructible.gd")
const OfficeDoor = preload("res://scripts/maps/office_door.gd")
const Barrel = preload("res://scripts/explosive_barrel.gd")
const LOGO = preload("res://assets/ui/maps/bb-office-logo.svg")
const MODEL_PATH = "res://assets/models/bb_office/"
const SHOT_ONLY_LAYER = 32
var office: Node3D
var assets: Dictionary = {}

func _initialize() -> void:
	build.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

func add(parent: Node, node: Node, label: String) -> Node:
	node.name = label
	parent.add_child(node)
	node.owner = office
	return node

func model(parent: Node3D, asset: String, label: String) -> void:
	if not assets.has(asset):
		assets[asset] = load(MODEL_PATH+asset+".glb")
	add(parent, assets[asset].instantiate(), label)

func box(parent: Node3D, center: Vector3, size: Vector3, layer: int = 1) -> void:
	var body = StaticBody3D.new()
	body.position = center
	body.collision_layer = layer
	body.collision_mask = 0
	add(parent, body, "Body%d"%parent.get_child_count())
	var shape = BoxShape3D.new()
	shape.size = size
	var collision = CollisionShape3D.new()
	collision.shape = shape
	add(body, collision, "Collision")

func glass_panes(parent: Node3D, entries: Array) -> void:
	var paint = StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.albedo_color = Color(.39,.68,.88,.12)
	for entry in entries:
		var pane = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(entry[1][0], entry[1][1])
		pane.mesh = quad
		pane.material_override = paint
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pane.position = vec(entry[0])
		pane.rotation.y = entry[2]
		add(parent, pane, "Glass%d"%parent.get_child_count())
		# Keep the collider separate so an intact pane blocks players and AI.
		var frame = add(parent, Node3D.new(), "Frame%d"%parent.get_child_count())
		frame.transform = pane.transform
		box(frame, Vector3.ZERO, Vector3(quad.size.x,quad.size.y,.10))

func add_logo(parent: Node3D) -> void:
	var sign_mesh = QuadMesh.new()
	sign_mesh.size = Vector2(5.95,1.32)
	var paint = StandardMaterial3D.new()
	paint.albedo_texture = LOGO
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var sign_node = MeshInstance3D.new()
	sign_node.mesh = sign_mesh
	sign_node.material_override = paint
	sign_node.position = Vector3(0,2.02,20.27)
	sign_node.rotation.y = PI
	sign_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add(parent, sign_node, "BBLogo")

func props(parent: Node3D, items: Array) -> void:
	for item in items:
		var part: Node3D = OfficeDoor.new() if item.impact == "wood" else Destructible.new()
		part.position = vec(item.at)
		part.rotation.y = item.angle
		part.scenery = item.impact != "wood"
		part.structural_section = not part.scenery
		part.paper = item.impact == "paper"
		part.local_bounds = true
		part.palette = Color("a66f54") if item.impact == "wood" else Color("477b82")
		part.set_meta("office_impact", item.impact)
		add(parent, part, item.name)
		model(part, item.asset, "Model")
		var size = vec(item.bounds)
		var section_bounds = AABB(Vector3(-size.x*.5,0,-size.z*.5),size)
		if size != Vector3.ZERO:
			box(part, Vector3.UP*size.y*.5, size)
		for section in item.sections:
			var at = vec(section[0])
			var extent = vec(section[1])
			box(part, at, extent, SHOT_ONLY_LAYER if item.impact == "leaf" else 1)
			var piece_bounds = AABB(at-extent*.5, extent)
			section_bounds = piece_bounds if size == Vector3.ZERO else section_bounds.merge(piece_bounds)
		part.bounds = section_bounds
		for child in part.get_children():
			part.saved_parts.append(part.get_path_to(child))
		office.structure_paths.append(office.get_path_to(part))

func markers(parent: Node3D, label: String, positions: Array) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for i in range(positions.size()):
		var marker = Marker3D.new()
		marker.position = vec(positions[i])
		add(parent, marker, label+str(i))
		if label == "Opening":
			marker.set_meta("fast",i>=6)
		paths.append(office.get_path_to(marker))
	return paths

func build() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/bb_office_layout.json"))
	office = Office.new()
	office.name = "BBOffice"
	office.map_id = "bb_office"
	office.sun_energy = .44
	office.sun_color = Color("ffe5c4")
	office.sun_rotation_degrees = Vector3(-38,-61,0)
	office.fall_limit = -3.0
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("789dc1")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e6eeff")
	env.ambient_light_energy = .82
	office.environment_override = env
	var architecture = add(office, Node3D.new(), "Architecture")
	for asset in layout.fixed:
		model(architecture, asset, asset.capitalize())
	for entry in layout.boxes:
		box(architecture, vec(entry[0]), vec(entry[1]))
	glass_panes(architecture, layout.glass)
	add_logo(architecture)
	props(add(office, Node3D.new(), "Props"), layout.props)
	var mounts = add(office, Node3D.new(), "LightMounts")
	for entry in layout.spots:
		var mount = Marker3D.new()
		mount.position = vec(entry[0])
		add(mounts, mount, "Mount%d"%mounts.get_child_count())
		office.sweep_centers.append(vec(entry[1]))
	for entry in layout.barrels:
		var barrel = Barrel.new()
		barrel.position = vec(entry)
		add(office, barrel, "Barrel%d"%office.barrel_paths.size())
		office.barrel_paths.append(office.get_path_to(barrel))
	var routes = add(office, Node3D.new(), "Markers")
	office.start_path = markers(routes, "PlayerStart", [layout.start])[0]
	office.get_node(office.start_path).rotation.y = .14
	office.opening_paths = markers(routes, "Opening", layout.opening)
	office.reinforcement_paths = markers(routes, "Reinforcement", layout.spawns)
	office.respawn_paths = markers(routes, "Respawn", layout.respawns)
	office.route_paths = markers(routes, "Tour", layout.route)

	var nav = NavigationRegion3D.new()
	var mesh = NavigationMesh.new()
	mesh.agent_radius = .50
	mesh.agent_height = 2.0
	mesh.agent_max_climb = .25
	mesh.cell_size = .25
	mesh.cell_height = .25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = 1
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	mesh.geometry_source_group_name = "bb_office_navigation"
	mesh.filter_baking_aabb = AABB(Vector3(-27.3,-.55,-21.3),Vector3(54.6,3.50,42.6))
	nav.navigation_mesh = mesh
	add(office, nav, "Navigation")
	office.navigation_path = office.get_path_to(nav)
	office.add_to_group("bb_office_navigation",true)
	root.add_child(office)
	nav.bake_navigation_mesh(false)
	assert(mesh.get_polygon_count()>0)
	for _tick in range(30):
		await physics_frame
		var navigation_map = office.get_world_3d().navigation_map
		if NavigationServer3D.map_get_iteration_id(navigation_map)>0 and NavigationServer3D.map_get_closest_point_owner(navigation_map, office.player_start().origin) == nav.get_rid():
			break
	if not office.validate_navigation():
		quit(1)
		return
	for node in office.find_children("*", "", true, false):
		if node.has_meta("structure"):
			node.remove_meta("structure")
	var scene = PackedScene.new()
	assert(scene.pack(office)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/maps/bb_office.tscn")==OK)
	print("BB_OFFICE_SCENE_READY ",mesh.get_polygon_count()," navigation polygons")
	quit()
