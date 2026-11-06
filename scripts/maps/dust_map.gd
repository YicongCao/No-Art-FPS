extends "res://scripts/arena.gd"
@export var objective_paths: Array[NodePath] = []
var objectives: Array[Node3D] = []

func _ready() -> void:
	super._ready()
	for path in objective_paths:
		var objective = get_node(path)
		objective.game = game
		objectives.append(objective)

func opening_actors() -> Array[Dictionary]:
	var actors = super.opening_actors()
	for actor in actors:
		var route: Array[Vector3] = []
		for point in actor.marker.get_children():route.append(point.global_position)
		actor["patrol"] = route
	return actors

func uses_patrol(_zone: String) -> bool:
	return false

func accepts_fast(_zone: String) -> bool:
	return false

func reset_objectives() -> void:
	for objective in objectives:objective.reset()

func validate_map() -> bool:
	var ids: Dictionary = {}
	for objective in objectives:
		if objective.objective_id.is_empty() or ids.has(objective.objective_id):return false
		ids[objective.objective_id] = true
		if not objective.objective_id in game.rules.objective_ids:return false
	for actor in opening_actors():
		if actor.patrol.size()<2:return false
	return ids.size()==3 and ids.size()==game.rules.objective_ids.size()

func validate_navigation() -> bool:
	var navigation_map = get_world_3d().navigation_map
	for objective in objectives:
		var target = objective.global_position-Vector3.UP*.4
		var path = NavigationServer3D.map_get_path(navigation_map,player_start().origin,target,true)
		if path.size()<2 or path[-1].distance_to(target)>1:return false
	for actor in opening_actors():
		for i in range(actor.patrol.size()-1):
			var path = NavigationServer3D.map_get_path(navigation_map,actor.patrol[i],actor.patrol[i+1],true)
			if path.size()<2 or path[-1].distance_to(actor.patrol[i+1])>1:return false
	return true
