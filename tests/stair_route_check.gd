extends Node
var game: Node

func _ready() -> void:
	assert(DisplayServer.get_name()!="headless","Route check needs a rendered window for captured movement input")
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	game.invulnerable = 999
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for x in [7.6,-11.0]:
		game.player.position = Vector3(x,.05,0)
		game.player.velocity = Vector3.ZERO
		var points = [Vector3(x,3.1,-9.7)]
		if x<0:points.append(Vector3(-7.7,3.1,-9.7))
		points.append(Vector3(7.6 if x>0 else -7.7,3.1,-14.7))
		for point in points:
			var reached = await walk_to(point)
			if not reached:
				print("ROUTE_BLOCKED target=",point," actual=",game.player.position)
				for i in range(game.player.get_slide_collision_count()):
					var hit = game.player.get_slide_collision(i)
					print("COLLISION at=",hit.get_position()," normal=",hit.get_normal()," body=",hit.get_collider().global_position)
				get_tree().quit(1)
				return
		print("STAIR_ROUTE_PASS ",x)
		points.reverse()
		points.remove_at(0)
		points.append(Vector3(x,.05,0))
		for point in points:
			assert(await walk_to(point),"Reverse stair route blocked: "+str(game.player.position))
		print("STAIR_RETURN_PASS ",x)
	# Low input speed must also pass the colour seam; momentum cannot hide a lip.
	for x in [-7.7,7.6]:
		game.player.position = Vector3(x,3.15,-11.3)
		game.player.velocity = Vector3.ZERO
		assert(await walk_to(Vector3(x,3.1,-14.5),.7))
		assert(await walk_to(Vector3(x,3.1,-11.3),.7))
	print("STAIR_SLOW_SEAMS_PASS")
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.2).timeout
	print("STAIR_ROUTES_PASS")
	get_tree().quit()

func walk_to(target: Vector3, strength: float = 1.0) -> bool:
	for frame in range(300):
		var direction = target-game.player.position
		direction.y = 0
		if direction.length()<.17 and absf(target.y-game.player.position.y)<.16:
			Input.action_release("forward")
			return true
		game.player.rotation.y = atan2(-direction.x,-direction.z)
		Input.action_press("forward",strength)
		await get_tree().physics_frame
	Input.action_release("forward")
	return false
