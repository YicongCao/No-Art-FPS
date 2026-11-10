extends SceneTree

var game: Node3D
var camera: Camera3D

func _initialize() -> void:
	capture.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func capture() -> void:
	assert(DisplayServer.get_name()!="headless")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:
			break
	assert(game.nav_ready and game.title_frame_ready)
	game.qa_mode = true
	game.reduced_motion = false
	game.set_physics_process(false)
	game.player.set_process_unhandled_input(false)
	camera = Camera3D.new()
	camera.far = 145
	game.add_child(camera)
	DirAccess.make_dir_recursive_absolute("res://artifacts/local/next-arenas")
	var only := OS.get_cmdline_user_args()
	for id in game.CONCEPT_SESSIONS:
		if not only.is_empty() and id not in only:
			continue
		await game.select_session(game.CONCEPT_SESSIONS[id],id)
		assert(game.nav_ready and game.arena.map_id==id)
		game.start_run()
		game.begin_running()
		game.player.enabled = false
		game.hud.hide()
		game.player.gun.hide()
		game.enemies.hide()
		for enemy in game.live_enemies():
			enemy.set_physics_process(false)
		camera.make_current()
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/%s_layout.json"%id))
		var cutaway: Node3D = game.arena.get_node({"rain_market":"Architecture/canopy","baggage_below":"Architecture/ceiling_and_beams","snowline":"Moving/dome","palm_house":"Architecture/glasshouse_glass"}[id])
		cutaway.hide()
		if id=="snowline":
			game.arena.shutter_left.hide()
			game.arena.shutter_right.hide()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 55
		camera.global_position = Vector3(16,62,40)
		camera.look_at(Vector3.ZERO)
		await screenshot(id,"overview")
		cutaway.show()
		if id=="snowline":
			game.arena.shutter_left.show()
			game.arena.shutter_right.show()
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		for key in layout.cameras:
			var shot: Array = layout.cameras[key]
			camera.global_position = vec(shot[0])
			camera.look_at(vec(shot[1]))
			camera.fov = shot[2]
			game.rules.elapsed = shot[3] if shot.size()>3 else (47.0 if key.ends_with("frenzy") else 0.0)
			if key.ends_with("frenzy"):
				game.set_destroy_active(true)
				var targets = {"service-frenzy":"ServiceShortcut","sorting-frenzy":"BurstCase","telescope-frenzy":"StormHatch","tool-yard-frenzy":"GlassBreach"}
				if targets.has(key):
					var prop = game.arena.get_node("Props/"+targets[key])
					prop.hit_point = prop.world_bounds().get_center()
					prop.hits = 2
					prop.collapse(false)
					game.arena.scatter_prop(prop.impact_kind,prop.hit_point,Vector3.UP,prop.world_bounds().position.y,true)
					await create_timer(.1).timeout
			await screenshot(id,key)
		game.state = "TITLE"
		game.hud.show()
		game.enemies.show()
		game.player.camera.make_current()
	print("CONCEPT_ARENAS_RENDERED")
	quit()

func screenshot(id: String, key: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	assert(image.save_png("res://artifacts/local/next-arenas/%s-%s.png"%[id,key])==OK)
	print("ARENA_CAPTURE ",id," ",key)
