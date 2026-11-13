extends SceneTree
## Fixed daylight and frenzy views for reviewing the yard's colour and highlight range.
func _initialize() -> void:run.call_deferred()
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	var args := OS.get_cmdline_user_args()
	assert(args.size()==1)
	var out := "res://docs/updates/yard-lighting-2026-11-13/"+args[0]+"/"
	DirAccess.make_dir_recursive_absolute(out)
	var game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	root.size = Vector2i(1440,810)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready and game.arena.map_id=="yard")
	game.qa_mode = true
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.clear_round()
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.hud.go_time = 0
	var views := {
		"lane":[Vector3(18,.05,14),Vector3(18,1.7,-4)],
		"containers":[Vector3(0,.05,10.5),Vector3(-2,1.7,-1)],
	}
	for frenzy in [false,true]:
		game.set_destroy_active(frenzy)
		for label in views:
			var pose: Array = views[label]
			game.player.global_position = pose[0]
			var direction: Vector3 = (pose[0]+Vector3.UP*1.6).direction_to(pose[1])
			game.player.rotation.y = atan2(-direction.x,-direction.z)
			game.player.pitch = asin(direction.y)
			game.player.camera.rotation.x = game.player.pitch
			for i in range(12):await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(out+label+("-frenzy" if frenzy else "")+".png")==OK)
	game.set_destroy_active(false)
	print("YARD_LIGHT_CAPTURE_PASS sun=",game.sun.light_energy," ambient=",game.world_environment.environment.ambient_light_energy)
	game.queue_free()
	for i in range(3):await process_frame
	quit()
