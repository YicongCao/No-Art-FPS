extends "res://scripts/maps/map_root.gd"

const RESPAWN_SIGHT_RANGE = 12.0
const RESPAWN_CLEAR_LANE = 3.0

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
@export var batch_transforms: Dictionary = {}
@export var decoration_paths: Array[NodePath] = []
@export var static_collision_paths: Array[NodePath] = []
var structures: Array[Node3D] = []
var interactive_props: Node3D
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
var navigation_delay = 0.0
var navigation_baking = false
var restore_navigation_pending = false
var restore_navigation_iteration = -1
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
		var source: MultiMesh = node.multimesh
		var batch = MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = source.mesh
		batch.instance_count = source.instance_count
		var transforms: Array[Transform3D] = []
		for i in range(source.instance_count):
			var transform: Transform3D = batch_transforms[path][i] if batch_transforms.has(path) else source.get_instance_transform(i)
			transforms.append(transform)
			batch.set_instance_transform(i,transform)
		node.multimesh = batch
		initial_batches[node] = transforms

	interactive_props = preload("res://scripts/maps/interactive_props.gd").new()
	add_child(interactive_props)
	interactive_props.setup(self)

func bake_navigation() -> void:
	nav = get_node(navigation_path)
	original_navigation_mesh = nav.navigation_mesh.duplicate()
	nav.navigation_mesh = nav.navigation_mesh.duplicate()

func respawn_pose(player: CharacterBody3D, enemies: Array) -> Transform3D:
	var start = player_start()
	var candidates = respawn_candidates()
	if not enemies.is_empty():
		var separation = {}
		for point in candidates:
			var nearest = INF
			for enemy in enemies:nearest = minf(nearest,point.distance_squared_to(enemy.global_position))
			separation[point] = nearest
		candidates.sort_custom(func(a,b):return separation[a]>separation[b])
	if not candidates.has(start.origin):candidates.append(start.origin)
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.new()
	ray.collision_mask = player.collision_mask
	var body = PhysicsShapeQueryParameters3D.new()
	body.shape = player.body_shape.shape
	body.collision_mask = player.collision_mask
	for marker in candidates:
		ray.from = marker+Vector3.UP*.35
		ray.to = marker-Vector3.UP*.65
		var floor_hit = space.intersect_ray(ray)
		if floor_hit.is_empty() or floor_hit.normal.y<.65:continue
		var point: Vector3 = floor_hit.position+Vector3.UP*.05
		body.transform = Transform3D(Basis.IDENTITY,point+player.body_shape.position)
		if not space.intersect_shape(body,1).is_empty():continue
		var forward = respawn_direction(space,ray,point,player.camera.position.y,-start.basis.z)
		if forward!=Vector3.ZERO:return Transform3D(Basis.looking_at(forward),point)
	return start

func respawn_direction(space: PhysicsDirectSpaceState3D, ray: PhysicsRayQueryParameters3D,
		point: Vector3, eye_height: float, preferred: Vector3) -> Vector3:
	var level_forward = Vector3(preferred.x,0,preferred.z).normalized()
	var eye = point+Vector3.UP*eye_height
	var best = Vector3.ZERO
	var best_score = 0.0
	for i in range(16):
		var forward = level_forward.rotated(Vector3.UP,i*TAU/16)
		var sight = sight_distance(space,ray,eye,forward)
		if sight<RESPAWN_CLEAR_LANE:continue
		var feet = point+Vector3.UP*.4
		ray.from = feet
		ray.to = feet+forward*RESPAWN_CLEAR_LANE
		if not space.intersect_ray(ray).is_empty():continue
		# Check the floor ahead so an open sky or waterline cannot win over a lane.
		var ahead = point+forward*RESPAWN_CLEAR_LANE
		ray.from = ahead+Vector3.UP*.6
		ray.to = ahead-Vector3.UP*.75
		var floor_hit = space.intersect_ray(ray)
		if floor_hit.is_empty() or floor_hit.normal.y<.65:continue
		var score = sight
		for side in [-1,1]:
			score += sight_distance(space,ray,eye,forward.rotated(Vector3.UP,side*.32))*.5
		if score>best_score:
			best_score = score
			best = forward
	return best

func sight_distance(space: PhysicsDirectSpaceState3D, ray: PhysicsRayQueryParameters3D,
		origin: Vector3, forward: Vector3) -> float:
	ray.from = origin
	ray.to = origin+forward*RESPAWN_SIGHT_RANGE
	var hit = space.intersect_ray(ray)
	return RESPAWN_SIGHT_RANGE if hit.is_empty() else origin.distance_to(hit.position)

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
	if interactive_props:interactive_props.restore()
	var changed = false
	for node in structures:
		changed = changed or (node.collapsed and not node.scenery)
		node.restore()
	if changed:
		restore_navigation_pending = true
		navigation_dirty = true
		navigation_delay = 0.0

func request_navigation_update() -> void:
	if game.finale_active:return
	if not navigation_dirty:navigation_delay = .18
	navigation_dirty = true

func _physics_process(delta: float) -> void:
	if restore_navigation_iteration>=0:
		if NavigationServer3D.map_get_iteration_id(nav.get_navigation_map())==restore_navigation_iteration:return
		restore_navigation_iteration = -1
		navigation_baking = false
	if not navigation_dirty or navigation_baking or not nav:return
	if restore_navigation_pending:
		navigation_dirty = false
		restore_navigation_pending = false
		restore_navigation_iteration = NavigationServer3D.map_get_iteration_id(nav.get_navigation_map())
		navigation_baking = true
		nav.navigation_mesh = original_navigation_mesh.duplicate()
		return
	if game.finale_active:
		navigation_dirty = false
		return
	navigation_delay = maxf(0,navigation_delay-delta)
	if navigation_delay>0:return
	navigation_dirty = false
	navigation_baking = true
	bake_changed_geometry.call_deferred()

func bake_changed_geometry() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not nav.bake_finished.is_connected(navigation_finished):nav.bake_finished.connect(navigation_finished)
	var web = OS.has_feature("web")
	if web:nav.navigation_mesh.sample_partition_type = NavigationMesh.SAMPLE_PARTITION_MONOTONE
	nav.bake_navigation_mesh(not web)

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
	for prop in structures:
		if not prop.scenery or prop.collapsed:continue
		var at: Vector3 = prop.world_bounds().get_center()
		centers[Vector2i(floori(at.x/5),floori(at.z/5))] = at
		prop.collapse(false)
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
			if transform.origin.y<=.12 or node.multimesh.get_instance_transform(i).basis==Basis.from_scale(Vector3.ZERO):continue
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
