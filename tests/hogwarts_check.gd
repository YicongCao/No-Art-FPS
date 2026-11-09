extends SceneTree

var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.nav_ready and game.title_frame_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	await game.select_session("res://data/sessions/hogwarts.tres","hogwarts")
	var arena = game.arena
	assert(game.nav_ready and arena.map_id=="hogwarts" and arena.validate_navigation())
	game.start_run()
	game.begin_running()
	assert(game.rules.duration==60 and game.rules.destroy_duration==15 and game.grenade_stock==3)
	assert(game.live_enemies().size()==8)
	assert(game.live_enemies().filter(func(enemy):return enemy.fast).size()==2)
	game.clear_round()
	game.touch_mode = true
	game.player.rotation.y = 0
	game.player.enabled = true
	for path in arena.route_paths:
		var goal: Vector3 = arena.get_node(path).global_position
		assert(await walk_to(goal),"Blocked on route to %s from %s"%[goal,game.player.global_position])
	game.touch_mode = false
	game.start_run()
	game.begin_running()
	game.player.enabled = false
	game.reduced_motion = false
	assert(arena.house_cloth.size()==4)
	arena._process(0)
	var cloth := float(arena.house_cloth[0].get_shader_parameter("breeze"))
	game.rules.elapsed = 44.99
	game._physics_process(.02)
	assert(game.destroy_active and arena.frenzy_lights.size()==5 and arena.frenzy_lights[0].visible)
	arena._process(0)
	assert(arena.sky_paint.get_shader_parameter("frenzy")==1.0)
	assert(float(arena.house_cloth[0].get_shader_parameter("breeze"))!=cloth)
	game.pause_run()
	cloth = float(arena.house_cloth[0].get_shader_parameter("breeze"))
	arena._process(.25)
	assert(float(arena.house_cloth[0].get_shader_parameter("breeze"))==cloth)
	game.menu_action("resume")
	var prop = arena.structures[0]
	prop.ignite_hit(prop.position+Vector3.UP*.5)
	assert(not prop.collapsed)
	prop.ignite_hit(prop.position+Vector3.UP*.5)
	for _tick in range(45):await physics_frame
	assert(prop.collapsed)
	var score: int = game.rules.kills
	game.rules.elapsed = 59.99
	game._physics_process(.02)
	assert(game.finale_active and game.rules.kills==score)
	game._physics_process(1.01)
	assert(game.state=="RESULTS")
	for mode in ["comedy","roach"]:
		game.comedy_mode = mode
		game.start_run()
		assert(is_instance_valid(game.comedy_toilet) and not prop.collapsed and not arena.frenzy_lights[0].visible)
		assert(arena.sky_paint.get_shader_parameter("frenzy")==0.0)
	print("HOGWARTS_PASS: physical loop, stairs, side ramp, pavilion, round and frenzy, cover, finale, both comedy modes")
	game.music.stop()
	var settle_at := Time.get_ticks_msec()+450
	while Time.get_ticks_msec()<settle_at:await process_frame
	game.queue_free()
	await process_frame
	quit()

func walk_to(goal: Vector3) -> bool:
	var nav_map = game.arena.nav.get_navigation_map()
	var route = NavigationServer3D.map_get_path(nav_map,game.player.global_position,goal,true)
	if route.is_empty() or route[-1].distance_to(goal)>.81:
		return false
	for point in route:
		for _tick in range(380):
			var offset: Vector3 = point-game.player.global_position
			var movement = Vector2(offset.x,offset.z)
			if movement.length()<.18:break
			game.player.touch_move = (movement*4.0).limit_length()
			await physics_frame
		if Vector2(point.x-game.player.position.x,point.z-game.player.position.z).length()>.48:
			return false
	game.player.touch_move = Vector2.ZERO
	return game.player.position.distance_to(goal)<.93
