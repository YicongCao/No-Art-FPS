extends Node3D
class_name GameMap

var game: Node
@export var map_id = "yard"
@export var sun_rotation_degrees = Vector3(-52,-35,0)
@export var sun_color = Color("fff3d5")
@export var sun_energy = .22
@export var sun_shadow_bias = .1
@export var environment_override: Environment
@export var fall_limit = -8.0
@export var start_path: NodePath
@export var opening_paths: Array[NodePath] = []
@export var reinforcement_paths: Array[NodePath] = []
@export var respawn_paths: Array[NodePath] = []
@export var region_paths: Array[NodePath] = []
var opening_prepared_rooms: Array[Node3D] = []

func player_start() -> Transform3D:
	if not start_path.is_empty():return get_node(start_path).global_transform
	return Transform3D(Basis.IDENTITY,Vector3(0,.05,10.5))

func opening_actors() -> Array[Dictionary]:
	var actors: Array[Dictionary] = []
	for path in opening_paths:
		var marker = get_node(path)
		actors.append({"position":marker.global_position,"fast":marker.get_meta("fast",false),"marker":marker})
	return actors

func prepare_rooms() -> void:
	for room in opening_prepared_rooms:room.add_guard()

func respawn_candidates() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for path in respawn_paths:points.append(get_node(path).global_position)
	return points

func region_capacity(zone: String, total: int) -> int:
	var reserved = 0
	for path in region_paths:
		var region = get_node(path)
		var capacity = int(region.get_meta("capacity",0)) if region_intact(region) else 0
		if region.name==zone:return capacity
		reserved += capacity
	return total-reserved

func region_intact(region: Node) -> bool:
	var target_path = region.get_meta("structure_path",NodePath())
	return target_path.is_empty() or not get_node(target_path).collapsed

func uses_patrol(zone: String) -> bool:
	return zone!="yard"

func accepts_fast(zone: String) -> bool:
	return zone=="yard"

func prefers_reinforcement(_point: Vector3, _player: Node3D) -> bool:
	return true

func dispatch_reinforcements() -> void:
	pass

func reset_objectives() -> void:
	pass

func set_destroy_lighting(_active: bool) -> void:
	pass

func sweep_elapsed() -> float:
	var elapsed: float = game.rules.elapsed
	if not game.destroy_active:return elapsed
	# Keep the pose continuous while the sweep clock advances twice as fast.
	var phase_start: float = game.rules.duration-game.rules.destroy_duration
	return elapsed+maxf(0.0,elapsed-phase_start)

func prop_impact(_prop: Node3D, _point: Vector3, _normal: Vector3, _burning: bool) -> bool:
	return false

func cancel_interaction() -> void:
	if game and game.objective_focus:game.objective_focus.cancel()

func validate_map() -> bool:
	return true

func validate_navigation() -> bool:
	return true
