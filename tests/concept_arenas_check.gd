extends SceneTree

const TARGETS = {"rain_market":"ServiceShortcut","baggage_below":"BurstCase","snowline":"WeatherScreen"}
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:
			break
	assert(game.nav_ready and game.title_frame_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	for id in game.CONCEPT_SESSIONS:
		await game.select_session(game.CONCEPT_SESSIONS[id],id)
		assert(game.arena.map_id==id and game.nav_ready and game.arena.validate_navigation())
		assert(game.score_record_key()=="score_%s_v1"%id)
		game.start_run()
		game.begin_running()
		assert(game.rules.duration==60.0 and game.grenade_stock==3)
		assert(game.live_enemies().size()==8 and game.live_enemies().filter(func(enemy):return enemy.fast).size()==2)
		game.clear_round()
		game.touch_mode = true
		game.player.rotation.y = 0
		for path in game.arena.route_paths:
			var goal: Vector3 = game.arena.get_node(path).position
			assert(await walk_to(goal),"%s traversal blocked at %s on the way to %s"%[id,game.player.position,goal])
		game.touch_mode = false
		assert(game.arena.frenzy_lights.all(func(light):return not light.visible))
		game.start_run()
		game.begin_running()
		for enemy in game.live_enemies():
			enemy.set_physics_process(false)
		game.player.enabled = false
		game.rules.elapsed = 44.99
		game._physics_process(.01)
		assert(game.destroy_active and is_equal_approx(game.rules.remaining(),15.0))
		assert(game.arena.frenzy_lights.all(func(light):return light.visible))
		var previous: Basis = game.arena.frenzy_lights[0].basis
		game.rules.elapsed = 47.0
		game.arena._process(0)
		assert(previous!=game.arena.frenzy_lights[0].basis)
		if id=="baggage_below":
			assert(game.arena.belts[0].constant_linear_velocity.z<0)
			assert(game.arena.belts[1].constant_linear_velocity.z>0)
			assert(game.arena.belt_lamps.size()==10 and game.arena.belt_lamps[0].visible)
			await check_player_carry()
		if id=="snowline":
			assert(game.arena.deck_light.visible and not is_zero_approx(game.arena.dome.rotation.y))
		var held: Basis = game.arena.frenzy_lights[0].basis
		game.pause_run()
		game.arena._process(0)
		assert(held==game.arena.frenzy_lights[0].basis)
		if id=="baggage_below":
			assert(game.arena.belts.all(func(belt):return belt.constant_linear_velocity.is_zero_approx()))
		game.menu_action("resume")
		game.player.enabled = false
		var prop = game.arena.get_node("Props/"+TARGETS[id])
		var at: Vector3 = prop.world_bounds().get_center()
		prop.ignite_hit(at)
		assert(not prop.collapsed and prop.hits==1)
		prop.ignite_hit(at)
		for _tick in range(38):
			await physics_frame
		assert(prop.collapsed and prop.collision_states.keys().all(func(body):return body.collision_layer==0))
		game.start_run()
		assert(not prop.collapsed and game.arena.frenzy_lights.all(func(light):return not light.visible))
		assert(not game.destroy_active and not game.comedy_toilet)
		game.state = "RESULTS"
		game.menu_action("menu")
		print("NEW_ARENA_PASS ",id," routes, both elevations where applicable, waves, frenzy, destruction and reset")
	game.queue_free()
	await process_frame
	var deadline = Time.get_ticks_msec()+450
	while Time.get_ticks_msec()<deadline:
		await process_frame
	quit()

func walk_to(goal: Vector3) -> bool:
	var nav_map = game.arena.nav.get_navigation_map()
	var route = NavigationServer3D.map_get_path(nav_map,game.player.global_position,goal,true)
	if route.is_empty() or route[-1].distance_to(goal)>.81:
		return false
	for point in route:
		for _tick in range(420):
			var offset: Vector3 = point-game.player.global_position
			var movement = Vector2(offset.x,offset.z)
			if movement.length()<.18:
				break
			game.player.touch_move = (movement*4.0).limit_length()
			await physics_frame
		if Vector2(point.x-game.player.position.x,point.z-game.player.position.z).length()>.48:
			print("Walk stalled at ",game.player.position," towards ",point," on route ",route)
			return false
	game.player.touch_move = Vector2.ZERO
	return game.player.position.distance_to(goal)<.93

func check_player_carry() -> void:
	game.player.enabled = true
	game.player.velocity = Vector3.ZERO
	for i in range(2):
		var belt: StaticBody3D = game.arena.belts[i]
		game.player.position = belt.position+Vector3(0,.14,.5)
		for _tick in range(10):
			await physics_frame
		var before: float = game.player.position.z
		for _tick in range(24):
			await physics_frame
		var advance: float = (game.player.position.z-before)*game.arena.belt_directions[i]
		assert(advance>.25,"Standing player did not ride belt %d (%s)"%[i,advance])
	game.player.enabled = false
