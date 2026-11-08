extends Node3D

var game: Node
var arena: Node3D
@export var bounds: AABB
@export var saved_parts: Array[NodePath] = []
@export var local_bounds = false
@export var palette = Color("b65745")
@export var scenery = false
@export var structural_section = false
@export var paper = false
@export var keep_boundary = false
@export var batch_parts: Dictionary = {}
@export var supported_paths: Array[NodePath] = []
var parts: Array[Node] = []
var collision_states: Dictionary = {}
var hits = 0
var burn_time = -1.0
var collapsed = false
var flame_time = 0.0
var hit_point = Vector3.ZERO

func register(node: Node) -> void:
	parts.append(node)
	if node is CollisionObject3D:
		collision_states[node] = node.collision_layer
		node.set_meta("structure",self)
	for child in node.find_children("*","CollisionObject3D",true,false):
		collision_states[child] = child.collision_layer
		child.set_meta("structure",self)

func restore() -> void:
	hits = 0
	burn_time = -1
	collapsed = false
	flame_time = 0
	for part in parts:
		if part is Node3D:part.show()
	for body in collision_states:body.collision_layer = collision_states[body]
	for path in batch_parts:
		var batch = arena.get_node(path)
		for index in batch_parts[path]:
			batch.multimesh.set_instance_transform(index,arena.initial_batches[batch][index])

func ignite_hit(point: Vector3) -> void:
	if game==null or collapsed or game.state!="RUNNING" or not game.destroy_active:return
	hits += 1
	hit_point = point
	if hits>=2 and burn_time<0:
		burn_time = .22 if scenery else .55
		game.play_world_sound("fuse",world_bounds().get_center(),-12)

func _physics_process(delta: float) -> void:
	if game==null or game.state!="RUNNING" or not game.rules.active or collapsed or burn_time<0:return
	burn_time -= delta
	flame_time -= delta
	if flame_time<=0:
		flame_time = .16
		var source = hit_point if structural_section else world_bounds().get_center()+Vector3(0,-bounds.size.y*.3,0)
		game.fire_effect(source,1.2)
	if burn_time<=0:collapse()

func collapse(show_effects: bool = true) -> void:
	if game==null or collapsed or game.state!="RUNNING" or not (game.rules.active or game.finale_active):return
	collapsed = true
	if hits>=2:game.on_structure_destroyed(self)
	# Remove both visible geometry and collision; respawns/restarts retain sources.
	for part in parts:
		if part is Node3D:part.hide()
	if not keep_boundary:
		for body in collision_states:body.collision_layer = 0
	for path in batch_parts:
		var batch = arena.get_node(path)
		for index in batch_parts[path]:
			var at: Vector3 = arena.initial_batches[batch][index].origin
			batch.multimesh.set_instance_transform(index,Transform3D(Basis.from_scale(Vector3.ZERO),at))
	for path in supported_paths:get_node(path).collapse(false)
	var area = world_bounds()
	if not scenery and game.rules.active:
		for enemy in game.live_enemies():
			if (bounds.grow(.35).has_point(to_local(enemy.global_position+Vector3.UP)) if local_bounds else bounds.grow(.35).has_point(enemy.global_position+Vector3.UP)):enemy.take_damage(enemy.MAX_HEALTH)
	if show_effects:
		var blast_center = hit_point
		if paper and hits>=2:game.paper_impact(hit_point,Vector3.UP,area.position.y,true)
		if scenery:
			blast_center = area.get_center()
			blast_center.y = area.position.y+minf(area.size.y*.5,.85)
			game.finale_explosion(blast_center,clampf(area.size.length()*.2,.65,1.5),palette)
			game.play_world_sound("explosion",blast_center,-11)
		elif structural_section and game.finale_active:
			game.finale_explosion(area.get_center(),clampf(area.size.length()*.17,1.4,2.8),palette)
		else:game.collapse_effect(area,palette)
		if hits>=2 and not keep_boundary:
			var excluded: Array[RID] = []
			for body in collision_states:excluded.append(body.get_rid())
			game.scenery_blast(blast_center,excluded)
	# Removing small cover leaves the existing paths walkable. Only structural
	# changes need a bake, especially on the single-threaded Web build.
	if not scenery:arena.request_navigation_update()

func bind(context: Node, map: Node3D) -> void:
	game = context
	arena = map
	parts.clear()
	collision_states.clear()
	for path in saved_parts:register(get_node(path))

func world_bounds() -> AABB:
	return global_transform*bounds if local_bounds else bounds
