extends "res://scripts/arena.gd"

const Sweep = preload("res://scripts/maps/sweeping_light.gd")
const AirportDisplay = preload("res://scripts/maps/airport_display.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
const SNOW_SHADER = preload("res://assets/shaders/observatory_snow.gdshader")
const RAIN_SHADER = preload("res://assets/shaders/market_rain.gdshader")
const AWNING_SHADER = preload("res://assets/shaders/market_awning.gdshader")
const PUDDLES_SHADER = preload("res://assets/shaders/market_puddles.gdshader")
const NEON_FISH_SHADER = preload("res://assets/shaders/market_neon_fish.gdshader")
const HARBOUR_SHADER = preload("res://assets/shaders/market_harbour.gdshader")
const RED_STRIP_SHADER = preload("res://assets/shaders/observatory_light_strip.gdshader")
const PIPE_SPRAY_SHADER = preload("res://assets/shaders/market_pipe_spray.gdshader")
const STAR_CHART_SHADER = preload("res://assets/shaders/observatory_star_chart.gdshader")
const MINIBUS_START = 32.0
const MINIBUS_DOOR_OPEN_TIME = .85
const MINIBUS_WAVE_SIZE = 3
const BELT_SPEED = 1.05
const BELT_SURGE_SPEED = 1.9
const IMPACTS = {
	"ice": [[Vector3(.12,.092,.14),Color("bfe8ff")],[Vector3(.17,.11,.081),Color("fff1de")],[Vector3(.10,.062,.16),Color("83a7e8")]],
	"produce": [[Vector3(.12,.12,.14),Color("e89e54")],[Vector3(.10,.09,.12),Color("8db566")]],
	"luggage": [[Vector3(.23,.016,.115),Color("f4e9d6")],[Vector3(.061,.055,.21),Color("d1d8ee")],[Vector3(.12,.061,.09),Color("e28a58")]],
	"metal": [[Vector3(.12,.045,.13),Color("adc8dd")],[Vector3(.09,.07,.14),Color("f6ca70")]],
	"instrument": [[Vector3(.17,.043,.12),Color("b5d3e9")],[Vector3(.07,.10,.07),Color("fff4d6")],[Vector3(.13,.033,.16),Color("718eb6")]],
}

@export var route_paths: Array[NodePath] = []
@export var minibus_entry_path: NodePath
@export var minibus_rally_paths: Array[NodePath] = []
@export var spot_specs: Array = []
@export var awning_specs: Array = []
@export var neon_lamp_specs: Array = []
@export var harbour_ferry_specs: Array = []
@export var airport_layout: Dictionary = {}
@export var belt_directions: Array[int] = []
@export var comedy_site: Vector4
@export var normal_sky: Color
var frenzy_lights: Array[SpotLight3D] = []
var frenzy_origins: Array[Vector3] = []
var frenzy_targets: Array[Vector3] = []
var frenzy_motion: Array[Vector3] = []
var airport_display: AirportDisplay
var belts: Array[StaticBody3D] = []
var rain: MultiMeshInstance3D
var minibus_entry: Marker3D
var minibus_door: Node3D
var minibus_door_shape: CollisionShape3D
var minibus_closed_x: float
var minibus_next_spawn := MINIBUS_START
var minibus_seats := 0
var snow: MultiMeshInstance3D
var snow_paint: ShaderMaterial
var snow_elapsed: float = 0.0
var puddles: ShaderMaterial
var neon_fish_paint: ShaderMaterial
var neon_tubes: Array[StandardMaterial3D] = []
var neon_lamps: Array[OmniLight3D] = []
var harbour_paint: ShaderMaterial
var harbour_ferries: Array[Node3D] = []
var harbour_title_time := 0.0
var awning_paint: ShaderMaterial
var wind_phase: float = 0.0
var service_shortcut: Node3D
var pipe_spray: MeshInstance3D
var star_chart: MeshInstance3D
var deck_light: MeshInstance3D
var dome: Node3D
var shutter_left: Node3D
var shutter_right: Node3D
var shutter_lights: Node3D
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
		light.look_at(to_global(target),Vector3.BACK if absf(at.direction_to(target).y)>.99 else Vector3.UP)
		if motion.is_zero_approx():
			continue
		if entry[7]:
			Sweep.add_shaft(light,8.2,.065,4.8,.16)
		frenzy_lights.append(light)
		frenzy_origins.append(at)
		frenzy_targets.append(target)
		frenzy_motion.append(motion)
	for body in get_node("Belts").get_children():
		belts.append(body)
	dome = get_node_or_null("Moving/dome")
	shutter_left = get_node_or_null("Moving/shutter_left")
	shutter_right = get_node_or_null("Moving/shutter_right")
	shutter_lights = get_node_or_null("Moving/shutter_lights")
	if map_id=="rain_market":
		setup_minibus()
		setup_market_ambience()
		var fish: Node3D = get_node("Moving/neon_fish")
		neon_fish_paint = ShaderMaterial.new()
		neon_fish_paint.shader = NEON_FISH_SHADER
		for mesh: MeshInstance3D in fish.find_children("*","MeshInstance3D",true,false):
			mesh.material_override = neon_fish_paint
		add_rain()
		puddles = ShaderMaterial.new()
		puddles.shader = PUDDLES_SHADER
		add_wet_film(0,36.0,-18,18,3.7,0)
		add_wet_film(0,46.0,-25,-18,3.7,3.7)
		add_wet_film(0,46.0,18,25,0,0)
		for x in [-20.5,20.5]:
			var upper_y = 3.7*26/36+2.05
			var lower_y = 3.7*8/36+2.05
			add_wet_film(x,4.82,-18,-8,3.7,upper_y)
			add_wet_film(x,4.82,-8,10,upper_y,lower_y)
			add_wet_film(x,4.82,10,18,lower_y,0)
		add_awnings()
		service_shortcut = get_node("Props/ServiceShortcut")
		pipe_spray = MeshInstance3D.new()
		var spray_mesh = QuadMesh.new()
		spray_mesh.size = Vector2(2.15,1.50)
		pipe_spray.mesh = spray_mesh
		var spray_paint = ShaderMaterial.new()
		spray_paint.shader = PIPE_SPRAY_SHADER
		pipe_spray.material_override = spray_paint
		pipe_spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pipe_spray.position = service_shortcut.position+Vector3(1.51,1.01,-1.98)
		add_child(pipe_spray)
	if is_instance_valid(dome):
		add_snow()
		var paint = ShaderMaterial.new()
		paint.shader = RED_STRIP_SHADER
		deck_light = horizontal_effect(Vector2(1.04,8.7),Vector3(16.05,2.434,-2.51),paint)
		var chart_paint = ShaderMaterial.new()
		chart_paint.shader = STAR_CHART_SHADER
		star_chart = horizontal_effect(Vector2(13.3,13.3),dome.position+Vector3.UP*.039,chart_paint)
	if not belts.is_empty():
		add_belt_bags()
	if map_id=="baggage_below":
		airport_display = AirportDisplay.new()
		airport_display.name = "AirportDisplay"
		add_child(airport_display)
		airport_display.setup(airport_layout,belts)
	set_destroy_lighting(false)

func setup_market_ambience() -> void:
	for mesh: MeshInstance3D in get_node("Architecture/street_neon").find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if material and material.emission_enabled:
				var tube := material.duplicate() as StandardMaterial3D
				mesh.set_surface_override_material(surface,tube)
				neon_tubes.append(tube)
	for entry in neon_lamp_specs:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(entry[0][0],entry[0][1],entry[0][2])
		lamp.light_color = Color(entry[1])
		lamp.omni_range = 5.4
		lamp.omni_attenuation = 1.25
		lamp.shadow_enabled = false
		add_child(lamp)
		neon_lamps.append(lamp)
	harbour_paint = ShaderMaterial.new()
	harbour_paint.shader = HARBOUR_SHADER
	for mesh: MeshInstance3D in get_node("Architecture/harbour_water").find_children("*","MeshInstance3D",true,false):
		mesh.material_override = harbour_paint
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for entry in harbour_ferry_specs:
		harbour_ferries.append(get_node("Moving/"+entry[0]))

func pose_market_ambience(seconds: float) -> void:
	var neon_time := seconds if not game.reduced_motion else 1.5
	for i in range(neon_tubes.size()):
		var brightness := 0.5 + 0.5 * sin(neon_time*1.11 + i*.81)
		neon_tubes[i].emission_energy_multiplier = lerpf(.18,1.48,brightness)
	for i in range(neon_lamps.size()):
		var brightness := 0.5 + 0.5 * sin(neon_time*1.11 + neon_lamp_specs[i][2])
		neon_lamps[i].light_energy = lerpf(.26,1.75,brightness)
	neon_fish_paint.set_shader_parameter("brightness",.73 + .27*sin(neon_time*1.11+2.1))
	harbour_paint.set_shader_parameter("elapsed",seconds if not game.reduced_motion else 0.0)
	for i in range(harbour_ferries.size()):
		var spec: Array = harbour_ferry_specs[i]
		harbour_ferries[i].position.x = fposmod(spec[1]+seconds*spec[2]+94.0,188.0)-94.0

func horizontal_effect(size: Vector2, at: Vector3, paint: ShaderMaterial) -> MeshInstance3D:
	var effect = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = size
	effect.mesh = plane
	effect.position = at
	effect.material_override = paint
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(effect)
	return effect

func add_wet_film(x: float, width: float, rear: float, front: float, high_y: float, low_y: float) -> void:
	var length = front-rear
	var drop = high_y-low_y
	var film = horizontal_effect(Vector2(width,Vector2(length,drop).length()),
		Vector3(x,(high_y+low_y)*.5+.028,(front+rear)*.5),puddles)
	film.rotation.x = atan2(drop,length)

func add_awnings() -> void:
	awning_paint = ShaderMaterial.new()
	awning_paint.shader = AWNING_SHADER
	var fabric = PlaneMesh.new()
	fabric.orientation = PlaneMesh.FACE_Z
	fabric.size = Vector2.ONE
	fabric.subdivide_width = 31
	fabric.subdivide_depth = 11
	for entry in awning_specs:
		var cloth = MeshInstance3D.new()
		cloth.name = "WindblownTarpaulin"
		cloth.mesh = fabric
		cloth.material_override = awning_paint
		cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cloth.extra_cull_margin = .46
		cloth.scale = Vector3(entry[1],entry[2],1.0)
		cloth.position = Vector3(entry[0][0],entry[0][1]-entry[2]*.5,entry[0][2])
		cloth.rotation.y = entry[3]
		add_child(cloth)

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
		var at = Vector3(random.randf_range(-22.7,22.7),y,z)
		batch.set_instance_transform(i,Transform3D(Basis(Vector3.FORWARD,-.11),at))
		batch.set_instance_custom_data(i,Color(random.randf(),0,0,1))
	batch.custom_aabb = AABB(Vector3(-24,-3,-25),Vector3(48,18,50))
	rain = MultiMeshInstance3D.new()
	rain.multimesh = batch
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint = ShaderMaterial.new()
	paint.shader = RAIN_SHADER
	rain.material_override = paint
	add_child(rain)

func add_snow() -> void:
	var batch = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	var crystal = QuadMesh.new()
	crystal.size = Vector2.ONE
	batch.mesh = crystal
	batch.instance_count = 2200
	batch.custom_aabb = AABB(Vector3(-26,0,-28),Vector3(55,16,54))
	var random = RandomNumberGenerator.new()
	random.seed = 9253
	for i in range(batch.instance_count):
		var at = Vector3(random.randf_range(-25.0,25.0),0,random.randf_range(-25.0,25.0))
		batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,at))
		batch.set_instance_custom_data(i,Color(random.randf(),random.randf(),random.randf(),random.randf()))
	snow = MultiMeshInstance3D.new()
	snow.name = "Snowfall"
	snow.multimesh = batch
	snow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	snow_paint = ShaderMaterial.new()
	snow_paint.shader = SNOW_SHADER
	snow_paint.set_shader_parameter("crystal",load("res://assets/art/weather/snow-crystal.svg"))
	snow_paint.set_shader_parameter("arena_origin",global_position)
	snow_paint.set_shader_parameter("dome_center",Vector2(dome.position.x,dome.position.z))
	snow.material_override = snow_paint
	snow.visible = not game.reduced_motion
	add_child(snow)

