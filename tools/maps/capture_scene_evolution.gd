extends SceneTree
## Fixed first-person views for the scene geometry evolution; no lighting overrides.
## godot --path . --script tools/maps/capture_scene_evolution.gd -- sandgate before

const VIEWS := {
	"amusement_park": {
		"combat": [Vector3(0, .05, 20.6), Vector3(0, 3.4, 1)],
		"near": [Vector3(7.0, .05, 8.8), Vector3(0, 3.65, 1)],
		"side": [Vector3(-7.5, .05, 2.2), Vector3(0, 3.5, 1)],
		"booth": [Vector3(2.0, .05, 19.8), Vector3(5, 1.7, 24)],
	},
	"bb_office": {
		"combat": [Vector3(7, .05, 14.7), Vector3(0, 1.3, 10)],
		"near": [Vector3(2.8, .05, 13.3), Vector3(1.25, 1.0, 10.7)],
		"side": [Vector3(4.8, .05, 5.9), Vector3(1.1, 1.1, 4.3)],
		"equipment": [Vector3(-9.8, .05, 8.9), Vector3(-7.45, .95, 6.15)],
		"cooler": [Vector3(11.1, .05, 16), Vector3(9.35, .94, 13.9)],
	},
	"score_attack": {
		"combat": [Vector3(0, .05, 10.5), Vector3(-2, 1.4, -1)],
		"near": [Vector3(.2, .05, 2.3), Vector3(-2, 1.3, -1)],
		"side": [Vector3(-5.4, .05, 1.0), Vector3(-2, 1.2, -1)],
		"container": [Vector3(-.6, .05, -5.3), Vector3(-3.0, 1.5, -3)],
	},
	"sandgate": {
		"canopy": [Vector3(17.2, 2.45, -10.6), Vector3(18.2, 4.15, -16.3)],
		"combat": [Vector3(15.73, .05, 13.48), Vector3(12.0, 3.3, 7.5)],
		"near": [Vector3(14.0, .05, 11.0), Vector3(11.75, 3.6, 9.15)],
		"side": [Vector3(13.5, .05, 4.1), Vector3(11.8, 3.1, 10.3)],
		"gate": [Vector3(16.3, .05, 19.0), Vector3(16.3, 3.2, 15.2)],
	},
}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	assert(DisplayServer.get_name() != "headless")
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 2 and VIEWS.has(args[0]))
	var id := args[0]
	var out := "res://docs/art/toy-evo/evolution/%s/%s/" % [id, args[1]]
	DirAccess.make_dir_recursive_absolute(out)
	seed(20261112)
	var game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	root.size = Vector2i(1440, 810)
	for _frame in range(900):
		if game.title_frame_ready: break
		await process_frame
	assert(game.title_frame_ready)
	game.qa_mode = true
	game.set_physics_process(false)
	var sessions: Dictionary = game.TITLE_SESSIONS.duplicate()
	sessions.merge(game.CONCEPT_SESSIONS)
	await game.select_session(sessions[id], id)
	assert(game.nav_ready)
	game.start_run()
	game.begin_running()
	game.invulnerable = 999
	game.hud.go_time = 0
	game.rules.elapsed = 2.0
	var player = game.player
	player.enabled = false
	player.set_process_unhandled_input(false)
	for enemy in game.live_enemies(): enemy.set_physics_process(false)
	if id == "score_attack":
		for room in game.arena.containers: room.set_physics_process(false)
	for label in VIEWS[id]:
		var pose: Array = VIEWS[id][label]
		player.global_position = pose[0]
		player.velocity = Vector3.ZERO
		var direction: Vector3 = (pose[0] + Vector3.UP * 1.6).direction_to(pose[1])
		player.rotation.y = atan2(-direction.x, -direction.z)
		player.pitch = asin(direction.y)
		player.camera.rotation.x = player.pitch
		for _frame in range(12): await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(out + label + ".png") == OK)
		print("SCENE_EVOLUTION_CAPTURE ", id, " ", label, " fov=", player.camera.fov)
	quit()
