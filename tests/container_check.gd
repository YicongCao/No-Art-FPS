extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	var room = game.arena.containers[0]
	var guard = room.occupant
	assert(is_instance_valid(guard) and not room.opening)
	var start = guard.position
	game.player.position = room.to_global(Vector3(0,0,3))
	await get_tree().create_timer(.3).timeout
	assert(not room.opening and guard.position.distance_to(start)<.1,"Side wall must not trigger the door or release guard")
	game.player.position = room.to_global(Vector3(5,.05,0))
	await get_tree().physics_frame
	aim(room.to_global(Vector3(0,1.7,0)))
	await capture("container-closed")
	await get_tree().create_timer(.15).timeout
	assert(room.opening and room.progress>0)
	game.state = "PAUSED"
	var held = room.progress
	await get_tree().create_timer(.25).timeout
	assert(room.progress==held,"Door animation must pause")
	game.state = "RUNNING"
	await get_tree().create_timer(.7).timeout
	assert(room.progress==1)
	await capture("container-open")
	for frame in range(180):await get_tree().physics_frame
	assert(guard.position.distance_to(start)>1.5,"Released guard must navigate out")
	print("CONTAINER_AUTO_GUARD_PAUSE_PASS")
	game.clear_round()
	# Player physically walks through the open door into the hollow container.
	game.state = "RUNNING"
	game.player.position = room.to_global(Vector3(5,.05,0))
	game.player.velocity = Vector3.ZERO
	game.player.rotation.y = room.rotation.y+PI/2
	await get_tree().create_timer(.8).timeout
	game.player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.action_press("forward")
	await get_tree().create_timer(.65).timeout
	Input.action_release("forward")
	assert(room.to_local(game.player.position).x<2.5,"Player must walk into open container")
	game.player.enabled = false
	game.start_run()
	for item in game.arena.containers:
		assert(item.progress==0 and not item.opening)
		for shape in item.shapes:assert(not shape.disabled)
	print("CONTAINER_ENTRY_RESET_PASS")
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	# Every ground-level container entrance must connect to its interior.
	for item in game.arena.containers:
		var path = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),item.to_global(Vector3(0,0,0)),item.to_global(Vector3(4.5,0,0)),true)
		assert(path.size()>1,"Disconnected container interior")
		game.player.position = item.to_global(Vector3(4,.05,0))
		await get_tree().create_timer(.8).timeout
		assert(item.progress==1,"Door must auto-open: "+str(item.position))
	print("CONTAINER_ALL_DOORS_PASS")
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	print("CONTAINER_CHECK_PASS")
	get_tree().quit()

func aim(target: Vector3) -> void:
	var dir = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.pitch = asin(dir.y)

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
