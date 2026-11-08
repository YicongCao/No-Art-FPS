extends SceneTree

const SHOTS = {
	"overview": [Vector3(1.5,25,29),Vector3(0,1,-1),60.0],
	"a-long": [Vector3(16.30,1.58,19.20),Vector3(17.25,2.40,-4.0),59.0],
	"mid-doors": [Vector3(.2,1.62,10.0),Vector3(1.44,2.42,.15),66.0],
	"b-tunnel": [Vector3(-17.64,1.59,3.16),Vector3(-16.26,2.50,-8.35),68.0],
}

func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.arena.map_id=="sandgate" and game.nav_ready)
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
		await process_frame
		await RenderingServer.frame_post_draw
		var image = root.get_texture().get_image()
		assert(image.save_png("res://artifacts/local/sandgate-"+id+".png")==OK)
	print("SANDGATE_RENDER_PASS")
	quit()
