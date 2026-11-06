extends Node
var game: Node

func _ready() -> void:
	Engine.max_fps = 60
	game.start_run()
	game.begin_running()
	game.clear_round()
	game.set_physics_process(false)
	game.player.enabled = false
	game.player.set_process_unhandled_input(false)
	game.player.position = Vector3(18,.05,5)
	game.player.rotation.y = 0
	game.player.pitch = 0
	game.hud.go_time = 0
	game.invulnerable = 0
	var left = stationary(Vector3(13,0,12))
	var middle = stationary(Vector3(18,0,14))
	var right = stationary(Vector3(23,0,12))
	stationary(Vector3(18,0,-3))
	stationary(Vector3(18,0,33))
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.hud.refresh_rear_threats()
	assert(game.hud.rear_threats.size()==3)
	assert(game.hud.rear_sector(left.position)==0 and game.hud.rear_sector(middle.position)==1 and game.hud.rear_sector(right.position)==2)
	assert(game.hud.rear_sector(Vector3(18,0,-3))==-1)
	for marker in game.hud.rear_markers:assert(not marker.accessibility_name.is_empty())
	await capture("rear-threats")
	game.player.rotation.y = PI
	game.hud.refresh_rear_threats()
	assert(game.hud.rear_threats.size()==1,"Turning moves the old rear threats into view")
	game.player.rotation.y = 0
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_size(Vector2i(960,540))
		await capture("rear-threats-small")
		for marker in game.hud.rear_markers:assert(Rect2(Vector2.ZERO,game.hud.size).encloses(marker.get_rect()))
		DisplayServer.window_set_size(Vector2i(1280,720))
	middle.patrol_brain = game.PatrolBrain.new()
	middle.add_child(middle.patrol_brain)
	middle.patrol_brain.warning = .5
	game.hud.refresh_rear_threats()
	assert(game.hud.rear_threats.filter(func(t):return t.sector==1)[0].urgent,"Mission guard warning escalates the rear indicator")
	# Solid cover must suppress all three behind-the-player indicators.
	var wall = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(14,4,.4)
	shape.shape = box
	wall.add_child(shape)
	game.add_child(wall)
	wall.position = Vector3(18,2,9)
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.hud.refresh_rear_threats()
	assert(game.hud.rear_threats.is_empty())
	wall.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	left.take_hit(true)
	game.hud.refresh_rear_threats()
	assert(game.hud.rear_threats.size()==2)
	game.state = "PAUSED"
	game.hud._physics_process(.1)
	for marker in game.hud.rear_markers:assert(not marker.visible)
	game.state = "RUNNING"
	game.respawn_time = 1
	game.hud.refresh_rear_threats()
	assert(game.hud.rear_threats.is_empty())
	game.respawn_time = 0
	print("REAR_THREATS_PASS: three directions, front/range exclusion, cover, death, pause, respawn, labels")
	game.clear_round()
	game.health = game.MAX_HEALTH
	game.invulnerable = 0
	# A 16 m shot must arrive in about 0.2 s, with no visible projectile mesh.
	game.enemy_shoot(Vector3(18,1.1,-11))
	assert(game.bullets.size()==1 and not game.bullets[0].node is MeshInstance3D)
	assert(game.bullets[0].node.get_child_count()==0)
	game.update_bullets(.1)
	assert(game.health==game.MAX_HEALTH and game.bullets.size()==1)
	var trail = game.effects.get_children().filter(func(n):return n is MeshInstance3D)[-1]
	assert(trail.mesh is BoxMesh and trail.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert(is_equal_approx(trail.material_override.albedo_color.r,.65))
	var position: Vector3 = game.bullets[0].node.position
	game.state = "PAUSED"
	game.update_bullets(.2)
	assert(game.bullets[0].node.position==position and game.health==game.MAX_HEALTH)
	game.state = "RUNNING"
	game.update_bullets(.11)
	assert(game.health==game.MAX_HEALTH-34 and game.bullets.is_empty())
	print("ENEMY_SHOT_SPEED_PAUSE_PASS")
	# A long physics step still sweeps into cover, never through it.
	game.health = game.MAX_HEALTH
	game.invulnerable = 0
	var cover = StaticBody3D.new()
	var cover_shape = CollisionShape3D.new()
	cover_shape.shape = box
	cover.add_child(cover_shape)
	game.add_child(cover)
	cover.position = Vector3(18,2,-3)
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.enemy_shoot(Vector3(18,1.1,-11))
	game.update_bullets(.5)
	assert(game.health==game.MAX_HEALTH and game.bullets.is_empty())
	cover.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.hud.damage = 0
	game.hud.kill_pop = 0
	# Side-on capture of an actual grey trajectory, without changing player aim.
	game.enemy_shoot(Vector3(12,1.1,-3))
	game.update_bullets(.045)
	await capture("enemy-grey-trace",false)
	game.start_run()
	assert(game.bullets.is_empty())
	game.state = "RESULTS"
	game.clear_round()
	await get_tree().create_timer(.25).timeout
	print("AWARENESS_CHECK_PASS: swept cover collision, restart cleanup, grey trace rendered")
	get_tree().quit()

func stationary(pos: Vector3) -> Node3D:
	var enemy = game.spawn_enemy(pos,false)
	enemy.set_physics_process(false)
	return enemy

func capture(filename: String, settle: bool = true) -> void:
	if DisplayServer.get_name()=="headless":return
	if settle:await get_tree().create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+filename+".png")
