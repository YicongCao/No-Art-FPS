extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 120
	Engine.time_scale = 3
	game.player.set_process_unhandled_input(false)
	game.start_run();game.begin_running()
	game.invulnerable = 999
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not "--live-patrols" in OS.get_cmdline_user_args():
		for actor in game.enemies.get_children():actor.set_physics_process(false)
	if "--expanded-loop" in OS.get_cmdline_user_args():
		for target in [Vector3(-80,.05,-10),Vector3(-80,-3.45,34),Vector3(-78,-3.45,48),Vector3(-27,-3.45,34),Vector3(-38,2.55,8)]:
			var detour = NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,game.player.global_position,target,true)
			assert(detour.size()>1 and detour[-1].distance_to(target)<1,"Expanded loop not connected: "+str(target))
			for point in detour:assert(await walk(point),"Expanded loop blocked: target="+str(target)+" point="+str(point)+" player="+str(game.player.global_position))
		print("DUST_EXPANDED_LOOP_PASS: long/tunnel/B/mid/short actual walking")
	var visits = []
	for index in [1,2,0]:
		var objective = game.arena.objectives[index]
		var stand = objective.global_position+Vector3(0,-.4,1)
		var path = NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,game.player.global_position,stand,true)
		assert(path.size()>1)
		for point in path:
			assert(await walk(point),"Blocked path to "+objective.objective_id+" at "+str(game.player.global_position)+" target="+str(point))
		Input.action_release("forward")
		await get_tree().create_timer(.3).timeout
		assert(objective.available(),"Walking did not reach defuse range")
		var direction = game.player.camera.global_position.direction_to(objective.global_position)
		game.player.rotation.y = atan2(-direction.x,-direction.z)
		game.player.pitch = asin(direction.y)
		Input.action_press("interact")
		for tick in range(400):
			if objective.defused:break
			await get_tree().physics_frame
		assert(objective.defused,"Hold input did not defuse "+objective.objective_id)
		Input.action_release("interact")
		visits.append({"objective":objective.objective_id,"elapsed":game.rules.elapsed})
		await capture("mission-route-"+objective.objective_id)
	assert(game.state=="RESULTS" and game.rules.outcome=="SUCCESS" and game.rules.elapsed<180)
	await capture("mission-route-success")
	print("MISSION_ROUTE_PASS: actual collision movement and held input, 3x simulation, guard state controlled by --live-patrols; invulnerable QA, ",JSON.stringify(visits)+" shots="+str(game.rules.shots)+" kills="+str(game.rules.kills))
	game.state = "RESULTS";game.clear_round()
	await get_tree().create_timer(.2).timeout
	get_tree().quit()

func walk(point: Vector3) -> bool:
	for tick in range(900):
		var direction = point-game.player.global_position
		direction.y = 0
		if direction.length()<.22 and absf(point.y-game.player.global_position.y)<1:return true
		if "--live-patrols" in OS.get_cmdline_user_args():auto_shoot()
		game.player.rotation.y = atan2(-direction.x,-direction.z)
		Input.action_press("forward")
		await get_tree().physics_frame
	Input.action_release("forward")
	return false

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	for frame in range(6):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+name+".png")

func auto_shoot() -> void:
	for enemy in game.live_enemies():
		if enemy.global_position.distance_to(game.player.global_position)>28:continue
		var point = enemy.global_position+Vector3.UP*1.7
		var ray = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,point,1)
		if not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
		var aim = game.player.camera.global_position.direction_to(point)
		game.player.rotation.y = atan2(-aim.x,-aim.z)
		game.player.pitch = asin(aim.y)
		game.player.camera.rotation.x = game.player.pitch
		game.shoot()
		game.player.pitch = 0
		return
