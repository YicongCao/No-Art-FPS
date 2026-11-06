extends Node3D

const Arena = preload("res://scripts/arena.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Hud = preload("res://scripts/hud.gd")
const Rules = preload("res://scripts/run_rules.gd")
const LoadingTransition = preload("res://scripts/loading_transition.gd")
const OPENING_POSITIONS = [Vector3(-4,0,1.5),Vector3(11,0,1),Vector3(30,0,3),Vector3(30,0,-10),Vector3(-4,3.1,-11),Vector3(4,3.1,-11)]
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
const RESPAWN_DELAY = 5.0
var ammo = MAGAZINE_SIZE
var reload_time = 0.0
const RELOAD_DURATION = .9
var reload_start_ammo = MAGAZINE_SIZE
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
var music: AudioStreamPlayer
var music_volume = .7
var loading = LoadingTransition.new()
var load_ticket = 0
var opening_prepared = false
var enemy_model: PackedScene

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
	arena.game = self
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
	for key in ["shot","hit","kill","headshot","reload","hurt","tick","end","fuse","explosion","charge"]:
		sounds[key] = load("res://assets/audio/"+key+".wav")
	for i in range(12):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		audio_voices.append(voice)
	music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/music/sixty.wav")
	add_child(music)
	load_record()
	set_music_volume(music_volume)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Baking and server synchronization are separate. Do not expose a playable round
	# until the actual navigation map contains the walkable starting plaza.
	for attempt in range(300):
		if NavigationServer3D.map_get_iteration_id(get_world_3d().navigation_map)==0:
			await get_tree().physics_frame
			continue
		var closest = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map,Vector3(0,0,10.5))
		if closest.distance_to(Vector3(0,0,10.5))<1.0:
			nav_ready = true
			break
		await get_tree().physics_frame
	if not nav_ready:push_error("Navigation map failed to synchronize")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/title.png")
		get_tree().quit()
	if qa_mode:
		var test_path = "res://tests/playtest.gd"
		if "--check" in OS.get_cmdline_user_args():test_path = "res://tests/interaction_check.gd"
		if "--benchmark" in OS.get_cmdline_user_args():test_path = "res://tests/benchmark.gd"
		if "--feedback" in OS.get_cmdline_user_args():test_path = "res://tests/feedback_check.gd"
		if "--expansion" in OS.get_cmdline_user_args():test_path = "res://tests/expanded_map_check.gd"
		if "--population" in OS.get_cmdline_user_args():test_path = "res://tests/population_check.gd"
		if "--combat" in OS.get_cmdline_user_args():test_path = "res://tests/combat_check.gd"
		if "--movement" in OS.get_cmdline_user_args():test_path = "res://tests/movement_check.gd"
		if "--magazine" in OS.get_cmdline_user_args():test_path = "res://tests/magazine_check.gd"
		if "--containers" in OS.get_cmdline_user_args():test_path = "res://tests/container_check.gd"
		if "--terrace" in OS.get_cmdline_user_args():test_path = "res://tests/terrace_check.gd"
		if "--graffiti" in OS.get_cmdline_user_args():test_path = "res://tests/graffiti_check.gd"
		if "--respawn" in OS.get_cmdline_user_args():test_path = "res://tests/respawn_check.gd"
		if "--loading" in OS.get_cmdline_user_args():test_path = "res://tests/loading_check.gd"
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
		music_volume = clampf(float(cfg.get_value("settings","music_volume",.7)),0,1)

func save_record() -> void:
	if qa_mode:return
	var cfg = ConfigFile.new()
	cfg.set_value("score","best",best)
	cfg.set_value("settings","sensitivity",player.sensitivity)
	cfg.set_value("settings","reduced_motion",reduced_motion)
	cfg.set_value("settings","music_volume",music_volume)
	cfg.save("user://record.cfg")

func start_run() -> void:
	if not nav_ready:return
	load_ticket += 1
	clear_round()
	reset_run_state()
	state = "READY"
	if not qa_mode:Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset_run_state() -> void:
	rng.seed = 61105
	rules.start()
	rules.active = false
	ready_time = 3.0
	ammo = MAGAZINE_SIZE
	reload_time = 0
	fire_time = 0
	spawn_time = 0
	health = MAX_HEALTH
	invulnerable = 1
	since_damage = 0
	respawn_time = 0
	spawn_cooldowns.clear()
	spawn_cooldowns.resize(arena.spawn_points.size())
	spawn_cooldowns.fill(0.0)
	pending_spawn.clear()
	last_tick = 60
	new_record = false
	hud.time_pulse = 0
	hud.health_shade = 0
	player.reset_position()
	player.gun.show()
	player.enabled = false
	hud.hit = 0
	hud.damage = 0
	hud.kill_pop = 0
	hud.reset_magazine()

