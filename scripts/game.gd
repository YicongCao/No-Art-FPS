extends Node3D

const Arena = preload("res://scripts/arena.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Hud = preload("res://scripts/hud.gd")
const Rules = preload("res://scripts/run_rules.gd")
var arena: Node3D
var player: CharacterBody3D
var hud: Control
var enemies: Node3D
var effects: Node3D
var rules = Rules.new()
var state = "TITLE"
var previous_state = "RUNNING"
var ready_time = 3.0
const MAGAZINE_SIZE = 20
const MAX_HEALTH = 100.0
const HEAL_DELAY = 5.0
const HEAL_RATE = 12.0
var ammo = MAGAZINE_SIZE
var reload_time = 0.0
var fire_time = 0.0
var spawn_time = 0.0
var health = MAX_HEALTH
var new_record = false
var invulnerable = 0.0
var since_damage = 0.0
var respawn_time = 0.0
var best = 0
var reduced_motion = false
var bullets: Array[Dictionary] = []
var sounds: Dictionary = {}
var audio_voices: Array[AudioStreamPlayer] = []
var audio_index = 0
var last_tick = 0
var spawn_cooldowns: Array[float] = [0,0,0,0,0,0]
var pending_spawn: Dictionary = {}
var nav_ready = false
var rng = RandomNumberGenerator.new()
var qa_mode = false

func _ready() -> void:
	process_physics_priority = -100
	qa_mode = "--qa" in OS.get_cmdline_user_args()
	rng.seed = 61105
	var env = WorldEnvironment.new()
	var settings = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("5b7fc8")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dce8ff")
	settings.ambient_light_energy = .52
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = settings
	add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-35,0)
	sun.light_color = Color("fff3d5")
	sun.light_energy = .22
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	arena = Arena.new()
	add_child(arena)
	arena.bake_navigation()
	player = Player.new()
	player.game = self
	add_child(player)
	player.reset_position()
	player.enabled = false
	enemies = Node3D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	effects = Node3D.new()
	effects.name = "Effects"
	add_child(effects)
	var layer = CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	for key in ["shot","hit","kill","headshot","reload","hurt","tick","end"]:
		sounds[key] = load("res://assets/audio/"+key+".wav")
	for i in range(12):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		audio_voices.append(voice)
	load_record()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_ready = true
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/title.png")
		get_tree().quit()
	if qa_mode:
		var test_path = "res://tests/playtest.gd"
		if "--check" in OS.get_cmdline_user_args():test_path = "res://tests/interaction_check.gd"
		if "--benchmark" in OS.get_cmdline_user_args():test_path = "res://tests/benchmark.gd"
		if "--feedback" in OS.get_cmdline_user_args():test_path = "res://tests/feedback_check.gd"
		var qa = load(test_path).new()
		qa.game = self
		add_child(qa)

func load_record() -> void:
	if qa_mode:return
	var cfg = ConfigFile.new()
	if cfg.load("user://record.cfg") == OK:
		best = int(cfg.get_value("score","best",0))
		player.sensitivity = clampf(float(cfg.get_value("settings","sensitivity",.0022)),.0006,.006)
		reduced_motion = bool(cfg.get_value("settings","reduced_motion",false))

func save_record() -> void:
	if qa_mode:return
	var cfg = ConfigFile.new()
	cfg.set_value("score","best",best)
	cfg.set_value("settings","sensitivity",player.sensitivity)
	cfg.set_value("settings","reduced_motion",reduced_motion)
	cfg.save("user://record.cfg")

func start_run() -> void:
	if not nav_ready:return
	clear_round()
	rng.seed = 61105
	rules.start()
	rules.active = false
	state = "READY"
	ready_time = 3.0
	ammo = MAGAZINE_SIZE
	reload_time = 0
	fire_time = 0
	spawn_time = 0
	health = MAX_HEALTH
	invulnerable = 1
	since_damage = 0
	respawn_time = 0
	spawn_cooldowns = [0,0,0,0,0,0]
	pending_spawn.clear()
	last_tick = 60
	new_record = false
	hud.time_pulse = 0
	hud.health_shade = 0
	player.reset_position()
	player.enabled = false
	hud.hit = 0
	hud.damage = 0
	hud.kill_pop = 0
	if not qa_mode:Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func clear_round() -> void:
	bullets.clear()
	for node in enemies.get_children():
		enemies.remove_child(node)
		node.queue_free()
	for node in effects.get_children():
		effects.remove_child(node)
		node.queue_free()
	for voice in audio_voices:voice.stop()

