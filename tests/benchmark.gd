extends Node

var game: Node
var elapsed = 0.0
var samples: Array[float] = []
var done = false

func _ready() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game.start_run()
	game.begin_running()
	game.spawn_time = 999
	for p in [Vector3(-14,0,9),Vector3(14,0,9),Vector3(-15,0,-8),Vector3(15,0,-10),Vector3(-9,0,12),Vector3(9,0,12)]:game.spawn_enemy(p,false)
	game.invulnerable = 999
	game.player.enabled = false
	print("BENCHMARK_START: 10 enemies, uncapped; actual render dimensions recorded; 3 second warmup + 10 second sample")

func _process(delta: float) -> void:
	if done:return
	elapsed += delta
	game.player.rotation.y = sin(elapsed*.5)*.9
	if elapsed>3:samples.append(delta*1000)
	if elapsed>13:
		done = true
		samples.sort()
		var report = {
			"renderer":"Compatibility / OpenGL on Metal", "device":RenderingServer.get_video_adapter_name(),
			"render_resolution":str(get_viewport().get_texture().get_size()),"canvas_resolution":str(get_viewport().get_visible_rect().size),"enemy_count":game.live_enemies().size(),
			"vsync":false,"fps_cap":0,"sample_seconds":10,"frames":samples.size(),
			"p50_frame_ms":samples[int(samples.size()*.5)],"p95_frame_ms":samples[int(samples.size()*.95)],
			"p99_frame_ms":samples[int(samples.size()*.99)],"max_frame_ms":samples.back(),
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"note":"Short automated stress sample; includes engine/process scheduling, not GPU timer queries. Not a ten-minute soak or cross-platform result."}
		var file = FileAccess.open("res://artifacts/benchmark.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		file.close()
		print("BENCHMARK_PASS ",JSON.stringify(report))
		get_tree().quit()