func request_run() -> void:
	if state not in ["TITLE","RESULTS","PAUSED"]:return
	load_ticket += 1
	state = "LOADING"
	loading = LoadingTransition.new()
	rules.active = false
	player.enabled = false
	player.velocity = Vector3.ZERO
	if music:music.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.reset_magazine()
	hud.health_shade = 0
	hud.hit = 0
	hud.damage = 0
	hud.kill_pop = 0
	hud.sync_loading_cover()
	prepare_loaded_run.call_deferred(load_ticket)

func loading_frame() -> void:
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw

func prepare_loaded_run(ticket: int) -> void:
	# Show the loading screen before removing/creating any scene nodes.
	await loading_frame()
	if ticket!=load_ticket:return
	opening_prepared = false
	bullets.clear()
	for voice in audio_voices:voice.stop()
	var old_nodes = enemies.get_children()+effects.get_children()
	for i in range(old_nodes.size()):
		var node = old_nodes[i]
		if is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)
			node.queue_free()
		if i%6==5:
			await loading_frame()
			if ticket!=load_ticket:return
	for barrel in arena.barrels:barrel.reset()
	for room in arena.containers:room.reset()
	reset_run_state()
	loading.report(.1)
	await loading_frame()
	if ticket!=load_ticket:return
	# Clicking before navigation has synchronized remains a visible loading wait.
	for attempt in range(600):
		if nav_ready:break
		await loading_frame()
		if ticket!=load_ticket:return
	if not nav_ready:
		cancel_loading()
		push_error("Navigation unavailable; returned to title")
		return
	loading.report(.2)
	var path = "res://assets/models/enemy.glb"
	var error = ResourceLoader.load_threaded_request(path)
	var existing_status = ResourceLoader.load_threaded_get_status(path)
	if error!=OK and existing_status not in [ResourceLoader.THREAD_LOAD_IN_PROGRESS,ResourceLoader.THREAD_LOAD_LOADED]:
		cancel_loading()
		push_error("Unable to prepare enemy model")
		return
	while true:
		var progress: Array = []
		var status = ResourceLoader.load_threaded_get_status(path,progress)
		if not progress.is_empty():loading.report(.2+float(progress[0])*.2)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			enemy_model = ResourceLoader.load_threaded_get(path)
			break
		if status in [ResourceLoader.THREAD_LOAD_FAILED,ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
			cancel_loading()
			push_error("Enemy model loading failed")
			return
		await loading_frame()
		if ticket!=load_ticket:return
	# Instantiate and render one actor per frame, before the countdown, to warm
	# imported meshes/materials without a single eight-enemy creation burst.
	for i in range(OPENING_POSITIONS.size()):
		var actor = spawn_enemy(OPENING_POSITIONS[i],i==1)
		actor.look_at(Vector3(player.position.x,actor.position.y,player.position.z))
		loading.report(.4+float(i+1)/8*.5)
		await loading_frame()
		if ticket!=load_ticket:return
	for i in [0,2]:
		arena.containers[i].add_guard()
		loading.report(.84 if i==0 else .9)
		await loading_frame()
		if ticket!=load_ticket:return
	opening_prepared = true
	# Warm the first shot's effect materials beneath the opaque loading cover.
	var muzzle = player.gun.to_global(Vector3(0,.015,-1.0))
	spark(muzzle,Color("ffe19a"),.1,.035)
	trace(muzzle,muzzle-Vector3(0,0,2),Color("fff1b7"),.025,.045)
	for frame in range(4):
		await loading_frame()
		if ticket!=load_ticket:return
	loading.report(1)
	loading.work_complete = true

func cancel_loading() -> void:
	if state!="LOADING":return
	load_ticket += 1
	state = "TITLE"
	clear_round()
	player.reset_position()
	player.gun.show()
	player.enabled = false
	hud.sync_loading_cover()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if state!="LOADING":return
	loading.advance(delta)
	if loading.phase=="DONE":
		state = "READY"
		ready_time = 3.0
		hud.sync_loading_cover()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func clear_round() -> void:
	opening_prepared = false
	for barrel in arena.barrels:barrel.reset()
	for room in arena.containers:room.reset()
	bullets.clear()
	for node in enemies.get_children():
		enemies.remove_child(node)
		node.queue_free()
	for node in effects.get_children():
		effects.remove_child(node)
		node.queue_free()
	for voice in audio_voices:voice.stop()
	if music:music.stop()

func begin_running() -> void:
	state = "RUNNING"
	music.stream_paused = false
	music.play()
	rules.start()
	player.enabled = true
	# Deliberate opening target set when the countdown ends. Reinforcements use hidden gates.
	if not opening_prepared:
		for p in OPENING_POSITIONS:spawn_enemy(p,p==Vector3(11,0,1))
		# Two existing yard slots start inside the green and purple containers.
		for i in [0,2]:arena.containers[i].add_guard()
	opening_prepared = true
	play_sound("tick",-10)

func finish_run() -> void:
	state = "RESULTS"
	music.stop()
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
	if state=="LOADING" and not qa_mode:
		if what==NOTIFICATION_APPLICATION_FOCUS_OUT:loading.suspended = true
		elif what==NOTIFICATION_APPLICATION_FOCUS_IN:loading.suspended = false
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not qa_mode and state in ["READY","RUNNING"]:
		pause_run()

func pause_run() -> void:
	previous_state = state
	state = "PAUSED"
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state=="LOADING":cancel_loading()
		elif state in ["RUNNING","READY"]:pause_run()
		elif state == "PAUSED":menu_action("resume")
		elif state == "RESULTS":menu_action("menu")
	elif event.is_action_pressed("restart") and state in ["TITLE","RESULTS","PAUSED"]:request_run()
	elif event.is_action_pressed("reload") and state == "RUNNING":reload_weapon()
	elif event is InputEventKey and event.pressed and state == "PAUSED":
		if event.physical_keycode == KEY_MINUS:player.sensitivity = maxf(.0006,player.sensitivity-.0002)
		if event.physical_keycode in [KEY_EQUAL,KEY_PLUS]:player.sensitivity = minf(.006,player.sensitivity+.0002)
		if event.physical_keycode == KEY_M:reduced_motion = not reduced_motion
		save_record()

func menu_action(action: String) -> void:
	match action:
		"play", "retry":
			request_run()
		"resume":
			if state != "PAUSED":return
			state = previous_state
			player.enabled = state == "RUNNING" and respawn_time<=0
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
	if music:music.stream_paused = state == "PAUSED"
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
		respawn_time = maxf(0,respawn_time-delta)
		if respawn_time<.000001:respawn_time = 0
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
			player.gun.show()
			health = MAX_HEALTH
			ammo = MAGAZINE_SIZE
			hud.reset_magazine()
			reload_time = 0
			invulnerable = 1.5
	fire_time = maxf(0,fire_time-delta)
	if reload_time>0:
		reload_time = maxf(0,reload_time-delta)
		if reload_time<.000001:reload_time = 0
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
	enemy.home_zone = arena.enemy_zone(pos)
	enemy.fast = fast and enemy.home_zone=="yard"
	enemy.position = pos+Vector3(0,.05,0)
	enemies.add_child(enemy)
	return enemy

func population_target() -> int:
	return 8 if rules.elapsed<20 else (10 if rules.elapsed<40 else 12)

func zone_population(zone: String) -> int:
	return live_enemies().filter(func(e):return e.home_zone==zone).size()

func zone_capacity(zone: String) -> int:
	return population_target()-4 if zone=="yard" else 2

func spawn_is_clear(point: Vector3) -> bool:
	for enemy in live_enemies():
		var offset = enemy.global_position-point
		if absf(offset.y)<1.8 and Vector2(offset.x,offset.z).length()<1.4:return false
	return true

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
			if p.distance_to(player.position)>8 and spawn_is_clear(p) and (blocked or not visible_now) and live_enemies().size()<population_target() and zone_population(arena.enemy_zone(p))<zone_capacity(arena.enemy_zone(p)):
				var rushers = live_enemies().filter(func(e):return e.fast).size()
				spawn_enemy(p,rules.elapsed>8 and rushers<(2 if rules.elapsed<40 else 3) and rng.randf()<.35)
			pending_spawn.clear()
		return
	spawn_time -= delta
	var target = population_target()
	if spawn_time>0 or live_enemies().size()>=target:return
	spawn_time = .2
	var choices: Array[int] = []
	for i in range(arena.spawn_points.size()):
		var p: Vector3 = arena.spawn_points[i]
		if spawn_cooldowns[i]>0 or p.distance_to(player.position)<8 or not spawn_is_clear(p):continue
		var zone = arena.enemy_zone(p)
		if zone_population(zone)>=zone_capacity(zone):continue
		var path = NavigationServer3D.map_get_path(arena.nav.get_navigation_map(),p,player.position,true)
		if path.size()<2:continue
		var query = PhysicsRayQueryParameters3D.create(player.camera.global_position,p+Vector3(0,1,0),1)
		var occluded = not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
		var screen_point = player.camera.unproject_position(p+Vector3(0,1,0))
		var visible_target = not player.camera.is_position_behind(p) and get_viewport().get_visible_rect().has_point(screen_point)
		if occluded or not visible_target:choices.append(i)
	if choices.is_empty():return
	# Fill missing patrol posts first; reserve their slots even while they are visible.
	var patrol_choices = choices.filter(func(i):return arena.enemy_zone(arena.spawn_points[i])!="yard")
	if not patrol_choices.is_empty():choices.assign(patrol_choices)
	choices.sort_custom(func(a,b):return arena.spawn_points[a].distance_squared_to(player.position)<arena.spawn_points[b].distance_squared_to(player.position))
	var index = choices[rng.randi_range(0,mini(2,choices.size()-1))]
	var pos: Vector3 = arena.spawn_points[index]
	spawn_cooldowns[index] = 1.6
	pending_spawn = {"pos":pos,"delay":.4}
	spark(pos+Vector3(0,.1,0),Color("f2d084"),.25,.4)

func shoot() -> void:
	if state!="RUNNING" or not rules.active or fire_time>0 or reload_time>0 or respawn_time>0:return
	if ammo<=0:
		reload_weapon()
		return
	ammo -= 1
	hud.ammo_fired()
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
		if collider.has_method("ignite"):
			collider.ignite()
			hud.hit = .12
		elif enemy!=null:
			rules.hits += 1
			hud.hit = .12
			play_sound("hit",-14)
			enemy.take_hit(collider is Area3D)
			spark(target,Color("f2d084"),.07,.12)
		else:spark(target,Color("e5e0d2"),.045,.1)
	if ammo==0:reload_weapon()

func reload_weapon() -> void:
	if ammo>=MAGAZINE_SIZE or reload_time>0 or respawn_time>0 or state!="RUNNING":return
	reload_start_ammo = ammo
	reload_time = RELOAD_DURATION
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

func damage_player(amount: float = 34.0) -> void:
	if state!="RUNNING" or not rules.active or respawn_time>0:return
	since_damage = 0
	if invulnerable>0:return
	health = maxf(0,health-amount)
	invulnerable = .65
	since_damage = 0
	hud.damage = .8
	play_sound("hurt",-8)
	if health<=0:
		rules.deaths += 1
		respawn_time = RESPAWN_DELAY
		reload_time = 0
		fire_time = 0
		player.enabled = false
		player.velocity = Vector3.ZERO
		player.gun.hide()

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

func set_music_volume(value: float) -> void:
	music_volume = clampf(value,0,1)
	if music:music.volume_db = linear_to_db(maxf(.0001,music_volume))-8.0

func play_world_sound(key: String, pos: Vector3, volume: float) -> void:
	var voice = AudioStreamPlayer3D.new()
	voice.stream = sounds[key]
	voice.volume_db = volume
	voice.unit_size = 6
	voice.max_distance = 32
	effects.add_child(voice)
	voice.global_position = pos
	voice.finished.connect(voice.queue_free)
	voice.play()

func blast_clear(from: Vector3, to: Vector3, excluded: Array[RID]) -> bool:
	var ray = PhysicsRayQueryParameters3D.create(from,to,1,excluded)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func barrel_blast(center: Vector3, radius: float, source: StaticBody3D) -> void:
	if state!="RUNNING" or not rules.active:return
	play_world_sound("explosion",center,-5)
	for enemy in live_enemies():
		var target = enemy.global_position+Vector3.UP
		var distance = center.distance_to(target)
		if distance<=radius and blast_clear(center,target,[source.get_rid()]):
			enemy.take_damage(3 if distance<=3.2 else (2 if distance<4.2 else 1))
	var player_target = player.global_position+Vector3.UP
	var player_distance = center.distance_to(player_target)
	if player_distance<=radius and blast_clear(center,player_target,[source.get_rid()]):
		damage_player(lerpf(60,15,player_distance/radius))
	for barrel in arena.barrels:
		if barrel==source or barrel.spent:continue
		var target = barrel.global_position+Vector3.UP*.65
		if center.distance_to(target)<=radius and blast_clear(center,target,[source.get_rid(),barrel.get_rid()]):barrel.ignite(.25)
	# Low-poly fire and debris leave the centre readable; no full-screen flash.
	spark(center,Color("fff1b7"),1.2,.25)
	for i in range(8):
		var direction = Vector3(cos(i*TAU/8),.25+float(i%3)*.2,sin(i*TAU/8))
		spark(center+direction*.7,Color("ef7833"),.65,.45)
		trace(center+direction,center+direction*2.2,Color("573e37"),.12,.4)
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = .85
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = effect_material(Color("f6bc62"))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effects.add_child(ring)
	ring.global_position = center-Vector3.UP*.5
	var tween = ring.create_tween()
	tween.tween_property(ring,"scale",Vector3(radius,.15,radius),.35)
	tween.tween_callback(ring.queue_free)
