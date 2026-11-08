extends "res://scripts/arena.gd"

@export var route_paths: Array[NodePath] = []

const SweepingLight = preload("res://scripts/maps/sweeping_light.gd")
const SEARCHLIGHT_COLOR = Color("c3e3ff")
const NEON_STARBOARD = Color("36efff")
const NEON_PORT = Color("ff3cb0")
var searchlight: SpotLight3D
var port_searchlight: SpotLight3D

func _ready() -> void:
	super._ready()
	# Both lenses sit beneath the existing lamps on the yardarm.
	var mast: Node3D = get_node("MainMast")
	searchlight = SweepingLight.add_spot(mast,"DeckSearchlight",Vector3(2.95,7.8,0),
		SEARCHLIGHT_COLOR,5.0,33.0,18.0,true)
	SweepingLight.add_shaft(searchlight,24.0,.24,9.0,.21)
	port_searchlight = SweepingLight.add_spot(mast,"PortSearchlight",Vector3(-2.95,7.8,0),
		NEON_PORT,4.0,27.0,16.0,false)
	SweepingLight.add_shaft(port_searchlight,22.0,.24,8.0,.21)
	port_searchlight.hide()
	pose_searchlight(0)

func _process(_delta: float) -> void:
	if game and game.state=="RUNNING" and game.rules.active and not game.finale_active:
		pose_searchlight(sweep_elapsed())

func restore_structures() -> void:
	super.restore_structures()
	pose_searchlight(0)

func pose_searchlight(elapsed: float) -> void:
	var yaw = -.12+sin(elapsed*.64)*.76
	var pitch = -.55+.11*cos(elapsed*.80)
	searchlight.rotation = Vector3(pitch,yaw+PI,0)
	port_searchlight.rotation = Vector3(pitch,-yaw,0)

func set_destroy_lighting(active: bool) -> void:
	SweepingLight.set_tint(searchlight,NEON_STARBOARD if active else SEARCHLIGHT_COLOR)
	port_searchlight.visible = active

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