func setup_minibus() -> void:
	if minibus_entry_path.is_empty():return
	minibus_entry = get_node(minibus_entry_path)
	minibus_door = get_node("Moving/minibus_door")
	minibus_closed_x = minibus_door.position.x
	var body = StaticBody3D.new()
	body.collision_mask = 0
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.01,2.0,.12)
	minibus_door_shape = CollisionShape3D.new()
	minibus_door_shape.shape = shape
	body.add_child(minibus_door_shape)
	minibus_door.add_child(body)

func pose_minibus(open_amount: float) -> void:
	minibus_door.position.x = minibus_closed_x-2.06*open_amount
	var clear = open_amount>=.95
	if minibus_door_shape.disabled!=clear:
		minibus_door_shape.set_deferred("disabled",clear)

func reset_objectives() -> void:
	minibus_seats = 0
	minibus_next_spawn = MINIBUS_START
	if minibus_door:pose_minibus(0.0)

func dispatch_reinforcements() -> void:
	if not minibus_entry or game.rules.elapsed<minibus_next_spawn:return
	var enemies: Array = game.live_enemies()
	var room: int = game.population_target()-enemies.size()
	if room<=0:return
	if minibus_seats==0:
		minibus_seats = mini(MINIBUS_WAVE_SIZE,room)
	var point := minibus_entry.global_position
	if point.distance_to(game.player.global_position)<1.8 or not game.spawn_is_clear(point):
		minibus_next_spawn = game.rules.elapsed+.20
		return
	var rushers = enemies.filter(func(enemy):return enemy.fast).size()
	var enemy = game.spawn_enemy(point,minibus_seats==MINIBUS_WAVE_SIZE and rushers<3)
	enemy.rotation.y = PI
	var closest = INF
	for path in minibus_rally_paths:
		var rally: Vector3 = get_node(path).global_position
		var distance = rally.distance_squared_to(game.player.global_position)
		if distance<closest:
			closest = distance
			enemy.reinforcement_rally = rally
	minibus_seats -= 1
	minibus_next_spawn = game.rules.elapsed+(3.0 if minibus_seats==0 else .70)

