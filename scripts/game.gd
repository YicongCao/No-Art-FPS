extends Node3D

const TOUCH_LOOK_GAIN = 1.9
const WEB_RENDER_SCALES = [1.0,.85,.70]
const WEB_SHADOW_RANGES = [65.0,45.0,32.0]
const FINALE_FX_CELL_SIZE = 16.0

const DefaultSession = preload("res://data/sessions/score_attack.tres")
const PARK_SESSION_PATH = "res://data/sessions/amusement_park.tres"
const FERRY_SESSION_PATH = "res://data/sessions/last_ferry.tres"
var session = DefaultSession
var opening: Array[Dictionary] = []
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Hud = preload("res://scripts/hud.gd")
const Rules = preload("res://scripts/run_rules.gd")
const LoadingTransition = preload("res://scripts/loading_transition.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
var arena: Node3D
var sun: DirectionalLight3D
var world_environment: WorldEnvironment
var daylight_environment: Environment
var player: CharacterBody3D
var hud: Control
var enemies: Node3D
var effects: Node3D
var rules = DefaultSession.make_rules()
var state = "TITLE"
var previous_state = "RUNNING"
const MAGAZINE_SIZE = 20
const DESTROY_DURATION = 15.0
const ENEMY_BULLET_SPEED = 80.0
const ENEMY_TRAIL_LENGTH = 2.0
const ShotLine = preload("res://scripts/shot_line.gd")
const FlameBolt = preload("res://scripts/flame_bolt.gd")
const COMBAT_MUSIC = preload("res://assets/music/sixty.ogg")
const DESTROY_MUSIC = preload("res://assets/music/destroy.ogg")
const MAX_HEALTH = 150.0
const HEAL_DELAY = 5.0
const HEAL_RATE = 12.0
const RESPAWN_DELAY = 2.3
const RANGED_ATTACK_LIMIT = 3
const SCENERY_TARGET_LAYER = 16
const SCENERY_BLAST_RADIUS = 5.0
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
var ranged_aimers: Dictionary = {}
var player_bullets: Array[Dictionary] = []
var sounds: Dictionary = {}
var audio_voices: Array[AudioStreamPlayer] = []
var web_rifle: AudioStreamPlayer
var audio_index = 0
var spark_mesh = SphereMesh.new()
var trace_mesh = BoxMesh.new()
var blast_ring_mesh = TorusMesh.new()
var effect_materials: Dictionary = {}
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
var destroy_effects_warmed = false
var enemy_model: PackedScene
var title_frame_ready = false
var title_session_id = DefaultSession.session_id
var destroy_active = false
var finale_active = false
var finale_elapsed = 0.0
var collecting_finale_fx = false
var finale_fx_groups: Dictionary[Vector2i,CombatFX] = {}
var frozen_process_modes: Dictionary = {}
var frozen_tweens: Array[Tween] = []
const MULTIKILL_WINDOW = 1.25
var kill_group_start = -99.0
var kill_group_count = 0
var web_capture_wait = 0.0
var touch_mode = false
var touch_body_one_shot = false
var touch_fire = false
var web_ui_state = ""
var web_render_tier = 0
var switching_session = false
var map_switch_progress = 0.0
var dust_unlocked = false
var objective_focus: Node3D
var touch_interact = false
var best_mission = 0.0
const Settlement = preload("res://scripts/modes/rule_settlement.gd")
const PatrolBrain = preload("res://scripts/modes/patrol_brain.gd")

func capture_pointer() -> void:
	if touch_mode:return
	# Browsers resolve pointer-lock asynchronously after the input callback.
	# Freeze gameplay while waiting instead of treating the first unlocked
	# animation frame as a cancellation of the request we just made.
	if OS.has_feature("web"):web_capture_wait = .75
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	if OS.has_feature("web"):
		Engine.max_fps = 60
		get_viewport().msaa_3d = Viewport.MSAA_2X
		touch_mode = bool(JavaScriptBridge.eval("Boolean(window.noArtMobile)"))
	spark_mesh.radial_segments = 6
	spark_mesh.rings = 3
	trace_mesh.size = Vector3.ONE
	blast_ring_mesh.inner_radius = .85
	blast_ring_mesh.outer_radius = 1.0
	blast_ring_mesh.rings = 24
	blast_ring_mesh.ring_segments = 6
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	if touch_mode:get_window().content_scale_size = Vector2i(960,540)
	process_physics_priority = -100
	qa_mode = "--qa" in OS.get_cmdline_user_args()
	rng.seed = 61105
	if "--mission" in OS.get_cmdline_user_args():
		session = load("res://data/sessions/defuse.tres")
		rules = session.make_rules()
	elif "--park" in OS.get_cmdline_user_args():
		session = load(PARK_SESSION_PATH)
		rules = session.make_rules()
	elif "--ferry" in OS.get_cmdline_user_args():
		session = load(FERRY_SESSION_PATH)
		rules = session.make_rules()
	title_session_id = session.session_id
	var settlement = Settlement.new()
	settlement.game = self
	add_child(settlement)
	world_environment = WorldEnvironment.new()
	var settings = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("5b7fc8")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dce8ff")
	settings.ambient_light_energy = .52
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	daylight_environment = settings
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_split_1 = .24
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	arena = session.map_scene.instantiate()
	apply_map_lighting()
	arena.game = self
	add_child(arena)
	arena.bake_navigation()
	opening = arena.opening_actors()
	assert(arena.validate_map(),"Invalid map objectives or patrol markers")
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
	for key in ["shot","hit","kill","headshot","reload","hurt","tick","end","fuse","explosion","charge","cartridge_insert","magazine_latch"]:
		sounds[key] = load("res://assets/audio/"+key+".wav")
	for i in range(12):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		audio_voices.append(voice)
	if OS.has_feature("web"):
		# A dedicated, fixed-stream player keeps rapid gunshots out of the
		# single-threaded stream mixer and avoids swapping Web Audio samples.
		web_rifle = AudioStreamPlayer.new()
		web_rifle.stream = sounds.shot
		web_rifle.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		web_rifle.max_polyphony = 4
		add_child(web_rifle)
	music = AudioStreamPlayer.new()
	music.stream = COMBAT_MUSIC
	add_child(music)
	load_record()
	set_music_volume(music_volume)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	nav_ready = await wait_for_map_navigation()
	if not nav_ready:push_error("Navigation map failed to synchronize or targets are unreachable")
	await capture_opening_frame()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/title.png")
		get_tree().quit()
	if qa_mode:
		var test_path = "res://tests/playtest.gd"
		if "--record-demo" in OS.get_cmdline_user_args():test_path = "res://tests/demo_capture.gd"
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
		if "--routes" in OS.get_cmdline_user_args():test_path = "res://tests/stair_route_check.gd"
		if "--graffiti" in OS.get_cmdline_user_args():test_path = "res://tests/graffiti_check.gd"
		if "--respawn" in OS.get_cmdline_user_args():test_path = "res://tests/respawn_check.gd"
		if "--loading" in OS.get_cmdline_user_args():test_path = "res://tests/loading_check.gd"
		if "--dodge" in OS.get_cmdline_user_args():test_path = "res://tests/dodge_check.gd"
		if "--destroy" in OS.get_cmdline_user_args():test_path = "res://tests/destroy_check.gd"
		if "--multikill" in OS.get_cmdline_user_args():test_path = "res://tests/multikill_check.gd"
		if "--reload-audio" in OS.get_cmdline_user_args():test_path = "res://tests/reload_audio_check.gd"
		if "--finale" in OS.get_cmdline_user_args():test_path = "res://tests/finale_check.gd"
		if "--floor-render" in OS.get_cmdline_user_args():test_path = "res://tests/floor_render_check.gd"
		if "--dust-revision" in OS.get_cmdline_user_args():test_path = "res://tests/dust_revision_check.gd"
		if "--mission-route" in OS.get_cmdline_user_args():test_path = "res://tests/mission_route_check.gd"
		if "--mission-check" in OS.get_cmdline_user_args():test_path = "res://tests/mission_check.gd"
		if "--results-ui" in OS.get_cmdline_user_args():test_path = "res://tests/results_ui_check.gd"
		if "--blast-range" in OS.get_cmdline_user_args():test_path = "res://tests/barrel_range_check.gd"
		if "--barrel-routes" in OS.get_cmdline_user_args():test_path = "res://tools/analysis/barrel_routes.gd"
		if "--awareness" in OS.get_cmdline_user_args():test_path = "res://tests/awareness_check.gd"
		var qa = load(test_path).new()
		qa.game = self
		add_child(qa)

func apply_map_lighting() -> void:
	world_environment.environment = arena.environment_override if arena.environment_override else daylight_environment
	sun.rotation_degrees = arena.sun_rotation_degrees
	sun.light_color = arena.sun_color
	sun.light_energy = arena.sun_energy
	sun.shadow_bias = arena.sun_shadow_bias

func score_record_key() -> String:
	if session.session_id==DefaultSession.session_id:return "score"
	return "score_%s_v%d"%[session.session_id,session.layout_version]

func load_session_record(cfg: ConfigFile) -> void:
	best = int(cfg.get_value(score_record_key(),"best",0))
	best_mission = float(cfg.get_value(mission_record_key(),"fastest",0.0))

func load_record() -> void:
	if qa_mode:return
	var cfg = ConfigFile.new()
	if cfg.load("user://record.cfg") == OK:
		load_session_record(cfg)
		player.sensitivity = clampf(float(cfg.get_value("settings","sensitivity",.0022)),.0006,.006)
		reduced_motion = bool(cfg.get_value("settings","reduced_motion",false))
		music_volume = clampf(float(cfg.get_value("settings","music_volume",.7)),0,1)
		touch_body_one_shot = bool(cfg.get_value("settings","touch_body_one_shot",false))

func spawn_opening_actor(index: int) -> Node3D:
	var actor = spawn_enemy(opening[index].position,opening[index].fast)
	if opening[index].has("patrol"):
		var brain = PatrolBrain.new()
		brain.actor = actor
		brain.route = opening[index].patrol
		actor.patrol_brain = brain
		actor.attack = 1.0
		actor.add_child(brain)
		if brain.route.size()>1:
			var direction = brain.route[1]-brain.route[0]
			actor.rotation.y = atan2(-direction.x,-direction.z)
	else:actor.look_at(Vector3(player.position.x,actor.position.y,player.position.z))
	return actor

func capture_opening_frame() -> void:
	# Render the same frozen starting composition the loader will prepare.
	# Capture before any UI, movement or damage so it is a clean gameplay frame.
	if DisplayServer.get_name()=="headless":
		title_frame_ready = true
		return
	if not switching_session:hud.hide()
	for i in range(opening.size()):spawn_opening_actor(i)
	arena.prepare_rooms()
	opening_prepared = true
	# Submit the two instanced materials before the first DESTROY shot or collapse.
	# The tiny batch is below the starting floor and removed before the title capture.
	if not OS.has_feature("web") and rules.destroy_duration>0 and not destroy_effects_warmed:
		var warmup = CombatFX.new()
		warmup.game = self
		effects.add_child(warmup)
		var at = player.camera.to_global(Vector3(0,-1.85,-4))
		warmup.chunk(at,Vector3.ONE*.04,Color.WHITE,Vector3.ZERO)
		warmup.flame(at,.04,Color.WHITE)
		warmup.bloom(at,.04,Color.WHITE)
		warmup.show_pieces()
		await loading_frame()
		warmup.free()
		destroy_effects_warmed = true
	if switching_session:
		map_switch_progress = .92
		hud.set_title_frame(await capture_map_preview(),title_preview_key())
	else:
		await loading_frame()
		hud.set_title_frame(get_viewport().get_texture().get_image(),title_preview_key())
	title_frame_ready = true
	hud.show()
	if OS.has_feature("web") and not switching_session:
		await RenderingServer.frame_post_draw
		JavaScriptBridge.eval("window.noArtReady && window.noArtReady()")

func capture_map_preview() -> Image:
	# The visible viewport keeps its old title frame while the new camera renders.
	var preview = SubViewport.new()
	preview.size = Vector2i(get_viewport().get_texture().get_size())
	preview.world_3d = get_world_3d()
	preview.msaa_3d = get_viewport().msaa_3d
	add_child(preview)
	var eye = Camera3D.new()
	eye.fov = player.camera.fov
	eye.near = player.camera.near
	eye.far = player.camera.far
	eye.keep_aspect = player.camera.keep_aspect
	preview.add_child(eye)
	eye.global_transform = player.camera.global_transform
	eye.make_current()
	preview.render_target_update_mode = SubViewport.UPDATE_ONCE
	await loading_frame()
	var image = preview.get_texture().get_image()
	preview.queue_free()
	return image

func save_record() -> void:
	if qa_mode:return
	var cfg = ConfigFile.new()
	cfg.load("user://record.cfg")
	if rules.mission:cfg.set_value(mission_record_key(),"fastest",best_mission)
	else:cfg.set_value(score_record_key(),"best",best)
	cfg.set_value("settings","sensitivity",player.sensitivity)
	cfg.set_value("settings","reduced_motion",reduced_motion)
	cfg.set_value("settings","music_volume",music_volume)
	if touch_mode:cfg.set_value("settings","touch_body_one_shot",touch_body_one_shot)
	cfg.save("user://record.cfg")

func start_run() -> void:
	if not nav_ready:return
	load_ticket += 1
	clear_round()
	reset_run_state()
	# Synchronous preparation is used by isolated QA fixtures; player-facing
	# starts always go through request_run() and begin immediately after loading.
	state = "PREPARED"
	if not qa_mode:Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset_run_state() -> void:
	arena.cancel_interaction()
	objective_focus = null
	touch_interact = false
	rng.seed = 61105
	rules.start()
	rules.active = false
	destroy_active = false
	finale_active = false
	hud.destroy_time = 0
	kill_group_count = 0
	kill_group_start = -99
	hud.kill_group = 1
	hud.multi_time = 0
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
	last_tick = int(rules.duration)
	new_record = false
	hud.time_pulse = 0
	hud.go_time = 0
	hud.health_shade = 0
	player.reset_position()
	player.gun.show()
	player.enabled = false
	hud.hit = 0
	hud.damage = 0
	hud.damage_source = null
	hud.kill_pop = 0
	hud.reset_magazine()

func request_run() -> void:
	if switching_session or not title_frame_ready or state not in ["TITLE","RESULTS","PAUSED"]:return
	load_ticket += 1
	restore_frozen_world()
	hud.reset_results_frame()
	state = "LOADING"
	loading = LoadingTransition.new()
	rules.active = false
	player.enabled = false
	player.velocity = Vector3.ZERO
	if music:music.stop()
	# Browser pointer lock must begin inside the actual FIRE/Enter gesture,
	# not later when the asynchronous loading animation finishes.
	if OS.has_feature("web"):capture_pointer()
	else:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.reset_magazine()
	hud.health_shade = 0
	hud.hit = 0
	hud.damage = 0
	hud.damage_source = null
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
	ranged_aimers.clear()
	player_bullets.clear()
	for voice in audio_voices:voice.stop()
	if web_rifle:web_rifle.stop()
	var old_nodes = enemies.get_children()+effects.get_children()
	for i in range(old_nodes.size()):
		var node = old_nodes[i]
		if is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)
			node.queue_free()
		if i%6==5:
			await loading_frame()
			if ticket!=load_ticket:return
	arena.restore_finale_decor()
	arena.reset_objectives()
	for barrel in arena.barrels:barrel.reset()
	for room in arena.containers:room.reset()
	arena.restore_structures()
	reset_run_state()
	loading.report(.1)
	await loading_frame()
	if ticket!=load_ticket:return
	# Clicking before navigation has synchronized remains a visible loading wait.
	for attempt in range(600):
		if nav_ready and not arena.navigation_dirty and not arena.navigation_baking:break
		await loading_frame()
		if ticket!=load_ticket:return
	if not nav_ready:
		cancel_loading()
		push_error("Navigation unavailable; returned to title")
		return
	loading.report(.2)
	var path = "res://assets/models/enemy.glb"
	if OS.has_feature("web"):
		# The opening frame already cached this scene. Single-thread Web builds
		# must not depend on a worker thread to prepare it again.
		enemy_model = load(path)
		if not enemy_model:
			cancel_loading()
			push_error("Enemy model loading failed")
			return
		loading.report(.4)
	else:
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
	# Instantiate and render one actor per frame before gameplay to warm
	# imported meshes/materials without a single eight-enemy creation burst.
	for i in range(opening.size()):
		spawn_opening_actor(i)
		loading.report(.4+float(i+1)/8*.5)
		await loading_frame()
		if ticket!=load_ticket:return
	arena.prepare_rooms()
	loading.report(.9)
	await loading_frame()
	if ticket!=load_ticket:return
	opening_prepared = true
	# Warm the first shot's effect materials beneath the opaque loading cover.
	var muzzle = player.gun.to_global(Vector3(0,.015,-1.0))
	spark(muzzle,Color("ffe19a"),.1,.035)
	trace(muzzle,muzzle-Vector3(0,0,2),Color("fff1b7"),.025,.045)
	var web = OS.has_feature("web")
	var render_samples: Array[float] = []
	for frame in range(4):
		var started = Time.get_ticks_usec()
		await loading_frame()
		if ticket!=load_ticket:return
		if web:render_samples.append((Time.get_ticks_usec()-started)/1000.0)
	if web:
		if apply_web_render_budget(render_samples):
			await loading_frame()
			if ticket!=load_ticket:return
			destroy_effects_warmed = false
		if rules.destroy_duration>0 and not destroy_effects_warmed:
			await warm_web_destroy_effects(ticket)
			if ticket!=load_ticket:return
	loading.report(1)
	loading.work_complete = true

