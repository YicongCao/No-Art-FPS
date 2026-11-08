extends SceneTree

const SandgateSession = preload("res://data/sessions/sandgate.tres")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready)
	game.qa_mode = true
	if game.session!=SandgateSession:await game.select_session(SandgateSession)
	assert(game.nav_ready and game.session==SandgateSession and game.arena.validate_navigation())
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	assert(game.rules.duration==60.0 and not game.rules.mission)
	assert(game.grenade_stock==3 and game.live_enemies().size()==8)
	assert(game.live_enemies().filter(func(enemy):return enemy.fast).size()==2)
	assert(game.score_record_key()=="score_sandgate_v1")
	game.achievements.scores.clear()
	game.achievements.merge_score("score",21)
	game.best = 0
	for enemy in game.live_enemies():enemy.set_physics_process(false)
	game.touch_mode = true
	game.player.rotation.y = 0
	var start: Vector3 = game.arena.player_start().origin
	await physics_frame
	var tick = Engine.get_physics_frames()
	assert(await walk_to(Vector3(15.77,0,14.06)))
	var first_enemy = game.live_enemies()[0]
	aim_at(first_enemy.global_position+Vector3.UP*1.7)
	game.shoot()
	assert(first_enemy.dead and game.rules.kills==1)
	var opening_time = float(Engine.get_physics_frames()-tick)/Engine.physics_ticks_per_second
	assert(opening_time<=5.0)
	print("SANDGATE_OPENING_PASS: direct first headshot in %.2f seconds after moving through Long Doors"%opening_time)

	# Keep enemies from physically blocking the timed route checks.
	game.clear_round()
	game.player.rotation.y = 0
	var routes: Array[NodePath] = game.arena.route_paths
	for i in range(1,routes.size()):
		var point: Vector3 = game.arena.get_node(routes[i]).global_position
		assert(await walk_to(point),"Player could not walk to Sandgate tour marker %d"%i)
	assert(await walk_to(start))
	game.touch_mode = false
	print("SANDGATE_WALK_PASS: A Long, pit, A ramp, Short, Mid Doors, B exit, B Window and both tunnel ends")

	# Reinforcement should enter from cover, and the ordinary respawn keeps the spent stock.
	game.player.enabled = false
	game.spawn_time = 0
	game.update_spawns(.2)
	assert(not game.pending_spawn.is_empty(),"No covered reinforcement near Sandgate spawn")
	game.update_spawns(.45)
	assert(not game.live_enemies().is_empty())
	game.player.enabled = true
	game.request_grenade()
	game.update_grenades(.14)
	assert(game.grenade_stock==2 and game.grenades.size()==1)
	game.invulnerable = 0
	game.damage_player(game.MAX_HEALTH)
	assert(game.respawn_time==2.0 and not game.player.enabled)
	game._physics_process(1.0)
	assert(is_equal_approx(game.respawn_time,1.0))
	game._physics_process(1.0)
	assert(game.respawn_time==0 and game.player.enabled and game.grenade_stock==2)

	game.player.enabled = false
	game.player.position = Vector3(8.75,.05,3.1)
	game.player.velocity = Vector3.ZERO
	var gate = game.arena.get_node("Props/a_cross_wall")
	var crates = game.arena.get_node("Props/b_crate_wall")
	var aim = Vector3(10.74,1.37,3.1)
	await physics_frame
	assert(not passage_open())
	shoot_at(aim)
	assert(gate.hits==0)
	game.rules.elapsed = 44.98
	game._physics_process(.01)
	assert(not game.destroy_active)
	game._physics_process(.01)
	assert(game.destroy_active and is_equal_approx(game.rules.remaining(),15.0))
	shoot_at(aim)
	assert(gate.hits==1 and not gate.collapsed)
	shoot_at(aim)
	assert(gate.hits==2 and gate.burn_time>0)
	for _tick in range(41):await physics_frame
	assert(gate.collapsed and passage_open())
	game.player.position = Vector3(-13.33,.05,-3.85)
	await physics_frame
	shoot_at(Vector3(-13.34,1.27,-6.62))
	shoot_at(Vector3(-13.34,1.27,-6.62))
	for _tick in range(20):await physics_frame
	assert(crates.collapsed)
	game.rules.elapsed = 59.99
	game._physics_process(.01)
	assert(game.finale_active)
	game._physics_process(game.rules.finale_duration)
	assert(game.state=="RESULTS")
	assert(game.best>=1 and game.map_best_score("sandgate")==game.best and game.map_best_score("score_attack")==21)
	game.start_run()
	assert(not gate.collapsed and not crates.collapsed and not game.destroy_active and game.grenade_stock==3)
	print("SANDGATE_ROUND_PASS: 60 seconds, replenishment, respawn, grenades, 15-second frenzy, shortcut, finale, record isolation and reset")
	if DisplayServer.get_name()=="headless":
		var deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<deadline:await process_frame
	game.queue_free()
	await process_frame
	quit()

func walk_to(goal: Vector3) -> bool:
	var nav = game.arena.nav.get_navigation_map()
	var route = NavigationServer3D.map_get_path(nav,game.player.global_position,goal,true)
	if route.is_empty() or route[-1].distance_to(goal)>.8:return false
	for point in route:
		for _tick in range(160):
			var offset: Vector3 = point-game.player.global_position
			var direction = Vector2(offset.x,offset.z)
			if direction.length()<.24:break
			game.player.touch_move = (direction*4.5).limit_length()
			await physics_frame
		if Vector2(point.x-game.player.position.x,point.z-game.player.position.z).length()>.45:
			print("WALK_BLOCKED ",game.player.position," toward ",point)
			return false
	game.player.touch_move = Vector2.ZERO
	return game.player.position.distance_to(goal)<.90

func aim_at(target: Vector3) -> void:
	var direction = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch
	game.player.crosshair_offset = Vector2.ZERO

func shoot_at(target: Vector3) -> void:
	aim_at(target)
	game.fire_time = 0
	game.shoot()

func passage_open() -> bool:
	var ray = PhysicsRayQueryParameters3D.create(Vector3(8.8,1.3,3.1),Vector3(12.1,1.3,3.1),1)
	return game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
