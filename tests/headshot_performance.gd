extends SceneTree
## Isolate the added burst cost at a fixed camera, without recording or live AI.
const FX = preload("res://scripts/headshot_fx.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	root.size = Vector2i(1440,810)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready)
	game.qa_mode = true
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.player.position = Vector3(18,.05,14)
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3.ZERO
	game.hud.go_time = 0
	var results: Array = []
	for rate in [0,1,10,0]:
		game.clear_round()
		for i in range(60):await process_frame
		var intervals: Array[float] = []
		var draws: Array[float] = []
		var creation: Array[float] = []
		var start := Time.get_ticks_usec()
		var previous := start
		var next_burst := start
		var full_peak := 0
		while Time.get_ticks_usec()-start<8000000:
			if rate>0 and Time.get_ticks_usec()>=next_burst:
				var before := Time.get_ticks_usec()
				var fx = FX.new()
				game.effects.add_child(fx)
				fx.setup(game,Vector3(18,1.75,10),Vector3.FORWARD,Vector3.BACK,false,true,.09)
				creation.append((Time.get_ticks_usec()-before)/1000.0)
				next_burst += 1000000/rate
				full_peak = maxi(full_peak,get_nodes_in_group("headshot_full").size())
			await process_frame
			var now := Time.get_ticks_usec()
			intervals.append((now-previous)/1000.0)
			previous = now
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var first_creation := creation[0] if not creation.is_empty() else 0.0
		intervals.sort()
		draws.sort()
		creation.sort()
		var row := {"bursts_per_second":rate,"frames":intervals.size(),"frame_ms_p50":p(intervals,.5),"frame_ms_p95":p(intervals,.95),"frame_ms_p99":p(intervals,.99),"frame_ms_max":intervals[-1],"draw_calls_p50":p(draws,.5),"draw_calls_p95":p(draws,.95),"first_setup_cpu_ms":first_creation,"setup_cpu_ms_p95":p(creation,.95) if not creation.is_empty() else 0.0,"full_peak":full_peak}
		results.append(row)
		print("HEADSHOT_PERF ",JSON.stringify(row))
	var file := FileAccess.open("res://docs/art/toy/headshot/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":"Compatibility","gpu":RenderingServer.get_video_adapter_name(),"viewport":str(root.size),"vsync":DisplayServer.window_get_vsync_mode(),"note":"Fixed yard camera, 8 seconds per phase; baseline, 1 burst/s, 10 bursts/s, baseline. Effects only, no AI, no kills or corpse updates. Loading prewarm enabled. Frame intervals include vsync and OS scheduling; not GPU timings. CPU setup excludes deferred renderer work.","samples":results},"  "))
	game.queue_free()
	for i in range(3):await process_frame
	quit()
func p(values: Array[float], quantile: float) -> float:
	return values[mini(int(values.size()*quantile),values.size()-1)]
