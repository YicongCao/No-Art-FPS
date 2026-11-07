extends "res://scripts/arena.gd"

@export var carousel_path: NodePath
@export var horse_paths: Array[NodePath] = []
@export var car_paths: Array[NodePath] = []
@export var tour_paths: Array[NodePath] = []
var carousel: Node3D
var horses: Array[Node3D] = []
var cars: Array[PathFollow3D] = []

func _ready() -> void:
	super._ready()
	carousel = get_node(carousel_path)
	for path in horse_paths:horses.append(get_node(path))
	for path in car_paths:cars.append(get_node(path))
	pose_rides(0)

func _process(_delta: float) -> void:
	if game and game.state=="RUNNING" and game.rules.active and not game.finale_active:
		pose_rides(game.rules.elapsed)

func restore_structures() -> void:
	super.restore_structures()
	pose_rides(0)

func pose_rides(elapsed: float) -> void:
	carousel.rotation.y = -elapsed*TAU/13.33
	for i in range(horses.size()):
		horses[i].position.y = sin(elapsed*TAU/1.8+i*TAU/horses.size())*.17
	var length = cars[0].get_parent().curve.get_baked_length()
	for i in range(cars.size()):
		cars[i].progress = fposmod(4.0+elapsed*7.5-i*1.78,length)

func validate_map() -> bool:
	return opening_paths.size()==8 and reinforcement_paths.size()>=12 and respawn_paths.size()>=6 and cars.size()==3

func validate_navigation() -> bool:
	var map = get_world_3d().navigation_map
	var start = player_start().origin
	for path in opening_paths+reinforcement_paths+respawn_paths+tour_paths:
		var target: Vector3 = get_node(path).global_position
		var closest = NavigationServer3D.map_get_closest_point(map,target)
		var route = NavigationServer3D.map_get_path(map,start,closest,true)
		if closest.distance_to(target)>.85 or route.is_empty() or route[-1].distance_to(closest)>.65:
			push_error("Park route unavailable: %s at %s (closest %s)"%[path,target,closest])
			return false
	return true
