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
	game.hud.go_time = 0
	game.player.position = Vector3(18,.05,5)
	game.player.rotation.y = atan2(3.0,7.0)
	game.player.pitch = 0
	await get_tree().physics_frame
	check_distribution()
	await check_live_miss()
	await check_live_hit()
	get_tree().quit()

func guard() -> Node3D:
	var enemy = game.spawn_enemy(Vector3(15,0,-2),false)
	enemy.set_physics_process(false)
	enemy.look_at(Vector3(18,enemy.position.y,5))
	return enemy

func check_distribution() -> void:
	var enemy = guard()
	var origin: Vector3 = enemy.ranged_origin()
	var aimed: Vector3 = game.player.global_position+Vector3(0,1.1,0)
	var ear: Vector3 = game.player.camera.global_position
	var axis_from: Vector3 = game.player.global_position
	var axis_to: Vector3 = axis_from+Vector3.UP*1.8
	var hits := 0
	var whizzes := 0
	var samples := 4000
	for i in samples:
		var target: Vector3 = enemy.shot_target(origin,aimed)
		if target==aimed:
			hits += 1
			continue
		var far: Vector3 = origin+origin.direction_to(target)*60.0
		var points := Geometry3D.get_closest_points_between_segments(origin,far,axis_from,axis_to)
		assert(points[0].distance_to(points[1])>.45,"A miss must clear the player capsule")
		if Geometry3D.get_closest_point_to_segment(ear,origin,far).distance_to(ear)<=game.NEAR_MISS_RADIUS:whizzes += 1
	var rate := float(hits)/samples
	assert(absf(rate-game.ENEMY_HIT_CHANCE)<.03,"Hit rate "+str(rate))
	assert(float(whizzes)/(samples-hits)>.95,"Misses pass within whiz range")
	print("ENEMY_HIT_RATE_PASS: ",snappedf(rate,.001)," of ",samples,"; misses clear the capsule, ",whizzes,"/",samples-hits," within whiz radius")
	enemy.queue_free()
	game.clear_round()

func fire(enemy: Node3D) -> void:
	enemy.attack = 0
	await get_tree().physics_frame
	enemy.advance_ranged_attack(0,true)
	enemy.advance_ranged_attack(enemy.windup,true)
	assert(game.bullets.size()==1,"The guard fired one round")

func whiz_played() -> bool:
	return game.effects.get_children().any(func(node):return node is AudioStreamPlayer3D and node.stream==game.sounds.whiz)

func check_live_miss() -> void:
	game.enemy_hit_chance = 0.0
	game.invulnerable = 0
	var health: float = game.health
	var enemy = guard()
	await fire(enemy)
	var tracer: Node3D = game.bullets[0].node
	var captured := false
	for step in 12:
		game.update_bullets(1.0/60.0)
		if not captured and is_instance_valid(tracer) and tracer.visible and tracer.global_position.distance_to(game.player.camera.global_position)<4.0:
			assert(tracer.material_override.albedo_color.a>.5,"Tracer is opaque in flight")
			await capture("near-miss-tracer")
			captured = true
	assert(captured,"The passing tracer is rendered near the camera")
	assert(whiz_played(),"A passing round whizzes")
	assert(game.health==health,"A miss does no damage")
	print("NEAR_MISS_TRACER_PASS: visible tracer beside the camera, whiz, no damage")
	enemy.queue_free()
	game.clear_round()
	await capture("near-miss-cleared")

func check_live_hit() -> void:
	game.enemy_hit_chance = 1.0
	game.invulnerable = 0
	var health: float = game.health
	var enemy = guard()
	await fire(enemy)
	for step in 30:game.update_bullets(1.0/60.0)
	assert(game.health<health,"An aimed round hits")
	game.enemy_hit_chance = game.ENEMY_HIT_CHANCE
	print("ENEMY_AIMED_HIT_PASS")
	enemy.queue_free()
	game.clear_round()

func capture(filename: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/local")
	get_viewport().get_texture().get_image().save_png("res://artifacts/local/"+filename+".png")
