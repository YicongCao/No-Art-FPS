extends Node3D

const Sweep = preload("res://scripts/maps/sweeping_light.gd")
const Sparks = preload("res://scripts/combat_fx.gd")
const COLUMNS = 5
const LIT = Color("fff0ca")
const DEAD = Color("343d51")
const ALARM_RED = Color("ff2647")

var game: Node
var ceiling: MultiMesh
var fixtures := PackedVector3Array()
var dead_fixtures: Array[int] = []
var faulty_fixtures: Array[int] = []
var row_lights: Array[SpotLight3D] = []
var row_fixtures: Array[int] = []
var alarm_lens: StandardMaterial3D
var alarms: Array[SpotLight3D] = []
var rng := RandomNumberGenerator.new()
var next_spark := 0.0

func setup(layout: Dictionary) -> void:
	rng.randomize()
	for entry in layout.ceiling_lamps:
		fixtures.append(Vector3(entry[0],entry[1],entry[2]))
	var strip := BoxMesh.new()
	strip.size = Vector3(2.59,.055,.26)
	ceiling = MultiMesh.new()
	ceiling.transform_format = MultiMesh.TRANSFORM_3D
	ceiling.use_colors = true
	ceiling.mesh = strip
	ceiling.instance_count = fixtures.size()
	for i in range(fixtures.size()):
		ceiling.set_instance_transform(i,Transform3D(Basis.IDENTITY,fixtures[i]))
		var row := floori(float(i) / COLUMNS)
		var column := i % COLUMNS
		if (row + column) % 2 == 0:dead_fixtures.append(i)
		# One shadowless pool per row approximates the surviving strips.
		if column == 1 + row % 2:
			var light := Sweep.add_spot(self,"CeilingPool",fixtures[i] + Vector3.DOWN*.12,LIT,2.4,12.5,57,false)
			var target := Vector3(0,0,fixtures[i].z)
			light.look_at(to_global(target))
			row_lights.append(light)
			row_fixtures.append(i)
	var tubes := MultiMeshInstance3D.new()
	tubes.name = "CeilingStrips"
	tubes.multimesh = ceiling
	tubes.material_override = Sparks.paint_for(false)
	tubes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tubes)
	var dome := CylinderMesh.new()
	dome.bottom_radius = .14
	dome.top_radius = .105
	dome.height = .22
	dome.radial_segments = 10
	alarm_lens = StandardMaterial3D.new()
	alarm_lens.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for entry in layout.gate_beacons:
		var at := Vector3(entry[0],entry[1],entry[2])
		var lens := MeshInstance3D.new()
		lens.name = "AlarmDome"
		lens.mesh = dome
		lens.position = at + Vector3.UP*.11
		lens.material_override = alarm_lens
		add_child(lens)
		var beam := Sweep.add_spot(self,"GateAlarm",at + Vector3.UP*.20,ALARM_RED,3.2,7.7,26,false)
		Sweep.add_shaft(beam,5.8,.06,9.0,.20)
		alarms.append(beam)
	set_frenzy(false)

func set_frenzy(active: bool) -> void:
	var available: Array[int] = []
	faulty_fixtures.clear()
	for i in range(fixtures.size()):
		var unpowered := active and i in dead_fixtures
		ceiling.set_instance_color(i,DEAD if unpowered else LIT)
		if active and not unpowered:available.append(i)
	if active:
		for _i in range(5):
			faulty_fixtures.append(available.pop_at(rng.randi_range(0,available.size()-1)))
	for light in row_lights:
		light.visible = active
		light.light_energy = 2.4
	for light in alarms:light.visible = active
	alarm_lens.albedo_color = ALARM_RED if active else Color("642b3b")
	next_spark = .29

func pose(seconds: float, reduced_motion: bool) -> void:
	for i in faulty_fixtures:
		var cycle := fposmod(seconds + i*.371,2.1 + float(i%3)*.3)
		var flicker := not reduced_motion and cycle < .39
		var brightness := .22 if flicker and sin(cycle*44.0+i) < .36 else 1.0
		ceiling.set_instance_color(i,DEAD.lerp(LIT,brightness))
		var row := row_fixtures.find(i)
		if row >= 0:row_lights[row].light_energy = 2.4*brightness
	for i in range(alarms.size()):
		var yaw := i*2.07 + (0.0 if reduced_motion else seconds*4.1)
		alarms[i].rotation = Vector3(-.22,yaw,0.0)
	if not reduced_motion and seconds >= next_spark:
		next_spark = seconds + rng.randf_range(.65,1.40)
		throw_sparks()

func throw_sparks() -> void:
	var nearby: Array[int] = []
	var player_at := to_local(game.player.global_position as Vector3)
	for i in dead_fixtures:
		if fixtures[i].distance_squared_to(player_at) < 22.0*22.0:nearby.append(i)
	if nearby.is_empty():return
	var i := nearby[rng.randi_range(0,nearby.size()-1)]
	var at := to_global(fixtures[i] + Vector3(rng.randf_range(-.85,.85),-.12,0))
	var fx := Sparks.new()
	fx.name = "AirportElectricalSparks"
	fx.game = game
	fx.duration = .56
	game.effects.add_child(fx)
	for j in range(10):
		var velocity := Vector3(rng.randf_range(-2.1,2.1),rng.randf_range(-3.0,-.8),rng.randf_range(-1.2,1.2))
		var tint := Color("fff5d3") if j%3==0 else Color("ffbb52")
		fx.chunk(at,Vector3(.043,.23,.043),tint,velocity)
	fx.show_pieces(false)
