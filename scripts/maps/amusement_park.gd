extends "res://scripts/arena.gd"

const SweepingLight = preload("res://scripts/maps/sweeping_light.gd")
const MIRROR_TILES = preload("res://assets/shaders/mirror_ball.gdshader")
const PIXEL_MIRROR = preload("res://assets/textures/park_experiment/brushed_steel.png")
const TexturePreview = preload("res://scripts/maps/park_texture_preview.gd")
const CAROUSEL_TURN_RATE = -TAU/13.33
const DISCO_TURN_RATE = TAU/5.2+CAROUSEL_TURN_RATE
const DISCO_COLORS = [Color("ff8bc8"),Color("9ee9ff")]
const NEON_COLORS = [Color("ff39b8"),Color("6bff70")]
const DISCO_REST_RANGE = 6.6
const DISCO_FRENZY_RANGE = 32.0
const NIGHTFALL_DURATION = 1.8

@export var carousel_path: NodePath
@export var horse_paths: Array[NodePath] = []
@export var car_paths: Array[NodePath] = []
@export var tour_paths: Array[NodePath] = []
var carousel: Node3D
var horses: Array[Node3D] = []
var cars: Array[PathFollow3D] = []
var disco_ball: Node3D
var disco_paint: ShaderMaterial
var disco_spots: Array[SpotLight3D] = []
var disco_rest_pitch := 0.0
var nightfall := 0.0
var texture_preview: TexturePreview

func _ready() -> void:
	super._ready()
	carousel = get_node(carousel_path)
	for path in horse_paths:horses.append(get_node(path))
	for path in car_paths:cars.append(get_node(path))
	add_disco_ball()
	pose_rides(0,0)
	if game and game.park_experimental_textures:set_experimental_textures(true)

func set_experimental_textures(enabled: bool) -> void:
	if enabled and not texture_preview:texture_preview = TexturePreview.new()
	if texture_preview:texture_preview.set_enabled(self,enabled)
	if enabled:disco_paint.set_shader_parameter("pixel_tile",PIXEL_MIRROR)
	disco_paint.set_shader_parameter("pixel_finish",enabled)

func _process(_delta: float) -> void:
	if game and game.state=="RUNNING" and game.rules.active and not game.finale_active:
		pose_rides(game.rules.elapsed,sweep_elapsed())

func restore_structures() -> void:
	super.restore_structures()
	pose_rides(0,0)

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
	disco_paint = ShaderMaterial.new()
	disco_paint.shader = MIRROR_TILES
	var globe = MeshInstance3D.new()
	globe.mesh = mesh
	globe.material_override = disco_paint
	disco_ball.add_child(globe)
	for i in range(2):
		var sign_x = 1.0 if i==0 else -1.0
		var spot = SweepingLight.add_spot(disco_ball,"Reflection%d"%i,
			Vector3(sign_x*.54,-.16,0),DISCO_COLORS[i],4.0,DISCO_REST_RANGE,14.0,false)
		spot.look_at(disco_ball.to_global(Vector3(sign_x*4.0,-2.8,.7)))
		disco_rest_pitch = spot.rotation.x
		SweepingLight.add_shaft(spot,4.8,.055,10.0,.27)
		disco_spots.append(spot)

func set_destroy_lighting(active: bool) -> void:
	if not active:set_nightfall(0.0)
	var colors = NEON_COLORS if active else DISCO_COLORS
	for i in range(disco_spots.size()):
		var spot := disco_spots[i]
		SweepingLight.set_tint(spot,colors[i])
		spot.spot_range = DISCO_FRENZY_RANGE if active else DISCO_REST_RANGE
		spot.spot_angle = 9.0 if active else 14.0
		spot.light_energy = 7.0 if active else 4.0
		SweepingLight.resize_shaft(spot,DISCO_FRENZY_RANGE if active else 4.8,
			6.8 if active else 10.0,.22 if active else .27)
		if not active:spot.rotation.x = disco_rest_pitch

func set_nightfall(progress: float) -> void:
	if nightfall==progress:return
	nightfall = progress
	var sky_material := environment_override.sky.sky_material as ShaderMaterial
	sky_material.set_shader_parameter("nightfall",nightfall)

func pose_rides(elapsed: float, light_elapsed: float) -> void:
	carousel.rotation.y = elapsed*CAROUSEL_TURN_RATE
	disco_ball.rotation.y = .45+light_elapsed*DISCO_TURN_RATE-carousel.rotation.y
	if game and game.destroy_active:
		var phase_start: float = game.rules.duration-game.rules.destroy_duration
		set_nightfall(smoothstep(0.0,NIGHTFALL_DURATION,elapsed-phase_start))
		var raise_beam := smoothstep(0.0,1.15,elapsed-phase_start)
		for spot in disco_spots:
			spot.rotation.x = lerpf(disco_rest_pitch,-.11,raise_beam)
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
