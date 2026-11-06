extends Node
var game: Node

func _ready() -> void:
	assert(DisplayServer.get_name()!="headless","Floor check requires rendered frames")
	Engine.max_fps = 60
	if "--baseline" in OS.get_cmdline_user_args() and FileAccess.file_exists("res://artifacts/local/floor-baseline.tscn"):
		var original = game.session.duplicate()
		original.map_scene = load("res://artifacts/local/floor-baseline.tscn")
		await game.select_session(original)
	game.start_run();game.begin_running();game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.player.set_process(false)
	game.hud.go_time = 0
	var report: Dictionary = {}
	for sample in [["b_mid_seam",Vector3(-60,-3.5,41)],["mid_seam",Vector3(-50,-3.5,34)]]:
		var point: Vector3 = sample[1]
		var colors: Array[Color] = []
		for frame in range(36):
			# Look at one fixed floor point while the actual camera traverses nearby.
			var offset = Vector3(-2+frame*.12,.05,5) if sample[0]=="b_mid_seam" else Vector3(-1.5+frame*.025,.05,2)
			game.player.global_position = point+offset
			var direction = game.player.camera.global_position.direction_to(point)
			game.player.rotation.y = atan2(-direction.x,-direction.z)
			game.player.camera.rotation.x = asin(direction.y)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var image = get_viewport().get_texture().get_image()
			var screen = game.player.camera.unproject_position(point)
			var scale = Vector2(image.get_size())/game.hud.size
			var pixel = Vector2i(screen*scale)
			var ray = PhysicsRayQueryParameters3D.create(game.player.camera.global_position,point-Vector3.UP*.01,1)
			var floor_hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
			assert(not floor_hit.is_empty() and floor_hit.normal.y>.99,"Sample must view an unobstructed floor")
			var color = Color(0,0,0,0)
			for x in range(-2,3):
				for y in range(-2,3):color += image.get_pixel(pixel.x+x,pixel.y+y)
			colors.append(color/25)
			if frame in [0,18,35]:image.save_png("res://artifacts/local/floor-"+sample[0]+"-%02d.png"%frame)
		var variation = 0.0
		for a in colors:
			for b in colors:variation = maxf(variation,Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length())
		report[sample[0]] = {"max_color_distance":variation,"frames":36}
		if not "--baseline" in OS.get_cmdline_user_args():assert(variation<.015,"Floor color flickers while walking: "+str(report))
	FileAccess.open("res://artifacts/local/floor-render"+("-before" if "--baseline" in OS.get_cmdline_user_args() else "-after")+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FLOOR_RENDER_CHECK_PASS: ",JSON.stringify(report))
	game.state = "RESULTS";game.clear_round()
	await get_tree().create_timer(.2).timeout
	get_tree().quit()
