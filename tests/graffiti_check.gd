extends Node

var game: Node

func _ready() -> void:
	assert(DisplayServer.get_name()!="headless","Graffiti check requires rendering")
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.set_process(false)
	game.player.set_process_unhandled_input(false)
	game.arena.set_process(false)
	for room in game.arena.containers:room.set_physics_process(false)
	assert(game.arena.find_children("*","Label3D",true,false).is_empty())
	for color in ["red","cream","yellow","ink"]:
		var material = game.arena.materials[color]
		assert(material.next_pass==null,"Paint must share the opaque wall pass")
		for i in range(int(material.get_shader_parameter("paint_count"))):
			var texture = material.get_shader_parameter("artwork_"+str(i))
			assert(texture.get_image().has_mipmaps(),"Graffiti requires mipmaps")
	var murals = [
		["sector",Vector3(-6,1.45,-1.58),Vector3.BACK],
		["yard",Vector3(0,1.45,-8.94),Vector3.BACK],
		["warehouse",Vector3(23.85,2.75,-2.5),Vector3.LEFT]]
	var maximum_change = 0.0
	for mural in murals:
		var center: Vector3 = mural[1]
		var normal: Vector3 = mural[2]
		var right = Vector3.UP.cross(normal)
		var reference: Array[Image] = []
		# Replay the same near/far/oblique views in reverse order to detect
		# history-dependent depth/sorting flicker in the central mural area.
		for pass_index in range(2):
			for step in range(12):
				var pose = step if pass_index==0 else 11-step
				var angle = lerpf(-.65,.65,float(pose)/11)
				var distance = 4.5+float(pose%3)*1.5
				var eye = center+normal*cos(angle)*distance+right*sin(angle)*distance+Vector3.UP*.25
				game.player.position = eye-Vector3(0,1.65,0)
				var direction = eye.direction_to(center)
				game.player.rotation.y = atan2(-direction.x,-direction.z)
				game.player.camera.rotation.x = asin(direction.y)
				await get_tree().create_timer(.05).timeout
				await RenderingServer.frame_post_draw
				var image = get_viewport().get_texture().get_image()
				var crop = image.get_region(Rect2i(image.get_width()/2-110,image.get_height()/2-75,220,150))
				if pass_index==0:
					reference.append(crop)
				else:
					var delta = reference[pose].compute_image_metrics(crop,false)["mean"]
					maximum_change = maxf(maximum_change,delta)
					if delta>=.5:
						reference[pose].save_png("res://artifacts/local/graffiti-expected.png")
						crop.save_png("res://artifacts/local/graffiti-actual.png")
						print("GRAFFITI_VIEW_DIFF ",mural[0]," pose=",pose," eye=",eye)
					assert(delta<.5,"Repeated mural view changed: "+str(delta))
				if pass_index==0 and pose==1:
					image.save_png("res://artifacts/graffiti-oblique-"+mural[0]+".png")
		print("GRAFFITI_SWEEP_PASS ",mural[0])
	print("GRAFFITI_CHECK_PASS repeated_view_max_mean_change=",maximum_change)
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.3).timeout
	get_tree().quit()
