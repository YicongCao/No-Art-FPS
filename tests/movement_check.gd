extends Node

var game: Node
var minimum_spacing = INF

func _ready() -> void:
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	var guards = game.live_enemies().filter(func(e):return not e.fast and not is_instance_valid(e.container_room))
	var starts: Array[Vector3] = []
	var travelled: Array[float] = []
	for enemy in guards:
		starts.append(enemy.position)
		travelled.append(0.0)
	for frame in range(720):
		await get_tree().physics_frame
		check_spacing()
		for i in range(guards.size()):
			travelled[i] = maxf(travelled[i],guards[i].position.distance_to(starts[i]))
	for i in range(guards.size()):
		print("GUARD_TRAVEL ",guards[i].home_zone," ",starts[i]," distance=",travelled[i]," end=",guards[i].position)
		assert(travelled[i]>2.0,"Every opening black guard must move: "+str(starts[i]))
	print("MOVEMENT_OPENING_PASS")
	# Twelve real navigation agents cross opposing lanes through the same plaza.
	game.clear_round()
	game.player.position = Vector3(0,.05,23)
	game.player.pitch = -.13
	guards.clear()
	starts.clear()
	for side in [-1,1]:
		for row in range(6):
			var point = Vector3(side*6,0,13.5+row*1.3+(0.3 if side==1 else 0.0))
			var enemy = game.spawn_enemy(point,false)
			enemy.think = 999
			enemy.attack = 999
			enemy.agent.target_position = Vector3(-point.x,0,point.z)
			guards.append(enemy)
			starts.append(enemy.position)
	for frame in range(600):
		await get_tree().physics_frame
		check_spacing()
		if frame==120:capture.call_deferred("enemy-crossing")
	for i in range(guards.size()):
		print("CROSSING_TRAVEL ",starts[i]," end=",guards[i].position)
		assert(absf(guards[i].position.x-starts[i].x)>8,"Crowded guard must make forward progress")
	print("MOVEMENT_CROSSING_PASS minimum_center_spacing=",minimum_spacing)
	game.pause_run()
	var frozen = guards[0].position
	await get_tree().create_timer(.3).timeout
	assert(guards[0].position.is_equal_approx(frozen),"Avoidance must not move paused actors")
	game.state = "RUNNING"
	game.clear_round()
	game.player.reset_position()
	game.player.enabled = false
	var occupied = Vector3(-2,0,21)
	var blocker = game.spawn_enemy(occupied,false)
	blocker.set_physics_process(false)
	assert(not game.spawn_is_clear(occupied))
	game.pending_spawn = {"pos":occupied,"delay":0.0}
	game.update_spawns(.1)
	assert(game.live_enemies().size()==1 and game.pending_spawn.is_empty(),"Recheck occupancy after warning")
	blocker.take_hit(true)
	assert(game.spawn_is_clear(occupied),"Dead actors must release their slot")
	game.pending_spawn = {"pos":occupied,"delay":0.0}
	game.update_spawns(.1)
	assert(game.live_enemies().size()==1,"Freed hidden slot must accept a reinforcement")
	print("MOVEMENT_SPAWN_PAUSE_PASS")
	game.state = "RESULTS"
	game.clear_round()
	guards.clear()
	await get_tree().create_timer(.25).timeout
	await get_tree().process_frame
	print("MOVEMENT_CHECK_PASS")
	get_tree().quit()

func check_spacing() -> void:
	var actors = game.live_enemies()
	for i in range(actors.size()):
		for j in range(i+1,actors.size()):
			var offset = actors[i].position-actors[j].position
			if absf(offset.y)>1.5:continue
			var gap = Vector2(offset.x,offset.z).length()
			minimum_spacing = minf(minimum_spacing,gap)
			assert(gap>.55,"Enemy capsules overlapped: "+str(gap))

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
