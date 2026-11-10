extends Node

var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.spawn_time = 999
	var first_spawn: Vector3 = game.arena.get_node(game.arena.respawn_paths[0]).global_position
	var original_forward: Vector3 = -game.arena.player_start().basis.z
	var wall = StaticBody3D.new()
	var blocker = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3,2.6,.35)
	blocker.shape = box
	wall.add_child(blocker)
	game.arena.add_child(wall)
	wall.global_transform = Transform3D(Basis.looking_at(original_forward),first_spawn+original_forward*1.2+Vector3.UP*1.3)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(game.rules.deaths==0)
	assert(game.health==225)
	for frame in range(6):
		game.invulnerable = 0
		game.damage_player()
		assert(game.player.enabled and game.respawn_time==0,"Six standard hits are survivable")
	game.invulnerable = 0
	game.damage_player()
	assert(game.rules.deaths==1 and game.respawn_time==2.0 and not game.player.enabled)
	assert(game.respawn_duration==2.0)
	assert(not game.player.gun.visible)
	var shots = game.rules.shots
	game.shoot()
	game.damage_player(game.MAX_HEALTH)
	assert(game.rules.shots==shots and game.rules.deaths==1)
	await capture("death-wait")
	game.pause_run()
	game._physics_process(1)
	assert(game.respawn_time==2.0)
	game.menu_action("resume")
	assert(not game.player.enabled,"Resume must not re-enable a dead player")
	var start = game.player.position
	var clock = game.rules.elapsed
	Input.action_press("forward")
	for frame in range(119):
		game._physics_process(1.0/60.0)
		await get_tree().physics_frame
		assert(game.respawn_time>0 and not game.player.enabled,"No early respawn")
		assert(game.player.position.is_equal_approx(start),"Cannot move during death wait")
		if frame==59:await capture("death-half")
	Input.action_release("forward")
	game._physics_process(1.0/60.0)
	assert(game.respawn_time==0 and game.player.enabled and game.player.gun.visible)
	assert(game.health==game.MAX_HEALTH and game.ammo==20 and game.rules.deaths==1)
	assert(is_equal_approx(game.rules.elapsed-clock,2.0),"Round clock keeps running during death")
	assert(game.player.global_position.distance_to(first_spawn)<.15)
	assert_clear_view()
	await capture("death-one")
	wall.global_position = first_spawn+Vector3.UP*1.3
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.rules.elapsed = 44.99
	defeat()
	assert(not game.destroy_active and game.respawn_time==2.0)
	for frame in range(119):
		game._physics_process(1.0/60.0)
		assert(not game.player.enabled and game.respawn_duration==2.0)
	game._physics_process(1.0/60.0)
	assert(game.destroy_active and game.rules.deaths==2 and game.respawn_time==0)
	assert(game.player.global_position.distance_to(first_spawn)>1.0,"An obstructed marker is skipped")
	assert_clear_view()
	wall.queue_free()
	await capture("death-two")
	defeat()
	assert(game.respawn_time==1.25 and game.respawn_duration==1.25 and not game.player.enabled)
	for frame in range(74):
		game._physics_process(1.0/60.0)
		assert(game.respawn_time>0 and not game.player.enabled,"No early frenzy respawn")
	game._physics_process(1.0/60.0)
	assert(game.respawn_time==0 and game.player.enabled and game.player.gun.visible)
	# A death near the deadline ends at results; it must not respawn after time is up.
	game.rules.elapsed = 59
	defeat()
	game._physics_process(1)
	assert(game.finale_active and not game.player.enabled)
	game._physics_process(game.rules.finale_duration)
	assert(game.state=="RESULTS" and not game.player.enabled)
	game._physics_process(6)
	assert(game.state=="RESULTS" and game.rules.deaths==4)
	await capture("text-review-results")
	game.start_run()
	assert(game.rules.deaths==0 and game.respawn_time==0 and game.player.gun.visible)
	await capture("death-reset")
	# Starting over during a pending death also clears the entire sequence.
	game.begin_running()
	game.clear_round()
	defeat()
	game.start_run()
	assert(game.rules.deaths==0 and game.respawn_time==0 and game.player.gun.visible)
	game.pause_run()
	await capture("text-review-pause")
	game.menu_action("resume")
	game.state = "TITLE"
	await capture("text-review-title")
	print("RESPAWN_CHECK_PASS: normal 120 ticks, frenzy 75 ticks, phase boundary, clear facing, blocked marker fallback, pause, deadline and restart")
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()

func defeat() -> void:
	game.invulnerable = 0
	game.damage_player(game.MAX_HEALTH)

func assert_clear_view() -> void:
	var camera = game.player.camera
	var ray = PhysicsRayQueryParameters3D.create(camera.global_position,
		camera.global_position-camera.global_basis.z*2.99,game.player.collision_mask)
	assert(game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Respawn camera has a clear forward lane")

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
