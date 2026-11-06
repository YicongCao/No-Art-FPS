extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	game.invulnerable = 999
	assert(game.arena.palms.size()==6 and game.arena.loungers.size()==3)
	for target in [Vector3(-4,3.1,-20),Vector3(6,3.1,-20),Vector3(1,3.1,-22.5),Vector3(1,2.62,-18)]:
		var path = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),Vector3(0,0,10.5),target,true)
		assert(path.size()>1 and path[-1].distance_to(target)<.7,"Terrace path disconnected: "+str(target))
	print("TERRACE_NAV_LOOP_POOL_PASS")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Both outer wings used to have a hole between the old landing and new terrace.
	for x in [-8.3,7.7]:
		for direction in [-1,1]:
			game.player.position = Vector3(x,3.15,-11.3 if direction==-1 else -14.2)
			game.player.velocity = Vector3.ZERO
			game.player.rotation.y = 0 if direction==-1 else PI
			Input.action_press("forward")
			for frame in range(29):
				await get_tree().physics_frame
				assert(game.player.position.y>3.0,"Landing/terrace seam must support every step")
			Input.action_release("forward")
			assert(game.player.position.z<-13.6 if direction==-1 else game.player.position.z>-11.9)
	print("TERRACE_BOTH_SEAMS_PASS")
	# Walk from the stair landing into the terrace, then down and out of the pool.
	game.player.position = Vector3(-4,3.15,-11)
	game.player.velocity = Vector3.ZERO
	game.player.rotation.y = 0
	Input.action_press("forward")
	await get_tree().create_timer(1.35).timeout
	Input.action_release("forward")
	assert(game.player.position.z<-19 and game.player.position.y>2.9,"Landing route must reach terrace")
	game.player.position = Vector3(1,3.15,-13.5)
	game.player.velocity = Vector3.ZERO
	Input.action_press("forward")
	await get_tree().create_timer(.65).timeout
	Input.action_release("forward")
	assert(game.player.position.z<-16 and game.player.position.y<2.8 and game.player.position.y>2.4,"Pool has a walkable shallow bottom")
	game.player.rotation.y = PI
	Input.action_press("forward")
	await get_tree().create_timer(1.1).timeout
	Input.action_release("forward")
	print("POOL_EXIT ",game.player.position)
	assert(game.player.position.z>-14.5 and game.player.position.y>2.95,"Pool ramp must allow exit without jumping")
	print("TERRACE_WALK_POOL_EXIT_PASS")
	# A trunk is solid; broad leaves remain above the walking area.
	var palm = game.arena.palms[0]
	game.player.position = palm.position+Vector3(0,.05,2)
	game.player.rotation.y = 0
	game.player.velocity = Vector3.ZERO
	Input.action_press("forward")
	await get_tree().create_timer(.5).timeout
	Input.action_release("forward")
	assert(game.player.position.z>palm.position.z+.45,"Palm trunk must stop the player")
	print("TERRACE_PALM_COLLISION_PASS")
	game.player.enabled = false
	game.set_physics_process(false)
	game.rules.elapsed = 13
	game.ammo = 16
	await shot("terrace-seam",Vector3(-9.9,4.75,-9.6),Vector3(-5.5,3.1,-14.3))
	await shot("pool-terrace",Vector3(-6,4.75,-12.9),Vector3(1.5,3.4,-18.5))
	await shot("pool-loungers",Vector3(3,4.75,-12.5),Vector3(-4.5,3.7,-18.5))
	await shot("pool-entry",Vector3(1,4.75,-13.7),Vector3(1,3,-18))
	await shot("palms-yard",Vector3(-15,1.7,17),Vector3(-22,3,4))
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	print("TERRACE_CHECK_PASS")
	get_tree().quit()

func shot(filename: String, eye: Vector3, target: Vector3) -> void:
	if DisplayServer.get_name()=="headless":return
	game.player.position = eye-Vector3(0,1.65,0)
	var dir = eye.direction_to(target)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.pitch = asin(dir.y)
	await get_tree().create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
