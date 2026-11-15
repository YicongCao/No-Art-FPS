extends Node

var game: Node3D
var diagnostic := false
var frames: Array[float] = []
var draws: Array[float] = []
var cpu: Array[float] = []
var physics: Array[float] = []
var spikes: Array = []
var last_us := 0
var second := 0.0
var yaw := 0.0
var bench := false
var refresh_poll := 0.0
var current_target := 60

func setup(context: Node3D) -> void:
	game = context
	diagnostic = bool(JavaScriptBridge.eval("Boolean(window.noArtPerfEnabled)"))
	bench = OS.has_feature("perfbench")
	if bench:benchmark.call_deferred()
	set_process(true)

func benchmark() -> void:
	game.qa_mode = true
	var map_id = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('map')||'sandgate'"))
	if not game.title_session_path(map_id).is_empty():await game.select_session(load(game.title_session_path(map_id)),map_id)
	seed(20261115)
	game.request_run()
	while game.state!="RUNNING":await get_tree().process_frame
	game.invulnerable = 999
	seed(20261115)
	game.player.enabled = false
	yaw = game.player.rotation.y

func percentile(values: Array[float], fraction: float) -> float:
	var copy = values.duplicate()
	copy.sort()
	return copy[mini(copy.size()-1,int(copy.size()*fraction))] if not copy.is_empty() else 0.0

func _process(delta: float) -> void:
	refresh_poll += delta
	if refresh_poll>=1.0:
		refresh_poll = 0
		var target := int(JavaScriptBridge.eval("window.noArtTargetFPS?.()||60"))
		if target!=current_target and game.state in ["TITLE","LOADING"]:
			current_target = target
			if game.has_method("apply_frame_budget"):game.apply_frame_budget(target)
	if not diagnostic:return
	var now := Time.get_ticks_usec()
	if game.state=="RUNNING":
		if last_us>0:
			var ms := (now-last_us)/1000.0
			frames.append(ms)
			if ms>25 and spikes.size()<12:spikes.append({"ms":ms,"elapsed":game.rules.elapsed,"cpu":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000})
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		second += delta
		if bench:
			game.player.rotation.y = yaw+sin(game.rules.elapsed*.45)*.35
			if game.rules.elapsed>10:game.shoot()
		if second>=1.0:
			var sample = {"intervals":frames.duplicate(),"player":str(game.player.global_position),"actors":game.live_enemies().size(),"map":game.arena.map_id,"elapsed":game.rules.elapsed,"phase":"finale" if game.finale_active else ("frenzy" if game.destroy_active else "normal"),"frames":frames.size(),"p50":percentile(frames,.5),"p95":percentile(frames,.95),"p99":percentile(frames,.99),"max":percentile(frames,1),"draws":percentile(draws,.5),"cpu":percentile(cpu,.5),"physics":percentile(physics,.5),"spikes":spikes,"scale":game.get_viewport().scaling_3d_scale,"viewport":str(game.get_viewport().size),"render_size":str(Vector2i(Vector2(game.get_viewport().size)*game.get_viewport().scaling_3d_scale)),"cap":Engine.max_fps}
			JavaScriptBridge.eval("window.noArtFrameReport?.(%s)"%JSON.stringify(sample))
			frames.clear();draws.clear();cpu.clear();physics.clear();spikes.clear();second = 0
		last_us = now
	else:last_us = 0
