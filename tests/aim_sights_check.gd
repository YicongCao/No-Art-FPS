extends SceneTree

const Player = preload("res://scripts/player.gd")
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
	game.qa_mode = true
	game.start_run()
	game.begin_running()
	for enemy in game.live_enemies():enemy.set_physics_process(false)
	game.set_physics_process(false)
	var player = game.player
	for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(900,700)]:
		root.size = size
		for touch in [false,true]:
			game.touch_mode = touch
			player.set_aim_requested(true)
			player.aim_requested = true
			for _frame in range(30):await process_frame
			assert(is_equal_approx(player.aim_blend,1.0))
			var camera: Camera3D = player.camera
			var center: Vector2 = root.get_visible_rect().get_center()+player.crosshair_offset
			var rear := camera.unproject_position(player.gun.to_global(Player.RIFLE_REAR_APERTURE))
			var post := camera.unproject_position(player.gun.to_global(Player.RIFLE_FRONT_POST_TIP))
			assert(post.distance_to(center)<1.5,"Front post %s misses aim point %s"%[post,center])
			assert(rear.distance_to(center)<1.5,"Rear aperture %s misses aim point %s"%[rear,center])
			var ray: Vector3 = camera.project_ray_normal(center)
			assert(ray.angle_to(-camera.global_basis.z)<.001)
			player.aim_requested = false
			for _frame in range(30):await process_frame
	print("AIM_SIGHTS_PASS: rear aperture and front post sit on the shot point for desktop and touch")
	game.queue_free()
	await process_frame
	var deadline = Time.get_ticks_msec()+450
	while Time.get_ticks_msec()<deadline:await process_frame
	quit()