func begin_running() -> void:
	state = "RUNNING"
	rules.start()
	player.enabled = true
	# Deliberate opening target set when the countdown ends. Reinforcements use hidden gates.
	for p in [Vector3(-4,0,1.5),Vector3(2,0,-5),Vector3(11,0,1),Vector3(-13,0,-5)]:
		spawn_enemy(p,false)
	play_sound("tick",-10)

func finish_run() -> void:
	state = "RESULTS"
	rules.active = false
	player.enabled = false
	player.velocity = Vector3.ZERO
	new_record = rules.kills > best
	best = maxi(best,rules.kills)
	save_record()
	pending_spawn.clear()
	for bullet in bullets:
		if is_instance_valid(bullet.node):bullet.node.queue_free()
	bullets.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_sound("end",-7)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not qa_mode and state in ["READY","RUNNING"]:
		pause_run()

func pause_run() -> void:
	previous_state = state
	state = "PAUSED"
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state in ["RUNNING","READY"]:pause_run()
		elif state == "PAUSED":menu_action("resume")
		elif state == "RESULTS":menu_action("menu")
	elif event.is_action_pressed("restart") and state in ["TITLE","RESULTS","PAUSED"]:start_run()
	elif event.is_action_pressed("reload") and state == "RUNNING":reload_weapon()
	elif event is InputEventKey and event.pressed and state == "PAUSED":
		if event.physical_keycode == KEY_MINUS:player.sensitivity = maxf(.0006,player.sensitivity-.0002)
		if event.physical_keycode in [KEY_EQUAL,KEY_PLUS]:player.sensitivity = minf(.006,player.sensitivity+.0002)
		if event.physical_keycode == KEY_M:reduced_motion = not reduced_motion
		save_record()

func menu_action(action: String) -> void:
	match action:
		"play", "retry":
			if state in ["TITLE","RESULTS","PAUSED"]:start_run()
		"resume":
			if state != "PAUSED":return
			state = previous_state
			player.enabled = state == "RUNNING"
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		"menu":
			if state != "RESULTS":return
			state = "TITLE"
			clear_round()
			player.reset_position()
		"motion":
			if state != "PAUSED":return
			reduced_motion = not reduced_motion
			save_record()

func _physics_process(delta: float) -> void:
	if state == "READY":
		ready_time -= delta
		if ready_time <= 0:begin_running()
		return
	if state != "RUNNING":return
	rules.tick(delta)
	if not rules.active:
		finish_run()
		return
	invulnerable = maxf(0,invulnerable-delta)
	since_damage += delta
	if health<MAX_HEALTH and since_damage>=HEAL_DELAY and respawn_time<=0:
		health = minf(MAX_HEALTH,health+HEAL_RATE*delta)
	if respawn_time>0:
		respawn_time -= delta
		if respawn_time<=0:
			player.reset_position()
			# Choose the most separated navigable respawn location.
			var safest = Vector3(0,.05,10.5)
			var best_distance = -1.0
			for candidate in [safest,Vector3(-14,.05,1),Vector3(14,.05,8)]:
				var min_distance = 100.0
				for enemy in live_enemies():min_distance = minf(min_distance,candidate.distance_to(enemy.position))
				if min_distance>best_distance:
					best_distance = min_distance
					safest = candidate
			player.position = safest
			player.enabled = true
			health = MAX_HEALTH
			ammo = MAGAZINE_SIZE
			reload_time = 0
			invulnerable = 1.5
	fire_time = maxf(0,fire_time-delta)
	if reload_time>0:
		reload_time -= delta
		if reload_time<=0:ammo = MAGAZINE_SIZE
	if Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:shoot()
	update_spawns(delta)
	update_bullets(delta)
	var seconds = ceili(rules.remaining())
	if seconds<=10 and seconds!=last_tick:
		last_tick = seconds
		hud.time_pulse = 1.0
		play_sound("tick",-12)