func warm_web_destroy_effects(ticket: int) -> void:
	# Render each material in view while the loading cover is opaque. In
	# WebGL, creating a material alone does not compile its draw variants.
	var eye = player.camera
	var at = eye.to_global(Vector3(0,0,-3))
	for stage in range(3):
		var fx = CombatFX.new()
		fx.game = self
		effects.add_child(fx)
		match stage:
			0:
				var bolt = FlameBolt.new()
				fx.add_child(bolt)
				bolt.set_segment(at-eye.global_basis.x*.3,at+eye.global_basis.x*.3,eye.global_position)
				fx.flame(at+Vector3.UP*.4,.3,Color("ef7833"))
			1:fx.chunk(at,Vector3.ONE*.25,Color("b65745"),Vector3.ZERO)
			2:fx.bloom(at,.35,Color("f2d084"))
		fx.show_pieces()
		await loading_frame()
		if ticket!=load_ticket:return
		fx.queue_free()
	destroy_effects_warmed = true

func apply_web_render_budget(samples: Array[float]) -> bool:
	# Size render targets behind the loading cover. Changing scale or shadow
	# mode in combat can make WebGL reallocate buffers and compile new programs.
	samples.sort()
	var typical = samples[1]
	var tier = 2 if typical>42 else (1 if typical>23 else 0)
	if tier<=web_render_tier:return false
	web_render_tier = tier
	get_viewport().scaling_3d_scale = WEB_RENDER_SCALES[tier]
	sun.directional_shadow_max_distance = WEB_SHADOW_RANGES[tier]
	if tier==2:
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	return true

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
	if OS.has_feature("web") and web_ui_state!=state:
		web_ui_state = state
		JavaScriptBridge.eval("window.noArtState("+JSON.stringify(state)+")")
		if touch_mode:JavaScriptBridge.eval("window.noArtMode("+JSON.stringify("defuse" if rules.mission else "arena")+")")
	if OS.has_feature("web") and state=="CAPTURING":
		if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
			web_capture_wait = 0
			state = previous_state
			player.enabled = state=="RUNNING" and rules.active and respawn_time<=0
		else:
			web_capture_wait = maxf(0,web_capture_wait-delta)
			if web_capture_wait<=0:
				state = previous_state
				pause_run()
		return
	# Escape can release the browser's pointer lock without a Godot key event.
	# Never run down the timer behind an unlocked cursor.
	if OS.has_feature("web") and not touch_mode and state=="RUNNING" and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:pause_run()
	if state!="LOADING":return
	var previous_rounds = loading.rounds
	loading.advance(delta)
	play_magazine_feed_sounds(previous_rounds,loading.rounds,MAGAZINE_SIZE)
	if loading.phase=="DONE":
		begin_running()
		hud.sync_loading_cover()
		if not OS.has_feature("web"):Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not touch_mode and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
			previous_state = "RUNNING"
			state = "CAPTURING"
			player.enabled = false

