extends "res://scripts/arena.gd"

const SweepingLight = preload("res://scripts/maps/sweeping_light.gd")
const MIRROR_TILES = preload("res://assets/shaders/mirror_ball.gdshader")

@export var carousel_path: NodePath
@export var horse_paths: Array[NodePath] = []
@export var car_paths: Array[NodePath] = []
@export var tour_paths: Array[NodePath] = []
var carousel: Node3D
var horses: Array[Node3D] = []
var cars: Array[PathFollow3D] = []
var disco_ball: Node3D

func _ready() -> void:
	super._ready()
	carousel = get_node(carousel_path)
	for path in horse_paths:horses.append(get_node(path))
	for path in car_paths:cars.append(get_node(path))
	add_disco_ball()
	pose_rides(0)

func _process(_delta: float) -> void:
	if game and game.state=="RUNNING" and game.rules.active and not game.finale_active:
		pose_rides(game.rules.elapsed)

func restore_structures() -> void:
	super.restore_structures()
	pose_rides(0)

func add_disco_ball() -> void:
	disco_ball = Node3D.new()
	disco_ball.name = "DiscoBall"
	disco_ball.position.y = 3.28
	carousel.add_child(disco_ball)
	var mesh = SphereMesh.new()
	mesh.radius = .58
	mesh.height = 1.16
	mesh.radial_segments = 24
	mesh.rings = 12
	var paint = ShaderMaterial.new()
	paint.shader = MIRROR_TILES
	var globe = MeshInstance3D.new()
	globe.mesh = mesh
	globe.material_override = paint
	disco_ball.add_child(globe)
	for i in range(2):
		var sign_x = 1.0 if i==0 else -1.0
		var tint = Color("ff8bc8") if i==0 else Color("9ee9ff")
		var spot = SweepingLight.add_spot(disco_ball,"Reflection%d"%i,
			Vector3(sign_x*.54,-.16,0),tint,4.0,6.6,14.0,false)
		spot.look_at(disco_ball.to_global(Vector3(sign_x*4.0,-2.8,.7)))
		SweepingLight.add_shaft(spot,4.8,.055,10.0,.27)

func pose_rides(elapsed: float) -> void:
	carousel.rotation.y = -elapsed*TAU/13.33
	disco_ball.rotation.y = .45+elapsed*TAU/5.2
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
