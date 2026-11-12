extends SceneTree

# Fixed Hogwarts views for lighting before/after comparisons.
# godot --path . --script tools/maps/capture_toy_compare.gd -- <folder>
# Writes docs/art/toy/hogwarts/<folder>/{quidditch,castle,hogsmeade,gameplay}.png
var game: Node3D

func _initialize() -> void:
	capture.call_deferred()

func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func capture() -> void:
	assert(DisplayServer.get_name()!="headless")
	var args := OS.get_cmdline_user_args()
	var out := "res://docs/art/toy/hogwarts/%s/"%(args[0] if not args.is_empty() else "after")
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	root.size = Vector2i(1600,900)
	for _frame in range(900):
		if game.title_frame_ready:break
		await process_frame
	game.qa_mode = true
	game.set_physics_process(false)
	await game.select_session("res://data/sessions/hogwarts.tres","hogwarts")
	game.start_run()
	game.begin_running()
	game.invulnerable = 999
	game.hud.go_time = 0
	game.rules.elapsed = 2.0
	var player = game.player
	player.enabled = false
	for enemy in game.live_enemies():enemy.set_physics_process(false)
	player.global_position = Vector3(-22.5,.05,16.5)
	var target := Vector3(-17.0,0,9.6)
	game.clear_round()
	var rifleman = game.spawn_enemy(target,false)
	var rusher = game.spawn_enemy(target+Vector3(2.6,0,-1.4),true)
	for foe in [rifleman,rusher]:
		foe.set_physics_process(false)
		foe.look_at(Vector3(player.global_position.x,0,player.global_position.z),Vector3.UP)
	var direction: Vector3 = (player.global_position+Vector3.UP*1.6).direction_to(target+Vector3(1.6,1.3,-.6))
	player.rotation.y = atan2(-direction.x,-direction.z)
	player.pitch = asin(direction.y)
	player.camera.rotation.x = player.pitch
	await shot(out+"gameplay.png")
	game.hud.hide()
	player.gun.hide()
	var camera := Camera3D.new()
	camera.far = 265
	game.add_child(camera)
	camera.make_current()
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/maps/hogwarts_layout.json"))
	for id in ["quidditch","castle","hogsmeade"]:
		var settings: Array = layout.cameras[id]
		camera.global_position = vec(settings[0])
		camera.look_at(vec(settings[1]))
		camera.fov = settings[2]
		await shot(out+id+".png")
	quit()

func shot(path: String) -> void:
	for _frame in range(8):await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK)
