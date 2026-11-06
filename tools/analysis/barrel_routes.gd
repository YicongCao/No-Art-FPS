extends Node
var game: Node
var paths: Array = []
var state: PhysicsDirectSpaceState3D

func _ready() -> void:
	game.set_physics_process(false)
	state = game.get_world_3d().direct_space_state
	var destinations = [game.arena.player_start().origin,Vector3(-10,0,1),Vector3(10,0,8),Vector3(18,0,12),Vector3(18,0,-8),Vector3(30,0,3),Vector3(30,0,-10),Vector3(-4,3.1,-11),Vector3(6,3.1,-20)]
	var sources: Array = game.arena.spawn_points.duplicate()
	for actor in game.opening:sources.append(actor.position)
	for source in sources:
		var zone = game.arena.enemy_zone(source)
		for target in destinations:
			if zone!="yard" and game.arena.enemy_zone(target)!=zone:continue
			# Approximate lateral approaches with two nearby offsets around each player anchor.
			for offset in [Vector3.ZERO,Vector3(5,0,0),Vector3(-5,0,0)]:
				var goal = target+offset if zone=="yard" else target
				var path = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),source,goal,true)
				if path.size()<2 or path[-1].distance_to(goal)>1:continue
				paths.append(path)
	var report = {"routes":paths.size(),"max_displacement":2.5,"radius":7.5,"barrels":[],"paths":[]}
	for path in paths:
		var points = []
		for p in path:points.append([p.x,p.y,p.z])
		report.paths.append(points)
	for barrel in game.arena.barrels:
		var origin: Vector3 = barrel.global_position
		var best = origin
		var original_score = score(origin)
		var best_score = original_score
		for radius in [.75,1.5,2.5]:
			for i in range(24):
				var candidate = origin+Vector3(cos(i*TAU/24),0,sin(i*TAU/24))*radius
				if not safe(candidate,barrel):continue
				var value = score(candidate)-radius*.04
				if value>best_score+.01:
					best_score = value
					best = candidate
		# Sequential placement checks keep neighbouring barrels from overlapping.
		barrel.global_position = best
		report.barrels.append({"path":str(game.arena.get_path_to(barrel)),"from":[origin.x,origin.y,origin.z],"to":[best.x,best.y,best.z],"before":original_score,"after":score(best)})
	FileAccess.open("res://artifacts/barrel-route-analysis.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("BARREL_ROUTES_ANALYZED ",paths.size()," routes, ",report.barrels.size()," barrels")
	get_tree().quit()

func score(point: Vector3) -> float:
	var result = 0.0
	for path in paths:
		var distance = 1000.0
		var nearest = Vector3.ZERO
		for i in range(path.size()-1):
			var p = Geometry3D.get_closest_point_to_segment(point,path[i],path[i+1])
			if p.distance_to(point)<distance:
				distance = p.distance_to(point)
				nearest = p
		if distance>7.5 or absf(nearest.y-point.y)>1:continue
		var ray = PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.4,nearest+Vector3.UP,1)
		if not state.intersect_ray(ray).is_empty():continue
		result += exp(-distance*distance/18.0)
	return result/paths.size()*100

func safe(point: Vector3, barrel: Node3D) -> bool:
	for other in game.arena.barrels:
		if other!=barrel and other.global_position.distance_to(point)<1.2:return false
	for p in game.arena.spawn_points:
		if p.distance_to(point)<1.5:return false
	for actor in game.opening:
		if actor.position.distance_to(point)<1.5:return false
	var floor_ray = PhysicsRayQueryParameters3D.create(point+Vector3.UP*.4,point-Vector3.UP*.4,1,[barrel.get_rid()])
	var floor_hit = state.intersect_ray(floor_ray)
	if floor_hit.is_empty() or absf(floor_hit.position.y-point.y)>.1:return false
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = .65
	shape.height = 1.2
	query.shape = shape
	query.transform.origin = point+Vector3.UP*.72
	query.collision_mask = 1
	query.exclude = [barrel.get_rid()]
	if not state.intersect_shape(query).is_empty():return false
	var nearest = NavigationServer3D.map_get_closest_point(game.arena.nav.get_navigation_map(),point)
	return Vector2(nearest.x-point.x,nearest.z-point.z).length()<.65