func add_belt_bags() -> void:
	var model = load("res://assets/models/baggage_below/suitcase.glb") as PackedScene
	for _index in range(belts.size()*2):
		var bag = model.instantiate() as Node3D
		bag.scale = Vector3.ONE*.86
		add_child(bag)
		belt_bags.append(bag)

func _process(delta: float) -> void:
	if game==null:
		return
	var active: bool = game.state=="RUNNING" and game.rules.active and not game.finale_active
	if snow:
		snow.visible = not game.reduced_motion
		if snow.visible and (active or game.state=="TITLE"):
			snow_elapsed += delta
			snow_paint.set_shader_parameter("elapsed",snow_elapsed)
	if is_instance_valid(rain):
		rain.visible = not game.reduced_motion
		if active or game.state=="TITLE":
			var gust_speed = 4.9 if game.destroy_active else 2.7
			wind_phase = fposmod(wind_phase+delta*gust_speed,TAU*2.0)
		var phase = 0.0 if game.reduced_motion else wind_phase
		awning_paint.set_shader_parameter("wind_phase",phase)
		puddles.set_shader_parameter("ripple_phase",phase)
	var elapsed: float = game.rules.elapsed
	if harbour_paint:
		if game.state=="TITLE":harbour_title_time += delta
		if active or game.state=="TITLE":
			pose_market_ambience(harbour_title_time if game.state=="TITLE" else elapsed)
	if minibus_door and active:
		pose_minibus(smoothstep(MINIBUS_START-MINIBUS_DOOR_OPEN_TIME,MINIBUS_START-.05,elapsed))
	if pipe_spray:
		pipe_spray.visible = game.destroy_active and service_shortcut.collapsed
		pipe_spray.material_override.set_shader_parameter("elapsed",elapsed)
	var speed = BELT_SURGE_SPEED if game.destroy_active else BELT_SPEED
	var frenzy_elapsed: float = maxf(0.0,elapsed-(game.rules.duration-game.rules.destroy_duration))
	var belt_travel: float = elapsed*BELT_SPEED+frenzy_elapsed*(BELT_SURGE_SPEED-BELT_SPEED)
	for i in range(belts.size()):
		var direction = belt_directions[i]
		belts[i].constant_linear_velocity = Vector3(0,0,speed*direction) if active else Vector3.ZERO
		var track = belts[i].get_node("Surface") as MeshInstance3D
		var paint = track.material_override as ShaderMaterial
		var travel = belt_travel*direction
		paint.set_shader_parameter("travel",fmod(travel,1.0/3.5))
		for j in range(2):
			var bag = belt_bags[i*2+j]
			bag.position = belts[i].position+Vector3((j-.5)*1.55,.10,fposmod(travel+3.1+j*8.5,16.2)-8.1)
	if airport_display:
		if game.state=="TITLE":
			airport_display.idle_seconds += delta
		var display_seconds = airport_display.idle_seconds if game.state=="TITLE" else elapsed
		airport_display.pose(display_seconds,game.reduced_motion)
	if active and game.destroy_active:
		pose_frenzy(sweep_elapsed())

