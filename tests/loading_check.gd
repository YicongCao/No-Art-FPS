extends Node

var game: Node
var captures: Dictionary = {}
var last_capture_time = 0

func _ready() -> void:
	assert(DisplayServer.get_name()!="headless","Loading check requires rendered frames")
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	# Unknown progress cannot fill the final three rounds or start a transition.
	var model = game.LoadingTransition.new()
	model.report(.8)
	for i in range(600):model.advance(1.0/60.0)
	assert(model.rounds==17 and model.phase=="FILL")
	model.suspended = true
	model.advance(.5)
	assert(model.rounds==17)
	model.suspended = false
	model.work_complete = true
	var sequence: Array[String] = []
	for i in range(300):
		if sequence.is_empty() or sequence[-1]!=model.phase:sequence.append(model.phase)
		model.advance(1.0/60.0)
	assert(sequence==["FILL","SEAT","REVEAL","DOCK","DONE"])
	print("LOADING_MODEL_WAIT_CAP_PASS")
	await get_tree().process_frame
	assert(not game.hud.menu.has_node("arena") and not game.hud.menu.has_node("defuse"))
	press_dust_shortcut(false)
	game.menu_action("defuse")
	assert(not game.dust_unlocked and not game.rules.mission and not game.hud.menu.has_node("defuse"))
	await capture("title-fire")
	assert(game.title_frame_ready and game.hud.title_frame!=null)
	captures["opening-frame"] = game.hud.title_frame.get_image()
	var title_background = background_patch(captures["title-fire"])
	# The title must retain the captured starting frame even when the underlying
	# 3D camera is moved; loading preparation must remain hidden behind it too.
	game.player.rotation.y = .5
	await get_tree().process_frame
	await capture("title-frozen-check")
	assert(title_background.compute_image_metrics(background_patch(captures["title-frozen-check"]),false)["mean"]<.01)
	captures.erase("title-frozen-check")
	game.player.rotation.y = 0
	# Exercise the actual text button hitbox, rather than directly firing its signal.
	var button = game.hud.fire_button
	assert(button is Button and button.text=="FIRE" and button.get_theme_constant("outline_size")==0)
	assert(button.get_theme_color("font_color")==Color.WHITE)
	assert(button.get_theme_stylebox("normal").bg_color==Color("754c87"))
	assert(button.get_theme_font("font").resource_path=="res://assets/fonts/Rajdhani-Bold.ttf")
	click_button(button)
	assert(game.state=="LOADING","FIRE click starts loading immediately")
	var audio_start = game.audio_index
	var ticket = game.load_ticket
	game.menu_action("play")
	assert(game.load_ticket==ticket,"Double click cannot start a second load")
	var seen: Dictionary = {}
	var prepared_ids: Array = []
	var previous_rounds = 0.0
	var start_time = Time.get_ticks_usec()
	var last_time = start_time
	var frame_intervals: Array[float] = []
	var first_cover_ms = 0.0
	for frame in range(900):
		await get_tree().process_frame
		if game.state!="LOADING":break
		var now = Time.get_ticks_usec()
		frame_intervals.append(float(now-last_time)/1000.0)
		last_time = now
		assert(not game.rules.active and game.rules.elapsed==0)
		assert(not game.player.enabled and game.hud.go_time==0)
		var loader = game.loading
		assert(game.audio_index-audio_start==int(loader.rounds),"Loading clicks follow rendered cartridge boundaries")
		assert(loader.rounds>=previous_rounds)
		if not loader.work_complete:assert(loader.rounds<=17)
		previous_rounds = loader.rounds
		game.shoot()
		assert(game.rules.shots==0)
		var phase: String = loader.phase
		if phase=="FILL" and not seen.has("FILL"):
			await capture("loading-fill")
			first_cover_ms = float(last_capture_time-start_time)/1000.0
			assert(title_background.compute_image_metrics(background_patch(captures["loading-fill"]),false)["mean"]<.01,"Title and loading share the same image and black opacity")
			assert(game.hud.loading_cover.material.get_shader_parameter("shade_opacity")==game.hud.TITLE_SHADE_OPACITY)
			seen["FILL"] = true
		elif phase=="SEAT" and loader.phase_time>.1 and not seen.has(phase):
			assert(loader.rounds==20 and loader.work_complete)
			await capture("loading-seated")
			seen[phase] = true
		elif phase=="REVEAL" and loader.phase_time>.25 and not seen.has(phase):
			assert(loader.dock_progress()==0,"Do not move magazine before the wipe finishes")
			await capture("loading-reveal")
			seen[phase] = true
		elif phase=="DOCK" and loader.phase_time>.3 and not seen.has(phase):
			assert(loader.reveal_progress()==1)
			prepared_ids = game.live_enemies().map(func(e):return e.get_instance_id())
			await capture("loading-docking")
			seen[phase] = true
	assert(game.state=="RUNNING" and game.opening_prepared)
	assert(game.audio_index-audio_start==21,"Twenty cartridge sounds followed by one GO tick")
	assert(seen.size()==4)
	assert(game.live_enemies().size()==8 and game.rules.elapsed<.05)
	assert(game.rules.active and game.player.enabled and game.hud.go_time>.7,"Dock completion starts gameplay immediately")
	assert(game.hud.loading_magazine_rect().is_equal_approx(game.hud.magazine_rect()),"Last transition rectangle matches the real HUD")
	assert(prepared_ids==game.live_enemies().map(func(e):return e.get_instance_id()),"Immediate start reuses prewarmed actors")
	await capture("loading-go")
	game.shoot()
	assert(game.rules.shots==1,"GO does not block firing")
	var start_position = game.player.position
	Input.action_press("right")
	await get_tree().create_timer(.2).timeout
	Input.action_release("right")
	assert(game.player.position.distance_to(start_position)>.4,"GO does not block movement")
	assert(game.rules.elapsed>.15 and game.hud.go_time>0)
	await capture("loading-go-fading")
	game.pause_run()
	var held_go = game.hud.go_time
	await get_tree().create_timer(.2).timeout
	assert(game.hud.go_time==held_go,"Pause freezes GO fade")
	game.menu_action("resume")
	await get_tree().create_timer(.75).timeout
	assert(game.hud.go_time==0 and game.rules.elapsed>.8)
	await capture("loading-go-finished")
	frame_intervals.sort()
	var report = {"first_loading_frame_ms":first_cover_ms,"loading_p95_frame_ms":frame_intervals[int(frame_intervals.size()*.95)],"loading_max_frame_ms":frame_intervals.back(),"note":"Rendered automated FIRE click and transition, 60 fps cap; not human input latency or a cross-device performance guarantee."}
	FileAccess.open("res://artifacts/loading-check.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LOADING_RENDERED_SEQUENCE_PASS ",JSON.stringify(report))
	# Retry also prepares a new round behind the cover; cancel via real Escape input.
	game.pause_run()
	game.menu_action("retry")
	await get_tree().process_frame
	var escape = InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	await get_tree().create_timer(.2).timeout
	assert(game.state=="TITLE" and game.enemies.get_child_count()==0 and game.hud.loading_cover.visible)
	await capture("title-return-check")
	assert(title_background.compute_image_metrics(background_patch(captures["title-return-check"]),false)["mean"]<.01,"Returning to title restores the same first-frame background")
	captures.erase("title-return-check")
	# Early click while nav is still pending, plus focus suspension and safe reentry.
	game.nav_ready = false
	game.request_run()
	await get_tree().create_timer(4).timeout
	assert(game.state=="LOADING" and not game.loading.work_complete)
	assert(game.loading.rounds==17)
	await capture("loading-waiting")
	game.loading.suspended = true
	var held = game.loading.rounds
	await get_tree().create_timer(.2).timeout
	assert(game.loading.rounds==held)
	game.nav_ready = true
	game.loading.suspended = false
	DisplayServer.window_set_size(Vector2i(960,540))
	await get_tree().create_timer(.15).timeout
	await capture("loading-small-window")
	for frame in range(500):
		if game.state=="RUNNING":break
		await get_tree().process_frame
	assert(game.state=="RUNNING" and game.live_enemies().size()==8 and game.hud.go_time>.7)
	press_dust_shortcut(true)
	assert(not game.dust_unlocked,"The shortcut is only active on the title screen")
	game.finish_run()
	game.menu_action("menu")
	await get_tree().process_frame
	press_dust_shortcut(true)
	assert(game.dust_unlocked and game.hud.menu.has_node("arena") and game.hud.menu.has_node("defuse"))
	assert(not game.rules.mission,"Unlocking shows the button without selecting Dust")
	click_button(game.hud.menu.get_node("defuse"))
	for frame in range(300):
		if not game.switching_session:break
		await get_tree().physics_frame
	assert(game.rules.mission and game.arena.map_id=="dust_flavor" and game.nav_ready and game.title_frame_ready)
	assert(game.hud.menu.has_node("defuse"),"The entry remains available after switching maps")
	print("DUST_TITLE_UNLOCK_PASS")
	game.clear_round()
	for filename in captures:captures[filename].save_png("res://artifacts/"+filename+".png")
	await get_tree().create_timer(.3).timeout
	print("LOADING_CHECK_PASS: white Rajdhani text/purple button, frozen first frame/shared shade, staged prep, 17-round cap, wipe then dock, immediate GO/input/timer, fade/pause, retry/cancel, early click, focus, resize")
	get_tree().quit()

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	last_capture_time = Time.get_ticks_usec()
	captures[filename] = get_viewport().get_texture().get_image()

func background_patch(image: Image) -> Image:
	# Outside both the title text and the central loading magazine.
	return image.get_region(Rect2i(int(image.get_width()*.72),int(image.get_height()*.16),120,90))

func click_button(button: Button) -> void:
	var point = button.get_global_rect().get_center()
	var motion = InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)

func press_dust_shortcut(with_shift: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = KEY_9
	event.ctrl_pressed = true
	event.shift_pressed = with_shift
	event.pressed = true
	get_viewport().push_input(event,true)