func live_enemies() -> Array:
	return enemies.get_children().filter(func(e):return not e.dead)

func spawn_enemy(pos: Vector3, fast: bool) -> Node3D:
	var enemy = Enemy.new()
	enemy.game = self
	enemy.fast = fast
	enemy.position = pos+Vector3(0,.05,0)
	enemies.add_child(enemy)
	return enemy

func update_spawns(delta: float) -> void:
	for i in range(spawn_cooldowns.size()):spawn_cooldowns[i] = maxf(0,spawn_cooldowns[i]-delta)
	if not pending_spawn.is_empty():
		pending_spawn.delay -= delta
		if pending_spawn.delay<=0:
			var p: Vector3 = pending_spawn.pos
			# The player can turn during the warning: recheck visibility before materializing.
			var query = PhysicsRayQueryParameters3D.create(player.camera.global_position,p+Vector3(0,1,0),1)
			var blocked = not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
			var screen = player.camera.unproject_position(p+Vector3(0,1,0))
			var visible_now = not player.camera.is_position_behind(p) and get_viewport().get_visible_rect().has_point(screen)
			if p.distance_to(player.position)>8 and (blocked or not visible_now) and live_enemies().size()<10:
				spawn_enemy(p,rules.elapsed>20 and rng.randf()<.3)
			pending_spawn.clear()
		return
	spawn_time -= delta
	var target = 4 if rules.elapsed<20 else (6 if rules.elapsed<40 else 8)
	if spawn_time>0 or live_enemies().size()>=target:return
	spawn_time = .4
	var choices: Array[int] = []
	for i in range(arena.spawn_points.size()):
		var p: Vector3 = arena.spawn_points[i]
		if spawn_cooldowns[i]>0 or p.distance_to(player.position)<8:continue
		var path = NavigationServer3D.map_get_path(arena.nav.get_navigation_map(),p,player.position,true)
		if path.size()<2:continue
		var query = PhysicsRayQueryParameters3D.create(player.camera.global_position,p+Vector3(0,1,0),1)
		var occluded = not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
		var screen_point = player.camera.unproject_position(p+Vector3(0,1,0))
		var visible_target = not player.camera.is_position_behind(p) and get_viewport().get_visible_rect().has_point(screen_point)
		if occluded or not visible_target:choices.append(i)
	if choices.is_empty():return
	var index = choices[rng.randi_range(0,choices.size()-1)]
	var pos: Vector3 = arena.spawn_points[index]
	spawn_cooldowns[index] = 2.5
	pending_spawn = {"pos":pos,"delay":.55}
	spark(pos+Vector3(0,.1,0),Color("f2d084"),.25,.55)

func shoot() -> void:
	if state!="RUNNING" or not rules.active or fire_time>0 or reload_time>0 or respawn_time>0:return
	if ammo<=0:
		reload_weapon()
		return
	ammo -= 1
	rules.shots += 1
	fire_time = .1
	player.recoil = 1
	hud.shot = .1
	play_sound("shot",-10,rng.randf_range(.94,1.05))
	var origin = player.camera.global_position
	var endpoint = origin-player.camera.global_basis.z*90
	var query = PhysicsRayQueryParameters3D.create(origin,endpoint,1|4|8)
	query.collide_with_areas = true
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	var target = result.position if not result.is_empty() else endpoint
	var muzzle = player.gun.to_global(Vector3(0,.015,-1.0))
	# Ray from body to muzzle prevents camera/viewmodel geometry shooting through walls.
	var clearance = PhysicsRayQueryParameters3D.create(origin,muzzle,1)
	var blockage = get_world_3d().direct_space_state.intersect_ray(clearance)
	if blockage.is_empty():
		var muzzle_query = PhysicsRayQueryParameters3D.create(muzzle,target,1)
		blockage = get_world_3d().direct_space_state.intersect_ray(muzzle_query)
	if not blockage.is_empty() and blockage.position.distance_to(target)>.12:
		target = blockage.position
		result = {}
	trace(muzzle,target,Color("fff1b7"),.025,.045)
	spark(muzzle,Color("ffe19a"),.1,.035)
	if not result.is_empty():
		var collider = result.collider
		var enemy = collider.get_meta("enemy",null) if collider is Area3D else (collider if collider.has_method("take_hit") else null)
		if enemy!=null:
			rules.hits += 1
			hud.hit = .12
			play_sound("hit",-14)
			enemy.take_hit(collider is Area3D)
			spark(target,Color("f2d084"),.07,.12)
		else:spark(target,Color("e5e0d2"),.045,.1)
	if ammo==0:reload_weapon()

