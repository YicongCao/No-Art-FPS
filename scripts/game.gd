extends Node3D

const TOUCH_LOOK_GAIN = 1.9
const WEB_RENDER_SCALES = [1.0,.85,.70]
const WEB_SHADOW_RANGES = [65.0,45.0,32.0]
const FINALE_FX_CELL_SIZE = 16.0

const DefaultSession = preload("res://data/sessions/score_attack.tres")
const PARK_SESSION_PATH = "res://data/sessions/amusement_park.tres"
const FERRY_SESSION_PATH = "res://data/sessions/last_ferry.tres"
const STUDIO_SESSION_PATH = "res://data/sessions/night_studio.tres"
const SANDGATE_SESSION_PATH = "res://data/sessions/sandgate.tres"
var session = DefaultSession
var opening: Array[Dictionary] = []
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Hud = preload("res://scripts/hud.gd")
const Rules = preload("res://scripts/run_rules.gd")
const LoadingTransition = preload("res://scripts/loading_transition.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
const ComedyFX = preload("res://scripts/comedy_fx.gd")
const ComedyToilet = preload("res://scripts/comedy_toilet.gd")
const Grenade = preload("res://scripts/grenade.gd")
const GRENADE_COUNT = 3
const GRENADE_WINDUP = .25
const GRENADE_RELEASE = .12
const GRENADE_INTERVAL = .75
const GRENADE_OUTER_RADIUS = 7.5
const GRENADE_LETHAL_RADIUS = 4.2
const TOILET_BLAST_RADIUS = 10.0
const AchievementProgress = preload("res://scripts/achievements.gd")
var achievements = AchievementProgress.new()
var progress_save_pending = false
var arena: Node3D
var sun: DirectionalLight3D
var world_environment: WorldEnvironment
var daylight_environment: Environment
var destroy_yard_environment: Environment
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
const RESPAWN_DELAY = 2.0
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
var comedy_mode = ""
var comedy_toilet: Node3D
var toilet_blast_active = false
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
var grenades: Array[CharacterBody3D] = []
var grenade_stock = 0
var grenade_throw_time = 0.0
var grenade_cooldown = 0.0
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
	# Single-line UI strings don't need the exporter's ICU line-breaking data.
	TranslationServer.add_translation(preload("res://data/ui_text.zh.translation"))
	TranslationServer.set_locale(initial_language())
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
	elif "--studio" in OS.get_cmdline_user_args():
		session = load(STUDIO_SESSION_PATH)
		rules = session.make_rules()
	elif "--sandgate" in OS.get_cmdline_user_args():
		session = load(SANDGATE_SESSION_PATH)
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
	destroy_yard_environment = settings.duplicate()
	destroy_yard_environment.background_color = Color("e88c49")
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
	achievements.unlocked.connect(hud.queue_badge_toast)
	achievements.changed.connect(queue_progress_save)
	for key in ["shot","hit","kill","headshot","reload","hurt","tick","end","fuse","explosion","charge","cartridge_insert","magazine_latch","comedy_plop","roach_buzz","water_shot","slipper_shot","roach_grenade","enemy_raise"]:
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

func set_destroy_active(active: bool) -> void:
	if destroy_active==active:return
	destroy_active = active
	arena.set_destroy_lighting(active)
	if arena.map_id=="yard":
		world_environment.environment = destroy_yard_environment if active else daylight_environment
		if OS.has_feature("web"):
			var sky = "#"+destroy_yard_environment.background_color.to_html(false) if active else ""
			JavaScriptBridge.eval("window.noArtSetDestroySky?.("+JSON.stringify(sky)+")")

func score_record_key() -> String:
	if session.session_id==DefaultSession.session_id:return "score"
	return "score_%s_v%d"%[session.session_id,session.layout_version]

func map_best_score(map_id: String) -> int:
	if map_id==DefaultSession.session_id:return achievements.scores.get("score",0)
	var prefix = "score_%s_v"%map_id
	var record = 0
	for key in achievements.scores:
		if key.begins_with(prefix) and key.substr(prefix.length()).is_valid_int():
			record = maxi(record,achievements.scores[key])
	return record

func load_session_record(cfg: ConfigFile) -> void:
	var key = score_record_key()
	achievements.merge_score(key,cfg.get_value(key,"best",0))
	best = achievements.scores.get(key,0)
	best_mission = float(cfg.get_value(mission_record_key(),"fastest",0.0))

static func system_language(locale: String) -> String:
	var parts = locale.replace("-", "_").to_lower().get_slice(".",0).get_slice("@",0).split("_",false)
	for i in range(1,parts.size()):
		if parts[i].length()==2:return "zh" if parts[i] in ["cn","hk","mo"] else "en"
	return "zh" if parts.is_empty() or parts[0] in ["zh","c","posix","und"] else "en"

func desktop_locale() -> String:
	var output: Array = []
	if OS.has_feature("macos"):
		if OS.execute("/usr/bin/defaults",["read","-g","AppleLocale"],output)==0:
			return str(output[0]).strip_edges()
	elif OS.has_feature("windows"):
		if OS.execute("reg.exe",["query","HKCU\\Control Panel\\International","/v","LocaleName"],output)==0:
			var locale = str(output[0]).get_slice("REG_SZ",1).strip_edges()
			if not locale.is_empty():return locale
	elif OS.has_feature("linux"):
		for variable in ["LC_ALL","LC_TIME","LANG"]:
			var locale = OS.get_environment(variable)
			if not locale.is_empty():return locale
	return OS.get_locale()

func initial_language() -> String:
	if OS.has_feature("web"):
		return "en" if JavaScriptBridge.eval("window.noArtLanguage?.()")=="en" else "zh"
	var cfg = ConfigFile.new()
	if not qa_mode and cfg.load("user://record.cfg")==OK:
		var saved = cfg.get_value("settings","language","")
		if saved in ["zh","en"]:return saved
	return system_language(desktop_locale())

func switch_language() -> void:
	var language = "en" if TranslationServer.get_locale()=="zh" else "zh"
	TranslationServer.set_locale(language)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.noArtSetLanguage?.(%s)"%JSON.stringify(language))
		sync_grenade_stock()
	elif not qa_mode:
		var cfg = ConfigFile.new()
		cfg.load("user://record.cfg")
		cfg.set_value("settings","language",language)
		cfg.save("user://record.cfg")
	hud.menu_state = ""

func load_record() -> void:
	if qa_mode:return
	var cfg = ConfigFile.new()
	var has_legacy = cfg.load("user://record.cfg")==OK
	if has_legacy:
		for key in cfg.get_sections():
			if key=="score" or key.begins_with("score_"):achievements.merge_score(key,cfg.get_value(key,"best",0))
		achievements.merge({"achievements":cfg.get_value("achievements","progress",{})})
		player.sensitivity = clampf(float(cfg.get_value("settings","sensitivity",.0022)),.0006,.006)
		reduced_motion = bool(cfg.get_value("settings","reduced_motion",false))
		music_volume = clampf(float(cfg.get_value("settings","music_volume",.7)),0,1)
		touch_body_one_shot = bool(cfg.get_value("settings","touch_body_one_shot",false))
	if OS.has_feature("web"):
		achievements.merge(JSON.parse_string(str(JavaScriptBridge.eval("window.noArtReadProgress?.()"))))
		if not achievements.counts.is_empty() or not achievements.scores.is_empty():queue_progress_save()
	load_session_record(cfg)

func queue_progress_save() -> void:
	if qa_mode or progress_save_pending:return
	progress_save_pending = true
	flush_progress.call_deferred()

func flush_progress() -> void:
	progress_save_pending = false
	if qa_mode:return
	if OS.has_feature("web"):
		var json = JSON.stringify(achievements.snapshot())
		var raw: Variant = JavaScriptBridge.eval("window.noArtWriteProgress?.(%s)"%json)
		var stored = JSON.parse_string(raw) if raw is String and not raw.is_empty() else null
		if stored is Dictionary:
			achievements.merge(stored)
			best = maxi(best,achievements.scores.get(score_record_key(),0))
			return
	var cfg = ConfigFile.new()
	cfg.load("user://record.cfg")
	cfg.set_value("achievements","progress",achievements.counts)
	cfg.save("user://record.cfg")

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
	var key = score_record_key()
	if not rules.mission and best>achievements.scores.get(key,0):
		achievements.merge_score(key,best)
		if OS.has_feature("web"):queue_progress_save()
	if qa_mode:return
	var cfg = ConfigFile.new()
	cfg.load("user://record.cfg")
	if rules.mission:cfg.set_value(mission_record_key(),"fastest",best_mission)
	else:
		cfg.set_value(key,"best",maxi(best,int(cfg.get_value(key,"best",0))))
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
	grenade_stock = 0 if rules.mission else GRENADE_COUNT
	grenade_throw_time = 0
	grenade_cooldown = 0
	sync_grenade_stock()
	arena.cancel_interaction()
	objective_focus = null
	touch_interact = false
	rng.seed = 61105
	rules.start()
	rules.active = false
	achievements.start_round()
	hud.reset_badge_toasts()
	set_destroy_active(false)
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
	player.set_weapon_style(comedy_mode)
	prepare_comedy_toilet()
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
	clear_grenades()
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
	var muzzle = player.weapon_muzzle()
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
	player.set_weapon_style("")
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
	set_destroy_active(false)
	clear_grenades()
	arena.cancel_interaction()
	objective_focus = null
	arena.reset_objectives()
	restore_frozen_world()
	remove_comedy_toilet()
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

func remove_comedy_toilet() -> void:
	if not is_instance_valid(comedy_toilet):return
	comedy_toilet.get_parent().remove_child(comedy_toilet)
	comedy_toilet.queue_free()
	comedy_toilet = null

func prepare_comedy_toilet() -> void:
	remove_comedy_toilet()
	if comedy_mode.is_empty() or not ComedyToilet.PLACEMENTS.has(arena.map_id):return
	var site: Vector4 = ComedyToilet.PLACEMENTS[arena.map_id]
	comedy_toilet = ComedyToilet.new()
	comedy_toilet.name = "ComedyToilet"
	comedy_toilet.game = self
	comedy_toilet.position = Vector3(site.x,site.y,site.z)
	comedy_toilet.rotation.y = site.w
	arena.add_child(comedy_toilet)

func begin_running() -> void:
	state = "RUNNING"
	if web_rifle:web_rifle.stream = sounds[shot_sound_key()]
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
	if not comedy_mode.is_empty():
		for actor in enemies.get_children():actor.set_comedy_head(comedy_mode)
	play_sound("tick",-10)

func finish_run() -> void:
	clear_grenades()
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
		achievements.finish_round(rules.elapsed>=rules.duration,rules.deaths)
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
	clear_grenades()
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
	if is_instance_valid(comedy_toilet):comedy_toilet.explode(true)
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
			select_session(PARK_SESSION_PATH,action)
		"last_ferry":
			select_session(FERRY_SESSION_PATH,action)
		"night_studio":
			select_session(STUDIO_SESSION_PATH,action)
		"sandgate":
			select_session(SANDGATE_SESSION_PATH,action)
		"comedy", "roach":
			if state!="TITLE":return
			comedy_mode = "" if comedy_mode==action else action
			hud.sync_comedy_buttons()
		"defuse":
			if dust_unlocked:
				select_session("res://data/sessions/defuse.tres","defuse_mission")
		"resume":
			if state != "PAUSED":return
			state = "CAPTURING" if OS.has_feature("web") and not touch_mode else previous_state
			player.enabled = state == "RUNNING" and rules.active and respawn_time<=0
			capture_pointer()
		"menu":
			if state not in ["RESULTS","PAUSED"]:return
			rules.active = false
			state = "TITLE"
			clear_round()
			player.set_weapon_style("")
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
		"language":
			if state=="PAUSED":switch_language()

func _physics_process(delta: float) -> void:
	var grenade_pressed = not touch_mode and Input.is_action_just_pressed("grenade")
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
					grenade_pressed = bool(packet.get("grenade",false))
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
		set_destroy_active(true)
		hud.go_time = 0
		hud.destroy_time = hud.DESTROY_NOTICE_DURATION
		music.stream = session.destroy_music if session.destroy_music else DESTROY_MUSIC
		music.play()
	update_grenades(delta)
	if grenade_pressed:request_grenade()
	invulnerable = maxf(0,invulnerable-delta)
	since_damage += delta
	if health<MAX_HEALTH and since_damage>=HEAL_DELAY and respawn_time<=0:
		health = minf(MAX_HEALTH,health+HEAL_RATE*delta)
	if respawn_time>0:
		respawn_time = maxf(0,respawn_time-delta)
		if respawn_time<.000001:respawn_time = 0
		if respawn_time<=0:
			player.teleport_to(arena.respawn_pose(player,live_enemies()))
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
			var zone = arena.enemy_zone(p)
			# The player can move or destroy cover during the warning.
			if p.distance_to(player.position)>8 and spawn_is_clear(p) and spawn_has_cover(p) and arena.zone_intact(zone) and live_enemies().size()<population_target() and zone_population(zone)<zone_capacity(zone):
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
		if not spawn_has_cover(p):continue
		var path = NavigationServer3D.map_get_path(arena.nav.get_navigation_map(),p,player.position,true)
		if path.size()<2 or path[-1].distance_to(player.position)>1.5:continue
		choices.append(i)
	if choices.is_empty():return
	# Fill missing patrol posts first; reserve their slots even while they are visible.
	var patrol_choices = choices.filter(func(i):return arena.enemy_zone(arena.spawn_points[i])!="yard")
	if not patrol_choices.is_empty():choices.assign(patrol_choices)
	var approach_choices = choices.filter(func(i):return arena.prefers_reinforcement(arena.spawn_points[i],player))
	if not approach_choices.is_empty():choices.assign(approach_choices)
	choices.sort_custom(func(a,b):return arena.spawn_points[a].distance_squared_to(player.position)<arena.spawn_points[b].distance_squared_to(player.position))
	var index = choices[rng.randi_range(0,mini(2,choices.size()-1))]
	var pos: Vector3 = arena.spawn_points[index]
	spawn_cooldowns[index] = 1.6
	pending_spawn = {"pos":pos,"delay":.4}
	spark(pos+Vector3(0,.1,0),Color("f2d084"),.25,.4)

func spawn_has_cover(point: Vector3) -> bool:
	var eye: Vector3 = player.camera.global_position
	return not blast_clear(eye,point+Vector3.UP*1.12,[]) and not blast_clear(eye,point+Vector3.UP*1.7,[])

func shoot() -> void:
	if objective_focus!=null:return
	if state!="RUNNING" or not rules.active or fire_time>0 or reload_time>0 or respawn_time>0 or grenade_throw_time>0:return
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
	var muzzle = player.weapon_muzzle()
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
	var toy = not comedy_mode.is_empty()
	var water = comedy_mode=="comedy"
	if shot_enemy and shot_enemy.fast and origin.distance_to(shot_enemy.global_position)>Enemy.CLOSE_SHOT_RANGE:
		shot_enemy.evade_shot(origin)
		var projectile: Node3D
		var flame: MeshInstance3D
		if destroy_active or toy:
			projectile = Node3D.new()
			if destroy_active:
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
		var toy_round: Node3D
		if toy:
			toy_round = ComedyFX.projectile(comedy_mode,origin.direction_to(target))
			projectile.add_child(toy_round)
			toy_round.global_position = muzzle
		player_bullets.append({"node":projectile,"flame":flame,"toy_round":toy_round,"velocity":origin.direction_to(target)*65,"life":1.4,"origin":origin,"muzzle":muzzle,"burning":destroy_active})
	else:
		if destroy_active:
			var flame = FlameBolt.new()
			effects.add_child(flame)
			flame.fly(muzzle,target,player.camera)
		elif water:trace(muzzle,target,ComedyFX.WATER,.045,.075)
		elif not toy:trace(muzzle,target,Color("fff1b7"),.025,.045)
		if toy:ComedyFX.fly(effects,comedy_mode,muzzle,target)
		resolve_shot(result,origin,target,destroy_active)
	spark(muzzle,ComedyFX.WATER if water and not destroy_active else Color("ffe19a"),.1,.035)
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
		if collider.has_meta("comedy_toilet"):
			var fixture = collider.get_meta("comedy_toilet")
			if fixture.shot_hit(collider.get_meta("charge",false),burning):hud.hit = .12
			spark(target,Color("ef7833") if burning else Color("e5e0d2"),.08,.1)
			return
		var enemy = enemy_from_hit(result)
		var building = collider.get_meta("structure",null) if collider.has_meta("structure") else null
		var barrel = enemy==null and collider.has_method("ignite")
		if building and building.paper:
			paper_impact(target,result.normal,building.world_bounds().position.y)
		if burning and (building or barrel):
			if not building or not building.paper:scenery_impact(target,result.normal)
			if building:building.ignite_hit(target)
		if barrel:
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
		elif not burning or not building:spark(target,Color("e5e0d2"),.045,.1)

func request_grenade() -> void:
	if state!="RUNNING" or not rules.active or rules.mission or respawn_time>0 or not player.enabled:return
	if grenade_stock<=0 or grenade_cooldown>0:return
	grenade_throw_time = GRENADE_WINDUP
	grenade_cooldown = GRENADE_INTERVAL
	player.prepare_grenade(comedy_mode)
	play_sound("cartridge_insert",-12,1.27)

func update_grenades(delta: float) -> void:
	for i in range(grenades.size()-1,-1,-1):
		var grenade = grenades[i]
		grenade.step(delta)
		if grenade.detonated:grenades.remove_at(i)
	grenade_cooldown = maxf(0,grenade_cooldown-delta)
	if grenade_throw_time<=0:return
	var previous = grenade_throw_time
	grenade_throw_time = maxf(0,grenade_throw_time-delta)
	var release_at = GRENADE_WINDUP-GRENADE_RELEASE
	if previous>release_at and grenade_throw_time<=release_at:launch_grenade()

func launch_grenade() -> void:
	var camera = player.camera
	var direction = camera.project_ray_normal(get_viewport().get_visible_rect().get_center()+player.crosshair_offset)
	var start = camera.to_global(Vector3(-.26,-.22,-.46))
	var query = PhysicsRayQueryParameters3D.create(camera.global_position,start,1)
	var obstruction = get_world_3d().direct_space_state.intersect_ray(query)
	if not obstruction.is_empty():start = obstruction.position+obstruction.normal*(Grenade.RADIUS+.01)
	var grenade = Grenade.new()
	grenade.name = "ThrownGrenade"
	grenade.game = self
	grenade.style = comedy_mode
	grenade.position = effects.to_local(start)
	grenade.velocity = direction*16.0+Vector3.UP*3.6
	effects.add_child(grenade)
	grenades.append(grenade)
	grenade_stock -= 1
	sync_grenade_stock()
	hud.grenade_eject_time = hud.GRENADE_EJECT_DURATION

func clear_grenades() -> void:
	grenade_throw_time = 0
	hud.grenade_eject_time = 0
	for grenade in grenades:
		grenade.get_parent().remove_child(grenade)
		grenade.queue_free()
	grenades.clear()

func sync_grenade_stock() -> void:
	if OS.has_feature("web") and touch_mode:
		JavaScriptBridge.eval("window.noArtSetGrenades?.(%d,%s)"%[grenade_stock,JSON.stringify(comedy_mode)])

func grenade_blast(center: Vector3, style: String) -> void:
	if state!="RUNNING" or not rules.active:return
	var kills_before = rules.kills
	for enemy in live_enemies():
		var target = enemy.global_position+Vector3.UP
		var distance = center.distance_to(target)
		if distance<=GRENADE_OUTER_RADIUS and blast_clear(center,target,[]):
			enemy.take_damage(Enemy.MAX_HEALTH if distance<=GRENADE_LETHAL_RADIUS else 1)
	if not rules.mission and rules.kills>kills_before:
		achievements.increment("grenade",rules.kills-kills_before)
	var target = player.global_position+Vector3.UP
	if center.distance_to(target)<=GRENADE_LETHAL_RADIUS and blast_clear(center,target,[]):
		damage_player(30,center)
	for barrel in arena.barrels:
		target = barrel.global_position+Vector3.UP*.65
		if not barrel.spent and center.distance_to(target)<=GRENADE_OUTER_RADIUS and blast_clear(center,target,[barrel.get_rid()]):
			barrel.ignite(.25)
	if is_instance_valid(comedy_toilet) and not comedy_toilet.spent:
		for charge in comedy_toilet.charge_bodies:
			target = charge.global_position
			if center.distance_to(target)<=GRENADE_OUTER_RADIUS and blast_clear(center,target,[charge.get_rid()]):
				comedy_toilet.shot_hit(true,destroy_active)
				break
	if destroy_active:grenade_hit_scenery(center)
	grenade_blast_fx(center,style)

func grenade_hit_scenery(center: Vector3) -> void:
	var space = get_world_3d().direct_space_state
	for structure in arena.structures:
		if structure.collapsed:continue
		var bounds: AABB = structure.world_bounds()
		var target = center.clamp(bounds.position,bounds.end)
		if target.distance_to(center)>GRENADE_OUTER_RADIUS:continue
		var direction = center.direction_to(target if not center.is_equal_approx(target) else bounds.get_center())
		if direction.is_zero_approx():continue
		var reach = GRENADE_OUTER_RADIUS if center.is_equal_approx(target) else minf(GRENADE_OUTER_RADIUS,target.distance_to(center)+.25)
		var query = PhysicsRayQueryParameters3D.create(center,center+direction*reach,1|SCENERY_TARGET_LAYER)
		var hit = space.intersect_ray(query)
		if not hit.is_empty() and hit.collider.get_meta("structure",null)==structure:
			structure.ignite_hit(hit.position)

func grenade_blast_fx(center: Vector3, style: String) -> void:
	var query = PhysicsRayQueryParameters3D.create(center,center-Vector3.UP*8,1)
	var ground = get_world_3d().direct_space_state.intersect_ray(query)
	var floor_y = ground.position.y+.07 if not ground.is_empty() else center.y
	var accent = Color("ed9259")
	match style:
		"comedy":
			accent = Color("c18b64")
			play_world_sound("comedy_plop",center,-7,.79)
		"roach":
			accent = Color("89af81")
			play_world_sound("roach_grenade",center,-7)
		_:play_world_sound("explosion",center,-8)
	var burst = CombatFX.new()
	burst.game = self
	burst.duration = .64
	effects.add_child(burst)
	burst.bloom(center,.83,Color("fff0bf"))
	burst.bloom(center+Vector3.UP*.25,.55,accent)
	var art = ComedyFX.ROACH_ART if style=="roach" else ComedyFX.POOP_ART
	for i in range(4 if reduced_motion else 8):
		var angle = i*2.39996
		var radial = Vector3(cos(angle),0,sin(angle))
		burst.chunk(center+radial*.25,Vector3(.18,.09,.28),accent,radial*5+Vector3.UP*(2+i%3),floor_y)
		if not style.is_empty() and i<4 and not reduced_motion:
			var fleck = ComedyFX.sprite(art[i%art.size()],.29)
			fleck.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			effects.add_child(fleck)
			fleck.global_position = center+radial*.3
			ComedyFX.blast_arc(fleck,Vector3(center.x,floor_y,center.z)+radial*(2.3+i*.36),.9,Vector3.ZERO,.58+i*.045)
	burst.show_pieces(false)
	blast_ring(Vector3(center.x,floor_y+.5,center.z),GRENADE_OUTER_RADIUS,Color("f7d08a"))

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
			if b.flame or b.toy_round:
				var travelled = b.origin.distance_to(to)
				# Draw the launch from the muzzle, then merge into the collision path.
				var offset: Vector3 = b.muzzle-b.origin
				var tip = to+offset*maxf(0,1-travelled/Enemy.CLOSE_SHOT_RANGE)
				if b.flame:
					var tail_distance = maxf(0,travelled-FlameBolt.LENGTH)
					var tail = b.origin+b.velocity.normalized()*tail_distance
					tail += offset*maxf(0,1-tail_distance/Enemy.CLOSE_SHOT_RANGE)
					b.flame.set_segment(tail,tip,player.camera.global_position)
				if b.toy_round:b.toy_round.global_position = tip

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
		if not from_finale and not rules.mission:
			achievements.combat_kill(session.session_id,headshot,kill_group_count,destroy_active,player.global_position.y,comedy_mode)
		hud.kill_group = kill_group_count
		hud.kill_pop = .5
		hud.multi_time = .65 if kill_group_count>=2 else 0.0
		if toilet_blast_active:return
		var pitch = minf(1.25,1+(kill_group_count-1)*.08)
		if not comedy_mode.is_empty() and not from_finale:
			var center: Vector3 = enemy.global_position+Vector3.UP*(1.78 if comedy_mode=="roach" else 1.02)
			ComedyFX.kill(effects,center.move_toward(player.camera.global_position,.34),comedy_mode,reduced_motion)
			play_sound("roach_buzz" if comedy_mode=="roach" else "comedy_plop",-7,pitch+(.15 if headshot else 0.0))
		else:play_sound("headshot" if headshot else "kill",-7,pitch)

func reserve_ranged_aim(enemy: Node3D) -> bool:
	if ranged_aimers.size()+bullets.size()>=RANGED_ATTACK_LIMIT:return false
	if is_behind_player(enemy.ranged_origin()) and (rear_bullet_active() or rear_aiming_enemy()!=null):return false
	ranged_aimers[enemy] = true
	return true

func is_behind_player(origin: Vector3) -> bool:
	var offset: Vector3 = origin-player.global_position
	offset.y = 0
	return player.global_basis.z.dot(offset)>0

func rear_bullet_active() -> bool:
	for bullet in bullets:
		if is_behind_player(bullet.origin):return true
	return false

func rear_aiming_enemy() -> Node3D:
	if rear_bullet_active():return null
	var next: Node3D
	for enemy in ranged_aimers:
		if not is_behind_player(enemy.ranged_origin()):continue
		if next==null or (enemy.rear_warned and not next.rear_warned) or (
				enemy.rear_warned==next.rear_warned and enemy.windup<next.windup):
			next = enemy
	return next

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
		grenade_throw_time = 0
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

func paper_impact(point: Vector3, normal: Vector3, floor_y: float, burst: bool = false) -> void:
	var fx = CombatFX.new()
	fx.name = "PaperScatter"
	fx.game = self
	fx.duration = 1.3 if burst else .7
	effects.add_child(fx)
	var tangent = normal.cross(Vector3.UP if absf(normal.y)<.95 else Vector3.RIGHT).normalized()
	var colors = [Color("fff9eb"),Color("edcf91"),Color("dedcd2")]
	var count = (10 if burst else 4) if reduced_motion else (22 if burst else 7)
	for i in range(count):
		var spread = tangent.rotated(normal,i*TAU/count)
		var speed = fx.rng.randf_range(1.1,3.3)*(1.65 if burst else 1.0)
		var launch = normal*fx.rng.randf_range(1.4,2.6)+spread*speed+Vector3.UP*1.85
		var extent = Vector3(.22,.006,.31)*fx.rng.randf_range(.77,1.15)
		fx.chunk(point+normal*.06+spread*.07,extent,colors[i%colors.size()],launch,floor_y+.025)
	fx.show_pieces(false)

func scenery_impact(point: Vector3, normal: Vector3) -> void:
	var fx = CombatFX.new()
	fx.name = "SceneryImpact"
	fx.game = self
	fx.duration = .22
	effects.add_child(fx)
	var tangent = normal.cross(Vector3.UP if absf(normal.y)<.95 else Vector3.RIGHT).normalized()
	var colors = [Color("ffb557"),Color("dc5e2b"),Color("fff1b7")]
	for i in range(6):
		var radial = tangent.rotated(normal,i*TAU/6)
		var velocity = radial*(2.1+float(i%3)*.45)+normal*1.6
		fx.chunk(point+normal*.05+radial*.07,Vector3(.18,.075,.13),colors[i%colors.size()],velocity,point.y-.55)
	fx.show_pieces(false)

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

func shot_sound_key() -> String:
	match comedy_mode:
		"comedy":return "water_shot"
		"roach":return "slipper_shot"
	return "shot"

func play_sound(key: String, volume: float = -10, pitch: float = 1) -> void:
	var voice = web_rifle if key=="shot" and web_rifle else audio_voices[audio_index%audio_voices.size()]
	audio_index += 1
	if voice!=web_rifle:voice.stream = sounds[shot_sound_key() if key=="shot" else key]
	voice.volume_db = volume
	voice.pitch_scale = pitch
	voice.play()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value,0,1)
	if music:music.volume_db = linear_to_db(maxf(.0001,music_volume))-8.0

