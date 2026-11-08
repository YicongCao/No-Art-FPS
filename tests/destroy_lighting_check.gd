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
	assert(game.title_frame_ready and game.nav_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	await check_map("yard")
	for path in [game.PARK_SESSION_PATH,game.FERRY_SESSION_PATH,game.STUDIO_SESSION_PATH]:
		await game.select_session(path)
		assert(game.nav_ready and game.title_frame_ready and game.session.resource_path==path)
		await check_map(game.arena.map_id)
	print("DESTROY_LIGHTING_PASS: four maps, continuous double-speed sweeps, distinct neon lights and shafts, orange sky, pause, retry and title reset")
	if DisplayServer.get_name()=="headless":
		# Let headless audio drain before freeing its streams.
		var deadline = Time.get_ticks_msec()+450
		while Time.get_ticks_msec()<deadline:await process_frame
	game.queue_free()
	await process_frame
	quit()

func check_map(map_id: String) -> void:
	var arena = game.arena
	var lights: Array[SpotLight3D] = []
	var moving: Array[SpotLight3D] = []
	var normal_environment: Environment = game.world_environment.environment
	match map_id:
		"amusement_park":
			lights.assign(arena.disco_spots)
			moving.assign(lights)
		"last_ferry":
			lights.assign([arena.searchlight,arena.port_searchlight])
			moving.assign([arena.searchlight])
			assert(not arena.port_searchlight.visible)
		"night_studio":
			lights.assign(arena.stage_spots)
			moving.assign(arena.sweeping_spots)
	var normal_colors: Array[Color] = []
	for light in lights:normal_colors.append(light.light_color)
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.player.enabled = false
	place_camera(map_id)
	game.rules.elapsed = 44.99
	arena._process(0)
	var before: Array[Quaternion] = []
	for light in moving:before.append(light.global_basis.get_rotation_quaternion())
	await capture(map_id,"normal")
	game._physics_process(.01)
	assert(game.destroy_active and is_equal_approx(game.rules.remaining(),15.0))
	arena._process(0)
	for i in range(moving.size()):
		assert(before[i].angle_to(moving[i].global_basis.get_rotation_quaternion())<.04)
	if map_id=="yard":
		assert(game.world_environment.environment.background_color==Color("e88c49"))
	else:
		assert(game.world_environment.environment==normal_environment)
		var colors = {}
		for light in lights:
			assert(light.visible and not colors.has(light.light_color))
			colors[light.light_color] = true
			var shaft = light.get_node_or_null("Shaft")
			if shaft:assert(shaft.material_override.get_shader_parameter("tint")==light.light_color)
		assert(lights[0].light_color!=normal_colors[0])
	game.rules.elapsed = 47.0
	arena._process(0)
	assert(is_equal_approx(arena.sweep_elapsed(),49.0))
	await capture(map_id,"frenzy")

	var held: Array[Basis] = []
	for light in moving:held.append(light.global_basis)
	game.pause_run()
	arena._process(.1)
	for i in range(moving.size()):assert(moving[i].global_basis==held[i])
	game.start_run()
	assert_reset(lights,normal_colors,normal_environment)

	game.begin_running()
	game.rules.elapsed = 45.0
	game._physics_process(0)
	game.pause_run()
	game.menu_action("menu")
	assert(game.state=="TITLE")
	assert_reset(lights,normal_colors,normal_environment)

func assert_reset(lights: Array[SpotLight3D], colors: Array[Color], environment: Environment) -> void:
	assert(not game.destroy_active and game.world_environment.environment==environment)
	for i in range(lights.size()):assert(lights[i].light_color.is_equal_approx(colors[i]))
	if game.arena.map_id=="last_ferry":assert(not game.arena.port_searchlight.visible)

func place_camera(map_id: String) -> void:
	var target: Vector3
	match map_id:
		"yard":return
		"amusement_park":
			game.player.position = Vector3(0,.05,8.8)
			target = Vector3(0,2.55,.4)
		"last_ferry":
			game.player.position = Vector3(-8,.05,12)
			target = Vector3(-.55,5.7,0)
		"night_studio":
			game.player.position = Vector3(.25,.05,8)
			target = Vector3(0,2.65,-3.6)
	var direction = game.player.camera.global_position.direction_to(target)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch

func capture(map_id: String, phase: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local/lighting-%s-%s.png"%[map_id,phase])
