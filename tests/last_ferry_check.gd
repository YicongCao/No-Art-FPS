extends SceneTree

var game: Node3D
var ferry: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready and game.session.session_id=="last_ferry")
	game.qa_mode = true
	ferry = game.arena
	assert(ferry.validate_map() and ferry.validate_navigation())
	assert(game.opening.filter(func(actor):return actor.fast).size()==2)
	assert(game.world_environment.environment==ferry.environment_override)
	for target in [ferry.get_node("Lighthouse").global_position+Vector3.UP*11,
			ferry.get_node("FarPier").global_position+Vector3.UP*3]:
		assert(game.player.camera.is_position_in_frustum(target),"An offshore landmark is outside the opening view")

	if DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute("res://artifacts/local")
		game.hud.title_frame.get_image().save_png("res://artifacts/local/ferry-opening.png")
		await overview()
		await tour()

	game.start_run()
	game.begin_running()
	game.invulnerable = 999
	assert(game.live_enemies().size()==8)
	var spawned = false
	var tested_cover = false
	var revived = false
	var finale = false
	for _frame in range(3900):
		await physics_frame
		var elapsed: float = game.rules.elapsed
		spawned = spawned or game.live_enemies().size()>8
		if is_equal_approx(elapsed,10.0):
			game.invulnerable = 0
			game.damage_player(999)
			assert(game.respawn_time>0)
		if elapsed>13 and elapsed<16 and game.respawn_time<=0:
			revived = game.player.enabled
			game.invulnerable = 999
		if game.destroy_active and not tested_cover:
			assert(is_equal_approx(elapsed,45.0))
			var cover = ferry.get_node("PortCrates")
			var target: Vector3 = cover.world_bounds().get_center()
			var origin = target+Vector3.BACK*3
			var query = PhysicsRayQueryParameters3D.create(origin,target,1)
			var hit = game.get_world_3d().direct_space_state.intersect_ray(query)
			assert(not hit.is_empty() and hit.collider.get_meta("structure")==cover)
			game.resolve_shot(hit,origin,target,true)
			assert(cover.hits==1 and not cover.collapsed)
			game.resolve_shot(hit,origin,target,true)
			for _tick in range(18):await physics_frame
			assert(cover.collapsed and hit.collider.collision_layer==0)
			tested_cover = true
		if game.finale_active:finale = game.rules.remaining()==0
		if game.state=="RESULTS":break
	assert(game.rules.elapsed==60 and game.state=="RESULTS")
	assert(spawned and tested_cover and revived and finale)
	assert(ferry.get_node("ForeCrates").collapsed and ferry.get_node("Catwalk").visible)
	game.start_run()
	assert(not ferry.get_node("PortCrates").collapsed)
	print("LAST_FERRY_PASS: reachable markers, both landmarks, 60-second round, replenishment, respawn, two-hit scenery, finale and reset")
	game.state = "RESULTS"
	game.clear_round()
	if DisplayServer.get_name()=="headless":
		var audio_deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<audio_deadline:await process_frame
	quit()

func overview() -> void:
	game.hud.hide()
	game.player.gun.hide()
	var camera = Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(36,49,39)
	camera.look_at(Vector3(0,0,-2))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 58
	camera.make_current()
	await capture("ferry-overview")
	game.player.camera.make_current()
	camera.queue_free()
	game.player.gun.show()
	game.hud.show()

func tour() -> void:
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = true
	game.player.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for waypoint in ferry.route_paths:
		var point: Vector3 = ferry.get_node(waypoint).global_position
		assert(await walk_to(point),"Blocked ferry route %s at %s" % [waypoint,game.player.position])
		if waypoint.get_name(1)=="Crossing3":await capture("ferry-catwalk")
	game.set_physics_process(true)
	print("FERRY_TOUR_PASS: two side lanes, bow and stern, both slopes and mast platform")

func walk_to(target: Vector3) -> bool:
	var map = ferry.get_world_3d().navigation_map
	var path = NavigationServer3D.map_get_path(map,game.player.position,target,true)
	if path.is_empty():return false
	for point in path:
		for _tick in range(270):
			var offset: Vector3 = point-game.player.position
			if Vector2(offset.x,offset.z).length()<.33:break
			game.player.rotation.y = atan2(-offset.x,-offset.z)
			Input.action_press("forward",clampf(offset.length(),.24,.72))
			await physics_frame
		Input.action_release("forward")
		var remaining: Vector3 = point-game.player.position
		if Vector2(remaining.x,remaining.z).length()>.6:return false
	return Vector2(game.player.position.x-target.x,game.player.position.z-target.z).length()<.92 and absf(game.player.position.y-target.y)<.8

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+name+".png")
