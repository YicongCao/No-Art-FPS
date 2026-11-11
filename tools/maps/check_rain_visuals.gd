extends SceneTree
## Repeatable visual workload, not a human playtest or full combat benchmark.
var game: Node3D
var camera: Camera3D
var out: String
const VIEWS = {
	"wet-aisle": [Vector3(.4,1.45,16.12),Vector3(.38,1.47,1.9),73.0],
	"fish-crossing": [Vector3(-19.2,2.67,19.68),Vector3(-13.25,2.87,10.45),80.0],
	"upper-crossing": [Vector3(-20.55,6.05,-3.88),Vector3(-9.6,2.7,-3.74),72.0],
	"service-frenzy": [Vector3(12.1,2.63,13.5),Vector3(8,2.82,4.1),72.0],
}
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	var args := OS.get_cmdline_user_args()
	out = "res://artifacts/local/rain-lookdev/"+(args[0] if args.size()>0 else "after")
	DirAccess.make_dir_recursive_absolute(out)
	seed(11011)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	game.qa_mode = true
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	await game.select_session(game.CONCEPT_SESSIONS.rain_market,"rain_market")
	game.start_run()
	game.begin_running()
	game.player.enabled = false
	game.invulnerable = 999
	for enemy in game.live_enemies():enemy.set_physics_process(false)
	game.hud.hide()
	game.player.gun.hide()
	game.enemies.hide()
	camera = Camera3D.new()
	camera.far = 145
	game.add_child(camera)
	camera.make_current()
	for key in VIEWS:
		var shot: Array = VIEWS[key]
		camera.position = shot[0]
		camera.look_at(shot[1])
		camera.fov = shot[2]
		game.rules.elapsed = 47 if key=="service-frenzy" else 8
		game.set_destroy_active(key=="service-frenzy")
		for i in range(40):await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(out+"/"+key+".png")==OK)
		if key=="wet-aisle" and "market_lookdev" in game.arena and game.arena.market_lookdev:
			game.arena.market_lookdev.reflection.get_texture().get_image().save_png(out+"/reflection.png")
	game.enemies.show()
	if "--capture-only" in args:
		print("RAIN_CAPTURE_PASS ",out)
		quit()
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var samples: Array[float] = []
	var normal: Array[float] = []
	var frenzy: Array[float] = []
	var calls: Array[float] = []
	var elapsed := 0.0
	var previous := Time.get_ticks_usec()
	while elapsed<63.0:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now-previous)/1000.0
		previous = now
		elapsed += ms/1000.0
		var t := maxf(0,elapsed-3)
		game.rules.elapsed = t
		game.set_destroy_active(t>=45)
		camera.position = Vector3(.4+sin(t*.19)*1.5,1.65,15.5)
		camera.look_at(Vector3(sin(t*.25)*9,3,0))
		camera.fov = 73
		if elapsed>3:
			samples.append(ms)
			if t<45:normal.append(ms)
			else:frenzy.append(ms)
			calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var report = {"device":RenderingServer.get_video_adapter_name(),"resolution":str(root.get_texture().get_size()),
		"seconds":60,"warmup":3,"vsync":false,"fps_cap":0,"all":stats(samples),"normal":stats(normal),"frenzy":stats(frenzy),
		"draw_calls":stats(calls),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"note":"60s deterministic camera sweep with 8 frozen actors, weather and frenzy lights; includes scheduling, not GPU timer queries or combat CPU benchmark."}
	FileAccess.open(out+"/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("RAIN_VISUAL_BENCH_PASS ",JSON.stringify(report))
	quit()
func stats(values: Array[float]) -> Dictionary:
	values.sort()
	var sum := 0.0
	for value in values:sum += value
	return {"count":values.size(),"mean":sum/values.size(),"p50":values[int(values.size()*.5)],"p95":values[int(values.size()*.95)],"p99":values[int(values.size()*.99)],"max":values.back()}
