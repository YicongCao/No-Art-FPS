extends "res://scripts/arena.gd"

const Sweep = preload("res://scripts/maps/sweeping_light.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
const RAIN_SHADER = preload("res://assets/shaders/market_rain.gdshader")
const BELT_SPEED = 1.05
const IMPACTS = {
	"ice": [[Vector3(.12,.092,.14),Color("bfe8ff")],[Vector3(.17,.11,.081),Color("fff1de")],[Vector3(.10,.062,.16),Color("83a7e8")]],
	"produce": [[Vector3(.12,.12,.14),Color("e89e54")],[Vector3(.10,.09,.12),Color("8db566")]],
	"luggage": [[Vector3(.23,.016,.115),Color("f4e9d6")],[Vector3(.061,.055,.21),Color("d1d8ee")],[Vector3(.12,.061,.09),Color("e28a58")]],
	"metal": [[Vector3(.12,.045,.13),Color("adc8dd")],[Vector3(.09,.07,.14),Color("f6ca70")]],
	"instrument": [[Vector3(.17,.043,.12),Color("b5d3e9")],[Vector3(.07,.10,.07),Color("fff4d6")],[Vector3(.13,.033,.16),Color("718eb6")]],
}

@export var route_paths: Array[NodePath] = []
@export var spot_specs: Array = []
@export var belt_directions: Array[int] = []
@export var comedy_site: Vector4
@export var normal_sky: Color
var frenzy_lights: Array[SpotLight3D] = []
var frenzy_origins: Array[Vector3] = []
var frenzy_targets: Array[Vector3] = []
var frenzy_motion: Array[Vector3] = []
var belt_lamps: Array[MeshInstance3D] = []
var belts: Array[StaticBody3D] = []
var rain: MultiMeshInstance3D
var dome: Node3D
var belt_bags: Array[Node3D] = []

func _ready() -> void:
	super._ready()
	if game==null:
		return
	for entry in spot_specs:
		var at = Vector3(entry[0][0],entry[0][1],entry[0][2])
		var target = Vector3(entry[1][0],entry[1][1],entry[1][2])
		var motion = Vector3(entry[6][0],entry[6][1],entry[6][2])
		var light = Sweep.add_spot(self,"ArenaSpot",at,Color(entry[2]),entry[3],entry[4],entry[5],false)
		light.look_at(to_global(target))
		if motion.is_zero_approx():
			continue
		if entry[7]:
			Sweep.add_shaft(light,8.2,.065,4.8,.16)
		frenzy_lights.append(light)
		frenzy_origins.append(at)
		frenzy_targets.append(target)
		frenzy_motion.append(motion)
		if map_id=="baggage_below" and at.y<2.0:
			var lamp = MeshInstance3D.new()
			var lens = BoxMesh.new()
			lens.size = Vector3(.07,.14,.65)
			lamp.mesh = lens
			var paint = StandardMaterial3D.new()
			paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			paint.albedo_color = light.light_color
			lamp.material_override = paint
			lamp.position = at+Vector3.DOWN*.36
			add_child(lamp)
			belt_lamps.append(lamp)
	for body in get_node("Belts").get_children():
		belts.append(body)
	dome = get_node_or_null("Moving/dome")
	if map_id=="rain_market":
		add_rain()
	if not belts.is_empty():
		add_belt_bags()
	set_destroy_lighting(false)

func add_rain() -> void:
	var batch = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	var streak = BoxMesh.new()
	streak.size = Vector3(.023,.46,.019)
	batch.mesh = streak
	batch.instance_count = 390
	var random = RandomNumberGenerator.new()
	random.seed = 1908
	for i in range(batch.instance_count):
		var z = random.randf_range(-23,23)
		var y = random.randf_range(5.2,10.3)+clampf((18-z)*.103,0,3.7)
		var at = Vector3(random.randf_range(-17.6,17.6),y,z)
		batch.set_instance_transform(i,Transform3D(Basis(Vector3.FORWARD,-.11),at))
		batch.set_instance_custom_data(i,Color(random.randf(),0,0,1))
	batch.custom_aabb = AABB(Vector3(-19,-3,-25),Vector3(38,18,50))
	rain = MultiMeshInstance3D.new()
	rain.multimesh = batch
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint = ShaderMaterial.new()
	paint.shader = RAIN_SHADER
	rain.material_override = paint
	add_child(rain)

func add_belt_bags() -> void:
	var model = load("res://assets/models/baggage_below/suitcase.glb") as PackedScene
	for _index in range(belts.size()*2):
		var bag = model.instantiate() as Node3D
		bag.scale = Vector3.ONE*.86
		add_child(bag)
		belt_bags.append(bag)

func _process(_delta: float) -> void:
	if game==null:
		return
	var active: bool = game.state=="RUNNING" and game.rules.active and not game.finale_active
	if is_instance_valid(rain):
		rain.visible = not game.reduced_motion
	for i in range(belts.size()):
		var velocity = BELT_SPEED*belt_directions[i] if active else 0.0
		belts[i].constant_linear_velocity = Vector3(0,0,velocity)
	var elapsed: float = game.rules.elapsed
	for i in range(belts.size()):
		var track = belts[i].get_node("Surface") as MeshInstance3D
		var paint = track.material_override as ShaderMaterial
		var travel: float = fmod(elapsed*BELT_SPEED*belt_directions[i],17.5)
		paint.set_shader_parameter("travel",travel)
		for j in range(2):
			var bag = belt_bags[i*2+j]
			bag.position = belts[i].position+Vector3((j-.5)*1.55,.10, fposmod(travel+3.1+j*8.5,16.2)-8.1)
	if active and game.destroy_active:
		pose_frenzy(sweep_elapsed())

func set_destroy_lighting(active: bool) -> void:
	for light in frenzy_lights:
		light.visible = active
	for lamp in belt_lamps:
		lamp.visible = active
	if is_instance_valid(dome):
		dome.rotation.y = 0
		# Each scene owns its environment resource. Reset it on every round.
		environment_override.background_color = Color("263c76") if active else normal_sky
		environment_override.ambient_light_color = Color("acbfff") if active else Color("cddfff")
		environment_override.ambient_light_energy = .60 if active else .81
	if active and game:
		pose_frenzy(sweep_elapsed())

func pose_frenzy(elapsed: float) -> void:
	if is_instance_valid(dome):
		dome.rotation.y = sin(elapsed*.60)*.42
	for i in range(frenzy_lights.size()):
		var phase = elapsed*.87+i*1.64
		var target = frenzy_targets[i]+frenzy_motion[i]*sin(phase)
		var light = frenzy_lights[i]
		if is_instance_valid(dome) and i==0:
			target = frenzy_targets[i]+frenzy_motion[i]*(dome.rotation.y/.42)
			light.position.x = frenzy_origins[i].x+dome.rotation.y*1.9
		light.look_at(to_global(target))
		if map_id=="baggage_below" and i<belt_lamps.size():
			var pulse = .5+.5*cos(elapsed*5.3-(i/2.0)*1.12)
			light.light_energy = .25+4.3*pulse*pulse
			var lamp_paint = belt_lamps[i].material_override as StandardMaterial3D
			lamp_paint.albedo_color = Color("253143").lerp(light.light_color,.25+.75*pulse)

func prop_impact(prop: Node3D, point: Vector3, normal: Vector3, _burning: bool) -> bool:
	if not "impact_kind" in prop or prop.impact_kind.is_empty():
		return false
	scatter_prop(prop.impact_kind,point,normal,prop.world_bounds().position.y,false)
	return true

func scatter_prop(kind: String, point: Vector3, normal: Vector3, floor_y: float, burst: bool) -> void:
	var fx = CombatFX.new()
	fx.name = "ArenaPropDebris"
	fx.game = game
	fx.duration = .8 if burst else .27
	game.effects.add_child(fx)
	var variants: Array = IMPACTS[kind]
	var count = (10 if burst else 4) if game.reduced_motion else (20 if burst else 7)
	var tangent = normal.cross(Vector3.UP if absf(normal.y)<.95 else Vector3.RIGHT).normalized()
	for i in range(count):
		var direction = tangent.rotated(normal,i*TAU/count)
		var variant: Array = variants[i%variants.size()]
		var extent: Vector3 = variant[0]*fx.rng.randf_range(.7,1.25)*(1.35 if burst else 1.0)
		var drift = Vector3.ZERO
		if burst and kind=="luggage":
			drift = Vector3(0,0,-BELT_SPEED if point.x<0 else BELT_SPEED)
		var velocity = normal*1.55+direction*fx.rng.randf_range(1.1,2.9)+Vector3.UP*1.4+drift
		fx.chunk(point+normal*.042,extent,variant[1],velocity,floor_y+.03)
	fx.show_pieces(false)

func validate_map() -> bool:
	return opening_paths.size()==8 and reinforcement_paths.size()>=12 and respawn_paths.size()>=6

func validate_navigation() -> bool:
	var navigation_map = get_world_3d().navigation_map
	var start = player_start().origin
	var valid = true
	for path in opening_paths+reinforcement_paths+respawn_paths+route_paths:
		var at: Vector3 = get_node(path).global_position
		var point = NavigationServer3D.map_get_closest_point(navigation_map,at)
		var route = NavigationServer3D.map_get_path(navigation_map,start,point,true)
		if point.distance_to(at)>.77 or route.is_empty() or route[-1].distance_to(point)>.51:
			push_error("%s has no walkable route to %s at %s (nearest %s)"%[map_id,path,at,point])
			valid = false
	return valid
