extends Node3D

var game: Node
var arena: Node3D
var bounds: AABB
var palette = Color("b65745")
var parts: Array[Node] = []
var collision_states: Dictionary = {}
var hits = 0
var burn_time = -1.0
var collapsed = false
var flame_time = 0.0

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

func ignite_hit(point: Vector3) -> void:
	if collapsed or game.state!="RUNNING" or not game.destroy_active:return
	hits += 1
	game.fire_effect(point,.45)
	if hits>=3 and burn_time<0:
		burn_time = .55
		game.play_world_sound("fuse",bounds.get_center(),-12)

func _physics_process(delta: float) -> void:
	if game.state!="RUNNING" or not game.rules.active or collapsed or burn_time<0:return
	burn_time -= delta
	flame_time -= delta
	if flame_time<=0:
		flame_time = .16
		game.fire_effect(bounds.get_center()+Vector3(0,-bounds.size.y*.3,0),1.2)
	if burn_time<=0:collapse()

func collapse() -> void:
	if collapsed or game.state!="RUNNING" or not game.rules.active:return
	collapsed = true
	# Remove both visible geometry and collision; respawns/restarts retain sources.
	for part in parts:
		if part is Node3D:part.hide()
	for body in collision_states:body.collision_layer = 0
	for enemy in game.live_enemies():
		if bounds.grow(.35).has_point(enemy.global_position+Vector3.UP):enemy.take_damage(3)
	game.collapse_effect(bounds,palette)
	arena.request_navigation_update()
