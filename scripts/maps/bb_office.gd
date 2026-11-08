extends "res://scripts/arena.gd"

const SweepingLight = preload("res://scripts/maps/sweeping_light.gd")
const Debris = preload("res://scripts/combat_fx.gd")
const NEON = [Color("3af0ff"), Color("fc68ba"), Color("a485ff"),
	Color("bafa52"), Color("3b8aff"), Color("ffad46")]
const IMPACTS = {
	"keys": [[Vector3(.068,.035,.068), Color("d5dae2")], [Vector3(.032,.032,.032), Color("6effec")], [Vector3(.12,.009,.13), Color("edcf91")]],
	"chips": [[Vector3(.12,.012,.09), Color("ffd060")], [Vector3(.09,.015,.12), Color("df913c")], [Vector3(.07,.011,.16), Color("e46e6c")]],
	"coffee": [[Vector3(.035,.09,.042), Color("8e4d2c")], [Vector3(.06,.065,.032), Color("f9e8cf")], [Vector3(.035,.055,.039), Color("b16b3e")]],
	"leaf": [[Vector3(.11,.012,.18), Color("7ec86e")], [Vector3(.075,.015,.13), Color("426c44")]],
	"wood": [[Vector3(.034,.27,.046), Color("b97552")], [Vector3(.065,.18,.032), Color("e2a77b")], [Vector3(.04,.068,.04), Color("dfb772")]],
}

@export var route_paths: Array[NodePath] = []
@export var sweep_centers: Array[Vector3] = []
var sweeps: Array[SpotLight3D] = []

func _ready() -> void:
	super._ready()
	if game == null:
		return
	for i in range(sweep_centers.size()):
		var mount: Node3D = get_node("LightMounts").get_child(i)
		var spot = SweepingLight.add_spot(mount, "NeonSweep", Vector3.ZERO, NEON[i], 4.0, 7.7, 28.0, false)
		SweepingLight.add_shaft(spot, 5.1, .075, 11.0, .13)
		sweeps.append(spot)
	set_destroy_lighting(false)

func _process(_delta: float) -> void:
	if game and game.destroy_active and game.state == "RUNNING" and game.rules.active and not game.finale_active:
		pose_sweeps(sweep_elapsed())

func pose_sweeps(elapsed: float) -> void:
	for i in range(sweeps.size()):
		var phase = elapsed*.94+i*TAU/6.0
		var target = sweep_centers[i]+Vector3(sin(phase)*2.6, cos(phase)*.22, cos(phase)*1.35)
		sweeps[i].look_at(to_global(target))

func set_destroy_lighting(active: bool) -> void:
	for spot in sweeps:
		spot.visible = active
	if active:
		pose_sweeps(sweep_elapsed())

func prop_impact(prop: Node3D, point: Vector3, normal: Vector3, burning: bool) -> bool:
	var kind: String = prop.get_meta("office_impact", "")
	if not IMPACTS.has(kind):
		return false
	var breach = kind == "wood" and not burning and prop.door_hits == 1
	spawn_debris(kind, point, normal, breach)
	if kind == "keys" and prop.to_local(point).y > 1.08 and normal.z > .5:
		screen_glitch(point,normal)
	if kind == "wood" and not burning:
		prop.breach_hit()
	return true

func spawn_debris(kind: String, point: Vector3, normal: Vector3, burst: bool) -> void:
	# Separate the small material bursts from destruction's full-volume effects.
	var fx = Debris.new()
	fx.name = "OfficeImpact"
	fx.game = game
	fx.duration = .56 if burst else .35
	game.effects.add_child(fx)
	var variants: Array = IMPACTS[kind]
	var count = (7 if burst else 4) if game.reduced_motion else (12 if burst else 7)
	var tangent = normal.cross(Vector3.UP if absf(normal.y) < .95 else Vector3.RIGHT).normalized()
	for i in range(count):
		var direction = tangent.rotated(normal, i*TAU/count)
		var variant: Array = variants[i % variants.size()]
		var velocity = normal*1.5 + direction*fx.rng.randf_range(.8,2.5) + Vector3.UP*1.7
		fx.chunk(point+normal*.04, variant[0]*fx.rng.randf_range(.72,1.2), variant[1], velocity, .025)
	fx.show_pieces(false)

func screen_glitch(point: Vector3, normal: Vector3) -> void:
	var fx = Debris.new()
	fx.game = game
	fx.duration = .11
	game.effects.add_child(fx)
	for i in range(3):
		var at = point+normal*.02+Vector3(.035*float(i-1),.037*float(i-1),0)
		fx.chunk(at,Vector3(.19+float(i)*.04,.014,.012),NEON[i],Vector3.ZERO,at.y)
	fx.show_pieces(false)

func validate_map() -> bool:
	return opening_paths.size() == 8 and reinforcement_paths.size() >= 12 and respawn_paths.size() >= 6

func validate_navigation() -> bool:
	var navigation_map = get_world_3d().navigation_map
	var start = player_start().origin
	var valid = true
	for path in opening_paths + reinforcement_paths + respawn_paths + route_paths:
		var point: Vector3 = get_node(path).global_position
		var closest = NavigationServer3D.map_get_closest_point(navigation_map, point)
		var route = NavigationServer3D.map_get_path(navigation_map, start, closest, true)
		if closest.distance_to(point) > .72 or route.is_empty() or route[-1].distance_to(closest) > .50:
			push_error("Office route unavailable: %s at %s, nearest %s" % [path, point, closest])
			valid = false
	return valid
