extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	root.size = Vector2i(1920,1080)
	var game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false;root.add_child(game)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.arena.map_id=="sandgate")
	game.qa_mode = true;game.start_run();game.begin_running()
	game.set_physics_process(false);game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.invulnerable = 999;game.hud.go_time = 0
	for actor in game.live_enemies():actor.set_physics_process(false)
	var views = {
		"gate":[Vector3(16.3,.05,21.2),Vector3(16.3,2.0,14.0)],
		"market":[Vector3(.2,.05,10.0),Vector3(1.44,2.0,.15)],
		"long":[Vector3(15.77,.05,14.06),Vector3(16.2,1.9,-4.0)]
	}
	for label in views:
		game.player.position = views[label][0]
		var direction: Vector3 = game.player.camera.global_position.direction_to(views[label][1])
		game.player.rotation.y = atan2(-direction.x,-direction.z)
		game.player.pitch = asin(direction.y)
		game.player.camera.rotation.x = game.player.pitch
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/local/release-sandgate-"+label+".png")
	for type in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for voice in game.find_children("*",type,true,false):voice.stop()
	await create_timer(.15).timeout
	game.queue_free();await create_timer(.15).timeout
	print("RELEASE_SANDGATE_CAPTURE_PASS")
	quit()
