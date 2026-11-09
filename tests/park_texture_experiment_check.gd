extends SceneTree

const OUTPUT = "res://artifacts/local/park-texture-experiment/"
const VIEWS = [
	["promenade",Vector3(-9.5,.05,17.9),Vector3(-.4,1.9,1.0)],
	["skate",Vector3(-18.0,.05,9.2),Vector3(-20.5,-.25,-1.5)],
	["station",Vector3(25.3,2.25,5.3),Vector3(24.7,2.85,-5.5)],
]
var game: Node3D

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	for _frame in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.nav_ready and game.title_frame_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	assert(not game.park_experimental_textures)
	var card: Button = game.hud.map_grid.get_node("MapPark")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = card.get_global_rect().get_center()
	root.push_input(press,true)
	assert(is_instance_valid(game.hud.park_options) and game.session.session_id=="score_attack")
	var toggle: CheckButton = game.hud.park_options.get_node("ExperimentalTextures")
	assert(not toggle.button_pressed)
	await game.select_session(game.PARK_SESSION_PATH,"amusement_park")
	assert(game.nav_ready and game.arena.texture_preview==null)
	var original := game.hud.title_frame as Texture2D
	var baseline_key: String = game.title_preview_key()
	await game.set_park_experimental_textures(true)
	var preview = game.arena.texture_preview
	assert(game.title_preview_key()!=baseline_key)
	assert(preview.meshes.size()==12 and preview.paints.size()>=16)
	for entry in preview.meshes:
		assert(entry.node.mesh==entry.uv_mesh and entry.original_mesh!=entry.uv_mesh)
		assert(entry.original_mesh.get_aabb().is_equal_approx(entry.uv_mesh.get_aabb()))
		for index in range(entry.uv_mesh.get_surface_count()):
			assert(entry.uv_mesh.surface_get_format(index)&Mesh.ARRAY_FORMAT_TEX_UV)
	await game.set_park_experimental_textures(false)
	assert(game.title_preview_key()==baseline_key and not game.hud.fire_button.disabled)
	if DisplayServer.get_name()!="headless":
		assert(game.hud.title_frame==original)
	for entry in preview.meshes:
		assert(entry.node.mesh==entry.original_mesh)
		for index in range(entry.overrides.size()):
			assert(entry.node.get_surface_override_material(index)==entry.overrides[index])
	if DisplayServer.get_name()!="headless":
		await capture_views()
	print("PARK_TEXTURE_EXPERIMENT_PASS: default off, right click menu, 12 UV meshes, title cache, full restore and capture")
	game.music.stop()
	var settle_at := Time.get_ticks_msec()+450
	while Time.get_ticks_msec()<settle_at:await process_frame
	game.queue_free()
	await process_frame
	quit()

func capture_views() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game.start_run()
	game.begin_running()
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.rules.elapsed = 12.0
	game.hud.go_time = 0
	game.enemies.hide()
	for enemy in game.live_enemies():enemy.set_physics_process(false)
	for view in VIEWS:
		game.player.position = view[1]
		var eye: Vector3 = game.player.camera.global_position
		var forward: Vector3 = eye.direction_to(view[2])
		game.player.rotation.y = atan2(-forward.x,-forward.z)
		game.player.pitch = asin(forward.y)
		game.arena.set_experimental_textures(false)
		var original := await shot(view[0]+"-original")
		game.arena.set_experimental_textures(true)
		var textured := await shot(view[0]+"-pixel")
		var difference := original.compute_image_metrics(textured,false)
		assert(difference["mean"]>.0001,"The experimental material must change the rendered view")
		game.arena.set_experimental_textures(false)
		var restored := await frame()
		var restored_difference := original.compute_image_metrics(restored,false)
		assert(restored_difference["max"]==0.0,"Restoring original materials must reproduce the original view")

func frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func shot(name: String) -> Image:
	var image := await frame()
	assert(image.save_png(OUTPUT+name+".png")==OK)
	print("PARK_TEXTURE_CAPTURE ",name)
	return image
