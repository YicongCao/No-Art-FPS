extends SceneTree

const CombatFX = preload("res://scripts/combat_fx.gd")
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.session.session_id=="night_studio" and game.nav_ready and game.title_frame_ready)
	var arena: Node3D = game.arena
	assert(arena.validate_navigation())
	assert(game.rules.duration==60 and game.score_record_key()=="score_night_studio_v1")
	game.qa_mode = true
	game.start_run()
	game.begin_running()
	assert(game.live_enemies().size()==8)
	game.clear_round()
	game.set_physics_process(false)
	game.invulnerable = 999
	game.touch_mode = true
	game.player.rotation.y = 0
	for index in [0,1,2,4,3,5,6,7,8]:
		var point: Vector3 = arena.get_node(arena.route_paths[index]).global_position
		assert(await walk_to(point),"Player could not walk to studio landmark %d"%index)
	game.touch_mode = false
	game.player.enabled = false
	print("STUDIO_WALK_PASS: stage, news, office, green room, archive, both ramps, catwalk and backstage")

	var rack = arena.get_node("Props/ArchiveRack4")
	game.player.position = Vector3(14,.05,-2.1)
	await physics_frame
	var impact = rack.global_position+Vector3(0,1.61,.30)
	shoot_at(impact)
	var papers = game.effects.get_node_or_null("PaperScatter")
	assert(papers and papers.get_child(0).multimesh.instance_count==7)
	assert(rack.hits==0 and not rack.collapsed,"Ordinary rounds scatter paper without damaging the rack")
	await capture("studio-paper-impact")
	for _tick in range(2700):game.rules.tick(1.0/60.0)
	game._physics_process(0)
	assert(game.destroy_active and is_equal_approx(game.rules.remaining(),15))
	shoot_at(impact)
	assert(rack.hits==1 and rack.burn_time<0)
	shoot_at(impact)
	assert(rack.hits==2 and rack.burn_time>0)
	for _tick in range(20):await physics_frame
	assert(rack.collapsed and rack.collision_states.keys()[0].collision_layer==0)
	assert(game.effects.get_children().any(func(fx):return fx is CombatFX and fx.duration==1.3))
	await capture("studio-paper-burst")

	var flat = arena.get_node("Props/VarietyFlat5")
	game.player.position = Vector3(0,.32,-3.5)
	await physics_frame
	var backdrop = flat.global_position+Vector3.UP*1.8
	shoot_at(backdrop)
	shoot_at(backdrop)
	for _tick in range(40):await physics_frame
	assert(flat.collapsed)
	assert(game.achievements.unlocked_badge("studio") and game.achievements.counts.wreck==2)
	var from = Vector3(0,1.35,-5.6)
	var to = Vector3(0,1.35,-10.05)
	var shortcut = PhysicsRayQueryParameters3D.create(from,to,1)
	assert(game.get_world_3d().direct_space_state.intersect_ray(shortcut).is_empty(),"A destroyed backdrop opens the backstage passage")
	var monitors = {
		arena.get_node("Props/StageMonitorLeft"): Vector3(-4.7,.05,-.3),
		arena.get_node("Props/ControlMonitor2"): Vector3(-13.3,.05,-14.85)
	}
	for monitor in monitors:
		game.player.position = monitors[monitor]
		await physics_frame
		shoot_at(monitor.world_bounds().get_center())
		assert(monitor.hits==1 and not monitor.collapsed)
		shoot_at(monitor.world_bounds().get_center())
		for _tick in range(20):await physics_frame
		assert(monitor.collapsed and not monitor.get_node("Model").visible)
		assert(monitor.collision_states.keys()[0].collision_layer==0)
	for _tick in range(900):game.rules.tick(1.0/60.0)
	game._physics_process(0)
	assert(game.finale_active)
	game.start_run()
	assert(not rack.collapsed and not flat.collapsed and rack.hits==0 and flat.hits==0)
	for monitor in monitors:
		assert(not monitor.collapsed and monitor.get_node("Model").visible)
		assert(monitor.collision_states.keys()[0].collision_layer==game.SCENERY_TARGET_LAYER)
	assert(not game.destroy_active and game.effects.get_child_count()==0)
	print("NIGHT_STUDIO_PASS: eight enemies, round deadline, ordinary paper impact, fire burst, shortcut, destructible monitors, independent record, full reset")
	if DisplayServer.get_name()=="headless":
		var audio_deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<audio_deadline:await process_frame
	game.queue_free()
	await process_frame
	quit()

func walk_to(goal: Vector3) -> bool:
	var map = game.get_world_3d().navigation_map
	var route = NavigationServer3D.map_get_path(map,game.player.global_position,goal,true)
	if route.is_empty():return false
	for point in route:
		for _tick in range(200):
			var offset = point-game.player.global_position
			var direction = Vector2(offset.x,offset.z)
			if direction.length()<.34:break
			game.player.touch_move = (direction*1.3).limit_length()
			await physics_frame
		if Vector2(point.x-game.player.position.x,point.z-game.player.position.z).length()>.6:return false
	game.player.touch_move = Vector2.ZERO
	return game.player.position.distance_to(goal)<.9

func shoot_at(target: Vector3) -> void:
	var direction = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch
	game.player.crosshair_offset = Vector2.ZERO
	game.fire_time = 0
	game.shoot()

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	for _tick in range(6):await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+label+".png")
