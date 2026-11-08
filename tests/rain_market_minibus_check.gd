extends SceneTree

var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	await game.select_session(game.CONCEPT_SESSIONS["rain_market"],"rain_market")
	assert(game.nav_ready and game.arena.validate_navigation())
	game.start_run()
	game.begin_running()
	game.clear_round()
	# Exercise the case where the ordinary cover-based director finds no spawn.
	game.spawn_time = 999
	game.player.enabled = false
	game.player.position = Vector3(0,.06,19)
	game.invulnerable = 999
	game.rules.elapsed = 31.0
	game._physics_process(1.0/60.0)
	assert(game.live_enemies().is_empty())
	game.rules.elapsed = 31.9
	var wave: Array[Node3D] = []
	for _tick in range(12*60):
		game._physics_process(1.0/60.0)
		var actors: Array = game.live_enemies()
		assert(actors.size()<=game.population_target())
		if wave.size()<3:
			for actor in actors:
				if actor not in wave:
					assert(actor.position.distance_to(game.arena.minibus_entry.position)<.20)
					wave.append(actor)
		await physics_frame
	assert(wave.size()==3 and wave[0].fast and not wave[1].fast and not wave[2].fast)
	assert(wave.all(func(actor):return actor.position.z>-20.0),"The first wave must leave the bus stop")
	assert(wave.all(func(actor):return actor.position.distance_to(game.player.position)<19.0),"The first wave must reach combat range on the lower slope")
	print("MINIBUS_ROUTE_PASS: three passengers disembarked and advanced to the lower market")
	game.pause_run()
	var door_x: float = game.arena.minibus_door.position.x
	var occupied: int = game.live_enemies().size()
	game._physics_process(1.0)
	assert(game.live_enemies().size()==occupied and game.arena.minibus_door.position.x==door_x)
	game.menu_action("resume")
	for actor in game.live_enemies():
		actor.take_damage(actor.MAX_HEALTH)
	game.rules.elapsed = 49.99
	game._physics_process(.02)
	assert(game.destroy_active and not game.live_enemies().is_empty(),"An empty market must refill during frenzy")
	game.start_run()
	assert(is_equal_approx(game.arena.minibus_door.position.x,game.arena.minibus_closed_x))
	assert(game.arena.minibus_seats==0 and game.arena.minibus_next_spawn==game.arena.MINIBUS_START)
	game.state = "RESULTS"
	game.menu_action("menu")
	wave.clear()
	game.queue_free()
	await process_frame
	var deadline = Time.get_ticks_msec()+450
	while Time.get_ticks_msec()<deadline:
		await process_frame
	print("MINIBUS_PASS: late dispatch, population cap, frenzy refill, pause and reset")
	quit()
