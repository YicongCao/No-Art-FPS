extends "res://scripts/arena.gd"

@export var route_paths: Array[NodePath] = []

func prefers_reinforcement(point: Vector3, player: Node3D) -> bool:
	var offset = point-player.global_position
	offset.y = 0
	var forward = -player.global_basis.z
	forward.y = 0
	return forward.normalized().dot(offset.normalized())>=-.42

func validate_map() -> bool:
	return opening_paths.size()==8 and reinforcement_paths.size()>=12 and respawn_paths.size()>=6

func validate_navigation() -> bool:
	var navigation_map = get_world_3d().navigation_map
	var start = player_start().origin
	var valid = true
	for path in opening_paths+reinforcement_paths+respawn_paths+route_paths:
		var point: Vector3 = get_node(path).global_position
		var closest = NavigationServer3D.map_get_closest_point(navigation_map,point)
		var route = NavigationServer3D.map_get_path(navigation_map,start,closest,true)
		if closest.distance_to(point)>.75 or route.is_empty() or route[-1].distance_to(closest)>.5:
			push_error("Sandgate route unavailable: %s at %s, nearest %s, end %s"%[
				path,point,closest,route[-1] if not route.is_empty() else "none"])
			valid = false
	return valid
