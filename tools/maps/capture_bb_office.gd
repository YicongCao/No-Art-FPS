extends SceneTree

const SHOTS = {
	"workstations": [Vector3(-3.3,1.62,2.9),Vector3(1.8,1.48,-4.7),66.0],
	"rooms": [Vector3(-.65,1.63,-9.65),Vector3(.2,1.64,-16.9),72.0],
	"manager": [Vector3(21.1,1.66,-10.15),Vector3(17.9,1.43,-16.1),66.0],
	"pantry": [Vector3(-21.35,1.63,16.2),Vector3(-22,1.41,13.7),66.0],
	"entrance": [Vector3(-2.2,1.65,12.0),Vector3(0,1.91,20.1),59.0],
	"skyline": [Vector3(21.3,1.64,11.3),Vector3(23,1.72,-8),66.0],
	"screen": [Vector3(-.05,1.52,1.1),Vector3(1.25,1.29,-1.62),59.0],
}

func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	assert(DisplayServer.get_name()!="headless")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:
			break
	assert(game.arena.map_id=="bb_office" and game.nav_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	game.hud.hide()
	game.player.gun.hide()
	game.enemies.hide()
	var camera = Camera3D.new()
	game.add_child(camera)
	camera.make_current()
	for id in SHOTS:
		var shot: Array = SHOTS[id]
		camera.global_position = shot[0]
		camera.look_at(shot[1])
		camera.fov = shot[2]
		await screenshot(id)
	game.start_run()
	game.begin_running()
	game.player.enabled = false
	game.enemies.hide()
	game.rules.elapsed = 46.0
	game.set_destroy_active(true)
	for id in ["workstations","screen"]:
		var shot: Array = SHOTS[id]
		camera.global_position = shot[0]
		camera.look_at(shot[1])
		camera.fov = shot[2]
		await screenshot(id+"-frenzy")
	print("BB_OFFICE_RENDER_PASS")
	quit()

func screenshot(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	assert(image.save_png("res://artifacts/local/bb-office-"+id+".png")==OK)
