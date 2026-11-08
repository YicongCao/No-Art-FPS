extends SceneTree

const OfficeSession = preload("res://data/sessions/bb_office.tres")
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
	game.qa_mode = true
	if game.session != OfficeSession:
		await game.select_session(OfficeSession)
	assert(game.nav_ready and game.arena.validate_navigation())
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	game.start_run()
	game.begin_running()
	assert(game.rules.duration == 60.0 and not game.rules.mission)
	assert(game.grenade_stock == 3 and game.live_enemies().size() == 8)
	assert(game.live_enemies().filter(func(enemy):return enemy.fast).size() == 2)
	assert(game.score_record_key() == "score_bb_office_v1")
	game.achievements.scores.clear()
	game.achievements.merge_score("score", 21)
	game.best = 0
	for enemy in game.live_enemies():
		enemy.set_physics_process(false)
	await physics_frame
	aim_at(game.live_enemies()[0].global_position+Vector3.UP*1.69)
	game.shoot()
	assert(game.rules.kills == 1, "The first target is visible from the office start")
	game.clear_round()

	var office = game.arena
	var desks = office.get_node("Props").get_children().filter(func(node):
		return node.name.begins_with("Programmer") or node.name.begins_with("PM") or node.name.begins_with("BackDesk")
	)
	assert(desks.size()==48 and office.power_faults.size()==12)
	assert(not office.arc.visible and not office.arc_light.visible)
	game.touch_mode = true
	game.player.rotation.y = 0
	for point in [Vector3(22,.05,10), Vector3(22,.05,-9), Vector3(-22,.05,-9),
			Vector3(-22,.05,10), Vector3(-6,.05,13.5), Vector3(0,.05,18.4),
			Vector3(3.85,.05,-15.5),Vector3(6.6,.05,1.1),Vector3(-6.5,.05,1.1),
			Vector3(-2.1,.05,6.6),Vector3(2.1,.05,6.6)]:
		assert(await walk_to(point), "Office walk blocked at %s toward %s" % [game.player.position,point])
	game.touch_mode = false

	for x in [-17, 17]:
		var index = 0 if x<0 else 1
		var door = office.get_node("Props/ManagerDoor%d"%index)
		var target = Vector3(x,1.37,-12.1)
		place_player(Vector3(x,.05,-10.35))
		await physics_frame
		assert(not passage_open(x))
		shoot_at(target)
		assert(not door.collapsed and door.door_hits == 1)
		shoot_at(target)
		assert(door.collapsed and not game.destroy_active)
		await physics_frame
		assert(passage_open(x))
		game.touch_mode = true
		game.player.rotation.y = 0
		game.player.touch_move = Vector2.UP
		for _tick in range(29):
			await physics_frame
		assert(game.player.position.z < -12.8, "The player can walk through a breached manager door")
		game.player.touch_move = Vector2.ZERO
		game.touch_mode = false

	place_player(Vector3(0,.05,1.05))
	await physics_frame
	shoot_at(Vector3(-1.25,1.27,-1.57))
	assert(game.effects.get_children().any(func(effect):return str(effect.name).begins_with("OfficeImpact")))
	assert(office.sweeps.all(func(spot):return not spot.visible))
	game.rules.elapsed = 44.99
	game._physics_process(.01)
	assert(game.destroy_active and is_equal_approx(game.rules.remaining(),15.0))
	var seen_colors = {}
	for spot in office.sweeps:
		assert(spot.visible and not seen_colors.has(spot.light_color))
		assert(spot.get_node("Shaft").material_override.get_shader_parameter("tint") == spot.light_color)
		seen_colors[spot.light_color] = true
	assert(seen_colors.size() == 6)
	var previous: Basis = office.sweeps[0].basis
	game.rules.elapsed = 46.0
	office._process(0)
	assert(previous != office.sweeps[0].basis)
	assert(office.arc.visible and office.arc_light.visible and office.arc_mesh.get_surface_count()==1)
	assert(game.effects.get_children().any(func(effect):return str(effect.name).begins_with("OfficePowerSparks")))
	var pulse: int = office.last_fault
	game.pause_run()
	office._process(0)
	assert(office.last_fault==pulse and office.arc.visible)
	game.menu_action("resume")
	game.player.enabled = false
	var computer = office.get_node("Props/Programmer10R")
	place_player(Vector3(-12.75,.05,1.35))
	await physics_frame
	var screen = Vector3(-12.75,1.23,-1.58)
	shoot_at(screen)
	assert(computer.hits == 1 and not computer.collapsed)
	shoot_at(screen)
	assert(computer.hits == 2)
	for _tick in range(18):
		await physics_frame
	assert(computer.collapsed)
	game.rules.elapsed = 59.99
	game._physics_process(.01)
	assert(game.finale_active)
	game._physics_process(game.rules.finale_duration)
	assert(game.state == "RESULTS")
	assert(game.map_best_score("bb_office") >= 1 and game.map_best_score("score_attack") == 21)
	game.start_run()
	assert(not computer.collapsed and not office.get_node("Props/ManagerDoor0").collapsed)
	assert(game.grenade_stock == 3 and not game.destroy_active and office.sweeps.all(func(spot):return not spot.visible))
	assert(not office.arc.visible and not office.arc_light.visible and office.last_fault==-1)
	print("BB_OFFICE_PASS: connected floor, two normal-phase breaches, props, six frenzy sweeps, finale, isolated record and reset")
	var deadline = Time.get_ticks_msec()+450
	while Time.get_ticks_msec() < deadline:
		await process_frame
	game.queue_free()
	await process_frame
	quit()

func walk_to(goal: Vector3) -> bool:
	var navigation_map = game.arena.nav.get_navigation_map()
	var route = NavigationServer3D.map_get_path(navigation_map,game.player.global_position,goal,true)
	if route.is_empty() or route[-1].distance_to(goal) > .8:
		return false
	for point in route:
		for _tick in range(160):
			var offset: Vector3 = point-game.player.global_position
			var direction = Vector2(offset.x,offset.z)
			if direction.length() < .24:
				break
			game.player.touch_move = (direction*4.5).limit_length()
			await physics_frame
		if Vector2(point.x-game.player.position.x,point.z-game.player.position.z).length() > .45:
			return false
	game.player.touch_move = Vector2.ZERO
	return game.player.position.distance_to(goal) < .90

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

func place_player(at: Vector3) -> void:
	game.player.position = at
	game.player.velocity = Vector3.ZERO

func passage_open(x: float) -> bool:
	var query = PhysicsRayQueryParameters3D.create(Vector3(x,1.37,-11.1),Vector3(x,1.37,-13.3),1)
	return game.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
