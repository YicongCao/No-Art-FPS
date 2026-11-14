extends Node
var game: Node
var samples: Array[float] = []
var frenzy_samples: Array[float] = []
var frames: Array = []
var phase = "heroes" if "--review-b" in OS.get_cmdline_user_args() else "grey" if "--grey" in OS.get_cmdline_user_args() else "corner"
var directory = "res://docs/art/space/review-b/" if "--review-b" in OS.get_cmdline_user_args() else "res://docs/art/space/review-a/"
var draw_samples: Array = []
var capture_done = false
var done = false
var last_frame_us = 0

func _ready() -> void:
	set_process(false)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	assert(game.nav_ready and game.arena.validate_navigation())
	assert(game.score_record_key()=="score_moonbase_trial_v1")
	game.menu_action("comedy")
	assert(game.comedy_mode.is_empty())
	game.menu_action("sandgate")
	assert(game.session.session_id=="moonbase_trial")
	game.start_run()
	game.begin_running()
	game.invulnerable = 999
	game.player.enabled = false
	game.pause_run()
	var paused: float = game.rules.elapsed
	await get_tree().create_timer(.3).timeout
	assert(game.rules.elapsed==paused)
	game.menu_action("resume")
	game.player.enabled = false
	game.player.position = Vector3(2,.05,13)
	game.player.camera.rotation.x = -.05
	await get_tree().create_timer(1.0).timeout
	await capture("opening")
	# Inspect the playable ramp with actual CharacterBody movement, not nav alone.
	game.player.position = Vector3(-9.5,.05,-6.5)
	game.player.rotation.y = 0
	game.player.enabled = true
	Input.action_press("forward")
	await get_tree().create_timer(1.45).timeout
	Input.action_release("forward")
	game.player.enabled = false
	assert(game.player.position.y>1.8,"Service ramp must be physically walkable")
	print("MOONBASE_RAMP_PASS ",game.player.position)
	game.player.position = Vector3(12,.05,-1)
	game.player.rotation.y = .3
	game.player.camera.rotation.x = .05
	await capture("corner")
	game.start_run()
	game.begin_running()
	game.invulnerable = 999
	game.player.enabled = false
	game.player.position = Vector3(2,.05,13)
	game.player.camera.rotation.x = -.05
	if "--visual-only" in OS.get_cmdline_user_args():
		game.rules.elapsed = 44.8
		await get_tree().create_timer(1.0).timeout
		assert(game.destroy_active)
		await capture("frenzy")
		game.set_physics_process(false)
		game.clear_round()
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().quit()
		return
	set_process(true)

func capture(label: String) -> void:
	if "--perf-only" in OS.get_cmdline_user_args():return
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(directory+phase+"-"+label+".png")==OK)
	if phase=="corner" and label=="opening":
		game.hud.hide()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_webp(directory+"title-background.webp")
		game.hud.show()

func _process(_delta: float) -> void:
	if done:return
	var now = Time.get_ticks_usec()
	var frame_ms = (now-last_frame_us)/1000.0 if last_frame_us else 0.0
	last_frame_us = now
	var elapsed: float = game.rules.elapsed
	if elapsed>3:samples.append(frame_ms)
	if frames.size()%60==0:draw_samples.append([elapsed,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	if elapsed>=43 and elapsed<=48:frenzy_samples.append(frame_ms)
	frames.append([snappedf(elapsed,.001),snappedf(frame_ms,.001),game.destroy_active])
	game.player.rotation.y = sin(elapsed*.14)*.28
	if elapsed>=45.3 and not capture_done:
		capture_done = true
		assert(game.destroy_active)
		capture("frenzy")
	if game.state=="RESULTS":
		done = true
		assert(game.state=="RESULTS" and capture_done)
		var report = {"phase":phase,"device":RenderingServer.get_video_adapter_name(),"resolution":str(get_viewport().get_texture().get_size()),"warm":stats(samples),"transition_43_to_48":stats(frenzy_samples),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"frames":frames,"draw_samples":draw_samples,"checks":["session isolation","map actions blocked","navigation all markers","physical ramp ascent","pause freeze","full 60 seconds","frenzy at 45 seconds","results"],"screenshot_readbacks_in_sample":not "--perf-only" in OS.get_cmdline_user_args(),"note":"Uncapped native monotonic wall-clock frame intervals including CPU scheduling; not GPU timings. Asset stage is identified by phase. Automatic test, not human playtest."}
		FileAccess.open(directory+phase+("-clean" if "--perf-only" in OS.get_cmdline_user_args() else "")+"-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report))
		game.start_run()
		assert(game.rules.elapsed==0 and game.rules.kills==0)
		print("MOONBASE_CHECK_PASS ",JSON.stringify(stats(samples)))
		get_tree().quit()

func stats(values: Array[float]) -> Dictionary:
	values.sort()
	return {"frames":values.size(),"p50_ms":values[int(values.size()*.5)],"p95_ms":values[int(values.size()*.95)],"p99_ms":values[int(values.size()*.99)],"max_ms":values.back()}
