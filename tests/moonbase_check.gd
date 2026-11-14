extends Node
var game: Node
var samples: Array[float] = []
var frenzy_samples: Array[float] = []
var frames: Array = []
var phase = "grey" if "--grey" in OS.get_cmdline_user_args() else "corner"
var directory = "res://docs/art/space/review-a/"
var capture_done = false
var done = false

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
	set_process(true)

func capture(label: String) -> void:
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(directory+phase+"-"+label+".png")==OK)

func _process(delta: float) -> void:
	if done:return
	var elapsed: float = game.rules.elapsed
	if elapsed>3:samples.append(delta*1000)
	if elapsed>=43 and elapsed<=48:frenzy_samples.append(delta*1000)
	frames.append([snappedf(elapsed,.001),snappedf(delta*1000,.001),game.destroy_active])
	game.player.rotation.y = sin(elapsed*.14)*.28
	if elapsed>=45.3 and not capture_done:
		capture_done = true
		assert(game.destroy_active)
		capture("frenzy")
	if game.state=="RESULTS":
		done = true
		assert(game.state=="RESULTS" and capture_done)
		var report = {"phase":phase,"device":RenderingServer.get_video_adapter_name(),"resolution":str(get_viewport().get_texture().get_size()),"warm":stats(samples),"transition_43_to_48":stats(frenzy_samples),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"frames":frames,"checks":["session isolation","map actions blocked","navigation all markers","physical ramp ascent","pause freeze","full 60 seconds","frenzy at 45 seconds","results"],"note":"Uncapped native engine frame intervals including CPU scheduling; not GPU timings. Placeholder enemies and weapon. Automatic test, not human playtest."}
		FileAccess.open(directory+phase+"-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		game.start_run()
		assert(game.rules.elapsed==0 and game.rules.kills==0)
		print("MOONBASE_CHECK_PASS ",JSON.stringify(stats(samples)))
		get_tree().quit()

func stats(values: Array[float]) -> Dictionary:
	values.sort()
	return {"frames":values.size(),"p50_ms":values[int(values.size()*.5)],"p95_ms":values[int(values.size()*.95)],"p99_ms":values[int(values.size()*.99)],"max_ms":values.back()}