func set_destroy_lighting(active: bool) -> void:
	for light in frenzy_lights:
		light.visible = active
	if airport_display and not active:
		airport_display.warning_lights(false,0.0,false)
	if puddles:
		puddles.set_shader_parameter("frenzy",active)
		pipe_spray.visible = active and service_shortcut.collapsed
		if not active:neon_fish_paint.set_shader_parameter("progress",1.0)
	if not belts.is_empty():
		environment_override.ambient_light_energy = .63 if active else .83
		game.sun.light_energy = .25 if active else sun_energy
	if is_instance_valid(dome):
		deck_light.visible = active
		star_chart.visible = active
		shutter_lights.visible = active
		if not active:
			pose_shutters(0.0)
		# Each scene owns its environment resource. Reset it on every round.
		environment_override.background_color = Color("263c76") if active else normal_sky
		environment_override.ambient_light_color = Color("acbfff") if active else Color("cddfff")
		environment_override.ambient_light_energy = .60 if active else .81
	if active and game:
		pose_frenzy(sweep_elapsed())

func pose_shutters(openness: float) -> void:
	const SHUTTER_TRAVEL = .465
	shutter_left.rotation.y = SHUTTER_TRAVEL*openness
	shutter_right.rotation.y = -SHUTTER_TRAVEL*openness

