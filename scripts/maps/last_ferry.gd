extends "res://scripts/arena.gd"

@export var route_paths: Array[NodePath] = []

func validate_map() -> bool:
	return opening_paths.size()==8 and reinforcement_paths.size()>=12 and respawn_paths.size()>=6

func validate_navigation() -> bool:
	var map = get_world_3d().navigation_map
	var start = player_start().origin
	for path in opening_paths+reinforcement_paths+respawn_paths+route_paths:
		var point: Vector3 = get_node(path).global_position
		var closest = NavigationServer3D.map_get_closest_point(map,point)
		var route = NavigationServer3D.map_get_path(map,start,closest,true)
		if closest.distance_to(point)>.85 or route.is_empty() or route[-1].distance_to(closest)>.65:
			push_error("Ferry route unavailable: %s at %s (closest %s)" % [path,point,closest])
			return false
	return true
