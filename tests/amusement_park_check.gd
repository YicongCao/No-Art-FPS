extends SceneTree

var game: Node3D
var park: Node3D
var rendered: bool

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	rendered = DisplayServer.get_name()!="headless"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.nav_ready and game.session.session_id=="amusement_park")
	game.qa_mode = true
	park = game.arena
	assert(park.validate_map() and park.validate_navigation())
	assert(game.opening.filter(func(actor):return actor.fast).size()==2)
	assert(game.world_environment.environment==park.environment_override)
	var curve: Curve3D = park.cars[0].get_parent().curve
	assert(curve.get_baked_length()>100)
	assert(curve.sample_baked(0).distance_to(curve.sample_baked(curve.get_baked_length()))<.01)

	if rendered:
		DirAccess.make_dir_recursive_absolute("res://artifacts/local")
		game.hud.title_frame.get_image().save_png("res://artifacts/local/park-opening.png")
		await overview()
		await tour()

	game.start_run()
	game.begin_running()
	assert(game.music.playing and game.music.stream==game.session.combat_music)
	assert(is_equal_approx(game.music.stream.get_length(),45.0) and game.music.stream.loop)
	game.invulnerable = 999
	var opening_count: int = game.live_enemies().size()
	assert(opening_count==8)
	var initial_car: float = park.cars[0].progress
	var initial_horse: float = park.horses[0].position.y
	var track_length = curve.get_baked_length()
	for _frame in range(120):await physics_frame
	assert(park.cars[0].progress!=initial_car and park.horses[0].position.y!=initial_horse)
	game.pause_run()
	var stopped: float = park.cars[0].progress
	for _frame in range(6):await physics_frame
	assert(park.cars[0].progress==stopped and game.music.stream_paused)
	game.menu_action("resume")
	for _frame in range(2):await physics_frame
	assert(not game.music.stream_paused and game.music.stream==game.session.combat_music)
	var spawn_seen = false
	var revived = false
	var destroyed = false
	var finale_seen = false
	var did_damage = false
	var first_car_wrap = false
	var previous_progress: float = park.cars[0].progress
	for _frame in range(3900):
		await physics_frame
		var elapsed: float = game.rules.elapsed
		spawn_seen = spawn_seen or game.live_enemies().size()>opening_count
		if not did_damage and elapsed>=11:
			game.invulnerable = 0
			game.damage_player(999)
			assert(game.respawn_time>0 and not game.player.enabled)
			did_damage = true
		if did_damage and game.respawn_time<=0 and elapsed<18:
			revived = true
			game.invulnerable = 999
		if not game.finale_active:
			first_car_wrap = first_car_wrap or previous_progress-park.cars[0].progress>track_length*.5
			previous_progress = park.cars[0].progress
		if game.destroy_active and not destroyed:
			assert(is_equal_approx(elapsed,45.0))
			assert(game.music.playing and game.music.stream==game.session.destroy_music)
			assert(is_equal_approx(game.music.stream.get_length(),15.0) and game.music.stream.loop)
			var kiosk = park.get_node("Kiosk1")
			game.player.position = Vector3(14,.05,19)
			game.player.velocity = Vector3.ZERO
			game.player.rotation.y = 0
			game.player.pitch = 0
			game.player.camera.rotation.x = 0
			await physics_frame
			game.shoot()
			assert(kiosk.hits==1 and not kiosk.collapsed)
			game.fire_time = 0
			game.shoot()
			assert(kiosk.hits==2)
			for _tick in range(18):await physics_frame
			assert(kiosk.collapsed)
			for body in kiosk.collision_states:assert(body.collision_layer==0)
			destroyed = true
		if game.finale_active:
			assert(game.rules.remaining()==0)
			finale_seen = true
		if game.state=="RESULTS":break
	assert(game.state=="RESULTS" and game.rules.elapsed==60)
	assert(not game.music.playing)
	assert(spawn_seen and revived and destroyed and finale_seen and first_car_wrap)
	assert(park.get_node("Carousel").collapsed and park.get_node("Coaster").collapsed)
	game.start_run()
	assert(park.get_node("Carousel/Turntable").visible and park.get_node("Coaster/RailPath").visible)
	assert(is_equal_approx(park.cars[0].progress,initial_car) and park.horses[0].position.y==initial_horse)
	assert(not park.get_node("Kiosk1").collapsed)
	game.begin_running()
	assert(game.music.playing and game.music.stream==game.session.combat_music)
	print("AMUSEMENT_PARK_PASS: navigation, ride loop, pause, 60-second round, spawns, respawn, two-hit scenery, finale, reset and both music cues")
	game.state = "RESULTS"
	game.clear_round()
	await process_frame
	await process_frame
	if not rendered:
		# Fixed-step headless runs can finish before the real-time mixer drains.
		var audio_deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<audio_deadline:await process_frame
	quit()

func overview() -> void:
	game.hud.hide()
	game.player.gun.hide()
	var camera = Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0,58,38)
	camera.look_at(Vector3(0,0,1))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 51
	camera.make_current()
	await capture("park-overview")
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
	for i in range(park.tour_paths.size()):
		var at: Vector3 = park.get_node(park.tour_paths[i]).global_position
		if park.tour_paths[i].get_name(1)=="Shortcut0_0":
			assert(await walk_to(Vector3(-6,0,1)),"Approach the west shortcut from its ramp mouth")
		assert(await walk_to(at),"Player route blocked at %s (%s), position %s"%[park.tour_paths[i],at,game.player.position])
		if i==3:await capture("park-bowl")
		if i==9:
			game.player.rotation.y = PI*.5
			await capture("park-station")
	# Enter and leave from each approach, independent of the tour's route order.
	for at in [Vector3(25.6,0,14),Vector3(25.6,2.2,1),Vector3(25.6,0,-12)]:
		assert(await walk_to(at),"Station ramp blocked at %s"%at)
	game.player.position = Vector3(8,.05,8)
	game.player.rotation.y = PI*.34
	await capture("park-carousel")
	game.set_physics_process(true)
	print("PARK_TOUR_PASS: loop, shortcuts, bowl and both station ramps")

func walk_to(target: Vector3) -> bool:
	var map = park.get_world_3d().navigation_map
	var path = NavigationServer3D.map_get_path(map,game.player.position,target,true)
	if path.is_empty():return false
	for point in path:
		for _tick in range(270):
			var offset: Vector3 = point-game.player.position
			if Vector2(offset.x,offset.z).length()<.36:break
			game.player.rotation.y = atan2(-offset.x,-offset.z)
			Input.action_press("forward",clampf(offset.length(),.24,.72))
			await physics_frame
		Input.action_release("forward")
		var remaining: Vector3 = point-game.player.position
		if Vector2(remaining.x,remaining.z).length()>.6:return false
	return Vector2(game.player.position.x-target.x,game.player.position.z-target.z).length()<.9 and absf(game.player.position.y-target.y)<.8

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/"+name+".png")
