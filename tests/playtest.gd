extends Node

var game: Node
var phase = 0
var elapsed = 0.0
var frame_ms: Array[float] = []
var baseline_nodes = 0
var reported = false
var captured: Dictionary = {}

func _ready() -> void:
	Engine.max_fps = 60
	game.start_run()
	game.ready_time = .05
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("QA_START: rendered full-minute autoplay and restart")

func _process(delta: float) -> void:
	if game.state == "READY":return
	if phase==0:
		baseline_nodes = get_tree().get_node_count()
		var start = game.player.position
		Input.action_press("right")
		phase = 1
		set_meta("start",start)
	if phase==1:
		elapsed += delta
		if elapsed>1:
			Input.action_release("right")
			assert(game.player.position.distance_to(get_meta("start"))>2,"Player must move with input")
			game.player.reset_position()
			phase = 2
			print("QA_MOVEMENT_PASS")
		return
	if phase==2 and game.state=="RUNNING":
		if game.rules.elapsed>3:frame_ms.append(delta*1000)
		# Aim at the nearest actually visible head, using the same firing path as input.
		var nearest: Node3D = null
		var dist = 10000.0
		for enemy in game.live_enemies():
			var point = enemy.global_position+Vector3(0,1.7,0)
			var query = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,point,1)
			if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty():continue
			var d = game.player.position.distance_to(enemy.position)
			if d<dist:
				dist = d
				nearest = enemy
		if nearest!=null:
			var dir = game.player.camera.global_position.direction_to(nearest.global_position+Vector3(0,1.7,0))
			game.player.rotation.y = atan2(-dir.x,-dir.z)
			game.player.pitch = asin(dir.y)
			game.player.camera.rotation.x = game.player.pitch
			game.shoot()
		# Visit separate sight lines and both elevation levels during a real-time round.
		var t = int(game.rules.elapsed)
		if t in [5,20,38,55] and not captured.has(t):
			captured[t] = true
			capture("gameplay-%02d"%t)
		if t==18 and not captured.has("elevated"):
			captured["elevated"] = true
			game.player.position = Vector3(3,3.2,-11)
		if t==34 and not captured.has("ground"):
			captured["ground"] = true
			game.player.position = Vector3(30,.05,7)
		if t==48 and not captured.has("return"):
			captured["return"] = true
			game.player.reset_position()
		return
	if phase==2 and game.state=="RESULTS" and not reported:
		reported = true
		assert(game.rules.elapsed==60 and not game.rules.active)
		assert(game.rules.kills>0,"Real firing must kill targets")
		var final_kills = game.rules.kills
		game.on_kill(game.enemies.get_child(0),true)
		assert(game.rules.kills==final_kills,"Results cannot accept late kills")
		await capture("results")
		frame_ms.sort()
		var report = {
			"duration_game_seconds":game.rules.elapsed,
			"kills":game.rules.kills,"headshots":game.rules.headshots,"shots":game.rules.shots,
			"frames":frame_ms.size(),"p95_frame_ms":frame_ms[int(frame_ms.size()*.95)],
			"p99_frame_ms":frame_ms[int(frame_ms.size()*.99)],
			"node_count_at_end":get_tree().get_node_count(),"baseline_nodes":baseline_nodes,
			"note":"Automated perfect-aim test with scripted repositioning; not human gameplay or long-run validation. Frame intervals include a 60 fps cap."}
		var file = FileAccess.open("res://artifacts/playtest.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		file.close()
		print("QA_ROUND_PASS ",JSON.stringify(report))
		game.start_run()
		assert(game.rules.kills==0 and game.ammo==20 and game.health==100 and game.bullets.is_empty())
		assert(game.enemies.get_child_count()==0 and game.effects.get_child_count()==0)
		print("QA_RESTART_PASS")
		await get_tree().process_frame
		get_tree().quit()

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