func clear_round() -> void:
	arena.cancel_interaction()
	objective_focus = null
	arena.reset_objectives()
	restore_frozen_world()
	hud.reset_results_frame()
	finale_active = false
	arena.restore_finale_decor()
	opening_prepared = false
	for barrel in arena.barrels:barrel.reset()
	for room in arena.containers:room.reset()
	arena.restore_structures()
	bullets.clear()
	ranged_aimers.clear()
	player_bullets.clear()
	for node in enemies.get_children():
		enemies.remove_child(node)
		node.queue_free()
	for node in effects.get_children():
		effects.remove_child(node)
		node.queue_free()
	for voice in audio_voices:voice.stop()
	if web_rifle:web_rifle.stop()
	if music:music.stop()

func begin_running() -> void:
	state = "RUNNING"
	music.stream = session.combat_music if session.combat_music else COMBAT_MUSIC
	music.stream_paused = false
	music.play()
	rules.start()
	player.enabled = true
	hud.go_time = hud.GO_DURATION
	# Reuse the opening actors prepared under the loading cover. Isolated QA
	# fixtures can still initialize them here. Reinforcements use hidden gates.
	if not opening_prepared:
		for i in range(opening.size()):spawn_opening_actor(i)
		# Two existing yard slots start inside the green and purple containers.
		arena.prepare_rooms()
	opening_prepared = true
	play_sound("tick",-10)