func play_world_sound(key: String, pos: Vector3, volume: float, pitch: float = 1.0) -> void:
	var voice = AudioStreamPlayer3D.new()
	voice.stream = sounds[key]
	voice.volume_db = volume
	voice.pitch_scale = pitch
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

func on_structure_destroyed(structure: Node3D) -> void:
	if not rules.active or rules.mission or not destroy_active:return
	achievements.increment("wreck")
	if session.session_id=="night_studio" and structure.has_meta("studio_backdrop"):achievements.advance("studio",1)

func barrel_blast(center: Vector3, radius: float, source: StaticBody3D) -> void:
	if state!="RUNNING":return
	if finale_active:
		finale_explosion(center,1.5,Color("b65745"))
		return
	if not rules.active:return
	play_world_sound("explosion",center,-5)
	var before = rules.kills
	blast_damage_enemies(center,radius,[source.get_rid()])
	if not rules.mission:
		achievements.advance("barrel",rules.kills-before)
		if destroy_active and source.destroy_hits>=2:achievements.increment("wreck")
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

func toilet_blast(center: Vector3) -> void:
	if state!="RUNNING" or not rules.active:return
	toilet_blast_active = true
	for enemy in live_enemies():
		var offset: Vector3 = enemy.global_position-center
		if Vector2(offset.x,offset.z).length_squared()<=TOILET_BLAST_RADIUS*TOILET_BLAST_RADIUS:
			enemy.take_damage(Enemy.MAX_HEALTH)
	toilet_blast_active = false
	if destroy_active and not rules.mission:achievements.increment("wreck")
	var roach = comedy_mode=="roach"
	var accent = Color("b59df0") if roach else Color("e6aa60")
	var raised = center+Vector3.UP*.65
	play_world_sound("explosion",raised,-4)
	play_world_sound("roach_buzz" if roach else "comedy_plop",raised,-3)
	var plume = CombatFX.new()
	plume.game = self
	plume.duration = 1.22
	effects.add_child(plume)
	plume.bloom(raised+Vector3.UP,1.42,Color("fff0aa"))
	for i in range(8):
		var ray = Vector3(cos(i*TAU/8),0,sin(i*TAU/8))
		plume.bloom(raised+ray*(.8+float(i%2)*.56)+Vector3.UP*(.3+float(i%3)*.48),.75+float(i%3)*.25,accent)
		plume.chunk(raised+ray*.55,Vector3(.29,.14,.58),Color("47a99d") if i%2==0 else Color("fff0cb"),ray*5+Vector3.UP*(4+float(i%3)),center.y+.08)
	plume.show_pieces()
	ComedyFX.toilet_scatter(effects,center,comedy_mode,reduced_motion)
	blast_ring(center+Vector3.UP*.59,TOILET_BLAST_RADIUS,accent)

func blast_ring(center: Vector3, radius: float, color: Color = Color("f6bc62")) -> void:
	var ring = MeshInstance3D.new()
	ring.mesh = blast_ring_mesh
	ring.material_override = effect_material(color)
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
	if path in [DefaultSession.resource_path,PARK_SESSION_PATH,FERRY_SESSION_PATH,STUDIO_SESSION_PATH,SANDGATE_SESSION_PATH]:return path
	return ""

func select_session(selection: Variant, highlighted_id: String = "") -> void:
	if state!="TITLE" or switching_session or not selection:return
	if selection is Resource:
		if selection==session:return
		highlighted_id = selection.session_id
	elif selection==session.resource_path:return
	if not highlighted_id.is_empty():title_session_id = highlighted_id
	switching_session = true
	map_switch_progress = 0.0
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
	title_session_id = session.session_id
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