func reload_weapon() -> void:
	if ammo>=MAGAZINE_SIZE or reload_time>0 or respawn_time>0 or state!="RUNNING":return
	reload_time = .9
	play_sound("reload",-8)

func on_kill(enemy: Node3D, headshot: bool) -> void:
	if rules.record_kill(enemy.get_instance_id(),headshot):
		hud.kill_pop = .5
		play_sound("headshot" if headshot else "kill",-7)

func enemy_shoot(origin: Vector3) -> void:
	if state!="RUNNING" or respawn_time>0:return
	var target = player.global_position+Vector3(0,1.1,0)+Vector3(rng.randf_range(-.25,.25),0,rng.randf_range(-.25,.25))
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = .08
	sphere.height = .16
	mesh.mesh = sphere
	mesh.material_override = effect_material(Color("ffbc65"))
	effects.add_child(mesh)
	mesh.global_position = origin
	bullets.append({"node":mesh,"velocity":origin.direction_to(target)*13,"life":3.0})

func update_bullets(delta: float) -> void:
	for i in range(bullets.size()-1,-1,-1):
		var b = bullets[i]
		if not is_instance_valid(b.node):
			bullets.remove_at(i)
			continue
		var from: Vector3 = b.node.global_position
		var to: Vector3 = from+b.velocity*delta
		var query = PhysicsRayQueryParameters3D.create(from,to,1|2)
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		b.life -= delta
		if not hit.is_empty() or b.life<=0:
			if not hit.is_empty() and hit.collider==player:damage_player()
			b.node.queue_free()
			bullets.remove_at(i)
		else:b.node.global_position = to

func damage_player() -> void:
	if state!="RUNNING" or invulnerable>0 or respawn_time>0:return
	health = maxf(0,health-34.0)
	invulnerable = .65
	since_damage = 0
	hud.damage = .8
	play_sound("hurt",-8)
	if health<=0:
		respawn_time = 1.0
		player.enabled = false
		player.velocity = Vector3.ZERO

func effect_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func spark(pos: Vector3, color: Color, radius: float, duration: float) -> void:
	var node = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 6
	mesh.rings = 3
	node.mesh = mesh
	node.material_override = effect_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effects.add_child(node)
	node.global_position = pos
	var tween = node.create_tween()
	tween.tween_property(node,"scale",Vector3.ONE*.05,duration)
	tween.tween_callback(node.queue_free)

func trace(from: Vector3, to: Vector3, color: Color, width: float, duration: float) -> void:
	var node = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(width,width,maxf(.01,from.distance_to(to)))
	node.mesh = mesh
	node.material_override = effect_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effects.add_child(node)
	node.global_position = (from+to)*.5
	if from.distance_to(to)>.01:node.look_at(to,Vector3.UP)
	var tween = node.create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(node.queue_free)

func play_sound(key: String, volume: float = -10, pitch: float = 1) -> void:
	var voice = audio_voices[audio_index%audio_voices.size()]
	audio_index += 1
	voice.stream = sounds[key]
	voice.volume_db = volume
	voice.pitch_scale = pitch
	voice.play()