func finish_run() -> void:
	if rules.mission and rules.outcome=="TIMEOUT" and state!="RESULTS":
		for objective in arena.objectives:
			if not objective.defused:finale_explosion(objective.global_position,1.2,Color("243440"))
		play_sound("explosion",-8)
	state = "RESULTS"
	music.stop()
	rules.active = false
	player.enabled = false
	player.velocity = Vector3.ZERO
	freeze_world()
	if rules.mission:
		new_record = rules.result_value()>0 and (best_mission<=0 or rules.result_value()<best_mission)
		if new_record:best_mission = rules.result_value()
	else:
		new_record = rules.kills > best
		best = maxi(best,rules.kills)
	save_record()
	pending_spawn.clear()
	bullets.clear()
	player_bullets.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_sound("end",-7)
	hud.capture_results_frame()

func freeze_world() -> void:
	# Freeze node callbacks and existing tweens, including dead actors and recoil.
	for root in [arena,player,enemies,effects]:
		for node in [root]+root.find_children("*","",true,false):
			if frozen_process_modes.has(node):continue
			frozen_process_modes[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_DISABLED
	for tween in get_tree().get_processed_tweens():
		if tween.is_running():
			tween.pause()
			frozen_tweens.append(tween)

func restore_frozen_world() -> void:
	for node in frozen_process_modes:
		if is_instance_valid(node):node.process_mode = frozen_process_modes[node]
	frozen_process_modes.clear()
	for tween in frozen_tweens:
		if tween.is_valid():tween.play()
	frozen_tweens.clear()

func start_finale() -> void:
	if finale_active or state!="RUNNING" or rules.active or rules.remaining()>0 or rules.finale_duration<=0:return
	finale_active = true
	finale_elapsed = 0
	music.stop()
	player.enabled = false
	player.velocity = Vector3.ZERO
	pending_spawn.clear()
	hud.time_pulse = 1
	collecting_finale_fx = OS.has_feature("web")
	# Only the round-ending blast awards kills after the combat clock closes.
	for enemy in live_enemies():
		finale_explosion(enemy.global_position+Vector3.UP,1.2,Color("243440"))
		enemy.take_damage(3,false,true)
	for building in arena.structures:
		if not building.scenery:building.collapse()
	for barrel in arena.barrels:barrel.explode()
	arena.explode_finale_decor()
	for fx in finale_fx_groups.values():fx.show_pieces()
	finale_fx_groups.clear()
	collecting_finale_fx = false
	play_sound("explosion",-6)

func finale_explosion(center: Vector3, extent: float, debris_color: Color) -> void:
	# Share draw batches across nearby simultaneous bursts while keeping
	# separate bounds for culling explosions on the other side of the map.
	var cell = Vector2i(floori(center.x/FINALE_FX_CELL_SIZE),floori(center.z/FINALE_FX_CELL_SIZE))
	var fx = finale_fx_groups.get(cell) if collecting_finale_fx else null
	if fx==null:
		fx = CombatFX.new()
		fx.game = self
		fx.duration = 1.65
		effects.add_child(fx)
		if collecting_finale_fx:finale_fx_groups[cell] = fx
	fx.rng.seed = int(center.x*173+center.z*419)+61106
	for i in range(6):
		var direction = Vector3(cos(i*TAU/6),fx.rng.randf_range(.5,1.4),sin(i*TAU/6))
		fx.chunk(center+direction*.2,Vector3.ONE*fx.rng.randf_range(.2,.6),debris_color,direction*extent*1.4)
	for i in range(5):
		var offset = Vector3(cos(i*TAU/5),float(i%2)*.4,sin(i*TAU/5))*extent*.45
		fx.bloom(center+offset,extent*(.7 if i%2==0 else .5),Color("ef7833") if i%2==0 else Color("f2d084"))
	fx.bloom(center+Vector3.UP*extent*.6,extent*.65,Color("573e37"))
	if not collecting_finale_fx:fx.show_pieces()

func _notification(what: int) -> void:
	if state=="LOADING" and not qa_mode:
		if what==NOTIFICATION_APPLICATION_FOCUS_OUT:loading.suspended = true
		elif what==NOTIFICATION_APPLICATION_FOCUS_IN:loading.suspended = false
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not qa_mode and state in ["RUNNING","CAPTURING"]:
		if state=="CAPTURING":state = previous_state
		pause_run()

func pause_run() -> void:
	arena.cancel_interaction()
	touch_interact = false
	previous_state = state
	state = "PAUSED"
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if state=="TITLE" and not dust_unlocked and event is InputEventKey:
		if event.pressed and not event.echo and event.physical_keycode==KEY_9 and event.ctrl_pressed and event.shift_pressed and not event.alt_pressed and not event.meta_pressed:
			dust_unlocked = true
			hud.rebuild_menu()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause"):
		if state=="LOADING":cancel_loading()
		elif state=="RUNNING":pause_run()
		elif state=="CAPTURING":
			state = previous_state
			pause_run()
		elif state == "PAUSED":menu_action("resume")
		elif state == "RESULTS":menu_action("menu")
	elif event.is_action_pressed("restart") and state in ["TITLE","RESULTS","PAUSED"]:
		var focused = get_viewport().gui_get_focus_owner()
		if state=="TITLE" and focused is Button and focused.get_parent()==hud.menu and focused!=hud.fire_button:
			if not focused.disabled:focused.pressed.emit()
			get_viewport().set_input_as_handled()
		else:request_run()
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
		"arena":
			select_session(DefaultSession)
		"amusement_park":
			select_session(PARK_SESSION_PATH)
		"last_ferry":
			select_session(FERRY_SESSION_PATH)
		"defuse":
			if dust_unlocked:
				select_session("res://data/sessions/defuse.tres")
		"resume":
			if state != "PAUSED":return
			state = "CAPTURING" if OS.has_feature("web") and not touch_mode else previous_state
			player.enabled = state == "RUNNING" and rules.active and respawn_time<=0
			capture_pointer()
		"menu":
			if state != "RESULTS":return
			state = "TITLE"
			clear_round()
			player.reset_position()
		"motion":
			if state != "PAUSED":return
			reduced_motion = not reduced_motion
			save_record()
		"touch_body_shots":
			if not touch_mode or state!="PAUSED":return
			touch_body_one_shot = not touch_body_one_shot
			save_record()
		"gyro":
			if touch_mode and state=="PAUSED":JavaScriptBridge.eval("window.noArtOpenGyro()")

func _physics_process(delta: float) -> void:
	if touch_mode:
		var packet = JSON.parse_string(str(JavaScriptBridge.eval("window.noArtReadTouch(%s)" % ("true" if respawn_time<=0 else "false"))))
		if packet is Dictionary:
			player.touch_move = Vector2(float(packet.x),float(packet.y)).limit_length()
			touch_fire = bool(packet.fire)
			touch_interact = bool(packet.get("interact",false))
			if state=="RUNNING":
				if bool(packet.blocked) or bool(packet.pause):
					pause_run()
				elif rules.active:
					var touch_sensitivity = player.sensitivity*TOUCH_LOOK_GAIN
					player.rotate_y(-float(packet.dx)*touch_sensitivity+float(packet.get("gyroYaw",0.0)))
					player.pitch = clampf(player.pitch-float(packet.dy)*touch_sensitivity+float(packet.get("gyroPitch",0.0)),-1.35,1.35)
					player.touch_jump = bool(packet.jump)
					if bool(packet.reload):reload_weapon()
	if music:music.stream_paused = state in ["PAUSED","CAPTURING"]
	if state != "RUNNING":return
	if OS.has_feature("web") and not touch_mode and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:return
	if finale_active:
		finale_elapsed = minf(rules.finale_duration,finale_elapsed+delta)
		if finale_elapsed>=rules.finale_duration-.000001:finish_run()
		return
	rules.tick(delta)
	if not rules.active:
		if rules.finale_duration>0:start_finale()
		else:finish_run()
		return
	if rules.destroy_duration>0 and not destroy_active and rules.remaining()<=rules.destroy_duration+.000001:
		destroy_active = true
		hud.go_time = 0
		hud.destroy_time = 1.7
		music.stream = session.destroy_music if session.destroy_music else DESTROY_MUSIC
		music.play()
		play_sound("end",-12,1.25)
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
			var safest = arena.player_start().origin
			var best_distance = -1.0
			for candidate in arena.respawn_candidates():
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
		var previous_rounds = hud.reload_rounds_fed()
		reload_time = maxf(0,reload_time-delta)
		if reload_time<.000001:reload_time = 0
		var rounds_to_fill = MAGAZINE_SIZE-reload_start_ammo
		var fed = hud.reload_rounds_fed() if reload_time>0 else float(rounds_to_fill)
		play_magazine_feed_sounds(previous_rounds,fed,rounds_to_fill)
		if reload_time<=0:ammo = MAGAZINE_SIZE
	if (touch_fire if touch_mode else Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):shoot()
	update_spawns(delta)
	update_bullets(delta)
	update_player_bullets(delta)
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
	enemy.fast = fast and arena.accepts_fast(enemy.home_zone)
	enemy.position = pos+Vector3(0,.05,0)
	enemies.add_child(enemy)
	return enemy

func population_target() -> int:
	return 8 if rules.elapsed<20 else (10 if rules.elapsed<40 else 12)

func zone_population(zone: String) -> int:
	return live_enemies().filter(func(e):return e.home_zone==zone).size()

func zone_capacity(zone: String) -> int:
	return arena.region_capacity(zone,population_target())

func spawn_is_clear(point: Vector3) -> bool:
	for enemy in live_enemies():
		var offset = enemy.global_position-point
		if absf(offset.y)<1.8 and Vector2(offset.x,offset.z).length()<1.4:return false
	return true

func update_spawns(delta: float) -> void:
	if finale_active or not rules.continuous_spawns:return
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
		if not arena.zone_intact(zone):continue
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
	if objective_focus!=null:return
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
	var aim_point = get_viewport().get_visible_rect().get_center()+player.crosshair_offset
	var endpoint = origin+player.camera.project_ray_normal(aim_point)*90
	var query = PhysicsRayQueryParameters3D.create(origin,endpoint,shot_collision_mask(destroy_active))
	query.collide_with_areas = true
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	var target = result.position if not result.is_empty() else endpoint
	var muzzle = player.gun.to_global(Vector3(0,.015,-1.0))
	# Ray from body to muzzle prevents camera/viewmodel geometry shooting through walls.
	var clearance = PhysicsRayQueryParameters3D.create(origin,muzzle,1)
	var blockage = get_world_3d().direct_space_state.intersect_ray(clearance)
	if blockage.is_empty():
		var muzzle_query = PhysicsRayQueryParameters3D.create(muzzle,target,1|SCENERY_TARGET_LAYER if destroy_active else 1)
		blockage = get_world_3d().direct_space_state.intersect_ray(muzzle_query)
	if not blockage.is_empty() and blockage.position.distance_to(target)>.12:
		target = blockage.position
		result = {}
	var shot_enemy = enemy_from_hit(result)
	if shot_enemy and shot_enemy.fast and origin.distance_to(shot_enemy.global_position)>Enemy.CLOSE_SHOT_RANGE:
		shot_enemy.evade_shot(origin)
		var projectile: Node3D
		var flame: MeshInstance3D
		if destroy_active:
			projectile = Node3D.new()
			flame = FlameBolt.new()
			projectile.add_child(flame)
		else:
			var ordinary = MeshInstance3D.new()
			ordinary.mesh = spark_mesh
			ordinary.scale = Vector3.ONE*.08
			ordinary.material_override = effect_material(Color("fff1b7"))
			projectile = ordinary
		effects.add_child(projectile)
		projectile.global_position = origin
		player_bullets.append({"node":projectile,"flame":flame,"velocity":origin.direction_to(target)*65,"life":1.4,"origin":origin,"burning":destroy_active})
	else:
		if destroy_active:
			var flame = FlameBolt.new()
			effects.add_child(flame)
			flame.fly(muzzle,target,player.camera)
		else:trace(muzzle,target,Color("fff1b7"),.025,.045)
		resolve_shot(result,origin,target,destroy_active)
	spark(muzzle,Color("ffe19a"),.1,.035)
	if destroy_active:fire_effect(muzzle,.13)
	if ammo==0:reload_weapon()

func enemy_from_hit(result: Dictionary) -> Node3D:
	if result.is_empty():return null
	var collider = result.collider
	if collider is Area3D:
		return collider.get_meta("enemy") if collider.has_meta("enemy") else null
	return collider if collider.has_method("take_hit") else null

func shot_collision_mask(burning: bool) -> int:
	return 1|4|8|SCENERY_TARGET_LAYER if burning else 1|4|8

func resolve_shot(result: Dictionary, origin: Vector3, target: Vector3, burning: bool = false) -> void:
	if state!="RUNNING" or not rules.active:return
	if not result.is_empty():
		var collider = result.collider
		var enemy = enemy_from_hit(result)
		if burning:
			var building = collider.get_meta("structure") if collider.has_meta("structure") else null
			if building:building.ignite_hit(target)
			else:fire_effect(target,.3)
		if enemy==null and collider.has_method("ignite"):
			collider.shot_hit(burning)
			hud.hit = .12
		elif enemy!=null:
			if not burning and enemy.fast and origin.distance_to(enemy.global_position)>Enemy.CLOSE_SHOT_RANGE:
				enemy.evade_shot(origin)
				spark(target,Color("fff1b7"),.11,.1)
				return
			rules.hits += 1
			hud.hit = .12
			play_sound("hit",-14)
			var is_head = collider is Area3D
			enemy.take_hit(is_head,burning or (touch_mode and touch_body_one_shot))
			if is_head:spark(target,Color("f2d084"),.07,.12)
			else:spark(target,Color("ed9957"),.12,.16)
		else:spark(target,Color("e5e0d2"),.045,.1)

func update_player_bullets(delta: float) -> void:
	for i in range(player_bullets.size()-1,-1,-1):
		var b = player_bullets[i]
		if not is_instance_valid(b.node):
			player_bullets.remove_at(i)
			continue
		var from: Vector3 = b.node.global_position
		var to: Vector3 = from+b.velocity*delta
		var query = PhysicsRayQueryParameters3D.create(from,to,shot_collision_mask(b.burning))
		query.collide_with_areas = true
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		b.life -= delta
		if not hit.is_empty() or b.life<=0:
			resolve_shot(hit,b.origin,hit.position if not hit.is_empty() else to,b.burning)
			b.node.queue_free()
			player_bullets.remove_at(i)
		else:
			b.node.global_position = to
			if b.flame:
				var length = minf(b.origin.distance_to(to),FlameBolt.LENGTH)
				b.flame.set_segment(to-b.velocity.normalized()*length,to,player.camera.global_position)

func reload_weapon() -> void:
	if objective_focus!=null:return
	if ammo>=MAGAZINE_SIZE or reload_time>0 or respawn_time>0 or state!="RUNNING" or not rules.active:return
	reload_start_ammo = ammo
	reload_time = RELOAD_DURATION
	play_sound("reload",-8)

func play_magazine_feed_sounds(previous: float, current: float, full_count: int) -> void:
	for _i in range(int(previous),int(current)):
		play_sound("cartridge_insert",-12)
	if previous<full_count and current>=full_count:
		play_sound("magazine_latch",-9)

func on_kill(enemy: Node3D, headshot: bool, from_finale: bool = false) -> void:
	if rules.record_kill(enemy.get_instance_id(),headshot,from_finale):
		if rules.elapsed-kill_group_start>MULTIKILL_WINDOW:
			kill_group_start = rules.elapsed
			kill_group_count = 0
		kill_group_count += 1
		hud.kill_group = kill_group_count
		hud.kill_pop = .5
		hud.multi_time = .65 if kill_group_count>=2 else 0.0
		play_sound("headshot" if headshot else "kill",-7,minf(1.25,1+(kill_group_count-1)*.08))

func reserve_ranged_aim(enemy: Node3D) -> bool:
	if ranged_aimers.size()+bullets.size()>=RANGED_ATTACK_LIMIT:return false
	ranged_aimers[enemy] = true
	return true

func enemy_shoot(origin: Vector3, target: Vector3) -> void:
	if state!="RUNNING" or not rules.active or respawn_time>0:return
	var trail = ShotLine.new()
	trail.name = "EnemyTracer"
	effects.add_child(trail)
	trail.material_override.albedo_color = Color("ffcf3bee")
	bullets.append({"node":trail,"origin":origin,"position":origin,"direction":origin.direction_to(target),"life":.8})

func update_bullets(delta: float) -> void:
	if state!="RUNNING" or not rules.active:return
	for i in range(bullets.size()-1,-1,-1):
		var b = bullets[i]
		if not is_instance_valid(b.node):
			bullets.remove_at(i)
			continue
		var from: Vector3 = b.position
		var to: Vector3 = from+b.direction*ENEMY_BULLET_SPEED*minf(delta,b.life)
		var query = PhysicsRayQueryParameters3D.create(from,to,1|2)
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		var end: Vector3 = hit.position if not hit.is_empty() else to
		var length: float = minf(end.distance_to(b.origin),ENEMY_TRAIL_LENGTH)
		b.node.set_segment(end-b.direction*length,end,.045)
		b.life -= delta
		if not hit.is_empty() or b.life<=0:
			if not hit.is_empty() and hit.collider==player:damage_player(34,b.origin)
			var fade = b.node.create_tween()
			fade.tween_property(b.node.material_override,"albedo_color:a",0.0,.075)
			fade.tween_callback(b.node.queue_free)
			bullets.remove_at(i)
		else:b.position = to

func damage_player(amount: float = 34.0, source: Variant = null) -> void:
	if state!="RUNNING" or not rules.active or respawn_time>0:return
	since_damage = 0
	if invulnerable>0:return
	health = maxf(0,health-amount)
	invulnerable = .65
	since_damage = 0
	hud.damage = .8
	hud.damage_source = source
	play_sound("hurt",-8)
	if objective_focus:objective_focus.cancel()
	if health<=0:
		rules.deaths += 1
		rules.report_death()
		respawn_time = RESPAWN_DELAY if rules.respawn_allowed else 0
		reload_time = 0
		fire_time = 0
		player.enabled = false
		player.velocity = Vector3.ZERO
		player.gun.hide()

func effect_material(color: Color) -> StandardMaterial3D:
	if effect_materials.has(color):return effect_materials[color]
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	effect_materials[color] = material
	return material

func fire_effect(at: Vector3, extent: float) -> void:
	# Bound active flame nodes, including continuous automatic fire.
	if effects.get_children().filter(func(n):return n is CombatFX).size()>=18:return
	var fx = CombatFX.new()
	fx.game = self
	fx.duration = .32
	effects.add_child(fx)
	fx.flame(at,extent,Color("ef7833"))
	fx.flame(at+Vector3.UP*extent*.25,extent*.55,Color("fff1b7"))
	fx.show_pieces()

func collapse_effect(bounds: AABB, color: Color) -> void:
	var fx = CombatFX.new()
	fx.game = self
	fx.duration = 1.8
	fx.rng.seed = int(bounds.position.x*31+bounds.position.z*67)
	effects.add_child(fx)
	var center = bounds.get_center()
	if not finale_active:play_world_sound("explosion",center,-7)
	var debris_count = effects.get_children().filter(func(n):return n is CombatFX and n.duration>1).size()
	var count = 32 if debris_count<4 else 12
	for i in range(count):
		var point = bounds.position+Vector3(fx.rng.randf()*bounds.size.x,fx.rng.randf()*bounds.size.y,fx.rng.randf()*bounds.size.z)
		var outward = point-center
		outward.y = 0
		var extent = Vector3(fx.rng.randf_range(.3,1.1),fx.rng.randf_range(.25,.65),fx.rng.randf_range(.3,1.1))
		fx.chunk(point,extent,color.lerp(Color("e5e0d2"),float(i%3)*.15),outward.normalized()*fx.rng.randf_range(1,3)+Vector3.UP*fx.rng.randf_range(1,4))
	for i in range(7):
		var point = center+Vector3(cos(i*TAU/7)*bounds.size.x*.25,-bounds.size.y*.25,sin(i*TAU/7)*bounds.size.z*.25)
		fx.flame(point,1.5,Color("ef7833"))
		fx.flame(point+Vector3.UP*.4,.85,Color("ffe78e"))
	fx.show_pieces()
	if finale_active:finale_explosion(center,clampf(bounds.size.length()*.12,1.8,4),color)

func spark(pos: Vector3, color: Color, radius: float, duration: float) -> void:
	var node = MeshInstance3D.new()
	node.mesh = spark_mesh
	node.scale = Vector3.ONE*radius*2
	node.material_override = effect_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effects.add_child(node)
	node.global_position = pos
	var tween = node.create_tween()
	tween.tween_property(node,"scale",node.scale*.05,duration)
	tween.tween_callback(node.queue_free)

func trace(from: Vector3, to: Vector3, color: Color, width: float, duration: float) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = trace_mesh
	node.material_override = effect_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effects.add_child(node)
	node.global_position = (from+to)*.5
	if from.distance_to(to)>.01:node.look_at(to,Vector3.UP)
	node.scale = Vector3(width,width,maxf(.01,from.distance_to(to)))
	var tween = node.create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(node.queue_free)
	return node

func play_sound(key: String, volume: float = -10, pitch: float = 1) -> void:
	var voice = web_rifle if key=="shot" and web_rifle else audio_voices[audio_index%audio_voices.size()]
	audio_index += 1
	if voice!=web_rifle:voice.stream = sounds[key]
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

func blast_damage_enemies(center: Vector3, radius: float, excluded: Array[RID]) -> void:
	for enemy in live_enemies():
		var target = enemy.global_position+Vector3.UP
		var distance = center.distance_to(target)
		if distance<=radius and blast_clear(center,target,excluded):
			enemy.take_damage(Enemy.MAX_HEALTH if distance<=radius*.64 else (2 if distance<radius*.84 else 1))

func scenery_blast(center: Vector3, excluded: Array[RID]) -> void:
	if state!="RUNNING" or not rules.active or not destroy_active:return
	blast_damage_enemies(center,SCENERY_BLAST_RADIUS,excluded)
	blast_ring(center,SCENERY_BLAST_RADIUS)

func barrel_blast(center: Vector3, radius: float, source: StaticBody3D) -> void:
	if state!="RUNNING":return
	if finale_active:
		finale_explosion(center,1.5,Color("b65745"))
		return
	if not rules.active:return
	play_world_sound("explosion",center,-5)
	blast_damage_enemies(center,radius,[source.get_rid()])
	var player_target = player.global_position+Vector3.UP
	var player_distance = center.distance_to(player_target)
	if player_distance<=radius and blast_clear(center,player_target,[source.get_rid()]):
		damage_player(lerpf(60,15,player_distance/radius),center)
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
	blast_ring(center,radius)

func blast_ring(center: Vector3, radius: float) -> void:
	var ring = MeshInstance3D.new()
	ring.mesh = blast_ring_mesh
	ring.material_override = effect_material(Color("f6bc62"))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effects.add_child(ring)
	ring.global_position = center-Vector3.UP*.5
	var tween = ring.create_tween()
	tween.tween_property(ring,"scale",Vector3(radius,.15,radius),.35)
	tween.tween_callback(ring.queue_free)

func interact_held() -> bool:
	return touch_interact if touch_mode else Input.is_action_pressed("interact")

func settle_rules() -> void:
	if state!="RUNNING" or not rules.active:return
	rules.settle()
	if objective_focus and rules.completed.has(objective_focus.objective_id):objective_focus.mark_defused()
	if not rules.active:finish_run()

func title_preview_key() -> String:
	var path: String = session.resource_path
	if path in [DefaultSession.resource_path,PARK_SESSION_PATH,FERRY_SESSION_PATH]:return path
	return ""

func select_session(selection: Variant) -> void:
	if state!="TITLE" or switching_session or not selection:return
	if selection is Resource:
		if selection==session:return
	elif selection==session.resource_path:return
	switching_session = true
	map_switch_progress = .08
	var previous_frame_ready = title_frame_ready
	title_frame_ready = false
	load_ticket += 1
	var old_map = arena
	var old_session = session
	var old_rules = rules
	var focused = get_viewport().gui_get_focus_owner()
	var focus_name: StringName = focused.name if focused and focused.get_parent()==hud.menu else &""
	hud.rebuild_menu()
	await loading_frame()
	var resource: Resource = selection if selection is Resource else load(selection)
	if not resource:
		title_frame_ready = previous_frame_ready
		finish_session_switch(focus_name)
		return
	map_switch_progress = .35
	await loading_frame()
	var next_map = resource.map_scene.instantiate()
	map_switch_progress = .55
	await loading_frame()
	clear_round()
	var navigation_map = get_world_3d().navigation_map
	var old_iteration = NavigationServer3D.map_get_iteration_id(navigation_map)
	remove_child(old_map)
	session = resource
	rules = session.make_rules()
	nav_ready = false
	arena = next_map
	apply_map_lighting()
	arena.game = self
	add_child(arena)
	arena.bake_navigation()
	opening = arena.opening_actors()
	player.reset_position()
	player.enabled = false
	map_switch_progress = .72
	if arena.validate_map():nav_ready = await wait_for_map_navigation(old_iteration)
	if nav_ready:
		old_map.queue_free()
		var cfg = ConfigFile.new()
		if not qa_mode:cfg.load("user://record.cfg")
		load_session_record(cfg)
		map_switch_progress = .84
		if hud.reuse_title_frame(title_preview_key()):
			title_frame_ready = true
		else:
			await loading_frame()
			await capture_opening_frame()
		title_session_id = session.session_id
	else:
		push_warning("Map selection reverted: navigation or spawn validation failed")
		var failed_iteration = NavigationServer3D.map_get_iteration_id(navigation_map)
		remove_child(arena)
		arena.queue_free()
		arena = old_map
		session = old_session
		rules = old_rules
		add_child(arena)
		apply_map_lighting()
		opening = arena.opening_actors()
		player.reset_position()
		nav_ready = await wait_for_map_navigation(failed_iteration)
		title_frame_ready = nav_ready
	finish_session_switch(focus_name)

func finish_session_switch(focus_name: StringName) -> void:
	switching_session = false
	map_switch_progress = 0.0
	hud.rebuild_menu()
	if focus_name!=&"":
		var button = hud.menu.get_node_or_null(NodePath(String(focus_name)))
		if button:button.grab_focus()

func wait_for_map_navigation(previous_iteration: int = 0) -> bool:
	var map = get_world_3d().navigation_map
	var start = arena.player_start().origin
	for _frame in range(300):
		await get_tree().physics_frame
		var iteration = NavigationServer3D.map_get_iteration_id(map)
		if iteration==0 or iteration==previous_iteration:continue
		if NavigationServer3D.map_get_closest_point_owner(map,start)!=arena.nav.get_rid():continue
		if NavigationServer3D.map_get_closest_point(map,start).distance_to(start)<1.0:
			return arena.validate_navigation()
	return false

func mission_record_key() -> String:
	return session.session_id+"_v"+str(session.layout_version)+"_"+str(int(rules.duration))
