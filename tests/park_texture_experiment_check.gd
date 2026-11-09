extends SceneTree

const OUTPUT = "res://artifacts/local/park-texture-experiment/"
const VIEWS = [
	["promenade",Vector3(-9.5,.05,17.9),Vector3(-.4,1.9,1.0)],
	["skate",Vector3(-18.0,.05,9.2),Vector3(-20.5,-.25,-1.5)],
	["station",Vector3(25.3,2.25,5.3),Vector3(24.7,2.85,-5.5)],
	["train",Vector3(24.4,2.25,5.2),Vector3(20.9,2.65,1.8),.08],
	["carousel",Vector3(3.25,.05,6.0),Vector3(.2,2.05,.5)],
	["kiosks",Vector3(-16.0,.05,19.5),Vector3(-21.0,1.5,13.0)],
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
	assert(not is_instance_valid(game.hud.park_options))
	await game.set_park_experimental_textures(true)
	assert(not game.park_experimental_textures)
	game.touch_mode = true
	hold_card(press.position)
	assert(not is_instance_valid(game.hud.park_options) and game.session.session_id=="score_attack")
	game.touch_mode = false
	type_code("xyzzy")
	assert(not game.park_experiment_unlocked)
	key(KEY_0,48,true)
	root.push_input(press,true)
	assert(not is_instance_valid(game.hud.park_options))
	type_code("xyxxyzzy")
	assert(not game.park_experiment_unlocked)
	key(KEY_0,48,true)
	key(KEY_CTRL,0)
	type_code("xyzzy")
	assert(game.park_experiment_unlocked)
	game.touch_mode = true
	hold_card(press.position)
	assert(is_instance_valid(game.hud.park_options) and game.session.session_id=="score_attack")
	game.hud.close_park_options()
	game.touch_mode = false
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
	var scenery: Array = game.arena.find_children("*","MeshInstance3D",true,false)
	scenery = scenery.filter(func(node):return not game.arena.disco_ball.is_ancestor_of(node))
	assert(preview.meshes.size()==scenery.size(),"Every authored mesh should be textured")
	assert(game.arena.disco_paint.get_shader_parameter("pixel_finish"))
	for entry in preview.meshes:
		for index in range(entry.node.mesh.get_surface_count()):
			assert(entry.node.get_active_material(index) is ShaderMaterial)
	var barrel: Node3D = game.arena.barrels[0]
	assert(barrel.experimental_paint and game.arena.barrels[1].experimental_paint!=barrel.experimental_paint)
	barrel.set_paint_color(Color("fff1b7"))
	assert(barrel.experimental_paint.get_shader_parameter("base_color")==barrel.paint.albedo_color)
	barrel.reset()
	assert(barrel.experimental_paint.get_shader_parameter("base_color")==Color("c34c35"))
	game.comedy_mode = "comedy"
	game.prepare_comedy_toilet()
	assert(is_instance_valid(game.comedy_toilet))
	for node in game.comedy_toilet.find_children("*","MeshInstance3D",true,false):
		for index in range(node.mesh.get_surface_count()):
			assert(node.get_active_material(index) is ShaderMaterial)
	game.remove_comedy_toilet()
	game.comedy_mode = ""
	await game.set_park_experimental_textures(false)
	assert(game.title_preview_key()==baseline_key and not game.hud.fire_button.disabled)
	assert(not barrel.experimental_paint and not game.arena.disco_paint.get_shader_parameter("pixel_finish"))
	if DisplayServer.get_name()!="headless":
		assert(game.hud.title_frame==original)
	for entry in preview.meshes:
		assert(entry.node.material_override==entry.override)
		for index in range(entry.original.size()):
			assert(entry.node.get_surface_override_material(index)==entry.original[index])
	if DisplayServer.get_name()!="headless":
		await capture_views()
	print("PARK_TEXTURE_EXPERIMENT_PASS: shortcut, right-click and long-press gating, ",preview.meshes.size()," scenery meshes and full restore")
	game.music.stop()
	var settle_at := Time.get_ticks_msec()+450
	while Time.get_ticks_msec()<settle_at:await process_frame
	game.queue_free()
	await process_frame
	quit()

func key(code: Key, character: int, control := false) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	event.unicode = character
	event.ctrl_pressed = control
	root.push_input(event,true)

func type_code(text: String) -> void:
	for index in range(text.length()):
		key(text.to_upper().unicode_at(index) as Key,text.unicode_at(index))

func hold_card(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = true
	root.push_input(event,true)
	game.hud.map_touch_started_at -= game.hud.MAP_HOLD_MS
	event.pressed = false
	root.push_input(event,true)

func capture_views() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game.start_run()
	game.begin_running()
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.hud.go_time = 0
	game.enemies.hide()
	for enemy in game.live_enemies():enemy.set_physics_process(false)
	for view in VIEWS:
		game.rules.elapsed = view[3] if view.size()>3 else 12.0
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