func pose_frenzy(elapsed: float) -> void:
	var dome_sweep := sin(elapsed*.60)
	if neon_fish_paint:
		var seconds: float = game.rules.elapsed-(game.rules.duration-game.rules.destroy_duration)
		neon_fish_paint.set_shader_parameter("progress",1.0 if game.reduced_motion else clampf(seconds/.85,0.0,1.0))
	var warning = Vector2.ZERO
	if airport_display:
		var frenzy_seconds: float = game.round_music_position()-(game.rules.duration-game.rules.destroy_duration)
		warning = airport_display.warning_lights(true,frenzy_seconds,game.reduced_motion)
	if is_instance_valid(dome):
		const SHUTTER_OPEN_SECONDS = 2.2
		var phase_start: float = game.rules.duration-game.rules.destroy_duration
		var open_amount := smoothstep(0.0,SHUTTER_OPEN_SECONDS,game.rules.elapsed-phase_start)
		pose_shutters(1.0 if game.reduced_motion else open_amount)
		deck_light.rotation.y = PI*.5+dome_sweep*.17
		deck_light.position.z = -2.65+dome_sweep*.89
		star_chart.rotation.y = elapsed*.23
	for i in range(frenzy_lights.size()):
		var phase = elapsed*.87+i*1.64
		var target = frenzy_targets[i]+frenzy_motion[i]*sin(phase)
		var light = frenzy_lights[i]
		if is_instance_valid(dome) and i==0:
			target = frenzy_targets[i]+frenzy_motion[i]*dome_sweep
			light.position.x = frenzy_origins[i].x+dome_sweep*.78
		light.look_at(to_global(target))
		if airport_display and frenzy_origins[i].y<2.0:
			light.light_energy = 4.1*(warning.x if frenzy_origins[i].x<0 else warning.y)

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
			var belt_velocity = BELT_SURGE_SPEED if game.destroy_active else BELT_SPEED
			drift = Vector3(0,0,-belt_velocity if point.x<0 else belt_velocity)
		var velocity = normal*1.55+direction*fx.rng.randf_range(1.1,2.9)+Vector3.UP*1.4+drift
		fx.chunk(point+normal*.042,extent,variant[1],velocity,floor_y+.03)
	fx.show_pieces(false)

func validate_map() -> bool:
	return opening_paths.size()==8 and reinforcement_paths.size()>=12 and respawn_paths.size()>=6

func validate_navigation() -> bool:
	var navigation_map = get_world_3d().navigation_map
	var start = player_start().origin
	var valid = true
	var paths = opening_paths+reinforcement_paths+respawn_paths+route_paths+minibus_rally_paths
	if not minibus_entry_path.is_empty():paths.append(minibus_entry_path)
	for path in paths:
		var at: Vector3 = get_node(path).global_position
		var point = NavigationServer3D.map_get_closest_point(navigation_map,at)
		var route = NavigationServer3D.map_get_path(navigation_map,start,point,true)
		if point.distance_to(at)>.77 or route.is_empty() or route[-1].distance_to(point)>.51:
			push_error("%s has no walkable route to %s at %s (nearest %s)"%[map_id,path,at,point])
			valid = false
	return valid
