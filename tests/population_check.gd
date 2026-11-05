extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	assert(game.live_enemies().size()==8)
	assert(game.zone_population("warehouse")==2 and game.zone_population("deck")==2)
	for point in game.arena.spawn_points:
		var path = NavigationServer3D.map_get_path(game.arena.nav.get_navigation_map(),point,Vector3(0,0,10.5),true)
		assert(path.size()>1 and path[-1].distance_to(Vector3(0,0,10.5))<1,"Disconnected spawn: "+str(point))
	print("POPULATION_OPENING_NAV_PASS")
	# Let real navigation move the patrols for longer than one patrol leg.
	await get_tree().create_timer(12).timeout
	for enemy in game.live_enemies():
		if enemy.home_zone!="yard":
			assert(game.arena.enemy_zone(enemy.position)==enemy.home_zone,"Patrol abandoned its floor: "+str(enemy.position))
	print("POPULATION_PATROL_PASS")
	# Kill all guards, face away, and exercise the actual delayed reinforcement path.
	game.player.position = Vector3(0,.05,10.5)
	game.player.rotation.y = PI
	await get_tree().physics_frame
	for enemy in game.live_enemies():
		if enemy.home_zone!="yard":enemy.take_hit(true)
	for i in range(400):
		game.update_spawns(.05)
		await get_tree().physics_frame
	assert(game.zone_population("warehouse")==2 and game.zone_population("deck")==2)
	assert(game.live_enemies().size()==8)
	print("POPULATION_REINFORCEMENT_PASS")
	for elapsed in [25.0,45.0]:
		game.rules.elapsed = elapsed
		for i in range(400):
			game.update_spawns(.05)
			await get_tree().physics_frame
		assert(game.live_enemies().size()==game.population_target())
		assert(game.zone_population("yard")==game.population_target()-4)
	print("POPULATION_RAMP_CAP_PASS")
	# A warning cannot materialize a close enemy, even if it was queued earlier.
	for enemy in game.live_enemies():
		if enemy.home_zone=="yard":
			enemy.take_hit(true)
			break
	var count = game.live_enemies().size()
	game.pending_spawn = {"pos":game.player.position+Vector3(1,0,0),"delay":0.0}
	game.update_spawns(.1)
	assert(game.live_enemies().size()==count and game.pending_spawn.is_empty())
	game.player.position = Vector3(18,.05,20)
	game.player.rotation.y = 0
	await get_tree().physics_frame
	var visible_point = Vector3(18,0,10)
	var sight = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,visible_point+Vector3.UP,1)
	assert(game.get_world_3d().direct_space_state.intersect_ray(sight).is_empty())
	game.pending_spawn = {"pos":visible_point,"delay":0.0}
	game.update_spawns(.1)
	assert(game.live_enemies().size()==count and game.pending_spawn.is_empty())
	print("POPULATION_SAFE_SPAWN_PASS")
	game.state = "RESULTS"
	game.clear_round()
	# Let the audio thread retire the final headshot voice before engine shutdown.
	await get_tree().create_timer(.2).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	print("POPULATION_CHECK_PASS")
	get_tree().quit()
