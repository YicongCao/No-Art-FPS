extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	game.qa_mode = true
	game.set_physics_process(false)
	await game.select_session(game.CONCEPT_SESSIONS.rain_market,"rain_market")
	var arena = game.arena
	assert(arena.validate_navigation())
	assert(arena.market_lookdev and arena.market_lookdev.cache.size()>0)
	var collision_count: int = arena.find_children("*","CollisionShape3D",true,false).size()
	var nav_before: int = arena.nav.navigation_mesh.get_polygon_count()
	game.start_run()
	game.begin_running()
	assert(game.live_enemies().size()==8 and game.rules.duration==60.0)
	var ink: ShaderMaterial = game.player.outline.material_override
	assert(is_equal_approx(ink.get_shader_parameter("ink_strength"),.34))
	var source = arena.get_node("Architecture/street").find_children("*","MeshInstance3D",true,false)[0]
	assert(source.mesh.surface_get_material(0) is StandardMaterial3D)
	assert(source.get_active_material(0) is ShaderMaterial)
	var old = arena.market_lookdev
	if DisplayServer.get_name()!="headless":
		assert(old.reflection and old.mirror)
		game.player.enabled = false
		game.player.position = Vector3(.4,.32,16)
		game.player.camera.make_current()
		await create_timer(.25).timeout
		assert(arena.puddles.get_shader_parameter("reflection_enabled"))
		game.touch_mode = true
		await create_timer(.25).timeout
		assert(old.reflection.size.x==384)
		game.player.position.x=21
		await create_timer(.25).timeout
		assert(not arena.puddles.get_shader_parameter("reflection_enabled"))
		game.touch_mode = false
	game.set_destroy_active(true)
	assert(arena.frenzy_lights.all(func(l):return l.visible))
	game.start_run()
	assert(not game.destroy_active)
	assert(arena.find_children("*","CollisionShape3D",true,false).size()==collision_count)
	assert(arena.nav.navigation_mesh.get_polygon_count()==nav_before)
	game.state = "TITLE"
	await game.select_session(game.SANDGATE_SESSION_PATH,"sandgate")
	assert(is_equal_approx(ink.get_shader_parameter("ink_strength"),.88))
	await process_frame
	assert(not is_instance_valid(old))
	await game.select_session(game.CONCEPT_SESSIONS.rain_market,"rain_market")
	assert(game.arena.market_lookdev)
	print("RAIN_MARKET_LOOKDEV_PASS")
	quit()
