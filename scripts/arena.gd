extends "res://scripts/maps/map_root.gd"

@export var navigation_path: NodePath
@export var structure_paths: Array[NodePath] = []
@export var barrel_paths: Array[NodePath] = []
@export var container_paths: Array[NodePath] = []
@export var opening_room_paths: Array[NodePath] = []
@export var traffic_paths: Array[NodePath] = []
@export var palm_paths: Array[NodePath] = []
@export var lounger_paths: Array[NodePath] = []
@export var pool_path: NodePath
@export var warehouse_path: NodePath
@export var deck_path: NodePath
@export var palette_materials: Dictionary = {}
@export var batch_paths: Array[NodePath] = []
@export var decoration_paths: Array[NodePath] = []
@export var static_collision_paths: Array[NodePath] = []
var structures: Array[Node3D] = []
var barrels: Array[Node3D] = []
var containers: Array[Node3D] = []
var traffic_lights: Array[Node3D] = []
var palms: Array[Node3D] = []
var loungers: Array[Node3D] = []
var pool: Node3D
var warehouse_structure: Node3D
var deck_structure: Node3D
var spawn_points: Array[Vector3] = []
var nav: NavigationRegion3D
var materials: Dictionary = {}
var navigation_dirty = false
var navigation_baking = false
var restore_navigation_pending = false
var original_navigation_mesh: NavigationMesh
var traffic_phase = -1
var finale_props: Array[Node3D] = []
var finale_hidden: Array[Node3D] = []
var finale_collisions: Dictionary = {}
var finale_batches: Dictionary = {}
var initial_batches: Dictionary = {}

func _ready() -> void:
	materials = palette_materials
	for path in structure_paths:
		var node = get_node(path)
		node.bind(game,self)
		structures.append(node)
	for path in barrel_paths:
		var node = get_node(path)
		node.game = game
		barrels.append(node)
	for path in container_paths:
		var node = get_node(path)
		node.game = game
		containers.append(node)
	for path in opening_room_paths:opening_prepared_rooms.append(get_node(path))
	for path in traffic_paths:traffic_lights.append(get_node(path))
	for path in palm_paths:palms.append(get_node(path))
	for path in lounger_paths:loungers.append(get_node(path))
	if not pool_path.is_empty():pool = get_node(pool_path)
	if not warehouse_path.is_empty():warehouse_structure = get_node(warehouse_path)
	if not deck_path.is_empty():deck_structure = get_node(deck_path)
	for path in reinforcement_paths:spawn_points.append(get_node(path).global_position)
	for path in decoration_paths:finale_props.append(get_node(path))
	for path in batch_paths:
		var node = get_node(path)
		node.multimesh = node.multimesh.duplicate()
		var transforms: Array[Transform3D] = []
		for i in range(node.multimesh.instance_count):transforms.append(node.multimesh.get_instance_transform(i))
		initial_batches[node] = transforms

func bake_navigation() -> void:
	nav = get_node(navigation_path)
	original_navigation_mesh = nav.navigation_mesh.duplicate()
	nav.navigation_mesh = nav.navigation_mesh.duplicate()

func enemy_zone(point: Vector3) -> String:
	for path in region_paths:
		var region = get_node(path)
		if region.get_meta("bounds").has_point(region.to_local(point)):return str(region.name)
	return "yard"

func patrol_points(zone: String) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for path in region_paths:
		var region = get_node(path)
		if region.name==zone:
			for marker in region.get_children():points.append(marker.global_position)
	return points

func zone_intact(zone: String) -> bool:
	for path in region_paths:
		var region = get_node(path)
		if region.name==zone:return region_intact(region)
	return true

func restore_structures() -> void:
	var changed = false
	for node in structures:
		changed = changed or node.collapsed
		node.restore()
	if changed:
		restore_navigation_pending = true
		request_navigation_update()

func request_navigation_update() -> void:
	if game.finale_active:return
	navigation_dirty = true

func _physics_process(_delta: float) -> void:
	if not navigation_dirty or navigation_baking or not nav:return
	navigation_dirty = false
	if restore_navigation_pending:
		restore_navigation_pending = false
		nav.navigation_mesh = original_navigation_mesh.duplicate()
		return
	navigation_baking = true
	bake_changed_geometry.call_deferred()

func bake_changed_geometry() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not nav.bake_finished.is_connected(navigation_finished):nav.bake_finished.connect(navigation_finished)
	nav.bake_navigation_mesh(not OS.has_feature("web"))

func navigation_finished() -> void:
	navigation_baking = false

func _process(_delta: float) -> void:
	var phase = int(Time.get_ticks_msec()/1000)%12
	var key = 0 if phase<5 else (1 if phase<6 else (2 if phase<11 else 1))
	if key==traffic_phase:return
	traffic_phase = key
	for index in range(traffic_lights.size()):
		for color in ["red","yellow","green"]:
			var lamp = traffic_lights[index].find_child("lamp_"+color,true,false)
			if lamp==null:continue
			var active = (color=="yellow" and key==1) or (color=="green" and key==(0 if index%2==0 else 2)) or (color=="red" and key==(2 if index%2==0 else 0))
			var material = StandardMaterial3D.new()
			material.albedo_color = materials[color].get_shader_parameter("base_color") if active and materials[color] is ShaderMaterial else (materials[color].albedo_color if active else Color("253039"))
			if active:material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			lamp.material_override = material

func explode_finale_decor() -> void:
	var centers: Dictionary = {}
	for prop in finale_props:
		if not prop.visible:continue
		finale_hidden.append(prop)
		prop.hide()
		centers[Vector2i(floori(prop.global_position.x/5),floori(prop.global_position.z/5))] = prop.global_position+Vector3.UP
	for path in static_collision_paths:
		var node = get_node(path)
		finale_collisions[node] = node.collision_layer
		node.collision_layer = 0
	for node in initial_batches:
		var transforms: Dictionary = {}
		for i in range(node.multimesh.instance_count):
			var transform: Transform3D = initial_batches[node][i]
			if transform.origin.y<=.12:continue
			transforms[i] = transform
			var at = node.to_global(transform.origin)
			centers[Vector2i(floori(at.x/5),floori(at.z/5))] = at
			node.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3.ZERO),transform.origin))
		if not transforms.is_empty():finale_batches[node] = transforms
	for point in centers.values():game.finale_explosion(point,1.1,Color("e9ba50"))

func restore_finale_decor() -> void:
	for prop in finale_hidden:prop.show()
	finale_hidden.clear()
	for node in finale_collisions:node.collision_layer = finale_collisions[node]
	finale_collisions.clear()
	for node in finale_batches:
		for i in finale_batches[node]:node.multimesh.set_instance_transform(i,finale_batches[node][i])
	finale_batches.clear()
