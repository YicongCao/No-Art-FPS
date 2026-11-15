extends SceneTree
var game: Node3D
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var baseline := "--baseline" in OS.get_cmdline_user_args()
	var out := "res://docs/updates/melee-clearance-2026-11-15/"
	Engine.max_fps = 60
	game = load("res://scenes/main.tscn").instantiate();game.remember_title_selection = false
	root.add_child(game);root.size = Vector2i(1280,592)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	assert(game.title_frame_ready)
	game.qa_mode = true;game.start_run();game.begin_running();game.clear_round()
	game.set_physics_process(false);game.player.enabled = false;game.invulnerable = 999
	game.hud.go_time = 0
	game.rusher_model = load("res://assets/models/toy/rusher_mobile.glb")
	var start: Vector3 = game.player.global_position
	var front: Vector3 = -game.player.global_basis.z
	var actor: Node3D
	if baseline:
		actor = load("res://artifacts/local/enemy_before_clearance.gd").new()
		actor.game = game;actor.fast = true;actor.home_zone = game.arena.enemy_zone(start)
		actor.position = start+front*4
		game.enemies.add_child(actor)
	else:actor = game.spawn_enemy(start+front*4,true)
	actor.attack = 999
	for i in range(150):await physics_frame
	actor.set_physics_process(false)
	await RenderingServer.frame_post_draw
	var label := "before" if baseline else "after"
	root.get_texture().get_image().save_png(out+label+".png")
	var delta: Vector3 = actor.global_position-game.player.global_position
	var report = {"distance_m":Vector2(delta.x,delta.z).length(),"actor":str(actor.global_position),"player":str(start),"viewport":str(root.size),"scenario":"Same sandgate spawn and camera, compact Web model, cooldown chase for 150 physics ticks; no camera or model scaling"}
	FileAccess.open(out+label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	for type in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for voice in game.find_children("*",type,true,false):voice.stop()
	await create_timer(.15).timeout
	game.queue_free();await create_timer(.15).timeout
	quit()
