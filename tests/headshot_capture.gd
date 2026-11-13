extends SceneTree
const CombatFX = preload("res://scripts/combat_fx.gd")
const OUT = "res://docs/art/toy/headshot/renders/"
var game: Node3D
var movie := false
func _initialize() -> void:run.call_deferred()
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	movie = "movie" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(OUT)
	game = load("res://scenes/main.tscn").instantiate()
	game.remember_title_selection = false
	root.add_child(game)
	root.size = Vector2i(1440,810)
	for i in range(900):
		await process_frame
		if game.title_frame_ready:break
	game.qa_mode = true
	game.start_run()
	game.begin_running()
	game.set_physics_process(false)
	game.player.enabled = false
	game.invulnerable = 999
	game.hud.go_time = 0
	if movie:
		print("HEADSHOT_MOVIE_START ",Engine.get_process_frames())
		for fast in [false,true]:
			for head in [false,true]:
				var foe = await setup_actor(fast,4)
				for i in range(30):await process_frame
				fire(foe,head)
				foe.set_physics_process(head)
				for i in range(70):await process_frame
		print("HEADSHOT_MOVIE_END ",Engine.get_process_frames())
	else:
		for fast in [false,true]:
			var label := "rusher" if fast else "rifleman"
			var foe = await setup_actor(fast,4)
			await capture(label+"-before")
			fire(foe,false)
			await frozen_frame(foe,.05)
			await capture(label+"-body")
			foe = await setup_actor(fast,4)
			fire(foe,true)
			for t in [.033,.10,.22,.65]:
				await frozen_frame(foe,t)
				await capture(label+"-head-"+str(roundi(t*1000)))
		for distance in [15,25]:
			var foe = await setup_actor(false,distance)
			fire(foe,true)
			await frozen_frame(foe,.033)
			await capture("head-"+str(distance)+"m")
	game.queue_free()
	for i in range(3):await process_frame
	print("HEADSHOT_CAPTURE_PASS")
	quit()

func setup_actor(fast: bool, distance: float) -> Node3D:
	game.clear_round()
	game.rules.start()
	game.kill_group_count = 0
	game.kill_group_start = -99
	game.hud.multi_time = 0
	await process_frame
	game.player.position = Vector3(18,.05,14)
	var foe = game.spawn_enemy(Vector3(18,.05,14-distance),fast)
	foe.set_physics_process(false)
	foe.look_at(Vector3(18,.05,14),Vector3.UP)
	var direction: Vector3 = game.player.camera.global_position.direction_to(foe.global_position+Vector3.UP*1.7)
	game.player.rotation.y = atan2(-direction.x,-direction.z)
	game.player.pitch = asin(direction.y)
	game.player.camera.rotation.x = game.player.pitch
	game.player.crosshair_offset = Vector2.ZERO
	game.hud.hit = 0
	game.hud.kill_pop = 0
	game.hud.headshot_confirm = 0
	game.hud.go_time = 0
	game.hud.set_process(true)
	for i in range(4):await process_frame
	return foe

func fire(foe: Node3D, head: bool) -> void:
	var point := foe.global_position+Vector3.UP*(1.7 if head else 1.25)+Vector3.BACK*.24
	if movie:
		var direction: Vector3 = game.player.camera.global_position.direction_to(point)
		game.player.pitch = asin(direction.y)
		game.player.camera.rotation.x = game.player.pitch
		game.fire_time = 0
		game.ammo = 30
		game.shoot()
		assert(foe.dead if head else foe.wounded)
		return
	# Use the same registered damage/kill event as a bullet, at a fixed visual pose.
	foe.take_hit(head,false,point,game.player.camera.global_position.direction_to(point),Vector3.BACK)
	game.hud.hit = .12
	if not movie:
		game.hud.set_process(false)
		for fx in game.effects.get_children():fx.set_physics_process(false)

func frozen_frame(foe: Node3D, target_time: float) -> void:
	var delta: float = target_time-foe.death_time if foe.dead else target_time
	while delta>.0001:
		var step := minf(delta,1.0/120)
		foe._physics_process(step) if foe.dead else foe.update_body_hit(step)
		for fx in game.effects.get_children():
			if fx is CombatFX:fx._physics_process(step)
		delta -= step
	game.hud.headshot_confirm = maxf(0,.22-target_time) if foe.dead else 0
	game.hud.hit = maxf(0,.12-target_time)
	game.hud.queue_redraw()
	await process_frame

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+label+".png")
	print("HEADSHOT_CAPTURE ",label)
