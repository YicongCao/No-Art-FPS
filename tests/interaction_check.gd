extends Node

var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	# Synthetic movement must not inherit OS mouse deltas when capture starts.
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Physically walk up both ramps, using normal movement and collision.
	for x in [-11.0,7.6]:
		game.player.position = Vector3(x,.05,-.5)
		game.player.velocity = Vector3.ZERO
		game.player.rotation.y = 0
		Input.action_press("forward")
		await get_tree().create_timer(1.5).timeout
		Input.action_release("forward")
		assert(game.player.position.y>2.7,"Ramp must be climbable: "+str(x)+" position "+str(game.player.position))
		print("QA_RAMP_PASS ",x," ",game.player.position)
	game.player.reset_position()
	var clock_before = game.rules.elapsed
	game.pause_run()
	await get_tree().create_timer(.25).timeout
	assert(game.rules.elapsed==clock_before,"Pause freezes the round clock")
	game.state = "RUNNING"
	game.player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game.ammo = 3
	game.reload_weapon()
	assert(game.reload_time>0)
	await get_tree().create_timer(1.0).timeout
	assert(game.ammo==20 and game.reload_time<=0)
	print("QA_PAUSE_RELOAD_PASS")
	# Head and body rays use the live physics shapes, not a direct damage shortcut.
	for head in [true,false]:
		var enemy = game.spawn_enemy(Vector3(0,0,5),false)
		enemy.rotation.y = PI
		enemy.set_physics_process(false)
		await get_tree().physics_frame
		var before = game.rules.kills
		for i in range(1 if head else 3):
			aim(enemy.position+Vector3(0,1.7 if head else 1.1,0))
			game.fire_time = 0
			game.shoot()
			if not head and i<2:
				assert(game.rules.kills==before and enemy.health==2-i)
				assert(enemy.visual.rotation.x>0 and enemy.armor_hit.get_shader_parameter("flash")>0)
				if i==0:await capture("body-hit-flash")
				enemy.update_body_hit(enemy.BODY_HIT_DURATION)
				assert(enemy.visual.rotation.x==0 and enemy.armor_hit.get_shader_parameter("flash")==0)
				assert(enemy.armor_hit.get_shader_parameter("damage_level")==i+1)
				if i==1:
					await get_tree().create_timer(.18).timeout
					await capture("body-hit-damage")
		assert(game.rules.kills==before+1,"Raycast damage must kill exactly once")
		enemy.take_hit(true)
		assert(game.rules.kills==before+1)
		enemy.queue_free()
		await get_tree().physics_frame
	print("QA_HEAD_BODY_DUPLICATE_PASS")
	assert(game.touch_body_one_shot,"Touch body shots default to one hit")
	for enabled in [true,false]:
		var enemy = game.spawn_enemy(Vector3(0,0,5),enabled)
		enemy.set_physics_process(false)
		await get_tree().physics_frame
		if not enabled:
			game.state = "PAUSED"
			game.touch_mode = true
			game.menu_action("touch_body_shots")
			game.touch_mode = false
			game.state = "RUNNING"
		assert(game.touch_body_one_shot==enabled)
		var before = game.rules.kills
		var headshots = game.rules.headshots
		for shot in range(1 if enabled else 3):
			aim(enemy.position+Vector3(0,1.1,0))
			game.fire_time = 0
			game.touch_mode = true
			game.shoot()
			game.touch_mode = false
			assert(enemy.dead==(enabled or shot==2))
		assert(game.rules.kills==before+1 and game.rules.headshots==headshots)
		enemy.queue_free()
		await get_tree().physics_frame
	print("QA_TOUCH_BODY_PASS: default one-hit, pause setting, three hits with assist off, normal kill scoring")
	game.player.position = Vector3(5,.05,8)
	var blocked = game.spawn_enemy(Vector3(5,0,-5),false)
	blocked.set_physics_process(false)
	await get_tree().physics_frame
	aim(blocked.position+Vector3(0,1.7,0))
	game.fire_time = 0
	game.shoot()
	assert(blocked.health==3,"A solid container must block shots")
	print("QA_WALL_BLOCK_PASS")
	var elapsed_before = game.rules.elapsed
	for i in range(5):
		game.invulnerable = 0
		game.damage_player()
	assert(game.respawn_time>0 and not game.player.enabled)
	await get_tree().create_timer(3.2).timeout
	assert(game.player.enabled and game.health==game.MAX_HEALTH and game.rules.elapsed>elapsed_before)
	print("QA_RESPAWN_PASS")
	game.clear_round()
	await get_tree().process_frame
	await get_tree().process_frame
	var baseline = get_tree().get_node_count()
	for i in range(10):
		game.start_run()
		game.begin_running()
		game.clear_round()
		await get_tree().process_frame
		await get_tree().process_frame
	assert(get_tree().get_node_count()<=baseline+3,"Restart must not retain enemies or effects")
	print("QA_TEN_RESTARTS_PASS nodes=",get_tree().get_node_count()," baseline=",baseline)
	# Reproducible engine renders with staged actors and score values.
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.spawn_time = 999
	game.player.reset_position()
	game.player.rotation.y = -.04
	game.player.pitch = -.03
	for p in [Vector3(-4.8,0,1.0),Vector3(1.3,0,-4.8),Vector3(11,0,0)]:
		var enemy = game.spawn_enemy(p,false)
		enemy.set_physics_process(false)
		enemy.look_at(Vector3(game.player.position.x,enemy.position.y,game.player.position.z))
	game.rules.elapsed = 13
	game.rules.kills = 12
	game.ammo = 16
	await get_tree().process_frame
	await capture("showcase-ground")
	game.player.position = Vector3(-8.5,3.2,-9.5)
	game.player.rotation.y = -2.65
	game.player.pitch = -.18
	await get_tree().process_frame
	await capture("showcase-platform")
	print("QA_INTERACTION_PASS; showcase values are staged for visual review")
	get_tree().quit()

func aim(target: Vector3) -> void:
	var dir = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-dir.x,-dir.z)
	game.player.pitch = asin(dir.y)
	game.player.camera.rotation.x = game.player.pitch

func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
