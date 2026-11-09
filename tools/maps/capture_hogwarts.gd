extends SceneTree

var game: Node3D
var camera: Camera3D
const OUTPUT = "res://artifacts/local/hogwarts/"

func _initialize() -> void:
	capture.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func capture() -> void:
	assert(DisplayServer.get_name()!="headless")
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		if game.title_frame_ready:break
		await process_frame
	assert(game.nav_ready and game.title_frame_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	await game.select_session("res://data/sessions/hogwarts.tres","hogwarts")
	assert(game.nav_ready and game.arena.map_id=="hogwarts")
	game.start_run()
	game.begin_running()
	game.player.enabled = false
	game.hud.hide()
	game.player.gun.hide()
	game.enemies.hide()
	for enemy in game.live_enemies():enemy.set_physics_process(false)
	camera = Camera3D.new()
	camera.far = 265
	game.add_child(camera)
	camera.make_current()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 83
	camera.global_position = Vector3(5,106,83)
	camera.look_at(Vector3(-1,0,0))
	await shot("overview")
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/hogwarts_layout.json"))
	for id in layout.cameras:
		var settings: Array = layout.cameras[id]
		camera.global_position = vec(settings[0])
		camera.look_at(vec(settings[1]))
		camera.fov = settings[2]
		game.rules.elapsed = settings[3] if settings.size()>3 else 2.0
		game.set_destroy_active(id=="frenzy")
		await shot(id)
	game.state = "TITLE"
	print("HOGWARTS_RENDER_PASS")
	quit()

func shot(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUTPUT+id+".png")==OK)
	print("HOGWARTS_CAPTURE ",id)
