extends "res://scripts/arena.gd"

@export var route_paths: Array[NodePath] = []

const SweepingLight = preload("res://scripts/maps/sweeping_light.gd")
const SWEEP_SPOTS = [1,2,4]
const NORMAL_COLORS = [Color("ffe5b3"),Color("ffe4ae"),Color("e5dbff"),Color("ffe5b3"),Color("ffe4ae")]
const NEON_COLORS = [Color("cbff46"),Color("ff399b"),Color("34edff"),Color("ffb142"),Color("9a5aff")]
var stage_spots: Array[SpotLight3D] = []
var sweeping_spots: Array[SpotLight3D] = []
var spotlight_centers: Array[Vector3] = []

func _ready() -> void:
	super._ready()
	if game==null:return
	for index in range(NEON_COLORS.size()):
		var spot: SpotLight3D = get_node("PracticalLighting/StageSpot%d"%index)
		stage_spots.append(spot)
		if index not in SWEEP_SPOTS:continue
		sweeping_spots.append(spot)
		spotlight_centers.append(spot.position-spot.basis.z*(spot.spot_range-1.8))
		spot.light_color = NORMAL_COLORS[index]
		spot.light_energy = 2.3 if index==2 else 2.6
		spot.spot_angle = 20.0
		spot.shadow_enabled = index==2 and not OS.has_feature("web")
		SweepingLight.add_shaft(spot,spot.spot_range-1.3,.20,14.0,.17)
	add_key_softbox()
	pose_spots(0)

func add_key_softbox() -> void:
	# A broad, fixed key provides readable faces between the moving stage spots.
	var fixture := Node3D.new()
	fixture.name = "StageKeySoftbox"
	fixture.position = Vector3(0,5.55,1.4)
	add_child(fixture)
	var housing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.9,.16,1.2)
	housing.mesh = box
	var casing := StandardMaterial3D.new()
	casing.albedo_color = Color("25304a")
	housing.material_override = casing
	fixture.add_child(housing)
	var diffuser := MeshInstance3D.new()
	var panel := BoxMesh.new()
	panel.size = Vector3(2.7,.035,1.03)
	diffuser.mesh = panel
	diffuser.position.y = -.095
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("fff1d9")
	paint.emission_enabled = true
	paint.emission = Color("fff1d9")
	paint.emission_energy_multiplier = .8
	diffuser.material_override = paint
	diffuser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fixture.add_child(diffuser)
	var key = SweepingLight.add_spot(fixture,"Key",Vector3(0,-.15,0),Color("fff0d4"),2.1,15,58,false)
	key.look_at(to_global(Vector3(0,1.1,-4.6)))

func _process(_delta: float) -> void:
	if game and game.state=="RUNNING" and game.rules.active and not game.finale_active:
		pose_spots(sweep_elapsed())

func restore_structures() -> void:
	super.restore_structures()
	pose_spots(0)

func set_destroy_lighting(active: bool) -> void:
	var colors = NEON_COLORS if active else NORMAL_COLORS
	for i in range(stage_spots.size()):
		SweepingLight.set_tint(stage_spots[i],colors[i])

func pose_spots(elapsed: float) -> void:
	for i in range(sweeping_spots.size()):
		var spot = sweeping_spots[i]
		var phase = elapsed*(.71+i*.12)+i*TAU/3.0
		var target = spotlight_centers[i]+Vector3(sin(phase)*2.45,0,cos(phase)*1.3)
		spot.look_at(to_global(target))

func validate_map() -> bool:
	return opening_paths.size()==8 and reinforcement_paths.size()>=12 and respawn_paths.size()>=6

func validate_navigation() -> bool:
	var map = get_world_3d().navigation_map
	var start = player_start().origin
	for path in opening_paths+reinforcement_paths+respawn_paths+route_paths:
		var point: Vector3 = get_node(path).global_position
		var closest = NavigationServer3D.map_get_closest_point(map,point)
		var route = NavigationServer3D.map_get_path(map,start,closest,true)
		if closest.distance_to(point)>.8 or route.is_empty() or route[-1].distance_to(closest)>.6:
			push_error("Studio route unavailable: %s at %s (closest %s)"%[path,point,closest])
			return false
	return true
